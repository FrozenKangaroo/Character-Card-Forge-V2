class_name CCFIdeaNotebookServiceV01532
extends RefCounted

const ROOT_DIR := "user://character_card_forge/idea_notebook"
const IDEAS_DIR := ROOT_DIR + "/ideas"
const LIBRARY_FILE := ROOT_DIR + "/library.json"
const LIBRARY_FORMAT := "character_card_forge_idea_notebook"
const IDEA_FORMAT := "character_card_forge_saved_idea"
const FORMAT_VERSION := 2
const LIBRARY_FORMAT_VERSION := 3

static var _storage_root_override := ""
static var _library_load_count_for_testing := 0
static var _idea_read_count_for_testing := 0
static var _legacy_notebook_folder_ids_cache: Dictionary = {}
static var _migration_alias_cache_ready := false


static func set_storage_root_for_testing(root_path: String) -> void:
	_storage_root_override = root_path.strip_edges().trim_suffix("/")
	_legacy_notebook_folder_ids_cache.clear()
	_migration_alias_cache_ready = false


static func reset_storage_root_after_testing() -> void:
	_storage_root_override = ""
	_legacy_notebook_folder_ids_cache.clear()
	_migration_alias_cache_ready = false


static func reset_io_counters_for_testing() -> void:
	_library_load_count_for_testing = 0
	_idea_read_count_for_testing = 0


static func io_counters_for_testing() -> Dictionary:
	return {
		"library_loads": _library_load_count_for_testing,
		"idea_reads": _idea_read_count_for_testing
	}


static func ensure_directories() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_root_dir()))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_ideas_dir()))


static func load_library() -> Dictionary:
	_library_load_count_for_testing += 1
	ensure_directories()
	if not FileAccess.file_exists(_library_file()):
		var fresh := _new_library()
		var write_result := _write_json(_library_file(), fresh)
		if not bool(write_result.get("ok", false)):
			return write_result
		_legacy_notebook_folder_ids_cache.clear()
		_migration_alias_cache_ready = true
		return {"ok": true, "data": fresh}
	var loaded := _read_json(_library_file())
	if not bool(loaded.get("ok", false)):
		return loaded
	var value: Variant = loaded.get("data", {})
	if not value is Dictionary:
		return {"ok": false, "error": "Idea Library library.json is not a JSON object."}
	var normalised := _normalise_library(value as Dictionary)
	var aliases_value: Variant = normalised.get("legacy_notebook_folder_ids", {})
	_legacy_notebook_folder_ids_cache = (
		(aliases_value as Dictionary).duplicate(true)
		if aliases_value is Dictionary else {}
	)
	_migration_alias_cache_ready = true
	if JSON.stringify(value) != JSON.stringify(normalised):
		var migrated := _write_json(_library_file(), normalised)
		if not bool(migrated.get("ok", false)):
			return migrated
		_migrate_legacy_idea_files_v0217(_legacy_notebook_folder_ids_cache)
	return {"ok": true, "data": normalised}


static func list_folders() -> Array[Dictionary]:
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return []
	var library: Dictionary = loaded.get("data", {})
	var rows: Array[Dictionary] = []
	for value in library.get("folders", []):
		if value is Dictionary:
			rows.append((value as Dictionary).duplicate(true))
	return rows


static func list_notebooks() -> Array[Dictionary]:
	# Compatibility alias for historical callers. Current UI and canonical v3
	# storage expose folders only.
	return list_folders()


static func hierarchy_snapshot() -> Dictionary:
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return loaded
	var library: Dictionary = loaded.get("data", {})
	var folders: Array[Dictionary] = []
	var folder_by_id := {}
	for value in library.get("folders", []):
		if not value is Dictionary:
			continue
		var folder: Dictionary = (value as Dictionary).duplicate(true)
		var folder_id := str(folder.get("id", ""))
		folders.append(folder)
		folder_by_id[folder_id] = folder
	var folder_paths := {}
	for folder in folders:
		var folder_id := str(folder.get("id", ""))
		folder_paths[folder_id] = _folder_path_from_records_v0215(
			folder_id, folder_by_id
		)
	return {
		"ok": true,
		"folders": folders,
		"notebooks": [],
		"folder_by_id": folder_by_id,
		"notebook_by_id": {},
		"folder_paths": folder_paths,
		"notebook_paths": {}
	}


static func hierarchy_counts_from_snapshot(
	snapshot: Dictionary, ideas: Array, include_archived: bool = false
) -> Dictionary:
	var direct_folder_counts := {"__all__": 0, "__unfiled__": 0}
	var folder_counts := {}
	var parent_by_folder := {}
	for folder_value in snapshot.get("folders", []):
		var folder: Dictionary = folder_value
		var folder_id := str(folder.get("id", ""))
		folder_counts[folder_id] = 0
		direct_folder_counts[folder_id] = 0
		parent_by_folder[folder_id] = str(folder.get("parent_folder_id", ""))
	for idea_value in ideas:
		if not idea_value is Dictionary:
			continue
		var idea: Dictionary = idea_value
		if not include_archived and bool(idea.get("archived", false)):
			continue
		direct_folder_counts["__all__"] = int(direct_folder_counts.get("__all__", 0)) + 1
		var folder_id := str(idea.get("folder_id", ""))
		if folder_id.is_empty() or not direct_folder_counts.has(folder_id):
			direct_folder_counts["__unfiled__"] = int(
				direct_folder_counts.get("__unfiled__", 0)
			) + 1
		else:
			direct_folder_counts[folder_id] = int(direct_folder_counts.get(folder_id, 0)) + 1
		var cursor := folder_id
		var visited := {}
		while not cursor.is_empty() and folder_counts.has(cursor) and not visited.has(cursor):
			visited[cursor] = true
			folder_counts[cursor] = int(folder_counts.get(cursor, 0)) + 1
			cursor = str(parent_by_folder.get(cursor, ""))
	return {
		"direct_folder_counts": direct_folder_counts,
		"folder_counts": folder_counts,
		# Historical key retained for older internal callers during the v3 transition.
		"notebook_counts": direct_folder_counts
	}


static func folder_path_from_snapshot(folder_id: String, snapshot: Dictionary) -> String:
	return str((snapshot.get("folder_paths", {}) as Dictionary).get(folder_id, ""))


static func notebook_path_from_snapshot(notebook_id: String, snapshot: Dictionary) -> String:
	return folder_path_from_snapshot(notebook_id, snapshot)


static func notebook_ids_in_folder_from_snapshot(
	folder_id: String, snapshot: Dictionary, recursive: bool = true
) -> Array[String]:
	return folder_ids_in_folder_from_snapshot(folder_id, snapshot, recursive)


static func folder_ids_in_folder_from_snapshot(
	folder_id: String, snapshot: Dictionary, recursive: bool = true
) -> Array[String]:
	var clean_id := folder_id.strip_edges()
	var result: Array[String] = []
	if clean_id.is_empty():
		return result
	result.append(clean_id)
	if recursive:
		var pending: Array[String] = [clean_id]
		var seen := {clean_id: true}
		while not pending.is_empty():
			var current: String = pending.pop_back()
			for folder_value in snapshot.get("folders", []):
				var folder: Dictionary = folder_value
				var child_id := str(folder.get("id", ""))
				if (
					str(folder.get("parent_folder_id", "")) == current
					and not seen.has(child_id)
				):
					seen[child_id] = true
					result.append(child_id)
					pending.append(child_id)
	return result


static func create_notebook(display_name: String, parent_folder_id: String = "") -> Dictionary:
	var result := create_folder(display_name, parent_folder_id)
	if bool(result.get("ok", false)):
		result["notebook"] = (result.get("folder", {}) as Dictionary).duplicate(true)
	return result


static func rename_notebook(notebook_id: String, display_name: String) -> Dictionary:
	return rename_folder(notebook_id, display_name)


static func create_folder(display_name: String, parent_folder_id: String = "") -> Dictionary:
	var clean_name := display_name.strip_edges()
	if clean_name.is_empty():
		return {"ok": false, "error": "Folder name cannot be empty."}
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return loaded
	var library: Dictionary = loaded.get("data", {})
	var clean_parent := _valid_folder_id_or_empty_from_library(parent_folder_id, library)
	if not parent_folder_id.strip_edges().is_empty() and clean_parent.is_empty():
		return {"ok": false, "error": "Parent folder was not found."}
	var folders: Array = library.get("folders", []).duplicate(true)
	for value in folders:
		if not value is Dictionary:
			continue
		var row: Dictionary = value
		if (
			str(row.get("parent_folder_id", "")) == clean_parent
			and str(row.get("name", "")).nocasecmp_to(clean_name) == 0
		):
			return {"ok": false, "error": "A folder named '%s' already exists here." % clean_name}
	var now := _now()
	var folder := {
		"id": _new_id(),
		"name": clean_name,
		"parent_folder_id": clean_parent,
		"created_at": now,
		"updated_at": now
	}
	folders.append(folder)
	library["folders"] = folders
	library["updated_at"] = now
	var saved := _write_json(_library_file(), library)
	if not bool(saved.get("ok", false)):
		return saved
	return {"ok": true, "folder": folder.duplicate(true)}


static func rename_folder(folder_id: String, display_name: String) -> Dictionary:
	var clean_id := folder_id.strip_edges()
	var clean_name := display_name.strip_edges()
	if clean_id.is_empty() or clean_name.is_empty():
		return {"ok": false, "error": "Folder ID and name are required."}
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return loaded
	var library: Dictionary = loaded.get("data", {})
	var folders: Array = library.get("folders", []).duplicate(true)
	var parent_id := ""
	var found := false
	for value in folders:
		if value is Dictionary and str((value as Dictionary).get("id", "")) == clean_id:
			parent_id = str((value as Dictionary).get("parent_folder_id", ""))
			found = true
			break
	if not found:
		return {"ok": false, "error": "Folder was not found."}
	for value in folders:
		if not value is Dictionary:
			continue
		var row: Dictionary = value
		if (
			str(row.get("id", "")) != clean_id
			and str(row.get("parent_folder_id", "")) == parent_id
			and str(row.get("name", "")).nocasecmp_to(clean_name) == 0
		):
			return {"ok": false, "error": "A folder named '%s' already exists here." % clean_name}
	for index in range(folders.size()):
		if not folders[index] is Dictionary:
			continue
		var row: Dictionary = (folders[index] as Dictionary).duplicate(true)
		if str(row.get("id", "")) != clean_id:
			continue
		row["name"] = clean_name
		row["updated_at"] = _now()
		folders[index] = row
		break
	library["folders"] = folders
	library["updated_at"] = _now()
	return _write_json(_library_file(), library)


static func move_notebook(notebook_id: String, parent_folder_id: String = "") -> Dictionary:
	return move_folder(notebook_id, parent_folder_id)


static func move_folder(folder_id: String, parent_folder_id: String = "") -> Dictionary:
	var clean_id := folder_id.strip_edges()
	var requested_parent := parent_folder_id.strip_edges()
	if clean_id.is_empty():
		return {"ok": false, "error": "Folder ID is required."}
	if clean_id == requested_parent:
		return {"ok": false, "error": "A folder cannot be moved into itself."}
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return loaded
	var library: Dictionary = loaded.get("data", {})
	var clean_parent := _valid_folder_id_or_empty_from_library(requested_parent, library)
	if not requested_parent.is_empty() and clean_parent.is_empty():
		return {"ok": false, "error": "Destination folder was not found."}
	if clean_parent in descendant_folder_ids(clean_id):
		return {"ok": false, "error": "A folder cannot be moved into one of its descendants."}
	var folders: Array = library.get("folders", []).duplicate(true)
	var moving_name := ""
	for value in folders:
		if value is Dictionary and str((value as Dictionary).get("id", "")) == clean_id:
			moving_name = str((value as Dictionary).get("name", ""))
			break
	for value in folders:
		if not value is Dictionary:
			continue
		var existing: Dictionary = value
		if (
			str(existing.get("id", "")) != clean_id
			and str(existing.get("parent_folder_id", "")) == clean_parent
			and str(existing.get("name", "")).nocasecmp_to(moving_name) == 0
		):
			return {"ok": false, "error": "A folder named '%s' already exists in the destination." % moving_name}
	var found := false
	for index in range(folders.size()):
		if not folders[index] is Dictionary:
			continue
		var row: Dictionary = (folders[index] as Dictionary).duplicate(true)
		if str(row.get("id", "")) != clean_id:
			continue
		row["parent_folder_id"] = clean_parent
		row["updated_at"] = _now()
		folders[index] = row
		found = true
		break
	if not found:
		return {"ok": false, "error": "Folder was not found."}
	library["folders"] = folders
	library["updated_at"] = _now()
	return _write_json(_library_file(), library)


static func delete_folder(folder_id: String) -> Dictionary:
	var clean_id := folder_id.strip_edges()
	if clean_id.is_empty():
		return {"ok": false, "error": "Folder ID is required."}
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return loaded
	var library: Dictionary = loaded.get("data", {})
	var folders: Array = library.get("folders", []).duplicate(true)
	var parent_id := ""
	var found := false
	for value in folders:
		if value is Dictionary and str((value as Dictionary).get("id", "")) == clean_id:
			parent_id = str((value as Dictionary).get("parent_folder_id", ""))
			found = true
			break
	if not found:
		return {"ok": false, "error": "Folder was not found."}
	# Move only ideas assigned directly to this folder. Descendant ideas remain
	# with their child folders, which are reparented below.
	var move_result := move_ideas_to_folder(
		_direct_idea_ids_for_folder_v0217(clean_id), parent_id
	)
	if not bool(move_result.get("ok", false)):
		return {
			"ok": false,
			"error": "The folder was kept because some direct ideas could not be moved. %s"
				% str(move_result.get("error", "")),
			"move_result": move_result
		}
	for index in range(folders.size() - 1, -1, -1):
		if not folders[index] is Dictionary:
			continue
		var row: Dictionary = (folders[index] as Dictionary).duplicate(true)
		if str(row.get("id", "")) == clean_id:
			folders.remove_at(index)
		elif str(row.get("parent_folder_id", "")) == clean_id:
			row["parent_folder_id"] = parent_id
			row["updated_at"] = _now()
			folders[index] = row
	library["folders"] = folders
	library["updated_at"] = _now()
	var saved := _write_json(_library_file(), library)
	if not bool(saved.get("ok", false)):
		return saved
	return {
		"ok": true,
		"moved_ideas": int(move_result.get("moved", 0)),
		"parent_folder_id": parent_id
	}


static func delete_notebook(notebook_id: String) -> Dictionary:
	return delete_folder(notebook_id)


static func save_generated_idea(raw_idea: Dictionary, folder_id: String = "", source: Dictionary = {}) -> Dictionary:
	var now := _now()
	var idea := _normalise_idea(raw_idea)
	if str(idea.get("concept", "")).strip_edges().is_empty():
		return {"ok": false, "error": "An idea needs concept text before it can be saved."}
	idea["id"] = _new_id()
	idea["folder_id"] = _valid_folder_id_or_empty(folder_id)
	idea.erase("notebook_id")
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
	if changes.has("folder_id"):
		idea["folder_id"] = _valid_folder_id_or_empty(str(changes.get("folder_id", "")))
	elif changes.has("notebook_id"):
		# Compatibility with historical internal callers; canonical writes remain v3.
		idea["folder_id"] = _valid_folder_id_or_empty(str(changes.get("notebook_id", "")))
	if changes.has("archived"):
		idea["archived"] = bool(changes.get("archived", false))
	if str(idea.get("concept", "")).is_empty():
		return {"ok": false, "error": "An idea needs concept text."}
	idea["updated_at"] = _now()
	idea["format_version"] = FORMAT_VERSION
	idea.erase("notebook_id")
	var saved := _write_json(_idea_path(idea_id), idea)
	if not bool(saved.get("ok", false)):
		return saved
	return {"ok": true, "idea": idea.duplicate(true)}


static func load_idea(idea_id: String) -> Dictionary:
	ensure_directories()
	var clean_id := idea_id.strip_edges()
	if clean_id.is_empty():
		return {"ok": false, "error": "Idea ID is required."}
	_idea_read_count_for_testing += 1
	var loaded := _read_json(_idea_path(clean_id))
	if not bool(loaded.get("ok", false)):
		return loaded
	var value: Variant = loaded.get("data", {})
	if not value is Dictionary:
		return {"ok": false, "error": "Saved idea is not a JSON object."}
	if (value as Dictionary).has("notebook_id") and not _migration_alias_cache_ready:
		# A direct legacy-Idea read must still honour collision aliases even when
		# no hierarchy call has populated the migration cache in this process.
		load_library()
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
	if not _migration_alias_cache_ready:
		load_library()
	var folder_filter := str(filters.get(
		"folder_id", filters.get("notebook_id", "__all__")
	))
	var has_folder_ids := filters.has("folder_ids") or filters.has("notebook_ids")
	var folder_ids_value: Variant = filters.get(
		"folder_ids", filters.get("notebook_ids", [])
	)
	var folder_ids: Array = (
		folder_ids_value as Array if folder_ids_value is Array else []
	)
	var search_text := str(filters.get("search", "")).strip_edges().to_lower()
	var tag_filter := str(filters.get("tag", "")).strip_edges().to_lower()
	var include_archived := bool(filters.get("include_archived", false))
	var rows: Array[Dictionary] = []
	for file_name in DirAccess.get_files_at(_ideas_dir()):
		if not file_name.to_lower().ends_with(".json"):
			continue
		_idea_read_count_for_testing += 1
		var loaded := _read_json(_ideas_dir() + "/" + file_name)
		if not bool(loaded.get("ok", false)):
			continue
		var value: Variant = loaded.get("data", {})
		if not value is Dictionary:
			continue
		var idea := _normalise_idea(value as Dictionary, true)
		if not include_archived and bool(idea.get("archived", false)):
			continue
		var idea_folder := str(idea.get("folder_id", ""))
		if folder_filter == "__unfiled__" and not idea_folder.is_empty():
			continue
		if folder_filter != "__all__" and folder_filter != "__unfiled__" and idea_folder != folder_filter:
			continue
		if has_folder_ids and not idea_folder in folder_ids:
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
	return direct_folder_counts(include_archived)


static func direct_folder_counts(include_archived: bool = false) -> Dictionary:
	var counts := {"__all__": 0, "__unfiled__": 0}
	for folder in list_folders():
		counts[str(folder.get("id", ""))] = 0
	for idea in list_ideas({"include_archived": include_archived}):
		counts["__all__"] = int(counts.get("__all__", 0)) + 1
		var folder_id := str(idea.get("folder_id", ""))
		if folder_id.is_empty() or not counts.has(folder_id):
			counts["__unfiled__"] = int(counts.get("__unfiled__", 0)) + 1
		else:
			counts[folder_id] = int(counts.get(folder_id, 0)) + 1
	return counts


static func folder_counts(include_archived: bool = false) -> Dictionary:
	var direct_counts := direct_folder_counts(include_archived)
	var result := {}
	var parent_by_folder := {}
	for folder in list_folders():
		var folder_id := str(folder.get("id", ""))
		result[folder_id] = 0
		parent_by_folder[folder_id] = str(folder.get("parent_folder_id", ""))
	for folder in list_folders():
		var folder_id := str(folder.get("id", ""))
		var count := int(direct_counts.get(folder_id, 0))
		var cursor := folder_id
		var visited := {}
		while not cursor.is_empty() and result.has(cursor) and not visited.has(cursor):
			visited[cursor] = true
			result[cursor] = int(result.get(cursor, 0)) + count
			cursor = str(parent_by_folder.get(cursor, ""))
	return result


static func folder_path(folder_id: String) -> String:
	var clean_id := folder_id.strip_edges()
	if clean_id.is_empty():
		return ""
	return folder_path_from_snapshot(clean_id, hierarchy_snapshot())


static func notebook_path(notebook_id: String) -> String:
	return folder_path(notebook_id)


static func descendant_folder_ids(folder_id: String, include_self: bool = false) -> Array[String]:
	var clean_id := folder_id.strip_edges()
	var result: Array[String] = []
	if clean_id.is_empty():
		return result
	var children := {}
	for folder in list_folders():
		var parent_id := str(folder.get("parent_folder_id", ""))
		if not children.has(parent_id):
			children[parent_id] = []
		(children[parent_id] as Array).append(str(folder.get("id", "")))
	var pending: Array[String] = [clean_id]
	var visited := {}
	while not pending.is_empty():
		var current: String = pending.pop_back()
		if current.is_empty() or visited.has(current):
			continue
		visited[current] = true
		if current != clean_id or include_self:
			result.append(current)
		for child_value in children.get(current, []):
			pending.append(str(child_value))
	return result


static func notebook_ids_in_folder(folder_id: String, recursive: bool = true) -> Array[String]:
	return folder_ids_in_folder(folder_id, recursive)


static func folder_ids_in_folder(folder_id: String, recursive: bool = true) -> Array[String]:
	var clean_id := folder_id.strip_edges()
	if clean_id.is_empty():
		return []
	var result: Array[String] = [clean_id]
	if recursive:
		result.append_array(descendant_folder_ids(clean_id))
	return result


static func move_ideas_to_folder(idea_ids: Array[String], folder_id: String = "") -> Dictionary:
	var destination := _valid_folder_id_or_empty(folder_id)
	if not folder_id.strip_edges().is_empty() and destination.is_empty():
		return {"ok": false, "error": "Destination folder was not found.", "moved": 0, "failed": idea_ids.size()}
	var unique_ids: Array[String] = []
	for idea_id in idea_ids:
		var clean_id := idea_id.strip_edges()
		if not clean_id.is_empty() and not clean_id in unique_ids:
			unique_ids.append(clean_id)
	var moved := 0
	var failures: Array[String] = []
	for idea_id in unique_ids:
		var loaded := load_idea(idea_id)
		if not bool(loaded.get("ok", false)):
			failures.append("%s: %s" % [idea_id, str(loaded.get("error", "Could not load idea."))])
			continue
		var idea: Dictionary = loaded.get("data", {})
		idea["folder_id"] = destination
		idea["updated_at"] = _now()
		idea["format_version"] = FORMAT_VERSION
		idea.erase("notebook_id")
		var saved := _write_json(_idea_path(idea_id), idea)
		if bool(saved.get("ok", false)):
			moved += 1
		else:
			failures.append("%s: %s" % [idea_id, str(saved.get("error", "Could not save idea."))])
	return {
		"ok": failures.is_empty(),
		"moved": moved,
		"failed": failures.size(),
		"failures": failures,
		"error": "; ".join(failures.slice(0, 3))
	}


static func _direct_idea_ids_for_folder_v0217(folder_id: String) -> Array[String]:
	var result: Array[String] = []
	for idea in list_ideas({"include_archived": true, "folder_id": folder_id}):
		result.append(str(idea.get("id", "")))
	return result


static func expanded_folder_ids() -> Array[String]:
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return []
	var library: Dictionary = loaded.get("data", {})
	var ui_value: Variant = library.get("ui_state", {})
	var ui: Dictionary = ui_value if ui_value is Dictionary else {}
	var valid := _folder_map()
	var result: Array[String] = []
	var ids_value: Variant = ui.get("expanded_folder_ids", [])
	if ids_value is Array:
		for value in ids_value as Array:
			var folder_id := str(value)
			if valid.has(folder_id) and not folder_id in result:
				result.append(folder_id)
	return result


static func save_expanded_folder_ids(folder_ids: Array[String]) -> Dictionary:
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return loaded
	var library: Dictionary = loaded.get("data", {})
	var valid := {}
	for folder in library.get("folders", []):
		if folder is Dictionary:
			valid[str((folder as Dictionary).get("id", ""))] = true
	var clean_ids: Array[String] = []
	for folder_id in folder_ids:
		if valid.has(folder_id) and not folder_id in clean_ids:
			clean_ids.append(folder_id)
	var ui_value: Variant = library.get("ui_state", {})
	var ui: Dictionary = (
		(ui_value as Dictionary).duplicate(true) if ui_value is Dictionary else {}
	)
	ui["expanded_folder_ids"] = clean_ids
	library["ui_state"] = ui
	return _write_json(_library_file(), library)


static func _new_library() -> Dictionary:
	var now := _now()
	return {
		"format": LIBRARY_FORMAT,
		"format_version": LIBRARY_FORMAT_VERSION,
		"created_at": now,
		"updated_at": now,
		"folders": [],
		"ui_state": {"expanded_folder_ids": []},
		"legacy_notebook_folder_ids": {}
	}


static func _normalise_library(raw: Dictionary) -> Dictionary:
	var result := raw.duplicate(true)
	result["format"] = LIBRARY_FORMAT
	result["format_version"] = LIBRARY_FORMAT_VERSION
	if str(result.get("created_at", "")).is_empty():
		result["created_at"] = _now()
	if str(result.get("updated_at", "")).is_empty():
		result["updated_at"] = str(result.get("created_at", _now()))
	var folders: Array = []
	var folder_ids := {}
	for value in result.get("folders", []):
		if not value is Dictionary:
			continue
		var row: Dictionary = (value as Dictionary).duplicate(true)
		var folder_id := str(row.get("id", "")).strip_edges()
		var folder_name := str(row.get("name", "")).strip_edges()
		if folder_id.is_empty() or folder_name.is_empty() or folder_ids.has(folder_id):
			continue
		folder_ids[folder_id] = true
		row["id"] = folder_id
		row["name"] = folder_name
		row["parent_folder_id"] = str(row.get("parent_folder_id", "")).strip_edges()
		if str(row.get("created_at", "")).is_empty():
			row["created_at"] = str(result.get("created_at", _now()))
		if str(row.get("updated_at", "")).is_empty():
			row["updated_at"] = str(row.get("created_at", _now()))
		folders.append(row)
	# Missing parents, self-parenting and cycles all recover to root.
	for index in range(folders.size()):
		var row: Dictionary = (folders[index] as Dictionary).duplicate(true)
		var folder_id := str(row.get("id", ""))
		var parent_id := str(row.get("parent_folder_id", ""))
		if parent_id == folder_id or (not parent_id.is_empty() and not folder_ids.has(parent_id)):
			row["parent_folder_id"] = ""
			folders[index] = row
	var parent_by_id := {}
	for value in folders:
		var row: Dictionary = value
		parent_by_id[str(row.get("id", ""))] = str(row.get("parent_folder_id", ""))
	for index in range(folders.size()):
		var row: Dictionary = (folders[index] as Dictionary).duplicate(true)
		var start_id := str(row.get("id", ""))
		var cursor := str(row.get("parent_folder_id", ""))
		var visited := {start_id: true}
		while not cursor.is_empty():
			if visited.has(cursor):
				row["parent_folder_id"] = ""
				folders[index] = row
				parent_by_id[start_id] = ""
				break
			visited[cursor] = true
			cursor = str(parent_by_id.get(cursor, ""))
	var aliases_value: Variant = result.get("legacy_notebook_folder_ids", {})
	var legacy_aliases: Dictionary = (
		(aliases_value as Dictionary).duplicate(true)
		if aliases_value is Dictionary else {}
	)
	# v1/v2 migration: every former Notebook becomes a Folder in the same
	# parent, with the same ID unless that ID is already occupied by a Folder.
	for value in result.get("notebooks", []):
		if not value is Dictionary:
			continue
		var row: Dictionary = (value as Dictionary).duplicate(true)
		var legacy_id := str(row.get("id", "")).strip_edges()
		var folder_name := str(row.get("name", "")).strip_edges()
		if legacy_id.is_empty() or folder_name.is_empty() or legacy_aliases.has(legacy_id):
			continue
		var migrated_id := legacy_id
		if folder_ids.has(migrated_id):
			migrated_id = "%s-legacy-notebook" % legacy_id
			var suffix := 2
			while folder_ids.has(migrated_id):
				migrated_id = "%s-legacy-notebook-%d" % [legacy_id, suffix]
				suffix += 1
		row["id"] = migrated_id
		row["name"] = folder_name
		var parent_id := str(row.get("parent_folder_id", "")).strip_edges()
		row["parent_folder_id"] = parent_id if folder_ids.has(parent_id) else ""
		if str(row.get("created_at", "")).is_empty():
			row["created_at"] = str(result.get("created_at", _now()))
		if str(row.get("updated_at", "")).is_empty():
			row["updated_at"] = str(row.get("created_at", _now()))
		folders.append(row)
		folder_ids[migrated_id] = true
		legacy_aliases[legacy_id] = migrated_id
	result["folders"] = folders
	result.erase("notebooks")
	var clean_aliases := {}
	for legacy_id_value in legacy_aliases:
		var legacy_id := str(legacy_id_value).strip_edges()
		var migrated_id := str(legacy_aliases[legacy_id_value]).strip_edges()
		if not legacy_id.is_empty() and folder_ids.has(migrated_id):
			clean_aliases[legacy_id] = migrated_id
	result["legacy_notebook_folder_ids"] = clean_aliases
	var ui_value: Variant = result.get("ui_state", {})
	var ui: Dictionary = ui_value if ui_value is Dictionary else {}
	var expanded: Array[String] = []
	var expanded_value: Variant = ui.get("expanded_folder_ids", [])
	if expanded_value is Array:
		for value in expanded_value as Array:
			var folder_id := str(value)
			if folder_ids.has(folder_id) and not folder_id in expanded:
				expanded.append(folder_id)
	ui["expanded_folder_ids"] = expanded
	result["ui_state"] = ui
	return result


static func _normalise_idea(raw: Dictionary, preserve_identity: bool = false) -> Dictionary:
	var result := raw.duplicate(true)
	if not preserve_identity:
		result.erase("id")
		result.erase("created_at")
		result.erase("updated_at")
	result["format"] = IDEA_FORMAT
	result["format_version"] = FORMAT_VERSION
	for key in ["title", "concept", "notes", "character_name", "character_role", "source_anchor", "roleplay_hook"]:
		result[key] = str(result.get(key, "")).strip_edges()
	var folder_id := str(result.get("folder_id", "")).strip_edges()
	if folder_id.is_empty():
		var legacy_notebook_id := str(result.get("notebook_id", "")).strip_edges()
		folder_id = str(_legacy_notebook_folder_ids_cache.get(
			legacy_notebook_id, legacy_notebook_id
		))
	result["folder_id"] = folder_id
	result.erase("notebook_id")
	if str(result.get("title", "")).is_empty():
		result["title"] = "Untitled idea"
	result["tags"] = _normalise_tags(result.get("tags", []))
	result["archived"] = bool(result.get("archived", false))
	var source_value: Variant = result.get("source", {})
	result["source"] = _normalise_source(source_value as Dictionary if source_value is Dictionary else {})
	return result


static func _migrate_legacy_idea_files_v0217(aliases: Dictionary) -> void:
	for file_name in DirAccess.get_files_at(_ideas_dir()):
		if not file_name.to_lower().ends_with(".json"):
			continue
		var path := _ideas_dir() + "/" + file_name
		var loaded := _read_json(path)
		if not bool(loaded.get("ok", false)):
			continue
		var value: Variant = loaded.get("data", {})
		if not value is Dictionary:
			continue
		var raw: Dictionary = value
		if not raw.has("notebook_id") and int(raw.get("format_version", FORMAT_VERSION)) >= FORMAT_VERSION:
			continue
		var canonical := raw.duplicate(true)
		var legacy_id := str(canonical.get("notebook_id", "")).strip_edges()
		if not canonical.has("folder_id") or str(canonical.get("folder_id", "")).strip_edges().is_empty():
			canonical["folder_id"] = str(aliases.get(legacy_id, legacy_id))
		canonical.erase("notebook_id")
		canonical["format"] = IDEA_FORMAT
		canonical["format_version"] = FORMAT_VERSION
		_write_json(path, canonical)


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


static func _folder_path_from_records_v0215(
	folder_id: String, folder_by_id: Dictionary
) -> String:
	var names: Array[String] = []
	var cursor := folder_id.strip_edges()
	var visited := {}
	while (
		not cursor.is_empty()
		and folder_by_id.has(cursor)
		and not visited.has(cursor)
	):
		visited[cursor] = true
		var row: Dictionary = folder_by_id[cursor]
		names.push_front(str(row.get("name", "Folder")))
		cursor = str(row.get("parent_folder_id", ""))
	return " / ".join(names)


static func _valid_notebook_id_or_empty(notebook_id: String) -> String:
	return _valid_folder_id_or_empty(notebook_id)


static func _valid_folder_id_or_empty(folder_id: String) -> String:
	var loaded := load_library()
	if not bool(loaded.get("ok", false)):
		return ""
	return _valid_folder_id_or_empty_from_library(
		folder_id, loaded.get("data", {})
	)


static func _valid_folder_id_or_empty_from_library(
	folder_id: String, library: Dictionary
) -> String:
	var clean_id := folder_id.strip_edges()
	if clean_id.is_empty():
		return ""
	for folder in library.get("folders", []):
		if folder is Dictionary and str((folder as Dictionary).get("id", "")) == clean_id:
			return clean_id
	return ""


static func _folder_map() -> Dictionary:
	var result := {}
	for folder in list_folders():
		result[str(folder.get("id", ""))] = folder
	return result


static func _root_dir() -> String:
	return ROOT_DIR if _storage_root_override.is_empty() else _storage_root_override


static func _ideas_dir() -> String:
	return _root_dir() + "/ideas"


static func _library_file() -> String:
	return _root_dir() + "/library.json"


static func _idea_path(idea_id: String) -> String:
	return _ideas_dir() + "/" + idea_id.validate_filename() + ".json"


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
