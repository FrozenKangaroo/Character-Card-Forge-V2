extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v0154.gd")
	for marker in [
		"Preserve established character facts by default",
		"alternate/rewrite directions",
		"Prefer deepening, connecting, and extending existing material",
		"Match response depth to the current stage of collaboration",
		"Do not unnecessarily medicalize, diagnose, or pathologize",
		"PRESENTATION CONTRACT",
		"- **Behavior:**",
		"queue_collaborator_reply"
	]:
		assert(service_source.contains(marker), "v0.15.4 Collaborator behaviour contract is missing %s." % marker)
	var service := CCFGenerationServiceV0154.new()
	assert(service.has_method("queue_collaborator_reply"), "v0.15.4 generation service must remain Collaborator-capable.")
	service.free()

	var window_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v0154.gd")
	for marker in [
		"Rename",
		"Delete Conversation",
		"_delete_active_session_v0154",
		"_render_collaborator_rich_text_v0154",
		"_render_heading_v0154",
		"_render_semantic_bullet_v0154",
		"_semantic_color_v0154",
		"push_font_size",
		"push_color",
		"push_bold",
		"push_italics"
	]:
		assert(window_source.contains(marker), "v0.15.4 Collaborator management/rich-text UI is missing %s." % marker)
	assert(window_source.contains("super._build_message_card_v0153"), "v0.15.4 must preserve selectable/copyable v0.15.3 message cards.")
	assert(window_source.contains("str(message.get(\"role\", \"\")) != \"assistant\""), "User messages should stay literal while AI messages receive rich rendering.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0154.gd")
	for marker in [
		"GENERATION_SERVICE_V0154",
		"CHARACTER_COLLABORATOR_WINDOW_V0154",
		"_autosave_collaborator_sessions_v0154",
		"CCFStorageService.save_project(_project_container)",
		"project_saved.emit(_project_container.duplicate(true))"
	]:
		assert(workspace_source.contains(marker), "v0.15.4 Collaborator autosave/runtime wiring is missing %s." % marker)

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0154.gd")
	assert(main_source.contains("main_v0153.gd"), "v0.15.4 must preserve v0.15.3 through inheritance.")
	assert(main_source.contains("WORKSPACE_V0154"), "v0.15.4 shell must install the v0.15.4 Workspace.")
	assert(_active_shell_inherits_from("res://scripts/main_v0154.gd"), "The active main shell must use or inherit v0.15.4.")

	print("v0.15.4 Collaborator autosave, conversation management, behaviour contract, and rich-text regression passed")
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