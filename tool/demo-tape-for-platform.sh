#!/usr/bin/env bash
# Print path to a VHS tape file, optionally adjusted for FAMON_DEMO_PLATFORM.
# For ios-simulator, writes a temp tape with ios monitor command (stdout = path).
#
# Usage:
#   TAPE=$(./tool/demo-tape-for-platform.sh assets/demos/linkedin/shipping-monitor/demo.tape)
#   vhs "$TAPE"
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=demo-config.sh
source "$SCRIPT_DIR/demo-config.sh"

TAPE_PATH="${1:?tape path required}"

if [[ "$FAMON_DEMO_PLATFORM" == "android" ]]; then
  echo "$TAPE_PATH"
  exit 0
fi

if [[ "$FAMON_DEMO_PLATFORM" != "ios-simulator" ]]; then
  echo "demo-tape-for-platform: only android and ios-simulator supported (got $FAMON_DEMO_PLATFORM)" >&2
  exit 1
fi

TMP="$(mktemp "${TMPDIR:-/tmp}/famon-demo.XXXXXX.tape")"
sed \
  -e 's/adb logcat -c/# iOS: logs cleared via prep-flutterfire-demo.sh/' \
  -e 's/--platform android/--platform ios-simulator/g' \
  -e "s|nohup \\(.*demo-navigate-flutterfire.sh\\)|nohup env FAMON_DEMO_PLATFORM=ios-simulator \\1|" \
  "$TAPE_PATH" >"$TMP"
echo "$TMP"
