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
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene_source.contains("main_v01511.gd"), "The active scene must use v0.15.11.")

	print("v0.15.11 visible Vision analysis regression passed")
	quit(0)
