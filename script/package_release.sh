#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

APP_NAME="Nodoze"
DISPLAY_NAME="nodoze"
BUNDLE_ID="io.nodoze.mac"
VERSION="0.1.0"
BUILD_NUMBER="1"
MIN_SYSTEM_VERSION="14.0"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Anthony Roslund (9456DA7AJR)}"
INSTALLER_SIGNING_IDENTITY="${INSTALLER_SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
NOTARY_KEY="${NOTARY_KEY:-}"
NOTARY_KEY_ID="${NOTARY_KEY_ID:-}"
NOTARY_ISSUER="${NOTARY_ISSUER:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
APP_BUNDLE="$RELEASE_DIR/$DISPLAY_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$RELEASE_DIR/$DISPLAY_NAME-$VERSION.zip"
PKG_ROOT="$RELEASE_DIR/pkg-root"
COMPONENT_PLIST="$RELEASE_DIR/component.plist"
COMPONENT_PKG="$RELEASE_DIR/$DISPLAY_NAME-component.pkg"
PKG_PATH="$RELEASE_DIR/$DISPLAY_NAME-$VERSION.pkg"

rm -rf "$RELEASE_DIR"
mkdir -p "$APP_MACOS"

swift build --package-path "$ROOT_DIR" --configuration release --product "$APP_NAME"
BUILD_BINARY="$(swift build --package-path "$ROOT_DIR" --configuration release --product "$APP_NAME" --show-bin-path)/$APP_NAME"

cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/codesign \
  --force \
  --timestamp \
  --options runtime \
  --sign "$SIGNING_IDENTITY" \
  "$APP_BUNDLE"

/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
/usr/bin/ditto -c -k --norsrc --noextattr --keepParent "$APP_BUNDLE" "$ZIP_PATH"

mkdir -p "$PKG_ROOT/Applications"
/usr/bin/ditto --norsrc --noextattr "$APP_BUNDLE" "$PKG_ROOT/Applications/$DISPLAY_NAME.app"
/usr/bin/xattr -cr "$PKG_ROOT"
find "$PKG_ROOT" -name '._*' -delete

pkgbuild --analyze --root "$PKG_ROOT" "$COMPONENT_PLIST"
/usr/libexec/PlistBuddy -c "Set :0:BundleIsRelocatable false" "$COMPONENT_PLIST"

pkgbuild \
  --root "$PKG_ROOT" \
  --component-plist "$COMPONENT_PLIST" \
  --filter '.*[.][_].*' \
  --filter '(^|/)\.DS_Store$' \
  --identifier "$BUNDLE_ID" \
  --version "$VERSION" \
  "$COMPONENT_PKG"

if [[ -n "$INSTALLER_SIGNING_IDENTITY" ]]; then
  productbuild --package "$COMPONENT_PKG" --sign "$INSTALLER_SIGNING_IDENTITY" "$PKG_PATH"
else
  productbuild --package "$COMPONENT_PKG" "$PKG_PATH"
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  if [[ -n "$INSTALLER_SIGNING_IDENTITY" ]]; then
    xcrun notarytool submit "$PKG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$PKG_PATH"
    xcrun stapler validate "$PKG_PATH"
  fi
elif [[ -n "$NOTARY_KEY" && -n "$NOTARY_KEY_ID" && -n "$NOTARY_ISSUER" ]]; then
  xcrun notarytool submit "$ZIP_PATH" --key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER" --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  if [[ -n "$INSTALLER_SIGNING_IDENTITY" ]]; then
    xcrun notarytool submit "$PKG_PATH" --key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER" --wait
    xcrun stapler staple "$PKG_PATH"
    xcrun stapler validate "$PKG_PATH"
  fi
fi

if [[ -n "$NOTARY_PROFILE" || ( -n "$NOTARY_KEY" && -n "$NOTARY_KEY_ID" && -n "$NOTARY_ISSUER" ) ]]; then
  rm -f "$ZIP_PATH"
  /usr/bin/ditto -c -k --norsrc --noextattr --keepParent "$APP_BUNDLE" "$ZIP_PATH"
fi

echo "$ZIP_PATH"
echo "$PKG_PATH"
