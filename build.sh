#!/bin/sh
# Compila "Tiro alla fune.app" nella cartella corrente (stesso schema di Jurassic Run).
set -e
cd "$(dirname "$0")"
APP="Tiro alla fune.app"
TMP=$(mktemp -d)

swiftc main.swift -o "$TMP/selftest" && "$TMP/selftest" --selftest # build di debug: gli assert sono attivi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
# app universale (Apple Silicon + Intel) da macOS 13
for arch in arm64 x86_64; do
  swiftc -O -target $arch-apple-macos13 main.swift -o "$TMP/TiroAllaFune-$arch"
done
lipo -create "$TMP/TiroAllaFune-arm64" "$TMP/TiroAllaFune-x86_64" -output "$APP/Contents/MacOS/TiroAllaFune"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Tiro alla fune</string>
  <key>CFBundleExecutable</key><string>TiroAllaFune</string>
  <key>CFBundleIdentifier</key><string>local.tiroallafune</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.games</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
EOF

codesign --force --deep --sign - "$APP" # firma locale: necessaria sui Mac Apple Silicon
rm -rf "$TMP"
echo "Fatto: open \"$APP\""
