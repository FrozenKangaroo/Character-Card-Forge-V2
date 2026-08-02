class_name CCFCollaboratorSessionStoreV0155
extends RefCounted

const FORMAT_VERSION := 1
const STORE_DIR := "user://collaborator_sessions"


static func load_sessions() -> Array:
	_ensure_store_dir()
	var sessions: Array = []
	var directory := DirAccess.open(STORE_DIR)
	if directory == null:
		return sessions
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.to_lower().ends_with(".json"):
			continue
		var path := "%s/%s" % [STORE_DIR, file_name]
		var parsed := JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			continue
		var document: Dictionary = parsed
		var raw_session: Variant = document.get("session", {})
		if not raw_session is Dictionary:
			continue
		var session: Dictionary = raw_session.duplicate(true)
		if str(session.get("session_id", "")).strip_edges().is_empty():
			continue
		sessions.append(session)
	return sessions


static func save_sessions(sessions: Array) -> Dictionary:
	_ensure_store_dir()
	var keep := {}
	for raw_session in sessions:
		if not raw_session is Dictionary:
			continue
		var session: Dictionary = raw_session.duplicate(true)
		var session_id := _safe_session_id(str(session.get("session_id", "")))
		if session_id.is_empty():
			continue
		keep[session_id] = true
		var path := "%s/%s.json" % [STORE_DIR, session_id]
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return {"ok": false, "error": "Could not open Collaborator session storage for writing: %s" % path}
		file.store_string(JSON.stringify({
			"format_version": FORMAT_VERSION,
			"session": session
		}, "  "))
		file.close()

	var directory := DirAccess.open(STORE_DIR)
	if directory != null:
		for file_name in directory.get_files():
			if not file_name.to_lower().ends_with(".json"):
				continue
			var session_id := file_name.get_basename()
			if not keep.has(session_id):
				directory.remove(file_name)
	return {"ok": true, "count": keep.size()}


static func merge_sessions(local_sessions: Array, embedded_sessions: Array, project_id: String = "", project_name: String = "") -> Array:
	var by_id := {}
	var order: Array[String] = []
	for raw_session in local_sessions:
		if not raw_session is Dictionary:
			continue
		var session: Dictionary = raw_session.duplicate(true)
		var session_id := str(session.get("session_id", "")).strip_edges()
		if session_id.is_empty():
			continue
		by_id[session_id] = session
		order.append(session_id)
	for raw_session in embedded_sessions:
		if not raw_session is Dictionary:
			continue
		var session: Dictionary = raw_session.duplicate(true)
		var session_id := str(session.get("session_id", "")).strip_edges()
		if session_id.is_empty():
			continue
		if str(session.get("linked_project_id", "")).is_empty() and not project_id.is_empty():
			session["linked_project_id"] = project_id
		if str(session.get("linked_project_name", "")).is_empty() and not project_name.is_empty():
			session["linked_project_name"] = project_name
		if not by_id.has(session_id):
			by_id[session_id] = session
			order.append(session_id)
			continue
		var local: Dictionary = by_id[session_id]
		if str(session.get("updated_at", "")) > str(local.get("updated_at", "")):
			by_id[session_id] = session
	var merged: Array = []
	for session_id in order:
		if by_id.has(session_id):
			merged.append((by_id[session_id] as Dictionary).duplicate(true))
	merged.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.get("updated_at", "")) < str(b.get("updated_at", "")))
	return merged


static func _ensure_store_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORE_DIR))


static func _safe_session_id(value: String) -> String:
	var clean := value.strip_edges()
	if clean.is_empty():
		return ""
	var result := ""
	for character in clean:
		if character.is_valid_identifier() or character.is_valid_int() or character in ["_", "-"]:
			result += character
		else:
			result += "_"
	return result
