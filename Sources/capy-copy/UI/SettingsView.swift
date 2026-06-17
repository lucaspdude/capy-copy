import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SettingsFormView(settingsStore: settingsStore)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
        }
        .frame(width: 380, height: 320)
    }
}
