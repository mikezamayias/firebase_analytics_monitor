#!/usr/bin/env bash
# Navigate Google Maps via mobile-mcp — dense rapid taps for ~80s of FA events
PY=/Users/mzamagias/Developer/Dart/famon/tool/mobile-mcp-call.py
D=644bfdb7

tap() { python3 "$PY" mobile_click_on_screen_at_coordinates "{\"device\":\"$D\",\"x\":$1,\"y\":$2}" > /dev/null 2>&1; }
swipe() { python3 "$PY" mobile_swipe_on_screen "{\"device\":\"$D\",\"startX\":$1,\"startY\":$2,\"endX\":$3,\"endY\":$4,\"duration\":300}" > /dev/null 2>&1; }
goback() { adb shell input keyevent 4; }
typet() { python3 "$PY" mobile_type_keys "{\"device\":\"$D\",\"text\":\"$1\"}" > /dev/null 2>&1; }

sleep 5

# Round 1: Tap Restaurants chip
tap 211 336; sleep 2
swipe 540 1800 540 600; sleep 1
tap 540 800; sleep 2
goback; sleep 1
tap 540 1200; sleep 2
goback; sleep 1
goback; sleep 1

# Round 2: Search
tap 404 189; sleep 1.5
typet "acropolis"; sleep 0.5
adb shell input keyevent 66; sleep 2
tap 540 600; sleep 2
swipe 540 1800 540 600; sleep 1
goback; sleep 1
goback; sleep 1

# Round 3: Hotels chip
tap 533 336; sleep 2
tap 540 800; sleep 2
swipe 540 1800 540 600; sleep 1
goback; sleep 1
goback; sleep 1

# Round 4: Groceries
tap 836 336; sleep 2
tap 540 800; sleep 2
goback; sleep 1
goback; sleep 1

# Round 5: Search again
tap 404 189; sleep 1.5
typet "heraklion"; sleep 0.5
adb shell input keyevent 66; sleep 2
tap 540 600; sleep 2
swipe 540 1800 540 600; sleep 1
goback; sleep 1
goback; sleep 1

# Round 6: More chips
tap 211 336; sleep 2
swipe 540 1800 540 600; sleep 1
tap 540 600; sleep 2
swipe 540 1800 540 600; sleep 1
goback; sleep 1
tap 540 1000; sleep 2
goback; sleep 1
goback; sleep 1
