extends "res://scripts/main_v0190.gd"

const WORKSPACE_V0191 = preload("res://scripts/ui/workspace_v0191.gd")
const LIBRARY_V0191 = preload("res://scripts/ui/library_view_v0191.gd")
const BUILD_DISPLAY_VERSION_V0191 := "0.19.1"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0191()


func _install_library_v0185() -> void:
	if _content == null:
		return
	var previous_library: CCFLibraryView = _library
	if previous_library != null and previous_library.get_script() == LIBRARY_V0191:
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
	var upgraded := LIBRARY_V0191.new() as CCFLibraryV0191View
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


func _install_workspace_v01526() -> void:
	if _content == null:
		return
	var previous_workspace: CCFWorkspaceView = _workspace
	if previous_workspace != null and previous_workspace.get_script() == WORKSPACE_V0191:
		previous_workspace.update_settings(_settings)
		return
	var should_be_visible := _current_view == "workspace"
	if previous_workspace != null:
		if previous_workspace.project_saved.is_connected(_on_project_saved):
			previous_workspace.project_saved.disconnect(_on_project_saved)
		if previous_workspace.library_requested.is_connected(_show_library_from_workspace):
			previous_workspace.library_requested.disconnect(_show_library_from_workspace)
		if previous_workspace.settings_requested.is_connected(_show_settings_from_workspace):
			previous_workspace.settings_requested.disconnect(_show_settings_from_workspace)
		if previous_workspace.template_manager_requested.is_connected(_show_templates_from_workspace):
			previous_workspace.template_manager_requested.disconnect(_show_templates_from_workspace)
		if previous_workspace.series_manager_requested.is_connected(_show_series_from_workspace):
			previous_workspace.series_manager_requested.disconnect(_show_series_from_workspace)
		if previous_workspace.project_imported.is_connected(_on_project_imported):
			previous_workspace.project_imported.disconnect(_on_project_imported)
		if previous_workspace.get_parent() == _content:
			_content.remove_child(previous_workspace)
		previous_workspace.queue_free()
	var upgraded: CCFWorkspaceView = WORKSPACE_V0191.new()
	upgraded.visible = should_be_visible
	upgraded.project_saved.connect(_on_project_saved)
	upgraded.library_requested.connect(_show_library_from_workspace)
	upgraded.settings_requested.connect(_show_settings_from_workspace)
	upgraded.template_manager_requested.connect(_show_templates_from_workspace)
	upgraded.series_manager_requested.connect(_show_series_from_workspace)
	upgraded.project_imported.connect(_on_project_imported)
	_workspace = upgraded
	_content.add_child(upgraded)
	upgraded.update_settings(_settings)
	_wire_ai_jobs_controller_v01531()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0191
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0191() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0191
			node.tooltip_text = (
				"v0.19.1 adds versioned export profiles, exact before-export previews, "
				+ "shared integration adapters, visible preservation/loss reports, "
				+ "and a denser, adjustable Character Library."
			)
			return
