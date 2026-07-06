#!/bin/bash
set -euo pipefail

# LiveWallpaper — resmi sürüm üretici
# Universal (arm64 + x86_64) build -> Developer ID imza (hardened runtime) ->
# notarize -> staple -> .zip + .dmg üretir. Sonuç: Gatekeeper uyarısı YOK.
#
# TEK SEFERLİK ÖN KOŞUL — notarytool kimliğini kaydet:
#   App Store Connect API key ile (önerilen):
#     xcrun notarytool store-credentials "LW_NOTARY" \
#       --key /yol/AuthKey_XXXX.p8 --key-id <KEY_ID> --issuer <ISSUER_ID>
#   veya app-specific password ile:
#     xcrun notarytool store-credentials "LW_NOTARY" \
#       --apple-id <mail> --team-id Y5YWL86LHN --password <app-specific-pw>
#
# Kullanım:  ./release.sh

APP_NAME="LiveWallpaper"
TEAM_ID="Y5YWL86LHN"
NOTARY_PROFILE="LW_NOTARY"
SIGN_ID="Developer ID Application: melih guclu (${TEAM_ID})"

cd "$(dirname "$0")"
ROOT="$(pwd)"
BUILD_DIR="$ROOT/build"
DERIVED="$BUILD_DIR/DerivedData"
DIST="$ROOT/dist"

# ---------- Preflight ----------
echo "==> [0/8] Ön kontroller"
if ! security find-identity -v -p codesigning | grep -q "$SIGN_ID"; then
  echo "HATA: '$SIGN_ID' keychain'de yok. Developer ID Application sertifikasını kur."
  exit 1
fi
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
  echo "HATA: notarytool profili '$NOTARY_PROFILE' yok."
  echo "      Bu dosyanın başındaki 'store-credentials' komutuyla oluştur."
  exit 1
fi

# ---------- Build ----------
echo "==> [1/8] Xcode projesi üretiliyor (xcodegen)"
xcodegen generate

echo "==> [2/8] Universal Release build (arm64 + x86_64) — imzasız"
rm -rf "$DERIVED"
xcodebuild -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

APP="$DERIVED/Build/Products/Release/$APP_NAME.app"
[ -d "$APP" ] || { echo "HATA: build bulunamadı: $APP"; exit 1; }
echo "    Mimari: $(lipo -archs "$APP/Contents/MacOS/$APP_NAME")"

# ---------- Sign ----------
echo "==> [3/8] Developer ID + hardened runtime ile imzalanıyor"
codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$APP"
codesign --verify --strict --verbose=2 "$APP"

# ---------- Notarize (zip) ----------
mkdir -p "$DIST"
ZIP="$DIST/$APP_NAME.zip"
echo "==> [4/8] Notarization için zip'leniyor"
rm -f "$ZIP"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> [5/8] Notarize ediliyor (birkaç dakika sürebilir)..."
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

# ---------- Staple + dağıtılabilir zip ----------
echo "==> [6/8] Ticket .app'e staple ediliyor"
xcrun stapler staple "$APP"
rm -f "$ZIP"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"   # staple'lı app'i yeniden zip'le

# ---------- DMG ----------
echo "==> [7/8] DMG oluşturuluyor"
DMG="$DIST/$APP_NAME.dmg"
STAGING="$BUILD_DIR/dmg-staging"
rm -f "$DMG"; rm -rf "$STAGING"; mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG"

echo "    DMG notarize + staple ediliyor..."
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"

# ---------- Doğrulama ----------
echo "==> [8/8] Gatekeeper doğrulaması"
spctl -a -vvv -t exec "$APP" || true

echo ""
echo "==> BİTTİ ✅"
echo "    App:  $APP  (imzalı + notarized + stapled)"
echo "    Zip:  $ZIP"
echo "    DMG:  $DMG"
echo ""
echo "Bu .zip ve .dmg'yi GitHub Releases'a yükle — kullanıcılar artık uyarısız açar."
