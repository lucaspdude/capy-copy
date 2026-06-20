import XCTest
@testable import capy_copy

final class SuggestedActionTests: XCTestCase {
    func testActionsForDate() {
        let date = Date()
        let actions = SuggestedAction.actions(for: .date(date), analysis: "Dinner tomorrow at 7pm")
        XCTAssertTrue(actions.contains { $0.titleKey == "action.addToCalendar" })
        XCTAssertTrue(actions.contains { $0.titleKey == "action.addToReminders" })
    }

    func testActionsForAddress() {
        let actions = SuggestedAction.actions(for: .address("1600 Amphitheatre Parkway"), analysis: "")
        XCTAssertTrue(actions.contains { $0.titleKey == "action.openInMaps" })
        XCTAssertTrue(actions.contains { $0.titleKey == "action.openInGoogleMaps" })
    }

    func testActionsForText() {
        let actions = SuggestedAction.actions(for: .text, analysis: "Remember to buy milk")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions.first?.titleKey, "action.addToNotes")
    }

    func testActionsForMediaIsEmpty() {
        let actions = SuggestedAction.actions(for: .media, analysis: "")
        XCTAssertTrue(actions.isEmpty)
    }
}
