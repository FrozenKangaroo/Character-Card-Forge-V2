class_name CCFWorkspaceV01517View
extends "res://scripts/ui/workspace_v01516.gd"

const GENERATION_SERVICE_V01517 = preload("res://scripts/services/generation_service_v01517.gd")


func _install_generation_service_v015() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V01517:
		return
	if previous_service != null:
		if previous_service.job_started.is_connected(_on_job_started):
			previous_service.job_started.disconnect(_on_job_started)
		if previous_service.job_completed.is_connected(_on_job_completed):
			previous_service.job_completed.disconnect(_on_job_completed)
		if previous_service.job_failed.is_connected(_on_job_failed):
			previous_service.job_failed.disconnect(_on_job_failed)
		if previous_service.job_cancelled.is_connected(_on_job_cancelled):
			previous_service.job_cancelled.disconnect(_on_job_cancelled)
		if previous_service.queue_changed.is_connected(_on_queue_changed):
			previous_service.queue_changed.disconnect(_on_queue_changed)
		if previous_service.get_parent() == self:
			remove_child(previous_service)
		previous_service.queue_free()

	var upgraded: CCFGenerationService = GENERATION_SERVICE_V01517.new()
	add_child(upgraded)
	upgraded.job_started.connect(_on_job_started)
	upgraded.job_completed.connect(_on_job_completed)
	upgraded.job_failed.connect(_on_job_failed)
	upgraded.job_cancelled.connect(_on_job_cancelled)
	upgraded.queue_changed.connect(_on_queue_changed)
	_generation_service = upgraded

	for client in [
		_builder_window,
		_controlled_build_window,
		_group_scene_window,
		_relationship_window,
		_card_workflow_window,
		_attachment_window,
		_character_collaborator_window
	]:
		if client != null and client.has_method("set_generation_service"):
			client.call("set_generation_service", _generation_service)
	_wire_ai_idea_controller_to_current_service()


func _ensure_collaborator_generation_service_v015() -> bool:
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01517:
		_install_generation_service_v015()
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01517:
		_status.text = "Character Collaborator could not activate the v0.15.17 generation service."
		return false
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(_generation_service)
	return true


func _apply_collaborator_blueprint_v01515(payload: Dictionary, session_title: String) -> void:
	if _project_container.is_empty():
		return
	var concept_prompt := str(payload.get("concept_prompt", "")).strip_edges()
	if concept_prompt.is_empty():
		_status.text = "Character Collaborator returned a Blueprint without a usable Generation Concept."
		return

	var suggested_name := str(payload.get("suggested_name", "")).strip_edges()
	var fallback_name := session_title.strip_edges()
	if fallback_name.is_empty():
		fallback_name = "Collaborator Character"
	var display_name := suggested_name if not suggested_name.is_empty() else fallback_name
	var created := CCFStorageService.new_character_record(display_name)
	CCFStorageService.set_value_at_path(created, "concept.prompt", concept_prompt)
	CCFStorageService.set_value_at_path(created, "metadata.name", display_name)
	CCFStorageService.set_value_at_path(created, "character.name", display_name)
	CCFStorageService.set_value_at_path(
		created, "generation.template_id", _active_template_id_v01517()
	)

	var alternatives := _normalise_alternative_greetings_v01517(
		payload.get("alternate_greetings", [])
	)
	CCFStorageService.set_value_at_path(
		created, "character.alternate_greetings", alternatives
	)
	var lorebook := _normalise_lorebook_v01517(payload.get("lorebook", {}))
	CCFStorageService.set_value_at_path(created, "character.character_book", lorebook)
	var lore_count := _lorebook_entry_count_v01515(lorebook)

	var provenance: Dictionary = created.get("provenance", {}).duplicate(true)
	provenance["character_collaborator"] = {
		"source": "character_collaborator_v01517",
		"handoff_mode": "blueprint",
		"session_title": session_title,
		"generated_at": Time.get_datetime_string_from_system(true),
		"template_id": _active_template_id_v01517(),
		"structured_supplements": true,
		"alternate_greetings_count": alternatives.size(),
		"lorebook_entries_count": lore_count
	}
	created["provenance"] = provenance

	var characters: Array = _project_container.get("characters", []).duplicate(true)
	characters.append(created)
	_project_container["characters"] = characters
	_dirty = true
	_switch_active_character(str(created.get("character_id", "")))
	_status.text = (
		"%s was created from the Collaborator as a detailed Generation Blueprint using template '%s', with %d Alternative Greeting(s) and %d Lorebook entr%s materialised alongside it. Review the source and supplementary material, then use Generate Character to materialise the validated template fields."
		% [
			display_name,
			_active_template_id_v01517(),
			alternatives.size(),
			lore_count,
			"y" if lore_count == 1 else "ies"
		]
	)


func _apply_collaborator_detailed_draft_v01515(payload: Dictionary, session_title: String) -> void:
	if _project_container.is_empty():
		return
	var fields_value: Variant = payload.get("fields", {})
	if not fields_value is Dictionary:
		_status.text = "Character Collaborator returned a detailed draft without usable template fields."
		return
	var fields: Dictionary = fields_value
	var fallback_name := session_title.strip_edges()
	if fallback_name.is_empty():
		fallback_name = "Collaborator Character"
	var created := CCFStorageService.new_character_record(fallback_name)
	CCFStorageService.set_value_at_path(
		created, "generation.template_id", _active_template_id_v01517()
	)
	var generated_name := str(payload.get("suggested_name", "")).strip_edges()

	for raw_field in CCFTemplateService.generation_fields(_template):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_id := str(field.get("id", "")).strip_edges()
		var field_path := str(field.get("path", "")).strip_edges()
		if field_id.is_empty() or field_path.is_empty() or not fields.has(field_id):
			continue
		var value: Variant = fields.get(field_id)
		CCFStorageService.set_value_at_path(created, field_path, value)
		if field_path in ["character.name", "metadata.name"]:
			generated_name = str(value).strip_edges()

	var concept_prompt := str(payload.get("concept_prompt", "")).strip_edges()
	if not concept_prompt.is_empty():
		CCFStorageService.set_value_at_path(created, "concept.prompt", concept_prompt)

	var alternatives := _normalise_alternative_greetings_v01517(
		payload.get("alternate_greetings", [])
	)
	CCFStorageService.set_value_at_path(
		created, "character.alternate_greetings", alternatives
	)
	var lorebook := _normalise_lorebook_v01517(payload.get("lorebook", {}))
	CCFStorageService.set_value_at_path(created, "character.character_book", lorebook)
	var lore_count := _lorebook_entry_count_v01515(lorebook)

	if generated_name.is_empty():
		generated_name = str(
			CCFStorageService.get_value_at_path(created, "character.name", "")
		).strip_edges()
	if generated_name.is_empty():
		generated_name = fallback_name
	CCFStorageService.set_value_at_path(created, "metadata.name", generated_name)
	CCFStorageService.set_value_at_path(created, "character.name", generated_name)

	var provenance: Dictionary = created.get("provenance", {}).duplicate(true)
	provenance["character_collaborator"] = {
		"source": "character_collaborator_v01517",
		"handoff_mode": "detailed_workspace_draft",
		"session_title": session_title,
		"generated_at": Time.get_datetime_string_from_system(true),
		"template_id": _active_template_id_v01517(),
		"structured_supplements": true,
		"alternate_greetings_count": alternatives.size(),
		"lorebook_entries_count": lore_count
	}
	created["provenance"] = provenance

	var characters: Array = _project_container.get("characters", []).duplicate(true)
	characters.append(created)
	_project_container["characters"] = characters
	_dirty = true
	_switch_active_character(str(created.get("character_id", "")))
	_status.text = (
		"Character Collaborator created a detailed Workspace draft for %s using template '%s', with %d Alternative Greeting(s) and %d Lorebook entr%s. Review/edit before saving."
		% [
			generated_name,
			_active_template_id_v01517(),
			alternatives.size(),
			lore_count,
			"y" if lore_count == 1 else "ies"
		]
	)


func _generate_character() -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var generation_settings := _generation_settings()
	var retry_count := int(generation_settings.get("retry_count", 1))

	var supplement_request := _blueprint_supplement_request_v01517()
	var supplement_queued := false
	var supplement_error := ""
	if bool(supplement_request.get("needed", false)):
		var supplement_result: Dictionary = _generation_service.call(
			"queue_blueprint_supplemental_material",
			_project,
			profile,
			retry_count,
			bool(supplement_request.get("fill_alternate_greetings", false)),
			bool(supplement_request.get("fill_lorebook", false))
		)
		supplement_queued = bool(supplement_result.get("ok", false))
		if not supplement_queued:
			supplement_error = str(
				supplement_result.get(
					"error", "Could not queue Blueprint supplementary materialisation."
				)
			)

	var result: Dictionary = _generation_service.queue_character_generation(
		_project,
		_template,
		profile,
		true,
		retry_count
	)
	if not bool(result.get("ok", false)):
		_status.text = str(
			result.get("error", "Could not queue validated character generation.")
		)
		if supplement_queued:
			_status.text += " Blueprint supplementary material is still queued independently."
		return

	var queued_ahead := int(result.get("queued_ahead", 0))
	if supplement_queued:
		_status.text = (
			"Blueprint supplementary materialisation queued first; validated template-driven character generation is queued behind it. Interview/Q&A, Generation Components and the active template contract will be preserved through review."
		)
	elif not supplement_error.is_empty():
		_status.text = (
			"Validated template-driven character generation queued%s. Blueprint supplementary material could not be queued: %s"
			% [
				" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "",
				supplement_error
			]
		)
	else:
		_status.text = (
			"Validated template-driven character generation queued%s. Generation Components, Interview/Q&A and the active template contract will be checked before anything reaches Generation Preview."
			% (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
		)


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	if job_type != "blueprint_supplemental_material":
		super._on_job_completed(job_id, job_type, data, metadata)
		return

	if not data is Dictionary:
		_status.text = "Blueprint supplementary material returned an invalid payload; normal character generation can continue."
		return

	var changed := false
	if bool(metadata.get("fill_alternate_greetings", false)):
		var current_alternatives: Variant = CCFStorageService.get_value_at_path(
			_project, "character.alternate_greetings", []
		)
		if not current_alternatives is Array or current_alternatives.is_empty():
			var alternatives := _normalise_alternative_greetings_v01517(
				(data as Dictionary).get("alternate_greetings", [])
			)
			CCFStorageService.set_value_at_path(
				_project, "character.alternate_greetings", alternatives
			)
			changed = true

	if bool(metadata.get("fill_lorebook", false)):
		var current_lorebook: Variant = CCFStorageService.get_value_at_path(
			_project, "character.character_book", {}
		)
		if _lorebook_entry_count_v01515(current_lorebook) == 0:
			var lorebook := _normalise_lorebook_v01517(
				(data as Dictionary).get("lorebook", {})
			)
			CCFStorageService.set_value_at_path(
				_project, "character.character_book", lorebook
			)
			changed = true

	var provenance_value: Variant = _project.get("provenance", {})
	var provenance: Dictionary = (
		provenance_value.duplicate(true) if provenance_value is Dictionary else {}
	)
	var collaborator_value: Variant = provenance.get("character_collaborator", {})
	var collaborator: Dictionary = (
		collaborator_value.duplicate(true) if collaborator_value is Dictionary else {}
	)
	collaborator["structured_supplements"] = true
	collaborator["supplements_materialised_at"] = Time.get_datetime_string_from_system(true)
	collaborator["alternate_greetings_count"] = _alternative_greeting_count_v01517(
		CCFStorageService.get_value_at_path(_project, "character.alternate_greetings", [])
	)
	collaborator["lorebook_entries_count"] = _lorebook_entry_count_v01515(
		CCFStorageService.get_value_at_path(_project, "character.character_book", {})
	)
	provenance["character_collaborator"] = collaborator
	_project["provenance"] = provenance
	changed = true

	if changed:
		_dirty = true
		if _alternate_editors != null:
			_load_alternative_greetings_controls()
	_status.text = "Blueprint Alternative Greetings/Lorebook materialised into the character. Validated character generation is continuing."


func _active_template_id_v01517() -> String:
	var template_id := str(_template.get("template_id", "default")).strip_edges()
	return template_id if not template_id.is_empty() else "default"


func _normalise_alternative_greetings_v01517(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for raw_greeting in value:
		var greeting := str(raw_greeting).strip_edges()
		if not greeting.is_empty():
			result.append(greeting)
	return result


func _normalise_lorebook_v01517(value: Variant) -> Dictionary:
	var lorebook: Dictionary = value.duplicate(true) if value is Dictionary else {}
	var name := str(lorebook.get("name", "Character Lorebook")).strip_edges()
	if name.is_empty():
		name = "Character Lorebook"
	lorebook["name"] = name
	var entries_value: Variant = lorebook.get("entries", [])
	if not entries_value is Array:
		lorebook["entries"] = []
	return lorebook


func _alternative_greeting_count_v01517(value: Variant) -> int:
	if not value is Array:
		return 0
	var count := 0
	for raw_greeting in value:
		if not str(raw_greeting).strip_edges().is_empty():
			count += 1
	return count


func _blueprint_supplement_request_v01517() -> Dictionary:
	var provenance_value: Variant = _project.get("provenance", {})
	if not provenance_value is Dictionary:
		return {"needed": false}
	var collaborator_value: Variant = (provenance_value as Dictionary).get(
		"character_collaborator", {}
	)
	if not collaborator_value is Dictionary:
		return {"needed": false}
	var collaborator: Dictionary = collaborator_value
	if str(collaborator.get("handoff_mode", "")) != "blueprint":
		return {"needed": false}
	if bool(collaborator.get("structured_supplements", false)):
		return {"needed": false}

	var alternatives_value: Variant = CCFStorageService.get_value_at_path(
		_project, "character.alternate_greetings", []
	)
	var fill_alternatives := _alternative_greeting_count_v01517(alternatives_value) == 0
	var lorebook_value: Variant = CCFStorageService.get_value_at_path(
		_project, "character.character_book", {}
	)
	var fill_lorebook := _lorebook_entry_count_v01515(lorebook_value) == 0
	return {
		"needed": fill_alternatives or fill_lorebook,
		"fill_alternate_greetings": fill_alternatives,
		"fill_lorebook": fill_lorebook
	}
