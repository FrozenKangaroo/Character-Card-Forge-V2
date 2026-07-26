#!/usr/bin/env python3
"""Validate release metadata and data files without changing the project."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:[-+][0-9A-Za-z.-]+)?$")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"Validation failed: {message}")


def read_match(path: Path, pattern: str, label: str) -> str:
    text = path.read_text(encoding="utf-8")
    match = re.search(pattern, text, flags=re.MULTILINE)
    require(match is not None, f"Could not find {label} in {path.relative_to(ROOT)}.")
    return match.group(1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--tag",
        default="",
        help="Optional release tag to compare with VERSION, for example v1.2.3",
    )
    args = parser.parse_args()

    required_paths = [
        "project.godot",
        "export_presets.cfg",
        "scenes/main.tscn",
        "scripts/main.gd",
        "scripts/main_with_image_page.gd",
        "scripts/services/attachment_service.gd",
        "scripts/services/image_generation_service.gd",
        "scripts/services/image_capability_service.gd",
        "scripts/services/settings_service.gd",
        "scripts/ui/attachment_manager_window.gd",
        "scripts/ui/image_generation_window.gd",
        "scripts/ui/image_generation_controller.gd",
        "scripts/ui/image_generation_page.gd",
        "scripts/ui/image_provider_settings_view.gd",
        "scripts/ui/settings_view.gd",
        "docs/vision_attachments.md",
        "docs/image_generation.md",
        "roadmap.md",
        "release.sh",
        "VERSION",
        ".github/workflows/validate.yml",
        ".github/workflows/release.yml",
    ]
    for relative in required_paths:
        require((ROOT / relative).is_file(), f"Missing required file: {relative}")

    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    require(bool(SEMVER_RE.fullmatch(version)), f"VERSION is not semantic: {version!r}")

    discovered = {
        "project.godot": read_match(
            ROOT / "project.godot", r'^config/version="([^"]+)"$', "application version"
        ),
        "scripts/main.gd": read_match(
            ROOT / "scripts/main.gd", r'^const APP_VERSION := "([^"]+)"$', "APP_VERSION"
        ),
        "project_package_service.gd": read_match(
            ROOT / "scripts/services/project_package_service.gd",
            r'^\s*"application_version":\s*"([^"]+)"',
            "package application version",
        ),
        "series_service.gd": read_match(
            ROOT / "scripts/services/series_service.gd",
            r'^\s*"application_version":\s*"([^"]+)"',
            "series-pack application version",
        ),
    }
    for source, source_version in discovered.items():
        require(
            source_version == version,
            f"{source} reports {source_version}, but VERSION reports {version}.",
        )

    project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
    require(
        'textures/vram_compression/import_etc2_astc=true' in project_text,
        "Universal/ARM64 macOS exports require ETC2/ASTC texture import to be enabled.",
    )

    settings_text = (ROOT / "scripts/services/settings_service.gd").read_text(encoding="utf-8")
    require(
        "const SETTINGS_FORMAT_VERSION := 6" in settings_text,
        "Settings schema must be version 6 for separated character-AI and image providers.",
    )
    for marker_text in (
        'const ROLE_TEXT := "text"',
        'const ROLE_VISION := "vision"',
        'const ROLE_IMAGE := "image"',
        'const PROFILE_KIND_AI := "ai"',
        'const PROFILE_KIND_IMAGE := "image"',
        'const IMAGE_BACKEND_OPENAI := "openai_compatible"',
        'const IMAGE_BACKEND_AUTOMATIC1111 := "automatic1111"',
        '"image_profiles": [_default_image_profile()]',
        '"base_url": "http://127.0.0.1:7860"',
        "static func image_profiles(",
        "static func image_profile_by_id(",
        "static func create_image_profile(",
        "static func replace_image_profile_by_id(",
        "static func _migrate_v5_image_profile(",
    ):
        require(marker_text in settings_text, f"Separated provider settings are missing {marker_text}")
    require(
        '"attachment_context_character_limit": 24000' in settings_text,
        "The default attachment context budget is missing.",
    )
    require(
        '"default_image_size": "1024x1024"' in settings_text
        and '"default_image_prompt_style": "auto"' in settings_text,
        "Default image generation settings are missing.",
    )
    for marker_text in (
        '"sampler": "Euler a"',
        '"steps": 28',
        '"cfg_scale": 7.0',
        '"seed": -1',
        '"batch_size": 1',
    ):
        require(marker_text in settings_text, f"Image profile defaults are missing {marker_text}")

    storage_text = (ROOT / "scripts/services/storage_service.gd").read_text(encoding="utf-8")
    require(
        storage_text.count('"attachments": []') >= 2,
        "Project and character attachment arrays are not both initialised.",
    )
    require(
        '"generated_images": []' in storage_text and '"portrait": ""' in storage_text,
        "Character asset records are missing generated-image or portrait foundations.",
    )
    require(
        'character["project_attachments"]' in storage_text,
        "Character workspace documents do not receive shared project attachments.",
    )
    require(
        "copy_managed_attachment(" in storage_text,
        "Project duplication does not copy managed attachment files.",
    )

    attachment_text = (ROOT / "scripts/services/attachment_service.gd").read_text(encoding="utf-8")
    for marker_text in (
        "static func import_file(",
        "static func create_note(",
        "static func context_report_for_workspace(",
        "static func image_data_url(",
    ):
        require(marker_text in attachment_text, f"Attachment service is missing {marker_text}")
    require(
        "MAX_TEXT_FILE_BYTES := 4 * 1024 * 1024" in attachment_text,
        "Attachment text preprocessing safety limit is missing.",
    )
    require(
        "MAX_VISION_IMAGE_BYTES := 25 * 1024 * 1024" in attachment_text,
        "Vision image safety limit is missing.",
    )

    generation_text = (ROOT / "scripts/services/generation_service.gd").read_text(encoding="utf-8")
    require(
        "func queue_vision_analysis(" in generation_text,
        "Vision analysis generation workflow is missing.",
    )
    require(
        '"type": "image_url"' in generation_text,
        "Vision analysis does not send OpenAI-compatible image_url content.",
    )
    require(
        generation_text.count("ENABLED ATTACHMENT CONTEXT") >= 6,
        "Attachment context is not wired into the expected generation workflows.",
    )

    image_generation_text = (ROOT / "scripts/services/image_generation_service.gd").read_text(encoding="utf-8")
    for marker_text in (
        "func generate(",
        "static func build_prompt(",
        '"/images/generations"',
        '"txt2img"',
        '"negative_prompt"',
        '"sampler_name"',
        '"cfg_scale"',
        '"seed"',
        '"batch_size"',
        "generation_batch_completed",
        "Marshalls.base64_to_raw",
        "decoded_image.save_png(",
    ):
        require(marker_text in image_generation_text, f"Image generation service is missing {marker_text}")
    require(
        '"provider": _pending_backend' in image_generation_text
        and '"backend": _pending_backend' in image_generation_text,
        "Generated image metadata does not record the selected image backend.",
    )
    require(
        "_extract_response_seeds(" in image_generation_text,
        "Stable Diffusion returned seeds are not captured for reproducible gallery records.",
    )

    capability_text = (ROOT / "scripts/services/image_capability_service.gd").read_text(encoding="utf-8")
    for marker_text in (
        "func fetch_capabilities(",
        '"sd-models"',
        '"samplers"',
        '"/models"',
        "capabilities_loaded",
    ):
        require(marker_text in capability_text, f"Image capability service is missing {marker_text}")

    workspace_text = (ROOT / "scripts/ui/workspace_view.gd").read_text(encoding="utf-8")
    require(
        "CCFAttachmentManagerWindow.new()" in workspace_text
        and 'attachments_button.text = "Vision / Attachments"' in workspace_text,
        "The workspace attachment manager entry point is missing.",
    )
    require(
        'job_type == "vision_analysis"' in workspace_text
        and 'metadata.get("preview_fields", [])' in workspace_text,
        "Vision results are not routed through the review-first generation preview.",
    )

    settings_view_text = (ROOT / "scripts/ui/settings_view.gd").read_text(encoding="utf-8")
    require(
        'intro.text = "Character AI providers"' in settings_view_text
        and "CCFImageProviderSettingsView.new()" in settings_view_text,
        "Settings does not separate character AI from image provider configuration.",
    )
    require(
        "Image generation profile" not in settings_view_text
        and 'form.add_child(_label("Image backend"))' not in settings_view_text,
        "Legacy image-provider controls are still mixed into the character AI form.",
    )

    image_provider_view_text = (ROOT / "scripts/ui/image_provider_settings_view.gd").read_text(encoding="utf-8")
    for marker_text in (
        'heading.text = "Image generation providers"',
        '"http://127.0.0.1:7860"',
        '"Server URL"',
        "_api_key_row.visible = not is_sd",
        "CCFSettingsService.create_image_profile(",
        "CCFSettingsService.replace_image_profile_by_id(",
    ):
        require(marker_text in image_provider_view_text, f"Image provider settings are missing {marker_text}")

    image_controller_text = (ROOT / "scripts/ui/image_generation_controller.gd").read_text(encoding="utf-8")
    require(
        "CCFSettingsService.image_profiles(_settings)" in image_controller_text
        and "CCFSettingsService.image_profile_by_id(" in image_controller_text,
        "Image Studio controller is not using the dedicated image provider collection.",
    )

    image_page_text = (ROOT / "scripts/ui/image_generation_page.gd").read_text(encoding="utf-8")
    require(
        'settings_button.text = "Manage Image Providers in Settings"' in image_page_text,
        "Image Studio is missing its Settings shortcut.",
    )
    require(
        "Server URL / port" not in image_page_text and "Save Connection" not in image_page_text,
        "Connection credentials are still embedded in Image Studio.",
    )

    main_page_text = (ROOT / "scripts/main_with_image_page.gd").read_text(encoding="utf-8")
    require(
        "CCFImageGenerationController.new()" in main_page_text
        and '_nav_buttons["image"]' in main_page_text
        and 'button.disabled = nav_id == "image"' in main_page_text,
        "Image Studio is not wired as a selected main navigation page with the dedicated controller.",
    )

    image_window_text = (ROOT / "scripts/ui/image_generation_window.gd").read_text(encoding="utf-8")
    for marker_text in (
        '"Set as Portrait"',
        'assets["generated_images"]',
        'assets["portrait"]',
        '"Discover Models / Samplers"',
        '"New Seed Variant"',
        "_current_generation_options(",
        "CCFImageCapabilityService.new()",
    ):
        require(marker_text in image_window_text, f"Image Studio is missing {marker_text}")

    release_text = (ROOT / "release.sh").read_text(encoding="utf-8")
    require(
        'DEFAULT_REPO_DIR="${HOME}/Projects/Character-Card-Forge-V2"' in release_text,
        "release.sh is missing the standard repository destination.",
    )
    require("rsync -a" in release_text, "release.sh is missing automatic repository sync.")
    require(
        "update_destination_main" in release_text and "working_copy_matches_ref" in release_text,
        "release.sh is missing automatic main fast-forward/reconciliation.",
    )
    require(
        "--exclude='.git/'" in release_text,
        "release.sh must protect the repository metadata during sync.",
    )
    require(
        "--delete" not in release_text,
        "release.sh must not delete repository-only files during its default sync.",
    )

    preset_text = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    for preset_name in ("Windows Desktop", "Linux x86_64", "macOS Universal"):
        require(f'name="{preset_name}"' in preset_text, f"Missing export preset {preset_name}.")
    require(
        preset_text.count(f'application/file_version="{version}"') == 1,
        "Windows file version is not synchronised.",
    )
    require(
        preset_text.count(f'application/product_version="{version}"') == 1,
        "Windows product version is not synchronised.",
    )
    require(
        preset_text.count(f'application/short_version="{version}"') == 1,
        "macOS short version is not synchronised.",
    )
    require(
        preset_text.count(f'application/version="{version}"') == 1,
        "macOS build version is not synchronised.",
    )

    json_files = sorted((ROOT / "data").rglob("*.json"))
    require(bool(json_files), "No bundled JSON data files were found.")
    for json_path in json_files:
        try:
            json.loads(json_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
            raise SystemExit(
                f"Validation failed: invalid JSON in {json_path.relative_to(ROOT)}: {error}"
            ) from error

    if args.tag:
        expected_tag = f"v{version}"
        require(
            args.tag == expected_tag,
            f"Release tag {args.tag!r} does not match VERSION ({expected_tag}).",
        )

    print(
        f"Validated Character Card Forge v{version}: version metadata, three export presets, "
        f"Vision/Attachments, separated character/image providers, OpenAI Images, Forge/A1111, "
        f"and {len(json_files)} JSON files."
    )


if __name__ == "__main__":
    main()
