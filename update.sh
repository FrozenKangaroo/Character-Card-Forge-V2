#!/usr/bin/env bash
set -euo pipefail

TARGET_BRANCH="main"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

say() {
    printf '%s\n' "$*"
}

fail() {
    printf 'Update failed: %s\n' "$*" >&2
    exit 1
}

command -v git >/dev/null 2>&1 || fail "git is not installed or not available in PATH."

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "This copy is not a Git checkout. Clone the GitHub repository once, then run this script from that checkout."

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if ! git remote get-url origin >/dev/null 2>&1; then
    fail "This checkout has no 'origin' remote configured."
fi

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    say "Local changes were found, so nothing was updated:"
    git status --short
    fail "Commit, stash, or remove the local changes, then run update.sh again."
fi

current_branch="$(git branch --show-current)"
if [[ -z "$current_branch" ]]; then
    fail "The checkout is in detached-HEAD state. Switch back to '$TARGET_BRANCH' before updating."
fi

if [[ "$current_branch" != "$TARGET_BRANCH" ]]; then
    say "Switching from '$current_branch' to '$TARGET_BRANCH'..."
    git switch "$TARGET_BRANCH" \
        || fail "Could not switch to '$TARGET_BRANCH'."
fi

say "Fetching latest Character Card Forge development source from origin/$TARGET_BRANCH..."
git fetch --prune origin "$TARGET_BRANCH"

before="$(git rev-parse HEAD)"

# Fast-forward only. This protects local commits instead of silently overwriting them.
if ! git merge --ff-only "origin/$TARGET_BRANCH"; then
    fail "Local '$TARGET_BRANCH' has diverged from origin/$TARGET_BRANCH. Resolve it manually; no files were overwritten by this script."
fi

after="$(git rev-parse HEAD)"

if [[ "$before" == "$after" ]]; then
    say "Already up to date."
else
    say "Updated successfully."
    say "Previous commit: ${before:0:12}"
    say "Current commit:  ${after:0:12}"
fi

say "Development checkout is ready: $repo_root"
