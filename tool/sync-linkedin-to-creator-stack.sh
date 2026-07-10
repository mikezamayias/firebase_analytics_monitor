#!/usr/bin/env bash
# Copy LinkedIn demo assets from famon repo → creator-stack/famon/linkedin/<project>/
set -euo pipefail

FAMON_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CREATOR_STACK="${CREATOR_STACK:-$HOME/Developer/creator-stack}"
SRC="$FAMON_DIR/assets/demos/linkedin"
DST="$CREATOR_STACK/famon/linkedin"

for project in shipping-monitor tooling-filters tooling-alias; do
  mkdir -p "$DST/$project"
  if [[ "$project" == "shipping-monitor" ]]; then
    # Flat layout in creator-stack: android-demo.mp4, ios-demo.mp4, …
    for platform in android ios; do
      for ext in mp4 gif; do
        if [[ -f "$SRC/$project/$platform/demo.$ext" ]]; then
          cp -f "$SRC/$project/$platform/demo.$ext" "$DST/$project/${platform}-demo.$ext"
        fi
      done
    done
  else
    for ext in mp4 gif; do
      if [[ -f "$SRC/$project/demo.$ext" ]]; then
        cp -f "$SRC/$project/demo.$ext" "$DST/$project/demo.$ext"
      fi
    done
  fi
done

echo "Synced to $DST"
ls -lh "$DST/shipping-monitor"/*.{mp4,gif} 2>/dev/null || true
ls -lh "$DST"/*/*.{mp4,gif} 2>/dev/null || true
