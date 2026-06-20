import XCTest
@testable import capy_copy

@MainActor
final class ClipboardMonitorTests: XCTestCase {
    func testMonitorHasMediaCallback() {
        let monitor = ClipboardMonitor()
        var received: DetectedContent?
        monitor.onNewMedia = { contentType in
            received = contentType
        }
        monitor.onNewMedia?(.media)
        XCTAssertEqual(received, .media)
    }
}
