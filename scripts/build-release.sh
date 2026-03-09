#!/bin/bash
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────
VERSION="${1:?Usage: $0 <version> (e.g. 1.0.2)}"
BUILD="${2:-1}"
IDENTITY="Developer ID Application: DCTR Inc. (7MXQUU6YV7)"
TEAM_ID="7MXQUU6YV7"
BUNDLE_ID_PREFIX="cz.dctr.pedalhud"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

APP_PATH=".build/PedalHUD.xcarchive/Products/Applications/PedalHUD.app"
ZIP_NAME="PedalHUD-${VERSION}.zip"
DMG_NAME="PedalHUD-${VERSION}.dmg"
APPCAST_NAME="appcast.xml"
MAIN_ENTITLEMENTS="Apps/PedalHUDMac/Resources/PedalHUD.entitlements"
EXT_ENTITLEMENTS="Apps/PedalHUDCameraExtension/Resources/PedalHUDCameraExtension.entitlements"

# ── Step 1: Archive ────────────────────────────────────────────
echo "==> Archiving PedalHUD v${VERSION} (build ${BUILD})..."
xcodebuild archive \
    -project PedalHUD/PedalHUD.xcodeproj \
    -scheme PedalHUD \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath .build/PedalHUD.xcarchive \
    -allowProvisioningUpdates \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD" \
    MACOSX_DEPLOYMENT_TARGET=15.0 \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    BUNDLE_ID_PREFIX="$BUNDLE_ID_PREFIX" \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO

# ── Step 2: Embed Developer ID provisioning profiles ──────────
echo "==> Removing development provisioning profiles..."
find "$APP_PATH" -name "embedded.provisionprofile" -delete -print

PROFILES_DIR="${PROFILES_DIR:-$PROJECT_DIR/Config/profiles}"
MAIN_PROFILE="$PROFILES_DIR/PedalHUD_Developer_ID.provisionprofile"
EXT_PROFILE="$PROFILES_DIR/PedalHUD_Camera_extension_Developer_ID.provisionprofile"

if [ -f "$MAIN_PROFILE" ] && [ -f "$EXT_PROFILE" ]; then
    echo "==> Embedding Developer ID provisioning profiles..."
    cp "$MAIN_PROFILE" "$APP_PATH/Contents/embedded.provisionprofile"
    EXT_PATH=$(find "$APP_PATH" -name "*.systemextension" -type d | head -1)
    if [ -n "$EXT_PATH" ]; then
        cp "$EXT_PROFILE" "$EXT_PATH/Contents/embedded.provisionprofile"
    fi
else
    echo "WARNING: Provisioning profiles not found in $PROFILES_DIR"
    echo "  System extension features may not work without them."
    echo "  Download from Apple Developer portal and place in Config/profiles/"
fi

# ── Step 3: Re-sign with Developer ID ──────────────────────────
echo "==> Signing with Developer ID..."

# Sign all standalone Mach-O executables
find "$APP_PATH" -type f -perm +111 | while read binary; do
    if file "$binary" | grep -q "Mach-O"; then
        echo "  Signing binary: $binary"
        codesign --force --options runtime --timestamp --sign "$IDENTITY" "$binary"
    fi
done

# Sign all dylibs
find "$APP_PATH" -name "*.dylib" | while read lib; do
    echo "  Signing dylib: $lib"
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$lib"
done

# Sign all bundles (deepest first)
find "$APP_PATH" -type d \( -name "*.app" -o -name "*.framework" -o -name "*.systemextension" -o -name "*.xpc" -o -name "*.appex" \) | awk '{print length, $0}' | sort -rn | cut -d' ' -f2- | while read component; do
    if [ "$component" = "$APP_PATH" ]; then
        continue
    fi
    ENTITLEMENTS_FLAG=""
    if [[ "$component" == *.systemextension ]]; then
        ENTITLEMENTS_FLAG="--entitlements $EXT_ENTITLEMENTS"
    fi
    echo "  Signing bundle: $component"
    codesign --force --options runtime --timestamp --sign "$IDENTITY" $ENTITLEMENTS_FLAG "$component"
done

# Sign the main app last with its entitlements
echo "  Signing main app: $APP_PATH"
codesign --force --options runtime --timestamp --sign "$IDENTITY" --entitlements "$MAIN_ENTITLEMENTS" "$APP_PATH"

echo "==> Verifying signature..."
codesign --verify --deep --strict "$APP_PATH"
echo "  Entitlements:"
codesign -d --entitlements - "$APP_PATH" 2>&1 | head -20

# ── Step 4: Create ZIP ─────────────────────────────────────────
echo "==> Creating ZIP..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_NAME"

# ── Step 5: Notarize ──────────────────────────────────────────
echo "==> Notarizing (this may take a few minutes)..."

# Try keychain profile first, then env vars, then prompt
if xcrun notarytool history --keychain-profile "notarytool" >/dev/null 2>&1; then
    NOTARIZE_ARGS=(--keychain-profile "notarytool")
elif [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_ID_PASSWORD:-}" ]; then
    NOTARIZE_ARGS=(--apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID")
else
    echo "No notarization credentials found."
    echo "Either set APPLE_ID and APPLE_ID_PASSWORD env vars, or run:"
    echo "  xcrun notarytool store-credentials notarytool --apple-id YOUR_ID --team-id $TEAM_ID"
    exit 1
fi

SUBMISSION=$(xcrun notarytool submit "$ZIP_NAME" "${NOTARIZE_ARGS[@]}" --wait --output-format json)
echo "$SUBMISSION"
STATUS=$(echo "$SUBMISSION" | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")

if [ "$STATUS" != "Accepted" ]; then
    SUBMISSION_ID=$(echo "$SUBMISSION" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
    echo "Notarization FAILED ($STATUS). Fetching log..."
    xcrun notarytool log "$SUBMISSION_ID" "${NOTARIZE_ARGS[@]}" notarization-log.json 2>/dev/null || true
    cat notarization-log.json 2>/dev/null
    exit 1
fi

# ── Step 6: Staple ─────────────────────────────────────────────
echo "==> Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

# Re-create ZIP after stapling
rm "$ZIP_NAME"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_NAME"

# ── Step 7: Generate Sparkle appcast ───────────────────────────
echo "==> Generating appcast..."
SIGN_UPDATE=$(find .build -name "sign_update" -type f | head -1)

if [ -z "$SIGN_UPDATE" ]; then
    echo "sign_update not found in build artifacts, downloading Sparkle tools..."
    SPARKLE_TAG=$(curl -sI "https://github.com/sparkle-project/Sparkle/releases/latest" | grep -i "^location:" | sed 's/.*tag\///' | tr -d '\r\n')
    curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_TAG}/Sparkle-${SPARKLE_TAG#v}.tar.xz" -o /tmp/sparkle.tar.xz
    mkdir -p /tmp/sparkle
    tar xJ -C /tmp/sparkle -f /tmp/sparkle.tar.xz
    SIGN_UPDATE=$(find /tmp/sparkle -name "sign_update" -type f | head -1)
fi

SPARKLE_SIGNATURE=$("$SIGN_UPDATE" "$ZIP_NAME")
DOWNLOAD_URL="https://github.com/davidmokos/PedalHUD/releases/download/v${VERSION}/${ZIP_NAME}"
PUB_DATE=$(date -R)

cat > "$APPCAST_NAME" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>PedalHUD</title>
    <link>https://github.com/davidmokos/PedalHUD/releases</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:version>${BUILD}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
      <enclosure
        url="${DOWNLOAD_URL}"
        ${SPARKLE_SIGNATURE}
        type="application/octet-stream"
      />
    </item>
  </channel>
</rss>
EOF

# ── Step 8: Create DMG ─────────────────────────────────────────
echo "==> Creating DMG..."
rm -rf dmg_staging
mkdir -p dmg_staging
cp -R "$APP_PATH" dmg_staging/
ln -s /Applications dmg_staging/Applications

hdiutil create -volname "PedalHUD" \
    -srcfolder dmg_staging \
    -ov -format UDZO \
    "$DMG_NAME"
rm -rf dmg_staging

# ── Done ───────────────────────────────────────────────────────
echo ""
echo "==> Build complete!"
echo "  DMG: $PROJECT_DIR/$DMG_NAME"
echo "  ZIP: $PROJECT_DIR/$ZIP_NAME"
echo "  Appcast: $PROJECT_DIR/$APPCAST_NAME"
echo ""
echo "To create a GitHub release:"
echo "  gh release create v${VERSION} '$DMG_NAME' '$ZIP_NAME' '$APPCAST_NAME' --title 'PedalHUD v${VERSION}'"
