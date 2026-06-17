import SwiftUI
import AppKit

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private let settingsStore: SettingsStore
    private var window: NSWindow?
    private let onFinish: () -> Void

    init(settingsStore: SettingsStore, onFinish: @escaping () -> Void) {
        self.settingsStore = settingsStore
        self.onFinish = onFinish
        super.init()
    }

    func show() {
        if window == nil {
            buildWindow()
        }

        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.orderOut(nil)
    }

    private func buildWindow() {
        let theme = settingsStore.selectedTheme.definition

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 540),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Capy Copy"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(theme.windowBackground)
        window.isOpaque = theme.name != .liquidGlass
        window.center()
        window.contentView = NSHostingView(
            rootView: OnboardingView(
                settingsStore: settingsStore,
                onFinish: { [weak self] in
                    self?.close()
                    self?.onFinish()
                }
            )
        )
        window.delegate = self
        self.window = window
    }
}
