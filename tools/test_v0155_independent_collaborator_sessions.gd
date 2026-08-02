extends SceneTree


func _init() -> void:
	var store_source := FileAccess.get_file_as_string("res://scripts/services/collaborator_session_store_v0155.gd")
	for marker in [
		"user://collaborator_sessions",
		"static func load_sessions",
		"static func save_sessions",
		"static func merge_sessions",
		"format_version"
	]:
		assert(store_source.contains(marker), "v0.15.5 independent Collaborator store is missing %s." % marker)

	CCFCollaboratorSessionStoreV0155.save_sessions([])
	var draft := {
		"session_id": "ci_unsaved_project_chat",
		"title": "Unsaved project brainstorm",
		"messages": [{"role": "user", "content": "Keep this even if the project is never saved."}],
		"context_items": [],
		"memory_summary": "",
		"summarized_through": -1,
		"created_at": "2026-08-02T00:00:00Z",
		"updated_at": "2026-08-02T00:01:00Z",
		"linked_project_id": "",
		"linked_project_name": "Unsaved Project"
	}
	var save_result := CCFCollaboratorSessionStoreV0155.save_sessions([draft])
	assert(bool(save_result.get("ok", false)), "Independent Collaborator session save must succeed without a project save.")
	var reloaded := CCFCollaboratorSessionStoreV0155.load_sessions()
	assert(reloaded.size() == 1, "Independent Collaborator session must survive a reload from user storage.")
	assert(str((reloaded[0] as Dictionary).get("session_id", "")) == "ci_unsaved_project_chat", "Reloaded independent Collaborator session ID must match.")

	var embedded := draft.duplicate(true)
	embedded["session_id"] = "portable_project_chat"
	embedded["updated_at"] = "2026-08-02T00:02:00Z"
	var merged := CCFCollaboratorSessionStoreV0155.merge_sessions(reloaded, [embedded], "project-123", "Portable Project")
	assert(merged.size() == 2, "Project portability snapshots should merge into the local Collaborator Library without replacing unrelated drafts.")
	var found_portable := false
	for raw in merged:
		if raw is Dictionary and str((raw as Dictionary).get("session_id", "")) == "portable_project_chat":
			found_portable = true
			assert(str((raw as Dictionary).get("linked_project_id", "")) == "project-123", "Imported project session should gain its project association.")
	assert(found_portable, "Merged Collaborator Library should contain the embedded project session.")
	CCFCollaboratorSessionStoreV0155.save_sessions([])

	var window_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v0155.gd")
	for marker in [
		"SESSION_STORE_V0155.load_sessions()",
		"SESSION_STORE_V0155.save_sessions(_sessions)",
		"storage_scope",
		"local_collaborator_library",
		"sessions_for_project_v0155",
		"Draft"
	]:
		assert(window_source.contains(marker), "v0.15.5 Collaborator window is missing independent-session behavior %s." % marker)

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0155.gd")
	assert(workspace_source.contains("CHARACTER_COLLABORATOR_WINDOW_V0155"), "v0.15.5 Workspace must instantiate the independent-session Collaborator window.")
	assert(workspace_source.contains("never forces an otherwise-unsaved project to disk"), "Workspace should document that chat autosave no longer saves an unsaved project.")
	assert(not workspace_source.contains("CCFStorageService.save_project(_project_container)"), "v0.15.5 Collaborator session changes must not depend on project save_project().")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0155.gd")
	assert(main_source.contains("main_v0154.gd"), "v0.15.5 must preserve v0.15.4 through inheritance.")
	assert(main_source.contains("WORKSPACE_V0155"), "v0.15.5 shell must install the v0.15.5 Workspace.")
	assert(_active_shell_inherits_from("res://scripts/main_v0155.gd"), "The active main shell must use or inherit v0.15.5.")

	print("v0.15.5 independent Character Collaborator session persistence regression passed")
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
		var source := FileAccess.get_file_as_string(current_path)
		if source.is_empty():
			return false
		var extends_marker := "extends \""
		var extends_index := source.find(extends_marker)
		if extends_index < 0:
			return false
		var parent_start := extends_index + extends_marker.length()
		var parent_end := source.find("\"", parent_start)
		if parent_end < 0:
			return false
		current_path = source.substr(parent_start, parent_end - parent_start)
	return false
