import SwiftUI

// Hallmark 2.0 native workbench: semantic surfaces, system type, one green accent.
// Critique: prioritize a legible live preview and native focus over ornamental controls.
enum HaloTheme {
    static let primaryAction = Color(red: 0.08, green: 0.39, blue: 0.23)
    static let cursor = Font.system(size: 22, weight: .bold)
    static let accent = Color(nsColor: .systemGreen)
    static let text = Color.primary
    static let secondary = Color.secondary
    static let surface = Color(nsColor: .windowBackgroundColor)
    static let preview = Color(nsColor: .textBackgroundColor)
    static let divider = Color(nsColor: .separatorColor)
    static let title = Font.system(size: 21, weight: .semibold)
    static let body = Font.system(size: 13)
    static let label = Font.system(size: 12, weight: .medium)
    static let caption = Font.system(size: 11)
    static let radius: CGFloat = 12
}
