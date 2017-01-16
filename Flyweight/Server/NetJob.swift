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
import PromiseKit
import Alamofire

// NetJobs can be quite different but they need to implement a standard set of methods to be usable with NetJobManager
protocol NetJob {
    var jobCompletionCallback: ((NetJobCompletion) -> ())? { get set }
    var requestId: Int { get set }
    func enqueue()
    func start()
    // cancel
    // progress
    // etc.
}

class NetJobCompletion {
    let job: NetJob
    let success: Bool
    let message: String?
    
    init(job: NetJob, success: Bool, message: String? = nil) {
        self.job = job
        self.success = success
        self.message = message
    }
}

class BinaryNetJob: NetJob {
    let session: Session
    var jobCompletionCallback: ((NetJobCompletion) -> ())?
    var result: Promise<Data>!
    var url: String
    var requestId: Int = 0
    private var fulfil: ((Data) -> Void)?
    private var reject: ((Error) -> Void)?
    
    init (session: Session, url: String) {
        self.session = session
        self.url = url
        // Get the promise armed and ready so things can hang on to it as soon as we init
        self.result = Promise { f, r in
            self.fulfil = { (data: Data) in
                f(data)
                self.jobCompletionCallback?(NetJobCompletion(job: self, success: true))
            }
            self.reject = { (error: Error) in
                r(error)
                self.jobCompletionCallback?(NetJobCompletion(job: self, success: false, message: "Download failure"))
            }
        }
    }
    
    func start() {
        Alamofire.request(self.url).responseData { response in
            if let value = response.result.value {
                self.fulfil?(value)
            }
            else {
                self.reject?(ApiError(path: self.url, error: response.result.error))
            }
        }
    }
    
    func enqueue() {
        session.netJobManager.queueJob(job: self, priority: .Normal)
    }
}

class TimelineUpdateNetJobResult {
    var fullSuccess = false             // did we get all the way to the end and terminate normally?
    var newNotices: [NoticeMO] = []       // the notices that were added, newest first
    var message: String?                // optional explanation for what happened
    var reachedStart = false            // did we run out of results earlier than expected?
    var limitNotice: NoticeInGSTimelineMO? // original parameter
}

class TimelineUpdateNetJob: NetJob {
    // NetJob requirements
    var jobCompletionCallback: ((NetJobCompletion) -> ())?
    var requestId: Int = 0
    
    let session: Session
    
    // Parameters that should be configured before enqueue()
    var listType: GSTimelineType?
    var instance: InstanceMO?
    var maxPages: Int = 1
    var perPage: Int = 50
    var isAuthenticated = false
    var limitNotice: NoticeInGSTimelineMO?
    
    // Work in progress
    private var currentPage = 1
    private var failureOccurred = false
    private var message: String?
    private var newNotices: [NoticeMO] = []
    private var reachedStart = false
    var requestParameters = ListRequestParameters()
    
    // For when we finish
    private var fulfil: ((TimelineUpdateNetJobResult) -> Void)?
    private var reject: ((Error) -> Void)?
    var result: Promise<TimelineUpdateNetJobResult>! // should not normally fail, just return 0 results
    
    init(session: Session) {
        self.session = session
        
        self.result = Promise { f, r in
            self.fulfil = { (result: TimelineUpdateNetJobResult) in
                f(result)
                if result.fullSuccess {
                    self.jobCompletionCallback?(NetJobCompletion(job: self, success: true))
                } else {
                    // Count it as a job failure even if we got partial results. Want to flag it as a network issue.
                    self.jobCompletionCallback?(NetJobCompletion(job: self, success: false, message: result.message))
                }
            }
            self.reject = { (error: Error) in
                r(error)
                
            }
        }
    }
    
    func configureLimitId() {
        // override in subclass
    }
    
    func start() {
        // TODO 1 - validate parameters and fail the promise if it wasn't
        
        // Now set request parameters for the first time
        self.configureLimitId()
        requestParameters.set(count: perPage)
        requestParameters.set(page: currentPage)
        
        submitNextRequest()
    }
    
    func submitNextRequest() {
        NSLog("Starting request with query string \(requestParameters.queryString)")
        session.api.getPublicTimeline(params: requestParameters)
            .then(execute: requestSuccessHandler)
            .catch(execute: requestFailureHandler)
    }

    func requestSuccessHandler(notices: [NoticeDTO]) {
        // Process them and get the valid ones back
        let realNotices = self.session.noticeManager.processNoticeDTOs(notices: notices)
        // Put them in our array
        self.newNotices.append(contentsOf: realNotices)
        
        // Have we joined the chain? Only if we got fewer results than we were expecting
        reachedStart = notices.count < self.perPage
        
        self.currentPage += 1
        if !self.reachedStart && self.currentPage <= self.maxPages {
            requestParameters.set(page: self.currentPage)
            self.submitNextRequest()
        } else {
            self.finalise()
        }
        
        return
    }
    
    func requestFailureHandler(error: Error) {
        if let e = error as? ApiError {
            self.message = "Failed to download: \(e.description)"
            self.failureOccurred = true
            self.finalise()
        }
    }
    
    // Using the state we have now, build up a TimelineUpdateNetJobResult and fulfil()
    func finalise() {
        let result = TimelineUpdateNetJobResult()
        result.fullSuccess = !self.failureOccurred
        result.newNotices = self.newNotices
        result.reachedStart = self.reachedStart
        result.message = self.message ?? "Downloaded \(self.newNotices.count) notice\(self.newNotices.count == 1 ? "" : "s")"
        result.limitNotice = self.limitNotice
        self.fulfil?(result)
    }
    
    func enqueue() {
        session.netJobManager.queueJob(job: self, priority: .Normal)
    }
}

class RefreshNetJob: TimelineUpdateNetJob {
    override func configureLimitId() {
        if let limitId = self.limitNotice?.noticeId {
            requestParameters.set(sinceId: limitId)
        }
    }
}

class LoadMoreNetJob: TimelineUpdateNetJob {
    override func configureLimitId() {
        if let limitId = self.limitNotice?.noticeId {
            requestParameters.set(maxId: limitId)
        }
    }
}

