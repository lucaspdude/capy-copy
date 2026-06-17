import XCTest
import Carbon
@testable import capy_copy

final class KeyboardShortcutTests: XCTestCase {
    func testDefaultShortcutIsCommandShiftV() {
        let shortcut = KeyboardShortcut.default
        XCTAssertEqual(shortcut.keyCode, Int(kVK_ANSI_V))
        XCTAssertTrue(shortcut.modifierFlags & NSEvent.ModifierFlags.command.rawValue != 0)
        XCTAssertTrue(shortcut.modifierFlags & NSEvent.ModifierFlags.shift.rawValue != 0)
    }

    func testCarbonModifierMapping() {
        let shortcut = KeyboardShortcut(
            keyCode: Int(kVK_ANSI_C),
            modifierFlags: NSEvent.ModifierFlags([.command, .option]).rawValue
        )
        let carbon = shortcut.carbonModifiers
        XCTAssertTrue(carbon & UInt32(cmdKey) != 0)
        XCTAssertTrue(carbon & UInt32(optionKey) != 0)
        XCTAssertFalse(carbon & UInt32(shiftKey) != 0)
        XCTAssertFalse(carbon & UInt32(controlKey) != 0)
    }

    func testDisplayStringFormatsShortcut() {
        let shortcut = KeyboardShortcut(
            keyCode: Int(kVK_ANSI_V),
            modifierFlags: NSEvent.ModifierFlags([.command, .shift]).rawValue
        )
        XCTAssertEqual(shortcut.displayString, "⌘⇧V")
    }

    func testCodableRoundTrip() throws {
        let shortcut = KeyboardShortcut(
            keyCode: Int(kVK_ANSI_1),
            modifierFlags: NSEvent.ModifierFlags.control.rawValue
        )
        let data = try JSONEncoder().encode(shortcut)
        let decoded = try JSONDecoder().decode(KeyboardShortcut.self, from: data)
        XCTAssertEqual(decoded, shortcut)
    }
}
