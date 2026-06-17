import Foundation
import CloudKit
import os.log

private let loggerSubsystem = Bundle.main.bundleIdentifier ?? "dev.capy-copy"

/// Actor-protected coordinator for CloudKit sync.
///
/// All mutable state is isolated to the actor. The `CKSyncEngineDelegate` callbacks are
/// implemented as `nonisolated` so CloudKit can call them from any queue; they immediately
/// hop back to the actor via `await self.<isolatedHelper>(...)`. The actor is implicitly
/// `Sendable`; the unchecked conformance is not required because no mutable state escapes.
actor CloudKitSyncCoordinator: HistorySyncing {
    static let containerIdentifier = "iCloud.dev.capy-copy"

    private let logger = Logger(subsystem: loggerSubsystem, category: "CloudKitSync")
    private let container: CKContainer
    private let database: CKDatabase
    private var engine: CKSyncEngine?
    private let state: SyncState
    private let historyStore: HistoryStore
    private var syncToggleObserver: NSObjectProtocol?

    private var isEnabled: Bool { UserDefaults.standard.bool(forKey: "syncEnabled") }

    init(historyStore: HistoryStore, state: SyncState) {
        self.historyStore = historyStore
        self.state = state
        self.container = CKContainer(identifier: CloudKitSyncCoordinator.containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    func observeSyncToggle() {
        guard syncToggleObserver == nil else { return }
        syncToggleObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleSyncToggleChanged()
            }
        }
    }

    func start() async {
        guard isEnabled else { return }

        let serialization = await state.load()
        let configuration = CKSyncEngine.Configuration(
            database: database,
            stateSerialization: serialization,
            delegate: self
        )
        let newEngine = CKSyncEngine(configuration)
        engine = newEngine

        do {
            let status = try await container.accountStatus()
            if status == .available {
                newEngine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneName: "HistoryZone"))])
            }
        } catch {
            logger.error("Failed to fetch CloudKit account status: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stop() async {
        engine = nil
    }

    func added(_ item: ClipItem) async {
        guard isEnabled, item.contentType != .image, let engine else { return }
        engine.state.add(pendingRecordZoneChanges: [.saveRecord(item.cloudKitRecordID())])
    }

    func updated(_ item: ClipItem) async {
        await added(item)
    }

    func deleted(recordNames: [String]) async {
        guard isEnabled, let engine else { return }
        let zoneID = CKRecordZone.ID(zoneName: "HistoryZone")
        let changes = recordNames.map { CKRecord.ID(recordName: $0, zoneID: zoneID) }
            .map { CKSyncEngine.PendingRecordZoneChange.deleteRecord($0) }
        engine.state.add(pendingRecordZoneChanges: changes)
    }

    private func handleSyncToggleChanged() async {
        if isEnabled && engine == nil {
            await start()
        } else if !isEnabled && engine != nil {
            await stop()
        }
    }
}

extension CloudKitSyncCoordinator: CKSyncEngineDelegate {
    nonisolated func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let update):
            await handleStateUpdate(update)
        case .accountChange(let accountChange):
            if case .signIn = accountChange.changeType {
                await handleAccountSignIn(syncEngine: syncEngine)
            }
        case .fetchedRecordZoneChanges(let changes):
            await applyRemoteChanges(changes)
        default:
            break
        }
    }

    nonisolated func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        await nextBatch(context: context, syncEngine: syncEngine)
    }

    private func handleStateUpdate(_ update: CKSyncEngine.Event.StateUpdate) async {
        await state.save(update.stateSerialization)
    }

    private func handleAccountSignIn(syncEngine: CKSyncEngine) async {
        syncEngine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneName: "HistoryZone"))])
    }

    private func applyRemoteChanges(_ changes: CKSyncEngine.Event.FetchedRecordZoneChanges) async {
        for modification in changes.modifications {
            do {
                let item = try ClipItem(cloudKitRecord: modification.record)
                await historyStore.applyRemoteItem(item)
            } catch {
                logger.error("Failed to decode remote CloudKit record: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func nextBatch(
        context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = syncEngine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }
        let localItems = await historyStore.items

        let validPending = pending.filter { change in
            switch change {
            case .saveRecord(let recordID):
                guard let item = localItems.first(where: { $0.contentHash == recordID.recordName }) else {
                    return false
                }
                return item.contentType != .image
            default:
                return true
            }
        }

        let removed = pending.filter { !validPending.contains($0) }
        syncEngine.state.remove(pendingRecordZoneChanges: removed)

        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: validPending) { recordID in
            guard let item = localItems.first(where: { $0.contentHash == recordID.recordName }) else {
                return nil
            }
            return item.cloudKitRecord()
        }
    }
}
