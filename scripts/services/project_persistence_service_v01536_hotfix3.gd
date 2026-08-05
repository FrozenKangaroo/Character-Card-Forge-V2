class_name CCFProjectPersistenceServiceV01536Hotfix3
extends RefCounted

const COMPLETION_SERVICE_V01535 = preload(
	"res://scripts/services/collaborator_completion_service_v01535.gd"
)


static func is_project_persisted(project: Dictionary) -> bool:
	var project_id := str(project.get("project_id", "")).strip_edges()
	if project_id.is_empty():
		return false
	return FileAccess.file_exists(
		CCFStorageService.project_folder(project_id).path_join(CCFStorageService.PROJECT_FILE)
	)


static func project_has_meaningful_content(
	project: Dictionary,
	template: Dictionary
) -> bool:
	if project.is_empty():
		return false

	var metadata_value: Variant = project.get("metadata", {})
	if metadata_value is Dictionary:
		var metadata: Dictionary = metadata_value
		var project_name := str(metadata.get("name", "")).strip_edges()
		if not project_name.is_empty() and project_name != "Untitled Project":
			return true
		for key in ["summary", "series_id"]:
			if not str(metadata.get(key, "")).strip_edges().is_empty():
				return true
		if _variant_has_content(metadata.get("tags", [])):
			return true

	if _variant_has_content(project.get("shared_context", {})):
		return true
	for key in ["relationships", "card_workflows", "attachments"]:
		if _variant_has_content(project.get(key, [])):
			return true

	var characters_value: Variant = project.get("characters", [])
	if characters_value is Array:
		for raw_character in characters_value:
			if raw_character is Dictionary and _character_has_meaningful_content(
				raw_character as Dictionary,
				template
			):
				return true
	return false


static func save_if_meaningful(
	project: Dictionary,
	template: Dictionary
) -> Dictionary:
	if is_project_persisted(project):
		return CCFStorageService.save_project(project)
	if not project_has_meaningful_content(project, template):
		return {
			"ok": true,
			"persisted": false,
			"skipped_empty": true,
			"project_id": str(project.get("project_id", "")),
			"path": ""
		}
	var result := CCFStorageService.save_project(project)
	if bool(result.get("ok", false)):
		result["persisted"] = true
		result["skipped_empty"] = false
	return result


static func capabilities() -> Dictionary:
	return {
		"version": "0.15.36-hotfix3",
		"deferred_first_save": true,
		"empty_unsaved_project_guard": true,
		"existing_project_non_destructive": true,
		"project_level_content_counts": true,
		"named_character_counts": true
	}


static func _character_has_meaningful_content(
	character: Dictionary,
	template: Dictionary
) -> bool:
	if not COMPLETION_SERVICE_V01535.is_effectively_empty_character(character, template):
		return true
	var display_name := CCFStorageService.character_display_name(character).strip_edges()
	return not _is_placeholder_character_name(display_name)


static func _is_placeholder_character_name(display_name: String) -> bool:
	var clean_name := display_name.strip_edges()
	if clean_name.is_empty() or clean_name == "Untitled Character":
		return true
	const PREFIX := "Untitled Character "
	if clean_name.begins_with(PREFIX):
		var suffix := clean_name.trim_prefix(PREFIX).strip_edges()
		return suffix.is_valid_int()
	return false


static func _variant_has_content(value: Variant) -> bool:
	if value == null:
		return false
	if value is String:
		return not (value as String).strip_edges().is_empty()
	if value is Array:
		for item in value as Array:
			if _variant_has_content(item):
				return true
		return false
	if value is Dictionary:
		for item in (value as Dictionary).values():
			if _variant_has_content(item):
				return true
		return false
	if value is bool:
		return bool(value)
	if value is int or value is float:
		return float(value) != 0.0
	return true
