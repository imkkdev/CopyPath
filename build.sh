#!/bin/bash
# 构建并签名「复制路径」Finder 扩展 app
set -euo pipefail
cd "$(dirname "$0")"

BUILD=build
APP="$BUILD/CopyPath.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" \
         "$APP/Contents/PlugIns/CopyPathExt.appex/Contents/MacOS"

echo "==> 编译宿主 app"
swiftc -O -swift-version 5 main.swift \
    -o "$APP/Contents/MacOS/CopyPath" \
    -framework AppKit

echo "==> 编译 Finder 扩展"
swiftc -O -swift-version 5 -parse-as-library -module-name CopyPathExt \
    FinderSync.swift \
    -o "$APP/Contents/PlugIns/CopyPathExt.appex/Contents/MacOS/CopyPathExt" \
    -framework FinderSync -framework AppKit \
    -Xlinker -e -Xlinker _NSExtensionMain

echo "==> 拷贝 Info.plist 与图标"
cp Info.plist    "$APP/Contents/Info.plist"
cp ExtInfo.plist "$APP/Contents/PlugIns/CopyPathExt.appex/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp AppIcon.icns  "$APP/Contents/Resources/AppIcon.icns"

echo "==> 签名(使用开发者证书,先扩展后宿主)"
SIGN="Apple Development: greenelee@163.com (PRUQ6CAF7C)"
codesign --force --sign "$SIGN" --timestamp=none \
    --entitlements CopyPathExt.entitlements \
    "$APP/Contents/PlugIns/CopyPathExt.appex"
codesign --force --sign "$SIGN" --timestamp=none "$APP"

echo "==> 构建完成: $APP"
