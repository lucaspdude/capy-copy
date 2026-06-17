import AppKit

@MainActor
struct MapsHelper {
    static func open(_ address: String, provider: MapsProvider) {
        guard let url = provider.mapsURL(for: address) else { return }
        NSWorkspace.shared.open(url)
    }
}
