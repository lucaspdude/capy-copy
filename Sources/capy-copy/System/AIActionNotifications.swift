import Foundation

extension Notification.Name {
    /// Posted when the user presses the Space shortcut to open the AI actions
    /// popover for the currently selected history item. The `object` is the
    /// selected `ClipItem.ID`.
    static let openAIActions = Notification.Name("dev.capy-copy.openAIActions")
}
