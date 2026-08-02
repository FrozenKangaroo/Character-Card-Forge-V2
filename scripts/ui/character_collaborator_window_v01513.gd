class_name CCFCharacterCollaboratorWindowV01513
extends "res://scripts/ui/character_collaborator_window_v01511.gd"

const SESSION_STORE_V01513 = preload("res://scripts/services/collaborator_session_store_v01513.gd")
const MAX_SINGLE_MESSAGE_CHARS_V01513 := 4000000

var _snapshot_pending_v01513 := false


func _working_text_v0153() -> String:
	if _active_collaborator_job_type_v0153 == "collaborator_preparing":
		return "Character Collaborator is preparing context…"
	return super._working_text_v0153()


func _send_message() -> void:
	if _generation_service == null or _generation_service.has_active_job():
		return
	var text := _input.text.strip_edges()
	if text.is_empty():
		return
	if text.length() > MAX_SINGLE_MESSAGE_CHARS_V01513:
		_status.text = "This single message is too large to process safely in the Collaborator UI. Split it into smaller messages or attach the material as reference context."
		return

	# Paint feedback before context assembly, token estimation, transcript autosave,
	# or request construction. Large active conversations can make those local steps
	# noticeable, but the UI should never look as if Send did nothing.
	_active_collaborator_job_type_v0153 = "collaborator_preparing"
	_status.text = "Preparing active conversation context…"
	_refresh_chat()
	_refresh_action_state()
	call_deferred("_scroll_chat_to_bottom")
	await get_tree().process_frame

	var previous_session := _active_session().duplicate(true)
	var session := previous_session.duplicate(true)
	var messages_value: Variant = session.get("messages", [])
	var messages: Array = messages_value.duplicate(true) if messages_value is Array else []
	messages.append({"role": "user", "content": text})
	session["messages"] = messages
	if _active_session_index >= 0 and _active_session_index < _sessions.size():
		_sessions[_active_session_index] = session

	# Budget the conversation including the pending message. The older send path
	# checked before appending it, which could underestimate a very large paste.
	if not _can_send_with_context_budget():
		if _active_session_index >= 0 and _active_session_index < _sessions.size():
			_sessions[_active_session_index] = previous_session
		_active_collaborator_job_type_v0153 = ""
		_refresh_all()
		return

	_input.clear()
	_pending_regenerate_index = -1
	_queue_reply(false)
	_store_active_session(session)
	_refresh_chat()
	_refresh_action_state()
	call_deferred("_scroll_chat_to_bottom")


func _store_active_session(session: Dictionary) -> void:
	if _active_session_index < 0 or _active_session_index >= _sessions.size():
		return
	if not session.has("linked_project_id"):
		session["linked_project_id"] = _current_project_id_v0155
	if not session.has("linked_project_name"):
		session["linked_project_name"] = _current_project_name_v0155
	session["storage_scope"] = "local_collaborator_library"
	session["updated_at"] = Time.get_datetime_string_from_system(true)
	_sessions[_active_session_index] = session

	# Normal v0.15.5 autosave rewrites every saved chat whenever any one chat
	# changes. Save only the active session on the hot message-send path so an
	# unrelated large archived conversation cannot stall the current one.
	var result := SESSION_STORE_V01513.save_session(session)
	if not bool(result.get("ok", false)) and _status != null:
		_status.text = "Collaborator local autosave failed: %s" % str(result.get("error", "Could not write conversation storage."))
	_schedule_project_snapshot_v01513()


func _schedule_project_snapshot_v01513() -> void:
	if _snapshot_pending_v01513:
		return
	_snapshot_pending_v01513 = true
	call_deferred("_emit_project_snapshot_v01513")


func _emit_project_snapshot_v01513() -> void:
	_snapshot_pending_v01513 = false
	# Local Collaborator storage is authoritative for autosave. Project snapshots
	# only need conversations linked to the current project, not every chat in the
	# local library. This also stops unrelated saved chats inflating each update.
	var snapshot: Array = []
	if not _current_project_id_v0155.is_empty():
		snapshot = sessions_for_project_v0155(_current_project_id_v0155)
	else:
		var active := _active_session()
		if not active.is_empty():
			snapshot.append(active.duplicate(true))
	sessions_changed.emit(snapshot)
