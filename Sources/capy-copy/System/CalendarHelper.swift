import Foundation
import EventKit

@MainActor
final class CalendarHelper {
    static let shared = CalendarHelper()

    private let eventStore = EKEventStore()

    private init() {}

    func createEvent(title: String, notes: String? = nil, date: Date) async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        guard granted else { throw CalendarHelperError.accessDenied }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = notes
        event.startDate = date
        event.endDate = date.addingTimeInterval(3600)
        event.calendar = eventStore.defaultCalendarForNewEvents
            ?? eventStore.calendars(for: .event).first

        try eventStore.save(event, span: .thisEvent)
    }

    func createReminder(title: String, notes: String? = nil, date: Date) async throws {
        let granted = try await eventStore.requestFullAccessToReminders()
        guard granted else { throw CalendarHelperError.accessDenied }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
            ?? eventStore.calendars(for: .reminder).first

        try eventStore.save(reminder, commit: true)
    }
}

enum CalendarHelperError: Error {
    case accessDenied
}
