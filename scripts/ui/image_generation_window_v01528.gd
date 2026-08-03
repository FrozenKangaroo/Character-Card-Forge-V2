class_name CCFImageGenerationWindowV01528
extends "res://scripts/ui/image_generation_window_v01526.gd"

var _preferred_project_v01528: Dictionary = {}
var _preferred_character_id_v01528 := ""


func open_studio() -> void:
	_reload_settings()
	_refresh_profiles()
	_refresh_projects()
	CCFToolWindowStateService.show_window(self, WINDOW_STATE_ID, Vector2i(1240, 860))


func update_settings_v01528(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	if _profile_selector != null:
		_refresh_profiles()


func sync_saved_project_v01528(
	project: Dictionary, preferred_character_id: String = ""
) -> void:
	if project.is_empty():
		return
	_preferred_project_v01528 = project.duplicate(true)
	_preferred_character_id_v01528 = preferred_character_id.strip_edges()
	if _preferred_character_id_v01528.is_empty():
		_preferred_character_id_v01528 = CCFStorageService.active_character_id(
			_preferred_project_v01528
		)
	if _project_selector != null:
		_refresh_projects()


func current_project_id_v01528() -> String:
	return str(_project.get("project_id", ""))


func current_profile_id_v01528() -> String:
	if _profile_selector == null or _profile_selector.selected < 0:
		return ""
	return str(_profile_selector.get_selected_metadata())


func _refresh_profiles() -> void:
	if _profile_selector == null:
		return
	var previous_profile_id := ""
	if _profile_selector.selected >= 0:
		previous_profile_id = str(_profile_selector.get_selected_metadata())
	var default_profile_id := CCFSettingsService.role_profile_id(
		_settings, CCFSettingsService.ROLE_IMAGE
	)
	var target_profile_id := (
		previous_profile_id
		if not previous_profile_id.is_empty()
		else default_profile_id
	)
	_loading_controls = true
	_profile_selector.clear()
	var selected_index := 0
	var profiles := CCFSettingsService.image_profiles(_settings)
	for raw_profile in profiles:
		if not raw_profile is Dictionary:
			continue
		var profile: Dictionary = raw_profile
		var profile_id := str(profile.get("id", "image_default"))
		_profile_selector.add_item(str(profile.get("name", "Image Provider")))
		var item_index := _profile_selector.item_count - 1
		_profile_selector.set_item_metadata(item_index, profile_id)
		if profile_id == target_profile_id:
			selected_index = item_index
	if _profile_selector.item_count > 0:
		_profile_selector.select(selected_index)
	_loading_controls = false
	_load_selected_profile_settings()


func _selected_profile() -> Dictionary:
	if _profile_selector == null or _profile_selector.selected < 0:
		return CCFSettingsService.profile_for_role(
			_settings, CCFSettingsService.ROLE_IMAGE
		)
	return CCFSettingsService.image_profile_by_id(
		_settings, str(_profile_selector.get_selected_metadata())
	)


func _load_selected_profile_settings() -> void:
	super._load_selected_profile_settings()
	var cached := CCFImageCapabilityCacheServiceV01528.capabilities_from_profile(
		_selected_profile()
	)
	_populate_discovery_list(
		_fetched_models,
		cached.get("models", []),
		"Choose discovered model / checkpoint…",
		"No cached models — run Discover"
	)
	_populate_discovery_list(
		_fetched_samplers,
		cached.get("samplers", []),
		"Choose discovered sampler…",
		"No cached samplers — run Discover"
	)


func _save_image_defaults() -> void:
	if _profile_selector == null or _profile_selector.selected < 0:
		_status.text = "Select an Image provider before saving defaults."
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	var profile := CCFSettingsService.image_profile_by_id(
		_settings, profile_id
	).duplicate(true)
	profile["model"] = _model_edit.text.strip_edges()
	profile["image_settings"] = _current_generation_options(
		"profile_default", ""
	)
	CCFSettingsService.replace_image_profile_by_id(
		_settings, profile_id, profile
	)
	var save_result := CCFSettingsService.save_settings(_settings)
	if bool(save_result.get("ok", false)):
		_settings = CCFSettingsService.load_settings()
		_status.text = "Saved image-generation defaults to %s." % str(
			profile.get("name", "Image Provider")
		)
	else:
		_status.text = str(
			save_result.get("error", "Could not save image defaults.")
		)


func _on_capabilities_loaded(capabilities: Dictionary) -> void:
	super._on_capabilities_loaded(capabilities)
	if _profile_selector == null or _profile_selector.selected < 0:
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	var cache_result := CCFImageCapabilityCacheServiceV01528.store_for_profile(
		_settings, profile_id, capabilities
	)
	if not bool(cache_result.get("ok", false)):
		_status.text += " Discovery succeeded, but the list could not be cached: %s" % str(
			cache_result.get("error", "Unknown settings error")
		)
		return
	_settings = cache_result.get("settings", _settings).duplicate(true)
	_status.text += " The discovered list was saved for this Image provider."


func _refresh_projects() -> void:
	if _project_selector == null:
		return
	var previous_project_id := str(_project.get("project_id", ""))
	var preferred_project_id := str(
		_preferred_project_v01528.get("project_id", "")
	)
	var target_project_id := (
		preferred_project_id
		if not preferred_project_id.is_empty()
		else previous_project_id
	)
	_loading_controls = true
	_project_selector.clear()
	var rows := CCFStorageService.list_projects()
	var selected_index := -1
	var listed_ids: Dictionary = {}
	for raw_row in rows:
		if not raw_row is Dictionary:
			continue
		var row: Dictionary = raw_row
		var project_id := str(row.get("project_id", ""))
		if project_id.is_empty():
			continue
		listed_ids[project_id] = true
		_project_selector.add_item(str(row.get("name", "Untitled Project")))
		var item_index := _project_selector.item_count - 1
		_project_selector.set_item_metadata(item_index, project_id)
		if project_id == target_project_id:
			selected_index = item_index

	# A freshly saved Workspace project is authoritative even if a platform-level
	# directory listing has not reflected the new folder yet in this frame.
	if (
		not preferred_project_id.is_empty()
		and not listed_ids.has(preferred_project_id)
	):
		var metadata: Dictionary = _preferred_project_v01528.get(
			"metadata", {}
		)
		_project_selector.add_item(
			str(metadata.get("name", "Untitled Project"))
		)
		selected_index = _project_selector.item_count - 1
		_project_selector.set_item_metadata(
			selected_index, preferred_project_id
		)
	_loading_controls = false

	if _project_selector.item_count == 0:
		_project.clear()
		_active_character_id = ""
		_character_selector.clear()
		_refresh_gallery()
		_status.text = "Reloaded projects: no saved character projects were found."
		return
	if selected_index < 0:
		selected_index = 0
	_project_selector.select(selected_index)
	var selected_project_id := str(
		_project_selector.get_item_metadata(selected_index)
	)
	if (
		selected_project_id == preferred_project_id
		and not _preferred_project_v01528.is_empty()
	):
		_load_project_snapshot_v01528(
			_preferred_project_v01528,
			_preferred_character_id_v01528
		)
	else:
		_load_project(selected_project_id)
	_status.text = "Reloaded %d saved project(s). Selected %s." % [
		_project_selector.item_count,
		_project_selector.get_item_text(selected_index)
	]


func _load_project_snapshot_v01528(
	project: Dictionary, preferred_character_id: String = ""
) -> void:
	if project.is_empty():
		return
	_project = project.duplicate(true)
	_active_character_id = preferred_character_id.strip_edges()
	if (
		_active_character_id.is_empty()
		or CCFStorageService.get_character(
			_project, _active_character_id
		).is_empty()
	):
		_active_character_id = CCFStorageService.active_character_id(_project)
	_refresh_characters()
	_build_prompt_from_character()
	_refresh_gallery()
	_select_project_id_v01528(str(_project.get("project_id", "")))


func _select_project_id_v01528(project_id: String) -> void:
	if _project_selector == null:
		return
	for item_index in range(_project_selector.item_count):
		if str(_project_selector.get_item_metadata(item_index)) == project_id:
			_project_selector.select(item_index)
			return


func _build_prompt_from_character() -> void:
	if _prompt_edit == null or _status == null:
		return
	if _project.is_empty():
		_status.text = "Build Prompt could not run because no saved project is selected. Reload Projects or save/open a Workspace project first."
		return
	if _active_character_id.is_empty():
		_status.text = "Build Prompt could not run because the selected project has no active character."
		return
	var character := CCFStorageService.get_character(
		_project, _active_character_id
	)
	if character.is_empty():
		_status.text = "Build Prompt could not run because the selected character is no longer present in the project."
		return
	var built_prompt := CCFImageGenerationService.build_prompt(
		_project,
		_active_character_id,
		_selected_prompt_style(),
		_extra_direction_edit.text
	)
	if built_prompt.strip_edges().is_empty():
		_status.text = "Build Prompt found no usable character description, personality, scenario, or visual direction."
		return
	_prompt_edit.text = built_prompt
	_status.text = "Built the image prompt from the selected saved character."
