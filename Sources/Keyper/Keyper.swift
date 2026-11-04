import AppKit
import Sparkle
import SwiftUI

@main
enum KeyperMain {
    static func main() {
        // `Keyper --render out.png [--page mine|mac|settings]` draws the panel to a picture (for checking the
        // design and for the README). Works offscreen.
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--render-icon"), i + 1 < args.count {
            // Menu bar icon at 8× on light and dark, for checking the drawing.
            _ = NSApplication.shared
            let big = NSImage(size: NSSize(width: 300, height: 150), flipped: false) { _ in
                for (x, bg, fg) in [(0.0, NSColor.white, NSColor.black), (150.0, NSColor(white: 0.15, alpha: 1), NSColor.white)] {
                    bg.setFill(); NSRect(x: x, y: 0, width: 150, height: 150).fill()
                    let tinted = NSImage(size: MenuBarIcon.image.size, flipped: false) { r in
                        MenuBarIcon.image.draw(in: r); fg.set(); r.fill(using: .sourceAtop); return true
                    }
                    tinted.draw(in: NSRect(x: x + 3, y: 3, width: 144, height: 144))
                }
                return true
            }
            if let tiff = big.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) {
                try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: args[i + 1]))
            }
            return
        }
        if let i = args.firstIndex(of: "--render"), i + 1 < args.count {
            let page = args.firstIndex(of: "--page").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
            render(to: args[i + 1], page: page ?? "mine")
            return
        }
        KeyperApp.main()
    }

    static func render(to path: String, page: String) {
        _ = NSApplication.shared
        let ui = UIState.shared
        ui.picture = true
        ui.page = page == "mac" ? .mac : page.hasPrefix("settings") ? .settings : .mine
        ui.addFormOpen = page == "settings-add"
        Store.shared.refreshNow()
        let view = PanelView().environmentObject(Store.shared).environmentObject(ui)
            .background(Color(nsColor: NSColor(white: 0.16, alpha: 1)))
            .environment(\.colorScheme, .dark)
        let host = NSHostingView(rootView: view)
        host.appearance = NSAppearance(named: .darkAqua)
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        host.layoutSubtreeIfNeeded()
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
        print("wrote", path, host.bounds.size)
    }
}

struct KeyperApp: App {
    @StateObject var store = Store.shared
    @StateObject var ui = UIState.shared

    init() { Updates.start() }

    var body: some Scene {
        MenuBarExtra {
            PanelView()
                .environmentObject(store)
                .environmentObject(ui)
                // Re-read every shortcut each time the panel opens, so the list is never out of date.
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                    store.refresh()
                }
                .onAppear { store.refresh() }
        } label: {
            Image(nsImage: MenuBarIcon.image)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Self-updating from GitHub releases (Sparkle). Checks about once a day.
enum Updates {
    static let controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
    static func start() { controller.startUpdater() }
    static func check() { controller.checkForUpdates(nil) }
}
