import Foundation
import CryptoKit

/// Persists the clipboard history to a single encrypted file on disk.
///
/// The file format is a `ChaChaPoly.SealedBox.combined` blob containing the
/// JSON encoding of `[ClipItem]`. The encryption key is provided by
/// `HistoryKeyStore` and is per-device (per ADR 0002).
actor HistoryPersistence {
    private let fileURL: URL
    private let key: SymmetricKey
    private let authKey: SymmetricKey

    init(fileURL: URL, key: SymmetricKey) {
        self.fileURL = fileURL
        self.key = key
        self.authKey = HistoryKeyStore.authenticationKey(from: key)
    }

    /// Synchronous read of the file. Safe to call from `HistoryStore.init`:
    /// the file is only ever written via `save()` (which uses `.atomic`), and
    /// we never call this concurrently with `save()` because callers must
    /// have finished construction before any new save is scheduled.
    nonisolated func loadSync() throws -> [ClipItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let blob = try Data(contentsOf: fileURL)
        // File format: 32-byte HMAC tag || ChaChaPoly.SealedBox.combined
        guard blob.count > 32 else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let tag = blob.prefix(32)
        let ciphertext = blob.dropFirst(32)
        let isValid = HMAC<SHA256>.isValidAuthenticationCode(
            tag,
            authenticating: ciphertext,
            using: authKey
        )
        guard isValid else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let box = try ChaChaPoly.SealedBox(combined: ciphertext)
        let plain = try ChaChaPoly.open(box, using: key)
        return try JSONDecoder().decode([ClipItem].self, from: plain)
    }

    func load() async throws -> [ClipItem] {
        try loadSync()
    }

    func save(_ items: [ClipItem]) async throws {
        let data = try JSONEncoder().encode(items)
        let sealed = try ChaChaPoly.seal(data, using: key)
        let mac = HMAC<SHA256>.authenticationCode(
            for: sealed.combined,
            using: authKey
        )
        var blob = Data()
        blob.append(contentsOf: mac)
        blob.append(sealed.combined)

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        try blob.write(to: fileURL, options: [.atomic, .completeFileProtection])
        // Set 0o600 on the file itself.
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)

        // Exclude from Time Machine and iCloud backups.
        var url = fileURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }
}
