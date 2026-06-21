import XCTest
@testable import capy_copy

final class MapsProviderTests: XCTestCase {
    func testAppleMapsIsHTTPS() {
        let url = MapsProvider.appleMaps.mapsURL(for: "Times Square")
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "maps.apple.com")
    }

    func testSpecialCharactersDoNotBreakQuery() {
        let url = MapsProvider.appleMaps.mapsURL(for: "a&b=c#d")
        // The '&' and '=' and '#' must be percent-encoded inside the query value,
        // not interpreted as URL structure.
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.query, "q=a%26b%3Dc%23d")
    }

    func testGoogleMapsURL() {
        let url = MapsProvider.googleMaps.mapsURL(for: "1600 Amphitheatre Parkway")
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "www.google.com")
        XCTAssertTrue(url?.query?.contains("1600%20Amphitheatre%20Parkway") == true)
    }
}
