class_name CCFProjectPackageService
extends RefCounted

const PACKAGE_TYPE := "character_card_forge_project"
const PACKAGE_FORMAT_VERSION := 1
const PROJECT_ENTRY := "project/character.json"
const MANIFEST_ENTRY := "manifest.json"
const PACKAGE_EXTENSION := "ccfproject"


static func export_project(project: Dictionary, destination_path: String) -> Dictionary:
	if project.is_empty():
		return {"ok": false, "error": "No project is available to package."}
	var project_id := str(project.get("project_id", "")).strip_edges()
	if project_id.is_empty():
		return {"ok": false, "error": "The project does not have a valid project ID."}
	var writer := ZIPPacker.new()
	var open_error := writer.open(destination_path)
	if open_error != OK:
		return {"ok": false, "error": "Could not create project package (error %s)." % open_error}

	var metadata = project.get("metadata", {})
	var project_name := "Untitled Project"
	if metadata is Dictionary:
		project_name = str(metadata.get("name", project_name))
	var template_ids := _referenced_template_ids(project)
	var series_id := CCFSeriesService.series_id_for_project(project)
	var manifest := {
		"package_type": PACKAGE_TYPE,
		"package_format_version": PACKAGE_FORMAT_VERSION,
		"created_at": Time.get_datetime_string_from_system(true),
		"application": "Character Card Forge",
		"application_version": "0.9.1",
		"project_format_version": int(project.get("format_version", 2)),
		"project_id": project_id,
		"project_name": project_name,
		"project_file": PROJECT_ENTRY,
		"character_count": project.get("characters", []).size(),
		"included_template_ids": template_ids,
		"included_series_id": series_id
	}
	var manifest_error := _write_zip_entry(writer, MANIFEST_ENTRY, JSON.stringify(manifest, "  ").to_utf8_buffer())
	if manifest_error != OK:
		writer.close()
		return {"ok": false, "error": "Could not write the package manifest."}
	var project_error := _write_zip_entry(writer, PROJECT_ENTRY, JSON.stringify(project, "  ").to_utf8_buffer())
	if project_error != OK:
		writer.close()
		return {"ok": false, "error": "Could not write the project data into the package."}
	for template_id in template_ids:
		var template := CCFTemplateService.load_template(template_id)
		var template_error := _write_zip_entry(
			writer,
			"templates/%s.json" % template_id,
			JSON.stringify(template, "  ").to_utf8_buffer()
		)
		if template_error != OK:
			writer.close()
			return {"ok": false, "error": "Could not add referenced template '%s' to the package." % template_id}

	if not series_id.is_empty():
		var series := CCFSeriesService.series_by_id(series_id)
		if not series.is_empty():
			var series_error := _write_zip_entry(
				writer,
				"series/%s.json" % series_id,
				JSON.stringify(series, "  ").to_utf8_buffer()
			)
			if series_error != OK:
				writer.close()
				return {"ok": false, "error": "Could not add the referenced series to the package."}

	var source_root := ProjectSettings.globalize_path(CCFStorageService.project_folder(project_id))
	if DirAccess.dir_exists_absolute(source_root):
		var asset_error := _add_directory_contents(writer, source_root, "project", true)
		if asset_error != OK:
			writer.close()
			return {"ok": false, "error": "Could not add one or more project assets to the package (error %s)." % asset_error}
	writer.close()
	return {"ok": true, "path": destination_path, "manifest": manifest}


static func import_project(source_path: String) -> Dictionary:
	var reader := ZIPReader.new()
	var open_error := reader.open(source_path)
	if open_error != OK:
		return {"ok": false, "error": "Could not open the project package (error %s)." % open_error}
	if not reader.file_exists(MANIFEST_ENTRY):
		reader.close()
		return {"ok": false, "error": "This archive does not contain a Character Card Forge package manifest."}
	if not reader.file_exists(PROJECT_ENTRY):
		reader.close()
		return {"ok": false, "error": "This package is missing project/character.json."}

	var manifest_text := reader.read_file(MANIFEST_ENTRY).get_string_from_utf8()
	var parsed_manifest = JSON.parse_string(manifest_text)
	if not parsed_manifest is Dictionary:
		reader.close()
		return {"ok": false, "error": "The package manifest is invalid JSON."}
	var manifest: Dictionary = parsed_manifest
	if str(manifest.get("package_type", "")) != PACKAGE_TYPE:
		reader.close()
		return {"ok": false, "error": "The selected archive is not a Character Card Forge project package."}
	if int(manifest.get("package_format_version", 0)) > PACKAGE_FORMAT_VERSION:
		reader.close()
		return {"ok": false, "error": "This project package was created with a newer unsupported package format."}

	var project_text := reader.read_file(PROJECT_ENTRY).get_string_from_utf8()
	var parsed_project = JSON.parse_string(project_text)
	if not parsed_project is Dictionary:
		reader.close()
		return {"ok": false, "error": "The packaged project data is invalid JSON."}
	var project: Dictionary = parsed_project.duplicate(true)
	var template_remap := _import_packaged_templates(reader)
	if not template_remap.is_empty():
		_remap_project_templates(project, template_remap)
	var series_remap := _import_packaged_series(reader)
	if not series_remap.is_empty():
		var project_metadata: Dictionary = project.get("metadata", {}).duplicate(true)
		var old_series_id := str(project_metadata.get("series_id", ""))
		if series_remap.has(old_series_id):
			project_metadata["series_id"] = str(series_remap.get(old_series_id))
			project["metadata"] = project_metadata
	var fresh_project := CCFStorageService.new_project()
	var new_project_id := str(fresh_project.get("project_id", ""))
	project["project_id"] = new_project_id
	project["created_at"] = Time.get_datetime_string_from_system(true)
	project["updated_at"] = project["created_at"]
	var save_result := CCFStorageService.save_project(project)
	if not save_result.get("ok", false):
		reader.close()
		return save_result

	var destination_root := ProjectSettings.globalize_path(CCFStorageService.project_folder(new_project_id))
	for entry_path in reader.get_files():
		var entry := str(entry_path)
		if entry == PROJECT_ENTRY or entry == MANIFEST_ENTRY or entry.ends_with("/"):
			continue
		if not entry.begins_with("project/"):
			continue
		var relative_path := entry.trim_prefix("project/")
		if not _is_safe_relative_path(relative_path):
			continue
		var destination := destination_root.path_join(relative_path)
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		var output := FileAccess.open(destination, FileAccess.WRITE)
		if output == null:
			reader.close()
			return {"ok": false, "error": "Could not extract package asset: %s" % relative_path}
		output.store_buffer(reader.read_file(entry))
		output.close()
	reader.close()
	var loaded := CCFStorageService.load_project(new_project_id)
	if not loaded.get("ok", false):
		return loaded
	return {
		"ok": true,
		"project": loaded.get("data", {}),
		"manifest": manifest,
		"project_id": new_project_id,
		"template_remap": template_remap,
		"series_remap": series_remap
	}


static func inspect_package(source_path: String) -> Dictionary:
	var reader := ZIPReader.new()
	var open_error := reader.open(source_path)
	if open_error != OK:
		return {"ok": false, "error": "Could not open the project package."}
	if not reader.file_exists(MANIFEST_ENTRY):
		reader.close()
		return {"ok": false, "error": "Package manifest missing."}
	var parsed = JSON.parse_string(reader.read_file(MANIFEST_ENTRY).get_string_from_utf8())
	var file_count := reader.get_files().size()
	reader.close()
	if not parsed is Dictionary:
		return {"ok": false, "error": "Package manifest is invalid."}
	return {"ok": true, "manifest": parsed, "file_count": file_count}


static func suggested_filename(project: Dictionary) -> String:
	var metadata = project.get("metadata", {})
	var project_name := "Untitled Project"
	if metadata is Dictionary:
		project_name = str(metadata.get("name", project_name))
	return "%s.%s" % [_safe_filename(project_name), PACKAGE_EXTENSION]


static func _referenced_template_ids(project: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for raw_character in project.get("characters", []):
		if not raw_character is Dictionary:
			continue
		var generation = raw_character.get("generation", {})
		if not generation is Dictionary:
			continue
		var template_id := str(generation.get("template_id", "default")).strip_edges()
		if template_id.is_empty() or template_id == "default" or result.has(template_id):
			continue
		var template_path := CCFStorageService.TEMPLATES_DIR.path_join(template_id + ".json")
		if FileAccess.file_exists(template_path):
			result.append(template_id)
	return result


static func _import_packaged_templates(reader: ZIPReader) -> Dictionary:
	var template_id_remap: Dictionary = {}
	var collision_index := 0
	for entry_path in reader.get_files():
		var entry := str(entry_path)
		if not entry.begins_with("templates/") or not entry.to_lower().ends_with(".json"):
			continue
		var parsed = JSON.parse_string(reader.read_file(entry).get_string_from_utf8())
		if not parsed is Dictionary:
			continue
		var template := CCFTemplateService.normalise_template(parsed)
		var old_id := str(template.get("template_id", "")).strip_edges()
		if old_id.is_empty() or old_id == "default":
			continue
		var existing_path := CCFStorageService.TEMPLATES_DIR.path_join(old_id + ".json")
		if not FileAccess.file_exists(existing_path):
			CCFTemplateService.save_template(template)
			continue
		var existing := CCFTemplateService.load_template(old_id)
		if existing == template:
			continue
		collision_index += 1
		var new_id := "imported_%s_%d_%d" % [
			_safe_template_id(old_id), int(Time.get_unix_time_from_system()), collision_index
		]
		template["template_id"] = new_id
		template["name"] = "%s (Imported)" % str(template.get("name", "Template"))
		var save_result := CCFTemplateService.save_template(template)
		if save_result.get("ok", false):
			template_id_remap[old_id] = new_id
	return template_id_remap


static func _import_packaged_series(reader: ZIPReader) -> Dictionary:
	var series_id_remap: Dictionary = {}
	for entry_path in reader.get_files():
		var entry := str(entry_path)
		if not entry.begins_with("series/") or not entry.to_lower().ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(reader.read_file(entry).get_string_from_utf8())
		if not parsed is Dictionary:
			continue
		var series := CCFSeriesService.normalise_series(parsed)
		var old_id := str(series.get("series_id", ""))
		var existing := CCFSeriesService.series_by_id(old_id)
		var remapped_id := ""
		if not existing.is_empty() and existing != series:
			var fresh := CCFSeriesService.new_series(
				str(series.get("name", "Series")) + " (Imported)"
			)
			remapped_id = str(fresh.get("series_id", ""))
			series["series_id"] = remapped_id
			series["name"] = str(fresh.get("name", "Imported Series"))
		var save_result := CCFSeriesService.save_series(series)
		if not save_result.get("ok", false):
			continue
		if not remapped_id.is_empty():
			series_id_remap[old_id] = remapped_id
	return series_id_remap


static func _remap_project_templates(
	project: Dictionary, template_id_remap: Dictionary
) -> void:
	var characters: Array = project.get("characters", []).duplicate(true)
	for index in range(characters.size()):
		if not characters[index] is Dictionary:
			continue
		var character: Dictionary = characters[index]
		var generation: Dictionary = character.get("generation", {}).duplicate(true)
		var old_id := str(generation.get("template_id", "default"))
		if template_id_remap.has(old_id):
			generation["template_id"] = str(template_id_remap.get(old_id))
			character["generation"] = generation
			characters[index] = character
	project["characters"] = characters


static func _safe_template_id(value: String) -> String:
	var result := ""
	var allowed := "abcdefghijklmnopqrstuvwxyz0123456789_"
	for character in value.to_lower():
		if allowed.contains(character):
			result += character
		else:
			result += "_"
	while result.contains("__"):
		result = result.replace("__", "_")
	result = result.trim_prefix("_").trim_suffix("_")
	if result.is_empty():
		return "template"
	return result


static func _add_directory_contents(
	writer: ZIPPacker,
	absolute_root: String,
	archive_root: String,
	skip_project_file: bool = false
) -> Error:
	var directory := DirAccess.open(absolute_root)
	if directory == null:
		return ERR_CANT_OPEN
	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		if entry_name != "." and entry_name != "..":
			var absolute_child := absolute_root.path_join(entry_name)
			var archive_child := archive_root.path_join(entry_name).replace("\\", "/")
			if directory.current_is_dir():
				var nested_error := _add_directory_contents(writer, absolute_child, archive_child, skip_project_file)
				if nested_error != OK:
					directory.list_dir_end()
					return nested_error
			elif not (skip_project_file and entry_name == CCFStorageService.PROJECT_FILE and archive_root == "project"):
				var file := FileAccess.open(absolute_child, FileAccess.READ)
				if file == null:
					directory.list_dir_end()
					return ERR_CANT_OPEN
				var buffer := file.get_buffer(file.get_length())
				file.close()
				var write_error := _write_zip_entry(writer, archive_child, buffer)
				if write_error != OK:
					directory.list_dir_end()
					return write_error
		entry_name = directory.get_next()
	directory.list_dir_end()
	return OK


static func _write_zip_entry(writer: ZIPPacker, path: String, data: PackedByteArray) -> Error:
	var start_error := writer.start_file(path)
	if start_error != OK:
		return start_error
	var write_error := writer.write_file(data)
	var close_error := writer.close_file()
	if write_error != OK:
		return write_error
	return close_error


static func _is_safe_relative_path(path: String) -> bool:
	if path.is_absolute_path():
		return false
	var normalised := path.replace("\\", "/")
	for part in normalised.split("/", false):
		if part == "..":
			return false
	return not normalised.is_empty()


static func _safe_filename(value: String) -> String:
	var clean := value.strip_edges()
	if clean.is_empty():
		clean = "Untitled Project"
	for forbidden in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		clean = clean.replace(forbidden, "_")
	return clean
