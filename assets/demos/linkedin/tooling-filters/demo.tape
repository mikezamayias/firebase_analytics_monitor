# LinkedIn Tooling — event filter demo, ~45s
Output assets/demos/linkedin/tooling-filters/demo.gif
Output assets/demos/linkedin/tooling-filters/demo.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 32
Set Width 2048
Set Height 1536
Set Padding 90
Set Theme "GitHub Dark"
Set TypingSpeed 35ms
Set Framerate 30

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
Sleep 300ms
Show

Type "famon monitor --platform android --show-only purchase,search,login,sign_up"
Sleep 400ms
Enter
Sleep 45000ms
Ctrl+C
Sleep 800ms
