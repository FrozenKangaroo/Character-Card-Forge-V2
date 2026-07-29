class_name CCFWorkspaceV0136View
extends CCFWorkspaceV0135View


func load_project(project: Dictionary, template: Dictionary, settings: Dictionary) -> void:
	var prepared := project.duplicate(true)
	var metadata: Dictionary = prepared.get("metadata", {}).duplicate(true)
	if not metadata.has("name_is_manual"):
		metadata["name_is_manual"] = CCFProjectLifecycleService.infer_manual_project_name(prepared)
	prepared["metadata"] = metadata
	CCFProjectLifecycleService.sync_project_name(prepared)
	super.load_project(prepared, template, settings)
	_apply_draft_placeholders()


func save_project() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	var prepared := CCFProjectLifecycleService.prepare_for_save(
		_project_container, _active_character_id
	)
	if not bool(prepared.get("ok", false)):
		_status.text = str(prepared.get("error", "This Character Project is not ready to save."))
		return
	var prepared_active := str(prepared.get("active_character_id", _active_character_id))
	var removed_count := int(prepared.get("removed_count", 0))
	var result := CCFStorageService.save_project(_project_container)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not save project."))
		return
	_active_character_id = prepared_active
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	var generation = _project.get("generation", {})
	var template_id := str(generation.get("template_id", "default")) if generation is Dictionary else "default"
	_template = CCFTemplateService.load_template(template_id)
	_dirty = false
	_populate_project_controls()
	_populate_template_selector()
	_rebuild_form()
	_update_header()
	_update_project_level_window_contexts()
	_status.text = "Saved at %s" % Time.get_time_string_from_system()
	if removed_count > 0:
		_status.text += " Discarded %d empty character draft%s." % [
			removed_count, "" if removed_count == 1 else "s"
		]
	project_saved.emit(_project_container.duplicate(true))


func _populate_project_controls() -> void:
	super._populate_project_controls()
	if _project_container.is_empty():
		return
	_loading_project_controls = true
	_loading_character_selector = true
	var metadata = _project_container.get("metadata", {})
	var manual := bool(metadata.get("name_is_manual", false)) if metadata is Dictionary else false
	if not manual:
		_project_name_edit.text = CCFProjectLifecycleService.automatic_project_name(_project_container)
	_project_name_edit.placeholder_text = "Project name — defaults to the first character's first name"
	for item_index in range(_character_selector.item_count):
		var item_text := _character_selector.get_item_text(item_index)
		var base_text := item_text.get_slice(" — ", 0).strip_edges()
		if CCFProjectLifecycleService.is_placeholder_character_name(base_text):
			var suffix := ""
			if item_text.contains(" — "):
				suffix = " — " + item_text.get_slice(" — ", 1)
			_character_selector.set_item_text(item_index, "New Character" + suffix)
	_loading_character_selector = false
	_loading_project_controls = false


func _capture_project_name() -> void:
	if _project_container.is_empty() or _project_name_edit == null:
		return
	var metadata: Dictionary = _project_container.get("metadata", {}).duplicate(true)
	var manual := bool(metadata.get("name_is_manual", false))
	var entered := _project_name_edit.text.strip_edges()
	if manual and not entered.is_empty():
		metadata["name"] = entered
		metadata["name_is_manual"] = true
		_project_container["metadata"] = metadata
		return
	metadata["name_is_manual"] = false
	_project_container["metadata"] = metadata
	CCFProjectLifecycleService.sync_project_name(_project_container)


func _on_project_name_changed(new_text: String) -> void:
	if _loading_project_controls or _project_container.is_empty():
		return
	var metadata: Dictionary = _project_container.get("metadata", {}).duplicate(true)
	var entered := new_text.strip_edges()
	if entered.is_empty():
		metadata["name_is_manual"] = false
		metadata["name"] = ""
		_project_container["metadata"] = metadata
		CCFProjectLifecycleService.sync_project_name(_project_container)
	else:
		metadata["name_is_manual"] = true
		metadata["name"] = entered
		_project_container["metadata"] = metadata
	_mark_dirty()


func _add_character() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	var character_id := CCFStorageService.add_character(
		_project_container, "Untitled Character"
	)
	_blank_character_name(character_id)
	_dirty = true
	_switch_active_character(character_id)
	_status.text = "New character draft added. It will not be saved until it has real character content and a name."


func _show_generation_preview(
	generated: Dictionary, metadata: Dictionary, preview_title: String
) -> void:
	var filtered := generated.duplicate(true)
	for raw_key in generated.keys():
		var value: Variant = generated.get(raw_key)
		if value == null:
			filtered.erase(raw_key)
			continue
		if value is String and value.strip_edges().to_lower() == "<null>":
			filtered.erase(raw_key)
	super._show_generation_preview(filtered, metadata, preview_title)


func _apply_draft_placeholders() -> void:
	if _project_name_edit != null:
		_project_name_edit.placeholder_text = "Project name — defaults to the first character's first name"
	var name_row = _field_controls.get("character.name", {})
	if name_row is Dictionary:
		var control: Control = name_row.get("control")
		if control is LineEdit and CCFProjectLifecycleService.is_placeholder_character_name(control.text):
			control.text = ""
			control.placeholder_text = "Character name"


func _blank_character_name(character_id: String) -> void:
	var index := CCFStorageService.character_index(_project_container, character_id)
	if index < 0:
		return
	var characters: Array = _project_container.get("characters", []).duplicate(true)
	var character: Dictionary = characters[index].duplicate(true)
	var metadata: Dictionary = character.get("metadata", {}).duplicate(true)
	var card: Dictionary = character.get("character", {}).duplicate(true)
	metadata["name"] = ""
	card["name"] = ""
	character["metadata"] = metadata
	character["character"] = card
	characters[index] = character
	_project_container["characters"] = characters
