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

public class ParseError: Error {
    let reason: String
    init (reason: String) {
        self.reason = reason
    }
}

public class ASEntry {
    var objectType: String?
    var id: String?
    var title: String?
    var htmlContent: String?
    var htmlLink: String?
    var statusNetNoticeId: Int64?
    var activityVerb: String?
    var published: Date?
    var updated: Date?
    var author: ASAuthor?
    var conversationUrl: String?
    var conversationNumber: Int64?
    var conversationThread: String?
    var categories: [String] = []
    var enclosures: [ASEnclosure] = []
    var client: String?
    
    var isPost = false
    var isComment = false
    var isFavourite = false
    var isRepeat = false
    var isDelete = false
    
    var isReply = false
    var inReplyToNoticeRef: String?
    var inReplyToNoticeUrl: String?
    var repeatOfNoticeId: Int64?
    var object: ASEntry?
}

public class ASAuthor {
    var objectType: String?
    var uri: String?
    var username: String?
    var userPage: String?
    var avatars: [ASAvatar] = []
    var displayName: String?
    var statusNetUserId: Int64?
}

public class ASAvatar {
    var mimeType: String?
    var width: Int64?
    var height: Int64?
    var url: String?
}

public class ASEnclosure {
    var url: String?
    var mimeType: String?
    var length: Int64?
}

