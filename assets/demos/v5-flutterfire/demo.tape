# famon v5 demo — FlutterFire example, 2s-paced GA4 events, filtering showcase
# Pre-req: FlutterFire analytics example installed (with 2s delays), adb connected
# Usage: cd famon && vhs assets/demos/v5-flutterfire/demo.tape

Output assets/demos/v5-flutterfire/demo.gif
Output assets/demos/v5-flutterfire/demo.mp4

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
Type "nohup /Users/mzamagias/Developer/Dart/famon/tool/demo-navigate-flutterfire.sh > /dev/null 2>&1 & disown %1 2>/dev/null"
Enter
Type "clear"
Enter
Sleep 200ms
Show

# Part 1: Unfiltered — events arrive one at a time, readable pace
Type "famon monitor --platform android"
Sleep 600ms
Enter
Sleep 45000ms
Ctrl+C
Sleep 1500ms

# Part 2: Param filter — same events, only key params shown
Type "famon monitor --platform android --show-only-params currency,value,search_term"
Sleep 600ms
Enter
Sleep 35000ms
Ctrl+C
Sleep 1500ms

# Part 3: Hide auto-events, show only app events
Type "famon monitor --platform android --hide session_start,first_open"
Sleep 600ms
Enter
Sleep 35000ms
Ctrl+C
Sleep 1000ms
