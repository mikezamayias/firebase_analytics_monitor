#!/usr/bin/env bash
# Record all 4 v6 showcase demos sequentially.
#
# Usage:
#   ./tool/record-v6.sh
#   FAMON_DEMO_PLATFORM=ios-simulator ./tool/record-v6.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=demo-config.sh
source "$SCRIPT_DIR/demo-config.sh"

prep() {
  "$SCRIPT_DIR/prep-flutterfire-demo.sh"
}

for dir in 01-unfiltered 02-event-filter 03-param-filter 04-hide-events; do
  echo "=== Recording $dir ($FAMON_DEMO_PLATFORM) ==="
  prep
  tape="$FAMON_DIR/assets/demos/v6-showcase/$dir/demo.tape"
  resolved="$("$SCRIPT_DIR/demo-tape-for-platform.sh" "$tape")"
  (cd "$FAMON_DIR" && vhs "$resolved" 2>&1 | tail -3)
  if [[ "$resolved" == /tmp/* ]] || [[ "$resolved" == "${TMPDIR:-/tmp}"/* ]]; then
    rm -f "$resolved"
  fi
  echo "=== Done $dir ==="
  echo ""
done

echo "=== All done ==="
ls -lh "$FAMON_DIR/assets/demos/v6-showcase"/*/demo.mp4 2>/dev/null || true
