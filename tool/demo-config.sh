# Shared FlutterFire analytics example identifiers for famon demo scripts.
# Source: packages/firebase_analytics/firebase_analytics/example (Android + iOS).

# shellcheck disable=SC2034
DEMO_PKG="${DEMO_PKG:-io.flutter.plugins.firebase.analytics.example}"
DEMO_BUNDLE_ID="${DEMO_BUNDLE_ID:-$DEMO_PKG}"
DEMO_ANDROID_ACTIVITY="${DEMO_ANDROID_ACTIVITY:-$DEMO_PKG/.MainActivity}"

# android | ios-simulator | ios-device
FAMON_DEMO_PLATFORM="${FAMON_DEMO_PLATFORM:-android}"

# Optional: local clone of flutterfire example (skip network clone when set).
FLUTTERFIRE_EXAMPLE_DIR="${FLUTTERFIRE_EXAMPLE_DIR:-}"

FAMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# iOS shipping monitor: named events to surface while tapping the stock FlutterFire example.
# (setUserId / setUserProperty / setConsent are SDK config — they rarely appear as named
# Logging event lines; famon still reads them in --verbose as raw FirebaseAnalytics chatter.)
DEMO_IOS_SHOW_ONLY="${DEMO_IOS_SHOW_ONLY:-test_event,login,purchase,search,sign_up,screen_view,add_to_cart}"

# macOS awk runs END even after an action exit; use a flag (see record-shipping-platform-demos.sh).
adb_has_device() {
  command -v adb >/dev/null || return 1
  adb devices 2>/dev/null | awk 'NR>1 && $2 == "device" { found = 1 } END { exit(found ? 0 : 1) }'
}
