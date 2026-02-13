import Carbon
import AppKit

final class HotkeyManager {
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var onHotkey: (() -> Void)?

    private static var shared: HotkeyManager?

    func register() {
        HotkeyManager.shared = self

        // Cmd+Shift+C
        // Carbon key code for 'C' is 8
        var hotkeyID = EventHotKeyID()
        hotkeyID.signature = OSType(0x434C4950) // "CLIP"
        hotkeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_: EventHandlerCallRef?, event: EventRef?, _: UnsafeMutableRawPointer?) -> OSStatus in
                HotkeyManager.shared?.onHotkey?()
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        if status != noErr {
            NSLog("HotkeyManager: InstallEventHandler failed: \(status)")
            return
        }

        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 8 // 'C'

        let regStatus = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        if regStatus != noErr {
            NSLog("HotkeyManager: RegisterEventHotKey failed: \(regStatus)")
        }
    }

    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}
