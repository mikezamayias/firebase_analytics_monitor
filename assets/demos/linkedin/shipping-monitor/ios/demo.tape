# LinkedIn — iOS Simulator shipping monitor (~35s live events; full button tour + tabs)
# Capability: --show-only while tapping stock FlutterFire buttons + tabs (config APIs often silent)
Output assets/demos/linkedin/shipping-monitor/ios/demo.gif
Output assets/demos/linkedin/shipping-monitor/ios/demo.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 32
Set Width 2048
Set Height 1536
Set Padding 48
Set Theme "GitHub Dark"
Set TypingSpeed 35ms
Set Framerate 60

Env LANG en_US.UTF-8
Env LC_ALL en_US.UTF-8

Hide
Type "export PS1='$ '"
Enter
Type "alias famon=/Users/mzamagias/Developer/Dart/famon/build/famon"
Enter
Type "# iOS: logs cleared via prep-flutterfire-demo.sh"
Enter
Type "nohup env FAMON_DEMO_PLATFORM=ios-simulator FAMON_DEMO_TAP_GAP=0.5 /Users/mzamagias/Developer/Dart/famon/tool/demo-navigate-flutterfire-button-tour.sh > /dev/null 2>&1 & disown %1 2>/dev/null"
Enter
Type "clear"
Enter
Sleep 300ms
Show

Type "famon monitor --platform ios-simulator --show-only test_event,login,purchase,search,sign_up,screen_view,add_to_cart"
Sleep 400ms
Enter
Sleep 53000ms
Ctrl+C
Sleep 800ms
