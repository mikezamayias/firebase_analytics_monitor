#!/usr/bin/env bash
#
# Release helper. PR-based: opens (or reuses) a `dev → main` pull
# request, waits for the required CI checks to pass, merges the PR
# with the "merge" method so dev's commits become ancestors of main,
# then tags the resulting merge commit on main. The tag push triggers
# .github/workflows/publish.yaml, which publishes the corresponding
# package to pub.dev.
#
# Per-package versioning (decoupled since 2026-05-24):
#
#   tool/release.sh famon       1.5.1   → tag famon-v1.5.1
#   tool/release.sh famon_core  1.5.1   → tag famon_core-v1.5.1
#
# Tag-format migration: legacy `v<version>` tags (pre-decoupling) stay
# in history but are no longer produced. The publish workflow matches
# `famon-v*` and `famon_core-v*` from this release onward.
#
# Why a PR and not a direct push?
#
# The "Protect main" repository ruleset requires a pull request, with
# the same required status checks every regular contribution must
# pass. Direct pushes are rejected for everyone, including admins —
# the release flow earns its merge the same way every other change
# does. Trusted-publishing OIDC still authenticates the publish jobs
# triggered by the tag push.
#
# Prerequisites:
# - `gh` CLI is installed and authenticated for this repository.
# - The release-prep PR (`chore(release): <pkg> X.Y.Z`) has already
#   merged into `dev` so the version sources and changelog sit at the
#   tip of `dev`.

set -euo pipefail

PACKAGE="${1:-}"
VERSION="${2:-}"

if [[ -z "$PACKAGE" || -z "$VERSION" ]]; then
  echo "Usage: $0 <famon|famon_core> <version>" >&2
  echo "Example: $0 famon 1.5.1" >&2
  exit 1
fi

case "$PACKAGE" in
  famon|famon_core) ;;
  *) echo "Unknown package: $PACKAGE (expected: famon | famon_core)" >&2; exit 1 ;;
esac

# Defensive: lock VERSION to the SemVer shape that update_version.dart
# already enforces. All current callers route through update_version.dart
# first, but validating at the release-script boundary keeps shell-metachar
# inputs (paths, accidental quotes, copy/paste typos) from reaching git tag
# / gh pr create where they'd produce surprising tag names or PR bodies.
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid VERSION format: $VERSION" >&2
  echo "Expected SemVer 2.0: x.y.z (e.g. 1.5.1, 1.5.1-beta.1, 1.5.1-rc-1, 1.5.1+build.42)" >&2
  exit 1
fi

TAG="${PACKAGE}-v${VERSION}"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree not clean. Commit or stash changes before releasing." >&2
  exit 1
fi

git fetch origin \
  +refs/heads/dev:refs/remotes/origin/dev \
  +refs/heads/main:refs/remotes/origin/main \
  --tags
git branch --track dev origin/dev 2>/dev/null || true
git branch --track main origin/main 2>/dev/null || true

if ! git show-ref --verify --quiet refs/heads/dev; then
  echo "Branch 'dev' not found. Ensure it exists locally." >&2
  exit 1
fi

if ! git show-ref --verify --quiet refs/heads/main; then
  echo "Branch 'main' not found. Ensure it exists locally." >&2
  exit 1
fi

git checkout dev
# Use `git merge` against the already-fetched ref rather than `git pull`.
# `git pull --ff-only origin dev` fails with "Cannot fast-forward to multiple
# branches" when the prior multi-ref fetch (dev + main + --tags) leaves
# FETCH_HEAD with several merge candidates and pull tries to FF all of them.
if ! git merge --ff-only origin/dev; then
  echo "Failed to fast-forward local 'dev' to origin/dev. Reconcile and re-run." >&2
  exit 1
fi
if [[ "$(git rev-parse dev)" != "$(git rev-parse origin/dev)" ]]; then
  echo "Local 'dev' is not exactly at origin/dev. Reconcile/push dev before releasing." >&2
  exit 1
fi

# Per-package preflight: only verify sources that the package actually owns.
case "$PACKAGE" in
  famon)
    if ! grep -qF "version: $VERSION" pubspec.yaml; then
      echo "pubspec.yaml version is not set to $VERSION" >&2
      echo "Run: dart run tool/update_version.dart --package famon $VERSION" >&2
      exit 1
    fi
    if ! grep -qF "const packageVersion = '$VERSION';" lib/src/version.dart; then
      echo "lib/src/version.dart does not contain version $VERSION" >&2
      echo "Run: dart run tool/update_version.dart --package famon $VERSION" >&2
      exit 1
    fi
    if ! grep -qF "## [$VERSION]" CHANGELOG.md; then
      echo "CHANGELOG.md does not contain a section for $VERSION" >&2
      exit 1
    fi
    ;;
  famon_core)
    if ! grep -qF "version: $VERSION" packages/famon_core/pubspec.yaml; then
      echo "packages/famon_core/pubspec.yaml version is not set to $VERSION" >&2
      echo "Run: dart run tool/update_version.dart --package famon_core $VERSION" >&2
      exit 1
    fi
    if ! grep -qF "## [$VERSION]" packages/famon_core/CHANGELOG.md; then
      echo "packages/famon_core/CHANGELOG.md does not contain a section for $VERSION" >&2
      exit 1
    fi
    ;;
esac

# Refresh origin/main right before the SHA compare so the "dev == main"
# shortcut can't be tricked by a fetch that happened minutes earlier.
git fetch origin +refs/heads/main:refs/remotes/origin/main

# Re-use an existing open release PR if one is already there.
PR_NUMBER="$(gh pr list \
  --base main --head dev \
  --state open --json number --jq '.[0].number // empty')"

# Skip PR creation if dev == main (e.g. a prior package release already
# merged dev → main and no new commits arrived since). Tag directly.
DEV_SHA="$(git rev-parse dev)"
MAIN_SHA="$(git rev-parse origin/main)"

if [[ -z "$PR_NUMBER" && "$DEV_SHA" == "$MAIN_SHA" ]]; then
  echo "dev is already at main ($DEV_SHA). Skipping PR — tagging directly."
  git checkout main
  if ! git merge --ff-only origin/main; then
    echo "Failed to fast-forward local 'main' to origin/main before direct tag." >&2
    exit 1
  fi
  git tag -a "$TAG" -m "Release $PACKAGE $VERSION"
  git push origin "$TAG"
  echo
  echo "Tagged $TAG at $(git rev-parse main)."
  echo "Tag pushed. .github/workflows/publish.yaml will publish $PACKAGE."
  exit 0
fi

if [[ -z "$PR_NUMBER" ]]; then
  if ! PR_URL="$(gh pr create \
    --base main --head dev \
    --title "chore(release): $PACKAGE $VERSION → main" \
    --body $'Automated release-sync PR opened by `tool/release.sh '"$PACKAGE $VERSION"$'`.\n\nMerges `dev` into `main` so the next `'"$TAG"$'` tag points at the resulting merge commit. The tag push triggers `.github/workflows/publish.yaml`, which publishes `'"$PACKAGE"$'` to pub.dev via OIDC trusted publishing.\n\nUse **Create a merge commit** when merging this PR — `tool/release.sh` requests it explicitly. Squash would lose dev\'s commit ancestry on main and reintroduce the divergence this PR-based flow is designed to fix.' 2>&1)"; then
    echo "gh pr create failed:" >&2
    echo "$PR_URL" >&2
    exit 1
  fi
  PR_NUMBER="${PR_URL##*/}"
fi

echo "Release PR: #$PR_NUMBER"
echo "Waiting for required CI checks…"

if ! gh pr checks "$PR_NUMBER" --watch --required; then
  echo "Required checks did not pass for PR #$PR_NUMBER." >&2
  exit 1
fi

STATE="$(gh pr view "$PR_NUMBER" \
  --json mergeStateStatus,mergeable \
  --jq '"\(.mergeStateStatus)/\(.mergeable)"')"
# UNSTABLE means a non-required check failed. The required checks were
# already waited on above, so a stray status from a third-party app must
# not block the release.
if [[ "$STATE" != "CLEAN/MERGEABLE" && "$STATE" != "UNSTABLE/MERGEABLE" ]]; then
  echo "PR #$PR_NUMBER is not mergeable: $STATE" >&2
  echo "Resolve threads or conflicts on the PR, then re-run this script." >&2
  exit 1
fi

if ! gh pr merge "$PR_NUMBER" --merge; then
  echo "gh pr merge failed for PR #$PR_NUMBER." >&2
  exit 1
fi

git checkout main
git fetch origin +refs/heads/main:refs/remotes/origin/main
if ! git merge --ff-only origin/main; then
  echo "Failed to fast-forward local 'main' to origin/main after PR merge. Tag aborted." >&2
  exit 1
fi

# Post-merge sanity: confirm the version the package owns actually reached main.
case "$PACKAGE" in
  famon)
    if ! grep -qF "version: $VERSION" pubspec.yaml; then
      echo "After merge, pubspec.yaml on main does not say version $VERSION." >&2
      echo "Inspect the merged result and re-run with a fresh tag if needed." >&2
      exit 1
    fi
    ;;
  famon_core)
    if ! grep -qF "version: $VERSION" packages/famon_core/pubspec.yaml; then
      echo "After merge, packages/famon_core/pubspec.yaml on main does not say version $VERSION." >&2
      exit 1
    fi
    ;;
esac

git tag -a "$TAG" -m "Release $PACKAGE $VERSION"
git push origin "$TAG"

echo
echo "Tagged $TAG at $(git rev-parse main)."
echo "Tag pushed. .github/workflows/publish.yaml will publish $PACKAGE."
