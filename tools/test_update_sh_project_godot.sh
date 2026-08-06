#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATER="$REPO_ROOT/update.sh"

fail() {
    printf 'Updater regression failed: %s\n' "$*" >&2
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

# Build a tiny remote repository containing the real updater under test.
git init --bare "$origin" >/dev/null
git -C "$origin" symbolic-ref HEAD refs/heads/main

git init -b main "$seed" >/dev/null
git -C "$seed" config user.name "CCF Updater Regression"
git -C "$seed" config user.email "ccf-updater-regression@example.invalid"
cp "$UPDATER" "$seed/update.sh"
printf 'remote-project-v1\n' > "$seed/project.godot"
printf 'payload-v1\n' > "$seed/payload.txt"
git -C "$seed" add update.sh project.godot payload.txt
git -C "$seed" commit -m "seed" >/dev/null
git -C "$seed" remote add origin "$origin"
git -C "$seed" push -u origin main >/dev/null

git clone -b main "$origin" "$client" >/dev/null 2>&1
git -C "$client" config user.name "CCF Updater Regression Client"
git -C "$client" config user.email "ccf-updater-client@example.invalid"

# Case 1: project.godot is the only local modification. The updater should
# preserve it automatically, fast-forward main, then restore the local copy.
printf 'local-godot-drift\n' >> "$client/project.godot"
printf 'payload-v2\n' > "$seed/payload.txt"
git -C "$seed" add payload.txt
git -C "$seed" commit -m "remote payload update" >/dev/null
git -C "$seed" push origin main >/dev/null

first_output="$(cd "$client" && bash update.sh 2>&1)" || {
    printf '%s\n' "$first_output" >&2
    fail "Updater should accept project.godot as the only local unstaged modification."
}
assert_contains "$first_output" "Preserving it automatically"
assert_contains "$first_output" "Restored the local project.godot change."
[[ "$(cat "$client/payload.txt")" == "payload-v2" ]] \
    || fail "Remote payload update was not fast-forwarded."
grep -q '^local-godot-drift$' "$client/project.godot" \
    || fail "Local project.godot change was not restored."
[[ "$(git -C "$client" status --porcelain)" == " M project.godot" ]] \
    || fail "Only the restored project.godot modification should remain after updating."

# Case 2: running again while already current must also work without manual
# stash/restore commands and must keep the local project.godot drift.
second_output="$(cd "$client" && bash update.sh 2>&1)" || {
    printf '%s\n' "$second_output" >&2
    fail "Repeated update with only project.godot dirty should succeed."
}
assert_contains "$second_output" "Already up to date."
grep -q '^local-godot-drift$' "$client/project.godot" \
    || fail "Repeated update lost the preserved project.godot change."

# Case 3: any additional tracked/untracked/staged work must retain the original
# fail-closed behaviour instead of being silently stashed or overwritten.
printf 'intentional-local-work\n' >> "$client/payload.txt"
set +e
blocked_output="$(cd "$client" && bash update.sh 2>&1)"
blocked_status=$?
set -e
[[ "$blocked_status" -ne 0 ]] || fail "Updater must refuse unrelated local work."
assert_contains "$blocked_output" "Local changes were found, so nothing was updated"
assert_contains "$blocked_output" "Commit, stash, or remove the local changes"
grep -q '^intentional-local-work$' "$client/payload.txt" \
    || fail "Blocked update must not overwrite unrelated local work."
git -C "$client" checkout -- payload.txt

# Case 4: if project.godot itself changes upstream, do not replay the older
# local version over the new authoritative project config. Keep the old local
# copy in a stash for manual recovery instead.
printf 'remote-project-v2\n' > "$seed/project.godot"
git -C "$seed" add project.godot
git -C "$seed" commit -m "remote project config update" >/dev/null
git -C "$seed" push origin main >/dev/null

third_output="$(cd "$client" && bash update.sh 2>&1)" || {
    printf '%s\n' "$third_output" >&2
    fail "Updater should complete when project.godot also changed upstream."
}
assert_contains "$third_output" "project.godot changed upstream in this update"
[[ "$(cat "$client/project.godot")" == "remote-project-v2" ]] \
    || fail "Upstream project.godot must win when it changed remotely."
[[ -z "$(git -C "$client" status --porcelain)" ]] \
    || fail "Checkout should be clean after accepting the new upstream project.godot."
git -C "$client" stash list | grep -q 'ccf-update: preserve local project.godot' \
    || fail "Older local project.godot must remain recoverable in Git stash."

printf 'v0.15.38-hotfix1 update.sh project.godot regression passed\n'
