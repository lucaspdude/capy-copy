import Foundation
import CloudKit
import os.log

private let syncStateLoggerSubsystem = Bundle.main.bundleIdentifier ?? "dev.capy-copy"

actor SyncState {
    private let logger = Logger(subsystem: syncStateLoggerSubsystem, category: "SyncState")
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() -> CKSyncEngine.State.Serialization? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data)
    }

    func save(_ state: CKSyncEngine.State.Serialization?) {
        guard let state else {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }
        do {
            let data = try JSONEncoder().encode(state)
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: Data.WritingOptions.atomic)
        } catch {
            logger.error("Failed to save sync state: \(error.localizedDescription, privacy: .public)")
        }
    }
}
