# Keyper

<img src="images/icon.png" alt="Keyper app icon" width="128">

**A tiny Mac menu bar app that keeps every hotkey you use in one list: yours, your apps', and macOS's own.**

<img src="images/keyper.gif" alt="Keyper's panel: My shortcuts grouped by app, the All Mac shortcuts reference, and Settings" width="460">

### [⬇️ Download Keyper](https://github.com/hi-dad/keyper/releases/latest/download/Keyper.dmg)
Free · macOS 14 or newer · no permissions, no account, offline

## Install

1. Open **Keyper.dmg** and drag Keyper into **Applications**.
2. Open it, and click **Open** when macOS asks if you're sure. (It's signed and checked by Apple.)

A keycap with ⌘ appears in your menu bar. Can't see it? Look behind any « arrow in a full menu bar.

## How to use

- **My shortcuts:** the hotkeys you actually use, one section per app. Ones you changed in macOS show up by themselves.
- **All Mac shortcuts:** a searchable reference. Tap **+** to add one to your page. An orange mark means you changed or turned off that shortcut; hover to see Apple's default.
- **Settings (gear):** favorite, rename, hide, reorder sections, pick icons and colors, add a shortcut by hand, and choose how keys look (⌘, Command or Cmd; one tile or one per key; text size).

Keyper only reads settings files and never changes a hotkey. It re-reads them every time you open it.

**Updates:** it offers new versions itself (or Settings → **Check for Updates…**). **Remove:** Settings → **Quit Keyper**, then drag it to the Trash.

<details><summary>Build it yourself</summary>

Needs Xcode or the Command Line Tools.

```bash
./build.sh     # builds, installs to Applications and opens it
```

`Keyper --render out.png --page mine|mac|settings` draws the panel to a picture.

Apps can list their own hotkeys for Keyper in `~/Library/Application Support/Keyper/Apps/<name>.json`
(format in `Sources/Keyper/Scanner.swift`).

</details>

MIT License
