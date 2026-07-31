extends "res://scripts/main_v0148.gd"

const LIBRARY_V0149 = preload("res://scripts/ui/library_view_v0149.gd")
const BUILD_DISPLAY_VERSION_V0149 := "0.14.9"


func _ready() -> void:
	super._ready()
	_install_library_v0149()
	_update_build_version_label()


func _install_library_v0149() -> void:
	if _content == null:
		return
	var previous_library: CCFLibraryView = _library
	if previous_library != null and previous_library.get_script() == LIBRARY_V0149:
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
	var upgraded: CCFLibraryView = LIBRARY_V0149.new()
	upgraded.visible = should_be_visible
	upgraded.new_character_requested.connect(_create_new_character)
	upgraded.open_project_requested.connect(_open_project)
	upgraded.project_changed.connect(_refresh_home_and_library)
	_library = upgraded
	_content.add_child(upgraded)


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0149
			node.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return
