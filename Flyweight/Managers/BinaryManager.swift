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

import PromiseKit
import UIKit
import CoreData

class BinaryManager {
    
    let session: Session
    
    var requestedLock = NSLock()
    var requested: [String] = []
    
    init(session: Session) {
        self.session = session
        
        do {
            let path = self.downloadsDir().path
            if !FileManager.default.fileExists(atPath: path) {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            NSLog("Could not create downloads directory")
        }
    }

    
    func pathForFile(_ filename: String) -> URL {
        let fileURL = self.downloadsDir().appendingPathComponent(filename)
        return fileURL
    }
    
    func downloadsDir() -> URL {
        return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("downloads")
    }
    
    func getImage(_ url: String) -> Promise<UIImage>  {
        return Promise<UIImage> { fulfil, reject in
            // TODO make this use the job manager
            let job = BinaryNetJob(session: self.session, url: url)
            job.result.then() { (data: Data) -> Void in
                if let image = UIImage(data: data) {
                    fulfil(image)
                }
                else {
                    reject(ApiError(path: url, error: nil))
                }
            }.catch() { error in
                reject(error)
            }
            job.start()
        }
    }
    
    func getDownloadedBinaryForUrl(url: String) -> DownloadedBinaryMO? {
        let cdFetch = NSFetchRequest<DownloadedBinaryMO>(entityName: "DownloadedBinary")
        cdFetch.predicate = NSPredicate(format: "url == %@", url)
        return session.fetch(request: cdFetch).first
    }
    
    func downloadImageIfNecessary(_ url: String?) {
        guard let url = url else { return }
        if getDownloadedBinaryForUrl(url: url) != nil {
            // If we have it, nothing to do
            return
        }
        
        requestedLock.lock()
        requested.append(url)
        requestedLock.unlock()
        
        let job = BinaryNetJob(session: session, url: url)
        let _ = job.result.then() { (data: Data) -> Void in
            let filename = NSUUID().uuidString
            // If someone has sent us >20 MB just fail, it's not worth it
            if data.count > 20*1024*1024 {
                return
            }
            do {
                try data.write(to: self.pathForFile(filename))
            } catch {
                NSLog("Couldn't write downloaded data")
            }
            
            // Pop it into CoreData
            let dbmo = NSEntityDescription.insertNewObject(forEntityName: "DownloadedBinary", into: self.session.moc) as! DownloadedBinaryMO
            dbmo.url = url
            dbmo.localPath = filename
            self.session.persist()
            
            // Raise an event so any image views know the data is available now
            self.session.events.downloadBinaryFinished
                .dispatchValue(value: DownloadBinaryFinishedEvent(url: url))
        }
        .always() {
            self.requestedLock.lock()
            self.requested = self.requested.filter { $0 != url }
            self.requestedLock.unlock()
        }
        job.start()
    }
}
