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

class NoticeManager {
    
    let session: Session
    
    init(session: Session) {
        self.session = session
    }
    
    func getNotice(id: Int64?, server: String? = nil) -> NoticeMO? {
        guard let id = id else
        {
            return nil
        }
        let server = server ?? session.account.server
        
        let query = NoticeMO.fetchRequest() as! NSFetchRequest<NoticeMO>
        query.predicate = NSPredicate(format: "server = %@ AND statusNetId = %ld", server, id)
        let results = session.fetch(request: query)
        return results.first
    }
    
    /// New way, using the parsed ActivityStreams XML objects
    func processNoticeEntries(sourceServer: String, entries: [ASEntry], idOverride: Int64? = nil) -> [NoticeMO] {
        var ret: [NoticeMO] = []
        
        for entry in entries {
            guard let statusNetId = idOverride ?? entry.statusNetNoticeId else { continue }

            // If that notice is already in our DB skip creating a new one
            if let existing = getNotice(id: statusNetId, server: sourceServer) {
                // TODO possibly update things? Can they change?
                
                // To deal with repeated notices already having been processed in the same batch,
                // we need to include them inline again in the returned notices.
                // This will give screwy results if a server gives us more results than we asked for
                // Trust the server impl for the moment
                ret.append(existing)
                
                continue
            }
            
            // Make sure we have all the common data we care about first
            guard let tag = entry.id,
                let htmlContent = entry.htmlContent,
                let htmlLink = entry.htmlLink,
                let published = entry.published,
                let updated = entry.updated,
                let author = entry.author,
                let conversationUrl = entry.conversationUrl,
                let conversationNumber = entry.conversationNumber,
                let conversationThread = entry.conversationThread else // not actually a big deal but common
            {
                continue
            }
            
            // Process author (User object in core data)
            // Get either an existing or new user based on the DTO
            // If we can't parse the user then we can't use this notice
            guard let user = session.userManager.processFeedAuthor(sourceServer: sourceServer, author: author) else {
                continue
            }
            
            // Must be a better way to organise this but it'll do for now
            // Ensure we have all the data for the specific subtype _before_ we commit to making the new NoticeMO
            if entry.isReply {
                guard entry.inReplyToNoticeUrl != nil && entry.inReplyToNoticeRef != nil else { continue }
            }
            if entry.isFavourite {
                guard entry.object?.statusNetNoticeId != nil && entry.object?.htmlLink != nil else { continue }
            }
            var repeatedNotice: NoticeMO? = nil
            if entry.isRepeat {
                if let object = entry.object,
                    let repeatedId = entry.repeatOfNoticeId {
                    repeatedNotice = processNoticeEntries(sourceServer: sourceServer, entries: [object], idOverride: repeatedId).first
                }
                // It's okay if the repeated notice goes into the DB but we hit a parse error for the containing one below
                guard repeatedNotice != nil else { continue }
            }
            if entry.isDelete {
                // TODO either purge the old one from the DB or mark it hidden
            }
            
            let new = NSEntityDescription.insertNewObject(forEntityName: "Notice", into: session.moc) as! NoticeMO
            
            // As yet unused, sadly. Put in sentinel values so numbers will be hidden in UI.
            new.faveNum = -1
            new.repeatNum = -1
            
            // Fill in all the info we have
            new.server = sourceServer
            new.statusNetId = statusNetId
            new.tag = tag
            new.htmlContent = htmlContent
            new.htmlLink = htmlLink
            new.published = published as NSDate
            new.lastUpdated = updated as NSDate
            new.conversationUrl = conversationUrl
            new.conversationId = conversationNumber
            new.conversationThread = conversationThread
            new.client = entry.client ?? "" // kind of optional
            new.user = user
            
            new.isOwnPost = entry.isPost || entry.isComment
            new.isReply = entry.isReply
            new.isRepeat = entry.isRepeat
            new.isFavourite = entry.isFavourite
            new.isDelete = entry.isDelete
            
            // Store extra data depending on the type of notice it was
            // If anything is missing this is an inconsistent notice and we should just ignore the whole thing
            
            if entry.isReply {
                guard let repliedTag = entry.inReplyToNoticeRef,
                    let repliedUrl = entry.inReplyToNoticeRef else
                {
                    continue
                }
                new.inReplyToNoticeTag = repliedTag
                new.inReplyToNoticeUrl = repliedUrl
            }
            
            if entry.isFavourite {
                guard let favouritedId = entry.object?.statusNetNoticeId,
                    let favouritedHtmlLink = entry.object?.htmlLink else
                {
                    continue
                }
                new.favouritedStatusNetId = favouritedId
                new.favouritedHtmlLink = favouritedHtmlLink
            }
            
            // The feed recursively embeds the repeated entry so we can recursively parse it too
            if entry.isRepeat {
                // If it's a repeat this will definitely have been set above
                new.repeatedNotice = repeatedNotice
            }
            
            session.persist()
            NSLog("Created new object with server \(new.server) and id \(new.statusNetId)")
            ret.append(new)
        }
        
        return ret
    }
}
