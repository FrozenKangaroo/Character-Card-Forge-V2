class_name CCFWorkspaceV0155View
extends "res://scripts/ui/workspace_v0154.gd"

const CHARACTER_COLLABORATOR_WINDOW_V0155 = preload("res://scripts/ui/character_collaborator_window_v0155.gd")


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V0155.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(_on_collaborator_sessions_changed_v015)
	_character_collaborator_window.character_draft_ready.connect(_on_collaborator_character_draft_ready_v015)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()


func _on_collaborator_sessions_changed_v015(_sessions: Array) -> void:
	# v0.15.5 makes the local Collaborator Library authoritative. Project data keeps
	# only a portability snapshot when there is a stable project ID; changing a chat
	# never forces an otherwise-unsaved project to disk.
	if _project_container.is_empty() or _character_collaborator_window == null:
		return
	var project_id := str(_project_container.get("project_id", "")).strip_edges()
	if project_id.is_empty():
		_project_container.erase("collaborator_sessions")
		return
	if _character_collaborator_window.has_method("sessions_for_project_v0155"):
		_project_container["collaborator_sessions"] = _character_collaborator_window.call("sessions_for_project_v0155", project_id)


func _autosave_collaborator_sessions_v0154() -> void:
	# Kept as an intentional no-op for compatibility with v0.15.4. Collaborator
	# persistence is handled by CCFCollaboratorSessionStoreV0155, not save_project().
	pass
