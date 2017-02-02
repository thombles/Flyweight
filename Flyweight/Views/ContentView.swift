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

class ContentView: UILabel {
    private var links: [LinkAttribute] = []
    
    override func awakeFromNib() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnLabel))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tap)
        self.lineBreakMode = .byWordWrapping
        self.numberOfLines = 0
    }
    
    func tapOnLabel(recognizer: UITapGestureRecognizer) {
        guard let attributedText = self.attributedText else { return }
        
        if recognizer.state == .ended {
            // Set up a text container matching the properties and contents of this label
            let location = recognizer.location(in: self)
            let formatted = NSMutableAttributedString(attributedString: attributedText)
            formatted.addAttributes([NSFontAttributeName: self.font], range: NSMakeRange(0, formatted.string.characters.count))
            let layoutManager = NSLayoutManager()
            let textStorage = NSTextStorage(attributedString: formatted)
            textStorage.addLayoutManager(layoutManager)
            let textContainer = NSTextContainer(size: self.bounds.size)
            textContainer.maximumNumberOfLines = self.numberOfLines
            textContainer.lineBreakMode = self.lineBreakMode
            textContainer.lineFragmentPadding = 0
            layoutManager.addTextContainer(textContainer)
            
            // Ask what the corresponding character would be at the point we click on
            // Note that this will get "stuck" on the end of the string for the remainder of the label
            // To prevent terminating links leaking into empty space we append a zero width space when we set the string
            let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            
            // If the touch corresponds to any of the contained links, open the URL
            for l in links {
                if characterIndex >= l.range.startIndex && characterIndex < l.range.endIndex {
                    // Open the URL in Safari
                    if let url = URL(string: l.url) {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            
            // TODO probably need to let the touch fall through somehow when I have tap-for-conversation
            
            // Also TODO someday some of these links will be special and do in-app functions instead
            
            // TODO use the started and ended to visibly show the press on the URL
        }
        
        
    }
    
    var htmlContent: String? {
        get {
            return self.text
        }
        set {
            guard let html = newValue else { return }
            // Add an zero width space to the end because this will allow the URL character matching to terminate
            let parser = HtmlDisplayParser(html: html + "\u{200B}", fontSize: self.font.pointSize)
            let (att, links) = parser.makeAttributedString()
            self.attributedText = att
            self.links = links
        }
    }
}
