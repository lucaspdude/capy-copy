import XCTest
@testable import capy_copy

final class MapsProviderTests: XCTestCase {
    func testAppleMapsIsHTTPS() {
        let url = MapsProvider.appleMaps.mapsURL(for: "Times Square")
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "maps.apple.com")
    }

    func testGoogleMapsIsHTTPS() {
        let url = MapsProvider.googleMaps.mapsURL(for: "Times Square")
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "www.google.com")
    }

    func testSpecialCharactersDoNotBreakQuery() {
        let url = MapsProvider.appleMaps.mapsURL(for: "a&b=c#d")
        // The '&' and '=' and '#' must be percent-encoded inside the query value,
        // not interpreted as URL structure.
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.query, "q=a%26b%3Dc%23d")
    }
}
