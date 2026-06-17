import XCTest
import CryptoKit
@testable import capy_copy

final class HistoryPersistenceTests: XCTestCase {
    private var tempDir: URL!
    private var key: SymmetricKey!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        key = SymmetricKey(size: .bits256)
    }

    override func tearDown() {
        if let tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    func testRoundTrip() async throws {
        let url = tempDir.appendingPathComponent("history.json")
        let persistence = HistoryPersistence(fileURL: url, key: key)

        let items = [
            ClipItem(
                rawText: "Hello world",
                contentType: .text,
                result: "A greeting."
            ),
            ClipItem(
                rawText: "https://example.com",
                contentType: .url,
                timestamp: Date(timeIntervalSince1970: 1_000),
                isLoading: true
            ),
            ClipItem(
                rawText: "1600 Amphitheatre Parkway",
                contentType: .address("1600 Amphitheatre Parkway"),
                result: "Formatted address.",
                errorMessage: "Something went wrong"
            )
        ]

        try await persistence.save(items)
        let loaded = try await persistence.load()

        XCTAssertEqual(loaded, items)
    }

    func testHistoryFileIsNotPlaintext() async throws {
        let url = tempDir.appendingPathComponent("history.json")
        let persistence = HistoryPersistence(fileURL: url, key: key)

        let secret = "super-secret-password-12345"
        let item = ClipItem(rawText: secret, contentType: .text)
        try await persistence.save([item])

        let raw = try Data(contentsOf: url)
        let asString = String(data: raw, encoding: .utf8) ?? ""
        XCTAssertFalse(asString.contains(secret),
                       "History file should not contain the raw clipboard text in plaintext")
    }

    func testHistoryFileIs0600AndExcludedFromBackup() async throws {
        let url = tempDir.appendingPathComponent("history.json")
        let persistence = HistoryPersistence(fileURL: url, key: key)
        try await persistence.save([ClipItem(rawText: "x", contentType: .text)])

        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let perms = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? 0
        XCTAssertEqual(perms & 0o777, 0o600, "History file should be 0600")

        let values = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true,
                       "History file should be excluded from backups")
    }

    func testWrongKeyFailsToLoad() async throws {
        let url = tempDir.appendingPathComponent("history.json")
        let persistence1 = HistoryPersistence(fileURL: url, key: key)
        try await persistence1.save([ClipItem(rawText: "x", contentType: .text)])

        let otherKey = SymmetricKey(size: .bits256)
        let persistence2 = HistoryPersistence(fileURL: url, key: otherKey)
        do {
            _ = try await persistence2.load()
            XCTFail("Loading with a wrong key should throw")
        } catch {
            // Expected — ChaChaPoly authentication fails.
        }
    }

    func testLoadReturnsEmptyWhenFileMissing() async throws {
        let url = tempDir.appendingPathComponent("missing.json")
        let persistence = HistoryPersistence(fileURL: url, key: key)

        let loaded = try await persistence.load()

        XCTAssertTrue(loaded.isEmpty)
    }

    func testStoreEnforcesLimit() async throws {
        let url = tempDir.appendingPathComponent("history.json")
        let persistence = HistoryPersistence(fileURL: url, key: key)
        let store = await HistoryStore(persistence: persistence, maxItems: { 2 })
        try await Task.sleep(nanoseconds: 50_000_000)

        _ = await store.add(rawText: "First", type: .text)
        _ = await store.add(rawText: "Second", type: .text)
        _ = await store.add(rawText: "Third", type: .text)

        let items = await store.items
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].rawText, "Third")
        XCTAssertEqual(items[1].rawText, "Second")
    }

    func testStoreUpdateResultAndClear() async throws {
        let url = tempDir.appendingPathComponent("history.json")
        let persistence = HistoryPersistence(fileURL: url, key: key)
        let store = await HistoryStore(persistence: persistence)
        try await Task.sleep(nanoseconds: 50_000_000)

        let item = await store.add(rawText: "Code snippet", type: .code)
        let addedItems = await store.items
        XCTAssertTrue(addedItems.first?.isLoading == true)

        await store.updateResult(id: item.id, result: "It adds two numbers.")
        let updated = await store.items
        XCTAssertEqual(updated.first?.result, "It adds two numbers.")
        XCTAssertFalse(updated.first?.isLoading == true)
        XCTAssertNil(updated.first?.errorMessage)

        await store.clear()
        let cleared = await store.items
        XCTAssertTrue(cleared.isEmpty)
    }
}
