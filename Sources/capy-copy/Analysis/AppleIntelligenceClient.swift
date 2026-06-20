import Foundation

/// Concrete foundation-model client using Apple Intelligence.
///
/// This is a scaffold: the actual private `FoundationModels` framework invocation
/// must be added by an engineer with access to the framework headers. The
/// surrounding parsing and categorization logic is complete.
actor AppleIntelligenceClient: FoundationModelClient {
    func analyze(_ text: String, contentType: DetectedContent) async throws -> AnalysisResult {
        guard !contentType.isMedia else {
            return AnalysisResult(category: contentType, explanation: "")
        }

        // TODO: Replace with actual private FoundationModels API call.
        //
        // Prompt shape:
        //   "Categorize the following clipboard text as one of: url, code,
        //    date, address, text. If date or address, extract the value.
        //    Return strict JSON: {\"category\":\"...\",\"value\":\"...\",\"explanation\":\"...\"}
        //
        //    Text: \(text)"
        //
        // For now, return the rule-based category with the original text as the
        // explanation so the UI can still render actions.
        let output = ModelOutput(category: categoryName(for: contentType), value: nil, explanation: text)
        return parse(output: output, fallback: contentType)
    }

    private func categoryName(for contentType: DetectedContent) -> String {
        switch contentType {
        case .url: return "url"
        case .code: return "code"
        case .date: return "date"
        case .address: return "address"
        case .text: return "text"
        case .image, .video, .media: return "media"
        }
    }

    private func parse(output: ModelOutput, fallback: DetectedContent) -> AnalysisResult {
        let category: DetectedContent
        switch output.category.lowercased() {
        case "url":
            category = .url
        case "code":
            category = .code
        case "date":
            if let value = output.value,
               let date = ISO8601DateFormatter().date(from: value) {
                category = .date(date)
            } else {
                category = fallback
            }
        case "address":
            category = .address(output.value ?? "")
        case "text":
            category = .text
        case "media":
            category = .media
        default:
            category = fallback
        }
        return AnalysisResult(category: category, explanation: output.explanation)
    }
}
