#!/bin/bash
set -e

APP_NAME="Snake"
EXECUTABLE_NAME="snake"
BUNDLE_DIR="${APP_NAME}.app"

echo "swift build..."
swift build -c release

echo "budnle structure init..."
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

echo "copy data to bundle..."
cp ".build/release/${EXECUTABLE_NAME}" "${BUNDLE_DIR}/Contents/MacOS/${EXECUTABLE_NAME}"
cp "res/AppIcon.icns" "${BUNDLE_DIR}/Contents/Resources/AppIcon.icns"

echo "generation of Info.plist..."
cat <<EOF > "${BUNDLE_DIR}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.snake</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

touch "${BUNDLE_DIR}"

echo "running hdiutil..."

mkdir -p dist
cp -R "Snake.app" dist/

ln -s /Applications dist/Applications

hdiutil create -volname "Snake" -srcfolder dist -ov -format UDZO "Snake.dmg"

rm -rf dist

echo "done."