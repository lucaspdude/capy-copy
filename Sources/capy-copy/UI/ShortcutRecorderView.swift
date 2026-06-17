import SwiftUI
import AppKit
import Carbon

/// A view that captures a single key combination from the user.
struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var shortcut: KeyboardShortcut

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.recorderDelegate = context.coordinator
        view.shortcut = shortcut
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.shortcut = shortcut
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(shortcut: $shortcut)
    }

    final class Coordinator: ShortcutRecorderDelegate {
        @Binding var shortcut: KeyboardShortcut

        init(shortcut: Binding<KeyboardShortcut>) {
            self._shortcut = shortcut
        }

        func shortcutDidChange(_ shortcut: KeyboardShortcut) {
            self.shortcut = shortcut
        }
    }
}

protocol ShortcutRecorderDelegate: AnyObject {
    func shortcutDidChange(_ shortcut: KeyboardShortcut)
}

final class ShortcutRecorderNSView: NSTextField {
    weak var recorderDelegate: ShortcutRecorderDelegate?

    var shortcut: KeyboardShortcut = .default {
        didSet { updateDisplay() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isEditable = false
        isSelectable = false
        alignment = .center
        bezelStyle = .roundedBezel
        focusRingType = .default
        setAccessibilityRole(.textField)
        setAccessibilityLabel("Global shortcut recorder")
        updateDisplay()
    }

    private func updateDisplay() {
        stringValue = shortcut == KeyboardShortcut(keyCode: 0, modifierFlags: 0)
            ? "Click to record shortcut"
            : shortcut.displayString
    }

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            .subtracting([.capsLock, .function, .numericPad, .help])

        // Ignore lone modifier keys.
        if event.keyCode == UInt16(kVK_Command) ||
            event.keyCode == UInt16(kVK_Shift) ||
            event.keyCode == UInt16(kVK_Option) ||
            event.keyCode == UInt16(kVK_Control) {
            return
        }

        guard !modifiers.isEmpty else { return }

        let newShortcut = KeyboardShortcut(
            keyCode: Int(event.keyCode),
            modifierFlags: modifiers.rawValue
        )
        shortcut = newShortcut
        recorderDelegate?.shortcutDidChange(newShortcut)
    }

    override func flagsChanged(with event: NSEvent) { /* no-op */ }

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        stringValue = "Recording…"
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        updateDisplay()
        return super.resignFirstResponder()
    }
}
