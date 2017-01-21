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

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // App has launched
        // We need to set up our static context so the app will run
        
        // Later this will be handled by the login/account selection screen
        
        let session = Session()
        
        let keychain = KeychainSwift()
        let username = "user1"
        let password = "t4qXvLH8q87DuKVX"
        let server = "https://gs1.karp.id.au/"
        
        // 1. Make sure we have an Account in DB
        let query = NSFetchRequest<AccountMO>(entityName: "Account")
        let accountQuery = session.fetch(request: query)
        if accountQuery.count == 0 {
            let newAccount = NSEntityDescription.insertNewObject(forEntityName: "Account", into: session.moc) as! AccountMO
            newAccount.id = 1
            newAccount.username = username
            newAccount.server = server
            session.persist()
            
            // This id allocation will need work hey
            keychain.set(password, forKey: "account\(newAccount.id)")
        }
        let account = session.fetch(request: query).first!
        
        // 2. Create a Session with the account and register it with the SessionManager
        session.account = account
        SessionManager.sessions.append(session)
        SessionManager.activeSession = session
        
        // Now all our ViewControllers can grab SessionManager.activeSession on viewWillAppear and have all functionality
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

