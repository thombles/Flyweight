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

// This is effectively the interface for one logged in Account.
// UI gets one of these by asking the SessionManager for the activeSession.
// Then it can query whatever it needs to about the client state, make requests, etc.
class Session {
    var username: String {
        return account.username
    }
    var password: String!
    var account: AccountMO! {
        didSet {
            let keychain = KeychainSwift()
            password = keychain.get("account\(account.id)")
        }
    }
    lazy var noticeManager: NoticeManager = NoticeManager(session: self)
    lazy var userManager: UserManager = UserManager(session: self)
    lazy var serverManager: ServerManager = ServerManager(session: self)
    lazy var binaryManager: BinaryManager = BinaryManager(session: self)
    lazy var netJobManager: NetJobManager = NetJobManager(session: self)
    lazy var instanceManager: InstanceManager = InstanceManager(session: self)
    lazy var gsTimelineManager: GSTimelineManager = GSTimelineManager(session: self)
    
    var events = SessionEventBus()
    
    // All sessions share a CoreData database
    static var dataController: DataController = DataController(modelName: "gs001", filename: "social.sqlite")
    static var accountsDataController: DataController = DataController(modelName: "acc001", filename: "accounts.sqlite")
    
    /*init(account: AccountMO) {
        self.account = account
    }*
 */
    
    init() {
        
    }
    
    var api: ServerApi {
        return self.serverManager.api
    }
    
    var moc: NSManagedObjectContext {
        return Session.dataController.managedObjectContext
    }
    
    var accountsMoc: NSManagedObjectContext {
        return Session.accountsDataController.managedObjectContext
    }
    
    func persist(moc: NSManagedObjectContext = Session.dataController.managedObjectContext) {
        do {
            try moc.save()
        } catch {
            fatalError("Could not save database: \(error)")
        }
    }
    
    func fetch<T>(request: NSFetchRequest<T>, moc: NSManagedObjectContext = Session.dataController.managedObjectContext) -> [T] {
        var results: [T]?
        do {
            results = try moc.fetch(request)
        } catch {
            fatalError("Failed to perform fetch \(error)")
        }
        return results!
    }
}
