class_name CCFImageGenerationPage
extends VBoxContainer

signal settings_requested

var _controller: CCFImageGenerationWindow
var _mounted := false
var _page_status: Label


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build_header()


func attach_controller(controller: CCFImageGenerationWindow) -> void:
	_controller = controller
	if _controller == null:
		_page_status.text = "Image Studio controller is unavailable."
		return
	_mount_controller_ui()
	if _controller._capability_service != null:
		_controller._capability_service.capabilities_failed.connect(_on_capability_failure)
	refresh()


func refresh() -> void:
	if _controller == null:
		return
	_controller._reload_settings()
	_controller._refresh_profiles()
	_controller._refresh_projects()
	_page_status.text = "Image provider connections are configured in Settings. Image Studio is for prompting, generation, discovery, gallery work, and reproducible seeds."


func _build_header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var hint := Label.new()
	hint.text = "Image Studio"
	hint.add_theme_font_size_override("font_size", 18)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hint)
	var settings_button := Button.new()
	settings_button.text = "Manage Image Providers in Settings"
	settings_button.pressed.connect(func(): settings_requested.emit())
	row.add_child(settings_button)

	_page_status = Label.new()
	_page_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_status.modulate = Color(0.68, 0.74, 0.84)
	add_child(_page_status)


func _mount_controller_ui() -> void:
	if _mounted or _controller == null:
		return
	var studio_root: Control = null
	for child in _controller.get_children():
		if child is MarginContainer:
			studio_root = child
			break
	if studio_root == null:
		_page_status.text = "Could not mount the Image Studio interface into the main workspace."
		return
	studio_root.reparent(self)
	studio_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	studio_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	studio_root.visible = true
	_controller.hide()
	_mounted = true


func _on_capability_failure(message_text: String) -> void:
	if _controller == null:
		return
	var lower_message := message_text.to_lower()
	if "<!doctype html" in lower_message or "<html" in lower_message:
		var profile := _controller._selected_profile()
		var server_url := str(profile.get("base_url", "")).strip_edges()
		var friendly := "The image server returned a webpage instead of API JSON. Open Settings → Image generation providers and check the image provider URL (%s). A normal local Forge/A1111 install usually uses http://127.0.0.1:7860 with WebUI API access enabled." % server_url
		_page_status.text = friendly
		_controller._status.text = friendly
	else:
		_page_status.text = message_text
