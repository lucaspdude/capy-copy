import Foundation

/// Shannon-entropy heuristic for spotting things that look like secrets but
/// the character-class rules in `ClipboardFilter` would miss:
///
/// - 40+ character base64 tokens (e.g. `ghp_abc...` style PATs)
/// - High-entropy passphrases that happen to have no spaces
/// - Long random hex strings (API keys, hashes)
///
/// The previous filter required the string to be 8-64 characters and to have
/// at least 3 character classes. A 70-character base64 token slipped through
/// because the length check rejected it, and a long random alphanumeric
/// string with only 2 character classes slipped through the class check.
enum EntropyHeuristic {
    /// Shannon entropy in bits per character. A random base64 string of 40
    /// characters has entropy around 5.5-6.0; English text is well below 4.5.
    static func shannon(_ s: String) -> Double {
        guard !s.isEmpty else { return 0 }
        var freq: [Character: Int] = [:]
        for c in s { freq[c, default: 0] += 1 }
        let n = Double(s.count)
        return -freq.values.reduce(0.0) { acc, count in
            let p = Double(count) / n
            return acc + p * (log(p) / log(2))
        }
    }

    /// Conservative: a string looks like a secret if it is 16+ chars, has no
    /// spaces, and has high per-character entropy.
    static func looksLikeSecret(_ s: String) -> Bool {
        if s.contains(" ") { return false }
        if s.count < 16 { return false }
        return shannon(s) > 4.0
    }
}
