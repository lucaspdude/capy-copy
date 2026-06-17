import Foundation
import Security
import CryptoKit

/// Manages the symmetric encryption key used by `HistoryPersistence` to encrypt
/// the local clipboard history at rest.
///
/// The key is generated lazily on first use and stored in the Keychain with
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` and no
/// `kSecAttrSynchronizable` flag. This means:
///
/// - The key never leaves the device (no iCloud Keychain sync).
/// - CloudKit (used for metadata-only sync in 1.0.0) holds ciphertext only.
/// - Reinstalling the app, signing out of iCloud, or wiping the Keychain
///   renders the existing history file unrecoverable; this is an accepted
///   trade-off documented in `docs/adr/0002-history-encryption-per-device.md`.
enum HistoryKeyStore {
    private static let service = "dev.capy-copy"
    private static let account = "history.key"

    enum KeyStoreError: Error {
        case unexpectedStatus(OSStatus)
    }

    /// Returns the existing key, creating one if none exists. Throws if the
    /// Keychain is unavailable (e.g. on a misconfigured system).
    static func loadOrCreate() throws -> SymmetricKey {
        if let existing = try? fetchKey() { return existing }
        let key = SymmetricKey(size: .bits256)
        try storeKey(key)
        return key
    }

    /// Derives a separate authentication key from the storage key using HKDF.
    /// Using the same key for both encryption and authentication is an
    /// anti-pattern; this split is cheap and gives defence-in-depth against
    /// any future change to the cipher choice.
    static func authenticationKey(from storageKey: SymmetricKey) -> SymmetricKey {
        let info = Data("capy-copy.history.hmac.v1".utf8)
        let salt = Data("capy-copy.history.hmac.salt".utf8)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: storageKey,
            info: info,
            outputByteCount: 32
        )
    }

    private static func fetchKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            // No kSecAttrSynchronizable → key stays on this device.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecReturnData as String: true
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeyStoreError.unexpectedStatus(status)
        }
        return SymmetricKey(data: data)
    }

    private static func storeKey(_ key: SymmetricKey) throws {
        let data = key.withUnsafeBytes { Data($0) }
        let attrs: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(attrs as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeyStoreError.unexpectedStatus(status)
        }
    }
}
