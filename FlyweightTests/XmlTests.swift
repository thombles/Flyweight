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

class XmlTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    private func loadDataFile(filename: String, ext: String) -> Data {
        // Since it's a test, just explode if it can't load
        let url = Bundle(for: type(of: self)).url(forResource: filename, withExtension: ext)
        return try! Data(contentsOf: url!)
    }
    
    // Generic wrapper for testing the parsing of XML feeds that should succeed
    private func tryParseXml(filename: String, tests: @escaping ([ASEntry]) -> ()) {
        let data = loadDataFile(filename: filename, ext: "xml")
        let exp = expectation(description: "Parsing complete")
        let parser = FeedParser()
        parser.parseEntries(data: data) { entries, error in
            XCTAssert(entries != nil, "Entries should not be nil")
            tests(entries!)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testBasicPost() {
        tryParseXml(filename: "PostNoticeFeed") { entries in
            XCTAssertEqual(entries.count, 1)
            let entry = entries[0]
            XCTAssertTrue(entry.isPost)
            XCTAssertFalse(entry.isReply)
            XCTAssertFalse(entry.isRepeat)
            XCTAssertFalse(entry.isFavourite)
            XCTAssertFalse(entry.isComment)
            XCTAssertFalse(entry.isDelete)
            XCTAssertEqual(entry.objectType, "http://activitystrea.ms/schema/1.0/note")
            XCTAssertEqual(entry.id, "tag:gs1.karp.id.au,2017-01-15:noticeId=13:objectType=note")
            XCTAssertEqual(entry.htmlLink, "https://gs1.karp.id.au/notice/13")
            XCTAssertEqual(entry.statusNetNoticeId, 13)
            XCTAssertEqual(entry.activityVerb, "http://activitystrea.ms/schema/1.0/post")
        }
    }
    
    func testImageAttachment() {
        tryParseXml(filename: "ImageNoticeFeed") { entries in
            XCTAssertEqual(entries.count, 1)
            let entry = entries[0]
            XCTAssertEqual(entry.enclosures.count, 1)
            let enclosure = entry.enclosures[0]
            XCTAssertEqual(enclosure.url, "https://gs1.karp.id.au/file/cc38cb87dc2b955f3b7b6630b2d6e6506df65b4166fbabe8d5a08b27678d4b1c.png")
            XCTAssertEqual(enclosure.mimeType, "image/png")
            XCTAssertEqual(enclosure.length, 32470)
        }
    }
    
}
