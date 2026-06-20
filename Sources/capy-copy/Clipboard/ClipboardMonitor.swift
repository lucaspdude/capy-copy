import Foundation
import AppKit
import Combine

@MainActor
final class ClipboardMonitor: ObservableObject {
    @Published private(set) var lastContent: String?

    var ignoreNextChange = false
    var onNewContent: ((String) -> Void)?
    var onNewImage: ((Data) -> Void)?
    var onNewVideo: ((URL) -> Void)?
    var onNewMedia: ((DetectedContent) -> Void)?

    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    func start() {
        stop()
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let pasteboard = NSPasteboard.general

        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if ignoreNextChange {
            ignoreNextChange = false
            return
        }

        if let image = NSImage(pasteboard: pasteboard),
           let imageData = image.tiffRepresentation {
            onNewImage?(imageData)
            return
        }

        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           let fileURL = fileURLs.first {
            if fileURL.isVideo {
                onNewVideo?(fileURL)
                return
            }
            if fileURL.pathExtension.lowercased() == "pdf" {
                onNewMedia?(.media)
                return
            }
        }

        if let types = pasteboard.types as? [String],
           types.contains("com.adobe.pdf") {
            onNewMedia?(.media)
            return
        }

        guard let string = pasteboard.string(forType: .string) else { return }

        switch ClipboardFilter.decision(for: string) {
        case .ignore:
            return
        case .accept:
            guard string != lastContent else { return }
            lastContent = string
            onNewContent?(string)
        }
    }
}
