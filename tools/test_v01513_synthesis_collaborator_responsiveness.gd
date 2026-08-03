extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01513.gd")
	assert(service_source.contains("EVERY key listed under ACTIVE TEMPLATE OUTPUT FIELDS"), "Full synthesis must explicitly require every template output field.")
	assert(service_source.contains("\"require_all_output_fields\": true"), "Full synthesis metadata must record the all-fields contract.")
	assert(service_source.contains("\"preview_include_unchanged\": true"), "Full synthesis preview must include preserved/unchanged returned fields.")
	assert(service_source.contains("never treat populated fields as already completed work"), "Populated Workspace fields must remain active synthesis material.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01513.gd")
	assert(workspace_source.contains("GENERATION_SERVICE_V01513"), "Workspace must install the v0.15.13 generation service.")
	assert(workspace_source.contains("CHARACTER_COLLABORATOR_WINDOW_V01513"), "Workspace must install the v0.15.13 Collaborator window.")
	assert(workspace_source.contains("preview_include_unchanged"), "Full synthesis preview must bypass changed-only filtering.")
	assert(workspace_source.contains("_add_preview_row(field, current_value, proposed_value)"), "Every returned synthesis field must be reviewable.")

	var collaborator_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v01513.gd")
	assert(collaborator_source.contains("collaborator_preparing"), "Collaborator must expose a local context-preparation state immediately after Send.")
	assert(collaborator_source.contains("await get_tree().process_frame"), "Collaborator must yield so preparation feedback paints before expensive local work.")
	assert(collaborator_source.contains("MAX_SINGLE_MESSAGE_CHARS_V01513"), "Collaborator needs a defensive single-message safety bound.")
	assert(collaborator_source.contains("SESSION_STORE_V01513.save_session(session)"), "Hot-path autosave must write only the active Collaborator session.")
	assert(collaborator_source.contains("sessions_for_project_v0155"), "Project snapshots must exclude unrelated saved chats.")
	assert(collaborator_source.contains("Budget the conversation including the pending message"), "Context budgeting must include the newly pasted message.")

	var store_source := FileAccess.get_file_as_string("res://scripts/services/collaborator_session_store_v01513.gd")
	assert(store_source.contains("static func save_session"), "v0.15.13 needs targeted per-session persistence.")
	assert(not store_source.contains("for raw_session in sessions"), "Targeted autosave must not rewrite the whole chat library.")

	var dialog_source := FileAccess.get_file_as_string("res://scripts/services/file_dialog_state_service_v01510.gd")
	assert(dialog_source.count("as FileDialog.DisplayMode") >= 2, "FileDialog display-mode restores must cast integers back to the enum type.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01513.gd")
	assert(main_source.contains("BUILD_DISPLAY_VERSION_V01513 := \"0.15.13\""), "The v0.15.13 shell must expose the build version.")
	assert(_active_shell_inherits_v01513(), "The active scene must use v0.15.13 or a later shell inheriting from it.")

	print("v0.15.13 synthesis and Collaborator responsiveness regression passed")
	quit(0)


func _active_shell_inherits_v01513() -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/"
	var marker_at := scene_source.find(marker)
	if marker_at < 0:
		return false
	var end_at := scene_source.find("\"", marker_at)
	if end_at < 0:
		return false
	var path := scene_source.substr(marker_at, end_at - marker_at)
	var visited := {}
	while not path.is_empty() and not visited.has(path):
		if path == "res://scripts/main_v01513.gd":
			return true
		visited[path] = true
		if not FileAccess.file_exists(path):
			return false
		var source := FileAccess.get_file_as_string(path)
		var extends_marker := "extends \""
		var extends_at := source.find(extends_marker)
		if extends_at < 0:
			return false
		var start_at := extends_at + extends_marker.length()
		var next_end := source.find("\"", start_at)
		if next_end < 0:
			return false
		path = source.substr(start_at, next_end - start_at)
	return false