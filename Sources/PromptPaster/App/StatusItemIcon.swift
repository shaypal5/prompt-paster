import AppKit

enum StatusItemIcon {
    static let accessibilityDescription = "Prompt Paster"
    static let symbolName = "text.bubble.fill"
    static let pointSize: CGFloat = 16

    static func makeMenuBarImage() -> NSImage {
        let symbolImage = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: accessibilityDescription
        ) ?? NSImage(size: NSSize(width: 18, height: 18))
        let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        let image = symbolImage.withSymbolConfiguration(configuration) ?? symbolImage
        image.isTemplate = true
        image.accessibilityDescription = accessibilityDescription
        return image
    }
}
