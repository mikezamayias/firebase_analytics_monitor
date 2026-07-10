# famon demo tape
# Renders assets/demo.gif and assets/demo.mp4
# Usage: vhs assets/demo.tape (run from famon repo root)

Output assets/demo.gif
Output assets/demo.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 48
Set Width 2560
Set Height 1440
Set Padding 80
Set Theme "TokyoNight"
Set TypingSpeed 45ms
Set Framerate 60
Set PlaybackSpeed 1.0

# Pre-warm: alias famon to the AOT binary + custom PS1 + clear.
# Hide suppresses keystrokes/output but still executes them.
Hide
Type "export PS1='$ '"
Enter
Type "alias famon=/Users/mzamagias/Developer/Dart/famon/build/famon"
Enter
Type "clear"
Enter
Sleep 200ms
Show

# 1. Version banner — anchors the "shipped v1.5.1" story
Type "famon --version"
Sleep 800ms
Enter
Sleep 3000ms
Ctrl+L

# 2. Database snapshot — shows the unified store across Android + iOS
Type "famon database info"
Sleep 800ms
Enter
Sleep 6000ms
Ctrl+L

# 3. Stats panel — colored emoji output, top events, low-frequency hints
Type "famon filter --stats-only"
Sleep 800ms
Enter
Sleep 8000ms
Ctrl+L

# 4. Filter capability — same DB, different lens
Type "famon filter --stats-only --min-frequency=2"
Sleep 800ms
Enter
Sleep 7000ms

# Closing dwell so the last frame is readable
Sleep 3500ms
