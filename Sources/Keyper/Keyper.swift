import AppKit
import Combine
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

/// Starts Keyper as a menu bar app (no Dock icon).
enum KeyperApp {
    static let delegate = AppDelegate()
    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

final class DropPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// The menu bar icon and its panel. Our own panel (not SwiftUI's MenuBarExtra window, which keeps the
/// size it once had and showed a glassy margin around the content) so it always fits what's inside.
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var item: NSStatusItem!
    var drop: DropPanel?
    var host: NSHostingView<AnyView>?
    var lastClose = Date.distantPast
    /// Where the open panel hangs from (under the icon).
    var anchor: NSPoint?
    var clickMonitor: Any?
    var watchers: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ n: Notification) {
        Updates.start()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = MenuBarIcon.image
        item.button?.target = self
        item.button?.action = #selector(toggleDrop)
        // For checking the panel on screen: `open Keyper.app --args -openOnLaunch YES [-openPage settings|mac]`.
        if UserDefaults.standard.bool(forKey: "openOnLaunch") {
            switch UserDefaults.standard.string(forKey: "openPage") {
            case "settings": UIState.shared.page = .settings
            case "mac": UIState.shared.page = .mac
            default: break
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.openDrop() }
        }
    }

    @objc func toggleDrop() {
        if drop?.isVisible == true { closeDrop(); return }
        // The same click on the icon may already have closed it a moment ago; then it meant "close".
        if Date().timeIntervalSince(lastClose) < 0.4 { return }
        openDrop()
    }

    func openDrop() {
        if drop == nil {
            let p = DropPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                              styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = true
            p.level = .popUpMenu
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.isReleasedWhenClosed = false
            let fx = NSVisualEffectView()
            fx.material = .popover; fx.state = .active; fx.blendingMode = .behindWindow
            fx.wantsLayer = true; fx.layer?.cornerRadius = 12; fx.layer?.masksToBounds = true
            let h = NSHostingView(rootView: AnyView(PanelView().environmentObject(Store.shared).environmentObject(UIState.shared)))
            host = h
            h.autoresizingMask = [.width, .height]
            fx.addSubview(h)
            p.contentView = fx
            h.frame = fx.bounds
            p.delegate = self
            drop = p
            // Clicking anywhere in the panel that isn't a text box lets go of the box you were editing.
            NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak p] e in
                guard let p, e.window === p, let root = p.contentView else { return e }
                var v = root.hitTest(root.convert(e.locationInWindow, from: nil))
                while let view = v, !(view is NSTextField || view is NSText) { v = view.superview }
                if v == nil { p.makeFirstResponder(nil) }
                return e
            }
            // Resize whenever what's shown changes (page, text size, hidden items...).
            Store.shared.objectWillChange.merge(with: UIState.shared.objectWillChange)
                .sink { [weak self] _ in DispatchQueue.main.async { self?.fitDrop() } }.store(in: &watchers)
        }
        // Re-read every shortcut each time the panel opens, so the list is never out of date.
        Store.shared.refresh()
        fitDrop()
        drop?.makeKeyAndOrderFront(nil)
        item.button?.highlight(true)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closeDrop()
        }
    }

    func closeDrop() {
        if drop?.isVisible == true { lastClose = Date() }
        drop?.makeFirstResponder(nil)   // reopen without a name box still selected
        drop?.orderOut(nil)
        item.button?.highlight(false)
        if let c = clickMonitor { NSEvent.removeMonitor(c); clickMonitor = nil }
    }

    /// Exactly the size of the content, top edge pinned just under the icon.
    func fitDrop() {
        guard let h = host, let p = drop, let b = item.button, let bw = b.window else { return }
        let size = h.fittingSize
        guard size.width > 0, size.height > 0 else { return }
        let screen = bw.screen?.visibleFrame ?? NSScreen.main!.visibleFrame
        let height = min(ceil(size.height), screen.height - 24), width = ceil(size.width)
        let icon = bw.convertToScreen(b.convert(b.bounds, to: nil))
        // Placed once per opening, so it doesn't slide sideways while open (other menu bar items changing
        // width, like a "Running command" label, can nudge Keyper's icon).
        if p.isVisible == false || anchor == nil { anchor = NSPoint(x: icon.midX, y: icon.minY) }
        let a = anchor!
        let x = min(max(a.x - width / 2, screen.minX + 8), screen.maxX - width - 8)
        p.setFrame(NSRect(x: x, y: a.y - 6 - height, width: width, height: height), display: true)
    }

    func windowDidResignKey(_ n: Notification) {
        guard (n.object as? NSPanel) === drop else { return }
        // A popover inside the panel (icon picker, hover note) takes key for a moment; keep the panel open.
        if NSApp.keyWindow != nil && NSApp.keyWindow !== drop { return }
        if let b = item.button, let bw = b.window,
           bw.convertToScreen(b.convert(b.bounds, to: nil)).contains(NSEvent.mouseLocation) { return }
        closeDrop()
    }
}

/// Self-updating from GitHub releases (Sparkle). Checks about once a day.
enum Updates {
    static let controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
    static func start() { controller.startUpdater() }
    static func check() { controller.checkForUpdates(nil) }
}
