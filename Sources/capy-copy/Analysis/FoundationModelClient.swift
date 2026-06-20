import Foundation

/// JSON shape returned by the foundation model.
struct ModelOutput: Codable {
    let category: String
    let value: String?
    let explanation: String
}

/// Result of analyzing a clip with a foundation model.
struct AnalysisResult {
    let category: DetectedContent
    let explanation: String
}

/// Actor-bound client that analyzes clipboard text.
protocol FoundationModelClient: Actor {
    func analyze(_ text: String, contentType: DetectedContent) async throws -> AnalysisResult
}

/// Runtime capability detection for Apple Intelligence.
enum FoundationModelCapability {
    static var isSupported: Bool {
        // Apple Intelligence requires macOS 15+ and Apple Silicon.
        let major = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        guard major >= 15 else { return false }
        #if arch(arm64)
        // The private FoundationModels API is only available on Apple Silicon.
        return true
        #else
        return false
        #endif
    }
}
