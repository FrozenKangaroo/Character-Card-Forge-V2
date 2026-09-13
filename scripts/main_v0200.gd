extends "res://scripts/main_v0195.gd"

const LIBRARY_V0200 = preload("res://scripts/ui/library_view_v0200.gd")
const SETTINGS_VIEW_V0200 = preload("res://scripts/ui/settings_view_v0200.gd")
const BUILD_DISPLAY_VERSION_V0200 := "0.20.0"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0200()


func _install_library_v0185() -> void:
	if _content == null:
		return
	var previous_library: CCFLibraryView = _library
	if previous_library != null and previous_library.get_script() == LIBRARY_V0200:
		return
	var should_be_visible := _current_view == "library"
	if previous_library != null:
		if previous_library.new_character_requested.is_connected(_create_new_character):
			previous_library.new_character_requested.disconnect(_create_new_character)
		if previous_library.open_project_requested.is_connected(_open_project):
			previous_library.open_project_requested.disconnect(_open_project)
		if previous_library.project_changed.is_connected(_refresh_home_and_library):
			previous_library.project_changed.disconnect(_refresh_home_and_library)
		if previous_library.get_parent() == _content:
			_content.remove_child(previous_library)
		previous_library.queue_free()
	var upgraded := LIBRARY_V0200.new() as CCFLibraryV0200View
	upgraded.visible = should_be_visible
	upgraded.new_character_requested.connect(_create_new_character)
	upgraded.open_project_requested.connect(_open_project)
	upgraded.project_changed.connect(_refresh_home_and_library)
	upgraded.ai_review_requested_v0184.connect(_open_library_ai_review_v0184)
	upgraded.front_porch_requested_v0184.connect(_open_library_front_porch_v0184)
	_library = upgraded
	_content.add_child(upgraded)
	if should_be_visible:
		upgraded.refresh_projects(false)


func _install_settings_view_v01528() -> void:
	if _content == null:
		return
	var previous_settings: CCFSettingsView = _settings_view
	if previous_settings != null and previous_settings.get_script() == SETTINGS_VIEW_V0200:
		previous_settings.load_settings(_settings)
		return
	var should_be_visible := _current_view == "settings"
	if previous_settings != null:
		if previous_settings.settings_saved.is_connected(_on_settings_saved):
			previous_settings.settings_saved.disconnect(_on_settings_saved)
		if previous_settings.get_parent() == _content:
			_content.remove_child(previous_settings)
		previous_settings.queue_free()
	var upgraded: CCFSettingsView = SETTINGS_VIEW_V0200.new()
	upgraded.visible = should_be_visible
	upgraded.settings_saved.connect(_on_settings_saved)
	_settings_view = upgraded
	_content.add_child(upgraded)
	upgraded.load_settings(_settings)


func _on_settings_saved(settings: Dictionary) -> void:
	var previous_storage_value: Variant = _settings.get("library_storage", {})
	var previous_storage: Dictionary = (
		previous_storage_value if previous_storage_value is Dictionary else {}
	)
	var next_storage_value: Variant = settings.get("library_storage", {})
	var next_storage: Dictionary = (
		next_storage_value if next_storage_value is Dictionary else {}
	)
	var location_changed := (
		str(previous_storage.get("mode", "local")) != str(next_storage.get("mode", "local"))
		or str(previous_storage.get("portable_root", "")) != str(
			next_storage.get("portable_root", "")
		)
	)
	super._on_settings_saved(settings)
	if _library != null:
		_library.refresh_projects(location_changed)
	if _dashboard != null:
		_dashboard.refresh()
	if location_changed:
		_global_status.text = (
			"Library location changed. Reopen projects from this library before editing or saving them."
		)


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0200
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0200() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0200
			node.tooltip_text = (
				"v0.20.0 virtualizes very large libraries, bounds disposable thumbnail "
				+ "caches and adds explicit single-writer portable/shared-folder libraries "
				+ "with safe saves, conflict detection and no silent fallback."
			)
			return
