extends "res://scripts/main_v01528.gd"

const IMAGE_WINDOW_V01529 = preload(
	"res://scripts/ui/image_generation_window_v01529.gd"
)
const BUILD_DISPLAY_VERSION_V01529 := "0.15.29"

var _image_page_v01529: CCFImageGenerationPage


func _ready() -> void:
	super._ready()
	_install_image_window_v01529()
	_install_embedded_image_page_v01529()
	_update_build_version_label()
	var last_view := str(_settings.get("ui", {}).get("last_view", "dashboard"))
	if last_view == "image":
		_show_image_page_v01529()


func _install_image_window_v01529() -> void:
	var previous := _image_generation_window
	if previous != null and previous.get_script() == IMAGE_WINDOW_V01529:
		_inject_image_scheduler_v01526()
		return
	if previous != null:
		if previous.project_changed.is_connected(_on_image_project_changed):
			previous.project_changed.disconnect(_on_image_project_changed)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded := IMAGE_WINDOW_V01529.new() as CCFImageGenerationWindowV01529
	upgraded.visible = false
	upgraded.title = "Character Card Forge — Image Generation Studio"
	upgraded.size = Vector2i(1180, 820)
	upgraded.min_size = Vector2i(920, 650)
	upgraded.force_native = true
	upgraded.transient = true
	upgraded.exclusive = false
	upgraded.project_changed.connect(_on_image_project_changed)
	_image_generation_window = upgraded
	add_child(upgraded)
	upgraded.hide()
	_inject_image_scheduler_v01526()
	upgraded.update_settings_v01528(_settings)
	_sync_current_workspace_to_image_studio_v01528()


func _install_embedded_image_page_v01529() -> void:
	if _content == null or _image_generation_window == null:
		return
	for child in _content.get_children():
		if child is CCFImageGenerationPage:
			(child as CCFImageGenerationPage).visible = false

	_image_page_v01529 = CCFImageGenerationPage.new()
	_image_page_v01529.visible = false
	_image_page_v01529.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_image_page_v01529.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_image_page_v01529.settings_requested.connect(
		_open_image_provider_settings_v01529
	)
	_content.add_child(_image_page_v01529)
	_image_page_v01529.attach_controller(_image_generation_window)
	_register_image_nav_button_v01529()


func _register_image_nav_button_v01529() -> void:
	for node in find_children("*", "Button", true, false):
		if node is Button and node.text == "Image Studio":
			_nav_buttons["image"] = node
			return


func _open_image_studio() -> void:
	if _image_page_v01529 == null:
		_global_status.text = "Image Studio page is unavailable."
		return
	if _workspace != null and _workspace.has_unsaved_changes():
		_global_status.text = (
			"Image Studio uses saved projects. Save workspace changes first if you want them included in image prompts."
		)
	else:
		_sync_current_workspace_to_image_studio_v01528()
	_show_image_page_v01529()


func _show_view(view_id: String) -> void:
	if _image_page_v01529 != null:
		_image_page_v01529.visible = false
	super._show_view(view_id)


func _show_image_page_v01529() -> void:
	if _image_page_v01529 == null:
		return
	_current_view = "image"
	_dashboard.visible = false
	_library.visible = false
	_workspace.visible = false
	_series_manager.visible = false
	_template_manager.visible = false
	_settings_view.visible = false
	for child in _content.get_children():
		if child is CCFImageGenerationPage and child != _image_page_v01529:
			(child as CCFImageGenerationPage).visible = false
	_image_page_v01529.visible = true
	_page_title.text = "Image Generation Studio"
	for nav_id in _nav_buttons:
		var button: Button = _nav_buttons[nav_id]
		button.disabled = nav_id == "image"
	_image_page_v01529.refresh()
	var ui: Dictionary = _settings.get("ui", {}).duplicate(true)
	ui["last_view"] = "image"
	_settings["ui"] = ui
	CCFSettingsService.save_settings(_settings)


func _open_image_provider_settings_v01529() -> void:
	_show_view("settings")
	if _settings_view != null and _settings_view.has_method("show_image_settings"):
		_settings_view.call("show_image_settings")


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01529
			node.tooltip_text = (
				"Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			)
			return
