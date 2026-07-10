# famon live monitor demo — Wolt + flags showcase
# Pre-req: adb device connected, FA debug enabled for com.wolt.android
# Usage: vhs assets/demo-live.tape (from famon repo root)

Output assets/demo.gif
Output assets/demo.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 36
Set Width 2560
Set Height 1440
Set Padding 60
Set Theme "TokyoNight"
Set TypingSpeed 45ms
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

# Part 1: Live monitor
Type "famon monitor --platform android"
Sleep 800ms
Enter
Sleep 60000ms

# Ctrl+C to stop monitor
Ctrl+C
Sleep 2000ms

# Part 2: Show accumulated stats
Type "famon filter --stats-only"
Sleep 800ms
Enter
Sleep 8000ms

# Part 3: Show filtered view
Type "famon filter --stats-only --show-only screen_view"
Sleep 800ms
Enter
Sleep 6000ms
