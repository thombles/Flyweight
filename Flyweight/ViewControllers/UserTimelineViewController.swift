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

class UserTimelineViewController : TimelineViewController {
    
    var username = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // In the future this could be any user and instance. For now it is our instance + me
        username = session?.userManager.getCurrentUsername() ?? ""
    }
    
    override func doRefresh() -> Promise<RefreshResult>? {
        if let timeline = doGetTimeline() {
            return session?.gsTimelineManager.refreshTimeline(timeline: timeline, lastNotice: self.notices.first, screenName: username)
        }
        return nil
    }
    
    override func doLoadMore() -> Promise<LoadMoreResult>? {
        if let timeline = doGetTimeline() {
            return session?.gsTimelineManager.loadMoreTimeline(timeline: timeline, maxNotice: self.notices.last, screenName: username)
        }
        return nil
    }
    
    override func doGetTimeline() -> GSTimelineMO? {
        return session?.gsTimelineManager.getUserTimeline(instance: nil, username: username)
    }
}
