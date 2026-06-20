import Foundation
import CryptoKit

@MainActor
final class AppAssembly {
    static let shared = AppAssembly()

    let settingsStore: SettingsStore
    let historyStore: HistoryStore
    let clipboardMonitor: ClipboardMonitor
    let menuBarController: MenuBarController
    private var onboardingWindowController: OnboardingWindowController?

    private init() {
        let settings = SettingsStore()
        self.settingsStore = settings

        let supportURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("capy-copy", isDirectory: true)
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".capy-copy", isDirectory: true)

        let persistence: HistoryPersistence
        do {
            let key = try HistoryKeyStore.loadOrCreate()
            persistence = HistoryPersistence(
                fileURL: supportURL.appendingPathComponent("history.json"),
                key: key
            )
        } catch {
            // Keychain unavailable is extremely rare on a signed app. Fall back
            // to a session-only key so the app still starts; nothing is
            // persisted in that case, and the next launch retries the Keychain.
            let key = SymmetricKey(size: .bits256)
            persistence = HistoryPersistence(
                fileURL: supportURL.appendingPathComponent("history.json"),
                key: key
            )
        }
        let syncState = SyncState(fileURL: supportURL.appendingPathComponent("sync-state"))
        let store = HistoryStore(persistence: persistence, maxItems: { settings.maxHistoryItems })
        self.historyStore = store

        let monitor = ClipboardMonitor()
        self.clipboardMonitor = monitor

        QuickPickerWindowController.shared.configure(
            historyStore: self.historyStore,
            clipboardMonitor: monitor,
            settingsStore: settings
        )

        let controller = MenuBarController(
            historyStore: self.historyStore,
            clipboardMonitor: monitor,
            settingsStore: settings
        )
        self.menuBarController = controller

        monitor.onNewContent = { [weak controller] text in
            controller?.handleNewClipboardContent(text)
        }

        monitor.onNewImage = { [weak self] data in
            self?.historyStore.addImage(data: data)
        }

        monitor.onNewVideo = { [weak self] url in
            self?.historyStore.addVideo(url: url)
        }

        monitor.onNewMedia = { [weak self] contentType in
            self?.historyStore.add(rawText: "", type: contentType)
        }

        monitor.start()

        if settings.syncEnabled {
            Task { [weak self] in
                guard let self else { return }
                let coordinator = CloudKitSyncCoordinator(historyStore: self.historyStore, state: syncState)
                await coordinator.observeSyncToggle()
                await self.historyStore.setSyncCoordinator(coordinator)
                await coordinator.start()
            }
        }

        if !settings.hasCompletedOnboarding {
            showOnboarding()
        }
    }

    func showOnboarding() {
        guard onboardingWindowController == nil else {
            onboardingWindowController?.show()
            return
        }

        let onboarding = OnboardingWindowController(settingsStore: settingsStore) { [weak self] in
            self?.onboardingWindowController = nil
        }
        self.onboardingWindowController = onboarding
        onboarding.show()
    }
}
