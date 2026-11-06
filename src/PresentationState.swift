import Foundation

/// Time is monotonic, supplied by the caller so transitions can be tested.
struct PresentationState {
    private(set) var lastMovement: TimeInterval = 0
    private(set) var locatorUntil: TimeInterval = 0
    mutating func recordMovement(at now: TimeInterval) { lastMovement = now }
    mutating func locate(at now: TimeInterval) { locatorUntil = now + 1.2 }
    mutating func cancelLocator() { locatorUntil = 0 }
    func isLocating(at now: TimeInterval) -> Bool { now < locatorUntil }
    func isVisible(enabled: Bool, hideWhenIdle: Bool, now: TimeInterval) -> Bool {
        isLocating(at: now) || (enabled && (!hideWhenIdle || now - lastMovement < 2))
    }
    static func allowsDisplay(selected: String, current: String) -> Bool {
        selected == "all" || selected == current
    }
}
