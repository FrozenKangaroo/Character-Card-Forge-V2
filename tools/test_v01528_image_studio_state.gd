extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_prepare_settings_v01528()
	var first_project := _create_saved_project_v01528(
		"First Fresh Project", "Ava", "A tall woman with long silver hair and blue eyes."
	)
	await _test_live_image_studio_v01528(first_project)
	print("v0.15.28 Image Studio live state regression passed")
	quit(0)


func _prepare_settings_v01528() -> void:
	var settings := CCFSettingsService.default_settings()
	var ai_profile: Dictionary = settings.get("api_profiles", [])[0].duplicate(true)
	ai_profile["id"] = "text_only_profile"
	ai_profile["name"] = "Text Model — must not appear in Image Studio"
	settings["api_profiles"] = [ai_profile]
	settings["active_api_profile_id"] = "text_only_profile"
	var image_profile: Dictionary = CCFSettingsService.image_profiles(settings)[0].duplicate(true)
	image_profile["id"] = "image_sd_profile"
	image_profile["name"] = "Local SD Image Provider"
	image_profile["model"] = "cached_checkpoint.safetensors"
	settings["image_profiles"] = [image_profile]
	CCFSettingsService.set_role_profile(
		settings, CCFSettingsService.ROLE_IMAGE, "image_sd_profile"
	)
	var save_result := CCFSettingsService.save_settings(settings)
	assert(bool(save_result.get("ok", false)), "The Image Studio fixture settings must save.")
	var cache_result := CCFImageCapabilityCacheServiceV01528.store_for_profile(
		CCFSettingsService.load_settings(),
		"image_sd_profile",
		{
			"backend": CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111,
			"backend_label": "Stable Diffusion Forge / Automatic1111",
			"models": ["cached_checkpoint.safetensors", "second_checkpoint.safetensors"],
			"samplers": ["Euler a", "DPM++ 2M"],
			"supports_sampler": true,
			"supports_steps": true,
			"supports_cfg_scale": true,
			"supports_seed": true
		}
	)
	assert(bool(cache_result.get("ok", false)), "Discovered Image capabilities must persist per Image profile.")


func _create_saved_project_v01528(
	project_name: String, character_name: String, description: String
) -> Dictionary:
	var project := CCFStorageService.new_project()
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["name"] = project_name
	project["metadata"] = metadata
	var characters: Array = project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[0].duplicate(true)
	var character_metadata: Dictionary = character.get("metadata", {}).duplicate(true)
	character_metadata["name"] = character_name
	character["metadata"] = character_metadata
	var card: Dictionary = character.get("character", {}).duplicate(true)
	card["name"] = character_name
	card["description"] = description
	card["personality"] = "Calm, observant, and quietly confident."
	card["scenario"] = "Standing beneath city lights after rain."
	character["character"] = card
	characters[0] = character
	project["characters"] = characters
	var save_result := CCFStorageService.save_project(project)
	assert(bool(save_result.get("ok", false)), "The freshly generated Workspace project must save.")
	return project


func _test_live_image_studio_v01528(first_project: Dictionary) -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "v0.15.28 must keep the main scene loadable.")
	var app := packed.instantiate()
	assert(app != null, "v0.15.28 main scene must instantiate.")
	get_root().add_child(app)
	for _frame in range(6):
		await process_frame

	var image_window := _find_image_window_v01528(app)
	assert(image_window != null, "The live app must install CCFImageGenerationWindowV01528.")
	var settings_view := _find_settings_v01528(app)
	assert(settings_view != null, "The live app must install CCFSettingsV01528View.")

	image_window.sync_saved_project_v01528(
		first_project, CCFStorageService.active_character_id(first_project)
	)
	await process_frame
	assert(
		image_window.current_project_id_v01528() == str(first_project.get("project_id", "")),
		"A saved Workspace project must become Image Studio's live selected project without restarting."
	)
	var project_selector := image_window.get("_project_selector") as OptionButton
	assert(
		_option_has_metadata_v01528(project_selector, str(first_project.get("project_id", ""))),
		"The freshly saved project must appear in the Image Studio dropdown immediately."
	)

	var prompt_edit := image_window.get("_prompt_edit") as TextEdit
	assert(prompt_edit != null and not prompt_edit.text.strip_edges().is_empty(), "Build Prompt from Character must produce text for a valid saved character.")
	assert(prompt_edit.text.contains("Ava"), "The built Image prompt must use the selected character rather than stale project state.")

	var profile_selector := image_window.get("_profile_selector") as OptionButton
	assert(profile_selector.item_count == 1, "Image Studio must enumerate Image profiles, not Character Text/Vision profiles.")
	assert(profile_selector.get_item_text(0) == "Local SD Image Provider", "The Image profile name must populate Image Studio.")
	assert(image_window.current_profile_id_v01528() == "image_sd_profile", "Image Studio must resolve the configured Image role through image_profile_by_id().")
	var fetched_models := image_window.get("_fetched_models") as OptionButton
	var fetched_samplers := image_window.get("_fetched_samplers") as OptionButton
	assert(_option_has_text_v01528(fetched_models, "cached_checkpoint.safetensors"), "Cached discovered checkpoints must populate Image Studio.")
	assert(_option_has_text_v01528(fetched_samplers, "DPM++ 2M"), "Cached discovered samplers must populate Image Studio.")

	# Reproduce Workspace Save after Image Studio is already alive. The new project
	# must appear immediately through the project_saved path, not after app restart.
	var second_project := _create_saved_project_v01528(
		"Second Fresh Project", "Mina", "A short-haired woman in a red coat."
	)
	app.call("_on_project_saved", second_project)
	await process_frame
	assert(
		image_window.current_project_id_v01528() == str(second_project.get("project_id", "")),
		"Workspace Save must push the newly saved project directly into Image Studio."
	)
	assert(
		_option_has_metadata_v01528(project_selector, str(second_project.get("project_id", ""))),
		"The project dropdown must include a project saved after Image Studio startup."
	)
	image_window.call("_refresh_projects")
	await process_frame
	assert(
		_option_has_metadata_v01528(project_selector, str(second_project.get("project_id", ""))),
		"Reload Projects must retain and rescan the freshly saved project."
	)

	# Settings discovery must persist and notify the live Image Studio.
	var image_settings := settings_view.get("_image_settings_view") as CCFImageProviderSettingsViewV01528
	assert(image_settings != null, "Settings must use the persistent v0.15.28 Image provider view.")
	image_settings.call(
		"_on_capabilities_loaded",
		{
			"backend": CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111,
			"backend_label": "Stable Diffusion Forge / Automatic1111",
			"models": ["newly_discovered_checkpoint.safetensors"],
			"samplers": ["Restart Sampler"],
			"supports_sampler": true,
			"supports_steps": true,
			"supports_cfg_scale": true,
			"supports_seed": true
		}
	)
	for _frame in range(3):
		await process_frame
	assert(_option_has_text_v01528(fetched_models, "newly_discovered_checkpoint.safetensors"), "Settings discovery must refresh the live Image Studio model list.")
	assert(_option_has_text_v01528(fetched_samplers, "Restart Sampler"), "Settings discovery must refresh the live Image Studio sampler list.")

	# Silent prompt failures are forbidden.
	image_window.set("_project", {})
	image_window.set("_active_character_id", "")
	image_window.call("_build_prompt_from_character")
	var status := image_window.get("_status") as Label
	assert(status.text.contains("no saved project is selected"), "Build Prompt must explain missing project state instead of silently returning.")

	app.queue_free()
	await process_frame


func _option_has_metadata_v01528(selector: OptionButton, expected: String) -> bool:
	if selector == null:
		return false
	for index in range(selector.item_count):
		if str(selector.get_item_metadata(index)) == expected:
			return true
	return false


func _option_has_text_v01528(selector: OptionButton, expected: String) -> bool:
	if selector == null:
		return false
	for index in range(selector.item_count):
		if selector.get_item_text(index) == expected:
			return true
	return false


func _find_image_window_v01528(root: Node) -> CCFImageGenerationWindowV01528:
	if root is CCFImageGenerationWindowV01528:
		return root as CCFImageGenerationWindowV01528
	for child in root.get_children():
		if child is Node:
			var found := _find_image_window_v01528(child)
			if found != null:
				return found
	return null


func _find_settings_v01528(root: Node) -> CCFSettingsV01528View:
	if root is CCFSettingsV01528View:
		return root as CCFSettingsV01528View
	for child in root.get_children():
		if child is Node:
			var found := _find_settings_v01528(child)
			if found != null:
				return found
	return null
