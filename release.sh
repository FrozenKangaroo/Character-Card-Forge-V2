#!/usr/bin/env bash
set -euo pipefail

EXPECTED_REMOTE="https://github.com/FrozenKangaroo/Character-Card-Forge-V2.git"
REQUIRED_GODOT_VERSION="4.7.1"
REQUIRED_GODOT_STATUS="stable"
DEFAULT_RELEASE_VERSION="0.15.40"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DEFAULT_REPO_DIR="${HOME}/Projects/Character-Card-Forge-V2"
DEFAULT_GODOT_BIN="${HOME}/Godot/Godot_v${REQUIRED_GODOT_VERSION}-${REQUIRED_GODOT_STATUS}_linux.x86_64"

resolve_repository_input() {
    if [[ -n "${CCF_REPO_DIR:-}" ]]; then
        printf '%s\n' "${CCF_REPO_DIR}"
        return 0
    fi

    local source_root=""
    if source_root="$(git -C "${SOURCE_DIR}" rev-parse --show-toplevel 2>/dev/null)"; then
        source_root="$(cd "${source_root}" && pwd -P)"
        if [[ "${source_root}" == "${SOURCE_DIR}" ]]; then
            printf '%s\n' "${SOURCE_DIR}"
            return 0
        fi
    fi

    printf '%s\n' "${DEFAULT_REPO_DIR}"
}

REPO_DIR_INPUT="$(resolve_repository_input)"

if [[ "${CCF_RELEASE_PRINT_REPO_ONLY:-0}" == "1" ]]; then
    printf '%s\n' "${REPO_DIR_INPUT}"
    exit 0
fi

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

canonical_existing_dir() {
    local directory="$1"
    if [[ ! -d "${directory}" ]]; then
        return 1
    fi
    (cd "${directory}" && pwd -P)
}

working_copy_matches_ref() {
    local repo_dir="$1"
    local ref="$2"
    local path
    local remote_blob
    local local_blob
    local -a changed_paths=()

    mapfile -d '' changed_paths < <(
        {
            git -C "${repo_dir}" diff --name-only -z
            git -C "${repo_dir}" diff --cached --name-only -z
            git -C "${repo_dir}" ls-files --others --exclude-standard -z
        } | sort -zu
    )

    if [[ "${#changed_paths[@]}" -eq 0 ]]; then
        return 1
    fi

    for path in "${changed_paths[@]}"; do
        if [[ ! -f "${repo_dir}/${path}" ]]; then
            return 1
        fi
        if ! remote_blob="$(git -C "${repo_dir}" rev-parse "${ref}:${path}" 2>/dev/null)"; then
            return 1
        fi
        local_blob="$(git hash-object "${repo_dir}/${path}")"
        if [[ "${local_blob}" != "${remote_blob}" ]]; then
            return 1
        fi
    done

    return 0
}

update_destination_main() {
    local repo_dir="$1"

    print_status "Updating destination checkout"
    git -C "${repo_dir}" fetch origin main --prune

    if [[ -n "$(git -C "${repo_dir}" status --porcelain)" ]]; then
        if working_copy_matches_ref "${repo_dir}" "origin/main"; then
            echo "The local files already match the merged origin/main state."
            echo "Reconciling the checkout automatically."
            git -C "${repo_dir}" reset --hard origin/main >/dev/null
        else
            echo "WARNING: The destination repository contains local changes that differ from origin/main."
            echo "The development copy may overwrite files with the same names."
            git -C "${repo_dir}" status --short
            if ! prompt_yes_no "Continue with the sync?" "N"; then
                exit 1
            fi
            return 0
        fi
    fi

    if git -C "${repo_dir}" merge-base --is-ancestor HEAD origin/main; then
        if [[ "$(git -C "${repo_dir}" rev-parse HEAD)" != \
              "$(git -C "${repo_dir}" rev-parse origin/main)" ]]; then
            git -C "${repo_dir}" merge --ff-only origin/main
        else
            echo "Destination checkout is already current."
        fi
        return 0
    fi

    if git -C "${repo_dir}" merge-base --is-ancestor origin/main HEAD; then
        echo "WARNING: Destination main contains local commits not present on origin/main."
        if ! prompt_yes_no "Continue without resetting those commits?" "N"; then
            exit 1
        fi
        return 0
    fi

    echo "ERROR: Destination main has diverged from origin/main." >&2
    echo "Resolve the Git history before running the release script again." >&2
    exit 1
}

sync_to_repository() {
    local repo_dir

    if ! repo_dir="$(canonical_existing_dir "${REPO_DIR_INPUT}")"; then
        echo "ERROR: Git repository directory was not found:" >&2
        echo "  ${REPO_DIR_INPUT}" >&2
        echo "Set CCF_REPO_DIR when your clone is stored elsewhere." >&2
        exit 1
    fi

    if [[ ! -d "${repo_dir}/.git" ]]; then
        echo "ERROR: Destination is not a Git repository:" >&2
        echo "  ${repo_dir}" >&2
        exit 1
    fi

    if [[ "${SOURCE_DIR}" == "${repo_dir}" ]]; then
        print_status "Using current repository checkout"
        echo "Release repository: ${repo_dir}"
        cd "${repo_dir}"
        return 0
    fi

    local repo_branch
    repo_branch="$(git -C "${repo_dir}" branch --show-current)"
    if [[ "${repo_branch}" != "main" ]]; then
        echo "ERROR: The destination clone must be on main before syncing; current branch is ${repo_branch}." >&2
        exit 1
    fi

    local repo_origin
    repo_origin="$(git -C "${repo_dir}" remote get-url origin 2>/dev/null || true)"
    if [[ "${repo_origin}" != "${EXPECTED_REMOTE}" && \
          "${repo_origin}" != "git@github.com:FrozenKangaroo/Character-Card-Forge-V2.git" ]]; then
        echo "WARNING: destination origin is ${repo_origin:-missing}, expected ${EXPECTED_REMOTE}."
        if ! prompt_yes_no "Sync into this repository anyway?" "N"; then
            exit 1
        fi
    fi

    update_destination_main "${repo_dir}"

    if ! command -v rsync >/dev/null 2>&1; then
        echo "ERROR: rsync is required to copy the development project into the Git clone." >&2
        echo "On Fedora/Nobara, install it with: sudo dnf install rsync" >&2
        exit 1
    fi

    print_status "Synchronising development project"
    echo "Source:      ${SOURCE_DIR}/"
    echo "Repository:  ${repo_dir}/"
    echo "Mode:        safe additive sync (repository-only files are not deleted)"

    rsync -a \
        --exclude='.git/' \
        --exclude='.godot/' \
        --exclude='build/' \
        --exclude='dist/' \
        --exclude='exports/' \
        --exclude='__pycache__/' \
        --exclude='*.pyc' \
        --exclude='*.pyo' \
        --exclude='*.log' \
        "${SOURCE_DIR}/" \
        "${repo_dir}/"

    chmod +x "${repo_dir}/release.sh" "${repo_dir}/update.sh"
    if compgen -G "${repo_dir}/tools/*.sh" >/dev/null; then
        chmod +x "${repo_dir}"/tools/*.sh
    fi

    echo "Sync complete. Continuing from the repository checkout."
    exec env \
        CCF_REPO_DIR="${repo_dir}" \
        "${repo_dir}/release.sh" "$@"
}

find_godot() {
    if [[ -n "${GODOT_BIN:-}" ]]; then
        if [[ -x "${GODOT_BIN}" ]]; then
            printf '%s\n' "${GODOT_BIN}"
            return 0
        fi
        echo "ERROR: GODOT_BIN is set but is not an executable file: ${GODOT_BIN}" >&2
        return 2
    fi
    if [[ -x "${DEFAULT_GODOT_BIN}" ]]; then
        printf '%s\n' "${DEFAULT_GODOT_BIN}"
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

validate_godot() {
    local godot_bin="$1"
    local version_line
    version_line="$("${godot_bin}" --version | head -n 1 | tr -d '\r')"

    if [[ "${version_line}" != "${REQUIRED_GODOT_VERSION}.${REQUIRED_GODOT_STATUS}"* ]]; then
        echo "ERROR: Character Card Forge releases require Godot ${REQUIRED_GODOT_VERSION} ${REQUIRED_GODOT_STATUS}." >&2
        echo "Detected: ${godot_bin}" >&2
        echo "Version:  ${version_line:-unknown}" >&2
        echo >&2
        echo "Set GODOT_BIN to the correct executable, for example:" >&2
        echo "  GODOT_BIN=/path/to/Godot_v${REQUIRED_GODOT_VERSION}-${REQUIRED_GODOT_STATUS}_linux.x86_64 bash release.sh" >&2
        return 1
    fi
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
    if ! godot_bin="$(find_godot)"; then
        echo "ERROR: Godot ${REQUIRED_GODOT_VERSION} ${REQUIRED_GODOT_STATUS} is required for local release validation." >&2
        echo "Expected default location:" >&2
        echo "  ${DEFAULT_GODOT_BIN}" >&2
        echo "Or set GODOT_BIN to the correct executable." >&2
        exit 1
    fi
    validate_godot "${godot_bin}"

    print_status "Parsing project with $("${godot_bin}" --version | head -n 1)"
    "${godot_bin}" --headless --path . --import

    print_status "Running broad release regression suite"
    python3 ./tools/run_regression_suite.py \
        --profile release \
        --godot "${godot_bin}"
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

sync_to_repository "$@"
validate_repository

print_status "Deployment strategy"
echo "  [1] Commit, push, tag, and trigger Windows/Linux/macOS builds"
echo "  [2] Commit and push source changes only"
read -r -p "Select option (1 or 2): " build_choice

case "${build_choice}" in
    1)
        current_version="$(tr -d '[:space:]' < VERSION)"
        release_default="${CCF_RELEASE_VERSION:-${DEFAULT_RELEASE_VERSION}}"
        echo "Current synchronized release metadata: ${current_version}"
        read -r -p "Release version [${release_default}]: " new_version
        new_version="${new_version:-${release_default}}"
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
