import XCTest
@testable import capy_copy

final class DeviceIdentityTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: DeviceIdentity.defaultsKey)
    }

    func testCurrentGeneratesStableID() {
        let first = DeviceIdentity.current
        let second = DeviceIdentity.current
        XCTAssertEqual(first.id, second.id)
        XCTAssertFalse(first.name.isEmpty)
    }

    func testCurrentPersistsNameChange() {
        var identity = DeviceIdentity.current
        identity.name = "Studio Mac"
        DeviceIdentity.save(identity)

        let loaded = DeviceIdentity.current
        XCTAssertEqual(loaded.name, "Studio Mac")
        XCTAssertEqual(loaded.id, identity.id)
    }
}
