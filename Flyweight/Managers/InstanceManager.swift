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

class InstanceManager {
    let session: Session
    init(session: Session) {
        self.session = session
    }
    
    func getInstance(url: String?) -> InstanceMO? {
        guard let url = url else { return nil }
        
        let query = NSFetchRequest<InstanceMO>(entityName: "Instance")
        query.predicate = NSPredicate(format: "url = %@", url)
        let results = session.fetch(request: query)
        return results.first
    }
    
    func processConfigDTO(url: String, config: GnusocialConfigDTO) -> InstanceMO? {
        if let existing = getInstance(url: url) { return existing }
        
        guard let fileQuota = config.attachments?.fileQuota,
            let name = config.site?.name,
            let serverOwnUrl = config.site?.server,
            let timezone = config.site?.timezone,
            let uploadsAllowed = config.attachments?.uploads else
        {
            return nil
        }
        
        let textLimit = Int64(config.site?.textLimit ?? "") ?? 1000
        let bioLimit = Int64(config.profile?.bioLimit ?? "") ?? textLimit
        let contentLimit = Int64(config.notice?.contentLimit ?? "") ?? textLimit
        let descLimit = Int64(config.group?.descLimit ?? "") ?? textLimit
        let fileQuota64 = Int64(fileQuota)
        
        
        // Otherwise make a new one
        let new = NSEntityDescription.insertNewObject(forEntityName: "Instance", into: session.moc) as! InstanceMO
        new.bioLimit = bioLimit
        new.contentLimit = contentLimit
        new.descLimit = descLimit
        new.fileQuota = fileQuota64
        new.textLimit = textLimit
        new.name = name
        new.serverOwnUrl = serverOwnUrl
        new.timezone = timezone
        new.url = url
        new.uploadsAllowed = uploadsAllowed
        
        if let logo = config.site?.logo {
            new.logo = logo
        }
        
        session.persist()
        
        return new
    }
}
