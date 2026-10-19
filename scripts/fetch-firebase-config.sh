#!/bin/sh
# Downloads the Firebase config for the iOS app into the app bundle sources.
# Run it again after enabling a new sign-in provider in the Firebase console:
# Google Sign-In only adds CLIENT_ID and REVERSED_CLIENT_ID once it is on.
#
#     sh scripts/fetch-firebase-config.sh
set -eu
cd "$(dirname "$0")/.."
# The CLI refuses to overwrite, so the old copy goes first.
rm -f iAdaptOps/Config/GoogleService-Info.plist
firebase apps:sdkconfig IOS 1:711836273030:ios:a76c4701c7e537a1354407 \
  --project iadaptops-vidi \
  --out iAdaptOps/Config/GoogleService-Info.plist
