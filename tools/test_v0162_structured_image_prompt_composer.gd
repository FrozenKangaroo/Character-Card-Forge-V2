extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0162_STRUCTURED_PROMPT_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var catalog_result := CCFImagePromptComposerServiceV0162.load_catalog()
	if not _require(bool(catalog_result.get("ok", false)), "The v0.16.2 creative prompt catalog must load."):
		return
	var catalog_variant: Variant = catalog_result.get("catalog", {})
	if not _require(catalog_variant is Dictionary, "The creative prompt catalog must be a Dictionary."):
		return
	var catalog: Dictionary = catalog_variant
	if not _require(int(catalog.get("format_version", 0)) == 1, "The creative catalog must remain versioned."):
		return
	if not _require((catalog.get("categories", []) as Array).size() >= 7, "The catalog must expose the planned creative categories."):
		return

	var selections := CCFImagePromptComposerServiceV0162.default_selection(catalog)
	var categories: Dictionary = selections.get("categories", {})
	categories["visual_style"] = "anime"
	categories["medium"] = "digital_painting"
	categories["composition"] = "full_body"
	categories["lighting"] = "golden_hour"
	categories["palette"] = "warm"
	categories["material"] = "fabric"
	categories["atmosphere"] = "rain"
	selections["modifiers"] = ["rich_detail", "clean_background"]
	if not _require(CCFImagePromptComposerServiceV0162.selection_is_valid(selections, catalog), "A valid structured creative selection must validate."):
		return
	var composed := CCFImagePromptComposerServiceV0162.compose(
		"Miya standing beside a city train",
		selections,
		catalog
	)
	var prompt := str(composed.get("prompt", ""))
	for expected_phrase in [
		"Miya standing beside a city train",
		"anime style",
		"digital painting",
		"full-body composition",
		"golden-hour lighting",
		"warm color palette",
		"detailed fabric textures",
		"falling rain",
		"rich fine detail",
		"clean uncluttered background"
	]:
		if not _require(prompt.contains(expected_phrase), "Composed prompt is missing expected contribution: %s" % expected_phrase):
			return
	if not _require(prompt.find("anime style") < prompt.find("digital painting"), "Visual Style must compose before Medium."):
		return
	if not _require(prompt.find("digital painting") < prompt.find("full-body composition"), "Medium must compose before Camera / Composition."):
		return
	if not _require(prompt.find("full-body composition") < prompt.find("golden-hour lighting"), "Camera / Composition must compose before Lighting."):
		return
	if not _require(prompt.find("golden-hour lighting") < prompt.find("warm color palette"), "Lighting must compose before Colour Palette."):
		return

	var recomposed := CCFImagePromptComposerServiceV0162.compose(prompt, selections, catalog)
	var prompt_again := str(recomposed.get("prompt", ""))
	if not _require(prompt_again.count("anime style") == 1, "Reapplying structured controls must not duplicate exact creative phrases."):
		return
	if not _require((composed.get("contributions", []) as Array).size() == 9, "Contribution metadata must expose every selected structured addition."):
		return

	CCFStorageService.ensure_directories()
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.16.2 main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v0162"), "The active application shell must identify v0.16.2."):
		return
	var image_window_value: Variant = app.get("_image_generation_window")
	if not _require(image_window_value is CCFImageGenerationWindowV0162, "The real application must install the v0.16.2 Image Studio."):
		return
	var image_window := image_window_value as CCFImageGenerationWindowV0162
	var advertised := image_window.structured_prompt_capabilities_v0162()
	if not _require(bool(advertised.get("provider_independent", false)), "The live Studio must advertise provider-independent creative intent."):
		return
	if not _require(bool(advertised.get("external_versioned_catalog", false)), "The live Studio must use the external versioned catalog architecture."):
		return
	if not _require(image_window.structured_prompt_surface_ready_v0162(), "The v0.16.2 controller must retain a live structured prompt surface."):
		return
	if not _require(app.find_child("ImageStudioCreativeControlsV0162", true, false) != null, "The mounted Image Studio must expose structured creative controls."):
		return
	if not _require(app.find_child("CreativeSelector_visual_style_V0162", true, false) != null, "The mounted Image Studio must expose a Visual Style selector."):
		return
	if not _require(app.find_child("CreativeSelector_lighting_V0162", true, false) != null, "The mounted Image Studio must expose a Lighting selector."):
		return
	if not _require(app.find_child("CreativeModifier_motion_blur_V0162", true, false) != null, "The mounted Image Studio must expose multi-select creative modifiers."):
		return
	if not _require(app.find_child("ImageStudioComposePromptButtonV0162", true, false) != null, "The mounted Image Studio must expose local prompt composition."):
		return
	if not _require(image_window.capability_surface_ready_v0161(), "v0.16.2 must preserve the v0.16.1 capability inspector."):
		return

	app.queue_free()
	await process_frame
	print("v0.16.2 structured Image prompt composer regression passed")
	quit(0)
