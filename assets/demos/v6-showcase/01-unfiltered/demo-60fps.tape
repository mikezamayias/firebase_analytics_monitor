# 01 — Unfiltered: raw event stream (60fps test)
Output assets/demos/v6-showcase/01-unfiltered/demo-60fps.gif
Output assets/demos/v6-showcase/01-unfiltered/demo-60fps.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 32
Set Width 2048
Set Height 1536
Set Padding 90
Set Theme "GitHub Dark"
Set TypingSpeed 40ms
Set Framerate 60

Env LANG en_US.UTF-8
Env LC_ALL en_US.UTF-8

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

Type "famon monitor --platform android"
Sleep 600ms
Enter
Sleep 120000ms
Ctrl+C
Sleep 1000ms
