import Foundation
import AppKit
import ApplicationServices
import Carbon
import os.log

@MainActor
enum PasteHelper {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "dev.capy-copy", category: "PasteHelper")

    /// Copies `text` to the clipboard and attempts to paste it into `targetApp`.
    /// If the paste fails (e.g. missing Accessibility permissions),
    /// the text is still on the clipboard for manual pasting.
    static func paste(text: String, to targetApp: NSRunningApplication?) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        triggerPaste(in: targetApp)
    }

    /// Copies `imageData` to the clipboard as an image and attempts to paste it
    /// into `targetApp`.
    static func paste(imageData: Data, to targetApp: NSRunningApplication?) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setData(imageData, forType: .tiff)
        triggerPaste(in: targetApp)
    }

    /// Drops the NSAppleScript path entirely. The previous implementation built
    /// an AppleScript by string-interpolating `targetApp.bundleIdentifier` into
    /// a `tell application id "..."` block — a string-injection surface that
    /// could break out of the `tell` block with a maliciously-crafted bundle
    /// identifier. CGEvent Cmd+V is auditable in one screen of Swift, requires
    /// only the Accessibility entitlement, and lets the app ship without
    /// `com.apple.security.automation.apple-events`.
    /// (See docs/adr/0001-paste-helper-cgevent.md.)
    private static func triggerPaste(in targetApp: NSRunningApplication?) {
        let trusted = PermissionChecker.accessibilityIsGranted()
        logger.log("Accessibility granted: \(trusted)")
        guard trusted else {
            showAccessibilityPrompt()
            return
        }

        guard let targetApp = targetApp else {
            logger.log("No target app provided")
            return
        }

        logger.log("Pasting into target app: \(targetApp.bundleIdentifier ?? "nil", privacy: .public) pid=\(targetApp.processIdentifier)")

        // Activate the target app and wait until it is actually frontmost.
        // The panel may have shifted focus to Capy Copy, so we must restore
        // the target app before injecting Cmd+V.
        let activated = targetApp.activate(options: [])
        logger.log("activate returned: \(activated)")

        waitForFrontmost(targetApp: targetApp, deadline: .now() + 1.0) { isFrontmost in
            logger.log("Target app frontmost: \(isFrontmost)")
            guard PermissionChecker.accessibilityIsGranted() else {
                logger.log("Accessibility lost while waiting")
                return
            }

            guard let source = CGEventSource(stateID: .combinedSessionState) else {
                logger.log("Failed to create CGEventSource")
                return
            }

            // Avoid suppressing our own injected events.
            source.setLocalEventsFilterDuringSuppressionState(
                [.permitLocalMouseEvents, .permitSystemDefinedEvents],
                state: .eventSuppressionStateSuppressionInterval
            )

            let vKey = CGKeyCode(kVK_ANSI_V)
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) else {
                logger.log("Failed to create CGEvent")
                return
            }
            down.flags = .maskCommand
            up.flags = .maskCommand
            logger.log("Posting Cmd+V via cgSessionEventTap")
            down.post(tap: .cgSessionEventTap)
            up.post(tap: .cgSessionEventTap)
        }
    }

    private static func waitForFrontmost(targetApp: NSRunningApplication, deadline: DispatchTime, completion: @escaping (Bool) -> Void) {
        func check() {
            let frontmost = NSWorkspace.shared.frontmostApplication
            if frontmost?.processIdentifier == targetApp.processIdentifier {
                completion(true)
            } else if DispatchTime.now() >= deadline {
                logger.log("Timeout waiting for target app frontmost; current frontmost: \(frontmost?.bundleIdentifier ?? "nil", privacy: .public)")
                completion(false)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: check)
            }
        }
        check()
    }

    private static func showAccessibilityPrompt() {
        PermissionChecker.requestAccessibilityAccess()
    }
}
