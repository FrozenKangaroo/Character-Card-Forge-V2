class_name CCFImageProviderSettingsView
extends VBoxContainer

signal settings_saved(settings: Dictionary)

var _settings: Dictionary = {}
var _profile_selector: OptionButton
var _default_selector: OptionButton
var _name_edit: LineEdit
var _backend_selector: OptionButton
var _url_label: Label
var _url_edit: LineEdit
var _api_key_label: Label
var _api_key_edit: LineEdit
var _api_key_row: HBoxContainer
var _size_edit: LineEdit
var _prompt_style: OptionButton
var _status: Label
var _capability_service: CCFImageCapabilityService
var _loading := false


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_capability_service = CCFImageCapabilityService.new()
	add_child(_capability_service)
	_capability_service.capabilities_loaded.connect(_on_capabilities_loaded)
	_capability_service.capabilities_failed.connect(_on_capabilities_failed)
	_build_ui()


func load_settings(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	if _profile_selector == null:
		return
	_refresh_selectors()
	_load_selected_profile()
	var generation: Dictionary = _settings.get("generation", {})
	_size_edit.text = str(generation.get("default_image_size", "1024x1024"))
	_select_metadata(_prompt_style, str(generation.get("default_image_prompt_style", "auto")))


func _build_ui() -> void:
	add_child(HSeparator.new())
	var heading := Label.new()
	heading.text = "Image generation providers"
	heading.add_theme_font_size_override("font_size", 22)
	add_child(heading)

	var hint := Label.new()
	hint.text = "Image providers are separate from character text/vision providers. A local Stable Diffusion server will never reuse your NanoGPT/OpenAI-compatible text URL, model, or API key."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.75, 0.77, 0.84)
	add_child(hint)

	var default_row := HBoxContainer.new()
	default_row.add_theme_constant_override("separation", 10)
	add_child(default_row)
	default_row.add_child(_label("Image Studio default"))
	_default_selector = OptionButton.new()
	_default_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_selector.item_selected.connect(_on_default_selected)
	default_row.add_child(_default_selector)

	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 8)
	add_child(profile_row)
	profile_row.add_child(_label("Edit image provider"))
	_profile_selector = OptionButton.new()
	_profile_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_selector.item_selected.connect(_on_profile_selected)
	profile_row.add_child(_profile_selector)
	var new_button := Button.new()
	new_button.text = "New"
	new_button.pressed.connect(_create_profile)
	profile_row.add_child(new_button)
	var duplicate_button := Button.new()
	duplicate_button.text = "Duplicate"
	duplicate_button.pressed.connect(_duplicate_profile)
	profile_row.add_child(duplicate_button)
	var delete_button := Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(_delete_profile)
	profile_row.add_child(delete_button)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	add_child(name_row)
	name_row.add_child(_label("Provider name"))
	_name_edit = LineEdit.new()
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name_edit)

	var backend_row := HBoxContainer.new()
	backend_row.add_theme_constant_override("separation", 10)
	add_child(backend_row)
	backend_row.add_child(_label("Backend"))
	_backend_selector = OptionButton.new()
	_backend_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_backend_selector.add_item("Stable Diffusion Forge / Automatic1111")
	_backend_selector.set_item_metadata(0, CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111)
	_backend_selector.add_item("OpenAI-compatible Images API")
	_backend_selector.set_item_metadata(1, CCFSettingsService.IMAGE_BACKEND_OPENAI)
	_backend_selector.item_selected.connect(_on_backend_selected)
	backend_row.add_child(_backend_selector)

	var url_row := HBoxContainer.new()
	url_row.add_theme_constant_override("separation", 10)
	add_child(url_row)
	_url_label = _label("Server URL")
	url_row.add_child(_url_label)
	_url_edit = LineEdit.new()
	_url_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_url_edit.placeholder_text = "http://127.0.0.1:7860"
	url_row.add_child(_url_edit)

	_api_key_row = HBoxContainer.new()
	_api_key_row.add_theme_constant_override("separation", 10)
	add_child(_api_key_row)
	_api_key_label = _label("API key")
	_api_key_row.add_child(_api_key_label)
	_api_key_edit = LineEdit.new()
	_api_key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_api_key_edit.secret = true
	_api_key_edit.placeholder_text = "Required only by the remote image provider"
	_api_key_row.add_child(_api_key_edit)

	var defaults_heading := Label.new()
	defaults_heading.text = "Image generation defaults"
	defaults_heading.add_theme_font_size_override("font_size", 18)
	add_child(defaults_heading)

	var size_row := HBoxContainer.new()
	size_row.add_theme_constant_override("separation", 10)
	add_child(size_row)
	size_row.add_child(_label("Default image size"))
	_size_edit = LineEdit.new()
	_size_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_size_edit.placeholder_text = "1024x1024"
	size_row.add_child(_size_edit)

	var style_row := HBoxContainer.new()
	style_row.add_theme_constant_override("separation", 10)
	add_child(style_row)
	style_row.add_child(_label("Default prompt style"))
	_prompt_style = OptionButton.new()
	_prompt_style.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry in [
		{"label": "Auto", "value": "auto"},
		{"label": "Natural language", "value": "natural"},
		{"label": "Stable Diffusion style", "value": "stable_diffusion"}
	]:
		_prompt_style.add_item(str(entry["label"]))
		_prompt_style.set_item_metadata(_prompt_style.item_count - 1, str(entry["value"]))
	style_row.add_child(_prompt_style)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	add_child(actions)
	var save_button := Button.new()
	save_button.text = "Save Image Settings"
	save_button.pressed.connect(_save)
	actions.add_child(save_button)
	var discover_button := Button.new()
	discover_button.text = "Test / Discover"
	discover_button.tooltip_text = "Save first, then test the selected image provider and discover checkpoints/models."
	discover_button.pressed.connect(_test_discover)
	actions.add_child(discover_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.7, 0.82, 0.72)
	add_child(_status)


func _refresh_selectors() -> void:
	_loading = true
	var profiles := CCFSettingsService.image_profiles(_settings)
	var current_edit_id := ""
	if _profile_selector.selected >= 0:
		current_edit_id = str(_profile_selector.get_selected_metadata())
	var default_id := CCFSettingsService.role_profile_id(_settings, CCFSettingsService.ROLE_IMAGE)
	_profile_selector.clear()
	_default_selector.clear()
	var edit_index := 0
	var default_index := 0
	for index in range(profiles.size()):
		var profile: Dictionary = profiles[index]
		var profile_id := str(profile.get("id", "image_default"))
		var profile_name := str(profile.get("name", "Image Provider"))
		_profile_selector.add_item(profile_name)
		_profile_selector.set_item_metadata(index, profile_id)
		_default_selector.add_item(profile_name)
		_default_selector.set_item_metadata(index, profile_id)
		if profile_id == current_edit_id:
			edit_index = index
		if profile_id == default_id:
			default_index = index
	if _profile_selector.item_count > 0:
		_profile_selector.select(edit_index)
		_default_selector.select(default_index)
	_loading = false


func _load_selected_profile() -> void:
	if _profile_selector.selected < 0:
		return
	var profile := CCFSettingsService.image_profile_by_id(
		_settings, str(_profile_selector.get_selected_metadata())
	)
	_name_edit.text = str(profile.get("name", "Image Provider"))
	_select_metadata(_backend_selector, CCFSettingsService.image_backend(profile))
	_url_edit.text = str(profile.get("base_url", ""))
	_api_key_edit.text = str(profile.get("api_key", ""))
	_update_backend_ui()


func _capture_selected_profile() -> void:
	if _profile_selector.selected < 0:
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	var profile := CCFSettingsService.image_profile_by_id(_settings, profile_id).duplicate(true)
	var display_name := _name_edit.text.strip_edges()
	profile["name"] = display_name if not display_name.is_empty() else "Image Provider"
	profile["image_backend"] = _selected_backend()
	var url_text := _url_edit.text.strip_edges()
	if profile["image_backend"] == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111 and url_text.is_empty():
		url_text = "http://127.0.0.1:7860"
	profile["base_url"] = url_text
	profile["api_key"] = _api_key_edit.text.strip_edges() if profile["image_backend"] == CCFSettingsService.IMAGE_BACKEND_OPENAI else ""
	CCFSettingsService.replace_image_profile_by_id(_settings, profile_id, profile)


func _save() -> bool:
	_capture_selected_profile()
	if _default_selector.selected >= 0:
		CCFSettingsService.set_role_profile(
			_settings, CCFSettingsService.ROLE_IMAGE, str(_default_selector.get_selected_metadata())
		)
	var generation: Dictionary = _settings.get("generation", {}).duplicate(true)
	var size_text := _size_edit.text.strip_edges()
	generation["default_image_size"] = size_text if not size_text.is_empty() else "1024x1024"
	generation["default_image_prompt_style"] = (
		str(_prompt_style.get_selected_metadata()) if _prompt_style.selected >= 0 else "auto"
	)
	_settings["generation"] = generation
	var result := CCFSettingsService.save_settings(_settings)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not save image settings."))
		return false
	_settings = CCFSettingsService.load_settings()
	_refresh_selectors()
	_load_selected_profile()
	_status.text = "Image provider settings saved."
	settings_saved.emit(_settings.duplicate(true))
	return true


func _test_discover() -> void:
	if not _save():
		return
	var profile := CCFSettingsService.image_profile_by_id(
		_settings, str(_profile_selector.get_selected_metadata())
	)
	var result := _capability_service.fetch_capabilities(profile)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not test the image provider."))
	else:
		_status.text = "Testing image provider and discovering available models…"


func _on_capabilities_loaded(capabilities: Dictionary) -> void:
	_status.text = "Connection successful: %d model/checkpoint(s), %d sampler(s) discovered." % [
		int(capabilities.get("models", []).size()), int(capabilities.get("samplers", []).size())
	]


func _on_capabilities_failed(message_text: String) -> void:
	var lower := message_text.to_lower()
	if "<!doctype html" in lower or "<html" in lower:
		_status.text = "The server returned a webpage instead of the image API. For a normal local Forge/A1111 install, use Server URL http://127.0.0.1:7860 and ensure WebUI API access is enabled."
	else:
		_status.text = message_text


func _on_profile_selected(_index: int) -> void:
	if _loading:
		return
	_load_selected_profile()


func _on_default_selected(_index: int) -> void:
	if _loading:
		return
	_status.text = "Image Studio default changed locally. Press Save Image Settings to persist it."


func _on_backend_selected(_index: int) -> void:
	if _loading:
		return
	_update_backend_ui()


func _update_backend_ui() -> void:
	var is_sd := _selected_backend() == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111
	_url_label.text = "Server URL" if is_sd else "API base URL"
	_url_edit.placeholder_text = "http://127.0.0.1:7860" if is_sd else "https://provider.example/v1"
	_api_key_row.visible = not is_sd
	if is_sd and _url_edit.text.strip_edges().is_empty():
		_url_edit.text = "http://127.0.0.1:7860"
	_status.text = (
		"Local Forge/A1111 normally needs only the WebUI server URL. No API key is used for a normal local install."
		if is_sd else
		"OpenAI-compatible image providers may require their own API base URL and API key."
	)


func _create_profile() -> void:
	_capture_selected_profile()
	var created := CCFSettingsService.create_image_profile(_settings)
	_refresh_selectors()
	_select_profile(str(created.get("id", "")))
	_load_selected_profile()
	_status.text = "Created a separate local Stable Diffusion image provider."


func _duplicate_profile() -> void:
	if _profile_selector.selected < 0:
		return
	_capture_selected_profile()
	var source_id := str(_profile_selector.get_selected_metadata())
	var created := CCFSettingsService.duplicate_image_profile(_settings, source_id)
	_refresh_selectors()
	_select_profile(str(created.get("id", "")))
	_load_selected_profile()
	_status.text = "Image provider duplicated."


func _delete_profile() -> void:
	if _profile_selector.selected < 0:
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	var result := CCFSettingsService.delete_image_profile(_settings, profile_id)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not delete image provider."))
		return
	_refresh_selectors()
	_load_selected_profile()
	_status.text = "Image provider deleted."


func _select_profile(profile_id: String) -> void:
	for index in range(_profile_selector.item_count):
		if str(_profile_selector.get_item_metadata(index)) == profile_id:
			_profile_selector.select(index)
			return


func _selected_backend() -> String:
	if _backend_selector.selected < 0:
		return CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111
	return str(_backend_selector.get_selected_metadata())


func _select_metadata(selector: OptionButton, value: String) -> void:
	for index in range(selector.item_count):
		if str(selector.get_item_metadata(index)) == value:
			selector.select(index)
			return
	if selector.item_count > 0:
		selector.select(0)


func _label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size.x = 220
	return label
