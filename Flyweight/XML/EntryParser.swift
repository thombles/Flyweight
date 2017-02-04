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

class EntryParser: NSObject, XMLParserDelegate {
    
    let namespace: String
    let tagName: String
    let parser: XMLParser?
    let completion: (ASEntry?) -> Void
    let entry = ASEntry()
    var currentTag: String?
    var tagText = FeedParser.Attrs()
    var childParser: NSObject?
    
    static let PostVerb = "http://activitystrea.ms/schema/1.0/post"
    static let CommentVerb = "http://activitystrea.ms/schema/1.0/comment"
    static let FavouriteVerb = "http://activitystrea.ms/schema/1.0/favorite"
    static let ShareVerb = "http://activitystrea.ms/schema/1.0/share"
    static let FollowVerb = "http://activitystrea.ms/schema/1.0/follow"
    static let DeleteVerb = "delete" // odd but true
    
    init(parser: XMLParser?, namespace: String, tagName: String, attrs: FeedParser.Attrs, completion: @escaping (ASEntry?) -> Void) {
        self.parser = parser
        self.completion = completion
        self.namespace = namespace
        self.tagName = tagName
        // No attributes we're concerned about in <entry>
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if namespaceURI == self.namespace && elementName == tagName {
            
            // Move the strings from the dict into the actual elements
            entry.objectType = tagText["objectType"]
            entry.id = tagText["id"]
            entry.title = tagText["title"]
            entry.htmlContent = tagText["htmlContent"]
            entry.activityVerb = tagText["activityVerb"]
            entry.published = FeedParser.dateFromTimestamp(string: tagText["published"])
            entry.updated = FeedParser.dateFromTimestamp(string: tagText["updated"])
            if entry.statusNetNoticeId == nil {
                entry.statusNetNoticeId = Int64(tagText["noticeId"] ?? "")
            }
            
            // Some verb processing to help downstream user process it
            entry.isFavourite = (entry.activityVerb == EntryParser.FavouriteVerb)
            entry.isRepeat = (entry.activityVerb == EntryParser.ShareVerb)
            entry.isPost = (entry.activityVerb == EntryParser.PostVerb)
            entry.isComment = (entry.activityVerb == EntryParser.CommentVerb)
            entry.isDelete = (entry.activityVerb == EntryParser.DeleteVerb)
            
            completion(entry)
        } else {
            currentTag = nil
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if let tag = processTag(namespace: namespaceURI, element: elementName, attrs: attributeDict) {
            currentTag = tag
        }
    }
    
    func processTag(namespace: String?, element: String, attrs: FeedParser.Attrs) -> String? {
        guard let namespace = namespace else { return nil }
 
        if namespace == FeedParser.ActivityStreamNS && element == "object-type" { return "objectType" }
        if namespace == FeedParser.AtomNS && element == "id" { return "id" }
        if namespace == FeedParser.AtomNS && element == "title" { return "title" }
        if namespace == FeedParser.AtomNS && element == "content" { return "htmlContent" } // assume HTML
        if namespace == FeedParser.AtomNS && element == "link"
                && attrs["rel"] == "alternate" && attrs["type"] == "text/html" {
            self.entry.htmlLink = attrs["href"]
        }
        if namespace == FeedParser.AtomNS /* wrong but anyway */ && element == "status_net" {
            if entry.statusNetNoticeId == nil { // can be set multiple ways
                entry.statusNetNoticeId = Int64(attrs["notice_id"] ?? "")
            }
        }
        if namespace == FeedParser.StatusNetNS && element == "notice_id" {
            if entry.statusNetNoticeId == nil {
                return "noticeId"
            }
        }
        if namespace == FeedParser.ActivityStreamNS && element == "verb" { return "activityVerb" }
        if namespace == FeedParser.AtomNS && element == "published" { return "published" }
        if namespace == FeedParser.AtomNS && element == "updated" { return "updated" }
        if namespace == FeedParser.AtomNS && element == "author" {
            let authorParser = AuthorParser(attrs: attrs) { author in
                self.entry.author = author
                self.parser?.delegate = self
            }
            childParser = authorParser
            self.parser?.delegate = authorParser // let it take over for now
        }
        if namespace == FeedParser.AtomNS && element == "source" {
            let sourceParser = SourceParser() {
                self.parser?.delegate = self
            }
            childParser = sourceParser
            self.parser?.delegate = sourceParser
        }
        if namespace == FeedParser.ActivityStreamNS && element == "object" {
            let entryParser = EntryParser(parser: parser, namespace: FeedParser.ActivityStreamNS, tagName: "object", attrs: attrs) { entry in
                self.entry.object = entry
                self.parser?.delegate = self
            }
            childParser = entryParser
            self.parser?.delegate = entryParser
        }
        if namespace == FeedParser.OStatusNS && element == "conversation" {
            self.entry.conversationUrl = attrs["href"]
            self.entry.conversationNumber = Int64(attrs["local_id"] ?? "")
            self.entry.conversationThread = attrs["ref"]
        }
        if namespace == FeedParser.AtomNS && element == "category" {
            if let term = attrs["term"] {
                self.entry.categories.append(term)
            }
        }
        if namespace == FeedParser.StatusNetNS && element == "notice_info" {
            if self.entry.statusNetNoticeId == nil { // can be set two ways
                self.entry.statusNetNoticeId = Int64(attrs["local_id"] ?? "")
            }
            self.entry.client = attrs["source"]
            self.entry.repeatOfNoticeId = Int64(attrs["repeat_of"] ?? "")
        }
        if namespace == FeedParser.ThreadNS && element == "in-reply-to" {
            self.entry.isReply = true
            self.entry.inReplyToNoticeRef = attrs["ref"]
            self.entry.inReplyToNoticeUrl = attrs["href"]
        }
        if namespace == FeedParser.AtomNS && element == "link" && attrs["rel"] == "enclosure" {
            let enclosure = ASEnclosure()
            enclosure.url = attrs["href"]
            enclosure.mimeType = attrs["type"]
            enclosure.length = Int64(attrs["length"] ?? "")
            entry.enclosures.append(enclosure)
        }
        
        return nil
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let tag = currentTag {
            tagText[tag] = (tagText[tag] ?? "") + string
        }
    }


}
