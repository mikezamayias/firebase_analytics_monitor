# Short proof render — FontSize 50 (not for publish)
Output assets/demos/linkedin/shipping-monitor/ios/demo-proof-50.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 50
Set Width 2048
Set Height 1536
Set Padding 48
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
Type "# iOS: logs cleared via prep-flutterfire-demo.sh"
Enter
Type "nohup env FAMON_DEMO_PLATFORM=ios-simulator /Users/mzamagias/Developer/Dart/famon/tool/demo-navigate-flutterfire.sh > /dev/null 2>&1 & disown %1 2>/dev/null"
Enter
Type "clear"
Enter
Sleep 300ms
Show

Type "famon monitor --platform ios-simulator"
Sleep 400ms
Enter
Sleep 10000ms
Ctrl+C
Sleep 800ms
