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

class UserManager {
    let session: Session
    
    init(session: Session) {
        self.session = session
    }
    
    func getUser(server: String?, profileUrl: String?) -> UserMO? {
        guard let profileUrl = profileUrl, let server = server else
        {
            return nil
        }
        
        let query = NSFetchRequest<UserMO>(entityName: "User")
        query.predicate = NSPredicate(format: "profileUrl = %@ AND server = %@", profileUrl, server)
        let results = session.fetch(request: query)
        return results.first
    }
 
    func processFeedAuthor(sourceServer: String, author: ASAuthor?) -> UserMO?
    {
        // Minimum parts required
        guard let author = author,
            let uri = author.uri,
            let statusNetUserId = author.statusNetUserId,
            let username = author.username else
        {
            return nil
        }
        
        if let existing = getUser(server: sourceServer, profileUrl: uri) {
            // TODO apply updates
            return existing
        }
        
        // Make a new User
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: session.moc) as! UserMO
        user.id = statusNetUserId
        user.profileUrl = uri
        user.name = username
        user.screenName = author.displayName
        user.bio = author.bio
        user.server = sourceServer
        NSLog("Added user \(user.name)")
        
        // Also process Avatars if we're making a new user. Not strictly required but do our best with them
        processFeedAvatars(user: user, avatars: author.avatars)
        
        session.persist()
        return user
    }
    
    func processFeedAvatars(user: UserMO, avatars: [ASAvatar]) {
        // Assuming new or updated user at this stage. Create new entries.
        // Should really diff them
        user.avatars = []
        for av in avatars {
            guard let url = av.url,
                let mimeType = av.mimeType,
                let width = av.width,
                let height = av.height else
            {
                continue
            }
            
            let avatarMO = NSEntityDescription.insertNewObject(forEntityName: "UserAvatar", into: session.moc) as! UserAvatarMO
            avatarMO.url = url
            avatarMO.mimeType = mimeType
            avatarMO.width = width
            avatarMO.height = height
            user.addToAvatars(avatarMO)
        }
    }

}
