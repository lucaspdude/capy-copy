import XCTest
import CryptoKit
@testable import capy_copy

@MainActor
final class HistoryStoreTests: XCTestCase {
    private var store: HistoryStore!
    private var persistence: HistoryPersistence!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let key = SymmetricKey(size: .bits256)
        persistence = HistoryPersistence(fileURL: tempDir.appendingPathComponent("history.json"), key: key)
        store = HistoryStore(persistence: persistence, maxItems: { 10 })
    }

    override func tearDown() {
        if let tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    func testAddCreatesLoadingItem() {
        let item = store.add(rawText: "sample", type: .text)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].id, item.id)
        XCTAssertTrue(store.items[0].isLoading)
    }
}
