#!/usr/bin/env bash
# Push the current tree of the `personal` branch to the CI repo as a single
# snapshot commit.
#
# Why: this clone carries Saber's full ~1.1 GB git history, but the personal
# GitHub repo only needs to *build* the current code. Each run appends one
# small commit on top of the previous snapshot, so GitHub history stays linear
# and light while the local clone keeps upstream history for merges.
#
# Usage: scripts/push-ci.sh            (writes branch "ci" onto origin/main)
# Written by Hermes Agent.
set -euo pipefail

cd "$(dirname "$0")/.."

SRC_BRANCH="${SRC_BRANCH:-personal}"
DST_REF="${DST_REF:-refs/heads/main}"
CI_BRANCH="${CI_BRANCH:-ci}"

SRC_COMMIT=$(git rev-parse "$SRC_BRANCH")
TREE=$(git rev-parse "$SRC_BRANCH^{tree}")

PARENT_ARGS=()
if git rev-parse --verify -q "refs/heads/$CI_BRANCH" >/dev/null; then
  PARENT_ARGS=(-p "refs/heads/$CI_BRANCH")
fi

MSG=$(printf 'Morisnote snapshot %s\n\nSource: %s (%s)\nDibuat oleh Hermes Agent.\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SRC_BRANCH" "${SRC_COMMIT:0:12}")

NEW_COMMIT=$(git commit-tree "$TREE" "${PARENT_ARGS[@]}" -m "$MSG")
git update-ref "refs/heads/$CI_BRANCH" "$NEW_COMMIT"

git push -f origin "$CI_BRANCH:$DST_REF"
echo "pushed $CI_BRANCH -> origin $DST_REF ($NEW_COMMIT)"
