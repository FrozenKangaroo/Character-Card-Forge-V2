extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0180_HOTFIX2_UPDATE_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	if not _require(
		CCFUpdateServiceV0180Hotfix2.compare_versions_v0180_hotfix2(
			"v0.18.1", "0.18.0"
		) > 0
		and CCFUpdateServiceV0180Hotfix2.compare_versions_v0180_hotfix2(
			"0.18.0-hotfix2", "0.18.0-hotfix1"
		) > 0
		and CCFUpdateServiceV0180Hotfix2.compare_versions_v0180_hotfix2(
			"0.18.0", "0.18.0-rc.1"
		) > 0
		and CCFUpdateServiceV0180Hotfix2.compare_versions_v0180_hotfix2(
			"not-a-version", "0.18.0"
		) == -99,
		"Release comparison must handle normal, hotfix, prerelease and invalid versions."
	):
		return

	var service := CCFUpdateServiceV0180Hotfix2.new()
	root.add_child(service)
	var release_payload := {
		"tag_name": "v0.18.1",
		"name": "Character Card Forge v0.18.1",
		"body": "Revision safety and recovery.",
		"draft": false,
		"prerelease": false,
		"published_at": "2026-09-09T00:00:00Z",
		"html_url": (
			"https://github.com/FrozenKangaroo/Character-Card-Forge-V2/releases/tag/v0.18.1"
		),
		"assets": [
			{
				"name": "CharacterCardForge-v0.18.1-windows-x86_64.zip",
				"browser_download_url": (
					"https://github.com/FrozenKangaroo/Character-Card-Forge-V2/releases/download/v0.18.1/CharacterCardForge-v0.18.1-windows-x86_64.zip"
				),
				"state": "uploaded",
				"size": 1000,
				"digest": "sha256:windows"
			},
			{
				"name": "CharacterCardForge-v0.18.1-linux-x86_64.tar.gz",
				"browser_download_url": (
					"https://github.com/FrozenKangaroo/Character-Card-Forge-V2/releases/download/v0.18.1/CharacterCardForge-v0.18.1-linux-x86_64.tar.gz"
				),
				"state": "uploaded",
				"size": 2000,
				"digest": "sha256:linux"
			},
			{
				"name": "CharacterCardForge-v0.18.1-macos-universal-unsigned.zip",
				"browser_download_url": (
					"https://github.com/FrozenKangaroo/Character-Card-Forge-V2/releases/download/v0.18.1/CharacterCardForge-v0.18.1-macos-universal-unsigned.zip"
				),
				"state": "uploaded",
				"size": 3000,
				"digest": "sha256:macos"
			}
		]
	}
	var result := service.process_release_response_v0180_hotfix2(
		"0.18.0",
		200,
		PackedStringArray(['ETag: "release-181"']),
		JSON.stringify(release_payload).to_utf8_buffer()
	)
	var asset: Dictionary = result.get("asset", {})
	if not _require(
		bool(result.get("ok", false))
		and bool(result.get("update_available", false))
		and str(result.get("latest_version", "")) == "0.18.1"
		and str(result.get("etag", "")) == '"release-181"'
		and str(asset.get("name", "")).contains("linux-x86_64"),
		"A valid newer GitHub release must select the current platform package."
	):
		return

	var unchanged := service.process_release_response_v0180_hotfix2(
		"0.18.1",
		304,
		PackedStringArray(),
		PackedByteArray(),
		result.get("release", {})
	)
	if not _require(
		bool(unchanged.get("ok", false))
		and not bool(unchanged.get("update_available", true)),
		"A conditional 304 response must reuse the bounded cached release."
	):
		return

	var rate_limited := service.process_release_response_v0180_hotfix2(
		"0.18.0", 429, PackedStringArray(), PackedByteArray()
	)
	if not _require(
		not bool(rate_limited.get("ok", true))
		and str(rate_limited.get("error", "")).contains("limited"),
		"GitHub rate limiting must fail without retrying or exposing technical payloads."
	):
		return

	var unsafe_payload := release_payload.duplicate(true)
	unsafe_payload["html_url"] = "https://example.invalid/releases/tag/v0.18.1"
	if not _require(
		CCFUpdateServiceV0180Hotfix2.normalise_release_v0180_hotfix2(
			unsafe_payload
		).is_empty(),
		"Release and download links must remain pinned to the official repository."
	):
		return

	var default_settings := CCFSettingsService.default_settings()
	if not _require(
		int(default_settings.get("format_version", 0)) == 7
		and bool(default_settings.get("updates", {}).get("automatic_checks", false)),
		"Settings format 7 must enable the disclosed automatic check by default."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.18.0-hotfix2 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var settings_value: Variant = app.get("_settings_view")
	if not _require(
		settings_value is CCFSettingsV0180Hotfix2View,
		"The live app must install the Updates-aware settings view."
	):
		return
	var settings_view := settings_value as CCFSettingsV0180Hotfix2View
	var live_service := settings_view.update_service_v0180_hotfix2()
	var capabilities := live_service.update_capabilities_v0180_hotfix2()
	if not _require(
		bool(capabilities.get("automatic_packaged_startup_check", false))
		and not bool(capabilities.get("silent_install", true))
		and not bool(capabilities.get("provider_credentials_used", true))
		and not live_service.is_busy_v0180_hotfix2(),
		"The live updater must be packaged-only on startup, credential-free and non-destructive."
	):
		return
	var found_updates_tab := false
	for index in range(settings_view._tabs.get_tab_count()):
		if settings_view._tabs.get_tab_title(index) == "Updates":
			found_updates_tab = true
			break
	if not _require(
		found_updates_tab,
		"Settings must expose a dedicated Updates tab."
	):
		return

	app.call("_on_update_state_changed_v0180_hotfix2", result)
	var notice_value: Variant = app.get("_update_notice_v0180_hotfix2")
	if not _require(
		notice_value is Button
		and notice_value.visible
		and notice_value.text.contains("0.18.1"),
		"A newer published release must produce a visible in-app update notice."
	):
		return
	var version_label_found := false
	for node in app.find_children("*", "Label", true, false):
		if not node is Label or not node.text.begins_with("Godot rewrite • v"):
			continue
		var displayed_version: String = str(node.text).trim_prefix(
			"Godot rewrite • v"
		)
		version_label_found = (
			CCFUpdateServiceV0180Hotfix2.compare_versions_v0180_hotfix2(
				displayed_version, "0.18.0-hotfix2"
			) >= 0
		)
		break
	if not _require(
		version_label_found,
		"The development build label must identify hotfix2 or a newer compatible build."
	):
		return

	app.queue_free()
	service.queue_free()
	await process_frame
	print("v0.18.0-hotfix2 GitHub update-check regression passed")
	quit(0)
