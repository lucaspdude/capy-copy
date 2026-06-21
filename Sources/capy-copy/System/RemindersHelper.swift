import EventKit
import AppKit
import os.log

@MainActor
struct RemindersHelper {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "dev.capy-copy", category: "RemindersHelper")
    private static let store = EKEventStore()

    /// Returns the current authorization status for Reminders.
    static func authorizationStatus() -> PermissionAuthorizationStatus {
        SystemPermission.reminders.status
    }

    /// Requests Reminders access if it has not already been determined.
    @discardableResult
    static func requestAccess() async -> Bool {
        await SystemPermission.reminders.requestAccess() == .authorized
    }

    /// Creates a new reminder. Requests permission first if necessary.
    static func addReminder(title: String, notes: String?) async {
        guard await requestAccess() else {
            logger.warning("Reminders access denied; cannot create reminder.")
            SystemPermission.reminders.openSettings()
            return
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = store.defaultCalendarForNewReminders()
            ?? store.calendars(for: .reminder).first

        do {
            try store.save(reminder, commit: true)
            if let url = URL(string: "x-apple-reminderkit://") {
                NSWorkspace.shared.open(url)
            }
        } catch {
            logger.error("Failed to save reminder: \(error.localizedDescription)")
        }
    }
}
