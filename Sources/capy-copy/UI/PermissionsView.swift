import SwiftUI

/// Permission management view used inside the picker and onboarding.
struct PermissionsView: View {
    @ObservedObject var settingsStore: SettingsStore

    @State private var accessibilityGranted = false
    @State private var calendarGranted = false
    @State private var remindersGranted = false

    private var theme: ThemeDefinition { settingsStore.selectedTheme.definition }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Permissions")
                    .font(theme.headlineFont)
                    .foregroundStyle(theme.primaryTextColor)

                PermissionRow(
                    icon: "cursorarrow.click",
                    title: NSLocalizedString("onboarding.pasteTitle", bundle: .module, comment: ""),
                    description: NSLocalizedString("onboarding.pasteDescription", bundle: .module, comment: ""),
                    isGranted: accessibilityGranted,
                    grantTitle: NSLocalizedString("onboarding.grant", bundle: .module, comment: ""),
                    action: {
                        if PermissionChecker.accessibilityIsGranted() {
                            accessibilityGranted = true
                        } else {
                            PermissionChecker.requestAccessibilityAccess()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                refreshStatuses()
                            }
                        }
                    },
                    openSettingsAction: {
                        PermissionChecker.openAccessibilitySettings()
                    },
                    theme: theme
                )

                Divider()
                    .overlay(theme.dividerColor)

                PermissionRow(
                    icon: "calendar",
                    title: NSLocalizedString("onboarding.calendarTitle", bundle: .module, comment: ""),
                    description: NSLocalizedString("onboarding.calendarDescription", bundle: .module, comment: ""),
                    isGranted: calendarGranted,
                    grantTitle: NSLocalizedString("onboarding.grant", bundle: .module, comment: ""),
                    action: {
                        Task {
                            let granted = await PermissionChecker.requestCalendarAccess()
                            await MainActor.run {
                                calendarGranted = granted
                            }
                        }
                    },
                    openSettingsAction: nil,
                    theme: theme
                )

                Divider()
                    .overlay(theme.dividerColor)

                PermissionRow(
                    icon: "bell",
                    title: NSLocalizedString("onboarding.remindersTitle", bundle: .module, comment: ""),
                    description: NSLocalizedString("onboarding.remindersDescription", bundle: .module, comment: ""),
                    isGranted: remindersGranted,
                    grantTitle: NSLocalizedString("onboarding.grant", bundle: .module, comment: ""),
                    action: {
                        Task {
                            let granted = await PermissionChecker.requestReminderAccess()
                            await MainActor.run {
                                remindersGranted = granted
                            }
                        }
                    },
                    openSettingsAction: nil,
                    theme: theme
                )

                Spacer()
            }
            .padding(20)
        }
        .background(Color.clear)
        .onAppear {
            refreshStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshStatuses()
        }
    }

    private func refreshStatuses() {
        accessibilityGranted = PermissionChecker.accessibilityIsGranted()
        calendarGranted = PermissionChecker.calendarAuthorizationStatus() == .fullAccess
        remindersGranted = PermissionChecker.reminderAuthorizationStatus() == .fullAccess
    }
}
