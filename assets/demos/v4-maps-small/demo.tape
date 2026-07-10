# famon v4 demo — Wolt, small font, param filtering, easter eggs
# Pre-req: adb connected, FA debug for com.wolt.android, Wolt open
# Usage: cd famon && vhs assets/demos/v4-maps-small/demo.tape

Output assets/demos/v4-maps-small/demo.gif
Output assets/demos/v4-maps-small/demo.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 24
Set Width 2560
Set Height 1440
Set Padding 40
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
Type "nohup /Users/mzamagias/Developer/Dart/famon/tool/demo-navigate.sh > /dev/null 2>&1 & disown %1 2>/dev/null"
Enter
Type "clear"
Enter
Sleep 200ms
Show

# Part 1: Unfiltered monitor — everything streaming
Type "famon monitor --platform android"
Sleep 600ms
Enter
Sleep 40000ms
Ctrl+C
Sleep 1500ms

# Part 2: Param filter — compact view, all events kept
Type "famon monitor --platform android --show-only-params screen_name,engagement_time_msec"
Sleep 600ms
Enter
Sleep 25000ms
Ctrl+C
Sleep 1500ms

# Part 3: Hide noisy auto-events
Type "famon monitor --platform android --hide user_engagement,session_start"
Sleep 600ms
Enter
Sleep 20000ms
Ctrl+C
Sleep 1000ms
