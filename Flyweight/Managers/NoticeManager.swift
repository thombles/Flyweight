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
        query.predicate = NSPredicate(format: "server = %@ and id = %ld", server, id)
        let results = session.fetch(request: query)
        return results.first
    }
    
    func processNoticeDTOs(notices: [NoticeDTO]) -> [NoticeMO] {
        var ret: [NoticeMO] = []
        
        for dto in notices {
            // Parse out the server part
            // This is GNU-social specific
            guard let uri = dto.uri else { continue }
            guard let noticeBaseUrl = uri.components(separatedBy: ":")[1]
                .components(separatedBy: ",").first else { continue }
            
            // If there isn't a matching notice in realm, create one
            if let existing = getNotice(id: dto.id, server: noticeBaseUrl) {
                NSLog("Already present with server \(existing.server) and id \(existing.id)")
                continue
            }
            
            // Make sure we have valid data
            guard let id = dto.id, let text = dto.text, let username = dto.user?.name, let screenName = dto.user?.screenName, let createdAt = dto.createdAt else {
                continue
            }
            
            guard let profileImageUrlProfileSize = dto.user?.profileImageUrlProfileSize else {
                continue
            }
            
            // Sentinel value for no value received from the server
            let faveNum = dto.faveNum ?? -1
            let repeatNum = dto.repeatNum ?? -1
            
            // Get either an existing or new user based on the DTO
            // If we can't parse the user then we can't use this notice
            guard let user = session.userManager.processDTO(dto: dto.user) else {
                continue
            }
            
            // Need to make a new one
            let new = NSEntityDescription.insertNewObject(forEntityName: "Notice", into: session.moc) as! NoticeMO
            new.id = id
            new.server = noticeBaseUrl
            new.text = text
            new.user = user
            new.createdAt = createdAt
            new.lastUpdated = Date()
            new.faveNum = faveNum
            new.repeatNum = repeatNum
            
            session.persist()
            NSLog("Created new object with server \(new.server) and id \(new.id)")
            ret.append(new)
        }

        return ret
    }
}
