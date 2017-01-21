//
//  ContentAttributeTests.swift
//  Flyweight
//
//  Created by Thomas Karpiniec on 22/1/17.
//  Copyright © 2017 Thomas Karpiniec. All rights reserved.
//

import XCTest
@testable import Flyweight

class ContentAttributeTests: XCTestCase {
    func testPlainText() {
        let input = "An ordinary string."
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(input, att.string)
        XCTAssertEqual(links.count, 0)
    }
    
    func testStartTag() {
        let input = "<b>Hello</b> text"
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "Hello text")
        XCTAssertEqual(links.count, 0)
    }
    
    func testEndTag() {
        let input = "Hello <b>text</b>"
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "Hello text")
        XCTAssertEqual(links.count, 0)
    }
    
    func testNested() {
        let input = "My <b>very <i>audacious</i> test</b>."
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "My very audacious test.")
        XCTAssertEqual(links.count, 0)
    }
    
    func testOpenTag() {
        let input = "Some <b>word</b whoops missed a bracket"
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "Some word")
        XCTAssertEqual(links.count, 0)
    }
    
    func testEmptyAnchor() {
        let input = "Hello <a>link</a>."
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "Hello link.")
        XCTAssertEqual(links.count, 0)
    }
    
    func testBasicAnchor() {
        let input = "Here is: <a href=\"https://git.gnu.io/\">GNU social</a>"
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "Here is: GNU social")
        //                          0123456789012345678
        XCTAssertEqual(links.count, 1)
        let link = links[0]
        XCTAssertEqual(link.url, "https://git.gnu.io/")
        XCTAssertEqual(link.startIndex, 9)
        XCTAssertEqual(link.endIndex, 19)
    }
    
    func testNestedInAnchor() {
        let input = "Here is: <a href=\"https://git.gnu.io/\"><b>GNU</b> social</a>"
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "Here is: GNU social")
        //                          0123456789012345678
        XCTAssertEqual(links.count, 1)
        let link = links[0]
        XCTAssertEqual(link.url, "https://git.gnu.io/")
        XCTAssertEqual(link.startIndex, 9)
        XCTAssertEqual(link.endIndex, 19)
    }
    
    func testTwoAnchors() {
        let input = "<a href=\"https://git.gnu.io/\">GNU social</a>; <a href=\"https://sfconservancy.org/\">SFC</a>"
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "GNU social; SFC")
        //                          0123456789012345
        XCTAssertEqual(links.count, 2)
        let link1 = links[0]
        XCTAssertEqual(link1.url, "https://git.gnu.io/")
        XCTAssertEqual(link1.startIndex, 0)
        XCTAssertEqual(link1.endIndex, 10)
        let link2 = links[1]
        XCTAssertEqual(link2.url, "https://sfconservancy.org/")
        XCTAssertEqual(link2.startIndex, 12)
        XCTAssertEqual(link2.endIndex, 15)
    }
    
    func testUnterminatedAnchor() {
        let input = "I am typing and <a href=\"https://git.gnu.io/\">the desc never ends"
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "I am typing and the desc never ends")
        //                          01234567890123456789012345678901234
        XCTAssertEqual(links.count, 1)
        let link = links[0]
        XCTAssertEqual(link.url, "https://git.gnu.io/")
        XCTAssertEqual(link.startIndex, 16)
        XCTAssertEqual(link.endIndex, 35)
    }
    
    func testOpenTagInsideAnchor() {
        let input = "Link <a href=\"https://git.gnu.io/\">Git <b>Hello</b fish example"
        let (att, links) = ContentView.convertHtmlToAttributedString(html: input)
        XCTAssertEqual(att.string, "Link Git Hello")
        //                          012345678901234
        XCTAssertEqual(links.count, 1)
        let link = links[0]
        XCTAssertEqual(link.url, "https://git.gnu.io/")
        XCTAssertEqual(link.startIndex, 5)
        XCTAssertEqual(link.endIndex, 14)
    }
}
