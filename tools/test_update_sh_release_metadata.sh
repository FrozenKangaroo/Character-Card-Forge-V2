#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
UPDATER="$REPO_ROOT/update.sh"
VERSION_TOOL="$REPO_ROOT/tools/set_version.py"
RELEASE_PATHS=(
    "VERSION"
    "export_presets.cfg"
    "project.godot"
    "scripts/main.gd"
    "scripts/services/project_package_service.gd"
    "scripts/services/series_service.gd"
)

fail() {
    printf 'Release-metadata updater regression failed: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]] || fail "Expected output to contain: $needle"
}

bash -n "$UPDATER" || fail "update.sh must pass bash -n."

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
origin="$tmp_root/origin.git"
seed="$tmp_root/seed"
client="$tmp_root/client"

git init --bare "$origin" >/dev/null
git -C "$origin" symbolic-ref HEAD refs/heads/main

git init -b main "$seed" >/dev/null
git -C "$seed" config user.name "CCF Release Metadata Regression"
git -C "$seed" config user.email "ccf-release-metadata@example.invalid"

cp "$UPDATER" "$seed/update.sh"
mkdir -p "$seed/tools" "$seed/scripts/services"
cp "$VERSION_TOOL" "$seed/tools/set_version.py"
for path in "${RELEASE_PATHS[@]}"; do
    mkdir -p "$seed/$(dirname "$path")"
    cp "$REPO_ROOT/$path" "$seed/$path"
done
printf 'payload-v1\n' > "$seed/payload.txt"

git -C "$seed" add .
git -C "$seed" commit -m "seed" >/dev/null
git -C "$seed" remote add origin "$origin"
git -C "$seed" push -u origin main >/dev/null

git clone -b main "$origin" "$client" >/dev/null 2>&1
git -C "$client" config user.name "CCF Release Metadata Regression Client"
git -C "$client" config user.email "ccf-release-metadata-client@example.invalid"

baseline_version="$(tr -d '[:space:]' < "$client/VERSION")"
release_candidate="0.15.40"
if [[ "$baseline_version" == "$release_candidate" ]]; then
    release_candidate="0.15.41"
fi

# Case 1: an interrupted release leaves the exact six-file set_version.py bundle
# unstaged. The updater may discard only this reproducible generated state and
# then fast-forward normally.
(cd "$client" && python3 tools/set_version.py "$release_candidate" >/dev/null)
printf 'payload-v2\n' > "$seed/payload.txt"
git -C "$seed" add payload.txt
git -C "$seed" commit -m "remote payload update 2" >/dev/null
git -C "$seed" push origin main >/dev/null

first_output="$(cd "$client" && bash update.sh 2>&1)" || {
    printf '%s\n' "$first_output" >&2
    fail "Updater should recover an exact unstaged set_version.py bundle."
}
assert_contains "$first_output" "Detected release metadata left by an interrupted release attempt"
assert_contains "$first_output" "Cleared the interrupted release metadata bundle."
[[ "$(cat "$client/payload.txt")" == "payload-v2" ]] \
    || fail "Remote update was not fast-forwarded after metadata recovery."
[[ "$(tr -d '[:space:]' < "$client/VERSION")" == "$baseline_version" ]] \
    || fail "Interrupted candidate release metadata should be reset to authoritative HEAD metadata."
[[ -z "$(git -C "$client" status --porcelain)" ]] \
    || fail "Checkout should be clean after recovering the generated metadata bundle."

# Case 2: release.sh may have staged the generated bundle before a later failure.
# The updater may recover it only when the index contains the same generated
# content and no unrelated staged edits.
(cd "$client" && python3 tools/set_version.py "$release_candidate" >/dev/null)
git -C "$client" add "${RELEASE_PATHS[@]}"
printf 'payload-v3\n' > "$seed/payload.txt"
git -C "$seed" add payload.txt
git -C "$seed" commit -m "remote payload update 3" >/dev/null
git -C "$seed" push origin main >/dev/null

second_output="$(cd "$client" && bash update.sh 2>&1)" || {
    printf '%s\n' "$second_output" >&2
    fail "Updater should recover an exact staged set_version.py bundle."
}
assert_contains "$second_output" "Detected release metadata left by an interrupted release attempt"
[[ "$(cat "$client/payload.txt")" == "payload-v3" ]] \
    || fail "Remote update was not fast-forwarded after staged metadata recovery."
[[ -z "$(git -C "$client" status --porcelain)" ]] \
    || fail "Checkout should be clean after staged metadata recovery."

# Case 3: if even one generated metadata file contains extra manual content, the
# bundle is no longer reproducible set_version.py output and must stay fail-closed.
(cd "$client" && python3 tools/set_version.py "$release_candidate" >/dev/null)
printf '\n# intentional local edit\n' >> "$client/scripts/main.gd"
set +e
blocked_output="$(cd "$client" && bash update.sh 2>&1)"
blocked_status=$?
set -e
[[ "$blocked_status" -ne 0 ]] || fail "Updater must refuse a modified release metadata bundle."
assert_contains "$blocked_output" "Local changes were found, so nothing was updated"
grep -q '^# intentional local edit$' "$client/scripts/main.gd" \
    || fail "Blocked recovery must preserve manual edits inside metadata files."
git -C "$client" restore --source=HEAD --staged --worktree -- "${RELEASE_PATHS[@]}"

# Case 4: exact generated metadata plus an unrelated tracked edit is not safe to
# auto-clean because the working copy contains real local work.
(cd "$client" && python3 tools/set_version.py "$release_candidate" >/dev/null)
printf 'intentional payload edit\n' >> "$client/payload.txt"
set +e
extra_output="$(cd "$client" && bash update.sh 2>&1)"
extra_status=$?
set -e
[[ "$extra_status" -ne 0 ]] || fail "Updater must refuse generated metadata when unrelated local work is present."
assert_contains "$extra_output" "Commit, stash, or remove the local changes"
grep -q '^intentional payload edit$' "$client/payload.txt" \
    || fail "Updater must not overwrite unrelated local work."

printf 'v0.15.40-hotfix9 interrupted release metadata updater regression passed\n'
