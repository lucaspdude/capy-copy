import Foundation

/// Dispatches AI-suggested actions to the appropriate system helper.
@MainActor
final class ActionDispatcher {
    static let shared = ActionDispatcher()

    private init() {}

    func handle(_ action: SuggestedAction) {
        switch action {
        case .addToCalendar(let date, let analysis):
            Task {
                await CalendarHelper.addEvent(title: analysis, date: date, notes: analysis)
            }
        case .addToReminder(let analysis):
            Task {
                await RemindersHelper.addReminder(title: analysis, notes: analysis)
            }
        case .openInMaps(let address, let provider):
            MapsHelper.open(address, provider: provider)
        case .openInGoogleMaps(let address):
            MapsHelper.open(address, provider: .googleMaps)
        case .addToNotes(let text):
            let title = String(text.prefix(60))
            NotesHelper.addNote(title: title, body: text)
        }
    }
}
