# LinkedIn Tooling — QA alias workflow, ~50s (monitor portion only after alias)
Output assets/demos/linkedin/tooling-alias/demo.gif
Output assets/demos/linkedin/tooling-alias/demo.mp4

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
Type "clear"
Enter
Sleep 300ms
Show

Type "alias famon-qa='famon monitor --platform android --show-only purchase,add_to_cart,view_cart,begin_checkout,add_payment_info'"
Sleep 300ms
Enter
Sleep 1200ms
Type "famon-qa"
Sleep 400ms
Enter
Sleep 50000ms
Ctrl+C
Sleep 800ms
