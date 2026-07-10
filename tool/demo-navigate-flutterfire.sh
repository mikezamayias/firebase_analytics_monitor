#!/usr/bin/env bash
# FlutterFire analytics example — tap "Test standard event types" (29 events, ~2s gaps).
# Works on Android (adb device) and iOS Simulator via mobile-mcp accessibility tree.
#
# Usage:
#   ./tool/demo-navigate-flutterfire.sh
#   FAMON_DEMO_PLATFORM=ios-simulator ./tool/demo-navigate-flutterfire.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=demo-config.sh
source "$SCRIPT_DIR/demo-config.sh"

HELPER="$SCRIPT_DIR/flutterfire-demo-mobile.py"

tap_standard() {
  python3 "$HELPER" tap-standard-events "$FAMON_DEMO_PLATFORM" >/dev/null
}

sleep 2

tap_standard
sleep 65

tap_standard
sleep 65

tap_standard
sleep 65
