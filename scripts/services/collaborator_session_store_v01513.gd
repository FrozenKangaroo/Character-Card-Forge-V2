class_name CCFCollaboratorSessionStoreV01513
extends RefCounted

const FORMAT_VERSION := 1
const STORE_DIR := "user://collaborator_sessions"


static func save_session(session: Dictionary) -> Dictionary:
	var session_id := _safe_session_id(str(session.get("session_id", "")))
	if session_id.is_empty():
		return {"ok": false, "error": "Collaborator session does not have a valid session ID."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORE_DIR))
	var path := "%s/%s.json" % [STORE_DIR, session_id]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open Collaborator session storage for writing: %s" % path}
	file.store_string(JSON.stringify({
		"format_version": FORMAT_VERSION,
		"session": session
	}, "  "))
	file.close()
	return {"ok": true, "session_id": session_id}


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
