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

struct EmbeddedLink {
    var startIndex: Int
    var endIndex: Int
    var url: String
}

class ContentView: UILabel {
    fileprivate var links: [EmbeddedLink] = []
    
    var htmlContent: String? {
        get {
            return self.text
        }
        set {
            guard let html = newValue else { return }
            let (att, links) = ContentView.convertHtmlToAttributedString(html: html)
            self.attributedText = att
            self.links = links
        }
    }
    
    class func convertHtmlToAttributedString(html: String) -> (NSAttributedString, [EmbeddedLink]) {
        // Just detect anchors for now and strip out any other tags
        // Pretty crusty but I'm not using a WKWebView just to display a notice
        // I only want to allow very specific things through anyway
        // TODO Nicer code
        
        var unattOutput = "" // unformatted version of the eventual displayed string
        var links: [EmbeddedLink] = []
        
        let ns = html as NSString
        var index = 0
        while index < ns.length {
            let nextBit = ns.substring(with: NSMakeRange(index, min(3, ns.length - index)))
            var nextChar = (nextBit as NSString).substring(with: NSMakeRange(0, 1))
            if nextBit == "<a " {
                // The index in the output string we're at now will be our start index for the link
                let startOfAnchor = (unattOutput as NSString).length
                
                var nextSnippet = ""
                // Process anchor tag in full - index should be moved up to just before </a>,
                // which will be handled by ordinary tag skip
                
                // Get up to either the href or the end of the <a> if it has no href
                repeat {
                    index += 1
                    nextChar = ns.substring(with: NSMakeRange(index, 1))
                    nextSnippet = ns.substring(with: NSMakeRange(index, 6))
                } while nextSnippet != "href=\"" && nextChar != ">" && index < ns.length
                
                // If we hit a > there was no href. Skip over it and return to normal parsing
                if nextChar == ">" {
                    index += 1
                    continue
                } else {
                    index += 6
                }
                
                // Otherwise we're now looking at the URL
                var url = ""
                repeat {
                    nextChar = ns.substring(with: NSMakeRange(index, 1))
                    if nextChar != "\"" {
                        url += nextChar
                    }
                    index += 1
                } while nextChar != "\"" && index < ns.length
                
                // Now get to the end of the anchor tag
                repeat {
                    nextChar = ns.substring(with: NSMakeRange(index, 1))
                    index += 1
                } while nextChar != ">" && index < ns.length
                
                // Now we're looking just past the ">" and it will be followed by the link description
                var partOfDesc = true
                repeat {
                    nextChar = ns.substring(with: NSMakeRange(index, 1))
                    nextSnippet = ns.substring(with: NSMakeRange(index, min(4, ns.length - index)))
                    if nextSnippet == "</a>" {
                        break
                    } else if nextChar == "<" { // some other tag - skip over it
                        partOfDesc = false
                    } else if nextChar == ">" && !partOfDesc {
                        partOfDesc = true
                    } else if partOfDesc {
                        unattOutput += nextChar
                    }
                    index += 1
                } while index < ns.length
                
                // Let the ordinary tag skip take care of the next <
                let endOfAnchor = (unattOutput as NSString).length
                
                // Do some basic validity checks. Weird stuff won't work, I don't mind at this point
                let urlns = (url as NSString)
                if endOfAnchor != startOfAnchor && (urlns.hasPrefix("http://") || urlns.hasPrefix("https://")) {
                    let link = EmbeddedLink(startIndex: startOfAnchor, endIndex: endOfAnchor, url: url)
                    links.append(link)
                }
                
                // All done
            } else if nextChar == "<" {
                // Skip until end of tag
                repeat {
                    nextChar = ns.substring(with: NSMakeRange(index, 1))
                    index += 1
                } while nextChar != ">" && index < ns.length
            } else {
                unattOutput += nextChar
                index += 1
            }
        }
        
        // Take the unattributed form and wrap it in an attributed string
        let att = NSMutableAttributedString(string: unattOutput)
        
        // Now apply our link formatting - actual URLs will be detected by touch coordinates
        let linkColour = UIColor.init(red: 0.1, green: 0.2, blue: 1.0, alpha: 1.0)
        for l in links {
            att.addAttribute(NSForegroundColorAttributeName, value: linkColour, range: NSMakeRange(l.startIndex, l.endIndex - l.startIndex))
        }
        
        return (att, links)
    }
}
