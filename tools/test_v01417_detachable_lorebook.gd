extends SceneTree


func _init() -> void:
	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01417.gd")
	assert(workspace.contains("force_native = true"), "Lorebook Manager must be forced into a native OS window.")
	assert(workspace.contains("transient = false"), "Lorebook Manager must not remain tied to the main window as a transient child.")
	assert(workspace.contains("exclusive = false"), "Lorebook Manager must remain non-modal and independently movable.")
	assert(workspace.find("force_native = true") < workspace.find("add_child(_lorebook_window)"), "force_native must be configured before the Lorebook window enters the scene tree.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01417.gd")
	assert(main_source.contains("extends \"res://scripts/main_v01416.gd\""), "v0.14.17 must retain the v0.14.16 Idea Generator contract.")
	assert(main_source.contains("WORKSPACE_V01417"), "v0.14.17 workspace must be installed.")
	var successor := FileAccess.get_file_as_string("res://scripts/main_v01418.gd")
	if not successor.is_empty():
		assert(successor.contains("extends \"res://scripts/main_v01417.gd\""), "Newer shells must retain the detachable v0.14.17 Lorebook layer through inheritance.")
	print("v0.14.17 detachable Lorebook Manager regression passed")
	quit(0)
