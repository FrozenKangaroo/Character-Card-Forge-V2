extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/library_view_v0149.gd")
	assert(source.contains("Choose folder…"), "Library folder assignment must use a picker.")
	assert(source.contains("Choose collection…"), "Library collection assignment must use a picker.")
	assert(source.contains("New Folder…"), "Library must retain an explicit new-folder workflow.")
	assert(source.contains("New Collection…"), "Library must retain an explicit new-collection workflow.")
	assert(source.contains("Active project:"), "Library action context must identify the active project.")
	assert(source.contains("projects selected"), "Library action context must identify bulk selection.")
	assert(source.contains("MenuButton.new()"), "Secondary Library actions should be grouped into menus.")
	assert(not source.contains("placeholder_text = \"Virtual folder\""), "Existing folders must not require retyping their names.")
	assert(not source.contains("placeholder_text = \"Collection\""), "Existing collections must not require retyping their names.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0149.gd")
	assert(main_source.contains("LIBRARY_V0149"), "v0.14.9 Library view is not installed by its application shell layer.")
	assert(main_source.contains("0.14.9"), "v0.14.9 development label marker is missing from its shell layer.")
	var current_shell := FileAccess.get_file_as_string("res://scripts/main_v01410.gd")
	assert(current_shell.contains("extends \"res://scripts/main_v0149.gd\""), "Newer shells must retain the v0.14.9 Library layer through inheritance.")
	print("v0.14.9 Library UX regression passed")
	quit(0)
