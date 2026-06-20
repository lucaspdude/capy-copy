import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    static let maxHistoryItemsRange: ClosedRange<Int> = 0...500

    static func clamp(_ value: Int) -> Int {
        min(max(value, maxHistoryItemsRange.lowerBound), maxHistoryItemsRange.upperBound)
    }
    @Published var mapsProvider: MapsProvider {
        didSet { UserDefaults.standard.set(mapsProvider.rawValue, forKey: SettingsKey.mapsProvider) }
    }

    @Published var autoAnalyze: Bool {
        didSet { UserDefaults.standard.set(autoAnalyze, forKey: SettingsKey.autoAnalyze) }
    }

    @Published var analyzeTextAndDates: Bool {
        didSet { UserDefaults.standard.set(analyzeTextAndDates, forKey: SettingsKey.analyzeTextAndDates) }
    }

    @Published var analyzeURLs: Bool {
        didSet { UserDefaults.standard.set(analyzeURLs, forKey: SettingsKey.analyzeURLs) }
    }

    @Published var analyzeCode: Bool {
        didSet { UserDefaults.standard.set(analyzeCode, forKey: SettingsKey.analyzeCode) }
    }

    @Published var maxHistoryItems: Int {
        didSet {
            let clamped = Self.clamp(maxHistoryItems)
            if clamped != maxHistoryItems {
                maxHistoryItems = clamped
                return  // the recursive didSet will persist the clamped value
            }
            UserDefaults.standard.set(maxHistoryItems, forKey: SettingsKey.maxHistoryItems)
        }
    }

    @Published var shortcut: KeyboardShortcut {
        didSet {
            if let data = try? JSONEncoder().encode(shortcut) {
                UserDefaults.standard.set(data, forKey: SettingsKey.shortcut)
            }
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: SettingsKey.hasCompletedOnboarding) }
    }

    @Published var selectedTheme: AppTheme {
        didSet { UserDefaults.standard.set(selectedTheme.rawValue, forKey: SettingsKey.selectedTheme) }
    }

    @Published var syncEnabled: Bool {
        didSet { UserDefaults.standard.set(syncEnabled, forKey: SettingsKey.syncEnabled) }
    }

    @Published var deviceName: String {
        didSet {
            UserDefaults.standard.set(deviceName, forKey: SettingsKey.deviceName)
            var identity = DeviceIdentity.current
            identity.name = deviceName
            DeviceIdentity.save(identity)
        }
    }

    @Published var clearHistorySyncsToAllDevices: Bool {
        didSet { UserDefaults.standard.set(clearHistorySyncsToAllDevices, forKey: SettingsKey.clearHistorySyncsToAllDevices) }
    }

    init() {
        let defaults = UserDefaults.standard

        self.syncEnabled = defaults.object(forKey: SettingsKey.syncEnabled) as? Bool ?? false
        self.deviceName = defaults.string(forKey: SettingsKey.deviceName) ?? DeviceIdentity.current.name
        self.clearHistorySyncsToAllDevices = defaults.object(forKey: SettingsKey.clearHistorySyncsToAllDevices) as? Bool ?? true

        if let raw = defaults.string(forKey: SettingsKey.mapsProvider),
           let provider = MapsProvider(rawValue: raw) {
            self.mapsProvider = provider
        } else {
            // Legacy Google Maps value is silently migrated to Apple Maps.
            self.mapsProvider = .appleMaps
        }

        // Notifications are disabled in 1.0.0 (Q3 → N1). Silently consume the legacy
        // UserDefaults value so a user upgrading from a previous build doesn't have
        // a stale entry lingering in their defaults plist.
        _ = defaults.object(forKey: SettingsKey.showNotifications)
        self.autoAnalyze = defaults.object(forKey: SettingsKey.autoAnalyze) as? Bool ?? false
        self.analyzeTextAndDates = defaults.object(forKey: SettingsKey.analyzeTextAndDates) as? Bool ?? true
        self.analyzeURLs = defaults.object(forKey: SettingsKey.analyzeURLs) as? Bool ?? false
        self.analyzeCode = defaults.object(forKey: SettingsKey.analyzeCode) as? Bool ?? false
        self.maxHistoryItems = Self.clamp(
            defaults.object(forKey: SettingsKey.maxHistoryItems) as? Int ?? 10
        )

        if let data = defaults.data(forKey: SettingsKey.shortcut),
           let saved = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            self.shortcut = saved
        } else {
            self.shortcut = .default
        }

        self.hasCompletedOnboarding = defaults.object(forKey: SettingsKey.hasCompletedOnboarding) as? Bool ?? false

        if let raw = defaults.string(forKey: SettingsKey.selectedTheme),
           let theme = AppTheme(rawValue: raw) {
            self.selectedTheme = theme
        } else {
            self.selectedTheme = .liquidGlass
        }
    }
}

extension SettingsStore {
    func shouldAnalyze(_ contentType: DetectedContent) -> Bool {
        guard autoAnalyze else { return false }
        switch contentType {
        case .text, .date, .address:
            return analyzeTextAndDates
        case .url:
            return analyzeURLs
        case .code:
            return analyzeCode
        case .image, .video, .media:
            return false
        }
    }
}

private enum SettingsKey {
    static let mapsProvider = "mapsProvider"
    static let showNotifications = "showNotifications"
    static let autoAnalyze = "autoAnalyze"
    static let analyzeTextAndDates = "analyzeTextAndDates"
    static let analyzeURLs = "analyzeURLs"
    static let analyzeCode = "analyzeCode"
    static let maxHistoryItems = "maxHistoryItems"
    static let shortcut = "shortcut"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let selectedTheme = "selectedTheme"
    static let syncEnabled = "syncEnabled"
    static let deviceName = "deviceName"
    static let clearHistorySyncsToAllDevices = "clearHistorySyncsToAllDevices"
}
