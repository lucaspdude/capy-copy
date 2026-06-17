import XCTest
import Carbon
@testable import capy_copy

@MainActor
final class SettingsStoreTests: XCTestCase {
    private let defaults = UserDefaults.standard
    private let originalShortcutKey = "shortcut"

    override func setUp() {
        super.setUp()
        defaults.removeObject(forKey: originalShortcutKey)
    }

    override func tearDown() {
        defaults.removeObject(forKey: originalShortcutKey)
        super.tearDown()
    }

    func testDefaultShortcut() {
        let store = SettingsStore()
        XCTAssertEqual(store.shortcut, KeyboardShortcut.default)
    }

    func testCustomShortcutPersists() {
        let first = SettingsStore()
        first.shortcut = KeyboardShortcut(
            keyCode: Int(kVK_ANSI_C),
            modifierFlags: NSEvent.ModifierFlags([.command, .option]).rawValue
        )

        let second = SettingsStore()
        XCTAssertEqual(second.shortcut.keyCode, Int(kVK_ANSI_C))
        XCTAssertEqual(second.shortcut.modifierFlags, NSEvent.ModifierFlags([.command, .option]).rawValue)
    }

    // MARK: - maxHistoryItems clamp (F-11)

    func testMaxHistoryItemsIsClampedOnRead() {
        defaults.set(99_999, forKey: "maxHistoryItems")
        let store = SettingsStore()
        XCTAssertLessThanOrEqual(store.maxHistoryItems, 500)
        defaults.removeObject(forKey: "maxHistoryItems")
    }

    func testMaxHistoryItemsClampsNegativeToZero() {
        defaults.set(-5, forKey: "maxHistoryItems")
        let store = SettingsStore()
        XCTAssertGreaterThanOrEqual(store.maxHistoryItems, 0)
        defaults.removeObject(forKey: "maxHistoryItems")
    }

    func testMaxHistoryItemsClampsOnSet() {
        let store = SettingsStore()
        store.maxHistoryItems = 100_000
        XCTAssertEqual(store.maxHistoryItems, 500)
        store.maxHistoryItems = -1
        XCTAssertEqual(store.maxHistoryItems, 0)
        store.maxHistoryItems = 42
        XCTAssertEqual(store.maxHistoryItems, 42)
    }
}
