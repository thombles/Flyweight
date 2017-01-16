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
    
    func getUser(profileUrl: String?) -> UserMO? {
        guard let profileUrl = profileUrl else
        {
            return nil
        }
        
        let query = NSFetchRequest<UserMO>(entityName: "User")
        query.predicate = NSPredicate(format: "profileUrl = %@", profileUrl)
        let results = session.fetch(request: query)
        return results.first
    }
    
    func processDTO(dto: UserDTO?) -> UserMO?
    {
        guard let dto = dto, let username = dto.name, let screenName = dto.screenName, let profileImageUrlProfileSize = dto.profileImageUrlProfileSize, let profileUrl = dto.statusnetProfileUrl else {
            return nil
        }
        
        if let existing = getUser(profileUrl: profileUrl) {
            return existing
        }
        
        // Make a new User
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: session.moc) as! UserMO
        user.name = username
        user.screenName = screenName
        user.profileImageUrlProfileSize = profileImageUrlProfileSize
        user.profileUrl = profileUrl
        session.persist()
        
        return user
    }
}
