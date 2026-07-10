#!/usr/bin/env bash
# Record LinkedIn-optimized famon demos (VHS tapes in assets/demos/linkedin/<project>/).
#
# Requires:
#   - vhs (brew install vhs)
#   - famon built: dart compile exe -o build/famon bin/famon.dart
#   - Android: adb + FlutterFire example installed
#   - iOS: booted Simulator + ./tool/install-flutterfire-example-ios.sh
#
# Usage:
#   ./tool/record-linkedin-demos.sh
#   ./tool/record-linkedin-demos.sh shipping-monitor
#   FAMON_DEMO_PLATFORM=ios-simulator ./tool/record-linkedin-demos.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=demo-config.sh
source "$SCRIPT_DIR/demo-config.sh"

LINKEDIN_DIR="$FAMON_DIR/assets/demos/linkedin"

case "$FAMON_DEMO_PLATFORM" in
  android)
    if ! command -v adb >/dev/null; then
      echo "adb not found — connect an Android device or start an emulator" >&2
      exit 1
    fi
    if ! adb_has_device; then
      echo "No adb device — plug in a phone or run an emulator, then retry" >&2
      adb devices
      exit 1
    fi
    ;;
  ios-simulator)
    if ! xcrun simctl list devices booted 2>/dev/null | grep -q Booted; then
      echo "No booted iOS Simulator" >&2
      exit 1
    fi
    ;;
  *)
    echo "FAMON_DEMO_PLATFORM must be android or ios-simulator for VHS record (got: $FAMON_DEMO_PLATFORM)" >&2
    exit 1
    ;;
esac

if [[ ! -x "$FAMON_DIR/build/famon" ]]; then
  echo "build/famon missing — run: cd $FAMON_DIR && dart compile exe -o build/famon bin/famon.dart" >&2
  exit 1
fi

prep() {
  "$SCRIPT_DIR/prep-flutterfire-demo.sh"
}

record_project() {
  local project="$1"
  local tape="$LINKEDIN_DIR/$project/demo.tape"
  if [[ ! -f "$tape" ]]; then
    echo "Missing $tape" >&2
    return 1
  fi
  mkdir -p "$LINKEDIN_DIR/$project"
  local resolved
  resolved="$("$SCRIPT_DIR/demo-tape-for-platform.sh" "$tape")"
  echo "=== Recording $project ($FAMON_DEMO_PLATFORM) ==="
  prep
  export FAMON_DEMO_PLATFORM
  (cd "$FAMON_DIR" && vhs "$resolved")
  if [[ "$resolved" == /tmp/* ]] || [[ "$resolved" == "${TMPDIR:-/tmp}"/* ]]; then
    rm -f "$resolved"
  fi
  echo "=== Done $project ==="
  ls -lh "$LINKEDIN_DIR/$project"/demo.{mp4,gif} 2>/dev/null || true
  echo ""
}

PROJECTS=(shipping-monitor tooling-filters tooling-alias)
if [[ $# -gt 0 ]]; then
  PROJECTS=("$@")
fi

for p in "${PROJECTS[@]}"; do
  record_project "$p"
done

"$FAMON_DIR/tool/sync-linkedin-to-creator-stack.sh"

echo "=== LinkedIn assets (repo) ==="
ls -lh "$LINKEDIN_DIR"/*/demo.{mp4,gif} 2>/dev/null || true
