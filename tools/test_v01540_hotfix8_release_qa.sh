#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

# Development branches keep the last synchronised release metadata internally
# consistent. The next intended promotion is a separate release.sh default and
# is applied atomically by tools/set_version.py only after the user chooses it.
synchronised_version="$(tr -d '[:space:]' < VERSION)"
project_version="$(sed -n 's/^config\/version="\([^"]*\)"$/\1/p' project.godot)"
if [[ -z "${synchronised_version}" || "${project_version}" != "${synchronised_version}" ]]; then
    echo "VERSION and project.godot release metadata must remain synchronised before promotion." >&2
    echo "VERSION=${synchronised_version:-missing}, project.godot=${project_version:-missing}" >&2
    exit 1
fi

grep -F 'DEFAULT_RELEASE_VERSION="0.15.40"' release.sh >/dev/null
grep -F 'release_default="${CCF_RELEASE_VERSION:-${DEFAULT_RELEASE_VERSION}}"' release.sh >/dev/null
grep -F 'Release version [${release_default}]' release.sh >/dev/null

grep -F 'REQUIRED_GODOT_VERSION="4.7.1"' release.sh >/dev/null
grep -F 'REQUIRED_GODOT_STATUS="stable"' release.sh >/dev/null
grep -F 'DEFAULT_GODOT_BIN="${HOME}/Godot/Godot_v${REQUIRED_GODOT_VERSION}-${REQUIRED_GODOT_STATUS}_linux.x86_64"' release.sh >/dev/null
grep -F 'validate_godot "${godot_bin}"' release.sh >/dev/null
grep -F 'ERROR: Character Card Forge releases require Godot ${REQUIRED_GODOT_VERSION} ${REQUIRED_GODOT_STATUS}.' release.sh >/dev/null

if grep -F 'local engine validation and broad regression checks were skipped' release.sh >/dev/null; then
    echo "release.sh must fail closed when the required Godot is unavailable." >&2
    exit 1
fi

grep -F 'res://scripts/main_v01540_hotfix8.gd' scenes/main.tscn >/dev/null
grep -F 'BUILD_DISPLAY_VERSION_V01540_HOTFIX8 := "0.15.40-hotfix8"' scripts/main_v01540_hotfix8.gd >/dev/null

# The compatibility parser must run before the inherited fallback so nested
# text/value response parts cannot be prematurely stringified.
python3 - <<'PY'
from pathlib import Path
text = Path("scripts/services/generation_service_v01310_hotfix.gd").read_text(encoding="utf-8")
choices = text.index('var choices: Variant = response.get("choices", [])', text.index('func _extract_content'))
inherited = text.index('var inherited: String = super._extract_content(response).strip_edges()', choices)
if inherited <= choices:
    raise SystemExit("Inherited response extraction still runs before compatibility parsing.")
PY

echo "v0.15.40-hotfix8 release QA regression passed"
