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

class LoginViewController: UIViewController {
    
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var serverField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBAction func logInTapped(_ sender: Any) {
        improveServerField()
        
        // Validate credentials first
        guard let username = usernameField.text,
            let password = passwordField.text,
            let server = serverField.text else
        {
            return // should be impossible
        }
        
        if username.isEmpty || password.isEmpty || server.isEmpty {
            resultLabel.text = "Please complete all fields"
            return
        }
        
        // All seems okay, so test it
        let api = ServerApi(baseUrl: server)
        api.verifyCredentials(username: username, password: password).then { verified -> Void in
            if verified {
                self.resultLabel.text = "OK!"
            } else {
                self.resultLabel.text = "Wrong username or password"
            }
        }.catch { err in
            self.resultLabel.text = "Could not connect to server"
        }.always {
            self.loginEnded()
        }
        
        loginInProgress()
    }
    
    /// Help the user format the server URL correctly
    func improveServerField() {
        guard var server = serverField.text else { return }
        
        let nsServer = server as NSString
        if !nsServer.hasPrefix("https://") && !nsServer.hasPrefix("http://") {
            server = "https://\(server)"
        }
        if !nsServer.hasSuffix("/") {
            server += "/"
        }
        serverField.text = server
    }
    
    @IBAction func serverEditingDidBegin(_ sender: Any) {
        if serverField.text?.isEmpty ?? true {
            serverField.text = "https://"
        }
    }
    
    @IBAction func serverEditingDidEnd(_ sender: Any) {
        improveServerField()
    }
    
    func loginInProgress() {
        usernameField.isEnabled = false
        passwordField.isEnabled = false
        serverField.isEnabled = false
        spinner.startAnimating()
        resultLabel.text = ""
    }
    
    func loginEnded() {
        usernameField.isEnabled = true
        passwordField.isEnabled = true
        serverField.isEnabled = true
        spinner.stopAnimating()
        resultLabel.isHidden = false
    }
    
    @IBAction func useTestCredentialsTapped(_ sender: Any) {
        
        let session = Session()
        
        // should prob fill in the fields hey
        let keychain = KeychainSwift()
        let username = "user1"
        let password = "t4qXvLH8q87DuKVX"
        let server = "https://gs1.karp.id.au/"
        
        // 1. Make sure we have an Account in DB
        let query = NSFetchRequest<AccountMO>(entityName: "Account")
        let accountQuery = session.fetch(request: query, moc: session.accountsMoc)
        if accountQuery.count == 0 {
            let newAccount = NSEntityDescription.insertNewObject(forEntityName: "Account", into: session.accountsMoc) as! AccountMO
            newAccount.id = 1
            newAccount.username = username
            newAccount.server = server
            session.persist(moc: session.accountsMoc)
            
            // TODO This id allocation will need work hey
            keychain.set(password, forKey: "account\(newAccount.id)")
        }
        let account = session.fetch(request: query, moc: session.accountsMoc).first!
        
        // 2. Create a Session with the account and register it with the SessionManager
        session.account = account
        SessionManager.sessions.append(session)
        SessionManager.activeSession = session
        
        // Now all our ViewControllers can grab SessionManager.activeSession on viewWillAppear and have all functionality
        
        performSegue(withIdentifier: "toMainScreen", sender: self)
    }
    
    
}
