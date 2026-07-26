class_name CCFStorageService
extends RefCounted

const ROOT_DIR := "user://character_card_forge"
const CHARACTERS_DIR := ROOT_DIR + "/characters"
const SETTINGS_DIR := ROOT_DIR + "/settings"
const CACHE_DIR := ROOT_DIR + "/cache"
const EXPORTS_DIR := ROOT_DIR + "/exports"
const TEMPLATES_DIR := ROOT_DIR + "/templates"
const SERIES_DIR := ROOT_DIR + "/series"
const PROJECT_FILE := "character.json"
const CURRENT_FORMAT_VERSION := 2


static func ensure_directories() -> void:
	for path in [
		ROOT_DIR,
		CHARACTERS_DIR,
		SETTINGS_DIR,
		CACHE_DIR,
		EXPORTS_DIR,
		TEMPLATES_DIR,
		SERIES_DIR
	]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


static func new_project() -> Dictionary:
	var now := Time.get_datetime_string_from_system(true)
	var first_character := new_character_record()
	return {
		"format_version": CURRENT_FORMAT_VERSION,
		"project_id": _new_uuid(),
		"created_at": now,
		"updated_at": now,
		"metadata": {
			"name": "Untitled Project",
			"summary": "",
			"tags": [],
			"series_id": "",
			"favorite": false,
			"library": {
				"folder": "",
				"collections": []
			}
		},
		"shared_context": {
			"title": "",
			"premise": "",
			"setting": "",
			"situation": "",
			"shared_rules": "",
			"notes": ""
		},
		"characters": [first_character],
		"relationships": [],
		"card_workflows": [],
		"attachments": [],
		"workspace": {
			"active_character_id": str(first_character.get("character_id", "")),
			"selected_project_tab": "characters"
		}
	}


static func new_character_record(character_name: String = "Untitled Character") -> Dictionary:
	var now := Time.get_datetime_string_from_system(true)
	var clean_name := character_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Untitled Character"
	return {
		"character_id": _new_uuid(),
		"created_at": now,
		"updated_at": now,
		"metadata": {
			"name": clean_name,
			"summary": "",
			"tags": [],
			"role": "",
			"creator": "",
			"character_version": "",
			"favorite": false
		},
		"concept": {
			"prompt": "",
			"notes": ""
		},
		"character": {
			"name": clean_name,
			"description": "",
			"personality": "",
			"scenario": "",
			"first_message": "",
			"example_dialogue": "",
			"creator_notes": "",
			"system_prompt": "",
			"post_history_instructions": "",
			"alternate_greetings": [],
			"character_book": {},
			"card_extensions": {}
		},
		"generation": {
			"template_id": "default",
			"last_model": "",
			"last_generated_at": "",
			"history": []
		},
		"assets": {
			"portrait": "",
			"generated_images": [],
			"emotion_images": []
		},
		"attachments": [],
		"workspace": {
			"selected_section": "overview",
			"builder": {}
		}
	}


static func save_project(project: Dictionary) -> Dictionary:
	ensure_directories()
	var normalised := _normalise_project(project)
	var project_id := str(normalised.get("project_id", "")).strip_edges()
	if project_id.is_empty():
		project_id = _new_uuid()
		normalised["project_id"] = project_id
	normalised["updated_at"] = Time.get_datetime_string_from_system(true)
	_sync_all_character_names(normalised)
	_sync_project_name(normalised)

	var folder := project_folder(project_id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder + "/assets"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder + "/attachments"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder + "/generated_images"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder + "/emotion_images"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder + "/characters"))
	for character in normalised.get("characters", []):
		if not character is Dictionary:
			continue
		var character_id := str(character.get("character_id", ""))
		if character_id.is_empty():
			continue
		var character_root := folder + "/characters/" + character_id
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(character_root + "/assets"))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(character_root + "/attachments"))
		DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(character_root + "/generated_images")
		)
		DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(character_root + "/emotion_images")
		)

	var path := folder + "/" + PROJECT_FILE
	var result := _write_json(path, normalised)
	if not result.get("ok", false):
		return result
	project.clear()
	project.merge(normalised, true)
	return {"ok": true, "path": path, "project_id": project_id}


static func load_project(project_id: String) -> Dictionary:
	var path := project_folder(project_id) + "/" + PROJECT_FILE
	var loaded := _read_json(path)
	if not loaded.get("ok", false):
		return loaded
	var project = loaded.get("data", {})
	if not project is Dictionary:
		return {"ok": false, "error": "Character project is not a JSON object."}
	return {"ok": true, "data": _normalise_project(project)}


static func list_projects() -> Array:
	ensure_directories()
	var rows: Array[Dictionary] = []
	for folder_project_id in DirAccess.get_directories_at(CHARACTERS_DIR):
		var loaded := load_project(folder_project_id)
		if not loaded.get("ok", false):
			continue
		var project: Dictionary = loaded.get("data", {})
		rows.append(project_library_row(project, folder_project_id))
	rows.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return str(first.get("updated_at", "")) > str(second.get("updated_at", ""))
	)
	return rows


static func project_library_row(project: Dictionary, fallback_project_id: String = "") -> Dictionary:
	var project_id := str(project.get("project_id", fallback_project_id)).strip_edges()
	if project_id.is_empty():
		project_id = fallback_project_id
	var metadata: Dictionary = project.get("metadata", {})
	var library_data := _normalise_library_metadata(metadata.get("library", {}))
	var character_rows: Array[Dictionary] = []
	var character_names: Array[String] = []
	var all_tags: Array[String] = _normalise_string_array(metadata.get("tags", []))
	var series_id := str(metadata.get("series_id", "")).strip_edges()
	var search_parts: Array[String] = [
		str(metadata.get("name", "")),
		str(metadata.get("summary", "")),
		series_id,
		str(library_data.get("folder", "")),
		_join_string_array(_normalise_string_array(library_data.get("collections", [])), " "),
		_join_string_array(all_tags, " ")
	]
	_collect_search_strings(project.get("shared_context", {}), search_parts)
	var portrait_source_path := ""
	var interoperability_formats: Array[String] = []
	var favorite_character_count := 0
	for raw_character in project.get("characters", []):
		if not raw_character is Dictionary:
			continue
		var character: Dictionary = raw_character
		var character_metadata: Dictionary = character.get("metadata", {})
		var character_data: Dictionary = character.get("character", {})
		var assets: Dictionary = character.get("assets", {})
		_collect_search_strings(character.get("concept", {}), search_parts)
		_collect_search_strings(character_data, search_parts)
		var character_tags := _normalise_string_array(character_metadata.get("tags", []))
		for tag_text in character_tags:
			_append_unique_string(all_tags, tag_text)
		var interoperability: Dictionary = {}
		var raw_interoperability: Variant = character.get("interoperability", {})
		if raw_interoperability is Dictionary:
			interoperability = raw_interoperability
		_collect_search_strings(interoperability, search_parts)
		var source_format := str(interoperability.get("source_format", "")).strip_edges()
		var source_spec := str(interoperability.get("source_spec", "")).strip_edges()
		var source_label := source_format
		if not source_spec.is_empty():
			source_label = "%s %s" % [source_format, source_spec] if not source_format.is_empty() else source_spec
		if not source_label.is_empty():
			_append_unique_string(interoperability_formats, source_label)
		var character_portrait := str(assets.get("portrait", "")).strip_edges()
		var resolved_portrait := _resolve_project_path(project_id, character_portrait)
		if portrait_source_path.is_empty() and not resolved_portrait.is_empty():
			portrait_source_path = resolved_portrait
		var character_favorite := bool(character_metadata.get("favorite", false))
		if character_favorite:
			favorite_character_count += 1
		var character_name := character_display_name(character)
		character_names.append(character_name)
		character_rows.append(
			{
				"character_id": str(character.get("character_id", "")),
				"name": character_name,
				"summary": str(character_metadata.get("summary", "")),
				"role": str(character_metadata.get("role", "")),
				"tags": character_tags,
				"favorite": character_favorite,
				"creator": str(character_metadata.get("creator", "")),
				"character_version": str(character_metadata.get("character_version", "")),
				"portrait_source_path": resolved_portrait,
				"source_format": source_format,
				"source_spec": source_spec,
				"source_spec_version": str(interoperability.get("source_spec_version", "")),
				"imported_at": str(interoperability.get("imported_at", ""))
			}
		)
		search_parts.append_array(
			[
				character_name,
				str(character_metadata.get("summary", "")),
				str(character_metadata.get("role", "")),
				str(character_metadata.get("creator", "")),
				str(character_metadata.get("character_version", "")),
				_join_string_array(character_tags, " "),
				str(character_data.get("description", "")),
				str(character_data.get("personality", "")),
				str(character_data.get("scenario", "")),
				str(character_data.get("first_message", "")),
				str(character_data.get("creator_notes", "")),
				source_label
			]
		)
	return {
		"project_id": project_id,
		"name": str(metadata.get("name", "Untitled Project")),
		"summary": str(metadata.get("summary", "")),
		"tags": _normalise_string_array(metadata.get("tags", [])),
		"all_tags": all_tags,
		"updated_at": str(project.get("updated_at", "")),
		"created_at": str(project.get("created_at", "")),
		"favorite": bool(metadata.get("favorite", false)),
		"series_id": series_id,
		"favorite_character_count": favorite_character_count,
		"character_count": character_names.size(),
		"character_names": character_names,
		"characters": character_rows,
		"folder": str(library_data.get("folder", "")),
		"collections": _normalise_string_array(library_data.get("collections", [])),
		"portrait_source_path": portrait_source_path,
		"interoperability_formats": interoperability_formats,
		"search_text": _join_string_array(search_parts, "\n").to_lower()
	}


static func duplicate_project(project_id: String) -> Dictionary:
	var loaded := load_project(project_id)
	if not loaded.get("ok", false):
		return loaded
	var copy: Dictionary = loaded.get("data", {}).duplicate(true)
	var now := Time.get_datetime_string_from_system(true)
	copy["project_id"] = _new_uuid()
	copy["created_at"] = now
	copy["updated_at"] = now
	var metadata: Dictionary = copy.get("metadata", {}).duplicate(true)
	metadata["name"] = str(metadata.get("name", "Untitled Project")) + " Copy"
	copy["metadata"] = metadata
	var old_to_new_ids: Dictionary = {}
	var attachment_copy_plan: Array[Dictionary] = []
	copy["attachments"] = _remap_duplicate_attachments(
		copy.get("attachments", []), "", "", attachment_copy_plan
	)
	var duplicated_characters: Array = []
	for raw_character in copy.get("characters", []):
		if not raw_character is Dictionary:
			continue
		var character: Dictionary = raw_character.duplicate(true)
		var old_character_id := str(character.get("character_id", ""))
		var new_character_id := _new_uuid()
		old_to_new_ids[old_character_id] = new_character_id
		character["character_id"] = new_character_id
		character["attachments"] = _remap_duplicate_attachments(
			character.get("attachments", []),
			old_character_id,
			new_character_id,
			attachment_copy_plan
		)
		character["created_at"] = now
		character["updated_at"] = now
		duplicated_characters.append(character)
	copy["characters"] = duplicated_characters
	var duplicated_relationships: Array = []
	for raw_relationship in copy.get("relationships", []):
		if not raw_relationship is Dictionary:
			continue
		var relationship: Dictionary = raw_relationship.duplicate(true)
		var old_first_id := str(relationship.get("character_a_id", ""))
		var old_second_id := str(relationship.get("character_b_id", ""))
		if not old_to_new_ids.has(old_first_id) or not old_to_new_ids.has(old_second_id):
			continue
		relationship["character_a_id"] = str(old_to_new_ids[old_first_id])
		relationship["character_b_id"] = str(old_to_new_ids[old_second_id])
		duplicated_relationships.append(_normalise_relationship_record(relationship))
	copy["relationships"] = duplicated_relationships
	var duplicated_workflows: Array = []
	for raw_workflow in copy.get("card_workflows", []):
		if not raw_workflow is Dictionary:
			continue
		var workflow: Dictionary = raw_workflow.duplicate(true)
		var remapped_ids: Array[String] = []
		for old_character_id in workflow.get("selected_character_ids", []):
			if old_to_new_ids.has(str(old_character_id)):
				remapped_ids.append(str(old_to_new_ids[str(old_character_id)]))
		workflow["selected_character_ids"] = remapped_ids
		var members: Array = []
		for raw_member in workflow.get("members", []):
			if not raw_member is Dictionary:
				continue
			var member: Dictionary = raw_member.duplicate(true)
			var old_member_id := str(member.get("character_id", ""))
			if old_to_new_ids.has(old_member_id):
				member["character_id"] = str(old_to_new_ids[old_member_id])
			members.append(member)
		workflow["members"] = members
		duplicated_workflows.append(workflow)
	copy["card_workflows"] = duplicated_workflows
	var workspace: Dictionary = copy.get("workspace", {}).duplicate(true)
	var old_active_id := str(workspace.get("active_character_id", ""))
	workspace["active_character_id"] = str(old_to_new_ids.get(old_active_id, ""))
	copy["workspace"] = workspace
	var save_result := save_project(copy)
	if not bool(save_result.get("ok", false)):
		return save_result
	var target_project_id := str(save_result.get("project_id", ""))
	var copy_warnings: Array[String] = []
	for copy_entry in attachment_copy_plan:
		var file_result := CCFAttachmentService.copy_managed_attachment(
			project_id,
			target_project_id,
			str(copy_entry.get("source", "")),
			str(copy_entry.get("target", ""))
		)
		if not bool(file_result.get("ok", false)):
			copy_warnings.append(str(file_result.get("error", "Could not copy an attachment.")))
	if not copy_warnings.is_empty():
		save_result["warnings"] = copy_warnings
	return save_result


static func _remap_duplicate_attachments(
	raw_attachments: Variant,
	old_character_id: String,
	new_character_id: String,
	copy_plan: Array[Dictionary]
) -> Array:
	var result: Array = []
	for raw_attachment in CCFAttachmentService.normalise_list(raw_attachments):
		var attachment: Dictionary = raw_attachment.duplicate(true)
		var source_relative := str(attachment.get("relative_path", ""))
		var target_relative := source_relative
		if not old_character_id.is_empty() and not new_character_id.is_empty():
			var old_prefix := "characters/%s/" % old_character_id
			if target_relative.begins_with(old_prefix):
				target_relative = (
					"characters/%s/" % new_character_id
					+ target_relative.trim_prefix(old_prefix)
				)
		attachment["relative_path"] = target_relative
		if not source_relative.is_empty() and not target_relative.is_empty():
			copy_plan.append({"source": source_relative, "target": target_relative})
		result.append(attachment)
	return result


static func delete_project(project_id: String) -> Dictionary:
	var absolute := ProjectSettings.globalize_path(project_folder(project_id))
	if not DirAccess.dir_exists_absolute(absolute):
		return {"ok": false, "error": "Character project folder does not exist."}
	var error := _remove_tree(absolute)
	if error != OK:
		return {"ok": false, "error": "Could not delete character project folder (error %s)." % error}
	return {"ok": true}


static func project_folder(project_id: String) -> String:
	return CHARACTERS_DIR + "/" + project_id


static func user_data_path() -> String:
	ensure_directories()
	return ProjectSettings.globalize_path(ROOT_DIR)


static func active_character_id(project: Dictionary) -> String:
	var workspace = project.get("workspace", {})
	if workspace is Dictionary:
		var requested_id := str(workspace.get("active_character_id", ""))
		if character_index(project, requested_id) >= 0:
			return requested_id
	var characters = project.get("characters", [])
	if characters is Array and not characters.is_empty() and characters[0] is Dictionary:
		return str(characters[0].get("character_id", ""))
	return ""


static func active_character_template_id(project: Dictionary) -> String:
	var character := get_character(project, active_character_id(project))
	var generation = character.get("generation", {})
	if generation is Dictionary:
		return str(generation.get("template_id", "default"))
	return "default"


static func character_index(project: Dictionary, character_id: String) -> int:
	var characters = project.get("characters", [])
	if not characters is Array:
		return -1
	for index in range(characters.size()):
		var character = characters[index]
		if character is Dictionary and str(character.get("character_id", "")) == character_id:
			return index
	return -1


static func get_character(project: Dictionary, character_id: String) -> Dictionary:
	var index := character_index(project, character_id)
	if index < 0:
		return {}
	var characters: Array = project.get("characters", [])
	var character = characters[index]
	return character.duplicate(true) if character is Dictionary else {}


static func add_character(project: Dictionary, character_name: String = "Untitled Character") -> String:
	var character := new_character_record(character_name)
	var characters: Array = project.get("characters", []).duplicate(true)
	characters.append(character)
	project["characters"] = characters
	var workspace: Dictionary = project.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = str(character.get("character_id", ""))
	project["workspace"] = workspace
	return str(character.get("character_id", ""))


static func duplicate_character(project: Dictionary, character_id: String) -> Dictionary:
	var source := get_character(project, character_id)
	if source.is_empty():
		return {"ok": false, "error": "The selected character could not be found."}
	var now := Time.get_datetime_string_from_system(true)
	var copy := source.duplicate(true)
	copy["character_id"] = _new_uuid()
	copy["created_at"] = now
	copy["updated_at"] = now
	var character_data: Dictionary = copy.get("character", {}).duplicate(true)
	character_data["name"] = str(character_data.get("name", "Untitled Character")) + " Copy"
	copy["character"] = character_data
	_sync_character_display_name(copy)
	var characters: Array = project.get("characters", []).duplicate(true)
	characters.append(copy)
	project["characters"] = characters
	var workspace: Dictionary = project.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = str(copy.get("character_id", ""))
	project["workspace"] = workspace
	return {"ok": true, "character_id": str(copy.get("character_id", ""))}


static func delete_character(project: Dictionary, character_id: String) -> Dictionary:
	var characters: Array = project.get("characters", []).duplicate(true)
	if characters.size() <= 1:
		return {"ok": false, "error": "A project must contain at least one character."}
	var index := character_index(project, character_id)
	if index < 0:
		return {"ok": false, "error": "The selected character could not be found."}
	characters.remove_at(index)
	project["characters"] = characters
	var remaining_relationships: Array = []
	for raw_relationship in project.get("relationships", []):
		if not raw_relationship is Dictionary:
			continue
		var first_id := str(raw_relationship.get("character_a_id", ""))
		var second_id := str(raw_relationship.get("character_b_id", ""))
		if first_id != character_id and second_id != character_id:
			remaining_relationships.append(raw_relationship)
	project["relationships"] = remaining_relationships
	project["card_workflows"] = _normalise_card_workflows(
		project, project.get("card_workflows", [])
	)
	var next_index := mini(index, characters.size() - 1)
	var next_character: Dictionary = characters[next_index]
	var next_id := str(next_character.get("character_id", ""))
	var workspace: Dictionary = project.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = next_id
	project["workspace"] = workspace
	return {"ok": true, "active_character_id": next_id}


static func update_character(project: Dictionary, workspace_document: Dictionary) -> Dictionary:
	var character_id := str(workspace_document.get("character_id", ""))
	var index := character_index(project, character_id)
	if index < 0:
		return {"ok": false, "error": "The active character no longer exists in this project."}
	var cleaned := workspace_document.duplicate(true)
	cleaned.erase("project_id")
	cleaned.erase("container_project_id")
	cleaned.erase("shared_context")
	cleaned.erase("project_metadata")
	cleaned.erase("relationships")
	cleaned.erase("project_characters")
	cleaned.erase("project_attachments")
	cleaned.erase("attachment_context_character_limit")
	cleaned.erase("card_workflows")
	cleaned["character_id"] = character_id
	cleaned["updated_at"] = Time.get_datetime_string_from_system(true)
	_sync_character_display_name(cleaned)
	var characters: Array = project.get("characters", []).duplicate(true)
	characters[index] = cleaned
	project["characters"] = characters
	return {"ok": true}


static func character_workspace_document(project: Dictionary, character_id: String) -> Dictionary:
	var character := get_character(project, character_id)
	if character.is_empty():
		return {}
	var project_id := str(project.get("project_id", ""))
	character["container_project_id"] = project_id
	character["project_id"] = workspace_owner_id(project_id, character_id)
	character["shared_context"] = project.get("shared_context", {}).duplicate(true)
	character["project_metadata"] = project.get("metadata", {}).duplicate(true)
	character["relationships"] = project.get("relationships", []).duplicate(true)
	character["project_attachments"] = project.get("attachments", []).duplicate(true)
	character["project_characters"] = project_character_summaries(project)
	character["card_workflows"] = project.get("card_workflows", []).duplicate(true)
	return character


static func workspace_owner_id(project_id: String, character_id: String) -> String:
	return "%s::%s" % [project_id, character_id]


static func character_display_name(character: Dictionary) -> String:
	var character_data = character.get("character", {})
	if character_data is Dictionary:
		var character_name := str(character_data.get("name", "")).strip_edges()
		if not character_name.is_empty():
			return character_name
	var metadata = character.get("metadata", {})
	if metadata is Dictionary:
		return str(metadata.get("name", "Untitled Character"))
	return "Untitled Character"


static func project_character_summaries(project: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_character in project.get("characters", []):
		if not raw_character is Dictionary:
			continue
		var character: Dictionary = raw_character
		var metadata = character.get("metadata", {})
		result.append(
			{
				"character_id": str(character.get("character_id", "")),
				"name": character_display_name(character),
				"role": str(metadata.get("role", "")) if metadata is Dictionary else "",
				"summary": str(metadata.get("summary", "")) if metadata is Dictionary else ""
			}
		)
	return result


static func get_value_at_path(data: Dictionary, path: String, fallback: Variant = "") -> Variant:
	var parts := path.split(".", false)
	var current: Variant = data
	for part in parts:
		if not current is Dictionary:
			return fallback
		var dict: Dictionary = current
		if not dict.has(part):
			return fallback
		current = dict[part]
	return current


static func set_value_at_path(data: Dictionary, path: String, value: Variant) -> void:
	var parts := path.split(".", false)
	if parts.is_empty():
		return
	var current: Dictionary = data
	for index in range(parts.size() - 1):
		var key := parts[index]
		if not current.has(key) or not current[key] is Dictionary:
			current[key] = {}
		current = current[key]
	current[parts[-1]] = value
	if path == "character.name":
		_sync_character_display_name(data)


static func _normalise_project(project: Dictionary) -> Dictionary:
	var characters_value = project.get("characters", null)
	if int(project.get("format_version", 1)) < CURRENT_FORMAT_VERSION or not (characters_value is Array):
		return _migrate_v1_project(project)

	var defaults := new_project()
	defaults["project_id"] = str(project.get("project_id", defaults["project_id"]))
	defaults["created_at"] = str(project.get("created_at", defaults["created_at"]))
	defaults["updated_at"] = str(project.get("updated_at", defaults["updated_at"]))
	for key in ["metadata", "shared_context", "workspace"]:
		var merged: Dictionary = defaults.get(key, {}).duplicate(true)
		var incoming = project.get(key, {})
		if incoming is Dictionary:
			merged.merge(incoming, true)
		defaults[key] = merged
	var normalised_metadata: Dictionary = defaults.get("metadata", {})
	normalised_metadata["tags"] = _normalise_string_array(normalised_metadata.get("tags", []))
	normalised_metadata["library"] = _normalise_library_metadata(
		normalised_metadata.get("library", {})
	)
	defaults["metadata"] = normalised_metadata
	var normalised_characters: Array = []
	for raw_character in project.get("characters", []):
		if raw_character is Dictionary:
			normalised_characters.append(_normalise_character(raw_character))
	if normalised_characters.is_empty():
		normalised_characters.append(new_character_record())
	defaults["characters"] = normalised_characters
	var relationships = project.get("relationships", [])
	defaults["relationships"] = relationships.duplicate(true) if relationships is Array else []
	defaults["relationships"] = _normalise_relationships(defaults, defaults["relationships"])
	var card_workflows = project.get("card_workflows", [])
	defaults["card_workflows"] = _normalise_card_workflows(defaults, card_workflows)
	defaults["attachments"] = CCFAttachmentService.normalise_list(project.get("attachments", []))
	for key in project:
		if not defaults.has(key):
			var custom_value = project.get(key)
			defaults[key] = (
				custom_value.duplicate(true)
				if custom_value is Dictionary or custom_value is Array
				else custom_value
			)
	defaults["format_version"] = CURRENT_FORMAT_VERSION
	var workspace: Dictionary = defaults.get("workspace", {})
	if character_index(defaults, str(workspace.get("active_character_id", ""))) < 0:
		workspace["active_character_id"] = str(normalised_characters[0].get("character_id", ""))
	defaults["workspace"] = workspace
	_sync_all_character_names(defaults)
	_sync_project_name(defaults)
	return defaults


static func _normalise_character(character: Dictionary) -> Dictionary:
	var defaults := new_character_record()
	defaults["character_id"] = str(character.get("character_id", defaults["character_id"]))
	defaults["created_at"] = str(character.get("created_at", defaults["created_at"]))
	defaults["updated_at"] = str(character.get("updated_at", defaults["updated_at"]))
	for key in ["metadata", "concept", "character", "generation", "assets", "workspace"]:
		var merged: Dictionary = defaults.get(key, {}).duplicate(true)
		var incoming = character.get(key, {})
		if incoming is Dictionary:
			merged.merge(incoming, true)
		defaults[key] = merged
	for key in character:
		if not defaults.has(key):
			var custom_value = character.get(key)
			defaults[key] = (
				custom_value.duplicate(true)
				if custom_value is Dictionary or custom_value is Array
				else custom_value
			)
	defaults["attachments"] = CCFAttachmentService.normalise_list(character.get("attachments", []))
	var character_metadata: Dictionary = defaults.get("metadata", {})
	character_metadata["tags"] = _normalise_string_array(character_metadata.get("tags", []))
	defaults["metadata"] = character_metadata
	_sync_character_display_name(defaults)
	return defaults


static func _migrate_v1_project(project: Dictionary) -> Dictionary:
	var migrated := new_project()
	migrated["project_id"] = str(project.get("project_id", migrated["project_id"]))
	migrated["created_at"] = str(project.get("created_at", migrated["created_at"]))
	migrated["updated_at"] = str(project.get("updated_at", migrated["updated_at"]))

	var legacy_character := new_character_record()
	legacy_character["created_at"] = str(project.get("created_at", legacy_character["created_at"]))
	legacy_character["updated_at"] = str(project.get("updated_at", legacy_character["updated_at"]))
	for key in ["metadata", "concept", "character", "generation", "assets", "workspace"]:
		var merged: Dictionary = legacy_character.get(key, {}).duplicate(true)
		var incoming = project.get(key, {})
		if incoming is Dictionary:
			merged.merge(incoming, true)
		legacy_character[key] = merged
	for key in project:
		if key in [
			"format_version",
			"project_id",
			"created_at",
			"updated_at",
			"metadata",
			"concept",
			"character",
			"generation",
			"assets",
			"attachments",
			"workspace"
		]:
			continue
		legacy_character[key] = project.get(key)
	_sync_character_display_name(legacy_character)
	migrated["characters"] = [legacy_character]

	var legacy_metadata = project.get("metadata", {})
	var project_metadata: Dictionary = migrated.get("metadata", {})
	if legacy_metadata is Dictionary:
		project_metadata["name"] = str(
			legacy_metadata.get("name", character_display_name(legacy_character))
		)
		project_metadata["summary"] = str(legacy_metadata.get("summary", ""))
		var legacy_tags = legacy_metadata.get("tags", [])
		project_metadata["tags"] = legacy_tags.duplicate(true) if legacy_tags is Array else []
		project_metadata["series_id"] = str(legacy_metadata.get("series_id", ""))
		project_metadata["favorite"] = bool(legacy_metadata.get("favorite", false))
		project_metadata["library"] = _normalise_library_metadata(legacy_metadata.get("library", {}))
	migrated["metadata"] = project_metadata
	var workspace: Dictionary = migrated.get("workspace", {})
	workspace["active_character_id"] = str(legacy_character.get("character_id", ""))
	migrated["workspace"] = workspace
	migrated["format_version"] = CURRENT_FORMAT_VERSION
	_sync_project_name(migrated)
	return migrated


static func _collect_search_strings(
	raw_value: Variant, output: Array[String], depth: int = 0
) -> void:
	if depth > 5:
		return
	if raw_value is Dictionary:
		for key in raw_value:
			_collect_search_strings(raw_value.get(key), output, depth + 1)
	elif raw_value is Array:
		for item in raw_value:
			_collect_search_strings(item, output, depth + 1)
	elif raw_value is String:
		var text: String = raw_value.strip_edges()
		if not text.is_empty():
			output.append(text)



static func _normalise_library_metadata(raw_value: Variant) -> Dictionary:
	var result := {"folder": "", "collections": []}
	if raw_value is Dictionary:
		result["folder"] = str(raw_value.get("folder", "")).strip_edges()
		result["collections"] = _normalise_string_array(raw_value.get("collections", []))
	return result


static func _normalise_string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_value is Array:
		for item in raw_value:
			var text := str(item).strip_edges()
			if not text.is_empty():
				_append_unique_string(result, text)
	return result


static func _append_unique_string(values: Array[String], candidate: String) -> void:
	for existing in values:
		if existing.nocasecmp_to(candidate) == 0:
			return
	values.append(candidate)


static func _join_string_array(values: Array[String], separator: String) -> String:
	var output := ""
	for value_index in range(values.size()):
		if value_index > 0:
			output += separator
		output += values[value_index]
	return output


static func _resolve_project_path(project_id: String, relative_path: String) -> String:
	var clean_path := relative_path.strip_edges()
	if clean_path.is_empty():
		return ""
	if clean_path.begins_with("user://") or clean_path.is_absolute_path():
		return clean_path
	return project_folder(project_id).path_join(clean_path)


static func _relationship_pair_key(character_a_id: String, character_b_id: String) -> String:
	var first_id := character_a_id.strip_edges()
	var second_id := character_b_id.strip_edges()
	if first_id.naturalnocasecmp_to(second_id) > 0:
		var swap_id := first_id
		first_id = second_id
		second_id = swap_id
	return "%s::%s" % [first_id, second_id]


static func _normalise_relationship_record(raw_relationship: Dictionary) -> Dictionary:
	var first_id := str(raw_relationship.get("character_a_id", "")).strip_edges()
	var second_id := str(raw_relationship.get("character_b_id", "")).strip_edges()
	if first_id.is_empty() or second_id.is_empty() or first_id == second_id:
		return {}
	var original_first_id := first_id
	if first_id.naturalnocasecmp_to(second_id) > 0:
		var swap_id := first_id
		first_id = second_id
		second_id = swap_id
	var swapped := original_first_id != first_id
	var tags: Array[String] = []
	var raw_tags = raw_relationship.get("tags", [])
	if raw_tags is Array:
		for raw_tag in raw_tags:
			var clean_tag := str(raw_tag).strip_edges()
			if not clean_tag.is_empty() and not tags.has(clean_tag):
				tags.append(clean_tag)
	elif not str(raw_tags).strip_edges().is_empty():
		for raw_tag in str(raw_tags).split(",", false):
			var clean_tag := raw_tag.strip_edges()
			if not clean_tag.is_empty() and not tags.has(clean_tag):
				tags.append(clean_tag)
	var raw_a_to_b := str(raw_relationship.get("a_to_b", ""))
	var raw_b_to_a := str(raw_relationship.get("b_to_a", ""))
	return {
		"relationship_id": _relationship_pair_key(first_id, second_id),
		"character_a_id": first_id,
		"character_b_id": second_id,
		"label": str(raw_relationship.get("label", "")),
		"status": str(raw_relationship.get("status", "")),
		"summary": str(raw_relationship.get("summary", "")),
		"a_to_b": raw_b_to_a if swapped else raw_a_to_b,
		"b_to_a": raw_a_to_b if swapped else raw_b_to_a,
		"dynamic": str(raw_relationship.get("dynamic", "")),
		"notes": str(raw_relationship.get("notes", "")),
		"tags": tags,
		"intensity": clampi(int(raw_relationship.get("intensity", 50)), 0, 100),
		"updated_at": str(
			raw_relationship.get("updated_at", Time.get_datetime_string_from_system(true))
		)
	}


static func _normalise_relationships(project: Dictionary, raw_relationships: Variant) -> Array:
	var result: Array = []
	if not raw_relationships is Array:
		return result
	var valid_ids: Dictionary = {}
	for summary in project_character_summaries(project):
		valid_ids[str(summary.get("character_id", ""))] = true
	var by_pair: Dictionary = {}
	for raw_relationship in raw_relationships:
		if not raw_relationship is Dictionary:
			continue
		var relationship := _normalise_relationship_record(raw_relationship)
		if relationship.is_empty():
			continue
		var first_id := str(relationship.get("character_a_id", ""))
		var second_id := str(relationship.get("character_b_id", ""))
		if not valid_ids.has(first_id) or not valid_ids.has(second_id):
			continue
		by_pair[_relationship_pair_key(first_id, second_id)] = relationship
	for relationship in by_pair.values():
		if relationship is Dictionary:
			result.append(relationship)
	return result


static func _normalise_card_workflows(project: Dictionary, raw_workflows: Variant) -> Array:
	var result: Array = []
	if not raw_workflows is Array:
		return result
	var valid_ids: Dictionary = {}
	for summary in project_character_summaries(project):
		valid_ids[str(summary.get("character_id", ""))] = true
	var seen_ids: Dictionary = {}
	for raw_workflow in raw_workflows:
		if not raw_workflow is Dictionary:
			continue
		var workflow: Dictionary = raw_workflow.duplicate(true)
		var workflow_id := str(workflow.get("workflow_id", "")).strip_edges()
		if workflow_id.is_empty():
			continue
		if seen_ids.has(workflow_id):
			continue
		seen_ids[workflow_id] = true
		var selected_ids: Array[String] = []
		for raw_id in workflow.get("selected_character_ids", []):
			var character_id := str(raw_id)
			if valid_ids.has(character_id) and not selected_ids.has(character_id):
				selected_ids.append(character_id)
		if selected_ids.size() < 2:
			continue
		workflow["selected_character_ids"] = selected_ids
		var members: Array = []
		for raw_member in workflow.get("members", []):
			if not raw_member is Dictionary:
				continue
			var character_id := str(raw_member.get("character_id", ""))
			if not selected_ids.has(character_id):
				continue
			var member: Dictionary = raw_member.duplicate(true)
			member["character_id"] = character_id
			members.append(member)
		workflow["members"] = members
		result.append(workflow)
	return result


static func _sync_all_character_names(project: Dictionary) -> void:
	var characters: Array = project.get("characters", []).duplicate(true)
	for index in range(characters.size()):
		if characters[index] is Dictionary:
			var character: Dictionary = characters[index]
			_sync_character_display_name(character)
			characters[index] = character
	project["characters"] = characters


static func _sync_character_display_name(character_record: Dictionary) -> void:
	var character: Dictionary = character_record.get("character", {})
	var metadata: Dictionary = character_record.get("metadata", {})
	var character_name := str(character.get("name", "")).strip_edges()
	if character_name.is_empty():
		character_name = "Untitled Character"
		character["name"] = character_name
	metadata["name"] = character_name
	character_record["character"] = character
	character_record["metadata"] = metadata


static func _sync_project_name(project: Dictionary) -> void:
	var metadata: Dictionary = project.get("metadata", {})
	var project_name := str(metadata.get("name", "")).strip_edges()
	var characters = project.get("characters", [])
	if (
		(project_name.is_empty() or project_name == "Untitled Project")
		and characters is Array
		and characters.size() == 1
		and characters[0] is Dictionary
	):
		project_name = character_display_name(characters[0])
	elif project_name.is_empty():
		project_name = "Untitled Project"
	metadata["name"] = project_name
	project["metadata"] = metadata


static func _write_json(path: String, data: Variant) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open %s for writing." % path}
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return {"ok": true}


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "File does not exist: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open %s." % path}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		return {"ok": false, "error": "Invalid JSON in %s." % path}
	return {"ok": true, "data": parsed}


static func _new_uuid() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	if bytes.size() != 16:
		return "%s-%s" % [Time.get_unix_time_from_system(), randi()]
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := ""
	for byte in bytes:
		hex += "%02x" % byte
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)
	]


static func _remove_tree(path: String) -> Error:
	var dir := DirAccess.open(path)
	if dir == null:
		return ERR_CANT_OPEN
	dir.list_dir_begin()
	var item := dir.get_next()
	while not item.is_empty():
		if item != "." and item != "..":
			var child := path.path_join(item)
			if dir.current_is_dir():
				var nested_error := _remove_tree(child)
				if nested_error != OK:
					dir.list_dir_end()
					return nested_error
			else:
				var file_error := DirAccess.remove_absolute(child)
				if file_error != OK:
					dir.list_dir_end()
					return file_error
		item = dir.get_next()
	dir.list_dir_end()
	return DirAccess.remove_absolute(path)
