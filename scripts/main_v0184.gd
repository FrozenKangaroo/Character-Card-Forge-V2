extends "res://scripts/main_v0183.gd"

const LIBRARY_V0184 = preload("res://scripts/ui/library_view_v0184.gd")
const LIBRARY_WORKFLOW_SERVICE_V0184 = preload(
	"res://scripts/services/library_workflow_service_v0184.gd"
)
const BUILD_DISPLAY_VERSION_V0184 := "0.18.4"


func _ready() -> void:
	super._ready()
	_install_library_v0184()
	_update_build_version_label_v0184()


func _install_library_v0184() -> void:
	if _content == null:
		return
	var previous_library: CCFLibraryView = _library
	if previous_library != null and previous_library.get_script() == LIBRARY_V0184:
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
	var upgraded := LIBRARY_V0184.new() as CCFLibraryV0184View
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


func _open_library_ai_review_v0184(project_id: String) -> void:
	_open_project(project_id)
	if _workspace != null and _workspace.has_method("_open_ai_review_v0183"):
		_workspace.call("_open_ai_review_v0183")


func _open_library_front_porch_v0184(project_id: String) -> void:
	_open_project(project_id)
	if _workspace != null and _workspace.has_method("_open_import_export_studio"):
		_workspace.call("_open_import_export_studio")


func _on_project_saved(project: Dictionary) -> void:
	LIBRARY_WORKFLOW_SERVICE_V0184.record_activity(
		str(project.get("project_id", "")), "edit", "Project saved"
	)
	super._on_project_saved(project)


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0184
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0184() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0184
			node.tooltip_text = (
				"v0.18.4 adds private workflow states and notes, recoverable archives, "
				+ "sensitive-artwork presentation policies, saved Smart Collections, "
				+ "recent activity, explainable duplicate review, batch validation/export "
				+ "and multi-project group assembly."
			)
			return
