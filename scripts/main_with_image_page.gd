extends "res://scripts/main.gd"

var _image_page: CCFImageGenerationPage


func _build_image_generation_window() -> void:
	_image_generation_window = CCFImageGenerationController.new()
	_image_generation_window.visible = false
	_image_generation_window.title = "Character Card Forge — Image Generation Studio"
	_image_generation_window.size = Vector2i(1180, 820)
	_image_generation_window.min_size = Vector2i(920, 650)
	_image_generation_window.force_native = true
	_image_generation_window.transient = true
	_image_generation_window.exclusive = false
	_image_generation_window.project_changed.connect(_on_image_project_changed)
	add_child(_image_generation_window)
	_image_generation_window.hide()


func _ready() -> void:
	super._ready()
	_register_image_nav_button()
	_image_page = CCFImageGenerationPage.new()
	_image_page.visible = false
	_image_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_image_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_image_page.settings_requested.connect(_open_image_provider_settings)
	_content.add_child(_image_page)
	_image_page.attach_controller(_image_generation_window)
	if str(_settings.get("ui", {}).get("last_view", "dashboard")) == "image":
		_show_image_page()


func _register_image_nav_button() -> void:
	for node in find_children("*", "Button", true, false):
		if node is Button and node.text == "Image Studio":
			_nav_buttons["image"] = node
			return


func _open_image_provider_settings() -> void:
	_show_view("settings")
	if _settings_view != null:
		_settings_view.show_image_settings()


func _open_image_studio() -> void:
	if _image_page == null:
		return
	if _workspace != null and _workspace.has_unsaved_changes():
		_global_status.text = "Image Studio uses saved projects. Save workspace changes first if you want them included in image prompts."
	_show_image_page()


func _show_view(view_id: String) -> void:
	if _image_page != null:
		_image_page.visible = false
	super._show_view(view_id)


func _show_image_page() -> void:
	if _image_page == null:
		return
	_current_view = "image"
	_dashboard.visible = false
	_library.visible = false
	_workspace.visible = false
	_series_manager.visible = false
	_template_manager.visible = false
	_settings_view.visible = false
	_image_page.visible = true
	_page_title.text = "Image Generation Studio"
	for nav_id in _nav_buttons:
		var button: Button = _nav_buttons[nav_id]
		button.disabled = nav_id == "image"
	_image_page.refresh()
	var ui: Dictionary = _settings.get("ui", {}).duplicate(true)
	ui["last_view"] = "image"
	_settings["ui"] = ui
	CCFSettingsService.save_settings(_settings)
