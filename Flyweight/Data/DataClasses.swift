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

@objc(AccountMO)
public class AccountMO: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var server: String
    @NSManaged var type: Int32 //todo make this an enum
    @NSManaged var username: String
    
    // Non-optionals need values
    override public func awakeFromInsert() {
        id = 0
        server = ""
        type = 0
        username = ""
    }
}

@objc(NoticeInGSTimelineMO)
public class NoticeInGSTimelineMO: NSManagedObject {
    @NSManaged var gsTimeline: GSTimelineMO?
    @NSManaged var noticeId: Int64
    @NSManaged var notice: NoticeMO?
    @NSManaged var previousNotice: NoticeMO?

    override public func awakeFromInsert() {
        noticeId = 0
    }
}


