import XCTest
@testable import capy_copy

final class FoundationModelClientTests: XCTestCase {
    func testCapabilityCheckExists() {
        _ = FoundationModelCapability.isSupported
    }

    func testMockClientReturnsResult() async throws {
        let client = MockFoundationModelClient()
        let result = try await client.analyze("Dinner tomorrow at 7pm", contentType: .text)
        XCTAssertFalse(result.explanation.isEmpty)
    }

    func testMockClientSkipsMedia() async throws {
        let client = MockFoundationModelClient()
        let result = try await client.analyze("", contentType: .image)
        XCTAssertEqual(result.category, .image)
        XCTAssertTrue(result.explanation.isEmpty)
    }

    func testMockClientUsesStub() async throws {
        let client = MockFoundationModelClient(stub: AnalysisResult(category: .date(Date()), explanation: "stubbed"))
        let result = try await client.analyze("anything", contentType: .text)
        XCTAssertEqual(result.explanation, "stubbed")
    }
}
