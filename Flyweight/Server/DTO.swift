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

class NoticeDTO: Mappable {
    var text: String?
    var truncated: Bool?
    var createdAt: Date?
    var inReplyToStatusId: String?
    var uri: String?
    var source: String?
    var id: Int64?
    var inReplyToUserId: Int64?
    var inReplyToScreenName: String?
    // geo?
    var user: UserDTO?
    var statusnetHtml: String?
    var statusnetConversationId: Int64?
    var statusnetInGroups: Bool?
    var externalUrl: String?
    var inReplyToProfileUrl: String?
    var inReplyToOstatusUri: String?
    // attentions?
    var faveNum: Int64?
    var repeatNum: Int64?
    var isPostVerb: Bool?
    var isLocal: Bool?
    var favorited: Bool?
    var repeated: Bool?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        let createdAtDateFormatter = DateFormatter()
        createdAtDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        createdAtDateFormatter.dateFormat = "E MMM dd HH:mm:ss xxxx yyyy"
        createdAtDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        text <- map["text"]
        truncated <- map["truncated"]
        createdAt <- (map["created_at"], DateFormatterTransform(dateFormatter: createdAtDateFormatter))
        inReplyToStatusId <- map["in_reply_to_status_id"]
        uri <- map["uri"]
        source <- map["source"]
        id <- map["id"]
        inReplyToUserId <- map["in_reply_to_user_id"]
        inReplyToScreenName <- map["in_reply_to_screen_name"]
        // geo?
        user <- map["user"]
        statusnetHtml <- map["statusnet_html"]
        statusnetConversationId <- map["statusnet_conversation_id"]
        statusnetInGroups <- map["statusnet_in_groups"]
        externalUrl <- map["external_url"]
        inReplyToProfileUrl <- map["in_reply_to_profileurl"]
        inReplyToOstatusUri <- map["in_reply_to_ostatus_uri"]
        // attentions?
        faveNum <- map["fave_num"]
        repeatNum <- map["repeat_num"]
        isPostVerb <- map["is_post_verb"]
        isLocal <- map["is_local"]
        favorited <- map["favorited"]
        repeated <- map["repeated"]
    }
}

class UserDTO: Mappable {
    var id: Int64?
    var name: String?
    var screenName: String?
    var location: String?
    var description: String?
    var profileImageUrl: String?
    var profileImageUrlHttps: String?
    var profileImageUrlProfileSize: String?
    var profileImageUrlOriginal: String?
    var groupsCount: Int?
    var linkColor: Bool?
    var backgroundColor: Bool?
    var url: String?
    var protected: Bool?
    var followersCount: Int?
    var friendsCount: Int?
    var createdAt: Date?
    var utcOffset: String?
    var timeZone: String?
    var statusesCount: Int?
    var following: Bool?
    var statusnetBlocking: Bool?
    var notifications: Bool?
    var statusnetProfileUrl: String?
    var coverPhoto: Bool?
    var backgroundImage: Bool?
    var profileLinkColor: Bool?
    var profileBackgroundColor: Bool?
    var profileBannerUrl: Bool?
    var isLocal: Bool?
    var isSilenced: Bool?
    var rights: RightsDTO?
    var isSandboxed: Bool?
    var ostatusUri: String?
    var favoritesCount: Int?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        let createdAtDateFormatter = DateFormatter()
        createdAtDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        createdAtDateFormatter.dateFormat = "E MMM dd HH:mm:ss xxxx yyyy"
        createdAtDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        id <- map["id"]
        name <- map["name"]
        screenName <- map["screen_name"]
        location <- map["location"]
        description <- map["description"]
        profileImageUrl <- map["profile_image_url"]
        profileImageUrlHttps <- map["profile_image_url_https"]
        profileImageUrlProfileSize <- map["profile_image_url_profile_size"]
        profileImageUrlOriginal <- map["profile_image_url_original"]
        groupsCount <- map["groups_count"]
        linkColor <- map["linkcolor"]
        backgroundColor <- map["backgroundcolor"]
        url <- map["url"]
        protected <- map["protected"]
        followersCount <- map["followers_count"]
        friendsCount <- map["friends_count"]
        createdAt <- (map["created_at"], DateFormatterTransform(dateFormatter: createdAtDateFormatter))
        utcOffset <- map["utc_offset"]
        timeZone <- map["time_zone"]
        statusesCount <- map["statuses_count"]
        following <- map["following"]
        statusnetBlocking <- map["statusnet_blocking"]
        notifications <- map["notifications"]
        statusnetProfileUrl <- map["statusnet_profile_url"]
        coverPhoto <- map["cover_photo"]
        backgroundImage <- map["background_image"]
        profileLinkColor <- map["profile_link_color"]
        profileBackgroundColor <- map["profile_background_color"]
        profileBannerUrl <- map["profile_banner_url"]
        isLocal <- map["is_local"]
        isSilenced <- map["is_silenced"]
        rights <- map["rights"]
        isSandboxed <- map["is_sandboxed"]
        ostatusUri <- map["ostatus_uri"]
        favoritesCount <- map["favourites_count"]
    }
}

class RightsDTO: Mappable {
    var deleteUser: Bool?
    var deleteOthersNotice: Bool?
    var silence: Bool?
    var sandbox: Bool?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        deleteUser <- map["delete_user"]
        deleteOthersNotice <- map["delete_others_notice"]
        silence <- map["silence"]
        sandbox <- map["sandbox"]
    }
}
