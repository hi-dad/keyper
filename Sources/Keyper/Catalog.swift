import Foundation

/// One built-in Mac shortcut for the "All Mac shortcuts" page. `symbolic` is its number in macOS's own shortcut
/// settings, when it has one: Keyper reads that to show what's really set on this Mac. In `keys`, "{@30}" means
/// "whatever shortcut 30 is set to" (for combos built on another shortcut).
struct RefShortcut {
    /// The full name (also its saved id, so it never changes).
    let name: String
    /// A shorter name shown in the panel.
    var label: String? = nil
    let keys: String
    var symbolic: Int? = nil
    var id: String { "mac:" + name }
    var display: String { label ?? name }
}

struct RefCategory {
    let id: String
    let name: String
    let icon: String
    let color: String
    let items: [RefShortcut]
}

enum Catalog {
    static let mac: [RefCategory] = [
        RefCategory(id: "mac.screenshots", name: "Screenshots", icon: "camera", color: "blue", items: [
            RefShortcut(name: "Save whole screen to file", label: "Save screen", keys: "{sh}{cmd}3", symbolic: 28),
            RefShortcut(name: "Copy whole screen", label: "Copy screen", keys: "{ctl}{sh}{cmd}3", symbolic: 29),
            RefShortcut(name: "Save selected area to file", label: "Save area", keys: "{sh}{cmd}4", symbolic: 30),
            RefShortcut(name: "Copy selected area", label: "Copy area", keys: "{ctl}{sh}{cmd}4", symbolic: 31),
            RefShortcut(name: "Capture one window", label: "Capture window", keys: "{@30} → Space"),
            RefShortcut(name: "Screenshot and recording controls", label: "Screenshot tools", keys: "{sh}{cmd}5", symbolic: 184),
        ]),
        RefCategory(id: "mac.apps", name: "Search and apps", icon: "magnifyingglass", color: "gray", items: [
            RefShortcut(name: "Spotlight search", label: "Spotlight", keys: "{cmd}Space", symbolic: 64),
            RefShortcut(name: "Finder search window", label: "Finder search", keys: "{opt}{cmd}Space", symbolic: 65),
            RefShortcut(name: "Switch apps", keys: "{cmd}Tab"),
            RefShortcut(name: "Switch windows in an app", label: "Switch windows", keys: "{cmd}`"),
            RefShortcut(name: "App settings", keys: "{cmd},"),
            RefShortcut(name: "Hide app", keys: "{cmd}H"),
            RefShortcut(name: "Hide other apps", label: "Hide others", keys: "{opt}{cmd}H"),
            RefShortcut(name: "Quit app", label: "Quit", keys: "{cmd}Q"),
            RefShortcut(name: "Force quit", keys: "{opt}{cmd}Esc"),
            RefShortcut(name: "Show the app's help menu", label: "Help menu", keys: "{sh}{cmd}/"),
        ]),
        RefCategory(id: "mac.windows", name: "Windows and tabs", icon: "macwindow", color: "gray", items: [
            RefShortcut(name: "Close window", keys: "{cmd}W"),
            RefShortcut(name: "Close all windows of the app", label: "Close all", keys: "{opt}{cmd}W"),
            RefShortcut(name: "Minimize", keys: "{cmd}M"),
            RefShortcut(name: "New window", keys: "{cmd}N"),
            RefShortcut(name: "New tab", keys: "{cmd}T"),
            RefShortcut(name: "Reopen closed tab", label: "Reopen tab", keys: "{sh}{cmd}T"),
            RefShortcut(name: "Next tab", keys: "{ctl}Tab"),
            RefShortcut(name: "Full screen", keys: "{ctl}{cmd}F"),
            RefShortcut(name: "See all open windows", label: "All windows", keys: "{ctl}↑", symbolic: 32),
            RefShortcut(name: "See this app's windows", label: "App windows", keys: "{ctl}↓", symbolic: 33),
            RefShortcut(name: "Show desktop", keys: "F11", symbolic: 36),
            RefShortcut(name: "Move one space left", label: "Space left", keys: "{ctl}←", symbolic: 79),
            RefShortcut(name: "Move one space right", label: "Space right", keys: "{ctl}→", symbolic: 81),
        ]),
        RefCategory(id: "mac.text", name: "Text", icon: "textformat", color: "gray", items: [
            RefShortcut(name: "Copy", keys: "{cmd}C"),
            RefShortcut(name: "Cut", keys: "{cmd}X"),
            RefShortcut(name: "Paste", keys: "{cmd}V"),
            RefShortcut(name: "Paste matching formatting", label: "Paste & match", keys: "{opt}{sh}{cmd}V"),
            RefShortcut(name: "Undo", keys: "{cmd}Z"),
            RefShortcut(name: "Redo", keys: "{sh}{cmd}Z"),
            RefShortcut(name: "Select all", keys: "{cmd}A"),
            RefShortcut(name: "Find", keys: "{cmd}F"),
            RefShortcut(name: "Find next", keys: "{cmd}G"),
            RefShortcut(name: "Move by word", label: "Word jump", keys: "{opt}← / →"),
            RefShortcut(name: "Jump to line start / end", label: "Line start/end", keys: "{cmd}← / →"),
            RefShortcut(name: "Jump to top / bottom", label: "Top/bottom", keys: "{cmd}↑ / ↓"),
            RefShortcut(name: "Select while moving", keys: "add {sh}"),
            RefShortcut(name: "Delete previous word", label: "Delete word", keys: "{opt}Delete"),
            RefShortcut(name: "Delete to line start", label: "Delete line", keys: "{cmd}Delete"),
            RefShortcut(name: "Delete forward", label: "Forward delete", keys: "Fn Delete"),
            RefShortcut(name: "Bold / italic / underline", label: "Bold/italic/underline", keys: "{cmd}B / I / U"),
            RefShortcut(name: "Emoji picker", label: "Emoji", keys: "{ctl}{cmd}Space"),
        ]),
        RefCategory(id: "mac.finder", name: "Finder", icon: "folder", color: "gray", items: [
            RefShortcut(name: "Preview file", label: "Preview", keys: "Space"),
            RefShortcut(name: "Open", keys: "{cmd}O"),
            RefShortcut(name: "Duplicate", keys: "{cmd}D"),
            RefShortcut(name: "Get info", keys: "{cmd}I"),
            RefShortcut(name: "New folder", keys: "{sh}{cmd}N"),
            RefShortcut(name: "Rename", keys: "Return"),
            RefShortcut(name: "Move copied files", label: "Move files", keys: "{cmd}C → {opt}{cmd}V"),
            RefShortcut(name: "Move to Trash", label: "Trash", keys: "{cmd}Delete"),
            RefShortcut(name: "Go to folder path", label: "Go to path", keys: "{sh}{cmd}G"),
            RefShortcut(name: "Parent folder", label: "Up a folder", keys: "{cmd}↑"),
            RefShortcut(name: "Open Downloads", label: "Downloads", keys: "{opt}{cmd}L"),
            RefShortcut(name: "Open Desktop", label: "Desktop", keys: "{sh}{cmd}D"),
            RefShortcut(name: "Open Applications", label: "Applications", keys: "{sh}{cmd}A"),
            RefShortcut(name: "Show hidden files", label: "Hidden files", keys: "{sh}{cmd}."),
        ]),
        RefCategory(id: "mac.system", name: "System", icon: "gearshape", color: "gray", items: [
            RefShortcut(name: "Lock screen", keys: "{ctl}{cmd}Q"),
            RefShortcut(name: "Quick Note", keys: "Fn Q"),
            RefShortcut(name: "Previous keyboard language", label: "Prev. language", keys: "{ctl}Space", symbolic: 60),
            RefShortcut(name: "Next keyboard language", label: "Next language", keys: "{ctl}{opt}Space", symbolic: 61),
            RefShortcut(name: "Small volume or brightness steps", label: "Fine volume", keys: "{opt}{sh}volume key"),
            RefShortcut(name: "Sound settings", keys: "{opt}volume key"),
            RefShortcut(name: "Restart, sleep, or shut down", label: "Power menu", keys: "{ctl}power button"),
        ]),
    ]

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
