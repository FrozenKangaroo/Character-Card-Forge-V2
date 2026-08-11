#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

bash -n ./release.sh
python3 ./tools/validate_project.py >/dev/null

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

# Hotfix8 established the release-QA contract. Later shells are expected to
# inherit that implementation, but the active scene is free to advance beyond
# the v0.15.40 filename family. Verify the real inheritance chain rather than
# pinning scenes/main.tscn to an obsolete versioned leaf.
grep -F 'BUILD_DISPLAY_VERSION_V01540_HOTFIX8 := "0.15.40-hotfix8"' scripts/main_v01540_hotfix8.gd >/dev/null
python3 - <<'PY'
from pathlib import Path
import re

TARGET = "res://scripts/main_v01540_hotfix8.gd"
scene = Path("scenes/main.tscn").read_text(encoding="utf-8")n
match = re.search(r'\[ext_resource path="(res://scripts/main[^\"]*\.gd)" type="Script" id="1_main"\]', scene)
if match is None:
    raise SystemExit("The main scene does not expose a versioned main-shell script.")

current = match.group(1)
visited = []
for _ in range(64):
    visited.append(current)
    if current == TARGET:
        break
    local_path = Path(current.removeprefix("res://"))
    if not local_path.is_file():
        raise SystemExit(f"The active shell inheritance file is missing: {local_path}.")
    text = local_path.read_text(encoding="utf-8")
    base = re.search(r'^extends\s+"(res://[^\"]+\.gd)"\s*$', text, re.MULTILINE)
    if base is None:
        raise SystemExit(
            "The active main-shell chain no longer reaches the hotfix8 release-QA layer. "
            f"Stopped at {current}."
        )
    current = base.group(1)
else:
    raise SystemExit("The active main-shell inheritance chain exceeded 64 layers.")

if TARGET not in visited:
    raise SystemExit(
        "The active main-shell chain no longer inherits v0.15.40-hotfix8 release QA. "
        f"Chain: {' -> '.join(visited)}"
    )
PY

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
