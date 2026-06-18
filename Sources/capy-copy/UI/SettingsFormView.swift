import SwiftUI

/// Reusable settings form used by both the sheet and the picker tab.
struct SettingsFormView: View {
    @ObservedObject var settingsStore: SettingsStore

    @State private var accessibilityGranted = false

    private var theme: ThemeDefinition { settingsStore.selectedTheme.definition }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Appearance
                VStack(alignment: .leading, spacing: 12) {
                    SettingsSectionHeader(title: "Appearance", theme: theme)
                    SettingsRow(
                        icon: "paintbrush",
                        title: "Theme",
                        description: "Choose the look of the Capy Copy picker.",
                        theme: theme
                    ) {
                        HStack(spacing: 6) {
                            ForEach(AppTheme.allCases) { appTheme in
                                Button {
                                    settingsStore.selectedTheme = appTheme
                                } label: {
                                    Text(appTheme.displayName)
                                        .font(theme.captionFont)
                                        .foregroundStyle(settingsStore.selectedTheme == appTheme ? theme.accentColor : theme.primaryTextColor)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                                                .fill(settingsStore.selectedTheme == appTheme ? theme.accentColor.opacity(0.15) : theme.cardBackgroundColor)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                                                .stroke(settingsStore.selectedTheme == appTheme ? theme.accentColor : theme.borderColor, lineWidth: theme.borderWidth)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Divider().overlay(theme.dividerColor)
                }

                // MARK: - iCloud Sync
                VStack(alignment: .leading, spacing: 12) {
                    SettingsSectionHeader(title: NSLocalizedString("settings.icloudSync", bundle: .module, comment: ""), theme: theme)
                    SettingsRow(
                        icon: "icloud",
                        title: NSLocalizedString("settings.syncEnabled", bundle: .module, comment: ""),
                        description: NSLocalizedString("settings.syncFooter", bundle: .module, comment: ""),
                        theme: theme
                    ) {
                        Toggle("", isOn: $settingsStore.syncEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(theme.accentColor)
                    }
                    Divider().overlay(theme.dividerColor)
                    SettingsRow(
                        icon: "desktopcomputer",
                        title: NSLocalizedString("settings.deviceName", bundle: .module, comment: ""),
                        description: "Name used to label items copied on this Mac.",
                        theme: theme
                    ) {
                        TextField("", text: $settingsStore.deviceName)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                    }
                    Divider().overlay(theme.dividerColor)
                    SettingsRow(
                        icon: "trash",
                        title: NSLocalizedString("settings.clearHistorySyncsToAllDevices", bundle: .module, comment: ""),
                        description: "When off, clearing history only affects this Mac.",
                        theme: theme
                    ) {
                        Toggle("", isOn: $settingsStore.clearHistorySyncsToAllDevices)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(theme.accentColor)
                    }
                    Divider().overlay(theme.dividerColor)
                }

                // MARK: - Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    SettingsSectionHeader(title: "Shortcuts", theme: theme)
                    SettingsRow(
                        icon: "keyboard",
                        title: "Global shortcut",
                        description: "Press the key combination you want to use to open Capy Copy.",
                        theme: theme
                    ) {
                        ShortcutRecorderView(shortcut: $settingsStore.shortcut)
                            .frame(width: 160, height: 28)
                    }
                    Divider().overlay(theme.dividerColor)
                }

                // MARK: - Permissions
                VStack(alignment: .leading, spacing: 12) {
                    SettingsSectionHeader(title: "Permissions", theme: theme)
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
                                    refreshPermissionStatuses()
                                }
                            }
                        },
                        openSettingsAction: {
                            PermissionChecker.openAccessibilitySettings()
                        },
                        theme: theme
                    )
                    Divider().overlay(theme.dividerColor)
                }

                // MARK: - Version
                VStack(alignment: .leading, spacing: 12) {
                    SettingsSectionHeader(title: "Version", theme: theme)
                    SettingsRow(
                        icon: "info.circle",
                        title: "Build",
                        description: "Use this to confirm you are running the most recent build.",
                        theme: theme
                    ) {
                        Text(appVersion)
                            .font(theme.bodyFont)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }

                Spacer(minLength: 12)
            }
            .padding(20)
        }
        .background(Color.clear)
        .onAppear { refreshPermissionStatuses() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissionStatuses()
        }
    }

    private func refreshPermissionStatuses() {
        accessibilityGranted = PermissionChecker.accessibilityIsGranted()
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (build \(build))"
    }
}
