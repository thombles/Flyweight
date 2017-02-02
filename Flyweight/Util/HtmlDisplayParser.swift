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

struct LinkAttribute {
    var range: NSRange
    var url: String
}

fileprivate enum StyleType {
    case Bold
    case Italic
    case Underline
}

fileprivate struct StyleAttribute {
    var type: StyleType
    var range: NSRange
}

// Sometimes more convenient
extension NSRange {
    var startIndex: Int {
        return location
    }
    var endIndex: Int {
        return location + length
    }
}

/// Utility class to take raw HTML content from GNU social and convert it to an NSAttributedString and list of tappable links
class HtmlDisplayParser {
    
    /// Raw string being processed
    private let html: String
    /// Font size for display
    private let fontSize: CGFloat
    
    // State during parsing
    private var styleAttributes: [StyleAttribute] = []
    private var linkAttributes: [LinkAttribute] = []
    private var boldStartPosition: Int?
    private var italicStartPosition: Int?
    private var underlineStartPosition: Int?
    private var anchorStartPosition: Int?
    private var anchorUrl: String?
    
    private var position = 0
    private var unattributedText = ""
    private let linkColour = UIColor.init(red: 0.1, green: 0.2, blue: 1.0, alpha: 1.0)
    
    /// Initialise a parser with an HTML content string from a GNU social server
    init(html: String, fontSize: CGFloat) {
        self.html = html
        self.fontSize = fontSize
    }
    
    /// Process the HTML content, stripping out unwanted tags and returning an attributed string.
    /// Also returns the URL ranges so that taps on the text can be handled.
    func makeAttributedString() -> (NSAttributedString, [LinkAttribute]) {
        let nsHtml = html as NSString
        position = 0
        unattributedText = ""
        
        // Process until position reaches the end
        while position < nsHtml.length {
            position += normalStep(nextChar: nsHtml.substring(with: NSMakeRange(position, 1)) as NSString,
                                   remainder: nsHtml.substring(from: position) as NSString)
        }
        
        // If any attributes are open, close them off here
        if let start = boldStartPosition {
            styleAttributes.append(StyleAttribute(type: .Bold, range: rangeWithStart(start)))
        }
        if let start = italicStartPosition {
            styleAttributes.append(StyleAttribute(type: .Italic, range: rangeWithStart(start)))
        }
        if let start = underlineStartPosition {
            styleAttributes.append(StyleAttribute(type: .Underline, range: rangeWithStart(start)))
        }
        if let start = anchorStartPosition, let url = anchorUrl {
            linkAttributes.append(LinkAttribute(range: rangeWithStart(start), url: url))
        }
        
        // At this point all the attributes should be in our state
        let att = NSMutableAttributedString(string: unattributedText)
        
        // Apply colour to links
        for l in linkAttributes {
            att.addAttribute(NSForegroundColorAttributeName, value: linkColour, range: l.range)
        }
        // Apply other styles
        for s in styleAttributes {
            switch s.type {
            case .Bold:
                att.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFont(ofSize: fontSize), range: s.range)
            case .Italic:
                att.addAttribute(NSFontAttributeName, value: UIFont.italicSystemFont(ofSize: fontSize), range: s.range)
            case .Underline:
                att.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.patternSolid, range: s.range)
            }
        }
        
        return (att, linkAttributes)
    }
    
    /// Bite off a chunk of the remaining HTML content to process. Returns how many characters to increment.
    private func normalStep(nextChar: NSString, remainder: NSString) -> Int {
        // Handle end of styles first
        if remainder.hasPrefix("</b>") {
            if let start = boldStartPosition {
                styleAttributes.append(StyleAttribute(type: .Bold, range: rangeWithStart(start)))
                boldStartPosition = nil
                return 4
            }
        }
        if remainder.hasPrefix("</i>") {
            if let start = italicStartPosition {
                styleAttributes.append(StyleAttribute(type: .Italic, range: rangeWithStart(start)))
                italicStartPosition = nil
                return 4
            }
        }
        if remainder.hasPrefix("</em>") {
            if let start = italicStartPosition {
                styleAttributes.append(StyleAttribute(type: .Italic, range: rangeWithStart(start)))
                italicStartPosition = nil
                return 5
            }
        }
        if remainder.hasPrefix("</u>") {
            if let start = underlineStartPosition {
                styleAttributes.append(StyleAttribute(type: .Underline, range: rangeWithStart(start)))
                underlineStartPosition = nil
                return 4
            }
        }
        
        // Handle start of styles
        if remainder.hasPrefix("<b>") {
            if boldStartPosition == nil {
                boldStartPosition = outputPosition
            }
            return 3
        }
        if remainder.hasPrefix("<i>") {
            if italicStartPosition == nil {
                italicStartPosition = outputPosition
            }
            return 3
        }
        if remainder.hasPrefix("<em>") {
            if italicStartPosition == nil {
                italicStartPosition = outputPosition
            }
            return 4
        }
        if remainder.hasPrefix("<u>") {
            if underlineStartPosition == nil {
                underlineStartPosition = outputPosition
            }
            return 3
        }
        
        // Handle end of an anchor tag
        if remainder.hasPrefix("</a>") {
            if let start = anchorStartPosition, let url = anchorUrl {
                linkAttributes.append(LinkAttribute(range: rangeWithStart(start), url: url))
                anchorStartPosition = nil
                anchorUrl = nil
            }
            return 4
        }
        
        // Handle newlines in various forms
        if remainder.hasPrefix("<br>") {
            unattributedText += "\n"
            return 4
        }
        if remainder.hasPrefix("<br/>") {
            unattributedText += "\n"
            return 5
        }
        if remainder.hasPrefix("<br />") {
            unattributedText += "\n"
            return 6
        }
        
        // Handle start of an anchor tag (in a separate function because it's complicated)
        if remainder.hasPrefix("<a ") {
            return startAnchor(remainder: remainder)
        }
        
        // Special cases now handled
        // If it looks like another tag, skip past it
        if nextChar == "<" {
            return skipPastTag(remainder: remainder)
        }
        
        // If it's an XML entity, substitute those instead
        if let size = handleEntity(entity: "&amp;", replacement: "&", remainder: remainder) {
            return size
        }
        if let size = handleEntity(entity: "&quot;", replacement: "\"", remainder: remainder) {
            return size
        }
        if let size = handleEntity(entity: "&apos;", replacement: "'", remainder: remainder) {
            return size
        }
        if let size = handleEntity(entity: "&lt;", replacement: "<", remainder: remainder) {
            return size
        }
        if let size = handleEntity(entity: "&gt;", replacement: ">", remainder: remainder) {
            return size
        }
        
        // Otherwise it's a plain old character. Copy it to the output buffer and move on.
        unattributedText += nextChar as String
        return 1
    }
    
    /// Handle the more complicated case when we are looking an opening anchor <a> tag and need to extract href.
    private func startAnchor(remainder: NSString) -> Int {
        let endOfTag = remainder.range(of: ">")
        if endOfTag.location == NSNotFound {
            // Open tag to end of string. Broken input and we're done here
            return remainder.length
        }
        // Save the end of the tag because we will always skip to there when we're done here, whether or not we find a valid link
        let endOfTagPos = endOfTag.location + 1
        
        // Isolate the "<a ... >" tag
        let openingTag = remainder.substring(with: NSMakeRange(0, endOfTagPos)) as NSString
        
        // Find the target URL if it exists. If it doesn't, bail out
        let hrefRange = openingTag.range(of: "href=\"")
        if hrefRange.location == NSNotFound {
            return endOfTagPos
        }
        
        // Take the actual URL and find the closing "; bail out if we don't find it
        let postHrefString = openingTag.substring(from: hrefRange.location + hrefRange.length) as NSString
        let endOfHrefRange = postHrefString.range(of: "\"")
        if endOfHrefRange.location == NSNotFound {
            return endOfTagPos
        }
        
        // If we're still here we have something in the URL position
        let possibleUrl = postHrefString.substring(with: NSMakeRange(0, endOfHrefRange.location)) as NSString
        // Make sure it looks vaguely like a URL
        if possibleUrl.hasPrefix("http://") || possibleUrl.hasPrefix("https://") {
            anchorStartPosition = outputPosition
            anchorUrl = possibleUrl as String
        }
        
        // Whether or not we recognised the URL as valid, jump to the end of the opening tag
        return endOfTagPos
    }
    
    /// Test if we're dealing with a "&foo;" type entity and apply the appropriate substitution if so
    /// Returns the number of characters to skip in the input
    private func handleEntity(entity: String, replacement: String, remainder: NSString) -> Int? {
        if remainder.hasPrefix(entity) {
            unattributedText += replacement
            return entity.characters.count
        }
        return nil
    }
    
    /// The current position in the output unattributed string
    private var outputPosition: Int {
        return unattributedText.characters.count
    }
    
    /// Return the number of characters required to jump past the current HTML tag
    private func skipPastTag(remainder: NSString) -> Int {
        let range = remainder.range(of: ">")
        if range.location == NSNotFound {
            return remainder.length
        }
        return range.location + 1
    }
    
    /// Create a range from the given start point to the end of the current unattributed text buffer
    private func rangeWithStart(_ start: Int) -> NSRange {
        return NSMakeRange(start, unattributedText.characters.count - start)
    }
}
