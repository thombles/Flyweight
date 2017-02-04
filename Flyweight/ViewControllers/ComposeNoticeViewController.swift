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

class ComposeNoticeViewController : UIViewController, UITextViewDelegate {
    
    var session: Session?
    var limit: Int64 = 1000
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBOutlet weak var textContent: UITextView!
    @IBOutlet weak var characterCount: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        session = SessionManager.activeSession
        if let limit = session?.instance.contentLimit {
            self.limit = limit
            refreshLimit()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        textContent.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        textContent.resignFirstResponder()
    }
    
    private func refreshLimit() {
        let remaining = limit - textContent.text.characters.count
        characterCount.text = "\(remaining) characters"
    }
    
    func textViewDidChange(_ textView: UITextView) {
        refreshLimit()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.modalTransitionStyle = .crossDissolve
        self.dismiss(animated: true)
    }
    
    @IBAction func postTapped(_ sender: Any) {
        self.modalTransitionStyle = .flipHorizontal
        self.dismiss(animated: true)
    }
}
