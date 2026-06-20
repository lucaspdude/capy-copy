import SwiftUI

struct AIActionsPopover: View {
    let item: ClipItem
    let theme: ThemeDefinition
    let onAction: (SuggestedAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if item.isLoading {
                loadingView
            } else if let error = item.errorMessage {
                errorView(error)
            } else {
                actionsList
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    private var header: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(theme.accentColor)
            Text(NSLocalizedString("ai.title", bundle: .module, comment: ""))
                .font(theme.bodyFont)
                .fontWeight(.semibold)
            Spacer()
        }
    }

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(NSLocalizedString("card.analyzing", bundle: .module, comment: ""))
                .font(theme.captionFont)
                .foregroundStyle(theme.secondaryTextColor)
        }
    }

    private func errorView(_ message: String) -> some View {
        Text(message)
            .font(theme.captionFont)
            .foregroundStyle(.red)
    }

    private var actionsList: some View {
        let actions = SuggestedAction.actions(for: item.contentType, analysis: item.result)
        return VStack(alignment: .leading, spacing: 8) {
            if actions.isEmpty {
                Text(NSLocalizedString("ai.noActions", bundle: .module, comment: ""))
                    .font(theme.captionFont)
                    .foregroundStyle(theme.secondaryTextColor)
            } else {
                ForEach(actions.indices, id: \.self) { index in
                    actionButton(actions[index])
                }
            }
        }
    }

    private func actionButton(_ action: SuggestedAction) -> some View {
        Button {
            onAction(action)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: action.iconName)
                Text(NSLocalizedString(action.titleKey, bundle: .module, comment: ""))
                Spacer()
            }
            .font(theme.bodyFont)
            .foregroundStyle(theme.primaryTextColor)
        }
        .buttonStyle(.plain)
    }
}
