import Foundation
import Carbon

final class HotKeyManager {
    var onHotKey: (() -> Void)?

    private var eventHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    deinit {
        unregister()
    }

    func register(keyCode: UInt32 = UInt32(kVK_ANSI_V),
                  modifiers: UInt32 = UInt32(cmdKey | shiftKey)) -> Bool {
        unregister()

        let callback: EventHandlerUPP = { _, eventRef, userData -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                manager.onHotKey?()
            }
            return noErr
        }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventSpec,
            selfPtr,
            &eventHandlerRef
        )

        guard handlerStatus == noErr else { return false }

        let hotKeyID = EventHotKeyID(
            signature: FourCharCode("Capy".fourCharCode),
            id: 1
        )

        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &eventHotKeyRef
        )

        guard registerStatus == noErr else {
            unregister()
            return false
        }

        return true
    }

    func unregister() {
        if let eventHotKeyRef = eventHotKeyRef {
            UnregisterEventHotKey(eventHotKeyRef)
            self.eventHotKeyRef = nil
        }
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}

private extension String {
    var fourCharCode: FourCharCode {
        var result: FourCharCode = 0
        for char in self.utf8.prefix(4) {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}
