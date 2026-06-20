import Foundation

/// Test double for `FoundationModelClient`.
///
/// Use this in unit tests to avoid depending on Apple Intelligence availability.
actor MockFoundationModelClient: FoundationModelClient {
    var stub: AnalysisResult?

    init(stub: AnalysisResult? = nil) {
        self.stub = stub
    }

    func analyze(_ text: String, contentType: DetectedContent) async throws -> AnalysisResult {
        if contentType.isMedia {
            return AnalysisResult(category: contentType, explanation: "")
        }
        if let stub {
            return stub
        }
        return AnalysisResult(category: .text, explanation: "Mock analysis for: \(text)")
    }
}
