#!/usr/bin/env python3
"""Validate source release notes and packaged Character Card Forge artifacts."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
SEMVER_RE = re.compile(
    r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:[-+][0-9A-Za-z.-]+)?$"
)
RELEASE_HEADING_RE = re.compile(
    r"^## \[(?P<version>[^]]+)] - (?P<date>\d{4}-\d{2}-\d{2})\s*$",
    re.MULTILINE,
)
REQUIRED_SECTIONS = (
    "Highlights",
    "Changes",
    "Migration notes",
    "Breaking changes",
    "Known limitations",
)


class ReadinessError(RuntimeError):
    """A release-readiness contract was not satisfied."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReadinessError(message)


def read_version(root: Path = REPO_ROOT) -> str:
    version_path = root / "VERSION"
    require(version_path.is_file(), "VERSION is missing.")
    version = version_path.read_text(encoding="utf-8").strip()
    require(bool(SEMVER_RE.fullmatch(version)), f"VERSION is not semantic: {version!r}.")
    return version


def extract_release_notes(changelog_text: str, version: str) -> str:
    match = next(
        (
            candidate
            for candidate in RELEASE_HEADING_RE.finditer(changelog_text)
            if candidate.group("version") == version
        ),
        None,
    )
    require(match is not None, f"CHANGELOG.md has no dated [{version}] release section.")
    assert match is not None
    following_heading = re.search(r"^## ", changelog_text[match.end():], re.MULTILINE)
    end = (
        match.end() + following_heading.start()
        if following_heading is not None
        else len(changelog_text)
    )
    notes = changelog_text[match.start():end].strip() + "\n"
    for section in REQUIRED_SECTIONS:
        heading = f"### {section}"
        require(heading in notes, f"[{version}] release notes are missing {heading}.")
        section_start = notes.index(heading) + len(heading)
        next_heading = notes.find("\n### ", section_start)
        body = notes[section_start:next_heading if next_heading >= 0 else len(notes)].strip()
        require(bool(body), f"[{version}] release-note section {heading} is empty.")
    return notes


def expected_artifact_names(version: str) -> tuple[str, str, str]:
    return (
        f"CharacterCardForge-v{version}-windows-x86_64.zip",
        f"CharacterCardForge-v{version}-linux-x86_64.tar.gz",
        f"CharacterCardForge-v{version}-macos-universal-unsigned.zip",
    )


def source_report(root: Path = REPO_ROOT, tag: str = "") -> dict[str, Any]:
    version = read_version(root)
    if tag:
        require(tag == f"v{version}", f"Release tag {tag!r} does not match VERSION v{version}.")
    changelog_path = root / "CHANGELOG.md"
    require(changelog_path.is_file(), "CHANGELOG.md is missing.")
    notes = extract_release_notes(changelog_path.read_text(encoding="utf-8"), version)

    release_script = (root / "release.sh").read_text(encoding="utf-8")
    workflow = (root / ".github/workflows/release.yml").read_text(encoding="utf-8")
    package_script = (root / "tools/package_release.sh").read_text(encoding="utf-8")
    require(
        "release_readiness_v0204.py" in release_script,
        "release.sh does not run the release-readiness preflight.",
    )
    require(
        "release_readiness_v0204.py" in workflow,
        "The tagged release workflow does not run the release-readiness preflight.",
    )
    require(
        "--notes-file" in workflow and "--generate-notes" not in workflow,
        "GitHub Releases must use the reviewed version-matched changelog notes.",
    )
    require(
        "SHA256SUMS.txt" in package_script,
        "Release packaging no longer produces the checksum manifest.",
    )
    return {
        "ok": True,
        "version": version,
        "tag": f"v{version}",
        "release_notes_chars": len(notes),
        "expected_artifacts": list(expected_artifact_names(version)),
    }


def _parse_checksum_manifest(text: str) -> dict[str, str]:
    entries: dict[str, str] = {}
    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue
        parts = line.split(maxsplit=1)
        require(len(parts) == 2, f"Malformed checksum line {line_number}.")
        digest, raw_name = parts
        name = raw_name.lstrip("*")
        require(bool(re.fullmatch(r"[0-9a-f]{64}", digest)), f"Invalid SHA-256 on line {line_number}.")
        require(name not in entries, f"Duplicate checksum entry for {name}.")
        entries[name] = digest
    return entries


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def artifact_report(dist_dir: Path, version: str) -> dict[str, Any]:
    require(dist_dir.is_dir(), f"Release artifact directory does not exist: {dist_dir}")
    expected = set(expected_artifact_names(version))
    checksum_path = dist_dir / "SHA256SUMS.txt"
    require(checksum_path.is_file(), "SHA256SUMS.txt is missing from the release artifacts.")
    actual_payloads = {path.name for path in dist_dir.iterdir() if path.is_file()} - {
        checksum_path.name
    }
    require(
        actual_payloads == expected,
        "Release artifacts differ from the exact platform set. "
        f"Expected {sorted(expected)}, found {sorted(actual_payloads)}.",
    )
    entries = _parse_checksum_manifest(checksum_path.read_text(encoding="utf-8"))
    require(
        set(entries) == expected,
        "SHA256SUMS.txt must contain exactly one entry for every platform package.",
    )
    sizes: dict[str, int] = {}
    for name in sorted(expected):
        artifact = dist_dir / name
        size = artifact.stat().st_size
        require(size > 0, f"Release artifact is empty: {name}")
        digest = _sha256_file(artifact)
        require(digest == entries[name], f"Checksum mismatch for {name}.")
        sizes[name] = size
    return {
        "ok": True,
        "version": version,
        "artifact_count": len(expected),
        "artifact_sizes": sizes,
        "checksums_verified": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", default="", help="Optional v-prefixed release tag.")
    parser.add_argument(
        "--artifacts",
        type=Path,
        help="Optional dist directory whose exact platform files and checksums must verify.",
    )
    parser.add_argument(
        "--write-notes",
        type=Path,
        help="Write the current version's reviewed changelog section to this file.",
    )
    parser.add_argument("--json", action="store_true", help="Print the report as JSON.")
    args = parser.parse_args()

    try:
        report = source_report(REPO_ROOT, args.tag)
        version = str(report["version"])
        if args.artifacts is not None:
            report["artifacts"] = artifact_report(args.artifacts, version)
        if args.write_notes is not None:
            notes = extract_release_notes(
                (REPO_ROOT / "CHANGELOG.md").read_text(encoding="utf-8"), version
            )
            args.write_notes.parent.mkdir(parents=True, exist_ok=True)
            args.write_notes.write_text(notes, encoding="utf-8")
            report["notes_file"] = str(args.write_notes)
    except (OSError, ReadinessError) as exc:
        print(f"Release readiness failed: {exc}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        message = (
            f"Release readiness passed for v{report['version']}: reviewed notes and "
            f"{len(report['expected_artifacts'])} expected platform packages."
        )
        if args.artifacts is not None:
            message += " Artifact names, sizes and SHA-256 checksums verified."
        print(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
