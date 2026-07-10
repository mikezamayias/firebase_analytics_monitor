#!/usr/bin/env bash
# Record separate LinkedIn clips for shipping-monitor: Android + iOS (~26s each).
#
# Android: prefers VHS if adb device available; else VHS without live events (never trim old demo.mp4 — wrong font).
# iOS: requires booted Simulator + install-flutterfire-example-ios.sh once.
#
# Usage:
#   ./tool/record-shipping-platform-demos.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=demo-config.sh
source "$SCRIPT_DIR/demo-config.sh"

LINKEDIN="$FAMON_DIR/assets/demos/linkedin/shipping-monitor"
DURATION="${LINKEDIN_CLIP_SECONDS:-26}"
FRAME_RATE="${LINKEDIN_FRAME_RATE:-60}"

record_vhs() {
  local platform="$1"
  local subdir="$2"
  local tape="$LINKEDIN/$subdir/demo.tape"
  if [[ ! -f "$tape" ]]; then
    echo "Missing $tape" >&2
    return 1
  fi
  mkdir -p "$LINKEDIN/$subdir"
  export FAMON_DEMO_PLATFORM="$platform"
  echo "=== VHS $subdir ($platform, ~${DURATION}s) ==="
  "$SCRIPT_DIR/prep-flutterfire-demo.sh"
  (cd "$FAMON_DIR" && vhs "$tape")
  normalize_mp4_fps "$LINKEDIN/$subdir/demo.mp4"
  ls -lh "$LINKEDIN/$subdir"/demo.{mp4,gif}
}

normalize_mp4_fps() {
  local mp4="$1"
  if [[ ! -f "$mp4" ]]; then
    return
  fi

  local fps
  fps="$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=avg_frame_rate \
    -of default=noprint_wrappers=1:nokey=1 "$mp4")"
  if [[ "$fps" == "$FRAME_RATE/1" ]]; then
    return
  fi

  local tmp="${mp4%.mp4}.${FRAME_RATE}fps.tmp.mp4"
  ffmpeg -y -hide_banner -loglevel error \
    -i "$mp4" -vf "fps=$FRAME_RATE" \
    -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p -movflags +faststart \
    "$tmp"
  mv "$tmp" "$mp4"
}

trim_android_fallback() {
  local src="$FAMON_DIR/assets/demo.mp4"
  local out_dir="$LINKEDIN/android"
  if [[ ! -f "$src" ]]; then
    echo "No $src — connect Android and re-run, or record manually" >&2
    return 1
  fi
  mkdir -p "$out_dir"
  local start="${ANDROID_TRIM_START:-4.5}"
  echo "=== Trim Android from $(basename "$src") (${start}s + ${DURATION}s) ==="
  ffmpeg -y -hide_banner -loglevel error \
    -ss "$start" -i "$src" -t "$DURATION" \
    -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p -movflags +faststart \
    "$out_dir/demo.mp4"
  ffmpeg -y -hide_banner -loglevel error \
    -i "$out_dir/demo.mp4" -vf "fps=15,scale=1024:-1:flags=lanczos" \
    "$out_dir/demo.gif"
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$out_dir/demo.mp4"
}

if [[ ! -x "$FAMON_DIR/build/famon" ]]; then
  echo "build/famon missing — compile famon first" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null; then
  echo "ffmpeg required" >&2
  exit 1
fi

# --- Android ---
if adb_has_device; then
  export FAMON_DEMO_PLATFORM=android
  record_vhs android android
else
  echo "No adb device — recording Android via VHS anyway (no live log events; FontSize from demo.tape is preserved)"
  echo "  Connect a phone/emulator and re-run for a clip with real monitor output."
  export FAMON_DEMO_PLATFORM=android
  record_vhs android android
fi

# --- iOS Simulator ---
if ! xcrun simctl list devices booted 2>/dev/null | grep -q Booted; then
  echo "Boot an iOS Simulator, then re-run for the iOS clip" >&2
  exit 1
fi
if ! xcrun simctl listapps booted 2>/dev/null | grep -q firebase.analytics.example; then
  echo "Installing FlutterFire example on booted simulator (unmodified upstream)…"
  "$SCRIPT_DIR/install-flutterfire-example-ios.sh"
fi
record_vhs ios-simulator ios

"$SCRIPT_DIR/normalize-shipping-android-aspect.sh"

"$FAMON_DIR/tool/sync-linkedin-to-creator-stack.sh"
"$SCRIPT_DIR/copy-shipping-platforms-to-icloud.sh"

echo ""
echo "Done. Publish bundle (after sync):"
echo "  ~/Developer/creator-stack/famon/linkedin/shipping-monitor/android-demo.mp4"
echo "  ~/Developer/creator-stack/famon/linkedin/shipping-monitor/ios-demo.mp4"
