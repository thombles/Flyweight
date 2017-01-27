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
import PromiseKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var serverField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var logInContainer: UIView!
    @IBOutlet weak var testCredentialsContainer: UIView!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var testCredentialsButton: UIButton!
    
    let session = Session()
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /// If it's covered up, shift the frame so that the bottom of the login button aligns with the top of the keyboard
    func keyboardWillShow(notification: NSNotification) {
        guard let keyboardPosition = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect else { return }
        let loginButtonBase = logInButton.convert(logInButton.bounds, to: self.view).origin.y + logInButton.bounds.height
        let keyboardTop = view.bounds.height - keyboardPosition.size.height
        let diff = keyboardTop - loginButtonBase
        if diff < 0 {
            self.view.frame = CGRect(x: 0, y: diff, width: self.view.frame.width, height: self.view.frame.height)
        }
    }
    
    /// When keyboard disappears, reset the frame
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        logInContainer.layer.cornerRadius = 5.0
        testCredentialsContainer.layer.cornerRadius = 5.0
        logInContainer.clipsToBounds = true
        testCredentialsContainer.clipsToBounds = true
    }
    
    @IBAction func logInTapped(_ sender: Any) {
        improveServerField()
        
        // Make sure we have credentials to work with first
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
        
        
        // First verify we can get a server config, then verify the credentials
        let api = ServerApi(baseUrl: server)
        api.getGnusocialConfig().then { config -> Promise<(Bool, VerifyCredentialsDTO?)> in
            if let instance = self.session.instanceManager.processConfigDTO(url: server, config: config) {
                self.session.instance = instance
                // Go on to verifying credentials
                return api.verifyCredentials(username: username, password: password)
            } else {
                return Promise<(Bool, VerifyCredentialsDTO?)>(error: ParseError(reason: "Could not parse server config"))
            }
        }.then { verified, dto -> Void in
            if verified {
                if let user = self.session.userManager.processVerifiedCredentials(server: server, dto: dto) {
                    self.session.user = user
                } else {
                    self.resultLabel.text = "Unexpected result from server"
                    throw ParseError(reason: "Could not parse credentials response")
                }
                self.resultLabel.text = "OK!"
                self.loginSuccess()
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
    
    func loginSuccess() {
        let keychain = KeychainSwift()

        // Should always succeed
        guard let username = usernameField.text,
            let password = passwordField.text,
            let server = serverField.text else
        {
            return
        }
        
        // 1. Make sure we have an Account in DB
        let query = NSFetchRequest<AccountMO>(entityName: "Account")
        let accountQuery = session.fetch(request: query, moc: session.accountsMoc)
        if accountQuery.count == 0 {
            let newAccount = NSEntityDescription.insertNewObject(forEntityName: "Account", into: session.accountsMoc) as! AccountMO
            newAccount.id = 1 // TODO make this increment once it's possible to have more than one account
            // Also TODO need to override this when you log out and log back in as somebody else
            newAccount.username = username
            newAccount.server = server
            session.persist(moc: session.accountsMoc)
            
            // TODO This id allocation will need work hey
            keychain.set(password, forKey: "account\(newAccount.id)")
        }
        guard let account = session.fetch(request: query, moc: session.accountsMoc).first else
        {
            // Should not happen but don't crash
            return
        }
        
        // 2. Create a Session with the account and register it with the SessionManager
        session.account = account
        SessionManager.sessions = [session]
        SessionManager.activeSession = session
        
        // Now all our ViewControllers can grab SessionManager.activeSession on viewWillAppear and have all functionality
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeScreen = storyboard.instantiateViewController(withIdentifier: "homeScreen")
        self.view.window?.rootViewController = homeScreen
        
        // Unsubscribe from notifications since we're disappearing
        NotificationCenter.default.removeObserver(self)
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
        logInButton.isEnabled = false
        testCredentialsButton.isEnabled = false
        spinner.startAnimating()
        resultLabel.text = ""
    }
    
    func loginEnded() {
        usernameField.isEnabled = true
        passwordField.isEnabled = true
        serverField.isEnabled = true
        logInButton.isEnabled = true
        testCredentialsButton.isEnabled = true
        spinner.stopAnimating()
        resultLabel.isHidden = false
    }
    
    @IBAction func useTestCredentialsTapped(_ sender: Any) {
        usernameField.text = "user1"
        passwordField.text = "t4qXvLH8q87DuKVX"
        serverField.text = "https://gs1.karp.id.au/"
        logInTapped(sender)
    }
    
    
    
}
