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


extension NoticeMO {

    @NSManaged public var client: String?
    @NSManaged public var conversationId: Int64
    @NSManaged public var conversationThread: String?
    @NSManaged public var conversationUrl: String?
    @NSManaged public var faveNum: Int64
    @NSManaged public var favouritedHtmlLink: String?
    @NSManaged public var favouritedStatusNetId: Int64
    @NSManaged public var htmlContent: String?
    @NSManaged public var htmlLink: String?
    @NSManaged public var inReplyToNoticeTag: String?
    @NSManaged public var inReplyToNoticeUrl: String?
    @NSManaged public var isDelete: Bool
    @NSManaged public var isFavourite: Bool
    @NSManaged public var isOwnPost: Bool
    @NSManaged public var isRepeat: Bool
    @NSManaged public var isReply: Bool
    @NSManaged public var published: NSDate?
    @NSManaged public var repeatNum: Int64
    @NSManaged public var server: String?
    @NSManaged public var statusNetId: Int64
    @NSManaged public var tag: String?
    @NSManaged public var lastUpdated: NSDate?
    @NSManaged public var repeatedNotice: NoticeMO?
    @NSManaged public var user: UserMO?

}
