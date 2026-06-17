import Foundation
import Carbon
import AppKit

/// Represents a global keyboard shortcut by its physical key code and modifier flags.
struct KeyboardShortcut: Codable, Equatable {
    let keyCode: Int
    let modifierFlags: UInt

    init(keyCode: Int, modifierFlags: UInt) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }

    /// The default shortcut: Command+Shift+V.
    static let `default` = KeyboardShortcut(
        keyCode: Int(kVK_ANSI_V),
        modifierFlags: NSEvent.ModifierFlags([.command, .shift]).rawValue
    )

    /// Modifier flags converted to Carbon constants for `RegisterEventHotKey`.
    var carbonModifiers: UInt32 {
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }

    /// Human-readable shortcut, e.g. "⌘⇧V".
    var displayString: String {
        var result = ""
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
        if flags.contains(.command) { result += "⌘" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.control) { result += "⌃" }
        result += keyDisplayName
        return result
    }

    private var keyDisplayName: String {
        if let special = Self.specialKeyDisplayNames[keyCode] {
            return special
        }

        // Letters and digits.
        let ansiLetters: [Int: String] = [
            kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
            kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
            kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
            kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
            kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
            kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
            kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z"
        ]
        if let letter = ansiLetters[keyCode] {
            return letter
        }

        let digits: [Int: String] = [
            kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
            kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
            kVK_ANSI_8: "8", kVK_ANSI_9: "9"
        ]
        if let digit = digits[keyCode] {
            return digit
        }

        return "(\(keyCode))"
    }

    private static let specialKeyDisplayNames: [Int: String] = [
        kVK_Return: "↩",
        kVK_Tab: "⇥",
        kVK_Space: "Space",
        kVK_Delete: "⌫",
        kVK_Escape: "⎋",
        kVK_Command: "⌘",
        kVK_Shift: "⇧",
        kVK_Option: "⌥",
        kVK_Control: "⌃",
        kVK_RightArrow: "→",
        kVK_LeftArrow: "←",
        kVK_DownArrow: "↓",
        kVK_UpArrow: "↑",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟"
    ]
}
