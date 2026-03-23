#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="KeyboardCleaner"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_BUNDLE="$PROJECT_DIR/build/${APP_NAME}.app"
CONTENTS="$APP_BUNDLE/Contents"
ICONSET_DIR="/tmp/${APP_NAME}.iconset"
SVG_FILE="/tmp/${APP_NAME}_logo.svg"

echo "==> Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

echo "==> Creating .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$CONTENTS/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/KeyboardCleaner/Info.plist" "$CONTENTS/Info.plist"

# Extract SVG from logo.html
echo "==> Extracting SVG logo..."
sed -n '/<svg/,/<\/svg>/p' "$PROJECT_DIR/logo.html" > "$SVG_FILE"

# Try to create .icns icon
ICON_CREATED=false

# Method 1: rsvg-convert (from librsvg, installable via brew install librsvg)
if command -v rsvg-convert &>/dev/null; then
    echo "==> Generating icon with rsvg-convert..."
    mkdir -p "$ICONSET_DIR"
    for SIZE in 16 32 64 128 256 512; do
        rsvg-convert -w $SIZE -h $SIZE "$SVG_FILE" -o "$ICONSET_DIR/icon_${SIZE}x${SIZE}.png"
    done
    for SIZE in 16 32 128 256; do
        DOUBLE=$((SIZE * 2))
        cp "$ICONSET_DIR/icon_${DOUBLE}x${DOUBLE}.png" "$ICONSET_DIR/icon_${SIZE}x${SIZE}@2x.png"
    done
    # 512@2x = 1024
    rsvg-convert -w 1024 -h 1024 "$SVG_FILE" -o "$ICONSET_DIR/icon_512x512@2x.png"
    iconutil -c icns -o "$CONTENTS/Resources/AppIcon.icns" "$ICONSET_DIR"
    ICON_CREATED=true
    rm -rf "$ICONSET_DIR"
fi

# Method 2: Python + cairosvg
if [ "$ICON_CREATED" = false ] && python3 -c "import cairosvg" 2>/dev/null; then
    echo "==> Generating icon with cairosvg..."
    mkdir -p "$ICONSET_DIR"
    for SIZE in 16 32 64 128 256 512 1024; do
        python3 -c "
import cairosvg
cairosvg.svg2png(url='$SVG_FILE', write_to='$ICONSET_DIR/icon_${SIZE}x${SIZE}.png', output_width=$SIZE, output_height=$SIZE)
"
    done
    for SIZE in 16 32 128 256; do
        DOUBLE=$((SIZE * 2))
        cp "$ICONSET_DIR/icon_${DOUBLE}x${DOUBLE}.png" "$ICONSET_DIR/icon_${SIZE}x${SIZE}@2x.png"
    done
    cp "$ICONSET_DIR/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"
    iconutil -c icns -o "$CONTENTS/Resources/AppIcon.icns" "$ICONSET_DIR"
    ICON_CREATED=true
    rm -rf "$ICONSET_DIR"
fi

if [ "$ICON_CREATED" = true ]; then
    echo "==> App icon created successfully"
else
    echo "==> WARNING: Could not create app icon (install librsvg: brew install librsvg)"
fi

# Update Info.plist with icon and bundle identifier
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$CONTENTS/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string 'AppIcon'" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIdentifier" "$CONTENTS/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string 'com.sabyrzhan.keyboardcleaner'" "$CONTENTS/Info.plist"

# Remove LSUIElement so app shows in Launchpad (it's still a utility, but needs to be visible)
# LSUIElement=true hides from Dock but app is still in Launchpad if in /Applications

echo ""
echo "==> Build complete!"
echo "    App bundle: $APP_BUNDLE"
echo ""
echo "    To install, run:"
echo "    cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "    The app will appear in Launchpad after copying to /Applications."
