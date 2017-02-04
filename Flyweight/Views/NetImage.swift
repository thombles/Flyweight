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

class NetImage: UIImageView {
    
    var session: Session?
    private var downloadListener: EventListenerToken<DownloadBinaryFinishedEvent>?
    
    override func awakeFromNib() {
        session = SessionManager.activeSession
    }
    
    var url: String? {
        willSet(newUrl) {
            if newUrl == nil || newUrl != self.url {
                self.image = nil
            }
        }
        didSet {
            if self.url != nil {
                self.downloadListener = self.session?.events.downloadBinaryFinished.subscribeValue { event in
                    if event.url == self.url {
                        self.updateFromQuery()
                    }
                }
                self.updateFromQuery()
            }
        }
    }
    
    fileprivate func updateFromQuery() {
        guard let url = self.url else { return }

        if let path = session?.binaryManager.getDownloadedBinaryForUrl(url: url)?.localPath {
            DispatchQueue.global(qos: .background).async {
                do {
                    guard let calculatedPath = SessionManager.activeSession?.binaryManager.pathForFile(path) else
                    { return }
                    let data = try Data(contentsOf: calculatedPath)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.image = image
                        }
                    }
                } catch {
                    NSLog("Failed to get the file")
                }
            }
        }
    }
}
