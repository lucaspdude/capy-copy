import Foundation
import CryptoKit

enum ClipContentHash {
    static func hash(for rawText: String, data: Data?) -> String {
        var sha = SHA256()
        if let data {
            sha.update(data: Data("capy-copy:data:".utf8))
            sha.update(data: data)
        } else {
            sha.update(data: Data("capy-copy:text:".utf8))
            sha.update(data: Data(rawText.utf8))
        }
        return sha.finalize().compactMap { String(format: "%02x", $0) }.joined()
    }
}
