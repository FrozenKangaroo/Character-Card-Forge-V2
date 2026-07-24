#!/usr/bin/env bash
set -euo pipefail

EXPECTED_REMOTE="https://github.com/FrozenKangaroo/Character-Card-Forge-V2.git"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

print_status() {
    printf '\033[0;36m=== %s ===\033[0m\n' "$1"
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-N}"
    local answer

    if [[ "${default}" == "Y" ]]; then
        read -r -p "${prompt} [Y/n]: " answer
        answer="${answer:-Y}"
    else
        read -r -p "${prompt} [y/N]: " answer
        answer="${answer:-N}"
    fi

    case "${answer}" in
        y|Y|yes|YES|Yes) return 0 ;;
        *) return 1 ;;
    esac
}

find_godot() {
    if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then
        printf '%s\n' "${GODOT_BIN}"
        return 0
    fi
    if command -v godot >/dev/null 2>&1; then
        command -v godot
        return 0
    fi
    if command -v godot4 >/dev/null 2>&1; then
        command -v godot4
        return 0
    fi
    return 1
}

validate_repository() {
    print_status "Checking repository"

    git rev-parse --is-inside-work-tree >/dev/null

    local branch
    branch="$(git branch --show-current)"
    if [[ "${branch}" != "main" ]]; then
        echo "ERROR: Releases must be prepared from main; current branch is ${branch}." >&2
        exit 1
    fi

    local origin
    origin="$(git remote get-url origin 2>/dev/null || true)"
    if [[ "${origin}" != "${EXPECTED_REMOTE}" && \
          "${origin}" != "git@github.com:FrozenKangaroo/Character-Card-Forge-V2.git" ]]; then
        echo "WARNING: origin is ${origin:-missing}, expected ${EXPECTED_REMOTE}."
        if ! prompt_yes_no "Continue with this origin?" "N"; then
            exit 1
        fi
    fi
}

run_checks() {
    print_status "Validating project metadata and bundled data"
    python3 ./tools/validate_project.py

    local godot_bin
    if godot_bin="$(find_godot)"; then
        print_status "Parsing project with $(${godot_bin} --version | head -n 1)"
        "${godot_bin}" --headless --path . --import
    else
        echo "WARNING: Godot was not found in PATH; local engine validation was skipped."
        echo "GitHub Actions will still parse the project before any release is published."
    fi
}

stage_and_commit() {
    local default_message="$1"

    print_status "Staging project changes"
    git add --all

    if git diff --cached --quiet; then
        echo "No new modifications to commit."
        return 0
    fi

    local commit_message
    read -r -p "Commit message [${default_message}]: " commit_message
    commit_message="${commit_message:-${default_message}}"
    git commit -m "${commit_message}"
}

ensure_tag_available() {
    local tag="$1"

    if git rev-parse "refs/tags/${tag}" >/dev/null 2>&1; then
        echo "ERROR: Local tag ${tag} already exists. Use a new patch version." >&2
        exit 1
    fi

    if git ls-remote --exit-code --tags origin "refs/tags/${tag}" >/dev/null 2>&1; then
        echo "ERROR: Remote tag ${tag} already exists. Published release history is not rewritten." >&2
        echo "Bump the patch version and try again." >&2
        exit 1
    fi
}

validate_repository

print_status "Deployment strategy"
echo "  [1] Commit, push, tag, and trigger Windows/Linux/macOS builds"
echo "  [2] Commit and push source changes only"
read -r -p "Select option (1 or 2): " build_choice

case "${build_choice}" in
    1)
        current_version="$(tr -d '[:space:]' < VERSION)"
        read -r -p "Release version [${current_version}]: " new_version
        new_version="${new_version:-${current_version}}"
        new_version="${new_version#v}"

        print_status "Synchronising version ${new_version}"
        python3 ./tools/set_version.py "${new_version}"
        run_checks
        stage_and_commit "Prepare Character Card Forge v${new_version}"

        print_status "Pushing main"
        git push origin main

        tag="v${new_version}"
        git fetch origin --tags --quiet
        ensure_tag_available "${tag}"

        print_status "Creating release tag ${tag}"
        git tag -a "${tag}" -m "Character Card Forge ${tag}"
        git push origin "${tag}"

        echo
        echo "SUCCESS: ${tag} was pushed. GitHub Actions is now building:"
        echo "  - Windows x86-64"
        echo "  - Linux x86-64"
        echo "  - unsigned macOS Universal"
        ;;
    2)
        run_checks
        stage_and_commit "Update Character Card Forge source"

        print_status "Pushing source changes"
        git push origin main
        echo "SUCCESS: Source changes were pushed without creating a release tag."
        ;;
    *)
        echo "ERROR: Select either 1 or 2." >&2
        exit 1
        ;;
esac
