#!/usr/bin/env bash
# Letterbox Android shipping clip to match iOS (2048x1536, 4:3) for LinkedIn stitching.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=demo-config.sh
source "$SCRIPT_DIR/demo-config.sh"

ANDROID_MP4="$FAMON_DIR/assets/demos/linkedin/shipping-monitor/android/demo.mp4"
IOS_MP4="$FAMON_DIR/assets/demos/linkedin/shipping-monitor/ios/demo.mp4"
TARGET_W=2048
TARGET_H=1536
PAD_COLOR="${SHIPPING_PAD_COLOR:-0x0f1115}"

if [[ ! -f "$ANDROID_MP4" ]]; then
  echo "Missing $ANDROID_MP4" >&2
  exit 1
fi

w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$ANDROID_MP4")
h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$ANDROID_MP4")
if [[ "$w" == "$TARGET_W" && "$h" == "$TARGET_H" ]]; then
  echo "Android clip already ${TARGET_W}x${TARGET_H}"
  exit 0
fi

backup="${ANDROID_MP4%.mp4}_16x9.original.mp4"
if [[ ! -f "$backup" ]]; then
  cp -f "$ANDROID_MP4" "$backup"
  echo "Backed up 16:9 original → $backup"
fi

tmp="${ANDROID_MP4}.tmp.mp4"
ffmpeg -y -hide_banner -loglevel error -i "$ANDROID_MP4" \
  -vf "scale=${TARGET_W}:-2:flags=lanczos,pad=${TARGET_W}:${TARGET_H}:(ow-iw)/2:(oh-ih)/2:color=${PAD_COLOR},colorbalance=bs=0.04:bm=0.015,format=yuv420p" \
  -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p -r 25 -movflags +faststart -an \
  "$tmp"
mv -f "$tmp" "$ANDROID_MP4"

ffmpeg -y -hide_banner -loglevel error -i "$ANDROID_MP4" \
  -vf "fps=12,scale=1024:-2:flags=lanczos" -loop 0 \
  "${ANDROID_MP4%.mp4}.gif"

if [[ -f "$IOS_MP4" ]]; then
  iw=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$IOS_MP4")
  ih=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$IOS_MP4")
  echo "Normalized Android → ${TARGET_W}x${TARGET_H} (iOS reference: ${iw}x${ih})"
else
  echo "Normalized Android → ${TARGET_W}x${TARGET_H}"
fi
