# 05 — Alias workflow: QA ticket alias + pipe to log file
Output assets/demos/v6-showcase/05-alias-workflow/demo.gif
Output assets/demos/v6-showcase/05-alias-workflow/demo.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 32
Set Width 2048
Set Height 1536
Set Padding 90
Set Theme "GitHub Dark"
Set TypingSpeed 40ms
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
Sleep 200ms
Show

# Step 1: Set up the QA alias
Type "alias famon-qa24274='famon monitor --platform android --show-only purchase,add_to_cart,view_cart,begin_checkout,add_payment_info'"
Sleep 300ms
Enter
Sleep 1500ms

# Step 2: Run it
Type "famon-qa24274"
Sleep 600ms
Enter
Sleep 120000ms
Ctrl+C
Sleep 1000ms
