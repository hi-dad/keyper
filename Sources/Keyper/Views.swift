import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

enum Page { case mine, mac, settings }

final class UIState: ObservableObject {
    static let shared = UIState()
    @Published var page = Page.mine
    var pageBeforeSettings = Page.mine
    @Published var showHidden = false
    @Published var search = ""
    /// For --render: lay everything out at full height instead of scrolling.
    var picture = false
    /// For --render --page settings-add: show the Add a shortcut form open.
    var addFormOpen = false
}

struct PanelView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var ui: UIState

    var body: some View {
        VStack(spacing: 0) {
            if ui.page != .settings {
                Picker("", selection: $ui.page) {
                    Text("My shortcuts").tag(Page.mine)
                    Text("All Mac shortcuts").tag(Page.mac)
                }
                .pickerStyle(.segmented).labelsHidden()
                .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 6)
            }
            if ui.picture {
                content.padding(14)
            } else {
                ScrollView { content.padding(14) }.frame(height: 520)
            }
            Divider()
            bottomBar.padding(.horizontal, 10).padding(.vertical, 7)
        }
        .frame(width: sz(400))
    }

    @ViewBuilder var content: some View {
        switch ui.page {
        case .mine: MinePage()
        case .mac: MacPage()
        case .settings: SettingsPage()
        }
    }

    var bottomBar: some View {
        let hiddenCount = store.sections.flatMap(\.items).filter(\.hidden).count
        return HStack {
            if ui.page == .mine && hiddenCount > 0 {
                Button {
                    ui.showHidden.toggle()
                } label: {
                    Label(ui.showHidden ? "Hide hidden" : "Show \(hiddenCount) hidden",
                          systemImage: ui.showHidden ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: sz(12)))
            }
            Spacer()
            Button {
                if ui.page == .settings { ui.page = ui.pageBeforeSettings }
                else { ui.pageBeforeSettings = ui.page; ui.page = .settings }
            } label: {
                Image(systemName: "gearshape").font(.system(size: sz(15))).frame(width: 26, height: 26)
            }
            .buttonStyle(.plain).foregroundStyle(.secondary).help("Settings")
        }
    }
}

// MARK: Pieces

struct IconTile: View {
    let icon: String
    let color: String
    var body: some View {
        let c = Store.color(color)
        Image(systemName: icon).font(.system(size: sz(12), weight: .semibold)).foregroundStyle(c)
            .frame(width: 24, height: 24)
            .background(RoundedRectangle(cornerRadius: 6).fill(c.opacity(0.2)))
    }
}

/// Header with the heavy line under it.
struct SectionHeader<Leading: View>: View {
    let name: String
    let icon: String
    let color: String
    @ViewBuilder var leading: Leading
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 9) {
                leading
                IconTile(icon: icon, color: color)
                Text(name).font(.system(size: sz(14), weight: .semibold))
                Spacer()
            }
            Rectangle().fill(Color.primary.opacity(0.35)).frame(height: 2)
        }
    }
}

extension SectionHeader where Leading == EmptyView {
    init(name: String, icon: String, color: String) {
        self.init(name: name, icon: icon, color: color) { EmptyView() }
    }
}

struct KeyCap: View {
    @EnvironmentObject var store: Store
    @Environment(\.colorScheme) var scheme
    let keys: String
    var body: some View {
        if store.separateTiles {
            HStack(spacing: 3) {
                let steps = Keys.parts(keys, style: store.style)
                ForEach(steps.indices, id: \.self) { i in
                    if i > 0 { Text("→").font(.system(size: sz(12))).foregroundStyle(.secondary).padding(.horizontal, 2) }
                    ForEach(steps[i].keys.indices, id: \.self) { j in tile(steps[i].keys[j], pad: 6) }
                }
            }
        } else {
            tile(store.show(keys), pad: 8)
        }
    }

    // Darker than the panel so keys stand out (a light gray tint in light mode).
    func tile(_ text: String, pad: CGFloat) -> some View {
        Text(text)
            .font(.system(size: sz(13), weight: .medium))
            .lineLimit(1).fixedSize()
            .padding(.horizontal, pad).padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(scheme == .dark ? 0.45 : 0.08)))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.2), lineWidth: 0.5))
    }
}

struct Rows<Row: View>: View {
    let count: Int
    @ViewBuilder let row: (Int) -> Row
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { i in
                if i > 0 { Divider().padding(.leading, 16) }
                row(i).padding(.leading, 16).padding(.vertical, 6)
            }
        }
    }
}

// MARK: My shortcuts

struct MinePage: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var ui: UIState

    var body: some View {
        let sections = store.sections.map { s -> Section in
            var s = s
            s.items = s.items.filter { ui.showHidden || !$0.hidden }
            return s
        }
        let favorites = sections.flatMap(\.items).filter(\.favorite)
        VStack(alignment: .leading, spacing: 18) {
            if !favorites.isEmpty { block("Favorites", "star.fill", "yellow", favorites) }
            ForEach(sections) { s in
                let items = s.items.filter { !$0.favorite }
                if !items.isEmpty { block(s.name, s.icon, s.color, items) }
            }
            if sections.allSatisfy({ $0.items.isEmpty }) {
                Text("Add shortcuts from All Mac shortcuts, or install an app with hotkeys.")
                    .foregroundStyle(.secondary).font(.system(size: sz(13)))
            }
        }
    }

    func block(_ name: String, _ icon: String, _ color: String, _ items: [Item]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(name: name, icon: icon, color: color)
            Rows(count: items.count) { i in
                HStack {
                    Text(items[i].name).font(.system(size: sz(13)))
                    Spacer(minLength: 12)
                    KeyCap(keys: items[i].keys)
                }
                .opacity(items[i].hidden ? 0.45 : 1)
            }
        }
    }
}

// MARK: All Mac shortcuts

struct MacPage: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var ui: UIState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            TextField("Search all Mac shortcuts", text: $ui.search).textFieldStyle(.roundedBorder)
            ForEach(Catalog.mac, id: \.id) { cat in
                let q = ui.search.lowercased()
                let items = cat.items.filter { q.isEmpty || $0.name.lowercased().contains(q) }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionHeader(name: cat.name, icon: cat.icon, color: cat.color)
                        Rows(count: items.count) { i in row(items[i]) }
                    }
                }
            }
        }
    }

    func row(_ s: RefShortcut) -> some View {
        let st = store.macState(s)
        let added = store.onPage.contains(s.id)
        return HStack(spacing: 6) {
            Text(s.name).font(.system(size: sz(13)))
            // You changed this one and it isn't on your page: say so.
            if let def = st.changedFrom, !added {
                ChangedMark(off: st.off, note: st.off
                    ? "Turned off on your Mac.\nApple's default: \(store.show(def))"
                    : "Customized on your Mac.\nApple's default: \(store.show(def))")
            }
            Spacer(minLength: 12)
            KeyCap(keys: st.keys)
            Button {
                store.toggle(\.onPage, s.id)
            } label: {
                Image(systemName: added ? "checkmark" : "plus").font(.system(size: sz(13), weight: .semibold))
                    .frame(width: 26, height: 26).contentShape(Rectangle())
            }
            .buttonStyle(.plain).foregroundStyle(added ? Color.green : Color.accentColor)
            .help(added ? "Remove from My shortcuts" : "Add to My shortcuts")
        }
    }
}

/// Orange mark on a Mac shortcut you changed (pencil) or turned off (slash). Hovering shows what it was.
/// A popover, because plain tooltips don't appear in a menu bar panel.
struct ChangedMark: View {
    let off: Bool
    let note: String
    @State private var showing = false
    var body: some View {
        Image(systemName: off ? "slash.circle" : "pencil.circle").foregroundStyle(.orange).font(.system(size: sz(12)))
            .onHover { showing = $0 }
            .popover(isPresented: $showing, arrowEdge: .top) {
                Text(note).font(.system(size: sz(12))).padding(10).fixedSize()
            }
    }
}

// MARK: Settings

struct SettingsPage: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var ui: UIState
    @State private var picking: String?
    @State private var atLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Button { ui.page = ui.pageBeforeSettings } label: {
                    Image(systemName: "chevron.left").font(.system(size: sz(14), weight: .semibold)).frame(width: 24, height: 24)
                }.buttonStyle(.plain)
                Text("Settings").font(.system(size: sz(16), weight: .semibold))
            }
            label("Show keys as")
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                ForEach([Mod.cmd, .opt, .ctl, .sh]) { m in
                    GridRow {
                        Text(m.word).font(.system(size: sz(13))).frame(maxWidth: .infinity, alignment: .leading)
                        Picker("", selection: Binding(get: { store.style(m) }, set: { store.setStyle(m, $0) })) {
                            Text("Symbol \(m.symbol)").tag(KeyStyle.symbol)
                            Text("Word \"\(m.word)\"").tag(KeyStyle.word)
                            if m != .sh { Text("Short \"\(m.short)\"").tag(KeyStyle.short) }
                        }
                        .labelsHidden().frame(width: 180)
                    }
                }
            }
            .padding(.leading, 4)

            label("Key tiles").padding(.top, 8)
            Picker("", selection: Binding(get: { store.separateTiles }, set: { store.setSeparateTiles($0) })) {
                Text("One per shortcut").tag(false)
                Text("One per key").tag(true)
            }
            .pickerStyle(.segmented).labelsHidden()

            label("Text size").padding(.top, 8)
            Picker("", selection: Binding(get: { store.textScale }, set: { store.setTextScale($0) })) {
                Text("Small").tag(CGFloat(0.9))
                Text("Normal").tag(CGFloat(1))
                Text("Large").tag(CGFloat(1.15))
                Text("Larger").tag(CGFloat(1.3))
            }
            .pickerStyle(.segmented).labelsHidden()

            label("Sections").padding(.top, 8)
            VStack(alignment: .leading, spacing: 16) {
                ForEach(store.sections) { s in sectionBlock(s) }
            }
            AddShortcut().padding(.top, 4)

            Divider().padding(.top, 8)
            Toggle("Open at login", isOn: $atLogin)
                .onChange(of: atLogin) { _, on in
                    if on { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
                }
                .font(.system(size: sz(13)))
            HStack {
                Button("Check for Updates…") { Updates.check() }
                Button("Quit Keyper") { NSApp.terminate(nil) }
            }
        }
    }

    func label(_ t: String) -> some View {
        Text(t).font(.system(size: sz(12))).foregroundStyle(.secondary)
    }

    func sectionBlock(_ s: Section) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(name: s.name, icon: s.icon, color: s.color)
                .overlay(alignment: .topTrailing) {
                    // Small arrows, in the same columns as the star and eye buttons below.
                    let i = store.sections.firstIndex { $0.id == s.id } ?? 0
                    HStack(spacing: 2) {
                        smallButton("chevron.up", i == 0 ? .clear : .secondary, "Move up") { store.moveSection(s.id, by: -1) }
                            .disabled(i == 0)
                        smallButton("chevron.down", i == store.sections.count - 1 ? .clear : .secondary, "Move down") {
                            store.moveSection(s.id, by: 1)
                        }
                        .disabled(i == store.sections.count - 1)
                    }
                    .offset(y: -2)
                }
            .overlay(alignment: .topLeading) {
                // The icon tile opens the icon and color picker.
                Color.clear.frame(width: 24, height: 24).contentShape(Rectangle())
                    .onTapGesture { picking = s.id }
                    .popover(isPresented: Binding(get: { picking == s.id }, set: { if !$0 { picking = nil } })) {
                        StylePicker(section: s).environmentObject(store)
                    }
            }
            Rows(count: s.items.count) { i in
                let it = s.items[i]
                HStack(spacing: 2) {
                    RenameField(item: it)
                    if store.isCustom(it.id) {
                        smallButton("trash", .secondary, "Delete this shortcut you added") { store.removeCustom(it.id) }
                    }
                    smallButton(it.favorite ? "star.fill" : "star", it.favorite ? .yellow : .secondary,
                                it.favorite ? "Remove from Favorites" : "Add to Favorites") { store.toggle(\.favorites, it.id) }
                    smallButton(it.hidden ? "eye.slash" : "eye", .secondary, it.hidden ? "Show" : "Hide") {
                        store.toggle(\.hidden, it.id)
                    }
                }
            }
        }
    }

    func smallButton(_ icon: String, _ color: Color, _ help: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: sz(13))).frame(width: 28, height: 28).contentShape(Rectangle())
        }
        .buttonStyle(.plain).foregroundStyle(color).help(help)
    }
}

/// Type in a hotkey Keyper can't read on its own. Modifier buttons plus a key box (not "press the keys"),
/// because pressing another app's hotkey would set that app off instead of reaching Keyper.
struct AddShortcut: View {
    @EnvironmentObject var store: Store
    @State private var open = UIState.shared.addFormOpen
    @State private var app = ""
    @State private var name = ""
    @State private var key = ""
    @State private var mods: Set<Mod> = []
    @State private var problem: String?

    var keys: String {
        let k = key.trimmingCharacters(in: .whitespaces)
        return Keys.template(ctl: mods.contains(.ctl), opt: mods.contains(.opt), sh: mods.contains(.sh),
                             cmd: mods.contains(.cmd), key: k.count == 1 ? k.uppercased() : k)
    }

    var body: some View {
        if !open {
            Button { open = true } label: { Label("Add a shortcut", systemImage: "plus") }
                .buttonStyle(.plain).foregroundStyle(Color.accentColor).font(.system(size: sz(13)))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add a shortcut").font(.system(size: sz(13), weight: .semibold))
                HStack(spacing: 4) {
                    TextField("App", text: $app).textFieldStyle(.roundedBorder)
                    Menu {
                        ForEach(store.appNames, id: \.self) { n in Button(n) { app = n } }
                    } label: { Image(systemName: "chevron.down") }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().help("Pick an app that's already listed")
                }
                TextField("What it does", text: $name).textFieldStyle(.roundedBorder)
                HStack(spacing: 4) {
                    ForEach([Mod.ctl, .opt, .sh, .cmd]) { m in
                        Button { if mods.contains(m) { mods.remove(m) } else { mods.insert(m) } } label: {
                            Text(m.symbol).font(.system(size: sz(13), weight: .medium)).frame(width: 28, height: 24)
                                .background(RoundedRectangle(cornerRadius: 6)
                                    .fill(mods.contains(m) ? Color.accentColor : Color.primary.opacity(0.08)))
                                .foregroundStyle(mods.contains(m) ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain).help(m.word)
                    }
                    TextField("Key, like K or Space", text: $key).textFieldStyle(.roundedBorder)
                }
                if !key.trimmingCharacters(in: .whitespaces).isEmpty {
                    HStack {
                        Text("Shows as").font(.system(size: sz(12))).foregroundStyle(.secondary)
                        KeyCap(keys: keys)
                    }
                }
                if let problem { Text(problem).font(.system(size: sz(12))).foregroundStyle(.red) }
                HStack {
                    Button("Cancel") { reset() }
                    Button("Add") { add() }.keyboardShortcut(.defaultAction)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
            .onChange(of: app) { problem = nil }
            .onChange(of: name) { problem = nil }
            .onChange(of: key) { problem = nil }
        }
    }

    func add() {
        let a = app.trimmingCharacters(in: .whitespaces), n = name.trimmingCharacters(in: .whitespaces)
        if a.isEmpty { problem = "Enter the app's name."; return }
        if n.isEmpty { problem = "Enter what the shortcut does."; return }
        if key.trimmingCharacters(in: .whitespaces).isEmpty { problem = "Enter the key, like K or Space."; return }
        store.addCustom(app: a, name: n, keys: keys)
        reset()
    }

    func reset() {
        open = false; app = ""; name = ""; key = ""; mods = []; problem = nil
    }
}

struct RenameField: View {
    @EnvironmentObject var store: Store
    let item: Item
    @State private var text = ""
    var body: some View {
        TextField(item.original, text: $text)
            .textFieldStyle(.roundedBorder).font(.system(size: sz(13)))
            .onAppear { text = item.name }
            .onChange(of: text) { _, t in store.rename(item.id, original: item.original, to: t) }
    }
}

struct StylePicker: View {
    @EnvironmentObject var store: Store
    let section: Section
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 6), count: 8), spacing: 6) {
                ForEach(Catalog.icons, id: \.self) { icon in
                    Button { store.setStyle(section.id, icon: icon) } label: {
                        Image(systemName: icon).font(.system(size: sz(13))).frame(width: 28, height: 28)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.accentColor, lineWidth: currentIcon == icon ? 2 : 0))
                    }.buttonStyle(.plain)
                }
            }
            HStack(spacing: 6) {
                ForEach(Catalog.colors, id: \.self) { c in
                    Button { store.setStyle(section.id, color: c) } label: {
                        Circle().fill(Store.color(c)).frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.primary, lineWidth: currentColor == c ? 2 : 0).padding(-3))
                    }.buttonStyle(.plain).frame(width: 28, height: 28)
                }
            }
        }
        .padding(12)
    }
    var current: Section? { store.sections.first { $0.id == section.id } }
    var currentIcon: String { current?.icon ?? section.icon }
    var currentColor: String { current?.color ?? section.color }
}

