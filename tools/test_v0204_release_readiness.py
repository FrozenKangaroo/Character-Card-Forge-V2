#!/usr/bin/env python3
"""Regression checks for the v0.20.4 deterministic release contract."""

from __future__ import annotations

import hashlib
import importlib.util
from pathlib import Path
import tempfile


ROOT = Path(__file__).resolve().parent.parent


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def load_module():
    path = ROOT / "tools/release_readiness_v0204.py"
    spec = importlib.util.spec_from_file_location("ccf_release_readiness_v0204", path)
    require(spec is not None and spec.loader is not None, "Could not load release preflight.")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    readiness = load_module()
    current_version = readiness.read_version(ROOT)
    report = readiness.source_report(ROOT, f"v{current_version}")
    require(
        report["ok"] and report["version"] == current_version,
        "Current source preflight failed.",
    )
    require(len(report["expected_artifacts"]) == 3, "Exactly three platform packages are required.")

    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    require("## 0.1.0" in changelog, "Historical changelog entries must remain intact.")
    require("## [0.20.4]" in changelog, "v0.20.4 release notes must remain intact.")
    notes = readiness.extract_release_notes(changelog, current_version)
    require("### Migration notes" in notes, "Migration notes must be explicit.")
    require("### Breaking changes" in notes, "Breaking changes must be explicit.")
    require("### Known limitations" in notes, "Known limitations must be explicit.")
    require("## 0.19.4" not in notes, "Only the requested version may enter release notes.")

    with tempfile.TemporaryDirectory(prefix="ccf-v0204-artifacts-") as temp_dir:
        dist = Path(temp_dir)
        checksum_lines: list[str] = []
        for index, name in enumerate(readiness.expected_artifact_names(current_version), start=1):
            payload = f"artifact-{index}".encode("utf-8")
            (dist / name).write_bytes(payload)
            checksum_lines.append(f"{hashlib.sha256(payload).hexdigest()}  {name}")
        (dist / "SHA256SUMS.txt").write_text("\n".join(checksum_lines) + "\n", encoding="utf-8")
        artifact_report = readiness.artifact_report(dist, current_version)
        require(
            artifact_report["artifact_count"] == 3 and artifact_report["checksums_verified"],
            "Complete artifact fixtures must verify.",
        )
        first_name = readiness.expected_artifact_names(current_version)[0]
        (dist / first_name).write_bytes(b"tampered")
        try:
            readiness.artifact_report(dist, current_version)
        except readiness.ReadinessError as exc:
            require("Checksum mismatch" in str(exc), "Tampering must fail specifically on checksum.")
        else:
            raise RuntimeError("A tampered platform package passed checksum validation.")

    release_script = (ROOT / "release.sh").read_text(encoding="utf-8")
    workflow = (ROOT / ".github/workflows/release.yml").read_text(encoding="utf-8")
    require("--preflight-only" in release_script, "The local helper needs a non-publishing preflight mode.")
    require(
        'release_default="${CCF_RELEASE_VERSION:-${current_version}}"' in release_script,
        "The release default must follow synchronized current metadata.",
    )
    require(
        release_script.index('ensure_tag_available "${tag}"')
        < release_script.index('print_status "Pushing main"'),
        "Tag collisions must fail before main is pushed.",
    )
    require("--notes-file" in workflow, "GitHub Release publishing must use reviewed notes.")
    require("--generate-notes" not in workflow, "Unreviewed generated notes must not be published.")
    require(
        workflow.index("--artifacts dist") < workflow.index("gh release create"),
        "Package verification must finish before GitHub Release creation.",
    )
    print("V0204_RELEASE_READINESS_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
