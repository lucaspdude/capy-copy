import XCTest
import CryptoKit
@testable import capy_copy

@MainActor
final class HistoryStoreDeduplicationTests: XCTestCase {
    private var store: HistoryStore!
    private var persistence: HistoryPersistence!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        persistence = HistoryPersistence(fileURL: tempDir.appendingPathComponent("history.json"), key: SymmetricKey(size: .bits256))
        store = HistoryStore(persistence: persistence, maxItems: { 10 })
    }

    override func tearDown() {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
        super.tearDown()
    }

    func testDuplicateTextUnionsSourceDeviceAndMovesToTop() {
        let first = store.add(rawText: "hello", type: .text)
        XCTAssertEqual(store.items.count, 1)

        let second = store.add(rawText: "hello", type: .text)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].id, first.id)
        XCTAssertTrue(store.items[0].sourceDevices.contains(DeviceIdentity.current.asSource()))
        XCTAssertEqual(second.id, first.id)
    }

    func testDistinctTextCreatesSeparateItems() {
        _ = store.add(rawText: "hello", type: .text)
        _ = store.add(rawText: "world", type: .text)
        XCTAssertEqual(store.items.count, 2)
    }
}
