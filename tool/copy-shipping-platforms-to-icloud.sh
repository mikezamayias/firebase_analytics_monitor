#!/usr/bin/env bash
# Copy shipping-monitor Android + iOS clips to iCloud Documents.
set -euo pipefail

FAMON_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$FAMON_DIR/assets/demos/linkedin/shipping-monitor"
ICLOUD="${ICLOUD_FAMON_DIR:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/famon/linkedin}"

mkdir -p "$ICLOUD"

CREATOR_SHIPPING="${CREATOR_SHIPPING:-$HOME/Developer/creator-stack/famon/linkedin/shipping-monitor}"

for platform in android ios; do
  flat="$CREATOR_SHIPPING/${platform}-demo.mp4"
  nested="$SRC/$platform/demo.mp4"
  if [[ -f "$flat" ]]; then
    /bin/cp -f "$flat" "$ICLOUD/famon-shipping-monitor-${platform}.mp4"
    echo "→ $ICLOUD/famon-shipping-monitor-${platform}.mp4"
  elif [[ -f "$nested" ]]; then
    /bin/cp -f "$nested" "$ICLOUD/famon-shipping-monitor-${platform}.mp4"
    echo "→ $ICLOUD/famon-shipping-monitor-${platform}.mp4 (from famon repo)"
  fi
done

# Legacy single-file name (iOS if present, else android) for older workflows
if [[ -f "$CREATOR_SHIPPING/ios-demo.mp4" ]]; then
  /bin/cp -f "$CREATOR_SHIPPING/ios-demo.mp4" "$ICLOUD/famon-shipping-monitor-demo.mp4"
elif [[ -f "$CREATOR_SHIPPING/android-demo.mp4" ]]; then
  /bin/cp -f "$CREATOR_SHIPPING/android-demo.mp4" "$ICLOUD/famon-shipping-monitor-demo.mp4"
elif [[ -f "$SRC/ios/demo.mp4" ]]; then
  /bin/cp -f "$SRC/ios/demo.mp4" "$ICLOUD/famon-shipping-monitor-demo.mp4"
elif [[ -f "$SRC/android/demo.mp4" ]]; then
  /bin/cp -f "$SRC/android/demo.mp4" "$ICLOUD/famon-shipping-monitor-demo.mp4"
fi
