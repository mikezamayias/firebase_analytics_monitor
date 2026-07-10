#!/usr/bin/env bash
# Trim existing v6-showcase MP4s into LinkedIn-length clips (no adb required).
# Writes assets/demos/linkedin/<project>/demo.{mp4,gif}
#
set -euo pipefail

FAMON_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LINKEDIN_DIR="$FAMON_DIR/assets/demos/linkedin"

if ! command -v ffmpeg >/dev/null; then
  echo "ffmpeg required (brew install ffmpeg)" >&2
  exit 1
fi

trim() {
  local src="$1" start="$2" dur="$3" project="$4"
  local out_dir="$LINKEDIN_DIR/$project"
  mkdir -p "$out_dir"
  local dst="$out_dir/demo.mp4"
  echo "→ $dst (${start}s + ${dur}s from $(basename "$src"))"
  ffmpeg -y -hide_banner -loglevel error \
    -ss "$start" -i "$src" -t "$dur" \
    -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
    -movflags +faststart \
    "$dst"
  ffmpeg -y -hide_banner -loglevel error \
    -i "$dst" -vf "fps=15,scale=1024:-1:flags=lanczos" \
    "$out_dir/demo.gif"
  ffprobe -v error -show_entries format=duration,size -of default=noprint_wrappers=1 "$dst"
}

V6="$FAMON_DIR/assets/demos/v6-showcase"

# shipping-monitor: use assets/demo.mp4 (successful adb recording with live events).
# Do NOT use demo-60fps.mp4 — that run stalled on "No logs detected" + blinking cursor.
GOOD="$FAMON_DIR/assets/demo.mp4"
trim "$GOOD" 5.5 40 shipping-monitor
trim "$V6/02-event-filter/demo.mp4" 3.0 48 tooling-filters
trim "$V6/05-alias-workflow/demo.mp4" 11.0 50 tooling-alias

"$FAMON_DIR/tool/sync-linkedin-to-creator-stack.sh"

echo ""
echo "Done. Upload: $LINKEDIN_DIR/shipping-monitor/demo.mp4"
