#!/usr/bin/env bash
set -euo pipefail

MIN_GODOT_VERSION="${CCF_MIN_GODOT_VERSION:-4.7.1}"
REQUESTED_GODOT_VERSION="${GODOT_VERSION:-${MIN_GODOT_VERSION}}"
GODOT_STATUS="${GODOT_STATUS:-stable}"

version_lt() {
    [[ "$1" != "$2" ]] && [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ]]
}

if version_lt "${REQUESTED_GODOT_VERSION}" "${MIN_GODOT_VERSION}"; then
    printf 'Requested Godot %s is older than the Character Card Forge minimum %s; using %s instead.\n' \
        "${REQUESTED_GODOT_VERSION}" "${MIN_GODOT_VERSION}" "${MIN_GODOT_VERSION}"
    GODOT_VERSION="${MIN_GODOT_VERSION}"
else
    GODOT_VERSION="${REQUESTED_GODOT_VERSION}"
fi

RELEASE_TAG="${GODOT_VERSION}-${GODOT_STATUS}"
EDITOR_BASENAME="Godot_v${GODOT_VERSION}-${GODOT_STATUS}_linux.x86_64"
BASE_URL="https://github.com/godotengine/godot/releases/download/${RELEASE_TAG}"
WORK_DIR="${RUNNER_TEMP:-/tmp}/character-card-forge-godot-${RELEASE_TAG}"
BIN_DIR="${HOME}/.local/bin"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_STATUS}"

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}" "${BIN_DIR}" "${TEMPLATE_DIR}"

curl --fail --location --retry 3 --retry-delay 2 \
    "${BASE_URL}/${EDITOR_BASENAME}.zip" \
    --output "${WORK_DIR}/godot-editor.zip"
unzip -q "${WORK_DIR}/godot-editor.zip" -d "${WORK_DIR}/editor"
install -m 0755 \
    "${WORK_DIR}/editor/${EDITOR_BASENAME}" \
    "${BIN_DIR}/godot"

curl --fail --location --retry 3 --retry-delay 2 \
    "${BASE_URL}/Godot_v${GODOT_VERSION}-${GODOT_STATUS}_export_templates.tpz" \
    --output "${WORK_DIR}/export-templates.tpz"
unzip -q "${WORK_DIR}/export-templates.tpz" -d "${WORK_DIR}/templates"

if [[ -d "${WORK_DIR}/templates/templates" ]]; then
    cp -a "${WORK_DIR}/templates/templates/." "${TEMPLATE_DIR}/"
else
    cp -a "${WORK_DIR}/templates/." "${TEMPLATE_DIR}/"
fi

if [[ -n "${GITHUB_PATH:-}" ]]; then
    echo "${BIN_DIR}" >> "${GITHUB_PATH}"
else
    export PATH="${BIN_DIR}:${PATH}"
fi

"${BIN_DIR}/godot" --version
printf 'Installed export templates in %s\n' "${TEMPLATE_DIR}"
