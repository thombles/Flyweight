// Flyweight - iOS client for GNU social
// Copyright 2017 Thomas Karpiniec
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import CoreData
import PromiseKit


class RefreshResult {
    var noticesToInsert: [NoticeInGSTimelineMO] = []
    var clearListFirst = false
}

class LoadMoreResult {
    var noticesToInsert: [NoticeInGSTimelineMO] = []
    var loadMorePossible = true
}


class GSTimelineManager {
    
    // Use this for any operation that could create a new timeline
    var timelineAcquisitionLock = NSLock()
    
    let session: Session
    init(session: Session) {
        self.session = session
    }
    
    func getPublicTimeline(instance: InstanceMO?) -> GSTimelineMO {
        // ignore instance for the second
        timelineAcquisitionLock.lock()
        var ret: GSTimelineMO?
        let query = NSFetchRequest<GSTimelineMO>(entityName: "GSTimeline")
        query.predicate = NSPredicate(format: "listType == %d", GSTimelineType.Public.rawValue)
        let timelines = session.fetch(request: query)
        if timelines.isEmpty {
            let newTimeline = NSEntityDescription.insertNewObject(forEntityName: "GSTimeline", into: session.moc) as! GSTimelineMO
            newTimeline.listType = GSTimelineType.Public.rawValue
            session.persist()
            ret = newTimeline
        } else {
            ret = timelines.first!
        }
        timelineAcquisitionLock.unlock()
        return ret!
    }
    
    func getNoticesForTimeline(timeline: GSTimelineMO) -> LoadMoreResult {
        // Let's just walk its associations until we either hit maximum, or the end
        let res = LoadMoreResult()
        res.loadMorePossible = true
        var count = 0
        let query = NoticeInGSTimelineMO.fetchRequest() as! NSFetchRequest<NoticeInGSTimelineMO>
        query.predicate = NSPredicate(format: "gsTimeline == %@", timeline)
        let notices = session.fetch(request: query).sorted { $0.noticeId > $1.noticeId }
        for n in notices {
            count += 1
            res.noticesToInsert.append(n)
            if n.previousNotice == nil && timeline.atBeginning {
                res.loadMorePossible = false
            }
            if count > 50 {
                break
            }
        }
        return res
    }
    
    // Set up refresh, return promise for result
    func refreshPublicTimeline(lastNotice: NoticeInGSTimelineMO?) -> Promise<RefreshResult> {
        // A refresh will always involve downloading new data so go straight to the NetJob
        let job = RefreshNetJob(session: session)
        job.limitNotice = lastNotice
        let timeline = getPublicTimeline(instance: nil)
        
        let refreshPromise: Promise<RefreshResult> = job.result.then { (result: TimelineUpdateNetJobResult) -> RefreshResult in
            let noticesInTimeline = self.processRefresh(netJobResult: result, timeline: timeline)
            let refreshResult = RefreshResult()
            refreshResult.noticesToInsert = noticesInTimeline.reversed()
            refreshResult.clearListFirst = !result.reachedStart
            return refreshResult
        }
        job.listType = .Public
        job.enqueue()
        return refreshPromise
    }
    
    // Set up load more, return promise for result
    func loadMorePublicTimeline(maxNotice: NoticeInGSTimelineMO?) -> Promise<LoadMoreResult> {
        // First let's see if we have more data we can provide out of the database
        // Get things older than the maxId and walk backwards until we have 10 new notices
        // If we fail on the first one, do the NetJob
        // If we reach the end of the chain, use the timeline's atBeginning flag to check
        let maxLimit = maxNotice?.noticeId ?? Int64.max
        let timeline = getPublicTimeline(instance: nil)
        let query = NSFetchRequest<NoticeInGSTimelineMO>(entityName: "NoticeInGSTimeline")
        query.predicate = NSPredicate(format: "noticeId < %ld", maxLimit)
        let candidates = session.fetch(request: query).sorted { $0.noticeId > $1.noticeId }
        
        // If we have at least one result (without forcing a complete calculation) then do our own result
        if maxNotice?.previousNotice != nil && candidates.first != nil {
            let loadMoreResult = LoadMoreResult()
            for c in candidates {
                // Take a candidate
                loadMoreResult.noticesToInsert.append(c)
                
                // If there is no previous notice in this chain, terminate here
                // If the timeline is marked atBeginning, that must be where we are (assuming DB not corrupt)
                if c.previousNotice == nil {
                    if timeline.atBeginning {
                        loadMoreResult.loadMorePossible = false
                    } else {
                        loadMoreResult.loadMorePossible = true
                    }
                    break
                }
                
                // If we have enough notices just using our database, stop here
                if loadMoreResult.noticesToInsert.count >= 50 {
                    break
                }
            }
            
            return Promise.init(value: loadMoreResult)
        }
        else {
            let job = LoadMoreNetJob(session: session)
            job.maxPages = 1
            job.limitNotice = maxNotice
            
            let loadMorePromise: Promise<LoadMoreResult> = job.result.then { (result: TimelineUpdateNetJobResult) -> LoadMoreResult in
                let noticesInTimeline = self.processRefresh(netJobResult: result, timeline: timeline)
                let loadMoreResult = LoadMoreResult()
                loadMoreResult.noticesToInsert = noticesInTimeline.reversed()
                loadMoreResult.loadMorePossible = !result.reachedStart
                if result.reachedStart {
                    // mark the timeline if we're at the beginning
                    timeline.atBeginning = true
                    self.session.persist()
                }
                return loadMoreResult
            }
            job.listType = .Public
            job.enqueue()
            return loadMorePromise
        }

    }
    
    // Private method to process results before the timeline gets them
    private func processRefresh(netJobResult: TimelineUpdateNetJobResult, timeline: GSTimelineMO) -> [NoticeInGSTimelineMO] {
        NSLog("Refresh fullSuccess: \(netJobResult.fullSuccess) new notice count: \(netJobResult.newNotices.count) chain joined: \(netJobResult.reachedStart)")
        
        var prevNotice: NoticeMO? = nil
        let chainedNotice: NoticeMO? = netJobResult.reachedStart ? netJobResult.limitNotice?.notice : nil
        var noticesInList: [NoticeInGSTimelineMO] = []
        let ascendingNotices = netJobResult.newNotices.sorted(by: { n1, n2 in return n1.id < n2.id })
        
        // If this was a LoadMore, i.e. ids are lower, join the chain!
        if let first = ascendingNotices.last {
            if let limitNotice = netJobResult.limitNotice {
                if first.id < limitNotice.noticeId {
                    limitNotice.previousNotice = first
                }
            }
        }
        
        for n in ascendingNotices {
            let noticeInTimeline = NSEntityDescription.insertNewObject(forEntityName: "NoticeInGSTimeline", into: session.moc) as! NoticeInGSTimelineMO
            noticeInTimeline.noticeId = n.id
            noticeInTimeline.previousNotice = prevNotice ?? chainedNotice
            noticeInTimeline.gsTimeline = timeline
            noticeInTimeline.notice = n
            noticesInList.append(noticeInTimeline)
            
            prevNotice = n
        }
        
        // If this was a Refresh, i.e. ids are higher, join the chain!
        if let last = noticesInList.first {
            if let limitNotice = netJobResult.limitNotice {
                if last.noticeId > limitNotice.noticeId {
                    last.previousNotice = limitNotice.notice
                }
            }
        }
        
        session.persist()
        return noticesInList
    }
}