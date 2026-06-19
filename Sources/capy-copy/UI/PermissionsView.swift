import SwiftUI

/// Permission management view used inside the picker and onboarding.
struct PermissionsView: View {
    @ObservedObject var settingsStore: SettingsStore

    @State private var grantedStatuses: [PermissionChecker.RequiredPermission: Bool] = [:]

    private var theme: ThemeDefinition { settingsStore.selectedTheme.definition }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Permissions")
                    .font(theme.headlineFont)
                    .foregroundStyle(theme.primaryTextColor)

                ForEach(PermissionChecker.RequiredPermission.allCases) { permission in
                    PermissionRow(
                        icon: permission.iconName,
                        title: NSLocalizedString(permission.displayKey, bundle: .module, comment: ""),
                        description: NSLocalizedString(permission.descriptionKey, bundle: .module, comment: ""),
                        isGranted: grantedStatuses[permission] ?? false,
                        grantTitle: NSLocalizedString("onboarding.grant", bundle: .module, comment: ""),
                        action: {
                            if permission == .accessibility {
                                if PermissionChecker.accessibilityIsGranted() {
                                    refreshStatuses()
                                } else {
                                    PermissionChecker.requestAccessibilityAccess()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        refreshStatuses()
                                    }
                                }
                            }
                        },
                        openSettingsAction: {
                            PermissionChecker.openSettings(for: permission)
                        },
                        theme: theme
                    )
                }

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
        var statuses: [PermissionChecker.RequiredPermission: Bool] = [:]
        for permission in PermissionChecker.RequiredPermission.allCases {
            statuses[permission] = permission.status == .granted
        }
        grantedStatuses = statuses
    }
}
