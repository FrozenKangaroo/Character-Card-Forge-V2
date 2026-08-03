extends SceneTree


func _init() -> void:
	var collaborator_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v01511.gd")
	assert(collaborator_source.contains("_active_collaborator_job_type_v0153 = \"\""), "Vision completion must clear the stale analysing state.")
	assert(collaborator_source.contains("\"role\": \"vision\""), "Completed Vision analysis must become a transcript message.")
	assert(collaborator_source.contains("Vision Analysis — %s"), "Vision messages need a distinct visible heading.")
	assert(collaborator_source.contains("_add_context_item"), "Vision analysis must remain available as Text-model reference context.")
	assert(collaborator_source.contains("_store_active_session(session)"), "Visible Vision messages must persist with the Collaborator session.")
	assert(collaborator_source.contains("_emit_sessions_changed()"), "Vision completion must trigger independent session autosave.")
	assert(collaborator_source.contains("_scroll_chat_to_bottom"), "Vision completion must scroll to the newly visible analysis.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01511.gd")
	assert(workspace_source.contains("CHARACTER_COLLABORATOR_WINDOW_V01511"), "Workspace must install the v0.15.11 Collaborator window.")
	assert(_active_shell_inherits_v01511(), "The active scene must use v0.15.11 or a later shell that inherits it.")

	print("v0.15.11 visible Vision analysis regression passed")
	quit(0)


func _active_shell_inherits_v01511() -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/main_v"
	var start := scene_source.find(marker)
	if start < 0:
		return false
	var end := scene_source.find(".gd", start)
	if end < 0:
		return false
	var script_path := scene_source.substr(start, end - start + 3)
	# Later releases add thin inherited shell layers. Keep the historical feature
	# check bounded but comfortably forward-compatible instead of failing once the
	# version chain becomes one level longer than its original fixed depth.
	for _depth in range(64):
		if script_path == "res://scripts/main_v01511.gd":
			return true
		if not FileAccess.file_exists(script_path):
			return false
		var source := FileAccess.get_file_as_string(script_path)
		var extends_prefix := "extends \""
		var extends_start := source.find(extends_prefix)
		if extends_start < 0:
			return false
		extends_start += extends_prefix.length()
		var extends_end := source.find("\"", extends_start)
		if extends_end < 0:
			return false
		script_path = source.substr(extends_start, extends_end - extends_start)
	return false
