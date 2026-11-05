import AppKit

/// One shortcut found on this Mac.
struct Found: Identifiable {
    let id: String
    let section: String
    let name: String
    let keys: String
}

struct FoundSection {
    let id: String
    let name: String
    let icon: String
    let color: String
}

/// Reads shortcuts from settings files only. Needs no permissions and changes nothing.
enum Scanner {
    struct Result {
        var sections: [FoundSection] = []
        var items: [Found] = []
    }

    static func scan() -> Result {
        var r = Result()
        ownApps(&r)
        sharedFiles(&r)
        otherApps(&r)
        return r
    }

    // MARK: Apps

    static func installed(_ bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    static func appName(_ url: URL) -> String {
        FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }

    static func ownApps(_ r: inout Result) {
        for a in Catalog.ownApps() {
            let sec = "app:" + a.bundleID
            r.sections.append(FoundSection(id: sec, name: a.name, icon: a.icon, color: a.color))
            for (i, s) in a.shortcuts.enumerated() {
                r.items.append(Found(id: "\(sec):\(i)", section: sec, name: s.0, keys: s.1))
            }
        }
    }

    /// Future apps can list their hotkeys in ~/Library/Application Support/Keyper/Apps/<name>.json:
    /// {"app": "Name", "bundleID": "...", "icon": "pin", "color": "orange",
    ///  "shortcuts": [{"name": "Do the thing", "keys": "{ctl}{opt}X"}]}
    static func sharedFiles(_ r: inout Result) {
        let dir = Store.folder.appendingPathComponent("Apps")
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for f in files where f.pathExtension == "json" {
            guard let data = try? Data(contentsOf: f),
                  let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let name = j["app"] as? String, let list = j["shortcuts"] as? [[String: Any]] else { continue }
            let sec = "app:" + ((j["bundleID"] as? String) ?? name)
            if r.sections.contains(where: { $0.id == sec }) { continue }
            r.sections.append(FoundSection(id: sec, name: name, icon: j["icon"] as? String ?? "square.grid.2x2",
                                           color: j["color"] as? String ?? "gray"))
            for (i, s) in list.enumerated() {
                guard let n = s["name"] as? String, let k = s["keys"] as? String else { continue }
                r.items.append(Found(id: "\(sec):\(i)", section: sec, name: n, keys: k))
            }
        }
    }

    /// Any other app: hotkeys saved by the common KeyboardShortcuts library (ChatGPT and many others), and
    /// App Shortcuts you added in System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts.
    static func otherApps(_ r: inout Result) {
        let prefs = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Preferences")
        let files = (try? FileManager.default.contentsOfDirectory(at: prefs, includingPropertiesForKeys: nil)) ?? []
        var found: [(FoundSection, [Found])] = []
        for f in files where f.pathExtension == "plist" {
            let domain = f.deletingPathExtension().lastPathComponent
            guard let data = try? Data(contentsOf: f),
                  let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { continue }
            let isGlobal = domain == ".GlobalPreferences"
            var name = "All apps"
            if !isGlobal {
                guard let url = installed(domain), !r.sections.contains(where: { $0.id == "app:" + domain }) else { continue }
                name = appName(url)
            }
            let sec = isGlobal ? "app:all" : "app:" + domain
            var items: [Found] = []
            for (key, value) in dict where key.hasPrefix("KeyboardShortcuts_") {
                guard let s = value as? String, let d = s.data(using: .utf8),
                      let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                      let code = j["carbonKeyCode"] as? Int, let mods = j["carbonModifiers"] as? Int,
                      let keys = Keys.fromCarbon(code: code, mods: mods) else { continue }
                items.append(Found(id: "\(sec):\(key)", section: sec, name: humanize(String(key.dropFirst(18))), keys: keys))
            }
            for (menu, eq) in dict["NSUserKeyEquivalents"] as? [String: String] ?? [:] {
                guard let keys = Keys.fromKeyEquivalent(eq) else { continue }
                // Menu paths are saved like "\u{1B}File\u{1B}Export"; show the last part.
                let label = menu.split(separator: "\u{1B}").last.map(String.init) ?? menu
                items.append(Found(id: "\(sec):menu:\(menu)", section: sec, name: label, keys: keys))
            }
            if items.isEmpty { continue }
            let icon = name == "ChatGPT" ? "message" : "square.grid.2x2"
            found.append((FoundSection(id: sec, name: name, icon: icon, color: name == "ChatGPT" ? "green" : "gray"),
                          items.sorted { $0.name < $1.name }))
        }
        for (s, items) in found.sorted(by: { $0.0.name < $1.0.name }) {
            r.sections.append(s)
            r.items += items
        }
    }

    /// "toggleAttachedLauncher" → "Toggle attached launcher".
    static func humanize(_ s: String) -> String {
        var out = ""
        for c in s {
            if c.isUppercase, !out.isEmpty { out += " " + c.lowercased() } else { out.append(c) }
        }
        return out.prefix(1).uppercased() + out.dropFirst()
    }
}
