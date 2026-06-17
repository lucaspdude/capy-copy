import XCTest
import CryptoKit
@testable import capy_copy

@MainActor
final class QuickPickerViewModelTests: XCTestCase {
    private var viewModel: QuickPickerViewModel!
    private var store: HistoryStore!
    private var persistence: HistoryPersistence!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        persistence = HistoryPersistence(fileURL: tempDir.appendingPathComponent("history.json"), key: SymmetricKey(size: .bits256))
        store = HistoryStore(persistence: persistence, maxItems: { 10 })
        viewModel = QuickPickerViewModel(
            historyStore: store,
            clipboardMonitor: ClipboardMonitor(),
            settingsStore: SettingsStore()
        )
    }

    override func tearDown() {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
        super.tearDown()
    }

    func testSearchMatchesDeviceName() {
        let item = store.add(rawText: "hello", type: .text)
        store.updateSourceDevices(id: item.id) { $0 = [DeviceSource(id: "1", name: "Studio Mac")] }

        viewModel.searchText = "Studio"
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems.first?.id, item.id)
    }

    func testDeviceScopeFiltersBySourceDevice() {
        let local = DeviceIdentity.current.asSource()
        let localItem = store.add(rawText: "local", type: .text)
        store.updateSourceDevices(id: localItem.id) { $0 = [local] }

        let remote = DeviceSource(id: "remote", name: "Laptop")
        let remoteItem = store.add(rawText: "remote", type: .text)
        store.updateSourceDevices(id: remoteItem.id) { $0 = [remote] }

        viewModel.selectedDeviceScope = .device(remote)
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems.first?.rawText, "remote")
    }
}
