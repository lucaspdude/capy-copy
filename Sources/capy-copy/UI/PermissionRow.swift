import SwiftUI

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let grantTitle: String
    let action: () -> Void
    let openSettingsAction: (() -> Void)?
    let theme: ThemeDefinition

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : icon)
                .foregroundStyle(isGranted ? theme.accentColor : theme.secondaryTextColor)
                .imageScale(.large)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.bodyFont)
                    .foregroundStyle(theme.primaryTextColor)

                Text(description)
                    .font(theme.captionFont)
                    .foregroundStyle(theme.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    if isGranted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.accentColor)
                            Text(NSLocalizedString("onboarding.granted", bundle: .module, comment: ""))
                                .font(theme.captionFont)
                                .foregroundStyle(theme.accentColor)
                        }
                    } else {
                        Button(action: action) {
                            Text(grantTitle)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(theme.accentColor)

                        if let openSettingsAction = openSettingsAction {
                            Button(action: openSettingsAction) {
                                Image(systemName: "gear")
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                            .help("Open System Settings")
                            .foregroundStyle(theme.secondaryTextColor)
                        }
                    }
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
