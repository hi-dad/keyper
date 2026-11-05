import Foundation

/// Shortcuts are stored as small templates like "{ctl}{sh}{cmd}3". The four modifier tokens are swapped for
/// a symbol (⌘) or a word (Command) when shown, per the "Show keys as" setting.
enum Mod: String, CaseIterable, Identifiable {
    case cmd, opt, ctl, sh
    var id: String { rawValue }
    var symbol: String { ["cmd": "⌘", "opt": "⌥", "ctl": "⌃", "sh": "⇧"][rawValue]! }
    var word: String { ["cmd": "Command", "opt": "Option", "ctl": "Control", "sh": "Shift"][rawValue]! }
    var short: String { ["cmd": "Cmd", "opt": "Opt", "ctl": "Ctrl", "sh": "Shift"][rawValue]! }
}

/// How a modifier is shown: ⌘, Command, or Cmd.
enum KeyStyle: Int { case symbol, word, short }

enum Keys {
    /// Apple's order for modifiers: ⌃⌥⇧⌘.
    static func template(ctl: Bool, opt: Bool, sh: Bool, cmd: Bool, key: String) -> String {
        (ctl ? "{ctl}" : "") + (opt ? "{opt}" : "") + (sh ? "{sh}" : "") + (cmd ? "{cmd}" : "") + key
    }

    /// hi-dad's rule: all symbols → a space between parts ("⌥ ⇧ ⌘ V"); any word or short name →
    /// a plus between parts ("Option + ⇧ + ⌘ + V"). Two-step shortcuts keep their arrow ("⌘ C → ⌥ ⌘ V").
    static func display(_ t: String, style: (Mod) -> KeyStyle) -> String {
        parts(t, style: style).map { step in
            let mods = step.mods
            if mods.isEmpty { return step.keys.joined() }
            return step.keys.joined(separator: mods.contains { style($0) != .symbol } ? " + " : " ")
        }.joined(separator: " → ")
    }

    /// Each step of a shortcut as separate keys, for the "Separate tiles" look: [["⌥", "⌘", "V"]].
    struct Step {
        var mods: [Mod]
        var keys: [String]
    }

    static func parts(_ t: String, style: (Mod) -> KeyStyle) -> [Step] {
        func name(_ m: Mod) -> String {
            switch style(m) {
            case .symbol: m.symbol
            case .word: m.word
            case .short: m.short
            }
        }
        return t.components(separatedBy: " → ").map { step in
            var rest = Substring(step)
            var mods: [Mod] = []
            while rest.hasPrefix("{"), let end = rest.firstIndex(of: "}"),
                  let m = Mod(rawValue: String(rest[rest.index(after: rest.startIndex)..<end])) {
                mods.append(m)
                rest = rest[rest.index(after: end)...]
            }
            // Tokens not at the start (like "add {sh}") are just swapped in place.
            var key = String(rest)
            for m in Mod.allCases { key = key.replacingOccurrences(of: "{\(m.rawValue)}", with: name(m)) }
            return Step(mods: mods, keys: mods.map(name) + (key.isEmpty ? [] : [key]))
        }
    }

    /// Carbon key codes (what apps register hotkeys with) for a US keyboard.
    static let names: [Int: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V", 11: "B", 12: "Q", 13: "W",
        14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9",
        26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        48: "Tab", 49: "Space", 50: "`", 51: "Delete", 53: "Esc", 117: "Fwd Delete", 123: "←", 124: "→",
        125: "↓", 126: "↑", 122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12", 115: "Home", 119: "End", 116: "Page Up", 121: "Page Down",
    ]

    /// From a Carbon hotkey (KeyboardShortcuts library format, used by ChatGPT and many other apps).
    static func fromCarbon(code: Int, mods: Int) -> String? {
        guard let key = names[code] else { return nil }
        return template(ctl: mods & 4096 != 0, opt: mods & 2048 != 0, sh: mods & 512 != 0, cmd: mods & 256 != 0, key: key)
    }

    /// From an App Shortcut you added in System Settings, like "@$k" (⇧⌘K).
    static func fromKeyEquivalent(_ s: String) -> String? {
        var ctl = false, opt = false, sh = false, cmd = false
        var rest = Substring(s)
        while let c = rest.first, "@$~^".contains(c), rest.count > 1 {
            switch c { case "@": cmd = true; case "$": sh = true; case "~": opt = true; default: ctl = true }
            rest = rest.dropFirst()
        }
        guard !rest.isEmpty else { return nil }
        let special: [Character: String] = ["\u{F700}": "↑", "\u{F701}": "↓", "\u{F702}": "←", "\u{F703}": "→",
                                            "\u{7F}": "Delete", "\r": "Return", "\t": "Tab", "\u{1B}": "Esc", " ": "Space",
                                            "\u{F728}": "Fwd Delete"]
        var key = String(rest).uppercased()
        if rest.count == 1, let c = rest.first {
            if let n = special[c] { key = n }
            else if let u = c.unicodeScalars.first?.value, (0xF704...0xF70F).contains(u) { key = "F\(u - 0xF704 + 1)" }
        }
        return template(ctl: ctl, opt: opt, sh: sh, cmd: cmd, key: key)
    }
}
