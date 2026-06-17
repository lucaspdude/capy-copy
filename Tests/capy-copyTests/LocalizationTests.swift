import XCTest
@testable import capy_copy

final class LocalizationTests: XCTestCase {
    let supportedLocales = ["en", "pt-BR", "es", "de", "fr", "ja", "zh-Hans"]

    /// The directory that holds the app's bundled resources (localizations,
    /// icons, privacy manifest). It lives at the repository root, outside the
    /// SwiftPM target path, so SwiftPM does not process it automatically.
    private var resourcesDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Tests/capy-copyTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repository root
            .appendingPathComponent("AppResources")
    }

    func testAllSupportedLocalesHaveSameKeysAsEnglish() throws {
        let englishURL = resourcesDirectory
            .appendingPathComponent("en.lproj")
            .appendingPathComponent("Localizable.strings")

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: englishURL.path),
            "Could not find English Localizable.strings at \(englishURL.path)"
        )

        let englishKeys = try keys(from: englishURL)
        XCTAssertFalse(englishKeys.isEmpty, "English strings file should not be empty")

        for locale in supportedLocales {
            let localeURL = resourcesDirectory
                .appendingPathComponent("\(locale).lproj")
                .appendingPathComponent("Localizable.strings")

            XCTAssertTrue(
                FileManager.default.fileExists(atPath: localeURL.path),
                "Missing Localizable.strings for locale \(locale)"
            )

            let localeKeys = try keys(from: localeURL)
            let missing = englishKeys.subtracting(localeKeys)
            let extra = localeKeys.subtracting(englishKeys)

            XCTAssertTrue(
                missing.isEmpty,
                "Locale \(locale) is missing keys: \(missing.sorted().joined(separator: ", "))"
            )
            XCTAssertTrue(
                extra.isEmpty,
                "Locale \(locale) has extra keys: \(extra.sorted().joined(separator: ", "))"
            )
        }
    }

    func testLocalizedStringsAreNotEmpty() throws {
        for locale in supportedLocales {
            let url = resourcesDirectory
                .appendingPathComponent("\(locale).lproj")
                .appendingPathComponent("Localizable.strings")

            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            let strings = try parseStrings(at: url)
            for (key, value) in strings {
                XCTAssertFalse(
                    value.isEmpty,
                    "Locale \(locale) has empty value for key \(key)"
                )
            }
        }
    }

    // MARK: - Helpers

    private func keys(from url: URL) throws -> Set<String> {
        Set(try parseStrings(at: url).keys)
    }

    private func parseStrings(at url: URL) throws -> [String: String] {
        let data = try Data(contentsOf: url)
        var format: PropertyListSerialization.PropertyListFormat = .binary
        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: &format
        ) as? [String: String] else {
            throw NSError(domain: "LocalizationTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to parse strings file"])
        }
        return plist
    }
}
