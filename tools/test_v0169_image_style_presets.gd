extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0169_IMAGE_STYLE_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var catalog_result := CCFImagePromptComposerServiceV0162.load_catalog()
	if not _require(bool(catalog_result.get("ok", false)), "Creative prompt catalog must load for style preset validation."):
		return
	var creative_catalog: Dictionary = catalog_result.get("catalog", {})
	var builtins := CCFImageStylePresetServiceV0169.load_builtin_presets()
	if not _require(builtins.size() >= 4, "v0.16.9 must expose several external built-in Image Style presets."):
		return
	for preset in builtins:
		if not _require(
			CCFImageStylePresetServiceV0169.selection_is_compatible(preset.get("selection", {}), creative_catalog),
			"Every built-in Image Style preset must reference valid v0.16.2 creative catalog IDs."
		):
			return

	var selection := {
		"categories": {
			"visual_style": "anime",
			"medium": "digital_painting",
			"composition": "close_up",
			"lighting": "rim",
			"palette": "pastel",
			"material": "fabric",
			"atmosphere": "none"
		},
		"modifiers": ["rich_detail", "sharp_focus"]
	}
	var user_preset := CCFImageStylePresetServiceV0169.make_preset(
		"Regression Style",
		selection,
		"v0169_regression_style"
	)
	if not _require(
		CCFImageStylePresetServiceV0169.selection_is_compatible(user_preset.get("selection", {}), creative_catalog),
		"A valid captured structured Creative selection must remain portable."
	):
		return
	var save_global := CCFImageStylePresetServiceV0169.upsert_global_preset(user_preset)
	if not _require(bool(save_global.get("ok", false)), "Global Image Style presets must persist."):
		return
	var found_global := false
	for preset in CCFImageStylePresetServiceV0169.load_global_presets():
		if str(preset.get("id", "")) == "v0169_regression_style":
			found_global = true
			break
	if not _require(found_global, "The saved Global preset must round-trip from user storage."):
		return

	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var project_preset := CCFImageStylePresetServiceV0169.make_preset(
		"Project Identity", selection, "v0169_project_style"
	)
	CCFImageStylePresetServiceV0169.set_project_default(project, project_preset)
	if not _require(
		str(CCFImageStylePresetServiceV0169.effective_default(project, character_id).get("id", "")) == "v0169_project_style",
		"Project visual identity must be the effective default when the character has no override."
	):
		return
	var character_selection := selection.duplicate(true)
	character_selection["categories"]["visual_style"] = "manga"
	var character_preset := CCFImageStylePresetServiceV0169.make_preset(
		"Character Override", character_selection, "v0169_character_style"
	)
	if not _require(
		CCFImageStylePresetServiceV0169.set_character_default(project, character_id, character_preset),
		"Per-character Image Style defaults must be writable."
	):
		return
	if not _require(
		str(CCFImageStylePresetServiceV0169.effective_default(project, character_id).get("id", "")) == "v0169_character_style",
		"Character Image Style defaults must override project visual identity."
	):
		return
	CCFImageStylePresetServiceV0169.clear_character_default(project, character_id)
	if not _require(
		str(CCFImageStylePresetServiceV0169.effective_default(project, character_id).get("id", "")) == "v0169_project_style",
		"Clearing the character override must reveal the project identity again."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.16.9 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v0169"), "The active application shell must identify v0.16.9."):
		return
	var studio_value: Variant = app.get("_image_generation_window")
	if not _require(studio_value is CCFImageGenerationWindowV0169, "The real application must install the v0.16.9 Image Studio."):
		return
	var studio := studio_value as CCFImageGenerationWindowV0169
	if not _require(studio.style_preset_surface_ready_v0169(), "The live Image Studio must expose the v0.16.9 style-preset surface."):
		return
	var capabilities := studio.style_preset_capabilities_v0169()
	if not _require(bool(capabilities.get("project_visual_identity", false)), "The style surface must advertise project visual identity."):
		return
	if not _require(bool(capabilities.get("per_character_defaults", false)), "The style surface must advertise per-character defaults."):
		return
	if not _require(bool(capabilities.get("technical_provider_settings_excluded", false)), "Style presets must explicitly exclude technical provider/model settings."):
		return
	if not _require(app.has_method("_update_build_version_label_v0168"), "v0.16.9 must preserve the v0.16.8 Image Input shell through inheritance."):
		return

	app.queue_free()
	await process_frame
	CCFImageStylePresetServiceV0169.delete_global_preset("v0169_regression_style")
	print("v0.16.9 Image Style preset regression passed")
	quit(0)
