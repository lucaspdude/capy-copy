import XCTest
import CryptoKit
@testable import capy_copy

final class ClipContentHashTests: XCTestCase {
    func testSameTextProducesSameHash() {
        let a = ClipContentHash.hash(for: "hello", data: nil)
        let b = ClipContentHash.hash(for: "hello", data: nil)
        XCTAssertEqual(a, b)
    }

    func testDifferentInputsProduceDifferentHashes() {
        let textHash = ClipContentHash.hash(for: "hello", data: nil)
        let dataHash = ClipContentHash.hash(for: "", data: Data("hello".utf8))
        XCTAssertNotEqual(textHash, dataHash)
    }
}
