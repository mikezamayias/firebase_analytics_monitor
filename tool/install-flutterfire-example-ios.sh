#!/usr/bin/env bash
# Build and install the official FlutterFire firebase_analytics example on the booted iOS Simulator.
#
# Usage:
#   ./tool/install-flutterfire-example-ios.sh
#   FLUTTERFIRE_EXAMPLE_DIR=/path/to/example ./tool/install-flutterfire-example-ios.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=demo-config.sh
source "$SCRIPT_DIR/demo-config.sh"

if ! command -v flutter >/dev/null; then
  echo "flutter not in PATH" >&2
  exit 1
fi
if ! xcrun simctl list devices booted 2>/dev/null | grep -q Booted; then
  echo "Boot an iOS Simulator first (Simulator.app)" >&2
  exit 1
fi

WORKDIR=""
cleanup() {
  if [[ -n "$WORKDIR" && -d "$WORKDIR" ]]; then
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT

resolve_example_dir() {
  if [[ -n "$FLUTTERFIRE_EXAMPLE_DIR" && -f "$FLUTTERFIRE_EXAMPLE_DIR/pubspec.yaml" ]]; then
    echo "$FLUTTERFIRE_EXAMPLE_DIR"
    return
  fi
  WORKDIR="$(mktemp -d)"
  echo "Cloning flutterfire (shallow)…" >&2
  git clone --depth 1 https://github.com/firebase/flutterfire.git "$WORKDIR/flutterfire"
  echo "$WORKDIR/flutterfire/packages/firebase_analytics/firebase_analytics/example"
}

EXAMPLE_DIR="$(resolve_example_dir)"
cd "$EXAMPLE_DIR"

echo "flutter pub get ($EXAMPLE_DIR)"
flutter pub get

echo "Building iOS simulator app…"
flutter build ios --simulator --debug

APP_PATH="$EXAMPLE_DIR/build/ios/iphonesimulator/Runner.app"
if [[ ! -d "$APP_PATH" ]]; then
  # Flutter 3.16+ may use different output path
  APP_PATH="$(find "$EXAMPLE_DIR/build/ios" -name 'Runner.app' -type d | head -1)"
fi
if [[ ! -d "$APP_PATH" ]]; then
  echo "Runner.app not found under build/ios" >&2
  exit 1
fi

echo "Installing on booted simulator: $APP_PATH"
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted "$DEMO_BUNDLE_ID" -FIRAnalyticsDebugEnabled >/dev/null || true

echo "Installed $DEMO_BUNDLE_ID — run famon monitor --platform ios-simulator"
