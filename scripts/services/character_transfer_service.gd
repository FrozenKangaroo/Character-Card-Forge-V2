class_name CCFCharacterTransferService
extends RefCounted

const OPERATION_COPY := "copy"
const OPERATION_MOVE := "move"


static func transfer_character(
	source_project: Dictionary,
	character_id: String,
	destination_project_id: String,
	operation: String,
	new_project_name: String = ""
) -> Dictionary:
	var clean_operation := operation.strip_edges().to_lower()
	if clean_operation not in [OPERATION_COPY, OPERATION_MOVE]:
		return {"ok": false, "error": "Character transfer operation must be Copy or Move."}
	var source_project_id := str(source_project.get("project_id", "")).strip_edges()
	if source_project_id.is_empty():
		return {"ok": false, "error": "Save the source Character Project before transferring a character."}
	var source_character := CCFStorageService.get_character(source_project, character_id)
	if source_character.is_empty():
		return {"ok": false, "error": "The selected character could not be found in the source project."}

	var clean_destination_id := destination_project_id.strip_edges()
	var create_new_project := clean_destination_id.is_empty()
	if not create_new_project and clean_destination_id == source_project_id:
		return {
			"ok": false,
			"error": "Choose a different Character Project. Use Duplicate Character for a copy inside the current project."
		}

	var persisted_source := source_project.duplicate(true)
	var source_save := CCFStorageService.save_project(persisted_source)
	if not bool(source_save.get("ok", false)):
		return source_save

	var target_project: Dictionary
	if create_new_project:
		target_project = _new_target_project(source_character, new_project_name)
		clean_destination_id = str(target_project.get("project_id", ""))
	else:
		var loaded_target := CCFStorageService.load_project(clean_destination_id)
		if not bool(loaded_target.get("ok", false)):
			return {
				"ok": false,
				"error": "Could not load the destination Character Project: %s" % str(loaded_target.get("error", "Unknown error"))
			}
		target_project = loaded_target.get("data", {}).duplicate(true)

	var destination_character := source_character.duplicate(true)
	var source_character_id := str(source_character.get("character_id", ""))
	var destination_character_id := source_character_id
	if clean_operation == OPERATION_COPY or CCFStorageService.character_index(target_project, destination_character_id) >= 0:
		destination_character_id = str(CCFStorageService.new_character_record(CCFStorageService.character_display_name(source_character)).get("character_id", ""))
	if destination_character_id.is_empty():
		return {"ok": false, "error": "Could not allocate an identity for the destination character."}

	if destination_character_id != source_character_id:
		destination_character = _remap_character_paths(destination_character, source_character_id, destination_character_id)
		destination_character["character_id"] = destination_character_id
		destination_character["created_at"] = Time.get_datetime_string_from_system(true)
	destination_character["updated_at"] = Time.get_datetime_string_from_system(true)

	var copy_result := _copy_character_tree(source_project_id, source_character_id, clean_destination_id, destination_character_id)
	if not bool(copy_result.get("ok", false)):
		if create_new_project:
			_cleanup_project_folder(clean_destination_id)
		return copy_result

	var target_characters: Array = target_project.get("characters", []).duplicate(true)
	if create_new_project:
		target_characters.clear()
	target_characters.append(destination_character)
	target_project["characters"] = target_characters
	var target_workspace: Dictionary = target_project.get("workspace", {}).duplicate(true)
	target_workspace["active_character_id"] = destination_character_id
	target_project["workspace"] = target_workspace
	if create_new_project:
		var target_metadata: Dictionary = target_project.get("metadata", {}).duplicate(true)
		var requested_name := new_project_name.strip_edges()
		if requested_name.is_empty():
			target_metadata["name"] = ""
			target_metadata["name_is_manual"] = false
		else:
			target_metadata["name"] = requested_name
			target_metadata["name_is_manual"] = true
		target_project["metadata"] = target_metadata
		CCFProjectLifecycleService.sync_project_name(target_project)

	var target_save := CCFStorageService.save_project(target_project)
	if not bool(target_save.get("ok", false)):
		_cleanup_character_tree(clean_destination_id, destination_character_id)
		if create_new_project:
			_cleanup_project_folder(clean_destination_id)
		return {
			"ok": false,
			"error": "The destination could not be saved, so the source character was left untouched: %s" % str(target_save.get("error", "Unknown error"))
		}

	var source_after := persisted_source.duplicate(true)
	var source_replaced_with_empty_draft := false
	if clean_operation == OPERATION_MOVE:
		var source_characters: Array = source_after.get("characters", []).duplicate(true)
		if source_characters.size() > 1:
			var delete_result := CCFStorageService.delete_character(source_after, source_character_id)
			if not bool(delete_result.get("ok", false)):
				return {
					"ok": false,
					"destination_saved": true,
					"target_project": target_project,
					"error": "The destination was saved, but the source character could not be removed. No source files were deleted."
				}
		else:
			var empty_draft := CCFStorageService.new_character_record()
			source_after["characters"] = [empty_draft]
			source_after["relationships"] = []
			source_after["card_workflows"] = []
			var source_workspace: Dictionary = source_after.get("workspace", {}).duplicate(true)
			source_workspace["active_character_id"] = str(empty_draft.get("character_id", ""))
			source_after["workspace"] = source_workspace
			source_replaced_with_empty_draft = true

		var source_remove_save := CCFStorageService.save_project(source_after)
		if not bool(source_remove_save.get("ok", false)):
			return {
				"ok": false,
				"destination_saved": true,
				"target_project": target_project,
				"error": "The destination was saved, but CCF could not save removal from the source. The source files were left intact to prevent data loss."
			}
		_cleanup_character_tree(source_project_id, source_character_id)

	source_project.clear()
	source_project.merge(source_after, true)
	return {
		"ok": true,
		"operation": clean_operation,
		"source_project": source_after.duplicate(true),
		"target_project": target_project.duplicate(true),
		"target_project_id": clean_destination_id,
		"target_character_id": destination_character_id,
		"source_replaced_with_empty_draft": source_replaced_with_empty_draft,
		"created_project": create_new_project
	}


static func _new_target_project(_source_character: Dictionary, project_name: String) -> Dictionary:
	var target := CCFStorageService.new_project()
	target["characters"] = []
	target["relationships"] = []
	target["card_workflows"] = []
	target["attachments"] = []
	target["shared_context"] = {
		"title": "",
		"premise": "",
		"setting": "",
		"situation": "",
		"shared_rules": "",
		"notes": ""
	}
	var metadata: Dictionary = target.get("metadata", {}).duplicate(true)
	metadata["name"] = project_name.strip_edges()
	metadata["name_is_manual"] = not project_name.strip_edges().is_empty()
	target["metadata"] = metadata
	return target


static func _remap_character_paths(value: Variant, source_character_id: String, destination_character_id: String) -> Variant:
	var source_prefix := "characters/%s/" % source_character_id
	var destination_prefix := "characters/%s/" % destination_character_id
	if value is String:
		return value.replace(source_prefix, destination_prefix)
	if value is Array:
		var remapped_array: Array = []
		for item in value:
			remapped_array.append(_remap_character_paths(item, source_character_id, destination_character_id))
		return remapped_array
	if value is Dictionary:
		var remapped_dictionary: Dictionary = {}
		for key in value:
			remapped_dictionary[key] = _remap_character_paths(value.get(key), source_character_id, destination_character_id)
		return remapped_dictionary
	return value


static func _copy_character_tree(source_project_id: String, source_character_id: String, target_project_id: String, target_character_id: String) -> Dictionary:
	var source_root := ProjectSettings.globalize_path(CCFStorageService.project_folder(source_project_id).path_join("characters/%s" % source_character_id))
	if not DirAccess.dir_exists_absolute(source_root):
		return {"ok": true, "copied": false}
	var target_root := ProjectSettings.globalize_path(CCFStorageService.project_folder(target_project_id).path_join("characters/%s" % target_character_id))
	_cleanup_tree_absolute(target_root)
	var copy_error := _copy_tree_absolute(source_root, target_root)
	if copy_error != OK:
		_cleanup_tree_absolute(target_root)
		return {
			"ok": false,
			"error": "Could not copy the character's managed assets to the destination (error %s). The source was not removed." % copy_error
		}
	return {"ok": true, "copied": true}


static func _copy_tree_absolute(source_path: String, target_path: String) -> Error:
	var make_error := DirAccess.make_dir_recursive_absolute(target_path)
	if make_error != OK:
		return make_error
	for directory_name in DirAccess.get_directories_at(source_path):
		var nested_error := _copy_tree_absolute(source_path.path_join(directory_name), target_path.path_join(directory_name))
		if nested_error != OK:
			return nested_error
	for file_name in DirAccess.get_files_at(source_path):
		var copy_error := DirAccess.copy_absolute(source_path.path_join(file_name), target_path.path_join(file_name))
		if copy_error != OK:
			return copy_error
	return OK


static func _cleanup_character_tree(project_id: String, character_id: String) -> void:
	_cleanup_tree_absolute(ProjectSettings.globalize_path(CCFStorageService.project_folder(project_id).path_join("characters/%s" % character_id)))


static func _cleanup_project_folder(project_id: String) -> void:
	_cleanup_tree_absolute(ProjectSettings.globalize_path(CCFStorageService.project_folder(project_id)))


static func _cleanup_tree_absolute(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for directory_name in DirAccess.get_directories_at(path):
		_cleanup_tree_absolute(path.path_join(directory_name))
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	DirAccess.remove_absolute(path)
