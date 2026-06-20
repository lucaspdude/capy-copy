import SwiftUI
import AppKit
import Combine

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let hotKeyManager: HotKeyManager

    private let historyStore: HistoryStore
    private let clipboardMonitor: ClipboardMonitor
    private let settingsStore: SettingsStore
    private let modelClient: FoundationModelClient?
    private var analysisQueue: Task<Void, Never>?
    private var shortcutCancellable: AnyCancellable?
    private var previousFrontmostApplication: NSRunningApplication?

    init(historyStore: HistoryStore,
         clipboardMonitor: ClipboardMonitor,
         settingsStore: SettingsStore,
         modelClient: FoundationModelClient?) {
        self.historyStore = historyStore
        self.clipboardMonitor = clipboardMonitor
        self.settingsStore = settingsStore
        self.modelClient = modelClient

        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.hotKeyManager = HotKeyManager()

        super.init()

        configureStatusItem()
        configureHotKey()
        trackFrontmostApplication()
    }

    // MARK: - Configuration

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        let icon = Bundle.module.image(forResource: "capy_menubar")
        icon?.size = NSSize(width: 18, height: 18)
        icon?.isTemplate = true

        button.image = icon
        button.imagePosition = .imageOnly
        button.toolTip = "Capy Copy"
        button.setAccessibilityLabel(NSLocalizedString(
            "app.name",
            bundle: .module,
            comment: ""
        ))
        button.action = #selector(statusItemClicked)
        button.target = self
    }

    private func configureHotKey() {
        hotKeyManager.onHotKey = { [weak self] in
            // The global hotkey fires while another app is frontmost, so
            // capture the current frontmost app as the paste target.
            let target = NSWorkspace.shared.frontmostApplication
            self?.showQuickPicker(targetApplication: target)
        }

        registerHotKey()

        shortcutCancellable = settingsStore.$shortcut
            .dropFirst()
            .sink { [weak self] _ in
                self?.registerHotKey()
            }
    }

    private func registerHotKey() {
        _ = hotKeyManager.register(
            keyCode: UInt32(settingsStore.shortcut.keyCode),
            modifiers: settingsStore.shortcut.carbonModifiers
        )
    }

    /// Keep track of the most recently active "regular" app that is not
    /// Capy Copy itself. When the user opens the picker by clicking the
    /// menu-bar icon, `NSWorkspace.shared.frontmostApplication` may already
    /// have switched to Capy Copy, so we use the previously recorded app as
    /// the paste target.
    private func trackFrontmostApplication() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activeApplicationChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func activeApplicationChanged(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        guard app.activationPolicy == .regular else { return }
        guard app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        previousFrontmostApplication = app
    }

    // MARK: - Actions

    @objc private func statusItemClicked() {
        // Use the app that was frontmost before Capy Copy took focus.
        showQuickPicker(targetApplication: previousFrontmostApplication)
    }

    private func showQuickPicker(targetApplication: NSRunningApplication?) {
        QuickPickerWindowController.shared.show(targetApplication: targetApplication)
    }

    // MARK: - Clipboard Handling

    func handleNewClipboardContent(_ text: String) {
        guard settingsStore.autoAnalyze else { return }
        guard !historyStore.items.contains(where: { $0.rawText == text }) else { return }

        let contentType = ContentAnalyzer.analyze(text)
        guard settingsStore.shouldAnalyze(contentType) else { return }

        let item = historyStore.add(rawText: text, type: contentType)

        analysisQueue = Task { [weak self, previous = analysisQueue] in
            _ = await previous?.result
            guard let self, let modelClient = self.modelClient else { return }
            do {
                let result = try await modelClient.analyze(text, contentType: contentType)
                await self.historyStore.updateResult(id: item.id, result: result.explanation)
            } catch {
                await self.historyStore.updateError(id: item.id, message: error.localizedDescription)
            }
        }
    }
}
