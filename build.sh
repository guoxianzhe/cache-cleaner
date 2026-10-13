#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app="build/Cache-Chan.app"
mkdir -p "$app/Contents/MacOS"
mkdir -p "$app/Contents/Resources" build/AppIcon.iconset
cp Info.plist "$app/Contents/Info.plist"
xcrun swiftc Sources/*.swift -target "$(uname -m)-apple-macos11.0" -o "$app/Contents/MacOS/CacheCleaner" -framework Cocoa
"$app/Contents/MacOS/CacheCleaner" --self-test
"$app/Contents/MacOS/CacheCleaner" --export-avatar build/avatar.png
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" build/avatar.png --out "build/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" build/avatar.png --out "build/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns build/AppIcon.iconset -o "$app/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$app"
echo "Built: $PWD/$app"
if [[ "${1:-}" == "--run" ]]; then open "$app"; fi
