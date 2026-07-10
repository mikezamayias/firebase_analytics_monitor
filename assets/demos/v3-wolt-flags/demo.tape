# famon v3 demo — filtering showcase with live Wolt events
# Theme: Dracula+ for high contrast
# Pre-req: adb device connected, FA debug for com.wolt.android, Wolt open
# Usage: cd famon && vhs assets/demos/v3-wolt-flags/demo.tape

Output assets/demos/v3-wolt-flags/demo.gif
Output assets/demos/v3-wolt-flags/demo.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 32
Set Width 2560
Set Height 1440
Set Padding 50
Set Theme "Dracula+"
Set TypingSpeed 40ms
Set Framerate 60
Set PlaybackSpeed 1.0

Hide
Type "export PS1='$ '"
Enter
Type "alias famon=/Users/mzamagias/Developer/Dart/famon/build/famon"
Enter
Type "adb logcat -c"
Enter
Type "famon database clear --confirm 2>/dev/null; true"
Enter
Type "nohup /Users/mzamagias/Developer/Dart/famon/tool/demo-navigate.sh > /dev/null 2>&1 & disown %1 2>/dev/null"
Enter
Type "clear"
Enter
Sleep 200ms
Show

# Part 1: Unfiltered monitor — show everything streaming
Type "famon monitor --platform android"
Sleep 600ms
Enter
Sleep 30000ms
Ctrl+C
Sleep 1500ms

# Part 2: Filtered monitor — only screen_view events
Type "famon monitor --platform android --show-only screen_view"
Sleep 600ms
Enter
Sleep 20000ms
Ctrl+C
Sleep 1500ms

# Part 3: Param filter — show only key params
Type "famon monitor --platform android --show-only-params screen_name,engagement_time_msec"
Sleep 600ms
Enter
Sleep 15000ms
Ctrl+C
Sleep 1500ms

# Part 4: Stats panel from accumulated live data
Type "famon filter --stats-only"
Sleep 600ms
Enter
Sleep 8000ms
