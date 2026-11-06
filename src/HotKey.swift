import Carbon
import AppKit

final class HotKeyManager {
    private var references: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?
    private var actions: [UInt32: () -> Void] = [:]

    init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            var identifier = EventHotKeyID()
            let result = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                           nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard result == noErr, identifier.signature == OSType(0x48414c4f),
                  let action = manager.actions[identifier.id] else { return OSStatus(eventNotHandledErr) }
            DispatchQueue.main.async(execute: action)
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    func register(id: UInt32, keyCode: UInt32, extraModifiers: UInt32 = 0, action: @escaping () -> Void) -> OSStatus {
        guard handler != nil else { return OSStatus(eventInternalErr) }
        var reference: EventHotKeyRef?
        let identifier = EventHotKeyID(signature: OSType(0x48414c4f), id: id)
        let result = RegisterEventHotKey(keyCode, UInt32(cmdKey | shiftKey) | extraModifiers, identifier,
                                        GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &reference)
        if result == noErr, let reference {
            references.append(reference)
            actions[id] = action
        }
        return result
    }
    func unregister() {
        references.forEach { UnregisterEventHotKey($0) }
        references.removeAll()
        actions.removeAll()
    }
    deinit {
        unregister()
        if let handler { RemoveEventHandler(handler) }
    }
}
