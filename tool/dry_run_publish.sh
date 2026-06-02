#!/usr/bin/env bash
# Dry-run publish for both packages. famon_core is copied to a temp dir first
# because the root .pubignore excludes packages/ (CI does the same in
# pr_publish_check.yaml).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/famon_core_publish_$$"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

cp -R "$ROOT/packages/famon_core" "$TMP"
(
  cd "$TMP"
  dart pub get
  dart pub publish --dry-run
)

(
  cd "$ROOT"
  dart pub get
  dart pub publish --dry-run
)
