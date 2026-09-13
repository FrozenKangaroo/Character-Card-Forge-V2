class_name CCFPortableLibraryServiceV0200
extends RefCounted

const FORMAT_VERSION := 1
const MANIFEST_FILE := ".ccf-library.json"
const CHARACTERS_FOLDER := "characters"


static func capabilities_v0200() -> Dictionary:
	return {
		"optional_portable_location": true,
		"local_indexes_and_thumbnails": true,
		"cooperative_single_writer_lock": true,
		"atomic_project_json_replace": true,
		"external_change_conflicts": true,
		"unavailable_share_never_falls_back": true,
		"automatic_cloud_sync": false,
		"collaborative_multi_user_editing": false
	}


static func inspect_location_v0200(root_path: String) -> Dictionary:
	var validation := _validate_root_v0200(root_path)
	if not bool(validation.get("ok", false)):
		return validation
	var root := str(validation.get("root", ""))
	if not DirAccess.dir_exists_absolute(root):
		return {
			"ok": true,
			"available": false,
			"initialized": false,
			"root": root,
			"project_count": 0,
			"message": "The selected folder is not currently available."
		}
	var manifest_path := root.path_join(MANIFEST_FILE)
	var manifest: Dictionary = {}
	if FileAccess.file_exists(manifest_path):
		var parsed := _read_json_v0200(manifest_path)
		if not bool(parsed.get("ok", false)):
			return {
				"ok": false,
				"available": true,
				"error": "The selected folder contains an invalid Character Card Forge library manifest."
			}
		manifest = parsed.get("data", {})
		if int(manifest.get("format_version", 0)) > FORMAT_VERSION:
			return {
				"ok": false,
				"available": true,
				"error": "This library was created by a newer, unsupported Character Card Forge version."
			}
	var characters_path := root.path_join(CHARACTERS_FOLDER)
	var project_count := 0
	if DirAccess.dir_exists_absolute(characters_path):
		project_count = DirAccess.get_directories_at(characters_path).size()
	return {
		"ok": true,
		"available": true,
		"initialized": not manifest.is_empty(),
		"root": root,
		"project_count": project_count,
		"library_id": str(manifest.get("library_id", "")),
		"message": (
			"Ready: %d project folder%s found." % [
				project_count, "" if project_count == 1 else "s"
			]
			if not manifest.is_empty()
			else "This folder can be initialized as a portable library."
		)
	}


static func prepare_location_v0200(root_path: String, writer_id: String) -> Dictionary:
	var validation := _validate_root_v0200(root_path)
	if not bool(validation.get("ok", false)):
		return validation
	var root := str(validation.get("root", ""))
	var create_error := DirAccess.make_dir_recursive_absolute(root)
	if create_error != OK:
		return {"ok": false, "error": "Could not create the selected portable-library folder."}
	var inspection := inspect_location_v0200(root)
	if not bool(inspection.get("ok", false)):
		return inspection
	var characters_path := root.path_join(CHARACTERS_FOLDER)
	create_error = DirAccess.make_dir_recursive_absolute(characters_path)
	if create_error != OK:
		return {"ok": false, "error": "Could not create the portable library's characters folder."}
	var write_test_path := root.path_join(".ccf-write-test-%s" % _safe_token_v0200(writer_id))
	var write_test := FileAccess.open(write_test_path, FileAccess.WRITE)
	if write_test == null:
		return {"ok": false, "error": "The selected folder is not writable."}
	write_test.store_string("Character Card Forge portable-library write test")
	write_test.flush()
	write_test.close()
	DirAccess.remove_absolute(write_test_path)

	var manifest_path := root.path_join(MANIFEST_FILE)
	var library_id := str(inspection.get("library_id", ""))
	if library_id.is_empty():
		library_id = _new_id_v0200("library")
		var manifest := {
			"format_version": FORMAT_VERSION,
			"library_id": library_id,
			"created_at": Time.get_datetime_string_from_system(true),
			"storage_contract": "portable-shared-folder",
			"writer_expectation": "single-writer",
			"indexes_and_thumbnails": "local-only"
		}
		var manifest_result := _write_json_v0200(manifest_path, manifest)
		if not bool(manifest_result.get("ok", false)):
			return manifest_result
	return {
		"ok": true,
		"available": true,
		"initialized": true,
		"root": root,
		"library_id": library_id,
		"project_count": int(inspection.get("project_count", 0)),
		"message": "Portable library ready. Existing projects were not moved or copied."
	}


static func settings_for_portable_v0200(
	settings: Dictionary, root_path: String
) -> Dictionary:
	var updated := settings.duplicate(true)
	var storage: Dictionary = updated.get("library_storage", {}).duplicate(true)
	storage["mode"] = "portable"
	storage["portable_root"] = root_path.strip_edges().simplify_path()
	updated["library_storage"] = storage
	return updated


static func settings_for_local_v0200(settings: Dictionary) -> Dictionary:
	var updated := settings.duplicate(true)
	var storage: Dictionary = updated.get("library_storage", {}).duplicate(true)
	storage["mode"] = "local"
	updated["library_storage"] = storage
	return updated


static func _validate_root_v0200(root_path: String) -> Dictionary:
	var root := root_path.strip_edges()
	if root.is_empty():
		return {"ok": false, "error": "Choose a portable-library folder."}
	if not root.is_absolute_path():
		return {"ok": false, "error": "Portable-library locations must use an absolute path."}
	root = root.simplify_path()
	if root in ["/", "\\"] or root.get_base_dir() == root:
		return {"ok": false, "error": "Choose a dedicated folder, not a filesystem root."}
	return {"ok": true, "root": root}


static func _read_json_v0200(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read the library manifest."}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {"ok": false, "error": "The library manifest is not a JSON object."}
	return {"ok": true, "data": parsed}


static func _write_json_v0200(path: String, data: Dictionary) -> Dictionary:
	var temporary := "%s.ccf-writing" % path
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not write the library manifest."}
	file.store_string(JSON.stringify(data, "  "))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var rename_error := DirAccess.rename_absolute(temporary, path)
	if rename_error != OK:
		DirAccess.remove_absolute(temporary)
		return {"ok": false, "error": "Could not finalize the library manifest."}
	return {"ok": true}


static func _safe_token_v0200(value: String) -> String:
	var result := ""
	for character_index in range(value.length()):
		var character := value.substr(character_index, 1).to_lower()
		if "abcdefghijklmnopqrstuvwxyz0123456789-_".contains(character):
			result += character
	return result.left(48) if not result.is_empty() else "writer"


static func _new_id_v0200(prefix: String) -> String:
	return "%s-%d-%d" % [prefix, int(Time.get_unix_time_from_system()), randi_range(100000, 999999)]
