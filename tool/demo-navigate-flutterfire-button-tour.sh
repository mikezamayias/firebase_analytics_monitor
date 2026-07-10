#!/usr/bin/env bash
# Tap each FlutterFire example home-screen button in order (stock app, unmodified),
# then open the tabs FAB and switch tabs.
#
# famon monitor shows parsed "Logging event" lines (event names). Widen
# DEMO_IOS_SHOW_ONLY / --show-only to match what each button actually logs:
#   - Test logEvent → test_event
#   - Test standard event types → login, purchase, search, sign_up, screen_view,
#     add_to_cart, and many more (one real burst)
#   - setUserId / setUserProperty / setConsent → usually no named event line
#     (SDK config; use famon monitor --verbose to see raw FirebaseAnalytics logs)
#   - FAB tabs → screen_view per tab
#
# Usage:
#   FAMON_DEMO_PLATFORM=ios-simulator FAMON_DEMO_TAP_GAP=2.1 ./tool/demo-navigate-flutterfire-button-tour.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=demo-config.sh
source "$SCRIPT_DIR/demo-config.sh"

HELPER="$SCRIPT_DIR/flutterfire-demo-mobile.py"
GAP="${FAMON_DEMO_TAP_GAP:-2.1}"
START_DELAY="${FAMON_DEMO_START_DELAY:-2.0}"

echo "Button tour on $FAMON_DEMO_PLATFORM (${GAP}s between taps)…"
sleep "$START_DELAY"
python3 "$HELPER" button-tour "$FAMON_DEMO_PLATFORM" "$GAP"
echo "Button tour done."
