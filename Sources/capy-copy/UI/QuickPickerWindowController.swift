import AppKit
import SwiftUI

@MainActor
final class QuickPickerWindowController {
    static let shared = QuickPickerWindowController()

    private var panel: NSPanel?
    private var historyStore: HistoryStore?
    private var clipboardMonitor: ClipboardMonitor?
    private var settingsStore: SettingsStore?
    private var keyMonitor: Any?
    private var targetApplication: NSRunningApplication?
    private weak var viewModel: QuickPickerViewModel?

    private init() {}

    func configure(historyStore: HistoryStore, clipboardMonitor: ClipboardMonitor, settingsStore: SettingsStore) {
        self.historyStore = historyStore
        self.clipboardMonitor = clipboardMonitor
        self.settingsStore = settingsStore
    }

    func show(targetApplication: NSRunningApplication? = nil) {
        guard let historyStore = historyStore,
              let clipboardMonitor = clipboardMonitor,
              let settingsStore = settingsStore else {
            assertionFailure("QuickPickerWindowController must be configured before showing.")
            return
        }

        let resolvedTarget = targetApplication ?? NSWorkspace.shared.frontmostApplication
        self.targetApplication = resolvedTarget

        if let panel = panel {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            viewModel?.resetSelection()
            viewModel?.selectedTab = .all
            return
        }

        let viewModel = QuickPickerViewModel(
            historyStore: historyStore,
            clipboardMonitor: clipboardMonitor,
            settingsStore: settingsStore
        )
        self.viewModel = viewModel

        let theme = settingsStore.selectedTheme.definition

        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        let panelHeight = (screenHeight * 2.0 / 3.0).rounded()

        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: panelHeight),
            styleMask: [.titled, .utilityWindow, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.title = "Capy Copy"
        newPanel.titlebarAppearsTransparent = true
        newPanel.titleVisibility = .hidden
        newPanel.isMovableByWindowBackground = true
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.hidesOnDeactivate = true
        newPanel.hasShadow = true
        newPanel.backgroundColor = .clear
        newPanel.isOpaque = false

        let contentView = NSView(frame: newPanel.contentRect(forFrameRect: newPanel.frame))
        contentView.autoresizingMask = [.width, .height]
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = theme.panelCornerRadius
        contentView.layer?.masksToBounds = true
        contentView.layer?.borderWidth = theme.borderWidth
        contentView.layer?.borderColor = NSColor(theme.borderColor).cgColor

        if theme.name == .liquidGlass {
            let visualEffectView = NSVisualEffectView(frame: contentView.bounds)
            visualEffectView.material = .popover
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.state = .active
            visualEffectView.autoresizingMask = [.width, .height]
            contentView.addSubview(visualEffectView)
        } else {
            contentView.layer?.backgroundColor = NSColor(theme.windowBackground).cgColor
        }

        let hostingView = NSHostingView(
            rootView: QuickPickerView(viewModel: viewModel)
        )
        hostingView.frame = contentView.bounds
        hostingView.autoresizingMask = [.width, .height]
        contentView.addSubview(hostingView)

        newPanel.contentView = contentView
        newPanel.center()

        self.panel = newPanel
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let window = event.window, window == self.panel else { return event }
            return self.handleKeyEvent(event) ? nil : event
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func paste(text: String) {
        hide()
        PasteHelper.paste(text: text, to: targetApplication)
    }

    func paste(imageData: Data) {
        hide()
        PasteHelper.paste(imageData: imageData, to: targetApplication)
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let viewModel = viewModel else { return false }
        switch event.keyCode {
        case 126: // up arrow
            viewModel.moveSelection(direction: -1)
            return true
        case 125: // down arrow
            viewModel.moveSelection(direction: 1)
            return true
        case 36, 76: // return / numpad enter
            viewModel.pasteSelected()
            return true
        case 53: // escape
            hide()
            return true
        default:
            return false
        }
    }
}
