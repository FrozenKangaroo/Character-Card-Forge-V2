#!/usr/bin/env bash
set -euo pipefail

TARGET_BRANCH="main"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

AUTO_PROJECT_GODOT_STASH=""
AUTO_PROJECT_GODOT_STASH_LABEL=""
RELEASE_METADATA_PATHS=(
    "VERSION"
    "export_presets.cfg"
    "project.godot"
    "scripts/main.gd"
    "scripts/services/project_package_service.gd"
    "scripts/services/series_service.gd"
)

say() {
    printf '%s\n' "$*"
}

fail() {
    printf 'Update failed: %s\n' "$*" >&2
    exit 1
}

command -v git >/dev/null 2>&1 || fail "git is not installed or not available in PATH."
command -v python3 >/dev/null 2>&1 || fail "python3 is not installed or not available in PATH."

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "This copy is not a Git checkout. Clone the GitHub repository once, then run this script from that checkout."

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if ! git remote get-url origin >/dev/null 2>&1; then
    fail "This checkout has no 'origin' remote configured."
fi

current_branch="$(git branch --show-current)"
if [[ -z "$current_branch" ]]; then
    fail "The checkout is in detached-HEAD state. Switch back to '$TARGET_BRANCH' before updating."
fi

find_stash_ref_by_hash() {
    local target_hash="$1"
    git stash list --format='%gd %H' \
        | awk -v target="$target_hash" '$2 == target { print $1; exit }'
}

drop_auto_project_godot_stash() {
    if [[ -z "$AUTO_PROJECT_GODOT_STASH" ]]; then
        return 0
    fi
    local stash_ref
    stash_ref="$(find_stash_ref_by_hash "$AUTO_PROJECT_GODOT_STASH")"
    if [[ -n "$stash_ref" ]]; then
        git stash drop "$stash_ref" >/dev/null
    fi
    AUTO_PROJECT_GODOT_STASH=""
    AUTO_PROJECT_GODOT_STASH_LABEL=""
}

restore_auto_project_godot_stash() {
    if [[ -z "$AUTO_PROJECT_GODOT_STASH" ]]; then
        return 0
    fi

    if git stash apply "$AUTO_PROJECT_GODOT_STASH" >/dev/null; then
        drop_auto_project_godot_stash
        say "Restored the local project.godot change."
        return 0
    fi

    say "Could not automatically restore the preserved project.godot change."
    say "It is still safely stored in Git stash: $AUTO_PROJECT_GODOT_STASH_LABEL"
    return 1
}

restore_project_godot_on_failed_update() {
    local exit_code=$?
    if [[ "$exit_code" -ne 0 && -n "$AUTO_PROJECT_GODOT_STASH" ]]; then
        say "Update did not complete; restoring the local project.godot change..."
        restore_auto_project_godot_stash || true
    fi
    exit "$exit_code"
}

trap restore_project_godot_on_failed_update EXIT

is_only_unstaged_project_godot_change() {
    local changed_paths modified_paths

    # Never auto-handle staged work or untracked files. Those may be intentional
    # user changes and retain the updater's original fail-closed behaviour.
    git diff --cached --quiet || return 1
    [[ -z "$(git ls-files --others --exclude-standard)" ]] || return 1

    changed_paths="$(git diff --name-only)"
    modified_paths="$(git diff --name-only --diff-filter=M)"

    [[ "$changed_paths" == "project.godot" ]] || return 1
    [[ "$modified_paths" == "project.godot" ]] || return 1
    return 0
}

is_generated_release_metadata_bundle() {
    local expected_paths changed_paths candidate_version tmp_root path index_copy

    [[ -z "$(git ls-files --others --exclude-standard)" ]] || return 1

    expected_paths="$(printf '%s\n' "${RELEASE_METADATA_PATHS[@]}" | sort)"
    changed_paths="$(git diff --name-only HEAD -- | sort)"
    [[ "$changed_paths" == "$expected_paths" ]] || return 1

    candidate_version="$(tr -d '[:space:]' < VERSION)"
    [[ -n "$candidate_version" ]] || return 1

    tmp_root="$(mktemp -d)" || return 1
    mkdir -p "$tmp_root/tools"

    for path in "${RELEASE_METADATA_PATHS[@]}"; do
        mkdir -p "$tmp_root/$(dirname "$path")"
        if ! git show "HEAD:$path" > "$tmp_root/$path"; then
            rm -rf "$tmp_root"
            return 1
        fi
    done
    if ! git show HEAD:tools/set_version.py > "$tmp_root/tools/set_version.py"; then
        rm -rf "$tmp_root"
        return 1
    fi

    if ! python3 "$tmp_root/tools/set_version.py" "$candidate_version" >/dev/null 2>&1; then
        rm -rf "$tmp_root"
        return 1
    fi

    # The working-tree files must exactly equal what the checked-in version
    # synchroniser would generate from HEAD for VERSION's candidate version.
    for path in "${RELEASE_METADATA_PATHS[@]}"; do
        if ! cmp -s "$repo_root/$path" "$tmp_root/$path"; then
            rm -rf "$tmp_root"
            return 1
        fi

        # If a release attempt staged the generated files before failing, allow
        # that exact generated index state too. Any other staged content remains
        # fail-closed so intentional edits are never discarded automatically.
        if ! git diff --cached --quiet HEAD -- "$path"; then
            index_copy="$tmp_root/index-${path//\//_}"
            if ! git show ":$path" > "$index_copy" 2>/dev/null; then
                rm -rf "$tmp_root"
                return 1
            fi
            if ! cmp -s "$index_copy" "$tmp_root/$path"; then
                rm -rf "$tmp_root"
                return 1
            fi
        fi
    done

    rm -rf "$tmp_root"
    return 0
}

discard_generated_release_metadata_bundle() {
    local candidate_version
    candidate_version="$(tr -d '[:space:]' < VERSION)"
    say "Detected release metadata left by an interrupted release attempt (v${candidate_version})."
    say "The six generated version files exactly match tools/set_version.py output, so they can be reset safely before updating."
    git restore --source=HEAD --staged --worktree -- "${RELEASE_METADATA_PATHS[@]}" \
        || fail "Could not reset the interrupted release metadata bundle. Nothing was updated."
    say "Cleared the interrupted release metadata bundle."
}

dirty_status="$(git status --porcelain --untracked-files=normal)"
if [[ -n "$dirty_status" && "$current_branch" == "$TARGET_BRANCH" ]]; then
    if is_generated_release_metadata_bundle; then
        discard_generated_release_metadata_bundle
        dirty_status="$(git status --porcelain --untracked-files=normal)"
    fi
fi

if [[ -n "$dirty_status" ]]; then
    if [[ "$current_branch" == "$TARGET_BRANCH" ]] && is_only_unstaged_project_godot_change; then
        AUTO_PROJECT_GODOT_STASH_LABEL="ccf-update: preserve local project.godot"
        say "Only project.godot has a local unstaged change. Preserving it automatically for this update..."
        git stash push -m "$AUTO_PROJECT_GODOT_STASH_LABEL" -- project.godot >/dev/null \
            || fail "Could not temporarily preserve project.godot. Nothing was updated."
        AUTO_PROJECT_GODOT_STASH="$(git rev-parse refs/stash)"
    else
        say "Local changes were found, so nothing was updated:"
        git status --short
        fail "Commit, stash, or remove the local changes, then run update.sh again."
    fi
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

if [[ -n "$AUTO_PROJECT_GODOT_STASH" ]]; then
    if git diff --quiet "$before" "$after" -- project.godot; then
        say "The update did not change project.godot upstream; restoring your local copy..."
        restore_auto_project_godot_stash \
            || fail "The update succeeded, but the preserved project.godot change could not be restored automatically."
    else
        say "project.godot changed upstream in this update, so the older local copy was not reapplied over it."
        say "Your previous local project.godot is still safely stored in Git stash: $AUTO_PROJECT_GODOT_STASH_LABEL"
        say "Review it later with: git stash show -p"
        # Leave the stash intact intentionally; the successful update should use
        # the new authoritative project.godot rather than silently reapply an old one.
        AUTO_PROJECT_GODOT_STASH=""
        AUTO_PROJECT_GODOT_STASH_LABEL=""
    fi
fi

if [[ "$before" == "$after" ]]; then
    say "Already up to date."
else
    say "Updated successfully."
    say "Previous commit: ${before:0:12}"
    say "Current commit:  ${after:0:12}"
fi

say "Development checkout is ready: $repo_root"
