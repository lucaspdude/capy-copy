import AppKit
import os.log

@MainActor
struct NotesHelper {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "dev.capy-copy", category: "NotesHelper")

    /// Creates a new note in the Notes app using AppleScript.
    ///
    /// This requires Automation permission for Notes. The first call triggers
    /// the system prompt; if the user denies it, System Settings is opened.
    static func addNote(title: String, body: String) {
        let scriptSource = """
        tell application "Notes"
            activate
            make new note at folder "Notes" with properties {name:"\(appleScriptEscape(title))", body:"\(appleScriptEscape(body))"}
        end tell
        """

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: scriptSource) else {
            logger.error("Failed to initialize AppleScript for Notes.")
            return
        }

        script.executeAndReturnError(&errorInfo)

        if let errorInfo = errorInfo,
           let errorNumber = errorInfo[NSAppleScript.errorNumber] as? Int,
           errorNumber == -1743 {
            logger.warning("Automation permission for Notes denied.")
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        } else if let errorInfo = errorInfo {
            logger.error("AppleScript error: \(errorInfo)")
        }
    }

    private static func appleScriptEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
