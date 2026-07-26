class_name CCFSettingsView
extends VBoxContainer

signal settings_saved(settings: Dictionary)

var _settings: Dictionary = {}
var _loaded_profile_id := ""
var _loading_profile := false
var _loading_roles := false
var _profile_selector: OptionButton
var _text_role_selector: OptionButton
var _vision_role_selector: OptionButton
var _image_role_selector: OptionButton
var _profile_name: LineEdit
var _base_url: LineEdit
var _api_key: LineEdit
var _model: LineEdit
var _temperature: SpinBox
var _max_tokens: SpinBox
var _vision_detail: OptionButton
var _include_existing: CheckBox
var _retry_count: SpinBox
var _idea_count: SpinBox
var _attachment_context_limit: SpinBox
var _default_image_size: LineEdit
var _image_prompt_style: OptionButton
var _fetched_models: OptionButton
var _fetch_models_button: Button
var _status: Label
var _model_service: CCFModelService


func _ready() -> void:
	add_theme_constant_override("separation", 14)

	_model_service = CCFModelService.new()
	add_child(_model_service)
	_model_service.models_loaded.connect(_on_models_loaded)
	_model_service.models_failed.connect(_on_models_failed)

	var intro := Label.new()
	intro.text = "OpenAI-compatible provider profiles"
	intro.add_theme_font_size_override("font_size", 22)
	add_child(intro)

	var hint := Label.new()
	hint.text = "Create reusable backend profiles, then assign separate profiles to text generation, vision analysis, and image generation. One profile may serve multiple roles."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.75, 0.77, 0.84)
	add_child(hint)

	var role_heading := Label.new()
	role_heading.text = "Provider roles"
	role_heading.add_theme_font_size_override("font_size", 19)
	add_child(role_heading)

	var role_grid := GridContainer.new()
	role_grid.columns = 2
	role_grid.add_theme_constant_override("h_separation", 14)
	role_grid.add_theme_constant_override("v_separation", 10)
	add_child(role_grid)

	role_grid.add_child(_label("Text generation profile"))
	_text_role_selector = OptionButton.new()
	_text_role_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_role_selector.item_selected.connect(_on_role_selected.bind(CCFSettingsService.ROLE_TEXT))
	role_grid.add_child(_text_role_selector)

	role_grid.add_child(_label("Vision analysis profile"))
	_vision_role_selector = OptionButton.new()
	_vision_role_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vision_role_selector.item_selected.connect(_on_role_selected.bind(CCFSettingsService.ROLE_VISION))
	role_grid.add_child(_vision_role_selector)

	role_grid.add_child(_label("Image generation profile"))
	_image_role_selector = OptionButton.new()
	_image_role_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_image_role_selector.item_selected.connect(_on_role_selected.bind(CCFSettingsService.ROLE_IMAGE))
	role_grid.add_child(_image_role_selector)

	var role_hint := Label.new()
	role_hint.text = "For multimodal vision, choose a model that accepts image_url input. For Image Studio, choose a profile whose base URL exposes an OpenAI-compatible /images/generations route; its model can still be overridden per run."
	role_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role_hint.modulate = Color(0.64, 0.68, 0.8)
	add_child(role_hint)

	var profile_heading := Label.new()
	profile_heading.text = "Edit provider profile"
	profile_heading.add_theme_font_size_override("font_size", 19)
	add_child(profile_heading)

	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 8)
	add_child(profile_row)

	_profile_selector = OptionButton.new()
	_profile_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_selector.item_selected.connect(_on_profile_selected)
	profile_row.add_child(_profile_selector)

	var new_profile_button := Button.new()
	new_profile_button.text = "New"
	new_profile_button.pressed.connect(_create_profile)
	profile_row.add_child(new_profile_button)

	var duplicate_button := Button.new()
	duplicate_button.text = "Duplicate"
	duplicate_button.pressed.connect(_duplicate_profile)
	profile_row.add_child(duplicate_button)

	var delete_button := Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(_delete_profile)
	profile_row.add_child(delete_button)

	var form := GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 14)
	form.add_theme_constant_override("v_separation", 10)
	add_child(form)

	_profile_name = _add_line(form, "Profile name")
	_base_url = _add_line(form, "API base URL")
	_api_key = _add_line(form, "API key")
	_api_key.secret = true

	form.add_child(_label("Model"))
	var model_box := VBoxContainer.new()
	model_box.add_theme_constant_override("separation", 6)
	model_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(model_box)

	var model_row := HBoxContainer.new()
	model_row.add_theme_constant_override("separation", 8)
	model_box.add_child(model_row)
	_model = LineEdit.new()
	_model.placeholder_text = "Enter a model ID or fetch the model list"
	_model.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	model_row.add_child(_model)
	_fetch_models_button = Button.new()
	_fetch_models_button.text = "Fetch Models"
	_fetch_models_button.pressed.connect(_fetch_models)
	model_row.add_child(_fetch_models_button)

	_fetched_models = OptionButton.new()
	_fetched_models.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fetched_models.item_selected.connect(_on_fetched_model_selected)
	model_box.add_child(_fetched_models)
	_reset_fetched_models()

	form.add_child(_label("Temperature"))
	_temperature = SpinBox.new()
	_temperature.min_value = 0.0
	_temperature.max_value = 2.0
	_temperature.step = 0.05
	_temperature.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_temperature)

	form.add_child(_label("Maximum output tokens"))
	_max_tokens = SpinBox.new()
	_max_tokens.min_value = 128
	_max_tokens.max_value = 131072
	_max_tokens.step = 128
	_max_tokens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_max_tokens)

	form.add_child(_label("Vision image detail"))
	_vision_detail = OptionButton.new()
	for detail in ["auto", "low", "high"]:
		_vision_detail.add_item(detail.capitalize())
		_vision_detail.set_item_metadata(_vision_detail.item_count - 1, detail)
	_vision_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_vision_detail)

	var generation_heading := Label.new()
	generation_heading.text = "Generation behaviour"
	generation_heading.add_theme_font_size_override("font_size", 19)
	add_child(generation_heading)

	var generation_grid := GridContainer.new()
	generation_grid.columns = 2
	generation_grid.add_theme_constant_override("h_separation", 14)
	generation_grid.add_theme_constant_override("v_separation", 10)
	add_child(generation_grid)

	generation_grid.add_child(_label("Use existing fields as context"))
	_include_existing = CheckBox.new()
	_include_existing.text = "Preserve and improve existing content when useful"
	generation_grid.add_child(_include_existing)

	generation_grid.add_child(_label("Automatic retries"))
	_retry_count = SpinBox.new()
	_retry_count.min_value = 0
	_retry_count.max_value = 5
	_retry_count.step = 1
	_retry_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	generation_grid.add_child(_retry_count)

	generation_grid.add_child(_label("Default idea count"))
	_idea_count = SpinBox.new()
	_idea_count.min_value = 1
	_idea_count.max_value = 12
	_idea_count.step = 1
	_idea_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	generation_grid.add_child(_idea_count)

	generation_grid.add_child(_label("Attachment context limit"))
	_attachment_context_limit = SpinBox.new()
	_attachment_context_limit.min_value = 2000
	_attachment_context_limit.max_value = 120000
	_attachment_context_limit.step = 1000
	_attachment_context_limit.suffix = " characters"
	_attachment_context_limit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	generation_grid.add_child(_attachment_context_limit)

	generation_grid.add_child(_label("Default image size"))
	_default_image_size = LineEdit.new()
	_default_image_size.placeholder_text = "1024x1024 or auto"
	_default_image_size.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	generation_grid.add_child(_default_image_size)

	generation_grid.add_child(_label("Default image prompt style"))
	_image_prompt_style = OptionButton.new()
	for style_entry in [
		{"label": "Auto", "value": "auto"},
		{"label": "Natural language", "value": "natural"},
		{"label": "Stable Diffusion style", "value": "stable_diffusion"}
	]:
		_image_prompt_style.add_item(str(style_entry["label"]))
		_image_prompt_style.set_item_metadata(
			_image_prompt_style.item_count - 1, str(style_entry["value"])
		)
	_image_prompt_style.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	generation_grid.add_child(_image_prompt_style)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	add_child(actions)

	var save_button := Button.new()
	save_button.text = "Save Settings"
	save_button.custom_minimum_size = Vector2(150, 42)
	save_button.pressed.connect(_save)
	actions.add_child(save_button)

	var folder_button := Button.new()
	folder_button.text = "Open Data Folder"
	folder_button.pressed.connect(func(): OS.shell_open(CCFStorageService.user_data_path()))
	actions.add_child(folder_button)

	_status = Label.new()
	_status.modulate = Color(0.72, 0.82, 0.72)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)

	load_settings(CCFSettingsService.load_settings())


func load_settings(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	if _profile_selector == null:
		return
	_refresh_profile_selector()
	_refresh_role_selectors()
	_load_active_profile()
	var generation_settings: Dictionary = _settings.get("generation", {})
	_include_existing.button_pressed = bool(
		generation_settings.get("include_existing_fields", true)
	)
	_retry_count.value = int(generation_settings.get("retry_count", 1))
	_idea_count.value = int(generation_settings.get("default_idea_count", 6))
	_attachment_context_limit.value = int(
		generation_settings.get("attachment_context_character_limit", 24000)
	)
	_default_image_size.text = str(generation_settings.get("default_image_size", "1024x1024"))
	_select_metadata(
		_image_prompt_style, str(generation_settings.get("default_image_prompt_style", "auto"))
	)


func _save() -> void:
	_capture_loaded_profile()
	_capture_role_assignments()
	var generation_settings: Dictionary = _settings.get("generation", {}).duplicate(true)
	generation_settings["include_existing_fields"] = _include_existing.button_pressed
	generation_settings["retry_count"] = int(_retry_count.value)
	generation_settings["default_idea_count"] = int(_idea_count.value)
	generation_settings["attachment_context_character_limit"] = int(
		_attachment_context_limit.value
	)
	generation_settings["default_image_size"] = _default_image_size.text.strip_edges()
	generation_settings["default_image_prompt_style"] = (
		str(_image_prompt_style.get_selected_metadata())
		if _image_prompt_style.selected >= 0
		else "auto"
	)
	_settings["generation"] = generation_settings

	var result := CCFSettingsService.save_settings(_settings)
	if result.get("ok", false):
		_status.text = "Settings saved. Text, vision, and image provider assignments are now active."
		settings_saved.emit(_settings.duplicate(true))
	else:
		_status.text = str(result.get("error", "Could not save settings."))


func _refresh_profile_selector() -> void:
	_loading_profile = true
	_profile_selector.clear()
	var active_id := str(_settings.get("active_api_profile_id", "default"))
	var selected_index := 0
	var profiles = _settings.get("api_profiles", [])
	if profiles is Array:
		for profile in profiles:
			if not profile is Dictionary:
				continue
			var display_name := str(profile.get("name", "Profile"))
			var profile_id := str(profile.get("id", ""))
			_profile_selector.add_item(display_name)
			var item_index := _profile_selector.item_count - 1
			_profile_selector.set_item_metadata(item_index, profile_id)
			if profile_id == active_id:
				selected_index = item_index
	if _profile_selector.item_count > 0:
		_profile_selector.select(selected_index)
	_loading_profile = false


func _refresh_role_selectors() -> void:
	_loading_roles = true
	var text_id := CCFSettingsService.role_profile_id(_settings, CCFSettingsService.ROLE_TEXT)
	var vision_id := CCFSettingsService.role_profile_id(
		_settings, CCFSettingsService.ROLE_VISION
	)
	var image_id := CCFSettingsService.role_profile_id(
		_settings, CCFSettingsService.ROLE_IMAGE
	)
	for selector in [_text_role_selector, _vision_role_selector, _image_role_selector]:
		selector.clear()
		for profile in _settings.get("api_profiles", []):
			if not profile is Dictionary:
				continue
			selector.add_item(str(profile.get("name", "Profile")))
			selector.set_item_metadata(
				selector.item_count - 1, str(profile.get("id", "default"))
			)
	_select_profile_id(_text_role_selector, text_id)
	_select_profile_id(_vision_role_selector, vision_id)
	_select_profile_id(_image_role_selector, image_id)
	_loading_roles = false


func _load_active_profile() -> void:
	var profile := CCFSettingsService.active_profile(_settings)
	_loaded_profile_id = str(profile.get("id", "default"))
	_profile_name.text = str(profile.get("name", "Default"))
	_base_url.text = str(profile.get("base_url", ""))
	_api_key.text = str(profile.get("api_key", ""))
	_model.text = str(profile.get("model", ""))
	_temperature.value = float(profile.get("temperature", 0.8))
	_max_tokens.value = int(profile.get("max_output_tokens", 6000))
	_select_metadata(_vision_detail, str(profile.get("vision_detail", "auto")))
	_reset_fetched_models()


func _capture_loaded_profile() -> void:
	if _loaded_profile_id.is_empty():
		return
	var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id).duplicate(true)
	var display_name := _profile_name.text.strip_edges()
	profile["name"] = display_name if not display_name.is_empty() else "Profile"
	profile["base_url"] = _base_url.text.strip_edges()
	profile["api_key"] = _api_key.text.strip_edges()
	profile["model"] = _model.text.strip_edges()
	profile["temperature"] = _temperature.value
	profile["max_output_tokens"] = int(_max_tokens.value)
	profile["vision_detail"] = (
		str(_vision_detail.get_selected_metadata())
		if _vision_detail.selected >= 0
		else "auto"
	)
	CCFSettingsService.replace_profile_by_id(_settings, _loaded_profile_id, profile)


func _capture_role_assignments() -> void:
	if _text_role_selector.selected >= 0:
		CCFSettingsService.set_role_profile(
			_settings,
			CCFSettingsService.ROLE_TEXT,
			str(_text_role_selector.get_selected_metadata())
		)
	if _vision_role_selector.selected >= 0:
		CCFSettingsService.set_role_profile(
			_settings,
			CCFSettingsService.ROLE_VISION,
			str(_vision_role_selector.get_selected_metadata())
		)
	if _image_role_selector.selected >= 0:
		CCFSettingsService.set_role_profile(
			_settings,
			CCFSettingsService.ROLE_IMAGE,
			str(_image_role_selector.get_selected_metadata())
		)


func _on_profile_selected(index: int) -> void:
	if _loading_profile or index < 0:
		return
	_capture_loaded_profile()
	var profile_id := str(_profile_selector.get_item_metadata(index))
	if profile_id.is_empty():
		return
	_settings["active_api_profile_id"] = profile_id
	_load_active_profile()
	_status.text = "Profile selected for editing. Press Save Settings to persist changes."


func _on_role_selected(_index: int, role: String) -> void:
	if _loading_roles:
		return
	_capture_role_assignments()
	_status.text = "%s provider assignment changed locally. Press Save Settings to persist it." % role.capitalize()


func _create_profile() -> void:
	_capture_loaded_profile()
	CCFSettingsService.create_profile(_settings)
	_refresh_profile_selector()
	_refresh_role_selectors()
	_load_active_profile()
	_status.text = "New API profile created and assigned to text generation."


func _duplicate_profile() -> void:
	_capture_loaded_profile()
	CCFSettingsService.duplicate_active_profile(_settings)
	_refresh_profile_selector()
	_refresh_role_selectors()
	_load_active_profile()
	_status.text = "API profile duplicated and assigned to text generation."


func _delete_profile() -> void:
	_capture_loaded_profile()
	var result := CCFSettingsService.delete_active_profile(_settings)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not delete profile."))
		return
	_refresh_profile_selector()
	_refresh_role_selectors()
	_load_active_profile()
	_status.text = "API profile deleted. Any affected provider roles used the remaining profile."


func _fetch_models() -> void:
	_capture_loaded_profile()
	var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id)
	var result := _model_service.fetch_models(profile)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not fetch models."))
		return
	_fetch_models_button.disabled = true
	_status.text = "Fetching model list…"


func _on_models_loaded(models: Array) -> void:
	_fetch_models_button.disabled = false
	_fetched_models.clear()
	_fetched_models.add_item("Choose a fetched model…")
	_fetched_models.set_item_disabled(0, true)
	for model_id in models:
		_fetched_models.add_item(str(model_id))
	_fetched_models.select(0)
	_status.text = "Loaded %d model IDs." % models.size()


func _on_models_failed(message: String) -> void:
	_fetch_models_button.disabled = false
	_status.text = message


func _on_fetched_model_selected(index: int) -> void:
	if index <= 0:
		return
	_model.text = _fetched_models.get_item_text(index)
	_status.text = "Selected model %s. Press Save Settings to persist it." % _model.text


func _reset_fetched_models() -> void:
	_fetched_models.clear()
	_fetched_models.add_item("Fetch models to populate this list")
	_fetched_models.set_item_disabled(0, true)
	_fetched_models.select(0)


func _select_profile_id(selector: OptionButton, profile_id: String) -> void:
	for index in range(selector.item_count):
		if str(selector.get_item_metadata(index)) == profile_id:
			selector.select(index)
			return
	if selector.item_count > 0:
		selector.select(0)


func _select_metadata(selector: OptionButton, value: String) -> void:
	for index in range(selector.item_count):
		if str(selector.get_item_metadata(index)) == value:
			selector.select(index)
			return
	if selector.item_count > 0:
		selector.select(0)


func _add_line(grid: GridContainer, label_text: String) -> LineEdit:
	grid.add_child(_label(label_text))
	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(edit)
	return edit


func _label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 220
	return label
