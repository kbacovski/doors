#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
ARCH="${ARCH:-universal}"
APP="$SCRIPT_DIR/build/doors.app"
CONTENTS="$APP/Contents"

mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
if [[ "$ARCH" == universal ]]; then
  for cpu in arm64 x86_64; do
    swiftc -parse-as-library -O -target "$cpu-apple-macosx13.0" -framework SwiftUI -framework AppKit \
      "$SCRIPT_DIR/RANS0MMac.swift" "$SCRIPT_DIR/CoinStore.swift" "$SCRIPT_DIR/Effects.swift" \
      -o "$CONTENTS/MacOS/RANS0MMac-$cpu"
  done
  lipo -create "$CONTENTS/MacOS/RANS0MMac-arm64" "$CONTENTS/MacOS/RANS0MMac-x86_64" \
    -output "$CONTENTS/MacOS/RANS0MMac"
  rm "$CONTENTS/MacOS/RANS0MMac-arm64" "$CONTENTS/MacOS/RANS0MMac-x86_64"
else
  swiftc -parse-as-library -O -target "$ARCH-apple-macosx13.0" -framework SwiftUI -framework AppKit \
    "$SCRIPT_DIR/RANS0MMac.swift" "$SCRIPT_DIR/CoinStore.swift" "$SCRIPT_DIR/Effects.swift" \
    -o "$CONTENTS/MacOS/RANS0MMac"
fi
cp "$SCRIPT_DIR/Resources/"* "$CONTENTS/Resources/"
cp "$SCRIPT_DIR/LICENSE.md" "$CONTENTS/Resources/LICENSE.md"
cp "$SCRIPT_DIR/README.md" "$CONTENTS/Resources/README.md"
/usr/libexec/PlistBuddy -c 'Clear dict' "$CONTENTS/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string com.rans0m.fan.doors' "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleName string doors' "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string doors' "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string RANS0MMac' "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string doors.icns' "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string 2.4' "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 6' "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSMinimumSystemVersion string 13.0' "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :NSHighResolutionCapable bool true' "$CONTENTS/Info.plist"
codesign --force --deep --sign - "$APP"
echo "Built $APP ($ARCH)"
