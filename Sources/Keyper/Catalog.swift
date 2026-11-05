import Foundation

enum Catalog {
    /// My own apps register their hotkeys in code, so Keyper knows them here. Shown only when installed
    /// (found by app name in Applications; the bundle ID is read from the installed app).
    struct OwnApp {
        var bundleID = ""
        let name: String
        /// The .app's file name, when it isn't the same as the name.
        var file: String? = nil
        let icon: String
        let color: String
        var shortcuts: [(String, String)]
    }

    static func ownApps() -> [OwnApp] {
        let list = [
            OwnApp(name: "Shelfie", icon: "photo", color: "purple", shortcuts: [
                ("Peek at shelf", "{opt}`"),
                ("Pick category", "1–5"),
                ("Discard", "6"),
                ("Use default", "Esc"),
            ]),
            OwnApp(name: "Copy Collector", file: "CopyCollector", icon: "doc.on.clipboard", color: "teal", shortcuts: [
                ("Collect on/off", "{ctl}{opt}C"),
                ("Add to pile", "{cmd}C"),
                ("Paste pile", "{cmd}V"),
            ]),
            OwnApp(name: "Window Pane Relief", icon: "pin", color: "orange", shortcuts: [
                ("Pin on top", "{ctl}{opt}P"),
            ]),
            OwnApp(name: "Paperlight", icon: "book", color: "yellow", shortcuts: [
                ("Filter on/off", "{ctl}{opt}R"),
            ]),
        ]
        let folders = ["/Applications", NSHomeDirectory() + "/Applications"]
        return list.compactMap { a in
            guard let id = folders.lazy.compactMap({ Bundle(path: "\($0)/\(a.file ?? a.name).app")?.bundleIdentifier }).first
            else { return nil }
            var a = a
            a.bundleID = id
            // Shelfie can be set to peek with a plain ` instead of ⌥`.
            if a.name == "Shelfie", CFPreferencesCopyAppValue("plainBacktick" as CFString, id as CFString) as? Bool == true {
                a.shortcuts[0].1 = "`"
            }
            return a
        }
    }

    /// Icons and colors offered in Settings for a section.
    static let icons = ["camera", "photo", "doc.on.clipboard", "pin", "book", "message", "apple.logo", "folder",
                        "doc.on.doc", "music.note", "headphones", "mic", "video", "globe", "safari",
                        "chevron.left.forwardslash.chevron.right", "terminal", "keyboard", "desktopcomputer", "macwindow",
                        "bolt", "paintbrush", "paintpalette", "pencil", "scissors", "wand.and.stars", "envelope",
                        "calendar", "note.text", "cloud", "lock", "magnifyingglass", "lightbulb", "moon", "sun.max",
                        "pawprint", "gamecontroller", "cart", "mappin", "heart", "star", "gearshape", "textformat",
                        "square.grid.2x2", "command", "sparkles", "film", "cup.and.saucer"]
    static let colors = ["blue", "purple", "teal", "orange", "yellow", "green", "pink", "red", "gray"]
}
