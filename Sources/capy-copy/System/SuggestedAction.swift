import Foundation

enum SuggestedAction: Equatable {
    case addToCalendar(date: Date?, analysis: String)
    case addToReminder(analysis: String)
    case openInMaps(address: String, provider: MapsProvider)
    case openInGoogleMaps(address: String)
    case addToNotes(text: String)

    var titleKey: String {
        switch self {
        case .addToCalendar: return "action.addToCalendar"
        case .addToReminder: return "action.addToReminders"
        case .openInMaps: return "action.openInMaps"
        case .openInGoogleMaps: return "action.openInGoogleMaps"
        case .addToNotes: return "action.addToNotes"
        }
    }

    var iconName: String {
        switch self {
        case .addToCalendar: return "calendar.badge.plus"
        case .addToReminder: return "checklist"
        case .openInMaps, .openInGoogleMaps: return "map"
        case .addToNotes: return "note.text.badge.plus"
        }
    }

    static func actions(for contentType: DetectedContent, analysis: String) -> [SuggestedAction] {
        switch contentType {
        case .date(let date):
            return [
                .addToCalendar(date: date, analysis: analysis),
                .addToReminder(analysis: analysis)
            ]
        case .address(let address):
            return [
                .openInMaps(address: address, provider: .appleMaps),
                .openInGoogleMaps(address: address)
            ]
        case .text, .url, .code:
            return [.addToNotes(text: analysis)]
        case .image, .video, .media:
            return []
        }
    }
}
