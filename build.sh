#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app="build/缓存小扫帚.app"
mkdir -p "$app/Contents/MacOS"
cp Info.plist "$app/Contents/Info.plist"
xcrun swiftc Sources/CacheCleaner.swift -o "$app/Contents/MacOS/CacheCleaner" -framework Cocoa
"$app/Contents/MacOS/CacheCleaner" --self-test
codesign --force --sign - "$app"
echo "已构建：$PWD/$app"
if [[ "${1:-}" == "--run" ]]; then open "$app"; fi
