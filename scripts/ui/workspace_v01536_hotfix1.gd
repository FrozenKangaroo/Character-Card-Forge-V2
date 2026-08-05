class_name CCFWorkspaceV01536Hotfix1View
extends "res://scripts/ui/workspace_v01536.gd"


func _add_character() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	var character_number: int = int(_project_container.get("characters", []).size()) + 1
	var character_id := CCFStorageService.add_character(
		_project_container, "Untitled Character %d" % character_number
	)
	var template_id := CCFTemplatePreferenceService.default_template_id(_settings)
	CCFTemplatePreferenceService.assign_character_template(
		_project_container,
		character_id,
		template_id
	)
	_dirty = true
	_switch_active_character(character_id)
	_status.text = (
		"New character added using the configured default template: %s."
		% str(_template.get("name", "Template"))
	)


func refresh_templates() -> void:
	if _project.is_empty():
		_populate_template_selector()
		return
	_capture_all_fields()
	var generation: Dictionary = _project.get("generation", {}).duplicate(true)
	var requested_id := str(generation.get("template_id", "default"))
	var available := false
	for summary in CCFTemplateService.list_templates():
		if summary is Dictionary and str(summary.get("template_id", "")) == requested_id:
			available = true
			break
	if not available:
		requested_id = CCFTemplatePreferenceService.default_template_id(_settings)
		generation["template_id"] = requested_id
		_project["generation"] = generation
		_dirty = true
	_template = CCFTemplateService.load_template(requested_id)
	_populate_template_selector()
	_rebuild_form()
	_update_header()
	if (
		_controlled_build_window != null
		and _controlled_build_window.owns_project(str(_project.get("project_id", "")))
	):
		_controlled_build_window.update_project_context(_project, _template, _settings)
