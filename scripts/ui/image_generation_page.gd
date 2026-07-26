class_name CCFImageGenerationPage
extends VBoxContainer

var _controller: CCFImageGenerationWindow
var _backend_selector: OptionButton
var _server_url_edit: LineEdit
var _api_key_edit: LineEdit
var _save_button: Button
var _save_discover_button: Button
var _connection_status: Label
var _mounted := false


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build_connection_panel()


func attach_controller(controller: CCFImageGenerationWindow) -> void:
	_controller = controller
	if _controller == null:
		_connection_status.text = "Image Studio controller is unavailable."
		return
	_mount_controller_ui()
	if _controller._profile_selector != null:
		_controller._profile_selector.item_selected.connect(_on_controller_profile_selected)
	if _controller._capability_service != null:
		_controller._capability_service.capabilities_failed.connect(_on_capability_failure)
	refresh()


func refresh() -> void:
	if _controller == null:
		return
	_controller._reload_settings()
	_controller._refresh_profiles()
	_controller._refresh_projects()
	_load_connection_from_selected_profile()


func _build_connection_panel() -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var title_label := Label.new()
	title_label.text = "Image provider connection"
	title_label.add_theme_font_size_override("font_size", 18)
	root.add_child(title_label)

	var hint := Label.new()
	hint.text = "Connection settings for the provider selected below in Image Studio. For Forge / Automatic1111, enter the WebUI server root including its port, for example http://127.0.0.1:7860. The app adds /sdapi/v1 endpoints automatically."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.68, 0.72, 0.82)
	root.add_child(hint)

	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)

	row.add_child(_label("Backend"))
	_backend_selector = OptionButton.new()
	_backend_selector.custom_minimum_size.x = 270
	_backend_selector.add_item("OpenAI-compatible Images API")
	_backend_selector.set_item_metadata(
		_backend_selector.item_count - 1,
		CCFSettingsService.IMAGE_BACKEND_OPENAI
	)
	_backend_selector.add_item("Stable Diffusion Forge / Automatic1111")
	_backend_selector.set_item_metadata(
		_backend_selector.item_count - 1,
		CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111
	)
	row.add_child(_backend_selector)

	row.add_child(_label("Server URL / port"))
	_server_url_edit = LineEdit.new()
	_server_url_edit.custom_minimum_size.x = 360
	_server_url_edit.placeholder_text = "http://127.0.0.1:7860"
	row.add_child(_server_url_edit)

	row.add_child(_label("API key"))
	_api_key_edit = LineEdit.new()
	_api_key_edit.custom_minimum_size.x = 210
	_api_key_edit.placeholder_text = "Optional"
	_api_key_edit.secret = true
	row.add_child(_api_key_edit)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)

	_save_button = Button.new()
	_save_button.text = "Save Connection"
	_save_button.pressed.connect(func(): _save_connection(false))
	actions.add_child(_save_button)

	_save_discover_button = Button.new()
	_save_discover_button.text = "Save & Discover"
	_save_discover_button.tooltip_text = "Save this backend/server configuration, then discover image models and Stable Diffusion samplers."
	_save_discover_button.pressed.connect(func(): _save_connection(true))
	actions.add_child(_save_discover_button)

	var api_hint := Label.new()
	api_hint.text = "Forge/A1111 must expose its WebUI API. Some installations require starting the WebUI with API access enabled (commonly --api). A 404 page containing HTML usually means the URL/port points at a website or proxy instead of the WebUI API server."
	api_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	api_hint.modulate = Color(0.62, 0.68, 0.78)
	root.add_child(api_hint)

	_connection_status = Label.new()
	_connection_status.text = "Select an image provider below to edit its connection."
	_connection_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_connection_status.modulate = Color(0.7, 0.82, 0.72)
	root.add_child(_connection_status)


func _mount_controller_ui() -> void:
	if _mounted or _controller == null:
		return
	var studio_root: Control = null
	for child in _controller.get_children():
		if child is MarginContainer:
			studio_root = child
			break
	if studio_root == null:
		_connection_status.text = "Could not mount the Image Studio interface into the main workspace."
		return
	studio_root.reparent(self)
	studio_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	studio_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	studio_root.visible = true
	_controller.hide()
	_mounted = true


func _on_controller_profile_selected(_index: int) -> void:
	_load_connection_from_selected_profile()


func _load_connection_from_selected_profile() -> void:
	if _controller == null or _controller._profile_selector == null:
		return
	var profile := _controller._selected_profile()
	_server_url_edit.text = str(profile.get("base_url", ""))
	_api_key_edit.text = str(profile.get("api_key", ""))
	_select_backend(CCFSettingsService.image_backend(profile))
	var name_text := str(profile.get("name", "Image provider"))
	_connection_status.text = "Editing connection for %s." % name_text


func _save_connection(discover_after_save: bool) -> void:
	if _controller == null or _controller._profile_selector == null:
		return
	if _controller._profile_selector.selected < 0:
		_connection_status.text = "Select an image provider first."
		return
	var server_url := _server_url_edit.text.strip_edges()
	if server_url.is_empty():
		_connection_status.text = "Enter the image provider server URL before saving."
		return
	var backend := _selected_backend()
	if backend == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111:
		if not server_url.begins_with("http://") and not server_url.begins_with("https://"):
			_connection_status.text = "Forge/A1111 server URL must begin with http:// or https://, for example http://127.0.0.1:7860."
			return

	var profile_id := str(_controller._profile_selector.get_selected_metadata())
	var settings := CCFSettingsService.load_settings()
	var profile := CCFSettingsService.profile_by_id(settings, profile_id).duplicate(true)
	profile["base_url"] = server_url
	profile["api_key"] = _api_key_edit.text.strip_edges()
	profile["image_backend"] = backend
	CCFSettingsService.replace_profile_by_id(settings, profile_id, profile)
	CCFSettingsService.set_role_profile(settings, CCFSettingsService.ROLE_IMAGE, profile_id)
	var save_result := CCFSettingsService.save_settings(settings)
	if not bool(save_result.get("ok", false)):
		_connection_status.text = str(save_result.get("error", "Could not save the image provider connection."))
		return

	_controller._settings = CCFSettingsService.load_settings()
	_controller._refresh_profiles()
	_controller._select_profile_by_id(profile_id)
	_load_connection_from_selected_profile()
	var backend_text := "Forge / Automatic1111" if backend == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111 else "OpenAI-compatible Images"
	_connection_status.text = "Saved %s connection at %s." % [backend_text, server_url]
	_controller._status.text = _connection_status.text
	if discover_after_save:
		_controller._discover_capabilities()


func _on_capability_failure(message_text: String) -> void:
	if _controller == null:
		return
	var lower_message := message_text.to_lower()
	if "<!doctype html" in lower_message or "<html" in lower_message:
		var profile := _controller._selected_profile()
		var server_url := str(profile.get("base_url", "")).strip_edges()
		var friendly := "The image server returned an HTML webpage instead of API JSON. Check Server URL / port (%s) and make sure Forge/A1111 WebUI API access is enabled. For a local default install, try http://127.0.0.1:7860." % server_url
		_connection_status.text = friendly
		_controller._status.text = friendly
	else:
		_connection_status.text = message_text


func _select_backend(backend: String) -> void:
	for index in range(_backend_selector.item_count):
		if str(_backend_selector.get_item_metadata(index)) == backend:
			_backend_selector.select(index)
			return
	if _backend_selector.item_count > 0:
		_backend_selector.select(0)


func _selected_backend() -> String:
	if _backend_selector.selected < 0:
		return CCFSettingsService.IMAGE_BACKEND_OPENAI
	return str(_backend_selector.get_selected_metadata())


func _label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	return label
