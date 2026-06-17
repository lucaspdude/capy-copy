import XCTest
@testable import capy_copy

final class ClipboardFilterTests: XCTestCase {
    func testEmptyStringIsIgnored() {
        XCTAssertEqual(ClipboardFilter.decision(for: ""), .ignore(.empty))
        XCTAssertEqual(ClipboardFilter.decision(for: "   "), .ignore(.empty))
        XCTAssertEqual(ClipboardFilter.decision(for: "\n\t"), .ignore(.empty))
    }

    func testShortTextIsIgnored() {
        XCTAssertEqual(ClipboardFilter.decision(for: "hi"), .ignore(.tooShort))
        XCTAssertEqual(ClipboardFilter.decision(for: "abcd"), .ignore(.tooShort))
    }

    func testLongPlainTextIsAccepted() {
        XCTAssertEqual(ClipboardFilter.decision(for: "The quick brown fox jumps over the lazy dog"), .accept)
    }

    func testPasswordLikeStringIsIgnored() {
        XCTAssertEqual(ClipboardFilter.decision(for: "P@ssw0rd"), .ignore(.likelySecret))
        XCTAssertEqual(ClipboardFilter.decision(for: "Ab1!xy9Z"), .ignore(.likelySecret))
    }

    func testSecretRulesRespectLengthBounds() {
        XCTAssertEqual(ClipboardFilter.decision(for: "Ab1!"), .ignore(.tooShort))
        XCTAssertEqual(ClipboardFilter.decision(for: String(repeating: "A", count: 65)), .accept)
    }

    func testURLWithTokenIsAccepted() {
        XCTAssertEqual(ClipboardFilter.decision(for: "https://example.com/api?token=Ab1!xy9Z"), .accept)
        XCTAssertEqual(ClipboardFilter.decision(for: "http://example.com/path"), .accept)
    }

    func testSpacesPreventSecretFlag() {
        XCTAssertEqual(ClipboardFilter.decision(for: "Hello World 123!"), .accept)
    }

    // MARK: - Entropy heuristic (F-08)

    func testLongHighEntropyTokenIsFiltered() {
        // 40-char base64 string, no spaces, high entropy
        let token = "aGVsbG93b3JsZHRoaXNpc2F0ZXN0MTIzNDU2Nzg5MA"
        XCTAssertEqual(ClipboardFilter.decision(for: token), .ignore(.likelySecret))
    }

    func testLongRandomAlphanumericIsFiltered() {
        // 40-char random alphanumeric, no spaces, 2 character classes but
        // high entropy — the entropy heuristic catches what the class rule misses.
        let chars = Array("abcdefghijklmnopqrstuvwxyz0123456789")
        let token = String((0..<40).map { _ in chars.randomElement()! })
        XCTAssertEqual(ClipboardFilter.decision(for: token), .ignore(.likelySecret))
    }

    func testLongEnglishSentenceIsAccepted() {
        let sentence = "The quick brown fox jumps over the lazy dog and then runs across the field"
        XCTAssertEqual(ClipboardFilter.decision(for: sentence), .accept)
    }

    func testEntropyHelperShannonOfUniformDistribution() {
        // A uniform distribution over 16 distinct chars in a 64-char string
        // has entropy log2(16) = 4.0. This is the threshold; > 4 is a secret.
        let alphabet = Array("0123456789abcdef")
        var chars: [Character] = []
        for i in 0..<64 {
            chars.append(alphabet[(i + i / 16) % 16])
        }
        let s = String(chars)
        let h = EntropyHeuristic.shannon(s)
        XCTAssertEqual(h, 4.0, accuracy: 0.0001)
        XCTAssertFalse(EntropyHeuristic.looksLikeSecret(s))
    }
}
