import Foundation
import SwiftUI

/// A size scaled by the "Text size" setting.
func sz(_ n: CGFloat) -> CGFloat { n * Store.shared.textScale }

/// A section as shown: its shortcuts, with your names, icon and color applied.
struct Section: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: String
    var items: [Item]
}

struct Item: Identifiable {
    let id: String
    let original: String
    var name: String
    let keys: String
    var favorite: Bool
    var hidden: Bool
}

/// Your choices (favorites, hidden, names, order, icons, colors, key style), saved in
/// ~/Library/Application Support/Keyper/settings.json. Fields are only ever added, never renamed. Unknown fields
/// are kept when saving, and a file written by a newer Keyper (higher formatVersion) is never overwritten.
final class Store: ObservableObject {
    static let shared = Store()
    static let formatVersion = 1
    static let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Keyper")
    static var file: URL { folder.appendingPathComponent("settings.json") }

    @Published private(set) var scan = Scanner.Result()
    @Published var renames: [String: String] = [:]
    @Published var favorites: Set<String> = []
    @Published var hidden: Set<String> = []
    /// Mac shortcuts you added to your page from "All Mac shortcuts".
    @Published var onPage: Set<String> = []
    /// Changed Mac shortcuts already added once (so removing one doesn't bring it back).
    var seenChanged: Set<String> = []
    @Published var order: [String] = []
    @Published var styles: [String: [String: String]] = [:]
    @Published var words: Set<Mod> = [.opt, .ctl]
    /// Modifiers shown short (Cmd, Opt, Ctrl). Wins over `words`.
    @Published var short: Set<Mod> = []
    /// Text size: 1 is normal.
    @Published var textScale: CGFloat = 1
    /// Each key on its own tile instead of one tile per shortcut.
    @Published var separateTiles = false
    /// Shortcuts you typed in yourself: [{"id", "app", "name", "keys"}].
    @Published var custom: [[String: String]] = []
    @Published var openAtLogin = false

    private var raw: [String: Any] = [:]
    private var readOnly = false

    init() {
        load()
    }

    // MARK: Saving

    func load() {
        guard let data = try? Data(contentsOf: Self.file),
              let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        raw = j
        readOnly = (j["formatVersion"] as? Int ?? 1) > Self.formatVersion
        renames = j["renames"] as? [String: String] ?? [:]
        favorites = Set(j["favorites"] as? [String] ?? [])
        hidden = Set(j["hidden"] as? [String] ?? [])
        onPage = Set(j["onPage"] as? [String] ?? [])
        seenChanged = Set(j["seenChanged"] as? [String] ?? [])
        order = j["order"] as? [String] ?? []
        styles = j["styles"] as? [String: [String: String]] ?? [:]
        if let w = j["words"] as? [String] { words = Set(w.compactMap(Mod.init)) }
        short = Set((j["short"] as? [String] ?? []).compactMap(Mod.init))
        textScale = j["textScale"] as? CGFloat ?? 1
        separateTiles = j["separateTiles"] as? Bool ?? false
        custom = j["custom"] as? [[String: String]] ?? []
    }

    func save() {
        guard !readOnly else { return }
        var j = raw
        j["formatVersion"] = Self.formatVersion
        j["renames"] = renames
        j["favorites"] = favorites.sorted()
        j["hidden"] = hidden.sorted()
        j["onPage"] = onPage.sorted()
        j["seenChanged"] = seenChanged.sorted()
        j["order"] = order
        j["styles"] = styles
        j["words"] = words.map(\.rawValue).sorted()
        j["short"] = short.map(\.rawValue).sorted()
        j["textScale"] = textScale
        j["separateTiles"] = separateTiles
        j["custom"] = custom
        raw = j
        try? FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
        if let data = try? JSONSerialization.data(withJSONObject: j, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: Self.file, options: .atomic)
        }
    }

    // MARK: Reading the Mac

    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            let r = Scanner.scan()
            DispatchQueue.main.async { self.apply(r) }
        }
    }

    func refreshNow() { apply(Scanner.scan()) }

    private func apply(_ r: Scanner.Result) {
        scan = r
        // A Mac shortcut you changed (to new keys, not turned off) goes on your page the first time it's seen.
        var changed = false
        for (id, st) in r.mac where st.changedFrom != nil && !st.off && !seenChanged.contains(id) {
            seenChanged.insert(id); onPage.insert(id); changed = true
        }
        if changed { save() }
    }

    // MARK: What's shown

    func macState(_ s: RefShortcut) -> MacState { scan.mac[s.id] ?? MacState(keys: s.keys) }

    /// Every section that has something on your page, in your order.
    var sections: [Section] {
        var all: [Section] = []
        for cat in Catalog.mac {
            let items = cat.items.filter { onPage.contains($0.id) }.map { s in
                item(s.id, s.name, macState(s).keys)
            }
            if !items.isEmpty { all.append(section(cat.id, cat.name, cat.icon, cat.color, items)) }
        }
        for s in scan.sections {
            let items = scan.items.filter { $0.section == s.id }.map { item($0.id, $0.name, $0.keys) }
            if !items.isEmpty { all.append(section(s.id, s.name, s.icon, s.color, items)) }
        }
        // Shortcuts you added by hand join the section with the same app name, or make their own.
        for c in custom {
            guard let id = c["id"], let app = c["app"], let name = c["name"], let keys = c["keys"] else { continue }
            let it = item(id, name, keys)
            if let i = all.firstIndex(where: { $0.name.lowercased() == app.lowercased() }) {
                all[i].items.append(it)
            } else {
                all.append(section("custom:" + app.lowercased(), app, "square.grid.2x2", "gray", [it]))
            }
        }
        return all.sorted { rank($0.id) < rank($1.id) }
    }

    /// Section names offered when adding a shortcut by hand.
    var appNames: [String] {
        var names = scan.sections.map(\.name)
        for c in custom { if let a = c["app"], !names.contains(a) { names.append(a) } }
        return names
    }

    func addCustom(app: String, name: String, keys: String) {
        custom.append(["id": "custom:" + UUID().uuidString, "app": app, "name": name, "keys": keys])
        save()
    }

    func isCustom(_ id: String) -> Bool { id.hasPrefix("custom:") }

    func removeCustom(_ id: String) {
        custom.removeAll { $0["id"] == id }
        save()
    }

    private func rank(_ id: String) -> Int {
        if let i = order.firstIndex(of: id) { return i }
        let defaults = Catalog.mac.map(\.id) + scan.sections.map(\.id)
        return order.count + (defaults.firstIndex(of: id) ?? 999)
    }

    private func item(_ id: String, _ name: String, _ keys: String) -> Item {
        Item(id: id, original: name, name: renames[id] ?? name, keys: keys,
             favorite: favorites.contains(id), hidden: hidden.contains(id))
    }

    private func section(_ id: String, _ name: String, _ icon: String, _ color: String, _ items: [Item]) -> Section {
        Section(id: id, name: name, icon: styles[id]?["icon"] ?? icon, color: styles[id]?["color"] ?? color, items: items)
    }

    // MARK: Changes

    func toggle(_ set: ReferenceWritableKeyPath<Store, Set<String>>, _ id: String) {
        if self[keyPath: set].contains(id) { self[keyPath: set].remove(id) } else { self[keyPath: set].insert(id) }
        save()
    }

    func rename(_ id: String, original: String, to name: String) {
        let n = name.trimmingCharacters(in: .whitespaces)
        if n.isEmpty || n == original { renames[id] = nil } else { renames[id] = n }
        save()
    }

    func setStyle(_ id: String, icon: String? = nil, color: String? = nil) {
        var s = styles[id] ?? [:]
        if let icon { s["icon"] = icon }
        if let color { s["color"] = color }
        styles[id] = s
        save()
    }

    func moveSection(_ id: String, by step: Int) {
        var ids = sections.map(\.id)
        guard let i = ids.firstIndex(of: id), ids.indices.contains(i + step) else { return }
        ids.swapAt(i, i + step)
        order = ids
        save()
    }

    func style(_ m: Mod) -> KeyStyle { short.contains(m) ? .short : words.contains(m) ? .word : .symbol }

    func setStyle(_ m: Mod, _ s: KeyStyle) {
        if s == .word { words.insert(m) } else { words.remove(m) }
        if s == .short { short.insert(m) } else { short.remove(m) }
        save()
    }

    func show(_ keys: String) -> String { Keys.display(keys, style: style) }

    func setTextScale(_ s: CGFloat) {
        textScale = s
        save()
    }

    func setSeparateTiles(_ on: Bool) {
        separateTiles = on
        save()
    }

    static func color(_ name: String) -> Color {
        switch name {
        case "blue": .blue
        case "purple": .purple
        case "teal": .teal
        case "orange": .orange
        case "yellow": .yellow
        case "green": .green
        case "pink": .pink
        case "red": .red
        default: .gray
        }
    }
}
