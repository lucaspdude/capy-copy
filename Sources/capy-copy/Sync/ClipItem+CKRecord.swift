import Foundation
import CloudKit

// MARK: - CloudKit mapping
//
// Synced fields (stored in the CKRecord):
//   - rawText           → encryptedValues["rawText"]
//   - timestamp         → ["timestamp"]
//   - contentType       → ["contentTypeData"] (JSON-encoded DetectedContent)
//   - sourceDevices     → ["sourceDevicesData"] (JSON-encoded Set<DeviceSource>)
//   - isFavorite        → ["isFavorite"]
//   - result            → ["result"] (AI analysis; only applied locally when autoAnalyze is enabled)
//
// Intentionally local-only / recomputed (not sent to CloudKit):
//   - errorMessage      (local-only UI state)
//   - isLoading         (local-only UI state)
//   - imageData         (image sync is disabled in v1)
//   - imageFilename     (image sync is disabled in v1)
//
// NOTE: clip content sync is deferred to 1.1.0+ (see ADR 0002). This file is
// currently a scaffolding for the future implementation; the conversion
// methods are unused in 1.0.0.

private enum CKKeys {
    static let rawText = "rawText"
    static let timestamp = "timestamp"
    static let contentTypeData = "contentTypeData"
    static let sourceDevicesData = "sourceDevicesData"
    static let isFavorite = "isFavorite"
    static let result = "result"
}

private let zoneID = CKRecordZone.ID(zoneName: "HistoryZone")

extension ClipItem {
    func cloudKitRecordID() -> CKRecord.ID {
        CKRecord.ID(recordName: contentHash, zoneID: zoneID)
    }

    func cloudKitRecord() -> CKRecord? {
        guard contentType != .image else { return nil }

        let record = CKRecord(recordType: "ClipItem", recordID: cloudKitRecordID())
        record[CKKeys.timestamp] = timestamp
        record[CKKeys.contentTypeData] = try? JSONEncoder().encode(contentType)
        record[CKKeys.sourceDevicesData] = try? JSONEncoder().encode(sourceDevices)
        record[CKKeys.isFavorite] = isFavorite ? 1 : 0
        record[CKKeys.result] = result
        record.encryptedValues[CKKeys.rawText] = rawText
        return record
    }

    init(cloudKitRecord record: CKRecord) throws {
        let id = UUID()
        let rawText = record.encryptedValues[CKKeys.rawText] as? String ?? ""
        let timestamp = record[CKKeys.timestamp] as? Date ?? Date()
        let contentType: DetectedContent
        if let data = record[CKKeys.contentTypeData] as? Data {
            contentType = (try? JSONDecoder().decode(DetectedContent.self, from: data)) ?? .text
        } else {
            contentType = .text
        }
        let sourceDevices: Set<DeviceSource>
        if let data = record[CKKeys.sourceDevicesData] as? Data {
            sourceDevices = (try? JSONDecoder().decode(Set<DeviceSource>.self, from: data)) ?? []
        } else {
            sourceDevices = []
        }
        let isFavorite = (record[CKKeys.isFavorite] as? Int) == 1
        let analysisResult: String
        if UserDefaults.standard.bool(forKey: "autoAnalyze"),
           let result = record[CKKeys.result] as? String {
            analysisResult = result
        } else {
            analysisResult = ""
        }

        self.init(
            id: id,
            rawText: rawText,
            contentType: contentType,
            timestamp: timestamp,
            contentHash: record.recordID.recordName,
            sourceDevices: sourceDevices,
            result: analysisResult,
            isFavorite: isFavorite
        )
    }
}
