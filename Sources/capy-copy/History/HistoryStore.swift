import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [ClipItem] = []
    @Published private(set) var lastPersistenceError: String?

    var favoriteItems: [ClipItem] {
        items.filter { $0.isFavorite }
    }

    private let persistence: HistoryPersistence
    private let maxItems: () -> Int
    private weak var syncCoordinator: HistorySyncing?
    private var pendingSyncIDs: Set<UUID> = []

    init(persistence: HistoryPersistence, maxItems: @escaping () -> Int = { 10 }, syncCoordinator: HistorySyncing? = nil) {
        self.persistence = persistence
        self.maxItems = maxItems
        self.syncCoordinator = syncCoordinator
        // Synchronously load on init. The previous design kicked off a detached
        // Task, which raced with any synchronous `add()` calls: a user copying
        // text during launch could have their new item overwritten by the
        // loaded array. `loadSync()` is safe here because save() is only
        // dispatched from the same MainActor (i.e. after init returns), and
        // save uses `.atomic` writes.
        let loaded = (try? persistence.loadSync()) ?? []
        self.items = loaded
        cleanupStaleLoadingItems()
    }

    func setSyncCoordinator(_ coordinator: HistorySyncing?) {
        self.syncCoordinator = coordinator
    }

    @discardableResult
    func add(rawText: String, type: DetectedContent) -> ClipItem {
        let hash = ClipContentHash.hash(for: rawText, data: nil)
        return upsert(hash: hash) {
            ClipItem(rawText: rawText, contentType: type, contentHash: hash, isLoading: true)
        }
    }

    @discardableResult
    func addImage(data: Data) -> ClipItem {
        let hash = ClipContentHash.hash(for: "", data: data)
        return upsert(hash: hash) {
            ClipItem(
                rawText: "",
                contentType: .image,
                contentHash: hash,
                isLoading: false,
                imageData: data
            )
        }
    }

    func updateSourceDevices(id: UUID, _ update: (inout Set<DeviceSource>) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        update(&items[index].sourceDevices)
        trackChange(id: id)
        persist()
    }

    @discardableResult
    func addVideo(url: URL) -> ClipItem? {
        // Reject local file:// URLs. Persisting the path would leak the user's
        // local filesystem layout into the encrypted history file; a future
        // sync layer could also accidentally exfiltrate it.
        guard !url.isFileURL else { return nil }
        let item = ClipItem(
            rawText: url.lastPathComponent,
            contentType: .video(url),
            isLoading: false
        )
        items.insert(item, at: 0)
        enforceLimit()
        persist()
        return item
    }

    func updateResult(id: UUID, result: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].result = result
        items[index].isLoading = false
        items[index].errorMessage = nil
        trackChange(id: id)
        persist()
    }

    func updateError(id: UUID, message: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].errorMessage = message
        items[index].isLoading = false
        trackChange(id: id)
        persist()
    }

    func clear() {
        let removed = items.filter { !$0.isFavorite }.map(\.contentHash)
        items.removeAll { !$0.isFavorite }
        persist()

        let shouldSync = UserDefaults.standard.object(forKey: "clearHistorySyncsToAllDevices") as? Bool ?? true
        guard shouldSync else { return }
        Task { [weak self] in
            guard let coordinator = self?.syncCoordinator else { return }
            await coordinator.deleted(recordNames: removed)
        }
    }

    func toggleFavorite(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isFavorite.toggle()
        trackChange(id: id)
        persist()
    }

    func applyRemoteItem(_ item: ClipItem) {
        if let index = items.firstIndex(where: { $0.contentHash == item.contentHash }) {
            items[index].sourceDevices.formUnion(item.sourceDevices)
            items[index].isFavorite = item.isFavorite
            moveToTop(index: index)
        } else {
            var remoteItem = item
            remoteItem.sourceDevices.insert(DeviceIdentity.current.asSource())
            items.insert(remoteItem, at: 0)
            enforceLimit()
        }
        persist()
    }

    func cleanupStaleLoadingItems(threshold: TimeInterval = 60) {
        let cutoff = Date().addingTimeInterval(-threshold)
        var changed = false

        for index in items.indices where items[index].isLoading && items[index].timestamp < cutoff {
            items[index].isLoading = false
            items[index].errorMessage = NSLocalizedString(
                "error.fm.timeout",
                tableName: nil,
                bundle: .module,
                comment: ""
            )
            changed = true
        }

        if changed {
            persist()
        }
    }

    // MARK: - Private

    private func upsert(hash: String, makeItem: () -> ClipItem) -> ClipItem {
        if let index = items.firstIndex(where: { $0.contentHash == hash }) {
            items[index].sourceDevices.insert(DeviceIdentity.current.asSource())
            moveToTop(index: index)
            trackChange(id: items[index].id)
            persist()
            return items[index]
        }

        let item = makeItem()
        items.insert(item, at: 0)
        enforceLimit()
        trackChange(id: item.id)
        persist()
        return item
    }

    private func load() async {
        do {
            items = try await persistence.load()
            cleanupStaleLoadingItems()
        } catch {
            items = []
        }
    }

    private func enforceLimit() {
        let limit = maxItems()
        if items.count > limit {
            items = Array(items.prefix(limit))
        }
    }

    private func persist() {
        let currentItems = items
        let idsToSync = pendingSyncIDs
        pendingSyncIDs.removeAll()
        let persistence = self.persistence
        Task { [weak self] in
            do {
                try await persistence.save(currentItems)
                await MainActor.run { self?.lastPersistenceError = nil }
            } catch {
                // Surface the error rather than swallowing it. UI can show a
                // non-secret banner; the error string itself is generic.
                let message = "history.save.failed: \(error.localizedDescription)"
                await MainActor.run { self?.lastPersistenceError = message }
            }

            guard let coordinator = self?.syncCoordinator else { return }
            for id in idsToSync {
                guard let item = currentItems.first(where: { $0.id == id }) else { continue }
                await coordinator.updated(item)
            }
        }
    }

    private func trackChange(id: UUID) {
        pendingSyncIDs.insert(id)
    }

    private func moveToTop(index: Int) {
        guard index > 0 else { return }
        let item = items.remove(at: index)
        items.insert(item, at: 0)
    }
}
