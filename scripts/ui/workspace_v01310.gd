class_name CCFWorkspaceV01310View
extends CCFWorkspaceV0138View


func _add_character() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	var character_id := CCFStorageService.add_character(
		_project_container, "Untitled Character"
	)
	var default_template_id := CCFTemplatePreferenceService.default_template_id(_settings)
	CCFTemplatePreferenceService.assign_character_template(
		_project_container, character_id, default_template_id
	)
	_blank_character_name(character_id)
	_dirty = true
	_switch_active_character(character_id)
	_status.text = "New character draft added with default template '%s'. It will not be saved until it has real character content and a name." % str(_template.get("name", "Default Character Card"))
