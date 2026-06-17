import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settingsStore: SettingsStore
    let onFinish: () -> Void

    private var theme: ThemeDefinition { settingsStore.selectedTheme.definition }

    var body: some View {
        NavigationStack {
            PermissionsView(settingsStore: settingsStore)
                .background(theme.windowBackground)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Continue") {
                            settingsStore.hasCompletedOnboarding = true
                            onFinish()
                        }
                        .keyboardShortcut(.defaultAction)
                        .tint(theme.accentColor)
                    }
                }
        }
        .frame(width: 420, height: 480)
        .background(theme.windowBackground)
    }
}
