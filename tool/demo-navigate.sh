#!/usr/bin/env bash
# Navigate Wolt via mobile-mcp — dense taps for ~80s of FA events
PY=/Users/mzamagias/Developer/Dart/famon/tool/mobile-mcp-call.py
D=644bfdb7

tap() { python3 "$PY" mobile_click_on_screen_at_coordinates "{\"device\":\"$D\",\"x\":$1,\"y\":$2}" > /dev/null 2>&1; }
swipe() { python3 "$PY" mobile_swipe_on_screen "{\"device\":\"$D\",\"startX\":$1,\"startY\":$2,\"endX\":$3,\"endY\":$4,\"duration\":300}" > /dev/null 2>&1; }
goback() { adb shell input keyevent 4; }
typet() { python3 "$PY" mobile_type_keys "{\"device\":\"$D\",\"text\":\"$1\"}" > /dev/null 2>&1; }

sleep 6

# Round 1: Browse restaurants
tap 148 498; sleep 2.5
swipe 540 1800 540 600; sleep 1.5
tap 540 900; sleep 3
swipe 540 1800 540 600; sleep 1.5
swipe 540 1800 540 600; sleep 1.5
tap 540 800; sleep 2
goback; sleep 1.5
goback; sleep 1.5
tap 540 1200; sleep 3
swipe 540 1800 540 600; sleep 1.5
goback; sleep 1.5
goback; sleep 1.5

# Round 2: Groceries
tap 379 498; sleep 2.5
swipe 540 1800 540 600; sleep 1.5
tap 540 900; sleep 3
swipe 540 1800 540 600; sleep 1
goback; sleep 1.5
goback; sleep 1.5

# Round 3: Search souvlaki
tap 540 2224; sleep 1.5
typet "famon"; sleep 0.5
adb shell input keyevent 66; sleep 3
tap 540 800; sleep 2.5
swipe 540 1800 540 600; sleep 1.5
goback; sleep 1

# Round 4: Back to home, browse more
goback; sleep 1.5
goback; sleep 1.5
tap 148 498; sleep 2.5
swipe 540 1800 540 600; sleep 1.5
swipe 540 1800 540 600; sleep 1.5
tap 540 600; sleep 3
swipe 540 1800 540 600; sleep 1.5
tap 540 900; sleep 2
goback; sleep 1.5
goback; sleep 1.5

# Round 5: Search pizza
tap 540 2224; sleep 1.5
typet "pub.dev"; sleep 0.5
adb shell input keyevent 66; sleep 3
tap 540 600; sleep 2.5
swipe 540 1800 540 600; sleep 1
goback; sleep 1
goback; sleep 1.5
goback; sleep 1
