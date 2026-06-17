import XCTest
@testable import capy_copy

final class LocalizationTests: XCTestCase {
    let supportedLocales = ["en", "pt-BR", "es", "de", "fr", "ja", "zh-Hans"]

    func testAllSupportedLocalesHaveSameKeysAsEnglish() throws {
        let bundle = Bundle.module
        guard let englishURL = bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: "en") else {
            XCTFail("Could not find English Localizable.strings")
            return
        }

        let englishKeys = try keys(from: englishURL)
        XCTAssertFalse(englishKeys.isEmpty, "English strings file should not be empty")

        for locale in supportedLocales {
            guard let url = bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: locale) else {
                XCTFail("Missing Localizable.strings for locale \(locale)")
                continue
            }

            let localeKeys = try keys(from: url)
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
        let bundle = Bundle.module
        for locale in supportedLocales {
            guard let url = bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: locale) else {
                continue
            }

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
