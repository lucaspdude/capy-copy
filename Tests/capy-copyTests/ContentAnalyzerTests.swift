import XCTest
@testable import capy_copy

final class ContentAnalyzerTests: XCTestCase {
    func testURLClassification() {
        XCTAssertEqual(ContentAnalyzer.analyze("https://example.com/article"), .url)
        XCTAssertEqual(ContentAnalyzer.analyze("http://localhost:8080"), .url)
    }

    func testCodeClassification() {
        XCTAssertEqual(ContentAnalyzer.analyze("func hello() { return 42 }"), .code)
        XCTAssertEqual(ContentAnalyzer.analyze("const x = 10;"), .code)
        XCTAssertEqual(ContentAnalyzer.analyze("import Foundation\nclass Foo {\n    var x: Int\n}"), .code)
    }

    func testDateClassification() {
        let result = ContentAnalyzer.analyze("Meeting tomorrow at 3pm")
        if case .date = result {
            // expected
        } else {
            XCTFail("Expected .date but got \(result)")
        }
    }

    func testDateClassificationWithTaskKeyword() {
        let result = ContentAnalyzer.analyze("Lembrar de ligar na sexta-feira")
        if case .date = result {
            // expected
        } else {
            XCTFail("Expected .date but got \(result)")
        }
    }

    func testAddressClassification() {
        let result = ContentAnalyzer.analyze("1600 Amphitheatre Parkway, Mountain View, CA")
        if case .address = result {
            // expected
        } else {
            XCTFail("Expected .address but got \(result)")
        }
    }

    func testPlainTextClassification() {
        let longText = "This is a long plain text paragraph that contains no dates, addresses, code, or URLs and should be classified as plain text."
        XCTAssertEqual(ContentAnalyzer.analyze(longText), .text)
    }

    func testDetectedContentIconNames() {
        XCTAssertEqual(DetectedContent.url.iconName, "link")
        XCTAssertEqual(DetectedContent.code.iconName, "curlybraces")
        XCTAssertEqual(DetectedContent.date(Date()).iconName, "calendar")
        XCTAssertEqual(DetectedContent.address("").iconName, "mappin.and.ellipse")
        XCTAssertEqual(DetectedContent.text.iconName, "text.alignleft")
        XCTAssertEqual(DetectedContent.media.iconName, "photo.stack")
    }

    func testMediaIdentification() {
        XCTAssertTrue(DetectedContent.image.isMedia)
        XCTAssertTrue(DetectedContent.video(nil).isMedia)
        XCTAssertTrue(DetectedContent.media.isMedia)
        XCTAssertFalse(DetectedContent.text.isMedia)
        XCTAssertFalse(DetectedContent.date(Date()).isMedia)
    }

    func testDetectedContentCodableRoundTrip() throws {
        let items: [DetectedContent] = [.url, .code, .date(Date(timeIntervalSince1970: 1000)), .address("Home"), .text, .image, .video(nil), .media]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for item in items {
            let data = try encoder.encode(item)
            let decoded = try decoder.decode(DetectedContent.self, from: data)
            XCTAssertEqual(decoded, item)
        }
    }
}
