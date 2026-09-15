#!/usr/bin/env python3
"""Validate the offline Help catalog and export deterministic GitHub Wiki Markdown."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shutil
import sys
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
CATALOG_PATH = ROOT / "data/help_articles_v1.json"
SCREENSHOT_CATALOG_PATH = ROOT / "data/help_screenshots_v1.json"
SCREENSHOT_SOURCE_DIR = ROOT / "docs/images/user-manual"


class ManualError(RuntimeError):
    """The user-manual source or requested output is invalid."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ManualError(message)


def load_catalog(path: Path = CATALOG_PATH) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(data, dict), "Help catalog root must be an object.")
    return data


def load_screenshot_catalog(path: Path = SCREENSHOT_CATALOG_PATH) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(data, dict), "Screenshot catalog root must be an object.")
    return data


def page_slug(value: str) -> str:
    words = re.findall(r"[A-Za-z0-9]+", value)
    require(bool(words), f"Cannot create a Wiki slug for {value!r}.")
    return "-".join(word.capitalize() for word in words)


def validate_catalog(catalog: dict[str, Any]) -> dict[str, Any]:
    categories = catalog.get("categories", [])
    articles = catalog.get("articles", [])
    require(catalog.get("format_version") == 1, "Unsupported Help catalog format.")
    require(isinstance(categories, list) and categories, "Help categories are missing.")
    require(isinstance(articles, list) and articles, "Help articles are missing.")

    category_ids: set[str] = set()
    category_slugs: set[str] = set()
    for category in categories:
        require(isinstance(category, dict), "Every Help category must be an object.")
        category_id = str(category.get("id", "")).strip()
        label = str(category.get("label", "")).strip()
        require(category_id and category_id not in category_ids, "Category IDs must be unique.")
        require(bool(label), f"Help category {category_id!r} needs a label.")
        slug = page_slug(label)
        require(slug not in category_slugs, f"Duplicate Wiki category slug: {slug}")
        category_ids.add(category_id)
        category_slugs.add(slug)

    article_ids: set[str] = set()
    article_slugs: set[str] = set()
    action_count = 0
    for article in articles:
        require(isinstance(article, dict), "Every Help article must be an object.")
        article_id = str(article.get("id", "")).strip()
        title = str(article.get("title", "")).strip()
        require(article_id and article_id not in article_ids, "Article IDs must be unique.")
        require(str(article.get("category", "")) in category_ids, f"Unknown category on {article_id}.")
        require(bool(title), f"Help article {article_id!r} needs a title.")
        require(bool(article.get("steps", [])), f"Help article {article_id!r} needs steps.")
        slug = page_slug(title)
        require(slug not in article_slugs, f"Duplicate Wiki article slug: {slug}")
        article_ids.add(article_id)
        article_slugs.add(slug)
        action_count += len(article.get("actions", []))

    for article in articles:
        for related_id in article.get("related", []):
            require(
                str(related_id) in article_ids,
                f"{article.get('id')} links to unknown article {related_id!r}.",
            )
    return {
        "category_count": len(categories),
        "article_count": len(articles),
        "action_count": action_count,
    }


def validate_screenshot_catalog(
    catalog: dict[str, Any], screenshot_catalog: dict[str, Any]
) -> dict[str, Any]:
    require(screenshot_catalog.get("format_version") == 1, "Unsupported screenshot catalog format.")
    mappings = screenshot_catalog.get("article_screenshots", {})
    require(isinstance(mappings, dict), "Screenshot article mappings must be an object.")
    article_ids = {str(article["id"]) for article in catalog["articles"]}
    unique_files: set[str] = set()
    usage_count = 0
    for article_id, screenshots in mappings.items():
        require(article_id in article_ids, f"Screenshots reference unknown article {article_id!r}.")
        require(isinstance(screenshots, list) and screenshots, f"{article_id} needs screenshot entries.")
        article_files: set[str] = set()
        for screenshot in screenshots:
            require(isinstance(screenshot, dict), f"Invalid screenshot entry for {article_id}.")
            file_name = str(screenshot.get("file", "")).strip()
            source = SCREENSHOT_SOURCE_DIR / file_name
            require(
                file_name
                and Path(file_name).name == file_name
                and Path(file_name).suffix.lower() == ".png",
                f"Screenshot file for {article_id} must be a plain PNG filename.",
            )
            require(file_name not in article_files, f"Duplicate screenshot {file_name} on {article_id}.")
            require(source.is_file(), f"Missing documentation screenshot: {source.relative_to(ROOT)}")
            require(bool(str(screenshot.get("alt", "")).strip()), f"{file_name} needs alternative text.")
            require(bool(str(screenshot.get("caption", "")).strip()), f"{file_name} needs a caption.")
            article_files.add(file_name)
            unique_files.add(file_name)
            usage_count += 1
    return {
        "screenshot_article_count": len(mappings),
        "screenshot_count": len(unique_files),
        "screenshot_usage_count": usage_count,
    }


def _article_lookup(catalog: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {str(article["id"]): article for article in catalog["articles"]}


def render_article(
    article: dict[str, Any],
    lookup: dict[str, dict[str, Any]],
    screenshot_catalog: dict[str, Any],
) -> str:
    lines = [
        f"# {article['title']}",
        "",
        str(article.get("summary", "")),
        "",
    ]
    screenshots = screenshot_catalog.get("article_screenshots", {}).get(str(article["id"]), [])
    if screenshots:
        lines.extend(["## Screenshot" if len(screenshots) == 1 else "## Screenshots", ""])
        for screenshot in screenshots:
            lines.extend(
                [
                    f"![{screenshot['alt']}](images/user-manual/{screenshot['file']})",
                    "",
                    f"*{screenshot['caption']}*",
                    "",
                ]
            )
    lines.extend(["## Steps", ""])
    for index, step in enumerate(article.get("steps", []), start=1):
        lines.append(f"{index}. {step}")
    notes = article.get("notes", [])
    if notes:
        lines.extend(["", "## Good to know", ""])
        lines.extend(f"- {note}" for note in notes)
    actions = article.get("actions", [])
    if actions:
        lines.extend(["", "## Open in Character Card Forge", ""])
        lines.extend(f"- **{action['label']}**" for action in actions)
    related = article.get("related", [])
    if related:
        lines.extend(["", "## Related pages", ""])
        for related_id in related:
            related_article = lookup[str(related_id)]
            lines.append(
                f"- [{related_article['title']}]({page_slug(str(related_article['title']))})"
            )
    lines.extend(["", "---", "", "Generated from the versioned offline Help catalog.", ""])
    return "\n".join(lines)


def rendered_pages(
    catalog: dict[str, Any], screenshot_catalog: dict[str, Any] | None = None
) -> dict[str, str]:
    validate_catalog(catalog)
    if screenshot_catalog is None:
        screenshot_catalog = load_screenshot_catalog()
    validate_screenshot_catalog(catalog, screenshot_catalog)
    lookup = _article_lookup(catalog)
    pages: dict[str, str] = {}
    home = [
        "# Character Card Forge User Manual",
        "",
        "Task-oriented guidance generated from the same validated catalog shipped in the app.",
        "",
    ]
    sidebar = ["**[Home](Home)**", ""]
    for category in catalog["categories"]:
        category_id = str(category["id"])
        label = str(category["label"])
        category_slug = page_slug(label)
        category_articles = [
            article for article in catalog["articles"] if article["category"] == category_id
        ]
        home.extend([f"## [{label}]({category_slug})", ""])
        category_lines = [f"# {label}", ""]
        sidebar.extend([f"**[{label}]({category_slug})**", ""])
        for article in category_articles:
            title = str(article["title"])
            slug = page_slug(title)
            summary = str(article.get("summary", ""))
            home.append(f"- [{title}]({slug}) — {summary}")
            category_lines.append(f"- [{title}]({slug}) — {summary}")
            sidebar.append(f"- [{title}]({slug})")
            pages[f"{slug}.md"] = render_article(article, lookup, screenshot_catalog)
        home.append("")
        category_lines.append("")
        pages[f"{category_slug}.md"] = "\n".join(category_lines)
        sidebar.append("")
    pages["Home.md"] = "\n".join(home)
    pages["_Sidebar.md"] = "\n".join(sidebar)
    return dict(sorted(pages.items()))


def export_pages(
    output: Path,
    pages: dict[str, str],
    screenshot_catalog: dict[str, Any] | None = None,
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    for name, content in pages.items():
        destination = output / name
        temporary = output / f".{name}.tmp"
        temporary.write_text(content, encoding="utf-8")
        temporary.replace(destination)
    if screenshot_catalog is None:
        screenshot_catalog = load_screenshot_catalog()
    asset_output = output / "images/user-manual"
    asset_output.mkdir(parents=True, exist_ok=True)
    file_names = {
        str(screenshot["file"])
        for screenshots in screenshot_catalog.get("article_screenshots", {}).values()
        for screenshot in screenshots
    }
    for file_name in sorted(file_names):
        shutil.copyfile(SCREENSHOT_SOURCE_DIR / file_name, asset_output / file_name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="Optional directory for Wiki Markdown pages.")
    parser.add_argument("--json", action="store_true", help="Print the validation report as JSON.")
    args = parser.parse_args()
    try:
        catalog = load_catalog()
        report = validate_catalog(catalog)
        screenshot_catalog = load_screenshot_catalog()
        report.update(validate_screenshot_catalog(catalog, screenshot_catalog))
        pages = rendered_pages(catalog, screenshot_catalog)
        report["page_count"] = len(pages)
        if args.output is not None:
            export_pages(args.output, pages, screenshot_catalog)
            report["output"] = str(args.output)
    except (OSError, json.JSONDecodeError, ManualError) as exc:
        print(f"User manual export failed: {exc}", file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(
            "User manual validated: "
            f"{report['article_count']} articles, {report['category_count']} categories, "
            f"{report['page_count']} deterministic Wiki pages and "
            f"{report['screenshot_count']} reviewed screenshots."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
