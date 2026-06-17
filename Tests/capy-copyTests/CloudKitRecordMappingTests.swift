import XCTest
import CloudKit
@testable import capy_copy

final class CloudKitRecordMappingTests: XCTestCase {
    func testRoundTripTextClip() throws {
        let item = ClipItem(rawText: "hello", contentType: .text)
        let record = try XCTUnwrap(item.cloudKitRecord())
        XCTAssertEqual(record.recordID.recordName, item.contentHash)
        XCTAssertNotNil(record["contentTypeData"] as? Data)

        let restored = try ClipItem(cloudKitRecord: record)
        XCTAssertEqual(restored.rawText, item.rawText)
        XCTAssertEqual(restored.contentHash, item.contentHash)
        XCTAssertEqual(restored.contentType, item.contentType)
    }

    func testSourceDevicesRoundTrip() throws {
        let devices: Set<DeviceSource> = [
            DeviceSource(id: "device-a", name: "Mac A"),
            DeviceSource(id: "device-b", name: "Mac B")
        ]
        let item = ClipItem(
            rawText: "shared",
            contentType: .text,
            sourceDevices: devices
        )
        let record = try XCTUnwrap(item.cloudKitRecord())
        let restored = try ClipItem(cloudKitRecord: record)
        XCTAssertEqual(restored.sourceDevices, devices)
    }

    func testIsFavoriteRoundTrip() throws {
        let item = ClipItem(rawText: "important", contentType: .text, isFavorite: true)
        let record = try XCTUnwrap(item.cloudKitRecord())
        XCTAssertEqual(record["isFavorite"] as? Int, 1)

        let restored = try ClipItem(cloudKitRecord: record)
        XCTAssertTrue(restored.isFavorite)
    }

    func testRawTextStoredInEncryptedValues() throws {
        let item = ClipItem(rawText: "secret", contentType: .text)
        let record = try XCTUnwrap(item.cloudKitRecord())

        XCTAssertEqual(record.encryptedValues["rawText"] as? String, "secret")
        XCTAssertNil(record["rawText"] as? String)
    }

    func testInvalidRecordDataFallsBackSafely() throws {
        let zoneID = CKRecordZone.ID(zoneName: "HistoryZone")
        let record = CKRecord(
            recordType: "ClipItem",
            recordID: CKRecord.ID(recordName: "invalid-hash", zoneID: zoneID)
        )
        record["contentTypeData"] = Data([0xFF, 0xFF])
        record["sourceDevicesData"] = Data([0xAA, 0xBB])

        let restored = try ClipItem(cloudKitRecord: record)
        XCTAssertEqual(restored.contentType, .text)
        XCTAssertTrue(restored.sourceDevices.isEmpty)
        XCTAssertEqual(restored.contentHash, "invalid-hash")
    }

    func testImageItemExcludedFromRecordGeneration() {
        let item = ClipItem(
            rawText: "",
            contentType: .image,
            imageData: Data([0xFF])
        )
        XCTAssertNil(item.cloudKitRecord())
    }
}
