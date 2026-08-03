extends "res://scripts/main_v01527.gd"

const SETTINGS_VIEW_V01528 = preload(
	"res://scripts/ui/settings_view_v01528.gd"
)
const IMAGE_WINDOW_V01528 = preload(
	"res://scripts/ui/image_generation_window_v01528.gd"
)
const BUILD_DISPLAY_VERSION_V01528 := "0.15.28"


func _ready() -> void:
	super._ready()
	_install_settings_view_v01528()
	_install_image_window_v01528()
	_update_build_version_label()


func _install_settings_view_v01528() -> void:
	if _content == null:
		return
	var previous_settings: CCFSettingsView = _settings_view
	if previous_settings != null and previous_settings.get_script() == SETTINGS_VIEW_V01528:
		previous_settings.load_settings(_settings)
		return
	var should_be_visible := _current_view == "settings"
	if previous_settings != null:
		if previous_settings.settings_saved.is_connected(_on_settings_saved):
			previous_settings.settings_saved.disconnect(_on_settings_saved)
		if previous_settings.get_parent() == _content:
			_content.remove_child(previous_settings)
		previous_settings.queue_free()
	var upgraded: CCFSettingsView = SETTINGS_VIEW_V01528.new()
	upgraded.visible = should_be_visible
	upgraded.settings_saved.connect(_on_settings_saved)
	_settings_view = upgraded
	_content.add_child(upgraded)
	upgraded.load_settings(_settings)


func _install_image_window_v01528() -> void:
	var previous := _image_generation_window
	if previous != null and previous.get_script() == IMAGE_WINDOW_V01528:
		_inject_image_scheduler_v01526()
		return
	if previous != null:
		if previous.project_changed.is_connected(_on_image_project_changed):
			previous.project_changed.disconnect(_on_image_project_changed)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded := IMAGE_WINDOW_V01528.new() as CCFImageGenerationWindowV01528
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


func _on_project_saved(project: Dictionary) -> void:
	super._on_project_saved(project)
	if _image_generation_window is CCFImageGenerationWindowV01528:
		(_image_generation_window as CCFImageGenerationWindowV01528).sync_saved_project_v01528(
			project,
			CCFStorageService.active_character_id(project)
		)


func _on_settings_saved(settings: Dictionary) -> void:
	super._on_settings_saved(settings)
	if _image_generation_window is CCFImageGenerationWindowV01528:
		(_image_generation_window as CCFImageGenerationWindowV01528).update_settings_v01528(
			_settings
		)


func _open_image_studio() -> void:
	if not _image_generation_window is CCFImageGenerationWindowV01528:
		super._open_image_studio()
		return
	if _workspace != null and _workspace.has_unsaved_changes():
		_global_status.text = "Image Studio uses saved projects. Save workspace changes first if you want them included in image prompts."
	else:
		_sync_current_workspace_to_image_studio_v01528()
	(_image_generation_window as CCFImageGenerationWindowV01528).open_studio()


func _sync_current_workspace_to_image_studio_v01528() -> void:
	if (
		not _image_generation_window is CCFImageGenerationWindowV01528
		or _workspace == null
	):
		return
	var project := _workspace.current_project()
	if project.is_empty():
		return
	(_image_generation_window as CCFImageGenerationWindowV01528).sync_saved_project_v01528(
		project,
		CCFStorageService.active_character_id(project)
	)


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01528
			node.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return
