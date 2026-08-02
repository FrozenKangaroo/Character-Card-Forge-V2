class_name CCFSeriesService
extends RefCounted

const FORMAT_VERSION := 1
const PACKAGE_FORMAT_VERSION := 1
const PACKAGE_TYPE := "character_card_forge_series_pack"
const SERIES_DIR := CCFStorageService.SERIES_DIR
const PACKAGE_EXTENSION := "ccfseries"
const MANIFEST_ENTRY := "manifest.json"


static func ensure_directories() -> void:
	CCFStorageService.ensure_directories()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SERIES_DIR))


static func new_series(series_name: String = "Untitled Series") -> Dictionary:
	var now := Time.get_datetime_string_from_system(true)
	var clean_name := series_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Untitled Series"
	return {
		"format_version": FORMAT_VERSION,
		"series_id": _new_uuid(),
		"created_at": now,
		"updated_at": now,
		"name": clean_name,
		"aliases": [],
		"description": "",
		"categories": [],
		"setting_guidance": "",
		"canon_notes": "",
		"visual_direction": "",
		"generation_rules": "",
		"default_tags": [],
		"matching_keywords": []
	}


static func normalise_series(raw_series: Dictionary) -> Dictionary:
	var defaults := new_series()
	var result := defaults.duplicate(true)
	for key in defaults:
		if raw_series.has(key):
			var value: Variant = raw_series.get(key)
			if value is Array or value is Dictionary:
				result[key] = value.duplicate(true)
			else:
				result[key] = value
	for key in raw_series:
		if not result.has(key):
			var custom_value: Variant = raw_series.get(key)
			if custom_value is Array or custom_value is Dictionary:
				result[key] = custom_value.duplicate(true)
			else:
				result[key] = custom_value
	result["format_version"] = FORMAT_VERSION
	result["series_id"] = str(result.get("series_id", "")).strip_edges()
	if str(result.get("series_id", "")).is_empty():
		result["series_id"] = _new_uuid()
	var clean_name := str(result.get("name", "")).strip_edges()
	result["name"] = clean_name if not clean_name.is_empty() else "Untitled Series"
	for array_key in ["aliases", "categories", "default_tags", "matching_keywords"]:
		result[array_key] = _normalise_string_array(result.get(array_key, []))
	for text_key in [
		"description",
		"setting_guidance",
		"canon_notes",
		"visual_direction",
		"generation_rules"
	]:
		result[text_key] = str(result.get(text_key, ""))
	result["created_at"] = str(result.get("created_at", Time.get_datetime_string_from_system(true)))
	result["updated_at"] = str(result.get("updated_at", result.get("created_at", "")))
	return result


static func save_series(series: Dictionary) -> Dictionary:
	ensure_directories()
	var clean_series: Dictionary = normalise_series(series)
	clean_series["updated_at"] = Time.get_datetime_string_from_system(true)
	var series_id := str(clean_series.get("series_id", ""))
	var result := _write_json(series_path(series_id), clean_series)
	if result.get("ok", false):
		series.clear()
		series.merge(clean_series, true)
		result["series"] = clean_series.duplicate(true)
		result["series_id"] = series_id
	return result


static func load_series(series_id: String) -> Dictionary:
	var clean_id := series_id.strip_edges()
	if clean_id.is_empty():
		return {"ok": false, "error": "No series ID was supplied."}
	var result := _read_json(series_path(clean_id))
	if not result.get("ok", false):
		return result
	var raw_data: Variant = result.get("data", {})
	if not raw_data is Dictionary:
		return {"ok": false, "error": "Series data is not a JSON object."}
	return {"ok": true, "data": normalise_series(raw_data)}


static func list_series() -> Array[Dictionary]:
	ensure_directories()
	var result: Array[Dictionary] = []
	for file_name in DirAccess.get_files_at(SERIES_DIR):
		if not file_name.to_lower().ends_with(".json"):
			continue
		var series_id := file_name.trim_suffix(".json")
		var loaded := load_series(series_id)
		if loaded.get("ok", false):
			var series_value: Variant = loaded.get("data", {})
			if series_value is Dictionary:
				result.append(series_value)
	result.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return str(first.get("name", "")).naturalnocasecmp_to(str(second.get("name", ""))) < 0
	)
	return result


static func series_by_id(series_id: String) -> Dictionary:
	var loaded := load_series(series_id)
	if not loaded.get("ok", false):
		return {}
	var series_value: Variant = loaded.get("data", {})
	if series_value is Dictionary:
		return series_value
	return {}


static func delete_series(series_id: String) -> Dictionary:
	var path := ProjectSettings.globalize_path(series_path(series_id))
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Series file does not exist."}
	var error := DirAccess.remove_absolute(path)
	if error != OK:
		return {"ok": false, "error": "Could not delete the series file (error %s)." % error}
	return {"ok": true, "series_id": series_id}


static func duplicate_series(series_id: String) -> Dictionary:
	var loaded := load_series(series_id)
	if not loaded.get("ok", false):
		return loaded
	var duplicate: Dictionary = loaded.get("data", {}).duplicate(true)
	var now := Time.get_datetime_string_from_system(true)
	duplicate["series_id"] = _new_uuid()
	duplicate["name"] = "%s Copy" % str(duplicate.get("name", "Series"))
	duplicate["created_at"] = now
	duplicate["updated_at"] = now
	return save_series(duplicate)


static func series_path(series_id: String) -> String:
	return SERIES_DIR.path_join(_safe_id(series_id) + ".json")


static func series_id_for_project(project: Dictionary) -> String:
	var metadata_value: Variant = project.get("metadata", project.get("project_metadata", {}))
	if metadata_value is Dictionary:
		return str(metadata_value.get("series_id", "")).strip_edges()
	return ""


static func series_for_project(project: Dictionary) -> Dictionary:
	var series_id := series_id_for_project(project)
	if series_id.is_empty():
		return {}
	return series_by_id(series_id)


static func generation_context_for_project(project: Dictionary) -> String:
	var series_id := series_id_for_project(project)
	if series_id.is_empty():
		return ""
	var series := series_by_id(series_id)
	if series.is_empty():
		return "Assigned series ID: %s (the local series definition is currently missing)." % series_id
	var lines: Array[String] = ["SERIES: %s" % str(series.get("name", "Untitled Series"))]
	var aliases := _normalise_string_array(series.get("aliases", []))
	if not aliases.is_empty():
		lines.append("Aliases: %s" % _join(aliases, ", "))
	var categories := _normalise_string_array(series.get("categories", []))
	if not categories.is_empty():
		lines.append("Categories: %s" % _join(categories, ", "))
	for field in [
		["description", "Description"],
		["setting_guidance", "Setting guidance"],
		["canon_notes", "Canon notes"],
		["visual_direction", "Visual direction"],
		["generation_rules", "Generation rules"]
	]:
		var field_id := str(field[0])
		var value := str(series.get(field_id, "")).strip_edges()
		if not value.is_empty():
			lines.append("%s: %s" % [str(field[1]), value])
	var default_tags := _normalise_string_array(series.get("default_tags", []))
	if not default_tags.is_empty():
		lines.append("Default tags: %s" % _join(default_tags, ", "))
	return _join(lines, "\n")


static func assign_project(project: Dictionary, series_id: String) -> Dictionary:
	var clean_id := series_id.strip_edges()
	if not clean_id.is_empty() and series_by_id(clean_id).is_empty():
		return {"ok": false, "error": "The selected series no longer exists."}
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["series_id"] = clean_id
	project["metadata"] = metadata
	return {"ok": true, "series_id": clean_id}


static func assign_saved_projects(project_ids: Array[String], series_id: String) -> Dictionary:
	if project_ids.is_empty():
		return {"ok": false, "error": "Select at least one project."}
	var updated := 0
	var failures: Array[String] = []
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not loaded.get("ok", false):
			failures.append(project_id)
			continue
		var project: Dictionary = loaded.get("data", {})
		var assign_result := assign_project(project, series_id)
		if not assign_result.get("ok", false):
			return assign_result
		var save_result := CCFStorageService.save_project(project)
		if save_result.get("ok", false):
			updated += 1
		else:
			failures.append(project_id)
	return {"ok": failures.is_empty(), "updated": updated, "failures": failures}


static func apply_default_tags(project: Dictionary) -> Dictionary:
	var series := series_for_project(project)
	if series.is_empty():
		return {"ok": false, "error": "This project does not have a valid assigned series."}
	var default_tags := _normalise_string_array(series.get("default_tags", []))
	if default_tags.is_empty():
		return {"ok": false, "error": "The assigned series has no default tags."}
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	var tags := _normalise_string_array(metadata.get("tags", []))
	var added := 0
	for tag_text in default_tags:
		if _append_unique_case_insensitive(tags, tag_text):
			added += 1
	metadata["tags"] = tags
	project["metadata"] = metadata
	return {"ok": true, "added": added}


static func match_project(project: Dictionary) -> Dictionary:
	var haystack := _project_match_text(project)
	var project_tags := _project_tags(project)
	var candidates: Array[Dictionary] = []
	for series in list_series():
		var score := 0
		var reasons: Array[String] = []
		var name := str(series.get("name", "")).strip_edges()
		if not name.is_empty() and haystack.contains(name.to_lower()):
			score += 8
			reasons.append("series name")
		for alias in _normalise_string_array(series.get("aliases", [])):
			if haystack.contains(alias.to_lower()):
				score += 6
				reasons.append("alias: %s" % alias)
		for keyword in _normalise_string_array(series.get("matching_keywords", [])):
			if haystack.contains(keyword.to_lower()):
				score += 3
				reasons.append("keyword: %s" % keyword)
		for tag_text in _normalise_string_array(series.get("default_tags", [])):
			if _array_contains_case_insensitive(project_tags, tag_text):
				score += 2
				reasons.append("tag: %s" % tag_text)
		for category in _normalise_string_array(series.get("categories", [])):
			if haystack.contains(category.to_lower()):
				score += 1
		if score > 0:
			candidates.append(
				{
					"series_id": str(series.get("series_id", "")),
					"name": name,
					"score": score,
					"reasons": reasons
				}
			)
	candidates.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			var first_score := int(first.get("score", 0))
			var second_score := int(second.get("score", 0))
			if first_score == second_score:
				return str(first.get("name", "")).naturalnocasecmp_to(str(second.get("name", ""))) < 0
			return first_score > second_score
	)
	var best: Dictionary = {}
	if not candidates.is_empty():
		best = candidates[0]
	var confident: bool = not best.is_empty() and int(best.get("score", 0)) >= 3
	if candidates.size() > 1 and int(candidates[0].get("score", 0)) == int(candidates[1].get("score", 0)):
		confident = false
	return {"ok": true, "best": best, "candidates": candidates, "confident": confident}


static func auto_assign_unassigned_projects() -> Dictionary:
	var assigned := 0
	var ambiguous := 0
	var unmatched := 0
	var failures: Array[String] = []
	for project_id in DirAccess.get_directories_at(CCFStorageService.CHARACTERS_DIR):
		var loaded := CCFStorageService.load_project(project_id)
		if not loaded.get("ok", false):
			failures.append(project_id)
			continue
		var project: Dictionary = loaded.get("data", {})
		if not series_id_for_project(project).is_empty():
			continue
		var match_result := match_project(project)
		if not bool(match_result.get("confident", false)):
			var candidates_value: Variant = match_result.get("candidates", [])
			if candidates_value is Array and not candidates_value.is_empty():
				ambiguous += 1
			else:
				unmatched += 1
			continue
		var best: Dictionary = match_result.get("best", {})
		assign_project(project, str(best.get("series_id", "")))
		var save_result := CCFStorageService.save_project(project)
		if save_result.get("ok", false):
			assigned += 1
		else:
			failures.append(project_id)
	return {
		"ok": failures.is_empty(),
		"assigned": assigned,
		"ambiguous": ambiguous,
		"unmatched": unmatched,
		"failures": failures
	}


static func usage_counts() -> Dictionary:
	var counts: Dictionary = {}
	for project_id in DirAccess.get_directories_at(CCFStorageService.CHARACTERS_DIR):
		var loaded := CCFStorageService.load_project(project_id)
		if not loaded.get("ok", false):
			continue
		var series_id := series_id_for_project(loaded.get("data", {}))
		if not series_id.is_empty():
			counts[series_id] = int(counts.get(series_id, 0)) + 1
	return counts


static func export_json(series_id: String, destination_path: String) -> Dictionary:
	var loaded := load_series(series_id)
	if not loaded.get("ok", false):
		return loaded
	return _write_json(destination_path, loaded.get("data", {}))


static func import_json(source_path: String) -> Dictionary:
	var loaded := _read_json(source_path)
	if not loaded.get("ok", false):
		return loaded
	var raw_data: Variant = loaded.get("data", {})
	if not raw_data is Dictionary:
		return {"ok": false, "error": "Imported series JSON must contain one object."}
	var series := normalise_series(raw_data)
	var existing := series_by_id(str(series.get("series_id", "")))
	if not existing.is_empty() and existing != series:
		series["series_id"] = _new_uuid()
		series["name"] = "%s (Imported)" % str(series.get("name", "Series"))
	return save_series(series)


static func export_pack(series_ids: Array[String], destination_path: String) -> Dictionary:
	if series_ids.is_empty():
		return {"ok": false, "error": "Select at least one series to export."}
	var included: Array[Dictionary] = []
	for series_id in series_ids:
		var series := series_by_id(series_id)
		if not series.is_empty():
			included.append(series)
	if included.is_empty():
		return {"ok": false, "error": "None of the selected series could be loaded."}
	var writer := ZIPPacker.new()
	var open_error := writer.open(destination_path)
	if open_error != OK:
		return {"ok": false, "error": "Could not create the Series Pack (error %s)." % open_error}
	var manifest_series: Array[Dictionary] = []
	var manifest: Dictionary = {
		"package_type": PACKAGE_TYPE,
		"package_format_version": PACKAGE_FORMAT_VERSION,
		"created_at": Time.get_datetime_string_from_system(true),
		"application": "Character Card Forge",
		"application_version": "0.15.9",
		"series_format_version": FORMAT_VERSION,
		"series_count": included.size(),
		"series": manifest_series
	}
	for series in included:
		var series_id := str(series.get("series_id", ""))
		manifest_series.append(
			{
				"series_id": series_id,
				"name": str(series.get("name", "Untitled Series")),
				"file": "series/%s.json" % series_id
			}
		)
		var entry_error := writer.start_file("series/%s.json" % series_id)
		if entry_error != OK:
			writer.close()
			return {"ok": false, "error": "Could not write a series entry into the pack."}
		var write_error := writer.write_file(JSON.stringify(series, "  ").to_utf8_buffer())
		writer.close_file()
		if write_error != OK:
			writer.close()
			return {"ok": false, "error": "Could not write series data into the pack."}
	var manifest_error := writer.start_file(MANIFEST_ENTRY)
	if manifest_error != OK:
		writer.close()
		return {"ok": false, "error": "Could not write the Series Pack manifest."}
	var manifest_write_error := writer.write_file(JSON.stringify(manifest, "  ").to_utf8_buffer())
	writer.close_file()
	writer.close()
	if manifest_write_error != OK:
		return {"ok": false, "error": "Could not write the Series Pack manifest data."}
	return {"ok": true, "path": destination_path, "manifest": manifest}


static func import_pack(source_path: String) -> Dictionary:
	var reader := ZIPReader.new()
	var open_error := reader.open(source_path)
	if open_error != OK:
		return {"ok": false, "error": "Could not open the Series Pack (error %s)." % open_error}
	if not reader.file_exists(MANIFEST_ENTRY):
		reader.close()
		return {"ok": false, "error": "The archive does not contain a Series Pack manifest."}
	var parsed_manifest: Variant = JSON.parse_string(
		reader.read_file(MANIFEST_ENTRY).get_string_from_utf8()
	)
	if not parsed_manifest is Dictionary:
		reader.close()
		return {"ok": false, "error": "The Series Pack manifest is invalid."}
	var manifest: Dictionary = parsed_manifest
	if str(manifest.get("package_type", "")) != PACKAGE_TYPE:
		reader.close()
		return {"ok": false, "error": "The selected archive is not a Character Card Forge Series Pack."}
	if int(manifest.get("package_format_version", 0)) > PACKAGE_FORMAT_VERSION:
		reader.close()
		return {"ok": false, "error": "This Series Pack uses a newer unsupported format."}
	var imported := 0
	var remapped: Dictionary = {}
	for entry_path in reader.get_files():
		var entry := str(entry_path)
		if not entry.begins_with("series/") or not entry.to_lower().ends_with(".json"):
			continue
		var parsed_series: Variant = JSON.parse_string(reader.read_file(entry).get_string_from_utf8())
		if not parsed_series is Dictionary:
			continue
		var series := normalise_series(parsed_series)
		var old_id := str(series.get("series_id", ""))
		var existing := series_by_id(old_id)
		var remapped_id := ""
		if not existing.is_empty() and existing != series:
			remapped_id = _new_uuid()
			series["series_id"] = remapped_id
			series["name"] = "%s (Imported)" % str(series.get("name", "Series"))
		var save_result := save_series(series)
		if save_result.get("ok", false):
			imported += 1
			if not remapped_id.is_empty():
				remapped[old_id] = remapped_id
	reader.close()
	return {"ok": true, "imported": imported, "remapped": remapped, "manifest": manifest}


static func suggested_pack_filename(series_ids: Array[String]) -> String:
	if series_ids.size() == 1:
		var series := series_by_id(series_ids[0])
		if not series.is_empty():
			return "%s.%s" % [_safe_filename(str(series.get("name", "series"))), PACKAGE_EXTENSION]
	return "character_card_forge_series_pack.%s" % PACKAGE_EXTENSION


static func _project_match_text(project: Dictionary) -> String:
	var row := CCFStorageService.project_library_row(project, str(project.get("project_id", "")))
	return str(row.get("search_text", "")).to_lower()


static func _project_tags(project: Dictionary) -> Array[String]:
	var metadata: Dictionary = project.get("metadata", {})
	var result := _normalise_string_array(metadata.get("tags", []))
	for raw_character in project.get("characters", []):
		if not raw_character is Dictionary:
			continue
		var character_metadata: Dictionary = raw_character.get("metadata", {})
		for tag_text in _normalise_string_array(character_metadata.get("tags", [])):
			_append_unique_case_insensitive(result, tag_text)
	return result


static func _normalise_string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_value is Array:
		for raw_item in raw_value:
			var text := str(raw_item).strip_edges()
			if not text.is_empty():
				_append_unique_case_insensitive(result, text)
	elif not str(raw_value).strip_edges().is_empty():
		for raw_item in str(raw_value).replace(";", ",").split(",", false):
			var text := raw_item.strip_edges()
			if not text.is_empty():
				_append_unique_case_insensitive(result, text)
	return result


static func _append_unique_case_insensitive(values: Array[String], candidate: String) -> bool:
	for existing in values:
		if existing.nocasecmp_to(candidate) == 0:
			return false
	values.append(candidate)
	return true


static func _array_contains_case_insensitive(values: Array[String], candidate: String) -> bool:
	for value in values:
		if value.nocasecmp_to(candidate) == 0:
			return true
	return false


static func _join(values: Array[String], separator: String) -> String:
	var output := ""
	for index in range(values.size()):
		if index > 0:
			output += separator
		output += values[index]
	return output


static func _safe_id(value: String) -> String:
	var output := ""
	var allowed := "abcdefghijklmnopqrstuvwxyz0123456789_-"
	for character in value.to_lower():
		output += character if allowed.contains(character) else "_"
	return output if not output.is_empty() else "series"


static func _safe_filename(value: String) -> String:
	var output := ""
	var allowed := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
	for character in value.strip_edges():
		if allowed.contains(character):
			output += character
		elif character == " " and not output.ends_with("_"):
			output += "_"
	return output if not output.is_empty() else "series"


static func _write_json(path: String, data: Variant) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open %s for writing." % path}
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return {"ok": true, "path": path}


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "File does not exist: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open %s." % path}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null:
		return {"ok": false, "error": "Invalid JSON in %s." % path}
	return {"ok": true, "data": parsed}


static func _new_uuid() -> String:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	if bytes.size() != 16:
		return "%s-%s" % [Time.get_unix_time_from_system(), randi()]
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hexadecimal := ""
	for byte in bytes:
		hexadecimal += "%02x" % byte
	return "%s-%s-%s-%s-%s" % [
		hexadecimal.substr(0, 8),
		hexadecimal.substr(8, 4),
		hexadecimal.substr(12, 4),
		hexadecimal.substr(16, 4),
		hexadecimal.substr(20, 12)
	]
