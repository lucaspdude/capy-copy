import SwiftUI

/// A row component for the Settings tab, styled like `PermissionRow`:
/// icon on the left, title + optional description, and a trailing control.
struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let description: String?
    let theme: ThemeDefinition
    @ViewBuilder let trailing: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(theme.secondaryTextColor)
                .imageScale(.large)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.bodyFont)
                    .foregroundStyle(theme.primaryTextColor)

                if let description {
                    Text(description)
                        .font(theme.captionFont)
                        .foregroundStyle(theme.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            trailing()
        }
        .padding(.vertical, 6)
    }
}

/// A section header used inside the Settings tab.
struct SettingsSectionHeader: View {
    let title: String
    let theme: ThemeDefinition

    var body: some View {
        Text(title)
            .font(theme.headlineFont)
            .foregroundStyle(theme.primaryTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
