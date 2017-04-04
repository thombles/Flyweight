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
import ObjectMapper

/*
 * These JSON definitions and comments are taken directly from the Mastodon API documentation
 * https://github.com/tootsuite/mastodon/blob/master/docs/Using-the-API/API.md
 */


/// A user in the fediverse
class AccountMDTO: Mappable {
    /// The ID of the account
    var id: Int64?
    
    /// The username of the account
    var username: String?
    
    /// Equals username for local users, includes @domain for remote ones
    var acct: String?
    
    /// The account's display name
    var displayName: String?
    
    /// Boolean for when the account cannot be followed without waiting for approval first
    var locked: Bool?
    
    /// The time the account was created
    var createdAt: Date?
    
    /// Biography of user
    var note: String?
    
    /// URL of the user's profile page (can be remote)
    var url: String?
    
    /// URL to the avatar image
    var avatar: String?
    
    /// URL to the header image
    var header: String?
    
    /// The number of followers for the account
    var followersCount: Int64?
    
    /// The number of accounts the given account is following
    var followingCount: Int64?
    
    /// The number of statuses the account has made
    var statusesCount: Int64?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        username <- map["username"]
        acct <- map["acct"]
        displayName <- map["display_name"]
        locked <- map["locked"]
        createdAt <- map["date"]
        note <- map["note"]
        url <- map["url"]
        avatar <- map["avatar"]
        header <- map["header"]
        followersCount <- map["followers_count"]
        followingCount <- map["following_count"]
        statusesCount <- map["statuses_count"]
    }
}

/// The software that someone is using to post a particular status
class ApplicationMDTO: Mappable {
    /// Name of the app
    var name: String?
    
    /// Homepage URL of the app
    var website: String?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        name <- map["name"]
        website <- map["website"]
    }
}

/// Media attached to a status
class AttachmentMDTO: Mappable {
    /// ID of the attachment
    var id: Int64?
    
    /// One of: "image", "video", "gifv"
    var type: String?
    
    /// URL of the locally hosted version of the image
    var url: String?
    
    /// For remote images, the remote URL of the original image
    var remoteUrl: String?
    
    /// URL of the preview image
    var previewUrl: String?
    
    /// Shorter URL for the image, for insertion into text (only present on local images)
    var textUrl: String?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        type <- map["type"]
        url <- map["url"]
        remoteUrl <- map["remote_url"]
        previewUrl <- map["preview_url"]
        textUrl <- map["text_url"]
    }
}

/// Honestly not sure what this is. Associated with a status - /api/v1/statuses/<id>/card
class CardMDTO: Mappable {
    /// The url associated with the card
    var url: String?
    
    /// The title of the card
    var title: String?
    
    /// The card description
    var description: String?
    
    /// The image associated with the card, if any
    var image: String?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        url <- map["url"]
        title <- map["title"]
        description <- map["description"]
        image <- map["image"]
    }
}

/// Groupings of the statuses that come before and after the current status in the thread
class ContextMDTO: Mappable {
    /// The ancestors of the status in the conversation, as a list of Statuses
    var ancestors: [StatusMDTO]?
    
    /// The descendants of the status in the conversation, as a list of Statuses
    var descendants: [StatusMDTO]?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        ancestors <- map["ancestors"]
        descendants <- map["descendants"]
    }
}

/// An error result
class ErrorMDTO: Mappable {
    /// A textual description of the error
    var error: String?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        error <- map["error"]
    }
}


class InstanceMDTO: Mappable {
    /// URI of the current instance
    var uri: String?
    
    /// The instance's title
    var title: String?
    
    /// A description for the instance
    var description: String?
    
    /// An email address which can be used to contact the instance administrator
    var email: String?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        uri <- map["uri"]
        title <- map["title"]
        description <- map["description"]
        email <- map["email"]
    }
}

class MentionMDTO: Mappable {
    /// URL of user's profile (can be remote)
    var url: String?
    
    /// The username of the account
    var username: String?
    
    /// Equals username for local users, includes @domain for remote ones
    var acct: String?
    
    /// Account ID
    var id: Int64?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        url <- map["url"]
        username <- map["username"]
        acct <- map["acct"]
        id <- map["id"]
    }
}

class NotificationMDTO: Mappable {
    /// The notification ID
    var id: Int64?
    
    /// One of: "mention", "reblog", "favourite", "follow"
    var type: String?
    
    /// The time the notification was created
    var createdAt: Date?
    
    /// The Account sending the notification to the user
    var account: AccountMDTO?
    
    /// The Status associated with the notification, if applicable
    var status: StatusMDTO?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        type <- map["type"]
        createdAt <- map["createdAt"]
        account <- map["account"]
        status <- map["status"]
    }
}

class RelationshipMDTO: Mappable {
    /// Whether the user is currently following the account
    var following: Bool?
    
    /// Whether the user is currently being followed by the account
    var followedBy: Bool?
    
    /// Whether the user is currently blocking the account
    var blocking: Bool?
    
    /// Whether the user is currently muting the account
    var muting: Bool?
    
    /// Whether the user has requested to follow the account
    var requested: Bool?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        following <- map["following"]
        followedBy <- map["followedBy"]
        blocking <- map["blocking"]
        muting <- map["muting"]
        requested <- map["requested"]
    }
}

class ReportMDTO: Mappable {
    /// The ID of the report
    var id: Int64?
    
    /// The action taken in response to the report
    var actionTaken: String?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        actionTaken <- map["actionTaken"]
    }
}

class ResultsMDTO: Mappable {
    /// An array of matched Accounts
    var accounts: [AccountMDTO]?
    
    /// An array of matchhed Statuses
    var statuses: [StatusMDTO]?
    
    /// An array of matched hashtags, as strings
    var hashtags: [String]?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        accounts <- map["accounts"]
        statuses <- map["statuses"]
        hashtags <- map["hashtags"]
    }
}

class StatusMDTO: Mappable {
    /// The ID of the status
    var id: Int64?
    
    /// A Fediverse-unique resource ID
    var uri: String?
    
    /// URL to the status page (can be remote)
    var url: String?
    
    /// The Account which posted the status
    var account: AccountMDTO?
    
    /// null or the ID of the status it replies to
    var inReplyToId: Int64?
    
    /// null or the ID of the account it replies to
    var inReplyToAccountId: Int64?
    
    /// null or the reblogged Status
    var reblog: StatusMDTO?
    
    /// Body of the status; this will contain HTML (remote HTML already sanitized)
    var content: String?
    
    /// The time the status was created
    var createdAt: Date?
    
    /// The number of reblogs for the status
    var reblogsCount: Int64?
    
    /// The number of favourites for the status
    var favouritesCount: Int64?
    
    /// Whether the authenticated user has reblogged the status
    var reblogged: Bool?
    
    /// Whether the authenticated user has favourited the status
    var favourited: Bool?
    
    /// Whether media attachments should be hidden by default
    var sensitive: Bool?
    
    /// If not empty, warning text that should be displayed before the actual content
    var spoilerText: String?
    
    /// One of: public, unlisted, private, direct
    var visibility: String?
    
    /// An array of Attachments
    var mediaAttachments: [AttachmentMDTO]?
    
    /// An array of Mentions
    var mentions: [MentionMDTO]?
    
    /// An array of Tags
    var tags: [TagMDTO]?
    
    /// Application from which the status was posted
    var application: ApplicationMDTO?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        uri <- map["uri"]
        url <- map["url"]
        account <- map["account"]
        inReplyToId <- map["in_reply_to_id"]
        inReplyToAccountId <- map["in_reply_to_account_id"]
        reblog <- map["reblog"]
        content <- map["content"]
        createdAt <- map["createdAt"]
        reblogsCount <- map["reblogs_count"]
        favouritesCount <- map["favourites_count"]
        reblogged <- map["reblogged"]
        favourited <- map["favourited"]
        sensitive <- map["sensitive"]
        spoilerText <- map["spoiler_text"]
        visibility <- map["visibility"]
        mediaAttachments <- map["media_attachments"]
        mentions <- map["mentions"]
        tags <- map["tags"]
        application <- map["application"]
    }
}

class TagMDTO: Mappable {
    /// The hashtag, not including the preceding #
    var name: String?
    
    /// The URL of the hashtag
    var url: String?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        name <- map["name"]
        url <- map["url"]
    }
}




