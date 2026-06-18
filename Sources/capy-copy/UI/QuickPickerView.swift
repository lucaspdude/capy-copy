import SwiftUI

enum PickerTab: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .favorites: return "star.fill"
        case .settings: return "gear"
        }
    }

    var label: String {
        switch self {
        case .all: return NSLocalizedString("picker.tab.all", bundle: .module, comment: "")
        case .favorites: return NSLocalizedString("picker.tab.favorites", bundle: .module, comment: "")
        case .settings: return NSLocalizedString("picker.tab.settings", bundle: .module, comment: "")
        }
    }

    var showsSearchBar: Bool {
        self == .all || self == .favorites
    }
}

struct QuickPickerView: View {
    @StateObject var viewModel: QuickPickerViewModel
    @FocusState private var searchFieldIsFocused: Bool

    private var theme: ThemeDefinition { viewModel.settingsStore.selectedTheme.definition }

    var body: some View {
        HStack(spacing: 0) {
            mainContent

            Divider()
                .overlay(theme.dividerColor)

            sidebar
        }
        .frame(minWidth: 720, idealWidth: 840, maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.windowBackground)
        .foregroundStyle(theme.primaryTextColor)
        .font(theme.bodyFont)
        .ignoresSafeArea(.container, edges: .top)
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            if viewModel.selectedTab.showsSearchBar {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
            }

            Group {
                switch viewModel.selectedTab {
                case .all:
                    itemList(items: viewModel.filteredItems)
                case .favorites:
                    itemList(items: viewModel.filteredFavoriteItems, mode: .favorites)
                case .settings:
                    SettingsFormView(settingsStore: viewModel.settingsStore)
                        .padding(.horizontal, 16)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.secondaryTextColor)
                .font(theme.bodyFont)

            TextField(
                NSLocalizedString("picker.searchPlaceholder", bundle: .module, comment: ""),
                text: $viewModel.searchText
            )
                .textFieldStyle(.plain)
                .font(theme.bodyFont)
                .foregroundStyle(theme.primaryTextColor)
                .focused($searchFieldIsFocused)
                .onAppear {
                    searchFieldIsFocused = true
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.secondaryTextColor)
                        .font(theme.bodyFont)
                }
                .buttonStyle(.plain)
            }

            deviceScopeMenu
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(theme.searchBackgroundColor)
        .cornerRadius(theme.searchCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.searchCornerRadius)
                .stroke(theme.borderColor, lineWidth: theme.borderWidth)
        )
    }

    private var deviceScopeMenu: some View {
        Menu {
            ForEach(viewModel.availableDeviceScopes, id: \.self) { scope in
                Button {
                    viewModel.selectedDeviceScope = scope
                } label: {
                    Label(scope.label, systemImage: scope.icon)
                }
            }
        } label: {
            Image(systemName: viewModel.selectedDeviceScope.icon)
                .foregroundStyle(theme.secondaryTextColor)
                .font(theme.bodyFont)
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: true, vertical: false)
        .help(NSLocalizedString("picker.deviceScopeHelp", bundle: .module, comment: ""))
    }

    private func itemList(items: [ClipItem], mode: EmptyStateMode = .history) -> some View {
        Group {
            if items.isEmpty {
                EmptyStateView(theme: theme, mode: mode)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(items) { item in
                                ClipCard(
                                    item: item,
                                    isSelected: viewModel.isSelected(item),
                                    historyStore: viewModel.historyStore,
                                    clipboardMonitor: viewModel.clipboardMonitor,
                                    settingsStore: viewModel.settingsStore,
                                    onSelect: {
                                        viewModel.select(item)
                                        searchFieldIsFocused = false
                                    },
                                    onCopy: {
                                        viewModel.paste(item: item)
                                    },
                                    onToggleFavorite: {
                                        viewModel.toggleFavorite(item)
                                    }
                                )
                                .id(item.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.selectedItemID) { newID in
                        guard let newID = newID else { return }
                        withAnimation(.easeInOut(duration: 0.15)) {
                            proxy.scrollTo(newID, anchor: .center)
                        }
                    }
                    .onAppear {
                        if let id = viewModel.selectedItemID {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 6) {
            ForEach(PickerTab.allCases) { tab in
                tabButton(for: tab)
            }

            Spacer()

            Divider()
                .overlay(theme.dividerColor)

            VStack(spacing: 6) {
                actionButton(icon: "trash", label: "Clear", help: "Clear history") {
                    viewModel.clearHistory()
                }
                actionButton(icon: "power", label: "Quit", help: "Quit Capy Copy") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(width: 72)
        .background(theme.cardBackgroundColor.opacity(0.5))
    }

    private func tabButton(for tab: PickerTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.selectedTab = tab
            }
            if tab == .all || tab == .favorites {
                searchFieldIsFocused = true
            } else {
                searchFieldIsFocused = false
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                Text(tab.label)
                    .font(theme.captionFont)
            }
            .frame(width: 56, height: 48)
            .foregroundStyle(viewModel.selectedTab == tab ? theme.accentColor : theme.secondaryTextColor)
            .background(
                RoundedRectangle(cornerRadius: theme.tabButtonCornerRadius, style: .continuous)
                    .fill(viewModel.selectedTab == tab ? theme.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: theme.tabButtonCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func actionButton(icon: String, label: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(width: 56, height: 24)
            .foregroundStyle(theme.secondaryTextColor)
            .contentShape(RoundedRectangle(cornerRadius: theme.buttonCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
