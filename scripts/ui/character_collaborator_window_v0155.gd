class_name CCFCharacterCollaboratorWindowV0155
extends "res://scripts/ui/character_collaborator_window_v0154.gd"

const SESSION_STORE_V0155 = preload("res://scripts/services/collaborator_session_store_v0155.gd")

var _current_project_id_v0155 := ""
var _current_project_name_v0155 := ""


func open_for_project(project: Dictionary, settings: Dictionary, character_id: String, template: Dictionary) -> void:
	_project = project.duplicate(true)
	_settings = settings.duplicate(true)
	_active_character_id = character_id
	_template = template.duplicate(true)
	_current_project_id_v0155 = str(_project.get("project_id", "")).strip_edges()
	_current_project_name_v0155 = _project_display_name_v0155(_project)

	var local_sessions := SESSION_STORE_V0155.load_sessions()
	var embedded_value: Variant = _project.get("collaborator_sessions", [])
	var embedded_sessions: Array = embedded_value.duplicate(true) if embedded_value is Array else []
	_sessions = SESSION_STORE_V0155.merge_sessions(
		local_sessions,
		embedded_sessions,
		_current_project_id_v0155,
		_current_project_name_v0155
	)
	_normalise_sessions()
	if _sessions.is_empty():
		_create_new_session(false)
	else:
		_active_session_index = clampi(_active_session_index, 0, _sessions.size() - 1) if _active_session_index >= 0 else _sessions.size() - 1
		_persist_local_sessions_v0155()
	_refresh_all()
	_status.text = "Collaborator chats autosave independently of project saves. You can close CCF and continue this conversation later."
	popup_centered()


func update_project_context(project: Dictionary, settings: Dictionary, character_id: String, template: Dictionary) -> void:
	super.update_project_context(project, settings, character_id, template)
	_current_project_id_v0155 = str(project.get("project_id", "")).strip_edges()
	_current_project_name_v0155 = _project_display_name_v0155(project)


func _create_new_session(emit_change: bool) -> void:
	super._create_new_session(false)
	var session := _active_session()
	if not session.is_empty():
		session["linked_project_id"] = _current_project_id_v0155
		session["linked_project_name"] = _current_project_name_v0155
		session["storage_scope"] = "local_collaborator_library"
		_sessions[_active_session_index] = session
	_persist_local_sessions_v0155()
	if emit_change:
		super._emit_sessions_changed()
		_refresh_all()


func _store_active_session(session: Dictionary) -> void:
	if _active_session_index < 0 or _active_session_index >= _sessions.size():
		return
	if not session.has("linked_project_id"):
		session["linked_project_id"] = _current_project_id_v0155
	if not session.has("linked_project_name"):
		session["linked_project_name"] = _current_project_name_v0155
	session["storage_scope"] = "local_collaborator_library"
	super._store_active_session(session)


func _emit_sessions_changed() -> void:
	_persist_local_sessions_v0155()
	super._emit_sessions_changed()


func _refresh_session_selector() -> void:
	_session_selector.clear()
	for raw in _sessions:
		if not raw is Dictionary:
			continue
		var session: Dictionary = raw
		var label := str(session.get("title", "Character Collaboration"))
		var linked_name := str(session.get("linked_project_name", "")).strip_edges()
		var linked_id := str(session.get("linked_project_id", "")).strip_edges()
		if not linked_name.is_empty():
			label += "  •  %s" % linked_name
		elif not linked_id.is_empty():
			label += "  •  Project-linked"
		else:
			label += "  •  Draft"
		_session_selector.add_item(label)
	if _active_session_index >= 0 and _active_session_index < _session_selector.item_count:
		_session_selector.select(_active_session_index)


func _persist_local_sessions_v0155() -> void:
	var result := SESSION_STORE_V0155.save_sessions(_sessions)
	if not bool(result.get("ok", false)) and _status != null:
		_status.text = "Collaborator local autosave failed: %s" % str(result.get("error", "Could not write conversation storage."))


func sessions_for_project_v0155(project_id: String) -> Array:
	var clean_project_id := project_id.strip_edges()
	var result: Array = []
	for raw in _sessions:
		if not raw is Dictionary:
			continue
		var session: Dictionary = raw
		if str(session.get("linked_project_id", "")).strip_edges() == clean_project_id:
			result.append(session.duplicate(true))
	return result


func _project_display_name_v0155(project: Dictionary) -> String:
	var direct_name := str(project.get("name", "")).strip_edges()
	if not direct_name.is_empty():
		return direct_name
	var metadata_value: Variant = project.get("metadata", {})
	if metadata_value is Dictionary:
		var metadata: Dictionary = metadata_value
		var metadata_name := str(metadata.get("name", "")).strip_edges()
		if not metadata_name.is_empty():
			return metadata_name
	return "Unsaved Project" if str(project.get("project_id", "")).strip_edges().is_empty() else "Project"
