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
		"bg_color",
		"border_color"
	]:
		assert(source.contains(marker), "v0.15.3 Collaborator chat UX is missing %s." % marker)
	var has_frame_wait := (
		source.contains("await get_tree().process_frame")
		or (
			source.contains("var scene_tree := get_tree()")
			and source.contains("await scene_tree.process_frame")
		)
	)
	assert(
		has_frame_wait,
		"v0.15.3 Collaborator chat UX must retain deferred process-frame scrolling through either the original call or the later lifecycle-safe retained SceneTree implementation."
	)

	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v015.gd")
	for marker in [
		"proactive creative character-design partner",
		"do not merely acknowledge, paraphrase, or mechanically follow",
		"Offer several materially different suggestions or alternatives",
		"identify undeveloped areas",
		"3 to 5 concise, genuinely different directions",
		"not generic invitations"
	]:
		assert(service_source.contains(marker), "Character Collaborator creative-initiative prompt is missing %s." % marker)

	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0153.gd")
	assert(workspace.contains("CHARACTER_COLLABORATOR_WINDOW_V0153"), "v0.15.3 Workspace must instantiate the chat-UX Collaborator window.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0153.gd")
	assert(main_source.contains("WORKSPACE_V0153"), "v0.15.3 shell must install the v0.15.3 Workspace.")
	assert(_active_shell_inherits_from("res://scripts/main_v0153.gd"), "The active main shell must preserve v0.15.3 Collaborator chat UX through direct use or inheritance.")
	print("v0.15.3 Character Collaborator chat UX and proactive prompt regression passed")
	quit(0)


func _active_shell_inherits_from(target_path: String) -> bool:
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "[ext_resource path=\""
	var marker_index := scene.find(marker)
	if marker_index < 0:
		return false
	var path_start := marker_index + marker.length()
	var path_end := scene.find("\"", path_start)
	if path_end < 0:
		return false
	var current_path := scene.substr(path_start, path_end - path_start)
	var visited := {}
	while not current_path.is_empty() and not visited.has(current_path):
		if current_path == target_path:
			return true
		visited[current_path] = true
		var current_source := FileAccess.get_file_as_string(current_path)
		if current_source.is_empty():
			return false
		var extends_marker := "extends \""
		var extends_index := current_source.find(extends_marker)
		if extends_index < 0:
			return false
		var parent_start := extends_index + extends_marker.length()
		var parent_end := current_source.find("\"", parent_start)
		if parent_end < 0:
			return false
		current_path = current_source.substr(parent_start, parent_end - parent_start)
	return false