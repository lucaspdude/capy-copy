import SwiftUI

/// Compact in-popover banner shown when one or more required permissions
/// are missing. Tapping the action opens System Settings for the first
/// missing permission.
struct PermissionBanner: View {
    let theme: ThemeDefinition
    let missingPermissions: [PermissionChecker.RequiredPermission]
    let onOpenSettings: (PermissionChecker.RequiredPermission) -> Void

    var body: some View {
        if let first = missingPermissions.first {
            HStack(spacing: 10) {
                Image(systemName: first.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.warningColor)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(theme.warningColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(bannerTitle)
                        .font(theme.captionFont)
                        .foregroundStyle(theme.primaryTextColor)
                    if missingPermissions.count > 1 {
                        Text(String(format: NSLocalizedString("permissions.banner.more", bundle: .module, comment: ""), missingPermissions.count - 1))
                            .font(.system(size: 11))
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }

                Spacer()

                Button(action: { onOpenSettings(first) }) {
                    Text(NSLocalizedString("permissions.banner.action", bundle: .module, comment: ""))
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(theme.primaryTextColor)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.accentColor.opacity(0.18))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: theme.searchCornerRadius, style: .continuous)
                    .fill(theme.warningColor.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.searchCornerRadius, style: .continuous)
                    .stroke(theme.warningColor.opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
    }

    private var bannerTitle: String {
        guard let first = missingPermissions.first else { return "" }
        let name = NSLocalizedString(first.displayKey, bundle: .module, comment: "")
        return String(format: NSLocalizedString("permissions.banner.missing", bundle: .module, comment: ""), name)
    }
}
