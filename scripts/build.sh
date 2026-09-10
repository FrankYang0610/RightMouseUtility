#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

app="$PWD/build/RightMouseUtility.app"
extension="$app/Contents/PlugIns/FinderExtension.appex"
identity="${SIGNING_IDENTITY:--}"
arch="${ARCH:-$(uname -m)}"
sdk="$(xcrun --sdk macosx --show-sdk-path)"
mkdir -p "$app/Contents/MacOS" "$extension/Contents/MacOS" build/ModuleCache
cp Resources/App-Info.plist "$app/Contents/Info.plist"
cp Resources/Extension-Info.plist "$extension/Contents/Info.plist"

flags=(-sdk "$sdk" -target "$arch-apple-macosx13.0" -swift-version 5 -O
       -warnings-as-errors -module-cache-path "$PWD/build/ModuleCache"
       -framework AppKit -framework FinderSync)
xcrun swiftc "${flags[@]}" -parse-as-library -module-name RightMouseUtility \
    Sources/Core/*.swift Sources/App/*.swift -o "$app/Contents/MacOS/RightMouseUtility"
xcrun swiftc "${flags[@]}" -parse-as-library -application-extension -module-name RightMouseFinder \
    -Xlinker -e -Xlinker _NSExtensionMain \
    Sources/Core/CreateRequest.swift Sources/FinderExtension/*.swift \
    -o "$extension/Contents/MacOS/FinderExtension"

sign_flags=(--force --sign "$identity" --options runtime)
if [[ "$identity" == "-" ]]; then sign_flags+=(--timestamp=none); fi
codesign "${sign_flags[@]}" --entitlements Resources/Extension.entitlements "$extension"
codesign "${sign_flags[@]}" "$app"
codesign --verify --deep --strict "$app"
printf 'Built %s\n' "$app"
