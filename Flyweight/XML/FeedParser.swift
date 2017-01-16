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

public class FeedParser: NSObject, XMLParserDelegate {
    public typealias ParseCallback = (([ASEntry]?, ParseError?)->(Void))
    public typealias Attrs = [String : String]
    
    static let AtomNS = "http://www.w3.org/2005/Atom"
    static let StatusNetNS = "http://status.net/schema/api/1/"
    static let PoCoNS = "http://portablecontacts.net/spec/1.0"
    static let ActivityStreamNS = "http://activitystrea.ms/spec/1.0/"
    static let OStatusNS = "http://ostatus.org/schema/1.0"
    static let ThreadNS = "http://purl.org/syndication/thread/1.0"
    
    var parser: XMLParser?
    var callback: ParseCallback?
    var parsedEntries: [ASEntry] = []
    var childParser: NSObject? // strong reference so it doesn't get dealloced
    
    public func parseEntries(data: Data, callback: @escaping ParseCallback) {
        parsedEntries = []
        self.callback = callback
        parser = XMLParser(data: data)
        if let p = parser {
            self.parser = p
            p.delegate = self
            p.shouldProcessNamespaces = true
            p.shouldReportNamespacePrefixes = false
            p.shouldResolveExternalEntities = false
            p.parse()
        } else {
            callback(nil, ParseError(reason: "Could not make parser"))
        }
    }
    
    public func parserDidStartDocument(_ parser: XMLParser) {
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        callback?(parsedEntries, nil)
    }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if namespaceURI == FeedParser.AtomNS && elementName == "entry" {
            let entryParser = EntryParser(parser: parser, namespace: FeedParser.AtomNS, tagName: "entry", attrs: attributeDict) { entry in
                if let e = entry {
                    self.parsedEntries.append(e)
                }
                self.parser?.delegate = self
            }
            childParser = entryParser
            self.parser?.delegate = entryParser // let it take over for now
        }
        
    }
    
    static func dateFromTimestamp(string: String?) -> Date? {
        guard let string = string else { return nil }
        // Put this in its own function in case we need to tweak later
        // Hopefully ISO8601 will cover everything we need
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}
