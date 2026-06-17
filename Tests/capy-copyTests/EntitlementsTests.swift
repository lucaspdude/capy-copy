import XCTest

/// Smoke tests for the two entitlements files. The actual sandbox effect is
/// verified at runtime (the app launches sandboxed), but these tests catch
/// regressions where the wrong entitlement set is shipped.
final class EntitlementsTests: XCTestCase {
    private let devPath = "capy-copy.entitlements"
    private let productionPath = "capy-copy.production.entitlements"

    // App Sandbox is intentionally disabled: CGEventPost cannot inject
    // keystrokes into other apps while sandboxed, even with Accessibility
    // permission granted. Capy Copy is distributed outside the Mac App Store.
    func test_appSandboxIsDisabled_inBothEntitlementsFiles() throws {
        for path in [devPath, productionPath] {
            let plist = try entitlements(at: path)
            XCTAssertNotEqual(plist["com.apple.security.app-sandbox"] as? Bool, true,
                              "\(path) must not enable app-sandbox so CGEvent paste works")
        }
    }

    func test_allowJitIsRemoved_inBothEntitlementsFiles() throws {
        for path in [devPath, productionPath] {
            let plist = try entitlements(at: path)
            XCTAssertNil(plist["com.apple.security.cs.allow-jit"],
                         "\(path) should not have allow-jit")
        }
    }

    func test_automationAppleEventsIsRemoved_inBothEntitlementsFiles() throws {
        for path in [devPath, productionPath] {
            let plist = try entitlements(at: path)
            XCTAssertNil(plist["com.apple.security.automation.apple-events"],
                         "\(path) should not have automation-apple-events (CGEvent paste is enough)")
        }
    }

    func test_networkClientIsNotGranted() throws {
        for path in [devPath, productionPath] {
            let plist = try entitlements(at: path)
            XCTAssertNil(plist["com.apple.security.network.client"],
                         "\(path) should not have network.client (1.0.0 makes no network calls)")
        }
    }

    func test_productionEntitlements_preserveCloudKitContainer() throws {
        let plist = try entitlements(at: productionPath)
        XCTAssertEqual(plist["com.apple.developer.icloud-services"] as? [String], ["CloudKit"])
        XCTAssertEqual(plist["com.apple.developer.icloud-container-identifiers"] as? [String],
                       ["iCloud.dev.capy-copy"])
    }

    func test_devEntitlements_doNotHaveCloudKit() throws {
        // The dev build is for local development and doesn't need CloudKit;
        // the production entitlements file is selected by package-app.sh
        // when DEVELOPER_ID is set.
        let plist = try entitlements(at: devPath)
        XCTAssertNil(plist["com.apple.developer.icloud-services"],
                     "Dev entitlements should not have CloudKit")
    }

    // Calendar/Reminders access is handled by macOS TCC (Privacy & Security)
    // when the app is not sandboxed, so the sandbox-specific entitlements are
    // intentionally absent.
    func test_calendarAndRemindersSandboxEntitlements_areRemovedInBothFiles() throws {
        for path in [devPath, productionPath] {
            let plist = try entitlements(at: path)
            XCTAssertNil(plist["com.apple.security.personal-information.calendars"],
                         "\(path) should not have sandbox calendar entitlement (not sandboxed)")
            XCTAssertNil(plist["com.apple.security.personal-information.reminders"],
                         "\(path) should not have sandbox reminders entitlement (not sandboxed)")
        }
    }

    // MARK: - Helpers

    private func entitlements(at path: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] ?? [:]
        return plist
    }
}
