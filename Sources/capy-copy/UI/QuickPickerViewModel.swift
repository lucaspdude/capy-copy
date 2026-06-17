import SwiftUI
import Combine

enum DeviceScope: Equatable, Hashable {
    case all
    case thisDevice
    case device(DeviceSource)
}

@MainActor
final class QuickPickerViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var selectedItemID: ClipItem.ID?
    @Published var selectedDeviceScope: DeviceScope = .all
    @Published var showSettings: Bool = false
    @Published var selectedTab: PickerTab = .all

    let historyStore: HistoryStore
    let clipboardMonitor: ClipboardMonitor
    let settingsStore: SettingsStore

    private var cancellables = Set<AnyCancellable>()

    init(historyStore: HistoryStore, clipboardMonitor: ClipboardMonitor, settingsStore: SettingsStore) {
        self.historyStore = historyStore
        self.clipboardMonitor = clipboardMonitor
        self.settingsStore = settingsStore

        $searchText
            .combineLatest(historyStore.$items)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resetSelection()
            }
            .store(in: &cancellables)

        settingsStore.$selectedTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var filteredItems: [ClipItem] {
        applyFilters(to: historyStore.items)
    }

    var filteredFavoriteItems: [ClipItem] {
        applyFilters(to: historyStore.favoriteItems)
    }

    private func applyFilters(to source: [ClipItem]) -> [ClipItem] {
        let deviceFiltered: [ClipItem]
        switch selectedDeviceScope {
        case .all:
            deviceFiltered = source
        case .thisDevice:
            deviceFiltered = source.filter { $0.sourceDevices.contains(DeviceIdentity.current.asSource()) }
        case .device(let sourceDevice):
            deviceFiltered = source.filter { $0.sourceDevices.contains(sourceDevice) }
        }

        guard !searchText.isEmpty else { return deviceFiltered }
        return deviceFiltered.filter { item in
            item.rawText.localizedCaseInsensitiveContains(searchText)
            || item.sourceDevices.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var availableDeviceScopes: [DeviceScope] {
        var scopes: [DeviceScope] = [.all, .thisDevice]
        let currentID = DeviceIdentity.current.id
        let others = historyStore.items
            .flatMap(\.sourceDevices)
            .filter { $0.id != currentID }
            .uniqued(by: \.id)
            .sorted(by: { $0.name < $1.name })
            .map(DeviceScope.device)
        scopes.append(contentsOf: others)
        return scopes
    }

    func resetSelection() {
        selectedItemID = filteredItems.first?.id
    }

    func moveSelection(direction: Int) {
        let items = filteredItems
        guard !items.isEmpty else { return }
        let currentIndex: Int
        if let selectedItemID = selectedItemID,
           let index = items.firstIndex(where: { $0.id == selectedItemID }) {
            currentIndex = index
        } else {
            currentIndex = 0
        }

        var newIndex = currentIndex + direction
        newIndex = max(0, min(items.count - 1, newIndex))
        self.selectedItemID = items[newIndex].id
    }

    func isSelected(_ item: ClipItem) -> Bool {
        selectedItemID == item.id
    }

    func select(_ item: ClipItem) {
        selectedItemID = item.id
    }

    func pasteSelected() {
        guard let selectedItemID = selectedItemID,
              let item = filteredItems.first(where: { $0.id == selectedItemID }) else {
            return
        }
        paste(item: item)
    }

    func paste(item: ClipItem) {
        clipboardMonitor.ignoreNextChange = true

        if case .image = item.contentType,
           let data = item.imageData {
            QuickPickerWindowController.shared.paste(imageData: data)
        } else {
            QuickPickerWindowController.shared.paste(text: item.rawText)
        }
    }

    func clearHistory() {
        historyStore.clear()
    }

    func toggleFavorite(_ item: ClipItem) {
        historyStore.toggleFavorite(id: item.id)
    }
}

private extension Sequence {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

extension DeviceScope {
    var label: String {
        switch self {
        case .all:
            return NSLocalizedString("deviceScope.all", bundle: .module, comment: "")
        case .thisDevice:
            return NSLocalizedString("deviceScope.thisDevice", bundle: .module, comment: "")
        case .device(let source):
            return source.name
        }
    }

    var icon: String {
        switch self {
        case .all: return "macwindow"
        case .thisDevice: return "desktopcomputer"
        case .device: return "macmini"
        }
    }
}
