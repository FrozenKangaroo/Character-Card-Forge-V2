extends "res://scripts/main_v0200.gd"

const LIBRARY_V0200_HOTFIX1 = preload(
	"res://scripts/ui/library_view_v0200_hotfix1.gd"
)
const BUILD_DISPLAY_VERSION_V0200_HOTFIX1 := "0.20.0-hotfix1"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0200_hotfix1()


func _install_library_v0185() -> void:
	if _content == null:
		return
	var previous_library: CCFLibraryView = _library
	if (
		previous_library != null
		and previous_library.get_script() == LIBRARY_V0200_HOTFIX1
	):
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
	var upgraded := (
		LIBRARY_V0200_HOTFIX1.new() as CCFLibraryV0200Hotfix1View
	)
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


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0200_HOTFIX1
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0200_hotfix1() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = (
				"Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0200_HOTFIX1
			)
			node.tooltip_text = (
				"v0.20.0-hotfix1 adds persistent collapsible Library Filters and "
				+ "Project Details, a unified Panels menu and optional side-panel "
				+ "auto-hide while retaining v0.20.0 large-library virtualization."
			)
			return
