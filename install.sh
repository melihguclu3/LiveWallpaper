#!/bin/bash
set -e

APP_NAME="LiveWallpaper"
INSTALL_DIR="/Applications"

echo "==> Installing $APP_NAME..."

# Check if running from repo (build from source) or standalone
if [ -f "project.yml" ]; then
    echo "==> Building from source..."

    # Check Xcode CLI tools
    if ! xcode-select -p &>/dev/null; then
        echo "Error: Xcode Command Line Tools required."
        echo "Run: xcode-select --install"
        exit 1
    fi

    # Install xcodegen if needed
    if ! command -v xcodegen &>/dev/null; then
        echo "==> Installing xcodegen..."
        brew install xcodegen
    fi

    # Generate & build
    xcodegen generate
    xcodebuild -project "$APP_NAME.xcodeproj" \
        -scheme "$APP_NAME" \
        -configuration Release \
        build -quiet

    BUILD_DIR=$(find ~/Library/Developer/Xcode/DerivedData/"$APP_NAME"-* \
        -path "*/Release/$APP_NAME.app" -maxdepth 5 2>/dev/null | head -1)

    if [ -z "$BUILD_DIR" ]; then
        echo "Error: Build failed."
        exit 1
    fi

    SOURCE_APP="$BUILD_DIR"
else
    # Standalone install from downloaded .app
    if [ -d "$APP_NAME.app" ]; then
        SOURCE_APP="$APP_NAME.app"
    else
        echo "Error: $APP_NAME.app not found. Run this from the project directory or next to the .app bundle."
        exit 1
    fi
fi

# Kill running instance
pkill -f "$APP_NAME" 2>/dev/null || true
sleep 1

# Install
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$SOURCE_APP" "$INSTALL_DIR/$APP_NAME.app"

echo "==> Installed to $INSTALL_DIR/$APP_NAME.app"
echo "==> Launching..."
open "$INSTALL_DIR/$APP_NAME.app"
echo "==> Done! Look for the play icon in your menu bar."
