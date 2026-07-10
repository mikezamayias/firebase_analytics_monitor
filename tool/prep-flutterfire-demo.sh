#!/usr/bin/env bash
# Prepare FlutterFire analytics example for famon demo recording.
#
# Usage:
#   FAMON_DEMO_PLATFORM=android ./tool/prep-flutterfire-demo.sh
#   FAMON_DEMO_PLATFORM=ios-simulator ./tool/prep-flutterfire-demo.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=demo-config.sh
source "$SCRIPT_DIR/demo-config.sh"

case "$FAMON_DEMO_PLATFORM" in
  android)
    if ! command -v adb >/dev/null; then
      echo "adb not found" >&2
      exit 1
    fi
    if ! adb_has_device; then
      echo "No adb device — start an emulator or connect a phone" >&2
      adb devices
      exit 1
    fi
    echo "Preparing Android ($DEMO_PKG)..."
    adb logcat -c
    adb shell setprop debug.firebase.analytics.app "$DEMO_PKG"
    adb shell setprop log.tag.FA VERBOSE
    adb shell setprop log.tag.FA-SVC VERBOSE
    adb shell am force-stop "$DEMO_PKG" || true
    sleep 1
    adb shell am start -n "$DEMO_ANDROID_ACTIVITY"
    sleep 4
    ;;
  ios-simulator)
    if ! command -v xcrun >/dev/null; then
      echo "xcrun not found — install Xcode Command Line Tools" >&2
      exit 1
    fi
    if ! xcrun simctl list devices booted 2>/dev/null | grep -q Booted; then
      echo "No booted iOS Simulator — open Simulator.app and boot a device" >&2
      xcrun simctl list devices booted
      exit 1
    fi
    if ! xcrun simctl listapps booted 2>/dev/null | grep -q "$DEMO_BUNDLE_ID"; then
      echo "FlutterFire example not installed on booted simulator." >&2
      echo "Run: $SCRIPT_DIR/install-flutterfire-example-ios.sh" >&2
      exit 1
    fi
    echo "Preparing iOS Simulator ($DEMO_BUNDLE_ID)..."
    xcrun simctl terminate booted "$DEMO_BUNDLE_ID" 2>/dev/null || true
    sleep 1
    # Firebase Analytics debug stream (same as Xcode scheme argument).
    xcrun simctl launch booted "$DEMO_BUNDLE_ID" -FIRAnalyticsDebugEnabled >/dev/null
    sleep 4
    ;;
  ios-device)
    echo "iOS device prep: install app + enable -FIRAnalyticsDebugEnabled in Xcode scheme, then launch manually." >&2
    echo "Bundle ID: $DEMO_BUNDLE_ID" >&2
    if ! command -v idevice_id >/dev/null; then
      echo "idevicesyslog missing — brew install libimobiledevice" >&2
      exit 1
    fi
    if ! idevice_id -l | grep -q .; then
      echo "No trusted iOS device connected" >&2
      exit 1
    fi
    ;;
  *)
    echo "FAMON_DEMO_PLATFORM must be android, ios-simulator, or ios-device (got: $FAMON_DEMO_PLATFORM)" >&2
    exit 1
    ;;
esac

echo "Ready ($FAMON_DEMO_PLATFORM)."
