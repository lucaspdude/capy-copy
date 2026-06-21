import SwiftUI
import AppKit

struct ClipCard: View {
    let item: ClipItem
    var isSelected: Bool = false
    @ObservedObject var historyStore: HistoryStore
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @ObservedObject var settingsStore: SettingsStore
    var onSelect: (() -> Void)?
    var onCopy: (() -> Void)?
    var onToggleFavorite: (() -> Void)?
    var onAIAction: ((SuggestedAction) -> Void)?

    @State private var copied = false
    @State private var isHovered = false
    @State private var showAIPopover = false

    private var aiEnabled: Bool {
        settingsStore.autoAnalyze && FoundationModelCapability.isSupported
    }

    private var theme: ThemeDefinition { settingsStore.selectedTheme.definition }

    private var previewText: String {
        let limit = 300
        if item.rawText.count > limit {
            return String(item.rawText.prefix(limit)) + "…"
        }
        return item.rawText
    }

    private var timestampText: String {
        item.timestamp.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if case .image = item.contentType {
                imageContent
            } else if case .video = item.contentType {
                videoContent
            } else {
                textContent
            }
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: isSelected ? max(theme.borderWidth, 2) : theme.borderWidth)
        )
        .contentShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .brightness(isHovered ? 0.03 : 0)
        .onTapGesture {
            onSelect?()
        }
        .onTapGesture(count: 2) {
            onCopy?()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAIActions)) { notification in
            guard let itemID = notification.object as? ClipItem.ID,
                  itemID == item.id,
                  aiEnabled else { return }
            showAIPopover = true
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if theme.name == .liquidGlass {
            Color.clear
                .background(.regularMaterial)
        } else {
            theme.cardBackgroundColor
        }
    }

    private var borderColor: Color {
        isSelected ? theme.accentColor : theme.borderColor
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: item.contentType.iconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.secondaryTextColor)

            Text(item.contentType.localizedName)
                .font(theme.captionFont)
                .fontWeight(.semibold)
                .foregroundStyle(theme.secondaryTextColor)

            Spacer()

            if !item.sourceDevices.isEmpty {
                deviceNameView
            }

            Text(timestampText)
                .font(theme.captionFont)
                .foregroundStyle(theme.tertiaryTextColor)

            if aiEnabled {
                iconButton(
                    icon: "sparkles",
                    active: false,
                    help: NSLocalizedString("card.aiActions", bundle: .module, comment: "")
                ) {
                    showAIPopover.toggle()
                }
                .popover(isPresented: $showAIPopover) {
                    AIActionsPopover(
                        item: item,
                        theme: theme,
                        onAction: { action in
                            showAIPopover = false
                            onAIAction?(action)
                        }
                    )
                }
            }

            iconButton(
                icon: item.isFavorite ? "star.fill" : "star",
                active: item.isFavorite,
                help: item.isFavorite
                    ? NSLocalizedString("card.removeFromFavorites", bundle: .module, comment: "")
                    : NSLocalizedString("card.addToFavorites", bundle: .module, comment: "")
            ) {
                onToggleFavorite?()
            }
        }
    }

    private var deviceNameView: some View {
        let currentID = DeviceIdentity.current.id
        let names = item.sourceDevices
            .map { $0.id == currentID ? NSLocalizedString("device.thisMac", bundle: .module, comment: "") : $0.name }
            .sorted()
        let display = names.joined(separator: ", ")

        return Label(display, systemImage: "desktopcomputer")
            .font(theme.captionFont)
            .foregroundStyle(theme.secondaryTextColor)
            .lineLimit(1)
            .help(String(format: NSLocalizedString("card.deviceTooltip", bundle: .module, comment: ""), display))
    }

    private func iconButton(icon: String, active: Bool, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(active ? theme.accentColor : theme.secondaryTextColor)
                .symbolEffect(.bounce, value: active)
                .frame(width: 34, height: 34)
                .contentShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func copyButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.accentColor)
                .frame(width: 34, height: 34)
                .contentShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius))
        }
        .buttonStyle(.plain)
        .help("Copy to clipboard")
    }

    private var textContent: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(previewText)
                .font(theme.bodyFont)
                .foregroundStyle(theme.primaryTextColor)
                .lineLimit(5)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

            copyButton {
                copy()
            }
        }
    }

    private var videoContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if case .video(let url) = item.contentType, let url = url {
                VideoThumbnailView(
                    url: url,
                    maxHeight: 120,
                    cornerRadius: theme.cardCornerRadius / 2
                )
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Video unavailable")
                        .font(theme.bodyFont)
                        .foregroundStyle(theme.secondaryTextColor)
                    Spacer()
                }
                .frame(minHeight: 44)
            }

            HStack {
                Spacer()
                copyButton {
                    copy()
                }
            }
        }
    }

    private var imageContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let nsImage = loadImage() {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius / 2, style: .continuous))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Image unavailable")
                        .font(theme.bodyFont)
                        .foregroundStyle(theme.secondaryTextColor)
                    Spacer()
                }
                .frame(minHeight: 44)
            }

            HStack {
                Spacer()
                copyButton {
                    copy()
                }
            }
        }
    }

    private func loadImage() -> NSImage? {
        guard let data = item.imageData else { return nil }
        if let image = NSImage(data: data) {
            return image
        }
        return nil
    }

    private func copy() {
        NSPasteboard.general.clearContents()

        if case .image = item.contentType,
           let data = item.imageData {
            NSPasteboard.general.setData(data, forType: .tiff)
        } else {
            NSPasteboard.general.setString(item.rawText, forType: .string)
        }

        clipboardMonitor.ignoreNextChange = true
        copied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }

        onCopy?()
    }
}
