extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v0153.gd")
	for marker in [
		"LINE_WRAPPING_BOUNDARY",
		"selection_enabled = true",
		"context_menu_enabled = true",
		"DisplayServer.clipboard_set",
		"Character Collaborator is thinking…",
		"_build_message_card_v0153",
		"_build_working_card_v0153",
		"await get_tree().process_frame",
		"bg_color",
		"border_color"
	]:
		assert(source.contains(marker), "v0.15.3 Collaborator chat UX is missing %s." % marker)
	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0153.gd")
	assert(workspace.contains("CHARACTER_COLLABORATOR_WINDOW_V0153"), "v0.15.3 Workspace must instantiate the chat-UX Collaborator window.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0153.gd")
	assert(main_source.contains("WORKSPACE_V0153"), "v0.15.3 shell must install the v0.15.3 Workspace.")
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene.contains("main_v0153.gd"), "Main scene must use the v0.15.3 shell.")
	print("v0.15.3 Character Collaborator chat UX regression passed")
	quit(0)
