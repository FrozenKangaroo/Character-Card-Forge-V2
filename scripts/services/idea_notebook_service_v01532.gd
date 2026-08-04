class_name CCFIdeaNotebookServiceV01532
extends RefCounted

const ROOT_DIR := "user://character_card_forge/idea_notebook"
const IDEAS_DIR := ROOT_DIR + "/ideas"
const LIBRARY_FILE := ROOT_DIR + "/library.json"
const LIBRARY_FORMAT := "character_card_forge_idea_notebook"
const IDEA_FORMAT := "character_card_forge_saved_idea"
const FORMAT_VERSION := 1


static func ensure_directories() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(IDEAS_DIR))


static func load_library() -> Dictionary:
	ensure_directories()
	if not FileAccess.file_exists(LIBRARY_FILE):
		var fresh := _new_library()
		var write_result := _write_json(LIBRARY_FILE, fresh)
		if not bool(write_result.get("ok", false)):
			return write_result
		return {"ok": true, "data": fresh}
	var loaded := _read_json(LIBRARY_FILE)
	if not bool(loaded.get("ok", false)):
		return loaded
	var value: Variant = loaded.get("data", {})
	if not value is Dictionary:
		return {"ok": false, "error": "Idea Notebook library.json is not a JSON object."}
	var normalised := _normalise_library(value as Dictionary)
	return {"ok": true, "data": normalised}


static func list_notebooks() -> Array[Dictionary]:
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return []
	var library: Dictionary = loaded.get("data", {})
	var rows: Array[Dictionary] = []
	for value in library.get("notebooks", []):
		if value is Dictionary:
			rows.append((value as Dictionary).duplicate(true))
	return rows


static func create_notebook(display_name: String) -> Dictionary:
	var clean_name := display_name.strip_edges()
	if clean_name.is_empty():
		return {"ok": false, "error": "Notebook name cannot be empty."}
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return loaded
	var library: Dictionary = loaded.get("data", {})
	var notebooks: Array = library.get("notebooks", []).duplicate(true)
	for value in notebooks:
		if value is Dictionary and str((value as Dictionary).get("name", "")).nocasecmp_to(clean_name) == 0:
			return {"ok": false, "error": "A notebook named '%s' already exists." % clean_name}
	var now := _now()
	var row := {
		"id": _new_id(),
		"name": clean_name,
		"created_at": now,
		"updated_at": now
	}
	notebooks.append(row)
	library["notebooks"] = notebooks
	library["updated_at"] = now
	var saved := _write_json(LIBRARY_FILE, library)
	if not bool(saved.get("ok", false)):
		return saved
	return {"ok": true, "notebook": row.duplicate(true)}


static func rename_notebook(notebook_id: String, display_name: String) -> Dictionary:
	var clean_id := notebook_id.strip_edges()
	var clean_name := display_name.strip_edges()
	if clean_id.is_empty() or clean_name.is_empty():
		return {"ok": false, "error": "Notebook ID and name are required."}
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return loaded
	var library: Dictionary = loaded.get("data", {})
	var notebooks: Array = library.get("notebooks", []).duplicate(true)
	for value in notebooks:
		if not value is Dictionary:
			continue
		var row: Dictionary = value
		if str(row.get("id", "")) != clean_id and str(row.get("name", "")).nocasecmp_to(clean_name) == 0:
			return {"ok": false, "error": "A notebook named '%s' already exists." % clean_name}
	var found := false
	for index in range(notebooks.size()):
		if not notebooks[index] is Dictionary:
			continue
		var row: Dictionary = (notebooks[index] as Dictionary).duplicate(true)
		if str(row.get("id", "")) != clean_id:
			continue
		row["name"] = clean_name
		row["updated_at"] = _now()
		notebooks[index] = row
		found = true
		break
	if not found:
		return {"ok": false, "error": "Notebook was not found."}
	library["notebooks"] = notebooks
	library["updated_at"] = _now()
	return _write_json(LIBRARY_FILE, library)


static func delete_notebook(notebook_id: String) -> Dictionary:
	var clean_id := notebook_id.strip_edges()
	if clean_id.is_empty():
		return {"ok": false, "error": "Notebook ID is required."}
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return loaded
	var library: Dictionary = loaded.get("data", {})
	var notebooks: Array = library.get("notebooks", []).duplicate(true)
	var removed := false
	for index in range(notebooks.size() - 1, -1, -1):
		if notebooks[index] is Dictionary and str((notebooks[index] as Dictionary).get("id", "")) == clean_id:
			notebooks.remove_at(index)
			removed = true
	if not removed:
		return {"ok": false, "error": "Notebook was not found."}
	library["notebooks"] = notebooks
	library["updated_at"] = _now()
	var saved := _write_json(LIBRARY_FILE, library)
	if not bool(saved.get("ok", false)):
		return saved
	# Deleting a notebook never deletes its ideas. They become Unfiled.
	for idea in list_ideas({"include_archived": true}):
		if str(idea.get("notebook_id", "")) == clean_id:
			var updated := idea.duplicate(true)
			updated["notebook_id"] = ""
			updated["updated_at"] = _now()
			_write_json(_idea_path(str(updated.get("id", ""))), updated)
	return {"ok": true}


static func save_generated_idea(raw_idea: Dictionary, notebook_id: String = "", source: Dictionary = {}) -> Dictionary:
	var now := _now()
	var idea := _normalise_idea(raw_idea)
	if str(idea.get("concept", "")).strip_edges().is_empty():
		return {"ok": false, "error": "An idea needs concept text before it can be saved."}
	idea["id"] = _new_id()
	idea["notebook_id"] = _valid_notebook_id_or_empty(notebook_id)
	idea["created_at"] = now
	idea["updated_at"] = now
	idea["archived"] = false
	idea["source"] = _normalise_source(source)
	idea["format"] = IDEA_FORMAT
	idea["format_version"] = FORMAT_VERSION
	var saved := _write_json(_idea_path(str(idea.get("id", ""))), idea)
	if not bool(saved.get("ok", false)):
		return saved
	return {"ok": true, "idea": idea.duplicate(true)}


static func update_idea(idea_id: String, changes: Dictionary) -> Dictionary:
	var loaded := load_idea(idea_id)
	if not bool(loaded.get("ok", false)):
		return loaded
	var idea: Dictionary = loaded.get("data", {})
	for key in ["title", "concept", "notes", "character_name", "character_role", "source_anchor", "roleplay_hook"]:
		if changes.has(key):
			idea[key] = str(changes.get(key, "")).strip_edges()
	if changes.has("tags"):
		idea["tags"] = _normalise_tags(changes.get("tags", []))
	if changes.has("notebook_id"):
		idea["notebook_id"] = _valid_notebook_id_or_empty(str(changes.get("notebook_id", "")))
	if changes.has("archived"):
		idea["archived"] = bool(changes.get("archived", false))
	if str(idea.get("concept", "")).is_empty():
		return {"ok": false, "error": "An idea needs concept text."}
	idea["updated_at"] = _now()
	var saved := _write_json(_idea_path(idea_id), idea)
	if not bool(saved.get("ok", false)):
		return saved
	return {"ok": true, "idea": idea.duplicate(true)}


static func load_idea(idea_id: String) -> Dictionary:
	ensure_directories()
	var clean_id := idea_id.strip_edges()
	if clean_id.is_empty():
		return {"ok": false, "error": "Idea ID is required."}
	var loaded := _read_json(_idea_path(clean_id))
	if not bool(loaded.get("ok", false)):
		return loaded
	var value: Variant = loaded.get("data", {})
	if not value is Dictionary:
		return {"ok": false, "error": "Saved idea is not a JSON object."}
	return {"ok": true, "data": _normalise_idea(value as Dictionary, true)}


static func delete_idea(idea_id: String) -> Dictionary:
	var path := _idea_path(idea_id.strip_edges())
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Idea was not found."}
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error != OK:
		return {"ok": false, "error": "Could not delete saved idea (error %d)." % error}
	return {"ok": true}


static func list_ideas(filters: Dictionary = {}) -> Array[Dictionary]:
	ensure_directories()
	var notebook_filter := str(filters.get("notebook_id", "__all__"))
	var search_text := str(filters.get("search", "")).strip_edges().to_lower()
	var tag_filter := str(filters.get("tag", "")).strip_edges().to_lower()
	var include_archived := bool(filters.get("include_archived", false))
	var rows: Array[Dictionary] = []
	for file_name in DirAccess.get_files_at(IDEAS_DIR):
		if not file_name.to_lower().ends_with(".json"):
			continue
		var loaded := _read_json(IDEAS_DIR + "/" + file_name)
		if not bool(loaded.get("ok", false)):
			continue
		var value: Variant = loaded.get("data", {})
		if not value is Dictionary:
			continue
		var idea := _normalise_idea(value as Dictionary, true)
		if not include_archived and bool(idea.get("archived", false)):
			continue
		var idea_notebook := str(idea.get("notebook_id", ""))
		if notebook_filter == "__unfiled__" and not idea_notebook.is_empty():
			continue
		if notebook_filter != "__all__" and notebook_filter != "__unfiled__" and idea_notebook != notebook_filter:
			continue
		if not tag_filter.is_empty():
			var tag_match := false
			for tag in idea.get("tags", []):
				if str(tag).to_lower() == tag_filter:
					tag_match = true
					break
			if not tag_match:
				continue
		if not search_text.is_empty():
			var haystack := " ".join([
				str(idea.get("title", "")),
				str(idea.get("concept", "")),
				str(idea.get("notes", "")),
				str(idea.get("character_name", "")),
				str(idea.get("character_role", "")),
				str(idea.get("roleplay_hook", "")),
				", ".join(idea.get("tags", []))
			]).to_lower()
			if not haystack.contains(search_text):
				continue
		rows.append(idea)
	rows.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return str(first.get("updated_at", "")) > str(second.get("updated_at", ""))
	)
	return rows


static func all_tags(include_archived: bool = false) -> Array[String]:
	var seen := {}
	var result: Array[String] = []
	for idea in list_ideas({"include_archived": include_archived}):
		for raw_tag in idea.get("tags", []):
			var tag := str(raw_tag).strip_edges()
			var key := tag.to_lower()
			if tag.is_empty() or seen.has(key):
				continue
			seen[key] = true
			result.append(tag)
	result.sort_custom(func(first: String, second: String) -> bool:
		return first.to_lower() < second.to_lower()
	)
	return result


static func notebook_counts(include_archived: bool = false) -> Dictionary:
	var counts := {"__all__": 0, "__unfiled__": 0}
	for notebook in list_notebooks():
		counts[str(notebook.get("id", ""))] = 0
	for idea in list_ideas({"include_archived": include_archived}):
		counts["__all__"] = int(counts.get("__all__", 0)) + 1
		var notebook_id := str(idea.get("notebook_id", ""))
		if notebook_id.is_empty() or not counts.has(notebook_id):
			counts["__unfiled__"] = int(counts.get("__unfiled__", 0)) + 1
		else:
			counts[notebook_id] = int(counts.get(notebook_id, 0)) + 1
	return counts


static func _new_library() -> Dictionary:
	var now := _now()
	return {
		"format": LIBRARY_FORMAT,
		"format_version": FORMAT_VERSION,
		"created_at": now,
		"updated_at": now,
		"notebooks": []
	}


static func _normalise_library(raw: Dictionary) -> Dictionary:
	var result := raw.duplicate(true)
	result["format"] = LIBRARY_FORMAT
	result["format_version"] = FORMAT_VERSION
	if str(result.get("created_at", "")).is_empty():
		result["created_at"] = _now()
	var notebooks: Array = []
	var seen_ids := {}
	for value in result.get("notebooks", []):
		if not value is Dictionary:
			continue
		var row: Dictionary = (value as Dictionary).duplicate(true)
		var notebook_id := str(row.get("id", "")).strip_edges()
		var notebook_name := str(row.get("name", "")).strip_edges()
		if notebook_id.is_empty() or notebook_name.is_empty() or seen_ids.has(notebook_id):
			continue
		seen_ids[notebook_id] = true
		row["id"] = notebook_id
		row["name"] = notebook_name
		notebooks.append(row)
	result["notebooks"] = notebooks
	return result


static func _normalise_idea(raw: Dictionary, preserve_identity: bool = false) -> Dictionary:
	var result := raw.duplicate(true)
	if not preserve_identity:
		result.erase("id")
		result.erase("created_at")
		result.erase("updated_at")
	result["format"] = IDEA_FORMAT
	result["format_version"] = FORMAT_VERSION
	for key in ["title", "concept", "notes", "character_name", "character_role", "source_anchor", "roleplay_hook", "notebook_id"]:
		result[key] = str(result.get(key, "")).strip_edges()
	if str(result.get("title", "")).is_empty():
		result["title"] = "Untitled idea"
	result["tags"] = _normalise_tags(result.get("tags", []))
	result["archived"] = bool(result.get("archived", false))
	var source_value: Variant = result.get("source", {})
	result["source"] = _normalise_source(source_value as Dictionary if source_value is Dictionary else {})
	return result


static func _normalise_source(raw: Dictionary) -> Dictionary:
	var result := raw.duplicate(true)
	result["type"] = str(result.get("type", "idea_generator")).strip_edges()
	result["seed_prompt"] = str(result.get("seed_prompt", "")).strip_edges()
	return result


static func _normalise_tags(raw: Variant) -> Array[String]:
	var values: Array = []
	if raw is Array:
		values = raw
	elif raw is PackedStringArray:
		values = Array(raw)
	else:
		values = str(raw).split(",", false)
	var seen := {}
	var result: Array[String] = []
	for value in values:
		var clean := str(value).strip_edges()
		var key := clean.to_lower()
		if clean.is_empty() or seen.has(key):
			continue
		seen[key] = true
		result.append(clean)
	return result


static func _valid_notebook_id_or_empty(notebook_id: String) -> String:
	var clean_id := notebook_id.strip_edges()
	if clean_id.is_empty():
		return ""
	for notebook in list_notebooks():
		if str(notebook.get("id", "")) == clean_id:
			return clean_id
	return ""


static func _idea_path(idea_id: String) -> String:
	return IDEAS_DIR + "/" + idea_id.validate_filename() + ".json"


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "File does not exist: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open %s for reading." % path}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		return {"ok": false, "error": "Could not parse %s: %s (line %d)." % [path, json.get_error_message(), json.get_error_line()]}
	return {"ok": true, "data": json.data}


static func _write_json(path: String, data: Dictionary) -> Dictionary:
	ensure_directories()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open %s for writing." % path}
	file.store_string(JSON.stringify(data, "  "))
	file.store_string("\n")
	file.close()
	return {"ok": true, "path": path}


static func _new_id() -> String:
	var crypto := Crypto.new()
	return crypto.generate_random_bytes(16).hex_encode()


static func _now() -> String:
	return Time.get_datetime_string_from_system(true)
