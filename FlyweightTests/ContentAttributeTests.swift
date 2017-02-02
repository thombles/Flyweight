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

import XCTest
@testable import Flyweight


class ContentAttributeTests: XCTestCase {
    private func makeParserForString(_ input: String) -> HtmlDisplayParser {
        return HtmlDisplayParser(html: input, fontSize: 10)
    }
    
    func testPlainText() {
        let input = "An ordinary string."
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(input, att.string)
        XCTAssertEqual(links.count, 0)
    }
    
    func testStartTag() {
        let input = "<b>Hello</b> text"
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "Hello text")
        XCTAssertEqual(links.count, 0)
    }
    
    func testEndTag() {
        let input = "Hello <b>text</b>"
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "Hello text")
        XCTAssertEqual(links.count, 0)
    }
    
    func testNested() {
        let input = "My <b>very <i>audacious</i> test</b>."
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "My very audacious test.")
        XCTAssertEqual(links.count, 0)
    }
    
    func testOpenTag() {
        let input = "Some <b>word</b whoops missed a bracket"
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "Some word")
        XCTAssertEqual(links.count, 0)
    }
    
    func testEmptyAnchor() {
        let input = "Hello <a>link</a>."
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "Hello link.")
        XCTAssertEqual(links.count, 0)
    }
    
    func testBasicAnchor() {
        let input = "Here is: <a href=\"https://git.gnu.io/\">GNU social</a>"
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "Here is: GNU social")
        //                          0123456789012345678
        XCTAssertEqual(links.count, 1)
        let link = links[0]
        XCTAssertEqual(link.url, "https://git.gnu.io/")
        XCTAssertEqual(link.range.startIndex, 9)
        XCTAssertEqual(link.range.endIndex, 19)
    }
    
    func testNestedInAnchor() {
        let input = "Here is: <a href=\"https://git.gnu.io/\"><b>GNU</b> social</a>"
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "Here is: GNU social")
        //                          0123456789012345678
        XCTAssertEqual(links.count, 1)
        let link = links[0]
        XCTAssertEqual(link.url, "https://git.gnu.io/")
        XCTAssertEqual(link.range.startIndex, 9)
        XCTAssertEqual(link.range.endIndex, 19)
    }
    
    func testTwoAnchors() {
        let input = "<a href=\"https://git.gnu.io/\">GNU social</a>; <a href=\"https://sfconservancy.org/\">SFC</a>"
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "GNU social; SFC")
        //                          0123456789012345
        XCTAssertEqual(links.count, 2)
        let link1 = links[0]
        XCTAssertEqual(link1.url, "https://git.gnu.io/")
        XCTAssertEqual(link1.range.startIndex, 0)
        XCTAssertEqual(link1.range.endIndex, 10)
        let link2 = links[1]
        XCTAssertEqual(link2.url, "https://sfconservancy.org/")
        XCTAssertEqual(link2.range.startIndex, 12)
        XCTAssertEqual(link2.range.endIndex, 15)
    }
    
    func testUnterminatedAnchor() {
        let input = "I am typing and <a href=\"https://git.gnu.io/\">the desc never ends"
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "I am typing and the desc never ends")
        //                          01234567890123456789012345678901234
        XCTAssertEqual(links.count, 1)
        let link = links[0]
        XCTAssertEqual(link.url, "https://git.gnu.io/")
        XCTAssertEqual(link.range.startIndex, 16)
        XCTAssertEqual(link.range.endIndex, 35)
    }
    
    func testOpenTagInsideAnchor() {
        let input = "Link <a href=\"https://git.gnu.io/\">Git <b>Hello</b fish example"
        let parser = makeParserForString(input)
        let (att, links) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "Link Git Hello")
        //                          012345678901234
        XCTAssertEqual(links.count, 1)
        let link = links[0]
        XCTAssertEqual(link.url, "https://git.gnu.io/")
        XCTAssertEqual(link.range.startIndex, 5)
        XCTAssertEqual(link.range.endIndex, 14)
    }
    
    func testNewline() {
        let input = "foo<br />bar"
        let parser = makeParserForString(input)
        let (att, _) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "foo\nbar")
    }
    
    func testHTMLEntity() {
        let input = "Hi &quot;Bob&quot; &amp; &quot;Sally&quot;"
        let parser = makeParserForString(input)
        let (att, _) = parser.makeAttributedString()
        XCTAssertEqual(att.string, "Hi \"Bob\" & \"Sally\"")
    }
}
