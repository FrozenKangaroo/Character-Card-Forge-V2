extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0163_IMAGE_STUDIO_TABS_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	CCFStorageService.ensure_directories()
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.16.3 main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v0163"), "The active application shell must identify v0.16.3."):
		return
	var value: Variant = app.get("_image_generation_window")
	if not _require(value is CCFImageGenerationWindowV0163, "The real application must install the v0.16.3 Image Studio."):
		return
	var studio := value as CCFImageGenerationWindowV0163
	if not _require(studio.tabbed_layout_ready_v0163(), "The v0.16.3 Image Studio tab layout must be ready."):
		return
	var advertised := studio.tabbed_image_studio_capabilities_v0163()
	if not _require(bool(advertised.get("advanced_optional_tab", false)), "v0.16.3 must advertise progressive disclosure for technical controls."):
		return
	if not _require(app.find_child("ImageStudioTabsV0163", true, false) != null, "The mounted Image Studio must expose its TabContainer."):
		return
	if not _require(app.find_child("ImageStudioCreativeControlsV0162", true, false) != null, "The v0.16.2 creative composer must survive the tab reorganisation."):
		return
	if not _require(app.find_child("ImageStudioCapabilitySummaryV0161", true, false) != null, "The v0.16.1 capability surface must survive inside Advanced."):
		return
	var tabs := app.find_child("ImageStudioTabsV0163", true, false) as TabContainer
	if not _require(tabs != null and tabs.get_tab_count() == 3, "Image Studio must expose exactly three workflow tabs in v0.16.3."):
		return
	if not _require(tabs.get_tab_title(0) == "Prompt & Results", "First tab must keep the core prompt/results workflow primary."):
		return
	if not _require(tabs.get_tab_title(1) == "Creative", "Second tab must contain structured creative intent."):
		return
	if not _require(tabs.get_tab_title(2) == "Advanced", "Third tab must contain optional technical controls."):
		return
	app.queue_free()
	await process_frame
	print("v0.16.3 tabbed Image Studio regression passed")
	quit(0)
