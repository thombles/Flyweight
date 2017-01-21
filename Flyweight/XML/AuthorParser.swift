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

class AuthorParser: NSObject, XMLParserDelegate {
    
    let completion: (ASAuthor?) -> Void
    let author = ASAuthor()
    var currentTag: String?
    var tagText = FeedParser.Attrs()
    var childParser: NSObject?
    
    init(attrs: FeedParser.Attrs, completion: @escaping (ASAuthor?) -> Void) {
        self.completion = completion
        // No attrs in <author>
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if namespaceURI == FeedParser.AtomNS && elementName == "author" {
            author.objectType = tagText["objectType"]
            author.uri = tagText["uri"]
            author.username = tagText["username"]
            author.displayName = tagText["displayName"]
            author.bio = tagText["bio"]
            completion(author)
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
        if namespace == FeedParser.AtomNS && element == "uri" { return "uri" }
        if namespace == FeedParser.AtomNS && element == "name" { return "username" }
        if namespace == FeedParser.PoCoNS && element == "displayName" { return "displayName" }
        if namespace == FeedParser.AtomNS && element == "summary" { return "bio" }
        
        if namespace == FeedParser.AtomNS && element == "link"
            && attrs["rel"] == "alternate" && attrs["type"] == "text/html" {
            author.userPage = attrs["href"]
        }
        if namespace == FeedParser.AtomNS && element == "link"
            && attrs["rel"] == "avatar" {
            let av = ASAvatar()
            av.mimeType = attrs["type"]
            av.width = Int64(attrs["media:width"] ?? "")
            av.height = Int64(attrs["media:height"] ?? "")
            av.url = attrs["href"]
            author.avatars.append(av)
        }
        if namespace == FeedParser.StatusNetNS && element == "profile_info" {
            author.statusNetUserId = Int64(attrs["local_id"] ?? "")
        }
        
        return nil
    }

    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let tag = currentTag {
            tagText[tag] = (tagText[tag] ?? "") + string
        }
    }
}
