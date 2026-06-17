import Foundation
import AppKit
import EventKit
import ApplicationServices
import os.log

@MainActor
enum PermissionChecker {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "dev.capy-copy", category: "PermissionChecker")

    // MARK: - Accessibility (paste)

    static func accessibilityIsGranted() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        let granted = AXIsProcessTrustedWithOptions(options)
        logger.log("AXIsProcessTrustedWithOptions returned: \(granted)")
        return granted
    }

    /// Prompts the user to grant Accessibility access. On macOS the system
    /// dialog is only shown the first time; after a denial the user must enable
    /// the permission manually in System Settings. This method opens System
    /// Settings so the user can toggle Capy Copy on.
    static func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        openAccessibilitySettings()
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Calendar

    static func calendarAuthorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    static func requestCalendarAccess() async -> Bool {
        let store = EKEventStore()
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    // MARK: - Reminders

    static func reminderAuthorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .reminder)
    }

    static func requestReminderAccess() async -> Bool {
        let store = EKEventStore()
        do {
            return try await store.requestFullAccessToReminders()
        } catch {
            return false
        }
    }
}
