import Carbon
import AppKit

class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    var onTrigger: (() -> Void)?
    
    init() {
        setupHandler()
    }
    
    private func setupHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if status == noErr {
                    if hotKeyID.signature == OSType(0x48414c4f) && hotKeyID.id == 1 { // "HALO" in hex
                        DispatchQueue.main.async {
                            manager.onTrigger?()
                        }
                    }
                }
                
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
        
        if status != noErr {
            print("Failed to install application event handler: \(status)")
        }
    }
    
    func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        
        let signature = OSType(0x48414c4f) // "HALO"
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        
        if status == noErr {
            self.hotKeyRef = ref
        } else {
            print("Failed to register hotkey: \(status)")
        }
    }
    
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    deinit {
        unregister()
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
        }
    }
}
