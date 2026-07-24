#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/VERSION")"
BUILD_DIR="${ROOT_DIR}/build"
DIST_DIR="${ROOT_DIR}/dist"

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

WINDOWS_EXE="${BUILD_DIR}/windows/CharacterCardForge.exe"
LINUX_EXE="${BUILD_DIR}/linux/CharacterCardForge.x86_64"
MACOS_ZIP="${BUILD_DIR}/macos/CharacterCardForge.zip"

for artifact in "${WINDOWS_EXE}" "${LINUX_EXE}" "${MACOS_ZIP}"; do
    if [[ ! -f "${artifact}" ]]; then
        echo "Missing exported artifact: ${artifact}" >&2
        exit 1
    fi
done

WINDOWS_STAGE="${BUILD_DIR}/package-windows"
LINUX_STAGE="${BUILD_DIR}/package-linux"
rm -rf "${WINDOWS_STAGE}" "${LINUX_STAGE}"
mkdir -p "${WINDOWS_STAGE}" "${LINUX_STAGE}"

cp "${WINDOWS_EXE}" "${WINDOWS_STAGE}/CharacterCardForge.exe"
cp "${ROOT_DIR}/README.md" "${WINDOWS_STAGE}/README.md"
(
    cd "${WINDOWS_STAGE}"
    zip -q -9 -r \
        "${DIST_DIR}/CharacterCardForge-v${VERSION}-windows-x86_64.zip" \
        .
)

cp "${LINUX_EXE}" "${LINUX_STAGE}/CharacterCardForge.x86_64"
chmod +x "${LINUX_STAGE}/CharacterCardForge.x86_64"
cp "${ROOT_DIR}/README.md" "${LINUX_STAGE}/README.md"
tar -C "${LINUX_STAGE}" -czf \
    "${DIST_DIR}/CharacterCardForge-v${VERSION}-linux-x86_64.tar.gz" \
    .

cp "${MACOS_ZIP}" \
    "${DIST_DIR}/CharacterCardForge-v${VERSION}-macos-universal-unsigned.zip"

(
    cd "${DIST_DIR}"
    sha256sum CharacterCardForge-v* > SHA256SUMS.txt
)

printf 'Packaged release files:\n'
find "${DIST_DIR}" -maxdepth 1 -type f -printf '  %f\n' | sort
