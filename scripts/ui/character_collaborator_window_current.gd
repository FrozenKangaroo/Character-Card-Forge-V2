class_name CCFCharacterCollaboratorWindowCurrent
extends "res://scripts/ui/character_collaborator_window_v0171.gd"

const SAFE_HANDOFF_V02115 = preload(
	"res://scripts/services/collaborator_safe_handoff_service_v02115.gd"
)

var _safe_handoff_v02115: Dictionary = {}


func open_for_project(
	project: Dictionary,
	settings: Dictionary,
	character_id: String,
	template: Dictionary
) -> void:
	_discard_safe_handoff_for_project_change_v02115(project)
	super.open_for_project(project, settings, character_id, template)


func update_project_context(
	project: Dictionary,
	settings: Dictionary,
	character_id: String,
	template: Dictionary
) -> void:
	_discard_safe_handoff_for_project_change_v02115(project)
	super.update_project_context(project, settings, character_id, template)


func _discard_safe_handoff_for_project_change_v02115(
	incoming_project: Dictionary
) -> void:
	if not bool(_safe_handoff_v02115.get("active", false)):
		return
	var origin_id := str(_safe_handoff_v02115.get("project_id", "")).strip_edges()
	var incoming_id := str(incoming_project.get("project_id", "")).strip_edges()
	if origin_id == incoming_id:
		return
	_safe_handoff_v02115.clear()
	_active_collaborator_job_type_v0153 = ""
	if _generation_service != null and _generation_service.has_active_job():
		_generation_service.cancel_active_job()


func set_generation_service(service: CCFGenerationService) -> void:
	var previous := _generation_service
	if (
		previous != null
		and previous.job_cancelled.is_connected(
			_on_safe_handoff_cancelled_v02115
		)
	):
		previous.job_cancelled.disconnect(_on_safe_handoff_cancelled_v02115)
	super.set_generation_service(service)
	if (
		_generation_service != null
		and not _generation_service.job_cancelled.is_connected(
			_on_safe_handoff_cancelled_v02115
		)
	):
		_generation_service.job_cancelled.connect(
			_on_safe_handoff_cancelled_v02115
		)


func _on_safe_handoff_cancelled_v02115(
	_job_id: String, _job_type: String
) -> void:
	if not bool(_safe_handoff_v02115.get("active", false)):
		return
	_safe_handoff_v02115.clear()
	_active_collaborator_job_type_v0153 = ""
	_status.text = "Collaborator Workspace handoff cancelled. No Workspace data was changed."
	_refresh_all()


func _generate_character() -> void:
	var strategy := SAFE_HANDOFF_V02115.strategy_from_settings(_settings)
	if strategy != SAFE_HANDOFF_V02115.STRATEGY_SAFE_SECTION:
		super._generate_character()
		return
	if _generation_service == null or _generation_service.has_active_job():
		return
	if not _can_send_with_context_budget():
		return
	var session := _active_session()
	if session.is_empty():
		return
	var selected_mode := HANDOFF_BLUEPRINT_V01515
	if _handoff_mode_v01515 != null:
		selected_mode = _handoff_mode_v01515.get_selected_id()
	var generation_value: Variant = _settings.get("generation", {})
	var generation: Dictionary = (
		generation_value if generation_value is Dictionary else {}
	)
	_safe_handoff_v02115 = {
		"active": true,
		"project_id": str(_project.get("project_id", "")).strip_edges(),
		"mode": selected_mode,
		"section_index": 0,
		"sections": [],
		"tail_recovery_attempted": false,
		"messages": _active_messages_for_model(),
		"context_blocks": _context_blocks(),
		"memory_summary": str(session.get("memory_summary", "")),
		"profile": CCFCollaboratorTokenBudgetCurrent.request_profile(
			CCFSettingsService.profile_for_role(
				_settings, CCFSettingsService.ROLE_TEXT
			)
		),
		"retry_count": int(generation.get("retry_count", 1)),
		"session_id": str(session.get("session_id", "")),
		"session_title": str(session.get("title", "Character Collaboration")),
		"fields": {},
	}
	_queue_safe_blueprint_section_v02115()


func _queue_safe_blueprint_section_v02115() -> void:
	if not bool(_safe_handoff_v02115.get("active", false)):
		return
	var index := int(_safe_handoff_v02115.get("section_index", 0))
	var sections_value: Variant = _safe_handoff_v02115.get("sections", [])
	var sections: Array = sections_value if sections_value is Array else []
	var accepted := ""
	if not sections.is_empty():
		accepted = SAFE_HANDOFF_V02115.assembled_accepted_sections(sections)
	var result: Dictionary = _generation_service.call(
		"queue_collaborator_blueprint_section_v02115",
		_safe_handoff_v02115.get("messages", []),
		_safe_handoff_v02115.get("context_blocks", []),
		str(_safe_handoff_v02115.get("memory_summary", "")),
		index,
		accepted,
		_safe_handoff_v02115.get("profile", {}),
		int(_safe_handoff_v02115.get("retry_count", 1)),
		str(_safe_handoff_v02115.get("session_id", "")),
		(
			"detailed_workspace_draft"
			if int(_safe_handoff_v02115.get("mode", 0)) == HANDOFF_DETAILED_DRAFT_V01515
			else "blueprint"
		)
	) as Dictionary
	if not bool(result.get("ok", false)):
		_fail_safe_handoff_v02115(
			str(result.get("error", "Could not queue Collaborator blueprint section."))
		)
		return
	_status.text = "Safe Section Build: generating blueprint section %d/%d — %s." % [
		index + 1,
		SAFE_HANDOFF_V02115.BLUEPRINT_SECTIONS.size(),
		SAFE_HANDOFF_V02115.section_heading(index).capitalize(),
	]
	_refresh_action_state()


func _on_generation_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	match job_type:
		"collaborator_blueprint_section_v02115":
			_handle_safe_blueprint_section_v02115(data, metadata)
			return
		"collaborator_safe_detailed_fields_v02115":
			_handle_safe_detailed_fields_v02115(data)
			return
		"collaborator_safe_supplement_v02115":
			_handle_safe_supplement_v02115(data)
			return
	super._on_generation_completed(job_id, job_type, data, metadata)


func _handle_safe_blueprint_section_v02115(
	data: Variant, metadata: Dictionary
) -> void:
	_active_collaborator_job_type_v0153 = ""
	if not bool(_safe_handoff_v02115.get("active", false)):
		return
	if not data is Dictionary:
		_fail_safe_handoff_v02115(
			"Safe Section Build returned an invalid blueprint section. No Workspace data was changed."
		)
		return
	var section_text := str((data as Dictionary).get("section_text", "")).strip_edges()
	if section_text.is_empty():
		_fail_safe_handoff_v02115(
			"Safe Section Build returned an empty %s section. No Workspace data was changed."
			% str(metadata.get("collaborator_section_heading_v02115", "blueprint"))
		)
		return
	var sections_value: Variant = _safe_handoff_v02115.get("sections", [])
	var sections: Array = sections_value.duplicate(true) if sections_value is Array else []
	sections.append(section_text)
	_safe_handoff_v02115["sections"] = sections
	var next_index := int(_safe_handoff_v02115.get("section_index", 0)) + 1
	_safe_handoff_v02115["section_index"] = next_index
	if next_index < SAFE_HANDOFF_V02115.BLUEPRINT_SECTIONS.size():
		_queue_safe_blueprint_section_v02115()
		return
	var concept := SAFE_HANDOFF_V02115.assembled_blueprint(sections)
	var assessment := SAFE_HANDOFF_V02115.assess_blueprint(concept)
	if not bool(assessment.get("complete", false)):
		if not bool(_safe_handoff_v02115.get("tail_recovery_attempted", false)):
			var problem_index := clampi(
				int(assessment.get("first_problem_index", 0)),
				0,
				SAFE_HANDOFF_V02115.BLUEPRINT_SECTIONS.size() - 1
			)
			var accepted_prefix_sections := (
				SAFE_HANDOFF_V02115.accepted_sections_before_problem(
					sections, assessment
				)
			)
			_safe_handoff_v02115["tail_recovery_attempted"] = true
			_safe_handoff_v02115["sections"] = accepted_prefix_sections
			_safe_handoff_v02115["section_index"] = problem_index
			_status.text = (
				"Safe Section Build detected an incomplete %s section; rebuilding that section onward once."
				% str(assessment.get("first_problem_heading", "Generation Concept"))
			)
			_queue_safe_blueprint_section_v02115()
			return
		_fail_safe_handoff_v02115(
			"Safe Section Build could not complete %s after one bounded tail rebuild. No Workspace data was changed."
			% str(assessment.get("first_problem_heading", "the Generation Concept"))
		)
		return
	_safe_handoff_v02115["concept_prompt"] = concept
	if int(_safe_handoff_v02115.get("mode", 0)) == HANDOFF_BLUEPRINT_V01515:
		_finish_safe_blueprint_handoff_v02115()
	else:
		_queue_safe_detailed_fields_v02115()


func _finish_safe_blueprint_handoff_v02115() -> void:
	var payload := {
		"suggested_name": "",
		"concept_prompt": str(_safe_handoff_v02115.get("concept_prompt", "")),
		"alternate_greetings": [],
		"lorebook": {"name": "", "entries": []},
		"handoff_mode": "blueprint",
		"handoff_build_strategy": SAFE_HANDOFF_V02115.STRATEGY_SAFE_SECTION,
	}
	var title := str(
		_safe_handoff_v02115.get("session_title", "Character Collaboration")
	)
	_safe_handoff_v02115.clear()
	character_draft_ready.emit(payload, title)
	_status.text = (
		"Safe Section Generation Blueprint sent to Workspace. Review the Generation Concept, then use Generate Character when ready."
	)
	_refresh_all()
	call_deferred("_scroll_chat_to_bottom")


func _queue_safe_detailed_fields_v02115() -> void:
	var result: Dictionary = _generation_service.call(
		"queue_collaborator_safe_detailed_v02115",
		str(_safe_handoff_v02115.get("concept_prompt", "")),
		_template,
		_safe_handoff_v02115.get("profile", {}),
		int(_safe_handoff_v02115.get("retry_count", 1)),
		str(_safe_handoff_v02115.get("session_id", ""))
	) as Dictionary
	if not bool(result.get("ok", false)):
		_fail_safe_handoff_v02115(
			str(result.get("error", "Could not queue detailed Safe Section Workspace fields."))
		)
		return
	_status.text = (
		"Safe Section Build: blueprint complete; building validated Workspace fields one section at a time."
	)


func _handle_safe_detailed_fields_v02115(data: Variant) -> void:
	_active_collaborator_job_type_v0153 = ""
	if not bool(_safe_handoff_v02115.get("active", false)):
		return
	if not data is Dictionary or not (data as Dictionary).get("fields", {}) is Dictionary:
		_fail_safe_handoff_v02115(
			"Detailed Safe Section Build returned invalid Workspace fields. No Workspace data was changed."
		)
		return
	_safe_handoff_v02115["fields"] = (
		(data as Dictionary).get("fields", {}) as Dictionary
	).duplicate(true)
	var result: Dictionary = _generation_service.call(
		"queue_collaborator_safe_supplement_v02115",
		str(_safe_handoff_v02115.get("concept_prompt", "")),
		_safe_handoff_v02115.get("profile", {}),
		int(_safe_handoff_v02115.get("retry_count", 1)),
		str(_safe_handoff_v02115.get("session_id", ""))
	) as Dictionary
	if not bool(result.get("ok", false)):
		_fail_safe_handoff_v02115(
			str(result.get("error", "Could not materialise Blueprint supplementary data."))
		)
		return
	_status.text = (
		"Safe Section Build: Workspace fields complete; materialising Alternative Greetings and Lorebook."
	)


func _handle_safe_supplement_v02115(data: Variant) -> void:
	_active_collaborator_job_type_v0153 = ""
	if not bool(_safe_handoff_v02115.get("active", false)):
		return
	if not data is Dictionary:
		_fail_safe_handoff_v02115(
			"Blueprint supplementary material was invalid. No Workspace data was changed."
		)
		return
	var supplement: Dictionary = data
	var payload := {
		"concept_prompt": str(_safe_handoff_v02115.get("concept_prompt", "")),
		"fields": (_safe_handoff_v02115.get("fields", {}) as Dictionary).duplicate(true),
		"alternate_greetings": supplement.get("alternate_greetings", []),
		"lorebook": supplement.get("lorebook", {"name": "", "entries": []}),
		"handoff_mode": "detailed_workspace_draft",
		"handoff_build_strategy": SAFE_HANDOFF_V02115.STRATEGY_SAFE_SECTION,
	}
	var title := str(
		_safe_handoff_v02115.get("session_title", "Character Collaboration")
	)
	_safe_handoff_v02115.clear()
	character_draft_ready.emit(payload, title)
	_status.text = (
		"Detailed Safe Section character draft, Alternative Greetings and Lorebook sent to Workspace."
	)
	_refresh_all()
	call_deferred("_scroll_chat_to_bottom")


func _on_generation_failed(
	job_id: String, job_type: String, message: String
) -> void:
	if job_type in [
		"collaborator_blueprint_section_v02115",
		"collaborator_safe_detailed_fields_v02115",
		"collaborator_safe_supplement_v02115",
	]:
		_safe_handoff_v02115.clear()
	super._on_generation_failed(job_id, job_type, message)


func _working_text_v0153() -> String:
	match _active_collaborator_job_type_v0153:
		"collaborator_blueprint_section_v02115":
			return "Safe Section Build is writing one complete Generation Concept section…"
		"collaborator_safe_detailed_fields_v02115":
			return "Safe Section Build is materialising validated Workspace fields…"
		"collaborator_safe_supplement_v02115":
			return "Safe Section Build is materialising Alternative Greetings and Lorebook…"
	return super._working_text_v0153()


func _refresh_action_state() -> void:
	super._refresh_action_state()
	if _handoff_mode_v01515 != null:
		_handoff_mode_v01515.disabled = (
			_handoff_mode_v01515.disabled
			or bool(_safe_handoff_v02115.get("active", false))
		)
	if _generate_button != null and bool(_safe_handoff_v02115.get("active", false)):
		_generate_button.disabled = true


func _fail_safe_handoff_v02115(message: String) -> void:
	_safe_handoff_v02115.clear()
	_active_collaborator_job_type_v0153 = ""
	_status.text = message
	_refresh_all()
