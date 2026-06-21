import SwiftUI

struct PermissionGateView: View {
    let permission: SystemPermission
    let theme: ThemeDefinition
    let onGrant: (() -> Void)?

    @State private var isRequesting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: permission.iconName)
                    .foregroundStyle(theme.accentColor)
                Text(NSLocalizedString(permission.titleKey, bundle: .module, comment: ""))
                    .font(theme.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
            }

            Text(NSLocalizedString(permission.descriptionKey, bundle: .module, comment: ""))
                .font(theme.captionFont)
                .foregroundStyle(theme.secondaryTextColor)

            HStack {
                Spacer()
                Button {
                    handlePrimaryAction()
                } label: {
                    Text(buttonTitle)
                        .font(theme.captionFont)
                }
                .disabled(isRequesting || permission.status == .authorized)
            }
        }
        .padding(12)
        .background(theme.cardBackgroundColor.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
    }

    private var buttonTitle: String {
        switch permission.status {
        case .notDetermined:
            return NSLocalizedString("permission.gate.grant", bundle: .module, comment: "")
        case .authorized:
            return NSLocalizedString("permission.gate.granted", bundle: .module, comment: "")
        case .denied:
            return NSLocalizedString("permission.gate.openSettings", bundle: .module, comment: "")
        }
    }

    private func handlePrimaryAction() {
        switch permission.status {
        case .notDetermined:
            isRequesting = true
            Task {
                _ = await permission.requestAccess()
                isRequesting = false
                onGrant?()
            }
        case .denied:
            permission.openSettings()
        case .authorized:
            break
        }
    }
}
