#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.6.3}"
GODOT_STATUS="${GODOT_STATUS:-stable}"
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
