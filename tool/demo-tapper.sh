#!/usr/bin/env bash
# Background script: taps around Wolt on connected Android device
# to generate Firebase Analytics events while famon monitor records.
# Screen: 1080x2400. Wolt home: categories row ~y400, search ~y560, list ~y800+

sleep 4

# Tap Restaurants category (leftmost icon)
adb shell input tap 55 400
sleep 2

# Scroll restaurant list
adb shell input swipe 540 1800 540 800 400
sleep 1.5

# Tap first restaurant card
adb shell input tap 540 900
sleep 2

# Scroll restaurant menu
adb shell input swipe 540 1800 540 600 400
sleep 1.5

# Scroll more
adb shell input swipe 540 1800 540 600 400
sleep 1.5

# Back to list
adb shell input keyevent 4
sleep 1.5

# Tap second restaurant
adb shell input tap 540 1200
sleep 2

# Scroll in restaurant
adb shell input swipe 540 1800 540 800 400
sleep 1.5

# Back
adb shell input keyevent 4
sleep 1.5

# Back to home
adb shell input keyevent 4
sleep 1.5

# Tap Groceries category (second icon)
adb shell input tap 150 400
sleep 2

# Scroll grocery stores
adb shell input swipe 540 1800 540 800 400
sleep 1.5

# Tap a store
adb shell input tap 540 900
sleep 2

# Back to home
adb shell input keyevent 4
sleep 1
adb shell input keyevent 4
sleep 1.5

# Tap Search button (center of banner)
adb shell input tap 300 560
sleep 1.5

# Type search
adb shell input text "souvlaki"
sleep 0.5
adb shell input keyevent 66
sleep 2

# Tap first result
adb shell input tap 540 800
sleep 2
