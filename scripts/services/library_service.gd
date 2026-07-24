class_name CCFLibraryService
extends RefCounted

const INDEX_FORMAT_VERSION := 2
const VIEW_STATE_FORMAT_VERSION := 2
const INDEX_FILE := CCFStorageService.CACHE_DIR + "/library_index.json"
const VIEW_STATE_FILE := CCFStorageService.SETTINGS_DIR + "/library_view.json"
const THUMBNAIL_DIR := CCFStorageService.CACHE_DIR + "/library_thumbnails"
const THUMBNAIL_WIDTH := 320
const THUMBNAIL_HEIGHT := 400


static func refresh_index(force_rebuild: bool = false) -> Dictionary:
	CCFStorageService.ensure_directories()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(THUMBNAIL_DIR))
	if force_rebuild:
		_clear_thumbnail_cache()
	var cached_entries: Dictionary = {}
	if not force_rebuild:
		var cached_index := _read_json(INDEX_FILE)
		if cached_index.get("ok", false):
			var cached_data: Dictionary = cached_index.get("data", {})
			if int(cached_data.get("format_version", 0)) == INDEX_FORMAT_VERSION:
				var raw_entries: Variant = cached_data.get("entries", {})
				if raw_entries is Dictionary:
					cached_entries = raw_entries

	var rows: Array[Dictionary] = []
	var next_entries: Dictionary = {}
	var reused_count := 0
	var refreshed_count := 0
	var skipped_count := 0
	for folder_project_id in DirAccess.get_directories_at(CCFStorageService.CHARACTERS_DIR):
		var project_path := CCFStorageService.project_folder(folder_project_id).path_join(
			CCFStorageService.PROJECT_FILE
		)
		var fingerprint := _file_fingerprint(project_path)
		var cached_entry_value: Variant = cached_entries.get(folder_project_id, {})
		var cached_entry: Dictionary = {}
		if cached_entry_value is Dictionary:
			cached_entry = cached_entry_value
		var row: Dictionary = {}
		var cached_row_value: Variant = cached_entry.get("row", {})
		if (
			not force_rebuild
			and str(cached_entry.get("fingerprint", "")) == fingerprint
			and cached_row_value is Dictionary
		):
			var cached_row: Dictionary = cached_row_value
			row = cached_row.duplicate(true)
			reused_count += 1
		else:
			var loaded := CCFStorageService.load_project(folder_project_id)
			if not loaded.get("ok", false):
				skipped_count += 1
				continue
			var project: Dictionary = loaded.get("data", {})
			row = CCFStorageService.project_library_row(project, folder_project_id)
			refreshed_count += 1
		row["thumbnail_path"] = _ensure_thumbnail(row, force_rebuild)
		var cached_base_row: Dictionary = row.duplicate(true)
		cached_base_row.erase("series_name")
		cached_base_row.erase("series_missing")
		_decorate_series(row)
		rows.append(row)
		next_entries[folder_project_id] = {
			"fingerprint": fingerprint,
			"row": cached_base_row
		}

	var index_data := {
		"format_version": INDEX_FORMAT_VERSION,
		"generated_at": Time.get_datetime_string_from_system(true),
		"entries": next_entries
	}
	_write_json(INDEX_FILE, index_data)
	_remove_stale_thumbnails(next_entries.keys())
	return {
		"ok": true,
		"rows": rows,
		"reused": reused_count,
		"refreshed": refreshed_count,
		"skipped": skipped_count
	}


static func load_view_state() -> Dictionary:
	var defaults := {
		"format_version": VIEW_STATE_FORMAT_VERSION,
		"view_mode": "grid",
		"sort_mode": "updated_desc",
		"favorites_only": false,
		"folder_filter": "",
		"collection_filter": "",
		"tag_filter": "",
		"series_filter": ""
	}
	var loaded := _read_json(VIEW_STATE_FILE)
	if not loaded.get("ok", false):
		return defaults
	var data: Dictionary = loaded.get("data", {})
	for key in defaults:
		if data.has(key):
			defaults[key] = data.get(key)
	defaults["format_version"] = VIEW_STATE_FORMAT_VERSION
	return defaults


static func save_view_state(state: Dictionary) -> Dictionary:
	var clean_state := state.duplicate(true)
	clean_state["format_version"] = VIEW_STATE_FORMAT_VERSION
	return _write_json(VIEW_STATE_FILE, clean_state)


static func set_project_favorite(project_ids: Array[String], favorite: bool) -> Dictionary:
	return _update_projects(
		project_ids,
		func(project: Dictionary) -> void:
			var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
			metadata["favorite"] = favorite
			project["metadata"] = metadata
	)


static func set_project_folder(project_ids: Array[String], folder_name: String) -> Dictionary:
	var clean_folder := folder_name.strip_edges()
	return _update_projects(
		project_ids,
		func(project: Dictionary) -> void:
			var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
			var library_data := _normalised_library_metadata(metadata.get("library", {}))
			library_data["folder"] = clean_folder
			metadata["library"] = library_data
			project["metadata"] = metadata
	)


static func add_project_collection(project_ids: Array[String], collection_name: String) -> Dictionary:
	var clean_collection := collection_name.strip_edges()
	if clean_collection.is_empty():
		return {"ok": false, "error": "Enter a collection name."}
	return _update_projects(
		project_ids,
		func(project: Dictionary) -> void:
			var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
			var library_data := _normalised_library_metadata(metadata.get("library", {}))
			var collections: Array[String] = _string_array(library_data.get("collections", []))
			_append_unique_case_insensitive(collections, clean_collection)
			collections.sort_custom(
				func(first: String, second: String) -> bool:
					return first.naturalnocasecmp_to(second) < 0
			)
			library_data["collections"] = collections
			metadata["library"] = library_data
			project["metadata"] = metadata
	)


static func remove_project_collection(project_ids: Array[String], collection_name: String) -> Dictionary:
	var clean_collection := collection_name.strip_edges()
	return _update_projects(
		project_ids,
		func(project: Dictionary) -> void:
			var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
			var library_data := _normalised_library_metadata(metadata.get("library", {}))
			var collections: Array[String] = _string_array(library_data.get("collections", []))
			collections = _without_value_case_insensitive(collections, clean_collection)
			library_data["collections"] = collections
			metadata["library"] = library_data
			project["metadata"] = metadata
	)


static func bulk_add_tags(
	project_ids: Array[String], tags: Array[String], include_characters: bool = false
) -> Dictionary:
	var clean_tags := _clean_tags(tags)
	if clean_tags.is_empty():
		return {"ok": false, "error": "Enter at least one tag."}
	return _update_projects(
		project_ids,
		func(project: Dictionary) -> void:
			var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
			var project_tags: Array[String] = _string_array(metadata.get("tags", []))
			for tag_text in clean_tags:
				_append_unique_case_insensitive(project_tags, tag_text)
			project_tags.sort_custom(
				func(first: String, second: String) -> bool:
					return first.naturalnocasecmp_to(second) < 0
			)
			metadata["tags"] = project_tags
			project["metadata"] = metadata
			if include_characters:
				var characters: Array = project.get("characters", [])
				for character_index in range(characters.size()):
					if not characters[character_index] is Dictionary:
						continue
					var character: Dictionary = characters[character_index]
					var character_metadata: Dictionary = character.get("metadata", {}).duplicate(true)
					var character_tags: Array[String] = _string_array(character_metadata.get("tags", []))
					for tag_text in clean_tags:
						_append_unique_case_insensitive(character_tags, tag_text)
					character_tags.sort_custom(
						func(first: String, second: String) -> bool:
							return first.naturalnocasecmp_to(second) < 0
					)
					character_metadata["tags"] = character_tags
					character["metadata"] = character_metadata
					characters[character_index] = character
				project["characters"] = characters
	)


static func set_project_series(project_ids: Array[String], series_id: String) -> Dictionary:
	var result := CCFSeriesService.assign_saved_projects(project_ids, series_id)
	invalidate_index()
	return result


static func merge_tag(old_tag: String, replacement_tag: String) -> Dictionary:
	var source_tag := old_tag.strip_edges()
	var target_tag := replacement_tag.strip_edges()
	if source_tag.is_empty() or target_tag.is_empty():
		return {"ok": false, "error": "Enter both the old tag and replacement tag."}
	var project_ids: Array[String] = []
	for folder_project_id in DirAccess.get_directories_at(CCFStorageService.CHARACTERS_DIR):
		project_ids.append(folder_project_id)
	var touched_projects := 0
	var touched_values := 0
	var failures: Array[String] = []
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not loaded.get("ok", false):
			failures.append(project_id)
			continue
		var project: Dictionary = loaded.get("data", {})
		var project_changed := false
		var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
		var result := _replace_tag_in_array(metadata.get("tags", []), source_tag, target_tag)
		if bool(result.get("changed", false)):
			metadata["tags"] = result.get("tags", [])
			project["metadata"] = metadata
			project_changed = true
			touched_values += int(result.get("replacements", 0))
		var characters: Array = project.get("characters", [])
		for character_index in range(characters.size()):
			if not characters[character_index] is Dictionary:
				continue
			var character: Dictionary = characters[character_index]
			var character_metadata: Dictionary = character.get("metadata", {}).duplicate(true)
			var character_result := _replace_tag_in_array(
				character_metadata.get("tags", []), source_tag, target_tag
			)
			if bool(character_result.get("changed", false)):
				character_metadata["tags"] = character_result.get("tags", [])
				character["metadata"] = character_metadata
				characters[character_index] = character
				project_changed = true
				touched_values += int(character_result.get("replacements", 0))
		if not project_changed:
			continue
		project["characters"] = characters
		var saved := CCFStorageService.save_project(project)
		if saved.get("ok", false):
			touched_projects += 1
		else:
			failures.append(project_id)
	invalidate_index()
	return {
		"ok": failures.is_empty(),
		"projects": touched_projects,
		"replacements": touched_values,
		"failures": failures,
		"error": "Some projects could not be updated." if not failures.is_empty() else ""
	}


static func delete_projects(project_ids: Array[String]) -> Dictionary:
	var deleted_count := 0
	var failures: Array[String] = []
	for project_id in project_ids:
		var result := CCFStorageService.delete_project(project_id)
		if result.get("ok", false):
			deleted_count += 1
		else:
			failures.append(project_id)
	invalidate_index()
	return {
		"ok": failures.is_empty(),
		"deleted": deleted_count,
		"failures": failures,
		"error": "Some projects could not be deleted." if not failures.is_empty() else ""
	}


static func _decorate_series(row: Dictionary) -> void:
	var series_id := str(row.get("series_id", "")).strip_edges()
	row["series_name"] = ""
	row["series_missing"] = false
	if series_id.is_empty():
		return
	var series := CCFSeriesService.series_by_id(series_id)
	if series.is_empty():
		row["series_name"] = "Missing series"
		row["series_missing"] = true
		return
	var series_name := str(series.get("name", "Untitled Series"))
	row["series_name"] = series_name
	row["search_text"] = "%s\n%s" % [str(row.get("search_text", "")), series_name.to_lower()]


static func invalidate_index() -> void:
	var absolute_path := ProjectSettings.globalize_path(INDEX_FILE)
	if FileAccess.file_exists(INDEX_FILE):
		DirAccess.remove_absolute(absolute_path)


static func facet_values(rows: Array[Dictionary]) -> Dictionary:
	var folder_map: Dictionary = {}
	var collection_map: Dictionary = {}
	var tag_map: Dictionary = {}
	for row in rows:
		var folder_name := str(row.get("folder", "")).strip_edges()
		if not folder_name.is_empty():
			folder_map[folder_name.to_lower()] = folder_name
		for collection_name in _string_array(row.get("collections", [])):
			collection_map[collection_name.to_lower()] = collection_name
		for tag_text in _string_array(row.get("all_tags", [])):
			tag_map[tag_text.to_lower()] = tag_text
	return {
		"folders": _sorted_dictionary_values(folder_map),
		"collections": _sorted_dictionary_values(collection_map),
		"tags": _sorted_dictionary_values(tag_map)
	}


static func _update_projects(project_ids: Array[String], mutator: Callable) -> Dictionary:
	if project_ids.is_empty():
		return {"ok": false, "error": "Select at least one project."}
	var updated_count := 0
	var failures: Array[String] = []
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not loaded.get("ok", false):
			failures.append(project_id)
			continue
		var project: Dictionary = loaded.get("data", {})
		mutator.call(project)
		var saved := CCFStorageService.save_project(project)
		if saved.get("ok", false):
			updated_count += 1
		else:
			failures.append(project_id)
	invalidate_index()
	return {
		"ok": failures.is_empty(),
		"updated": updated_count,
		"failures": failures,
		"error": "Some projects could not be updated." if not failures.is_empty() else ""
	}


static func _clear_thumbnail_cache() -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(THUMBNAIL_DIR)):
		return
	for file_name in DirAccess.get_files_at(THUMBNAIL_DIR):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(THUMBNAIL_DIR.path_join(file_name)))


static func _remove_stale_thumbnails(raw_project_ids: Array) -> void:
	var valid_names: Dictionary = {}
	for raw_project_id in raw_project_ids:
		valid_names["%s.png" % str(raw_project_id)] = true
	for file_name in DirAccess.get_files_at(THUMBNAIL_DIR):
		if file_name.get_extension().to_lower() != "png":
			continue
		if not valid_names.has(file_name):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(THUMBNAIL_DIR.path_join(file_name)))


static func _ensure_thumbnail(row: Dictionary, force_rebuild: bool) -> String:
	var project_id := str(row.get("project_id", "")).strip_edges()
	var source_path := str(row.get("portrait_source_path", "")).strip_edges()
	if project_id.is_empty() or source_path.is_empty():
		return ""
	if not FileAccess.file_exists(source_path):
		return ""
	var cache_path := THUMBNAIL_DIR.path_join("%s.png" % project_id)
	if not force_rebuild and FileAccess.file_exists(cache_path):
		var source_time := FileAccess.get_modified_time(source_path)
		var cache_time := FileAccess.get_modified_time(cache_path)
		if cache_time >= source_time:
			return cache_path
	var image := Image.new()
	var load_error := image.load(ProjectSettings.globalize_path(source_path))
	if load_error != OK or image.is_empty():
		return ""
	var image_width := image.get_width()
	var image_height := image.get_height()
	if image_width <= 0 or image_height <= 0:
		return ""
	var width_scale := float(THUMBNAIL_WIDTH) / float(image_width)
	var height_scale := float(THUMBNAIL_HEIGHT) / float(image_height)
	var scale_factor := minf(width_scale, height_scale)
	if scale_factor > 1.0:
		scale_factor = 1.0
	var target_width := maxi(1, int(round(float(image_width) * scale_factor)))
	var target_height := maxi(1, int(round(float(image_height) * scale_factor)))
	if target_width != image_width or target_height != image_height:
		image.resize(target_width, target_height, Image.INTERPOLATE_LANCZOS)
	var save_error := image.save_png(ProjectSettings.globalize_path(cache_path))
	return cache_path if save_error == OK else ""


static func _file_fingerprint(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		return "missing"
	return "%d:%d" % [
		FileAccess.get_modified_time(file_path),
		FileAccess.get_size(file_path)
	]


static func _normalised_library_metadata(raw_value: Variant) -> Dictionary:
	var result := {"folder": "", "collections": []}
	if raw_value is Dictionary:
		result["folder"] = str(raw_value.get("folder", "")).strip_edges()
		result["collections"] = _string_array(raw_value.get("collections", []))
	return result


static func _replace_tag_in_array(raw_tags: Variant, old_tag: String, replacement_tag: String) -> Dictionary:
	var tags := _string_array(raw_tags)
	var output: Array[String] = []
	var replacements := 0
	for tag_text in tags:
		if tag_text.nocasecmp_to(old_tag) == 0:
			_append_unique_case_insensitive(output, replacement_tag)
			replacements += 1
		else:
			_append_unique_case_insensitive(output, tag_text)
	output.sort_custom(
		func(first: String, second: String) -> bool:
			return first.naturalnocasecmp_to(second) < 0
	)
	return {
		"changed": replacements > 0,
		"tags": output,
		"replacements": replacements
	}


static func _clean_tags(tags: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for raw_tag in tags:
		var tag_text := raw_tag.strip_edges()
		if not tag_text.is_empty():
			_append_unique_case_insensitive(result, tag_text)
	return result


static func _string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_value is Array:
		for item in raw_value:
			var text := str(item).strip_edges()
			if not text.is_empty():
				_append_unique_case_insensitive(result, text)
	return result


static func _append_unique_case_insensitive(values: Array[String], candidate: String) -> void:
	for existing in values:
		if existing.nocasecmp_to(candidate) == 0:
			return
	values.append(candidate)


static func _without_value_case_insensitive(
	values: Array[String], removed_value: String
) -> Array[String]:
	var result: Array[String] = []
	for existing in values:
		if existing.nocasecmp_to(removed_value) != 0:
			result.append(existing)
	return result


static func _sorted_dictionary_values(value_map: Dictionary) -> Array[String]:
	var values: Array[String] = []
	for value in value_map.values():
		values.append(str(value))
	values.sort_custom(
		func(first: String, second: String) -> bool:
			return first.naturalnocasecmp_to(second) < 0
	)
	return values


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "File does not exist."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open file."}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		return {"ok": false, "error": "File does not contain a valid JSON object."}
	return {"ok": true, "data": parser.data}


static func _write_json(path: String, data: Dictionary) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not write file."}
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return {"ok": true, "path": path}
