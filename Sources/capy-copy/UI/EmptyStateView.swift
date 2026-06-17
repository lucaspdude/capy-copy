import SwiftUI

enum EmptyStateMode {
    case history
    case favorites
}

struct EmptyStateView: View {
    let theme: ThemeDefinition
    var mode: EmptyStateMode = .history

    private var title: String {
        switch mode {
        case .history:
            return NSLocalizedString("empty.title", bundle: .module, comment: "")
        case .favorites:
            return NSLocalizedString("empty.favoritesTitle", bundle: .module, comment: "")
        }
    }

    private var subtitle: String {
        switch mode {
        case .history:
            return NSLocalizedString("empty.subtitle", bundle: .module, comment: "")
        case .favorites:
            return NSLocalizedString("empty.favoritesSubtitle", bundle: .module, comment: "")
        }
    }

    private var icon: String {
        switch mode {
        case .history:
            return "doc.on.clipboard"
        case .favorites:
            return "star"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(theme.secondaryTextColor.opacity(0.8))

            Text(title)
                .font(theme.headlineFont)
                .foregroundStyle(theme.primaryTextColor)

            Text(subtitle)
                .font(theme.bodyFont)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
