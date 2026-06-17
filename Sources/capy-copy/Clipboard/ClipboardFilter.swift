import Foundation

enum FilterDecision: Equatable {
    case accept
    case ignore(FilterReason)
}

enum FilterReason: Equatable {
    case tooShort
    case empty
    case likelySecret
}

enum ClipboardFilter {
    static let minimumLength = 5

    static func decision(for text: String) -> FilterDecision {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .ignore(.empty)
        }

        if trimmed.count < minimumLength {
            return .ignore(.tooShort)
        }

        if !isURL(trimmed), isLikelySecret(trimmed) || EntropyHeuristic.looksLikeSecret(trimmed) {
            return .ignore(.likelySecret)
        }

        return .accept
    }

    private static func isURL(_ text: String) -> Bool {
        text.lowercased().hasPrefix("http://") || text.lowercased().hasPrefix("https://")
    }

    private static func isLikelySecret(_ text: String) -> Bool {
        guard !text.contains(" "), (8...64).contains(text.count) else {
            return false
        }

        var hasUpper = false
        var hasLower = false
        var hasDigit = false
        var hasSymbol = false

        let letters = CharacterSet.letters
        let digits = CharacterSet.decimalDigits
        let symbols = CharacterSet.alphanumerics.inverted

        for scalar in text.unicodeScalars {
            if letters.contains(scalar) {
                if scalar.properties.isUppercase {
                    hasUpper = true
                } else {
                    hasLower = true
                }
            } else if digits.contains(scalar) {
                hasDigit = true
            } else if symbols.contains(scalar) {
                hasSymbol = true
            }
        }

        let categories = [hasUpper, hasLower, hasDigit, hasSymbol].filter { $0 }.count
        return categories >= 3
    }
}
