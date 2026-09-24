#!/usr/bin/env python3
"""Regression checks for the v0.20.5 user-manual and Wiki export contract."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile


ROOT = Path(__file__).resolve().parent.parent


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def load_exporter():
    path = ROOT / "tools/export_user_manual_v0205.py"
    spec = importlib.util.spec_from_file_location("ccf_user_manual_v0205", path)
    require(spec is not None and spec.loader is not None, "Could not load Wiki exporter.")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    exporter = load_exporter()
    catalog = exporter.load_catalog()
    screenshot_catalog = exporter.load_screenshot_catalog()
    report = exporter.validate_catalog(catalog)
    screenshot_report = exporter.validate_screenshot_catalog(catalog, screenshot_catalog)
    pages = exporter.rendered_pages(catalog, screenshot_catalog)
    require(report["category_count"] == 10, "The manual must expose ten roadmap sections.")
    require(report["article_count"] >= 49, "The expanded manual lost required task coverage.")
    require(
        len(pages) == report["article_count"] + report["category_count"] + 2,
        "Wiki page set is incomplete.",
    )
    require("Home.md" in pages and "_Sidebar.md" in pages, "Wiki navigation pages are required.")
    require("Character Collaborator" in pages["Home.md"], "Home must index core authoring guidance.")
    require("Front Porch" in pages["_Sidebar.md"], "Sidebar must expose Front Porch guidance.")
    require(screenshot_report["screenshot_count"] == 19, "The reviewed screenshot set is incomplete.")
    require(
        screenshot_report["screenshot_article_count"] >= 20,
        "Screenshots must cover the core manual task paths.",
    )
    require(
        "images/user-manual/character-library.png" in pages["Find-And-Organise-Characters.md"],
        "The Library guide must include its reviewed screenshot.",
    )

    with tempfile.TemporaryDirectory(prefix="ccf-v0205-wiki-") as temp_dir:
        output = Path(temp_dir)
        exporter.export_pages(output, pages, screenshot_catalog)
        actual = {path.name for path in output.iterdir() if path.is_file() and path.suffix == ".md"}
        require(actual == set(pages), "Exported Wiki files differ from the deterministic page set.")
        for name, expected in pages.items():
            require(
                (output / name).read_text(encoding="utf-8") == expected,
                f"Wiki page changed during export: {name}",
            )
        exported_assets = output / "images/user-manual"
        expected_assets = {
            str(screenshot["file"])
            for screenshots in screenshot_catalog["article_screenshots"].values()
            for screenshot in screenshots
        }
        require(
            {path.name for path in exported_assets.iterdir() if path.is_file()} == expected_assets,
            "Exported Wiki screenshot set differs from the reviewed source assets.",
        )
        for file_name in expected_assets:
            require(
                (exported_assets / file_name).read_bytes()
                == (exporter.SCREENSHOT_SOURCE_DIR / file_name).read_bytes(),
                f"Wiki screenshot changed during export: {file_name}",
            )

    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    scene = (ROOT / "scenes/main.tscn").read_text(encoding="utf-8")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    require(version in {"0.20.5", "0.20.6", "0.20.7", "0.20.8", "0.20.9", "0.21.0"}, "The v0.20.5 manual must remain in a compatible candidate.")
    require(
        "main_v0205.gd" in scene or "main_current.gd" in scene,
        "The live scene must retain the v0.20.5 manual through a compatible application shell.",
    )
    require(
        "## Install" in readme and "## Create your first character" in readme,
        "README must be a task-focused product front door.",
    )
    require("Previous candidate" not in readme, "Version history belongs outside README.")
    print("V0205_WIKI_EXPORT_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
