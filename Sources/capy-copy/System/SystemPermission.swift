import EventKit
import AppKit

/// Permissions required by AI clipboard actions that integrate with system apps.
enum SystemPermission: String, CaseIterable, Identifiable {
    case calendar
    case reminders

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .calendar:
            return "permission.calendar.title"
        case .reminders:
            return "permission.reminders.title"
        }
    }

    var descriptionKey: String {
        switch self {
        case .calendar:
            return "permission.calendar.description"
        case .reminders:
            return "permission.reminders.description"
        }
    }

    var iconName: String {
        switch self {
        case .calendar:
            return "calendar"
        case .reminders:
            return "checklist"
        }
    }

    /// Current authorization status for this permission.
    var status: PermissionAuthorizationStatus {
        switch self {
        case .calendar:
            return authorizationStatus(for: .event)
        case .reminders:
            return authorizationStatus(for: .reminder)
        }
    }

    /// Requests access if needed. Returns the resulting authorization state.
    @discardableResult
    func requestAccess() async -> PermissionAuthorizationStatus {
        if status == .authorized { return .authorized }

        let granted: Bool
        switch self {
        case .calendar:
            granted = await requestCalendarAccess()
        case .reminders:
            granted = await requestRemindersAccess()
        }

        return granted ? .authorized : status
    }

    /// Opens the relevant System Settings pane.
    func openSettings() {
        let urlString: String
        switch self {
        case .calendar:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        case .reminders:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
        }
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}

enum PermissionAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
}

// MARK: - EventKit helpers

private func authorizationStatus(for entityType: EKEntityType) -> PermissionAuthorizationStatus {
    let status = EKEventStore.authorizationStatus(for: entityType)
    switch status {
    case .notDetermined:
        return .notDetermined
    case .fullAccess, .writeOnly:
        return .authorized
    case .denied, .restricted:
        return .denied
    @unknown default:
        return .denied
    }
}

private func requestCalendarAccess() async -> Bool {
    let store = EKEventStore()
    do {
        return try await store.requestFullAccessToEvents()
    } catch {
        return false
    }
}

private func requestRemindersAccess() async -> Bool {
    let store = EKEventStore()
    do {
        return try await store.requestFullAccessToReminders()
    } catch {
        return false
    }
}
