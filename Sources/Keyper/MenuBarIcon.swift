import AppKit

/// The menu bar icon: hi-dad's own keycap logo (assets/logo.png, made black-on-transparent as
/// assets/menu-icon.png), used as a template image so macOS colors it for light and dark menu bars.
enum MenuBarIcon {
    static let image: NSImage = {
        let file = Bundle.main.url(forResource: "menu-icon", withExtension: "png")
            ?? URL(fileURLWithPath: "assets/menu-icon.png")   // running from .build in the repo folder
        let img = NSImage(contentsOf: file) ?? NSImage(systemSymbolName: "command", accessibilityDescription: nil)!
        img.size = NSSize(width: 18, height: 18)
        img.isTemplate = true
        img.accessibilityDescription = "Keyper"
        return img
    }()
}
