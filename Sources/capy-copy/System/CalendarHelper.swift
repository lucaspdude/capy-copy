import EventKit
import AppKit
import os.log

@MainActor
struct CalendarHelper {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "dev.capy-copy", category: "CalendarHelper")
    private static let store = EKEventStore()

    /// Returns the current authorization status for Calendar.
    static func authorizationStatus() -> PermissionAuthorizationStatus {
        SystemPermission.calendar.status
    }

    /// Requests Calendar access if it has not already been determined.
    @discardableResult
    static func requestAccess() async -> Bool {
        await SystemPermission.calendar.requestAccess() == .authorized
    }

    /// Creates a new Calendar event. Requests permission first if necessary.
    static func addEvent(title: String, date: Date?, notes: String?) async {
        guard await requestAccess() else {
            logger.warning("Calendar access denied; cannot create event.")
            SystemPermission.calendar.openSettings()
            return
        }

        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = date ?? Date()
        event.endDate = (date ?? Date()).addingTimeInterval(3600)
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(event, span: .thisEvent)
            if let url = URL(string: "ical://") {
                NSWorkspace.shared.open(url)
            }
        } catch {
            logger.error("Failed to save Calendar event: \(error.localizedDescription)")
        }
    }
}
