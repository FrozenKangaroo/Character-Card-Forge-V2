#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

bash -n release.sh
bash -n update.sh

resolved_current="$(CCF_RELEASE_PRINT_REPO_ONLY=1 bash ./release.sh)"
if [[ "${resolved_current}" != "${repo_root}" ]]; then
    echo "Expected release.sh to select its current Git checkout." >&2
    echo "Expected: ${repo_root}" >&2
    echo "Actual:   ${resolved_current}" >&2
    exit 1
fi

tmp_root="$(mktemp -d)"
trap 'rm -rf "${tmp_root}"' EXIT
mkdir -p "${tmp_root}/override" "${tmp_root}/home" "${tmp_root}/development-copy"

override_dir="$(cd "${tmp_root}/override" && pwd -P)"
resolved_override="$(
    CCF_REPO_DIR="${override_dir}" \
    CCF_RELEASE_PRINT_REPO_ONLY=1 \
    bash ./release.sh
)"
if [[ "${resolved_override}" != "${override_dir}" ]]; then
    echo "Explicit CCF_REPO_DIR must override automatic current-checkout selection." >&2
    exit 1
fi

cp ./release.sh "${tmp_root}/development-copy/release.sh"
resolved_fallback="$(
    HOME="${tmp_root}/home" \
    CCF_RELEASE_PRINT_REPO_ONLY=1 \
    bash "${tmp_root}/development-copy/release.sh"
)"
expected_fallback="${tmp_root}/home/Projects/Character-Card-Forge-V2"
if [[ "${resolved_fallback}" != "${expected_fallback}" ]]; then
    echo "Non-repository development copies must retain the legacy destination fallback." >&2
    echo "Expected: ${expected_fallback}" >&2
    echo "Actual:   ${resolved_fallback}" >&2
    exit 1
fi

for helper in release.sh update.sh; do
    mode="$(git ls-files -s -- "${helper}" | awk '{print $1}')"
    if [[ "${mode}" != "100755" ]]; then
        echo "${helper} must be executable in Git; got mode ${mode:-missing}." >&2
        exit 1
    fi
done

echo "v0.15.19 release checkout selection shell regression passed"
