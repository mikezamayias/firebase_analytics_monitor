# FlutterFire example — demo recording (Android + iOS)

Demos use the official [firebase_analytics example](https://github.com/firebase/flutterfire/tree/main/packages/firebase_analytics/firebase_analytics/example):

| Platform | ID |
|----------|-----|
| Android package | `io.flutter.plugins.firebase.analytics.example` |
| iOS bundle ID | `io.flutter.plugins.firebase.analytics.example` |

Automation taps **Test standard event types** (~29 events, ~2s apart) via `tool/flutterfire-demo-mobile.py` (mobile-mcp).

## Android (default)

```bash
# Device/emulator + example APK installed (flutter run from example dir)
./tool/prep-flutterfire-demo.sh
./tool/demo-navigate-flutterfire.sh   # background taps
famon monitor --platform android
```

Record LinkedIn tapes:

```bash
./tool/record-linkedin-demos.sh
```

## iOS Simulator

```bash
# 1) Boot a simulator in Simulator.app
./tool/install-flutterfire-example-ios.sh

# 2) Record (VHS) or manual monitor
FAMON_DEMO_PLATFORM=ios-simulator ./tool/prep-flutterfire-demo.sh
FAMON_DEMO_PLATFORM=ios-simulator ./tool/demo-navigate-flutterfire.sh &
famon monitor --platform ios-simulator

# LinkedIn VHS batch
FAMON_DEMO_PLATFORM=ios-simulator ./tool/record-linkedin-demos.sh shipping-monitor
```

iOS uses `-FIRAnalyticsDebugEnabled` at launch (no `adb setprop`). Enable the same flag in Xcode if you run the example from the IDE.

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `FAMON_DEMO_PLATFORM` | `android` | `android`, `ios-simulator`, `ios-device` |
| `FLUTTERFIRE_EXAMPLE_DIR` | _(clone)_ | Local example path for `install-flutterfire-example-ios.sh` |

## Shipping post — separate Android + iOS clips (~26s)

For the launch post, record **two** attachments (platform is visible at monitor startup):

```bash
./tool/record-shipping-platform-demos.sh
```

Outputs:

- `assets/demos/linkedin/shipping-monitor/android/demo.mp4`
- `assets/demos/linkedin/shipping-monitor/ios/demo.mp4`

Startup lines to call out in copy: `Connecting to Android` / `Connecting to iOS Simulator` and `Platform: …`.

## LinkedIn disclosure

Posts should mention debug Analytics from the FlutterFire **example** app, not production user traffic.
