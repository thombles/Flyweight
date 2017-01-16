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

enum NetJobPriority {
    case Low
    case Normal
    case High
}

// NetJobs should be registered here
// This is the source of truth about what jobs are underway and their progress
class NetJobManager {
    let session: Session
    var jobs: [NetJob] = []
    private var requestIdLock = NSLock()
    private var jobsLock = NSLock()
    private var nextId = 1
    
    init(session: Session) {
        self.session = session
    }
    
    private func getNextRequestId() -> Int {
        requestIdLock.lock()
        let requestId = nextId
        nextId += 1
        requestIdLock.unlock()
        return requestId
    }
    
    // Needs to actually do a priority queue
    func queueJob(job: NetJob, priority: NetJobPriority = .Normal) {
        var mutJob = job
        
        jobsLock.lock()
        jobs.append(mutJob)
        jobsLock.unlock()
        
        mutJob.jobCompletionCallback = jobComplete
        mutJob.requestId = getNextRequestId()
        mutJob.start()
    }
    
    func jobComplete(completion: NetJobCompletion) {
        NSLog("NetJobManager: Job finished with success \(completion.success) message \"\(completion.message)\"")
        
        jobsLock.lock()
        jobs = jobs.filter { job in
            job.requestId != completion.job.requestId
        }
        jobsLock.unlock()
    }
}
