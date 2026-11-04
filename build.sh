#!/bin/zsh
# Builds Keyper.app, installs it to /Applications and relaunches it.
# Needs only the Swift toolchain; no Xcode project.
#   ./build.sh          build + install + relaunch
#   ./build.sh dist     build dist/Keyper.dmg to share (doesn't install); GitHub builds this on every push
#   .build/debug/Keyper --render out.png --page mine|mac|settings   draw the panel to a picture
set -e
cd "$(dirname "$0")"
source tools/sparkle.sh   # self-updating (Sparkle itself comes from the Swift package)
APP=Keyper.app

# Universal binary: Apple Silicon + Intel Macs.
swift build -c release --arch arm64 --arch x86_64
BIN=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Keyper

rm -rf $APP
mkdir -p $APP/Contents/MacOS $APP/Contents/Resources
cp $BIN $APP/Contents/MacOS/Keyper
sparkle_embed $APP "$(dirname $BIN)/Sparkle.framework"
install_name_tool -add_rpath @executable_path/../Frameworks $APP/Contents/MacOS/Keyper
cp assets/menu-icon.png assets/AppIcon.icns $APP/Contents/Resources/

cat > $APP/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Keyper</string>
  <key>CFBundleDisplayName</key><string>Keyper</string>
  <key>CFBundleIdentifier</key><string>io.github.hi-dad.keyper</string>
  <key>CFBundleExecutable</key><string>Keyper</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>Free and offline.</string>
</dict></plist>
PLIST
sparkle_plist $APP keyper

# Signing: uses $SIGN_IDENTITY, the name in a local .signing-identity file (git-ignored, yours only),
# or ad-hoc signing. Keyper needs no permissions, so any of these works.
IDENTITY="${SIGN_IDENTITY:-}"
[[ -z "$IDENTITY" && -f .signing-identity ]] && IDENTITY="$(head -1 .signing-identity)"
# A Developer ID signature (GitHub's release builds) also gets the hardened runtime + timestamp Apple's notarization needs.
EXTRA=()
[[ "$IDENTITY" == "Developer ID Application"* ]] && EXTRA=(--options runtime --timestamp)
if [[ -n "$IDENTITY" ]] && sparkle_sign $APP --force --sign "$IDENTITY" $EXTRA 2>/dev/null &&
   codesign --force --sign "$IDENTITY" $EXTRA $APP 2>/dev/null; then
  echo "Signed with: $IDENTITY"
else
  sparkle_sign $APP --force --sign -
  codesign --force --sign - $APP
  echo "Signed ad-hoc"
fi

# ./build.sh dist: a disk image to share (the app + an Applications shortcut + install steps), no install.
if [[ "$1" == "dist" ]]; then
  rm -rf dist && mkdir -p dist/stage
  mv $APP dist/stage/
  ln -s /Applications dist/stage/Applications
  cp "How to install.txt" dist/stage/
  hdiutil create -volname "Keyper" -srcfolder dist/stage -ov -format UDZO dist/Keyper.dmg >/dev/null
  rm -rf dist/stage
  echo "Made dist/Keyper.dmg"
  exit 0
fi

pkill -x Keyper || true
while pgrep -x Keyper >/dev/null; do sleep 0.2; done
rm -rf /Applications/$APP
mv $APP /Applications/
for i in 1 2 3 4 5; do open /Applications/$APP 2>/dev/null && break; sleep 1; done
echo "Installed to /Applications"
