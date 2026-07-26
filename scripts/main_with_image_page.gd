extends "res://scripts/main.gd"

var _image_page: CCFImageGenerationPage


func _ready() -> void:
	super._ready()
	_image_page = CCFImageGenerationPage.new()
	_image_page.visible = false
	_image_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_image_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_image_page)
	_image_page.attach_controller(_image_generation_window)
	if str(_settings.get("ui", {}).get("last_view", "dashboard")) == "image":
		_show_image_page()


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
		button.disabled = false
	_image_page.refresh()
	var ui: Dictionary = _settings.get("ui", {}).duplicate(true)
	ui["last_view"] = "image"
	_settings["ui"] = ui
	CCFSettingsService.save_settings(_settings)
