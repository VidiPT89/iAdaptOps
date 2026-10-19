#!/bin/sh
# Build phase: adds the URL schemes the sign-in redirects come back on to the
# built Info.plist, read from GoogleService-Info.plist so they never go stale.
#  - REVERSED_CLIENT_ID: Google Sign-In (present once Google is enabled).
#  - app-<GOOGLE_APP_ID>: Firebase's generic OAuth flow, used by Microsoft.
set -eu
CONFIG="$SRCROOT/iAdaptOps/Config/GoogleService-Info.plist"
PLIST="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
BUDDY=/usr/libexec/PlistBuddy

[ -f "$CONFIG" ] || { echo "warning: GoogleService-Info.plist missing, sign-in URL schemes not registered"; exit 0; }

$BUDDY -c "Delete :CFBundleURLTypes" "$PLIST" 2>/dev/null || true
$BUDDY -c "Add :CFBundleURLTypes array" "$PLIST"
$BUDDY -c "Add :CFBundleURLTypes:0 dict" "$PLIST"
$BUDDY -c "Add :CFBundleURLTypes:0:CFBundleURLName string SignIn" "$PLIST"
$BUDDY -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$PLIST"

APP_ID=$($BUDDY -c "Print :GOOGLE_APP_ID" "$CONFIG")
$BUDDY -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string app-$(echo "$APP_ID" | tr ':' '-')" "$PLIST"

REVERSED=$($BUDDY -c "Print :REVERSED_CLIENT_ID" "$CONFIG" 2>/dev/null || true)
if [ -n "$REVERSED" ]; then
  $BUDDY -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:1 string $REVERSED" "$PLIST"
fi
