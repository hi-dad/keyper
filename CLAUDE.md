# Keyper

Menu-bar app that lists hotkeys: "My shortcuts" (your page) and "All Mac shortcuts" (built-in reference).
SwiftPM only, no Xcode project. Bundle ID `io.github.hi-dad.keyper` (never change it).

- Build + install + relaunch: `./build.sh`
- Check the design without opening the menu: `.build/debug/Keyper --render out.png --page mine|mac|settings`
  and `.build/debug/Keyper --render-icon out.png` (menu bar icon at 8×, light + dark).
- Your choices live in `~/Library/Application Support/Keyper/settings.json` (formatVersion 1; add fields only).

Where shortcuts come from (Sources/Keyper/Scanner.swift), read-only, no permissions:
- macOS's own shortcuts: `com.apple.symbolichotkeys` (numbers mapped in Catalog.swift). An entry that's enabled
  with no parameters means Apple's default, not off.
- hi-dad's own apps: hard-coded in `Catalog.ownApps()` (their hotkeys are in code). Update when an app's hotkey changes.
- Future apps: `~/Library/Application Support/Keyper/Apps/<name>.json` (format in Scanner.sharedFiles).
- Other apps: `KeyboardShortcuts_*` keys and `NSUserKeyEquivalents` in ~/Library/Preferences, only for installed apps.
  The current ChatGPT app (`com.openai.codex`) doesn't store its hotkeys there; old `com.openai.chat` prefs are leftovers.
