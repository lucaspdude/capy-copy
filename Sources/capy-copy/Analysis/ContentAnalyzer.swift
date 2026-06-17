import Foundation

struct ContentAnalyzer {
    static func analyze(_ text: String) -> DetectedContent {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .text }

        if isURL(trimmed) {
            return .url
        }

        if isCode(trimmed) {
            return .code
        }

        if let date = detectDate(in: trimmed) {
            return .date(date)
        }

        if let address = detectAddress(in: trimmed) {
            return .address(address)
        }

        return .text
    }

    private static func isURL(_ text: String) -> Bool {
        text.lowercased().hasPrefix("http://") || text.lowercased().hasPrefix("https://")
    }

    private static func isCode(_ text: String) -> Bool {
        let indicators = [
            "{", ";", "def ", "func ", "=>", "class ", "import ",
            "const ", "let ", "var ", "#include", "function ", "return "
        ]

        for indicator in indicators {
            if text.contains(indicator) {
                return true
            }
        }

        let openBraces = text.filter { $0 == "{" }.count
        let closeBraces = text.filter { $0 == "}" }.count
        if openBraces > 0 && closeBraces > 0 {
            return true
        }

        let indentedLines = text.components(separatedBy: .newlines).filter {
            $0.starts(with: "    ") || $0.starts(with: "\t")
        }.count
        if indentedLines >= 2 {
            return true
        }

        return false
    }

    private static func detectDate(in text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)

        guard let firstDate = matches.first?.date else { return nil }

        let coveredLength = matches.reduce(0) { $0 + $1.range.length }
        let coverage = Double(coveredLength) / Double(text.count)

        if coverage >= 0.15 || text.count < 80 || containsTaskKeywords(text) {
            return firstDate
        }

        return nil
    }

    private static func detectAddress(in text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.address.rawValue) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)

        guard let match = matches.first else { return nil }

        let coveredLength = matches.reduce(0) { $0 + $1.range.length }
        let coverage = Double(coveredLength) / Double(text.count)

        if coverage >= 0.5 || text.count < 100 {
            return (text as NSString).substring(with: match.range)
        }

        return nil
    }

    private static func containsTaskKeywords(_ text: String) -> Bool {
        let keywords = [
            "meeting", "call", "remember", "todo", "task", "appointment",
            "event", "deadline", "follow up", "sync", "standup", "review",
            "interview", "consulta", "reunião", "reuniao", "lembrar",
            "tarefa", "compromisso", "evento", "prazo", "entrega"
        ]

        let lowercased = text.lowercased()
        return keywords.contains { lowercased.contains($0) }
    }
}
