class_name CCFImageGenerationWindow
extends Window

signal project_changed(project: Dictionary)

const WINDOW_STATE_ID := "image_generation"

var _settings: Dictionary = {}
var _project: Dictionary = {}
var _active_character_id := ""
var _image_service: CCFImageGenerationService
var _capability_service: CCFImageCapabilityService
var _project_selector: OptionButton
var _character_selector: OptionButton
var _profile_selector: OptionButton
var _backend_label: Label
var _model_edit: LineEdit
var _fetched_models: OptionButton
var _discover_button: Button
var _image_size_edit: LineEdit
var _prompt_style_selector: OptionButton
var _batch_size: SpinBox
var _sampler_edit: LineEdit
var _fetched_samplers: OptionButton
var _steps: SpinBox
var _cfg_scale: SpinBox
var _seed: SpinBox
var _extra_direction_edit: TextEdit
var _prompt_edit: TextEdit
var _negative_prompt_edit: TextEdit
var _gallery: ItemList
var _preview: TextureRect
var _preview_info: Label
var _status: Label
var _generate_button: Button
var _cancel_button: Button
var _set_portrait_button: Button
var _regenerate_button: Button
var _variant_button: Button
var _remove_button: Button
var _selected_image_index := -1
var _loading_controls := false


func _ready() -> void:
	close_requested.connect(_close_window)
	_image_service = CCFImageGenerationService.new()
	add_child(_image_service)
	_image_service.generation_started.connect(_on_generation_started)
	_image_service.generation_batch_completed.connect(_on_generation_batch_completed)
	_image_service.generation_failed.connect(_on_generation_failed)
	_image_service.generation_cancelled.connect(_on_generation_cancelled)

	_capability_service = CCFImageCapabilityService.new()
	add_child(_capability_service)
	_capability_service.capabilities_started.connect(_on_capabilities_started)
	_capability_service.capabilities_loaded.connect(_on_capabilities_loaded)
	_capability_service.capabilities_failed.connect(_on_capabilities_failed)
	_capability_service.capabilities_cancelled.connect(_on_capabilities_cancelled)

	_build_ui()
	_reload_settings()
	_refresh_projects()


func open_studio() -> void:
	_reload_settings()
	_refresh_profiles()
	_refresh_projects()
	CCFToolWindowStateService.show_window(self, WINDOW_STATE_ID, Vector2i(1240, 860))


func save_window_state() -> void:
	CCFToolWindowStateService.save_window(self, WINDOW_STATE_ID)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "Image Generation Studio"
	heading.add_theme_font_size_override("font_size", 22)
	root.add_child(heading)

	var hint := Label.new()
	hint.text = "Generate and reproduce character artwork through OpenAI-compatible image APIs or local Stable Diffusion Forge / Automatic1111. Generated files remain ordinary per-character PNG assets."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.72, 0.75, 0.84)
	root.add_child(hint)

	var source_row := HFlowContainer.new()
	source_row.add_theme_constant_override("separation", 8)
	root.add_child(source_row)
	source_row.add_child(_label("Project"))
	_project_selector = OptionButton.new()
	_project_selector.custom_minimum_size.x = 270
	_project_selector.item_selected.connect(_on_project_selected)
	source_row.add_child(_project_selector)
	source_row.add_child(_label("Character"))
	_character_selector = OptionButton.new()
	_character_selector.custom_minimum_size.x = 250
	_character_selector.item_selected.connect(_on_character_selected)
	source_row.add_child(_character_selector)
	var reload_button := Button.new()
	reload_button.text = "Reload Projects"
	reload_button.pressed.connect(_refresh_projects)
	source_row.add_child(reload_button)

	var provider_row := HFlowContainer.new()
	provider_row.add_theme_constant_override("separation", 8)
	root.add_child(provider_row)
	provider_row.add_child(_label("Image provider"))
	_profile_selector = OptionButton.new()
	_profile_selector.custom_minimum_size.x = 220
	_profile_selector.item_selected.connect(_on_profile_selected)
	provider_row.add_child(_profile_selector)
	var default_provider_button := Button.new()
	default_provider_button.text = "Use as Image Default"
	default_provider_button.tooltip_text = "Assign this reusable profile to the Image generation role."
	default_provider_button.pressed.connect(_save_default_image_profile)
	provider_row.add_child(default_provider_button)
	_backend_label = Label.new()
	_backend_label.text = "Backend: —"
	_backend_label.modulate = Color(0.68, 0.78, 0.9)
	provider_row.add_child(_backend_label)
	_discover_button = Button.new()
	_discover_button.text = "Discover Models / Samplers"
	_discover_button.pressed.connect(_discover_capabilities)
	provider_row.add_child(_discover_button)

	var model_row := HFlowContainer.new()
	model_row.add_theme_constant_override("separation", 8)
	root.add_child(model_row)
	model_row.add_child(_label("Model / checkpoint"))
	_model_edit = LineEdit.new()
	_model_edit.custom_minimum_size.x = 300
	_model_edit.placeholder_text = "Image model ID or Stable Diffusion checkpoint"
	model_row.add_child(_model_edit)
	_fetched_models = OptionButton.new()
	_fetched_models.custom_minimum_size.x = 300
	_fetched_models.item_selected.connect(_on_discovered_model_selected)
	model_row.add_child(_fetched_models)
	_reset_discovery_lists()
	var save_defaults_button := Button.new()
	save_defaults_button.text = "Save Image Defaults"
	save_defaults_button.tooltip_text = "Save model/checkpoint, sampler, steps, CFG, seed, and batch size into the selected provider profile."
	save_defaults_button.pressed.connect(_save_image_defaults)
	model_row.add_child(save_defaults_button)

	var option_row := HFlowContainer.new()
	option_row.add_theme_constant_override("separation", 8)
	root.add_child(option_row)
	option_row.add_child(_label("Size"))
	_image_size_edit = LineEdit.new()
	_image_size_edit.custom_minimum_size.x = 130
	_image_size_edit.placeholder_text = "1024x1024"
	option_row.add_child(_image_size_edit)
	option_row.add_child(_label("Prompt style"))
	_prompt_style_selector = OptionButton.new()
	for style_entry in [
		{"label": "Auto", "value": "auto"},
		{"label": "Natural language", "value": "natural"},
		{"label": "Stable Diffusion style", "value": "stable_diffusion"}
	]:
		_prompt_style_selector.add_item(str(style_entry["label"]))
		_prompt_style_selector.set_item_metadata(
			_prompt_style_selector.item_count - 1, str(style_entry["value"])
		)
	_prompt_style_selector.item_selected.connect(_on_prompt_style_selected)
	option_row.add_child(_prompt_style_selector)
	option_row.add_child(_label("Batch"))
	_batch_size = SpinBox.new()
	_batch_size.min_value = 1
	_batch_size.max_value = 8
	_batch_size.step = 1
	_batch_size.custom_minimum_size.x = 80
	option_row.add_child(_batch_size)
	var build_prompt_button := Button.new()
	build_prompt_button.text = "Build Prompt from Character"
	build_prompt_button.pressed.connect(_build_prompt_from_character)
	option_row.add_child(build_prompt_button)

	var advanced_row := HFlowContainer.new()
	advanced_row.add_theme_constant_override("separation", 8)
	root.add_child(advanced_row)
	advanced_row.add_child(_label("Sampler"))
	_sampler_edit = LineEdit.new()
	_sampler_edit.custom_minimum_size.x = 150
	_sampler_edit.placeholder_text = "Euler a"
	advanced_row.add_child(_sampler_edit)
	_fetched_samplers = OptionButton.new()
	_fetched_samplers.custom_minimum_size.x = 180
	_fetched_samplers.item_selected.connect(_on_discovered_sampler_selected)
	advanced_row.add_child(_fetched_samplers)
	advanced_row.add_child(_label("Steps"))
	_steps = SpinBox.new()
	_steps.min_value = 1
	_steps.max_value = 150
	_steps.step = 1
	_steps.custom_minimum_size.x = 80
	advanced_row.add_child(_steps)
	advanced_row.add_child(_label("CFG"))
	_cfg_scale = SpinBox.new()
	_cfg_scale.min_value = 1.0
	_cfg_scale.max_value = 30.0
	_cfg_scale.step = 0.5
	_cfg_scale.custom_minimum_size.x = 80
	advanced_row.add_child(_cfg_scale)
	advanced_row.add_child(_label("Seed"))
	_seed = SpinBox.new()
	_seed.min_value = -1
	_seed.max_value = 2147483647
	_seed.step = 1
	_seed.custom_minimum_size.x = 150
	_seed.tooltip_text = "Stable Diffusion: -1 requests a random seed. The actual returned seed is stored with each gallery image."
	advanced_row.add_child(_seed)

	var advanced_hint := Label.new()
	advanced_hint.text = "Sampler, Steps, CFG and Seed are sent to Forge/A1111. OpenAI-compatible backends ignore those controls; Batch and Size still apply when the provider supports them."
	advanced_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	advanced_hint.modulate = Color(0.62, 0.67, 0.78)
	root.add_child(advanced_hint)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 650
	root.add_child(body)

	var prompt_side := VBoxContainer.new()
	prompt_side.custom_minimum_size.x = 540
	prompt_side.add_theme_constant_override("separation", 7)
	body.add_child(prompt_side)
	prompt_side.add_child(_label("Additional visual direction"))
	_extra_direction_edit = TextEdit.new()
	_extra_direction_edit.custom_minimum_size.y = 70
	_extra_direction_edit.placeholder_text = "Optional clothing, composition, lighting, background, art direction, or pose notes."
	prompt_side.add_child(_extra_direction_edit)
	prompt_side.add_child(_label("Image prompt"))
	_prompt_edit = TextEdit.new()
	_prompt_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_prompt_edit.custom_minimum_size.y = 190
	_prompt_edit.placeholder_text = "Build a prompt from the selected character, then edit it freely."
	prompt_side.add_child(_prompt_edit)
	prompt_side.add_child(_label("Avoid / negative prompt"))
	_negative_prompt_edit = TextEdit.new()
	_negative_prompt_edit.custom_minimum_size.y = 75
	_negative_prompt_edit.placeholder_text = "Forge/A1111 receives this as negative_prompt. OpenAI-compatible routes receive provider-neutral exclusion guidance."
	prompt_side.add_child(_negative_prompt_edit)

	var generation_actions := HBoxContainer.new()
	generation_actions.add_theme_constant_override("separation", 8)
	prompt_side.add_child(generation_actions)
	_generate_button = Button.new()
	_generate_button.text = "Generate"
	_generate_button.pressed.connect(_generate_image)
	generation_actions.add_child(_generate_button)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_cancel_generation)
	generation_actions.add_child(_cancel_button)

	var gallery_side := VBoxContainer.new()
	gallery_side.custom_minimum_size.x = 430
	gallery_side.add_theme_constant_override("separation", 7)
	body.add_child(gallery_side)
	gallery_side.add_child(_label("Generated image gallery"))
	_gallery = ItemList.new()
	_gallery.custom_minimum_size.y = 150
	_gallery.select_mode = ItemList.SELECT_SINGLE
	_gallery.item_selected.connect(_on_gallery_selected)
	gallery_side.add_child(_gallery)
	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.custom_minimum_size = Vector2(360, 280)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gallery_side.add_child(_preview)
	_preview_info = Label.new()
	_preview_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_info.modulate = Color(0.72, 0.75, 0.84)
	gallery_side.add_child(_preview_info)

	var gallery_actions := HFlowContainer.new()
	gallery_actions.add_theme_constant_override("separation", 8)
	gallery_side.add_child(gallery_actions)
	_set_portrait_button = Button.new()
	_set_portrait_button.text = "Set as Portrait"
	_set_portrait_button.disabled = true
	_set_portrait_button.pressed.connect(_set_selected_as_portrait)
	gallery_actions.add_child(_set_portrait_button)
	var open_file_button := Button.new()
	open_file_button.text = "Open Image"
	open_file_button.pressed.connect(_open_selected_image)
	gallery_actions.add_child(open_file_button)
	_regenerate_button = Button.new()
	_regenerate_button.text = "Regenerate"
	_regenerate_button.disabled = true
	_regenerate_button.tooltip_text = "Reuse this image's stored prompt and generation settings. Stable Diffusion also reuses its stored seed."
	_regenerate_button.pressed.connect(_regenerate_selected)
	gallery_actions.add_child(_regenerate_button)
	_variant_button = Button.new()
	_variant_button.text = "New Seed Variant"
	_variant_button.disabled = true
	_variant_button.tooltip_text = "Reuse the selected image's prompt/settings but request a new Stable Diffusion seed."
	_variant_button.pressed.connect(_variant_selected)
	gallery_actions.add_child(_variant_button)
	_remove_button = Button.new()
	_remove_button.text = "Remove from Gallery"
	_remove_button.disabled = true
	_remove_button.tooltip_text = "Remove the gallery record but keep the PNG file as a recoverable asset."
	_remove_button.pressed.connect(_remove_selected_from_gallery)
	gallery_actions.add_child(_remove_button)

	_status = Label.new()
	_status.text = "Select a saved project and character."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.7, 0.82, 0.72)
	root.add_child(_status)


func _reload_settings() -> void:
	_settings = CCFSettingsService.load_settings()
	if _profile_selector == null:
		return
	_refresh_profiles()
	var generation_settings: Dictionary = _settings.get("generation", {})
	_image_size_edit.text = str(generation_settings.get("default_image_size", "1024x1024"))
	_select_prompt_style(str(generation_settings.get("default_image_prompt_style", "auto")))


func _refresh_profiles() -> void:
	if _profile_selector == null:
		return
	_loading_controls = true
	_profile_selector.clear()
	var selected_profile_id := CCFSettingsService.role_profile_id(
		_settings, CCFSettingsService.ROLE_IMAGE
	)
	var selected_index := 0
	for raw_profile in _settings.get("api_profiles", []):
		if not raw_profile is Dictionary:
			continue
		var profile: Dictionary = raw_profile
		var profile_id := str(profile.get("id", "default"))
		_profile_selector.add_item(str(profile.get("name", "Profile")))
		var item_index := _profile_selector.item_count - 1
		_profile_selector.set_item_metadata(item_index, profile_id)
		if profile_id == selected_profile_id:
			selected_index = item_index
	if _profile_selector.item_count > 0:
		_profile_selector.select(selected_index)
	_loading_controls = false
	_load_selected_profile_settings()


func _refresh_projects() -> void:
	if _project_selector == null:
		return
	var previous_project_id := str(_project.get("project_id", ""))
	_loading_controls = true
	_project_selector.clear()
	var rows := CCFStorageService.list_projects()
	var selected_index := -1
	for raw_row in rows:
		if not raw_row is Dictionary:
			continue
		var row: Dictionary = raw_row
		var project_id := str(row.get("project_id", ""))
		_project_selector.add_item(str(row.get("name", "Untitled Project")))
		var item_index := _project_selector.item_count - 1
		_project_selector.set_item_metadata(item_index, project_id)
		if project_id == previous_project_id:
			selected_index = item_index
	_loading_controls = false
	if _project_selector.item_count == 0:
		_project.clear()
		_active_character_id = ""
		_character_selector.clear()
		_refresh_gallery()
		_status.text = "No saved character projects are available yet."
		return
	if selected_index < 0:
		selected_index = 0
	_project_selector.select(selected_index)
	_load_project(str(_project_selector.get_item_metadata(selected_index)))


func _load_project(project_id: String) -> void:
	var loaded := CCFStorageService.load_project(project_id)
	if not bool(loaded.get("ok", false)):
		_status.text = str(loaded.get("error", "Could not load the selected project."))
		return
	_project = loaded.get("data", {}).duplicate(true)
	_active_character_id = CCFStorageService.active_character_id(_project)
	_refresh_characters()
	_build_prompt_from_character()
	_refresh_gallery()
	_status.text = "Image Studio loaded the saved project. Generated assets are saved immediately."


func _refresh_characters() -> void:
	_loading_controls = true
	_character_selector.clear()
	var selected_index := 0
	var row_index := 0
	for summary in CCFStorageService.project_character_summaries(_project):
		var character_id := str(summary.get("character_id", ""))
		_character_selector.add_item(str(summary.get("name", "Untitled Character")))
		_character_selector.set_item_metadata(row_index, character_id)
		if character_id == _active_character_id:
			selected_index = row_index
		row_index += 1
	if _character_selector.item_count > 0:
		_character_selector.select(selected_index)
	_loading_controls = false


func _on_project_selected(index: int) -> void:
	if _loading_controls or index < 0:
		return
	_load_project(str(_project_selector.get_item_metadata(index)))


func _on_character_selected(index: int) -> void:
	if _loading_controls or index < 0:
		return
	_active_character_id = str(_character_selector.get_item_metadata(index))
	_build_prompt_from_character()
	_refresh_gallery()


func _on_profile_selected(_index: int) -> void:
	if _loading_controls:
		return
	_load_selected_profile_settings()


func _load_selected_profile_settings() -> void:
	var profile := _selected_profile()
	_model_edit.text = str(profile.get("model", ""))
	var image_defaults := CCFSettingsService.image_settings(profile)
	_sampler_edit.text = str(image_defaults.get("sampler", "Euler a"))
	_steps.value = int(image_defaults.get("steps", 28))
	_cfg_scale.value = float(image_defaults.get("cfg_scale", 7.0))
	_seed.value = int(image_defaults.get("seed", -1))
	_batch_size.value = int(image_defaults.get("batch_size", 1))
	var backend := CCFImageGenerationService.backend_for_profile(profile)
	_backend_label.text = "Backend: %s" % (
		"Forge / Automatic1111" if backend == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111 else "OpenAI-compatible Images"
	)
	_reset_discovery_lists()


func _save_default_image_profile() -> void:
	if _profile_selector.selected < 0:
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	CCFSettingsService.set_role_profile(_settings, CCFSettingsService.ROLE_IMAGE, profile_id)
	var save_result := CCFSettingsService.save_settings(_settings)
	if bool(save_result.get("ok", false)):
		_status.text = "%s is now the default Image generation profile." % _profile_selector.get_item_text(_profile_selector.selected)
	else:
		_status.text = str(save_result.get("error", "Could not save the Image provider role."))


func _save_image_defaults() -> void:
	if _profile_selector.selected < 0:
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	var profile := CCFSettingsService.profile_by_id(_settings, profile_id).duplicate(true)
	profile["model"] = _model_edit.text.strip_edges()
	profile["image_settings"] = _current_generation_options("profile_default", "")
	CCFSettingsService.replace_profile_by_id(_settings, profile_id, profile)
	var save_result := CCFSettingsService.save_settings(_settings)
	if bool(save_result.get("ok", false)):
		_settings = CCFSettingsService.load_settings()
		_status.text = "Saved image-generation defaults to %s." % str(profile.get("name", "Profile"))
	else:
		_status.text = str(save_result.get("error", "Could not save image defaults."))


func _discover_capabilities() -> void:
	var result := _capability_service.fetch_capabilities(_selected_profile())
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not start image provider discovery."))


func _on_capabilities_started() -> void:
	_discover_button.disabled = true
	_status.text = "Discovering image models and backend capabilities…"


func _on_capabilities_loaded(capabilities: Dictionary) -> void:
	_discover_button.disabled = false
	_populate_discovery_list(
		_fetched_models,
		capabilities.get("models", []),
		"Choose discovered model / checkpoint…",
		"No models returned"
	)
	_populate_discovery_list(
		_fetched_samplers,
		capabilities.get("samplers", []),
		"Choose discovered sampler…",
		"No sampler list exposed"
	)
	var backend_label := str(capabilities.get("backend_label", "Image provider"))
	var discovery_note := str(capabilities.get("discovery_note", "")).strip_edges()
	_status.text = "%s discovery complete: %d models, %d samplers.%s" % [
		backend_label,
		int(capabilities.get("models", []).size()),
		int(capabilities.get("samplers", []).size()),
		" " + discovery_note if not discovery_note.is_empty() else ""
	]


func _on_capabilities_failed(message_text: String) -> void:
	_discover_button.disabled = false
	_status.text = message_text


func _on_capabilities_cancelled() -> void:
	_discover_button.disabled = false
	_status.text = "Image capability discovery cancelled."


func _populate_discovery_list(
	selector: OptionButton,
	values: Variant,
	placeholder: String,
	empty_text: String
) -> void:
	selector.clear()
	selector.add_item(placeholder)
	selector.set_item_disabled(0, true)
	if values is Array:
		for value in values:
			selector.add_item(str(value))
	if selector.item_count == 1:
		selector.add_item(empty_text)
		selector.set_item_disabled(1, true)
	selector.select(0)


func _reset_discovery_lists() -> void:
	if _fetched_models != null:
		_populate_discovery_list(_fetched_models, [], "Discover models to populate…", "No models discovered")
	if _fetched_samplers != null:
		_populate_discovery_list(_fetched_samplers, [], "Discover samplers to populate…", "No samplers discovered")


func _on_discovered_model_selected(index: int) -> void:
	if index <= 0 or _fetched_models.is_item_disabled(index):
		return
	_model_edit.text = _fetched_models.get_item_text(index)
	_status.text = "Selected discovered image model/checkpoint."


func _on_discovered_sampler_selected(index: int) -> void:
	if index <= 0 or _fetched_samplers.is_item_disabled(index):
		return
	_sampler_edit.text = _fetched_samplers.get_item_text(index)
	_status.text = "Selected discovered Stable Diffusion sampler."


func _on_prompt_style_selected(_index: int) -> void:
	if _loading_controls:
		return
	_build_prompt_from_character()


func _build_prompt_from_character() -> void:
	if _project.is_empty() or _active_character_id.is_empty() or _prompt_edit == null:
		return
	_prompt_edit.text = CCFImageGenerationService.build_prompt(
		_project,
		_active_character_id,
		_selected_prompt_style(),
		_extra_direction_edit.text
	)


func _generate_image() -> void:
	_start_generation("new", {})


func _start_generation(generation_mode: String, source_entry: Dictionary) -> void:
	if _project.is_empty() or _active_character_id.is_empty():
		_status.text = "Select a saved project and character first."
		return
	var source_image_id := str(source_entry.get("image_id", ""))
	var result := _image_service.generate(
		str(_project.get("project_id", "")),
		_active_character_id,
		_selected_profile(),
		_prompt_edit.text,
		_negative_prompt_edit.text,
		_image_size_edit.text,
		_selected_prompt_style(),
		_model_edit.text,
		_current_generation_options(generation_mode, source_image_id)
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not start image generation."))


func _current_generation_options(generation_mode: String, source_image_id: String) -> Dictionary:
	return {
		"sampler": _sampler_edit.text.strip_edges(),
		"steps": int(_steps.value),
		"cfg_scale": float(_cfg_scale.value),
		"seed": int(_seed.value),
		"batch_size": int(_batch_size.value),
		"generation_mode": generation_mode,
		"source_image_id": source_image_id
	}


func _cancel_generation() -> void:
	_image_service.cancel()


func _on_generation_started() -> void:
	_generate_button.disabled = true
	_cancel_button.disabled = false
	_regenerate_button.disabled = true
	_variant_button.disabled = true
	var backend := CCFImageGenerationService.backend_for_profile(_selected_profile())
	var backend_text := "Stable Diffusion" if backend == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111 else "image provider"
	_status.text = "Generating %d image(s) through %s…" % [int(_batch_size.value), backend_text]


func _on_generation_batch_completed(records: Array) -> void:
	_generate_button.disabled = false
	_cancel_button.disabled = true
	var character_index := CCFStorageService.character_index(_project, _active_character_id)
	if character_index < 0:
		_status.text = "Images were saved, but the originating character is no longer in this project."
		return
	var characters: Array = _project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[character_index].duplicate(true)
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	var generated_images: Array = assets.get("generated_images", []).duplicate(true)
	for reverse_index in range(records.size() - 1, -1, -1):
		var raw_record = records[reverse_index]
		if raw_record is Dictionary:
			generated_images.push_front(raw_record.duplicate(true))
	assets["generated_images"] = generated_images
	character["assets"] = assets
	characters[character_index] = character
	_project["characters"] = characters
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = "Image files were saved, but gallery records could not be saved: %s" % str(save_result.get("error", "Unknown error"))
		return
	_refresh_gallery()
	if _gallery.item_count > 0:
		_gallery.select(0)
		_on_gallery_selected(0)
	project_changed.emit(_project.duplicate(true))
	_status.text = "Generated %d image(s) and added them to the character gallery." % records.size()


func _on_generation_failed(message_text: String) -> void:
	_generate_button.disabled = false
	_cancel_button.disabled = true
	_status.text = message_text
	_refresh_gallery_action_state()


func _on_generation_cancelled() -> void:
	_generate_button.disabled = false
	_cancel_button.disabled = true
	_status.text = "Image generation cancelled."
	_refresh_gallery_action_state()


func _refresh_gallery() -> void:
	_selected_image_index = -1
	_gallery.clear()
	_preview.texture = null
	_preview_info.text = ""
	_set_portrait_button.disabled = true
	_regenerate_button.disabled = true
	_variant_button.disabled = true
	_remove_button.disabled = true
	var character := CCFStorageService.get_character(_project, _active_character_id)
	if character.is_empty():
		return
	var assets: Dictionary = character.get("assets", {})
	var generated_images = assets.get("generated_images", [])
	if not generated_images is Array:
		return
	for raw_entry in generated_images:
		var entry := _normalise_gallery_entry(raw_entry)
		if entry.is_empty():
			continue
		var created_at := str(entry.get("created_at", "")).replace("T", " ")
		var model_id := str(entry.get("model", "")).strip_edges()
		var gallery_label := created_at if not created_at.is_empty() else str(entry.get("path", "Generated image"))
		if not model_id.is_empty():
			gallery_label += " — %s" % model_id
		var stored_seed := int(entry.get("seed", -1))
		if stored_seed >= 0:
			gallery_label += " • seed %s" % stored_seed
		_gallery.add_item(gallery_label)
		_gallery.set_item_metadata(_gallery.item_count - 1, entry)
	if _gallery.item_count > 0:
		_gallery.select(0)
		_on_gallery_selected(0)


func _on_gallery_selected(index: int) -> void:
	if index < 0 or index >= _gallery.item_count:
		return
	_selected_image_index = index
	var entry = _gallery.get_item_metadata(index)
	if not entry is Dictionary:
		return
	var image_entry: Dictionary = entry
	var project_id := str(_project.get("project_id", ""))
	var user_path := CCFImageGenerationService.resolve_generated_image_path(
		project_id, str(image_entry.get("path", ""))
	)
	_preview.texture = _texture_from_user_path(user_path)
	_preview_info.text = _gallery_entry_summary(image_entry)
	_refresh_gallery_action_state()


func _refresh_gallery_action_state() -> void:
	var has_selection := _selected_image_index >= 0 and _selected_image_index < _gallery.item_count
	var entry := _selected_gallery_entry() if has_selection else {}
	var project_id := str(_project.get("project_id", ""))
	var user_path := CCFImageGenerationService.resolve_generated_image_path(
		project_id, str(entry.get("path", ""))
	) if has_selection else ""
	_set_portrait_button.disabled = not has_selection or user_path.is_empty() or _preview.texture == null
	_remove_button.disabled = not has_selection
	_regenerate_button.disabled = not has_selection or _image_service.is_active()
	_variant_button.disabled = not has_selection or _image_service.is_active()


func _regenerate_selected() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	_load_generation_from_entry(entry, true)
	_batch_size.value = 1
	_start_generation("regenerate", entry)


func _variant_selected() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	_load_generation_from_entry(entry, false)
	_batch_size.value = 1
	_seed.value = -1
	_start_generation("variant", entry)


func _load_generation_from_entry(entry: Dictionary, keep_seed: bool) -> void:
	var source_profile_id := str(entry.get("profile_id", "")).strip_edges()
	if not source_profile_id.is_empty():
		_select_profile_by_id(source_profile_id)
	_prompt_edit.text = str(entry.get("prompt", _prompt_edit.text))
	_negative_prompt_edit.text = str(entry.get("negative_prompt", _negative_prompt_edit.text))
	var stored_size := str(entry.get("size", "")).strip_edges()
	if not stored_size.is_empty():
		_image_size_edit.text = stored_size
	var stored_model := str(entry.get("model", "")).strip_edges()
	if not stored_model.is_empty():
		_model_edit.text = stored_model
	var stored_sampler := str(entry.get("sampler", "")).strip_edges()
	if not stored_sampler.is_empty():
		_sampler_edit.text = stored_sampler
	if entry.has("steps"):
		_steps.value = int(entry.get("steps", 28))
	if entry.has("cfg_scale"):
		_cfg_scale.value = float(entry.get("cfg_scale", 7.0))
	if keep_seed and entry.has("seed"):
		_seed.value = int(entry.get("seed", -1))
	_select_prompt_style(str(entry.get("prompt_style", _selected_prompt_style())))


func _select_profile_by_id(profile_id: String) -> void:
	for item_index in range(_profile_selector.item_count):
		if str(_profile_selector.get_item_metadata(item_index)) == profile_id:
			_profile_selector.select(item_index)
			_load_selected_profile_settings()
			return


func _set_selected_as_portrait() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	var character_index := CCFStorageService.character_index(_project, _active_character_id)
	if character_index < 0:
		return
	var characters: Array = _project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[character_index].duplicate(true)
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	assets["portrait"] = str(entry.get("path", ""))
	character["assets"] = assets
	characters[character_index] = character
	_project["characters"] = characters
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not save the portrait assignment."))
		return
	project_changed.emit(_project.duplicate(true))
	_status.text = "Selected generated image is now the character portrait."


func _remove_selected_from_gallery() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	var character_index := CCFStorageService.character_index(_project, _active_character_id)
	if character_index < 0:
		return
	var characters: Array = _project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[character_index].duplicate(true)
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	var old_images = assets.get("generated_images", [])
	var remaining: Array = []
	var target_id := str(entry.get("image_id", ""))
	var target_path := str(entry.get("path", ""))
	if old_images is Array:
		for raw_entry in old_images:
			var candidate := _normalise_gallery_entry(raw_entry)
			if candidate.is_empty():
				continue
			var same_id := not target_id.is_empty() and str(candidate.get("image_id", "")) == target_id
			var same_path := str(candidate.get("path", "")) == target_path
			if same_id or same_path:
				continue
			remaining.append(raw_entry)
	assets["generated_images"] = remaining
	character["assets"] = assets
	characters[character_index] = character
	_project["characters"] = characters
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not update the generated image gallery."))
		return
	_refresh_gallery()
	project_changed.emit(_project.duplicate(true))
	_status.text = "Gallery record removed. The PNG remains in the project asset folder for recovery."


func _open_selected_image() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	var user_path := CCFImageGenerationService.resolve_generated_image_path(
		str(_project.get("project_id", "")), str(entry.get("path", ""))
	)
	if user_path.is_empty():
		_status.text = "The selected image path is invalid."
		return
	var absolute_path := ProjectSettings.globalize_path(user_path)
	if not FileAccess.file_exists(user_path) and not FileAccess.file_exists(absolute_path):
		_status.text = "The selected image file no longer exists."
		return
	OS.shell_open(absolute_path)


func _selected_gallery_entry() -> Dictionary:
	if _selected_image_index < 0 or _selected_image_index >= _gallery.item_count:
		return {}
	var entry = _gallery.get_item_metadata(_selected_image_index)
	return entry.duplicate(true) if entry is Dictionary else {}


func _selected_profile() -> Dictionary:
	if _profile_selector.selected < 0:
		return CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_IMAGE)
	return CCFSettingsService.profile_by_id(
		_settings, str(_profile_selector.get_selected_metadata())
	)


func _selected_prompt_style() -> String:
	if _prompt_style_selector.selected < 0:
		return "auto"
	return str(_prompt_style_selector.get_selected_metadata())


func _select_prompt_style(prompt_style: String) -> void:
	for item_index in range(_prompt_style_selector.item_count):
		if str(_prompt_style_selector.get_item_metadata(item_index)) == prompt_style:
			_prompt_style_selector.select(item_index)
			return
	if _prompt_style_selector.item_count > 0:
		_prompt_style_selector.select(0)


func _normalise_gallery_entry(raw_entry: Variant) -> Dictionary:
	if raw_entry is Dictionary:
		var record: Dictionary = raw_entry.duplicate(true)
		if str(record.get("path", "")).strip_edges().is_empty():
			return {}
		return record
	var legacy_path := str(raw_entry).strip_edges()
	if legacy_path.is_empty():
		return {}
	return {"format_version": 0, "image_id": "", "path": legacy_path}


func _texture_from_user_path(user_path: String) -> Texture2D:
	if user_path.is_empty():
		return null
	var decoded_image := Image.new()
	var load_error := decoded_image.load(ProjectSettings.globalize_path(user_path))
	if load_error != OK:
		return null
	return ImageTexture.create_from_image(decoded_image)


func _gallery_entry_summary(entry: Dictionary) -> String:
	var lines: Array[String] = []
	var dimensions := ""
	if int(entry.get("width", 0)) > 0 and int(entry.get("height", 0)) > 0:
		dimensions = "%d×%d" % [int(entry.get("width", 0)), int(entry.get("height", 0))]
	if not dimensions.is_empty():
		lines.append(dimensions)
	var profile_label := str(entry.get("profile_name", "")).strip_edges()
	var model_id := str(entry.get("model", "")).strip_edges()
	var backend := str(entry.get("backend", entry.get("provider", ""))).strip_edges()
	if not profile_label.is_empty() or not model_id.is_empty() or not backend.is_empty():
		var provider_line := "Provider: %s" % (profile_label if not profile_label.is_empty() else backend)
		if not backend.is_empty() and backend != profile_label:
			provider_line += " • %s" % backend
		if not model_id.is_empty():
			provider_line += " • %s" % model_id
		lines.append(provider_line)
	var stored_seed := int(entry.get("seed", -1))
	var sampler_name := str(entry.get("sampler", "")).strip_edges()
	if stored_seed >= 0 or not sampler_name.is_empty():
		var generation_line := ""
		if stored_seed >= 0:
			generation_line = "Seed %s" % stored_seed
		if not sampler_name.is_empty():
			generation_line += (" • " if not generation_line.is_empty() else "") + sampler_name
		if entry.has("steps"):
			generation_line += " • %s steps" % int(entry.get("steps", 0))
		if entry.has("cfg_scale"):
			generation_line += " • CFG %s" % float(entry.get("cfg_scale", 0.0))
		lines.append(generation_line)
	var mode_text := str(entry.get("generation_mode", "")).strip_edges()
	if not mode_text.is_empty() and mode_text != "new":
		lines.append("Generation: %s" % mode_text.capitalize())
	var prompt_text := str(entry.get("prompt", "")).strip_edges()
	if not prompt_text.is_empty():
		lines.append("Prompt: %s" % prompt_text.left(500))
	var relative_path := str(entry.get("path", "")).strip_edges()
	if not relative_path.is_empty():
		lines.append("File: %s" % relative_path)
	return "\n".join(lines)


func _close_window() -> void:
	if _capability_service != null and _capability_service.is_active():
		_capability_service.cancel()
	save_window_state()
	hide()


func _label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	return label
