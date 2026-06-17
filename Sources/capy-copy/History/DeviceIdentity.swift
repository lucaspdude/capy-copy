import Foundation
import SystemConfiguration

extension ProcessInfo {
    /// The user-friendly computer name from the dynamic store.
    var computerName: String? {
        guard let store = SCDynamicStoreCreate(nil, "capy-copy" as CFString, nil, nil) else {
            return nil
        }
        return SCDynamicStoreCopyComputerName(store, nil) as String?
    }
}

struct DeviceIdentity: Codable, Equatable, Hashable {
    static let defaultsKey = "capy-copy.deviceIdentity"

    var id: String
    var name: String

    static var current: DeviceIdentity {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode(DeviceIdentity.self, from: data) {
            return saved
        }
        let fresh = DeviceIdentity(
            id: UUID().uuidString,
            name: Host.current().localizedName
                ?? ProcessInfo.processInfo.computerName
                ?? "Mac"
        )
        save(fresh)
        return fresh
    }

    static func save(_ identity: DeviceIdentity) {
        if let data = try? JSONEncoder().encode(identity) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    func asSource() -> DeviceSource {
        DeviceSource(id: id, name: name)
    }
}

struct DeviceSource: Codable, Hashable {
    let id: String
    var name: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DeviceSource, rhs: DeviceSource) -> Bool {
        lhs.id == rhs.id
    }
}
