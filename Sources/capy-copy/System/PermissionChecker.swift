import Foundation
import AppKit
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

    // MARK: - Generic Required Permissions API

    /// Permissions that the app cannot function correctly without.
    /// Adding a new case here will automatically include it in the
    /// in-popover permission gate and in the Settings/Permissions screens.
    enum RequiredPermission: String, CaseIterable, Identifiable, Codable {
        case accessibility

        var id: String { rawValue }

        var displayKey: String {
            switch self {
            case .accessibility:
                return "onboarding.pasteTitle"
            }
        }

        var descriptionKey: String {
            switch self {
            case .accessibility:
                return "onboarding.pasteDescription"
            }
        }

        var iconName: String {
            switch self {
            case .accessibility:
                return "cursorarrow.click"
            }
        }

        var settingsURL: URL? {
            switch self {
            case .accessibility:
                return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            }
        }

        @MainActor
        var status: PermissionState {
            switch self {
            case .accessibility:
                return accessibilityIsGranted() ? .granted : .denied
            }
        }
    }

    enum PermissionState: String, Codable {
        case granted
        case denied
    }

    /// Returns the subset of required permissions that are currently denied.
    /// This is the entry point used by the in-popover permission gate.
    static func missingRequiredPermissions() -> [RequiredPermission] {
        RequiredPermission.allCases.filter { $0.status == .denied }
    }

    static func openSettings(for permission: RequiredPermission) {
        if permission == .accessibility {
            openAccessibilitySettings()
            return
        }
        if let url = permission.settingsURL {
            NSWorkspace.shared.open(url)
        }
    }
}
