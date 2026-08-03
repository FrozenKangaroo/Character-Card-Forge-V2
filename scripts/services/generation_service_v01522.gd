class_name CCFGenerationServiceV01522
extends "res://scripts/services/generation_service_v01517.gd"

signal diagnostics_available(job_id: String, job_type: String, diagnostics: Dictionary)

const GENERATION_STRATEGY_SAFE_SECTION := "safe_section"
const GENERATION_STRATEGY_FAST_FULL := "fast_full"
const DEFAULT_GENERATION_STRATEGY := GENERATION_STRATEGY_SAFE_SECTION
const DIAGNOSTIC_FORMAT_VERSION := 1
const DIAGNOSTIC_HISTORY_LIMIT := 12
const SAFE_COMPONENT_REPAIR_LIMIT := 1
const SAFE_FIELD_REPAIR_LIMIT := 1

var _pending_generation_strategy_v01522 := ""
var _pending_safe_context_v01522: Dictionary = {}
var _diagnostic_history_v01522: Array[Dictionary] = []
var _failed_diagnostics_by_job_v01522: Dictionary = {}


func queue_character_generation_with_strategy(
	project: Dictionary,
	template: Dictionary,
	profile: Dictionary,
	include_existing_fields: bool,
	retry_count: int,
	strategy: String
) -> Dictionary:
	var resolved_strategy := normalise_generation_strategy_v01522(strategy)
	_pending_generation_strategy_v01522 = resolved_strategy
	_pending_safe_context_v01522 = {
		"project": project.duplicate(true),
		"template": template.duplicate(true),
		"include_existing_fields": include_existing_fields
	}
	var result: Dictionary = super.queue_character_generation(
		project, template, profile, include_existing_fields, retry_count
	)
	var pending_context := _pending_safe_context_v01522.duplicate(true)
	_pending_generation_strategy_v01522 = ""
	_pending_safe_context_v01522 = {}
	if not bool(result.get("ok", false)):
		return result
	var job_id := str(result.get("job_id", ""))
	if not job_id.is_empty():
		_decorate_strategy_job_v01522(job_id, resolved_strategy, pending_context)
	return result


func generation_plan_v01522(template: Dictionary) -> Array:
	var groups_by_field: Dictionary = {}
	for raw_group in CCFTemplateService.enabled_generation_groups(template):
		if not raw_group is Dictionary:
			continue
		var group: Dictionary = raw_group
		var output_field_id := str(group.get("output_field_id", "")).strip_edges()
		if output_field_id.is_empty():
			continue
		if not groups_by_field.has(output_field_id):
			groups_by_field[output_field_id] = []
		var field_groups: Array = groups_by_field.get(output_field_id, [])
		field_groups.append(group.duplicate(true))
		groups_by_field[output_field_id] = field_groups

	var plan: Array = []
	for raw_field in CCFTemplateService.generation_fields(template):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_id := str(field.get("id", "")).strip_edges()
		var bound_groups_value: Variant = groups_by_field.get(field_id, [])
		if bound_groups_value is Array and not bound_groups_value.is_empty():
			for raw_bound_group in bound_groups_value:
				if not raw_bound_group is Dictionary:
					continue
				var bound_group: Dictionary = raw_bound_group
				plan.append(
					{
						"kind": "output_group",
						"id": str(bound_group.get("id", "generation_group")),
						"title": str(bound_group.get("title", field.get("label", field_id))),
						"field_id": field_id,
						"field": field.duplicate(true),
						"group": bound_group.duplicate(true)
					}
				)
			continue
		plan.append(
			{
				"kind": "standalone_field",
				"id": field_id,
				"title": str(field.get("label", field_id)),
				"field_id": field_id,
				"field": field.duplicate(true)
			}
		)
	return plan


func strategy_capabilities_v01522() -> Dictionary:
	return {
		"default": DEFAULT_GENERATION_STRATEGY,
		"strategies": [GENERATION_STRATEGY_SAFE_SECTION, GENERATION_STRATEGY_FAST_FULL],
		"safe_section_build": true,
		"output_group_sections": true,
		"standalone_field_sections": true,
		"component_level_repair": true,
		"failure_diagnostics": true
	}


func diagnostics_for_job_v01522(job_id: String) -> Dictionary:
	var value: Variant = _failed_diagnostics_by_job_v01522.get(job_id, {})
	return value.duplicate(true) if value is Dictionary else {}


func diagnostic_history_v01522() -> Array:
	return _diagnostic_history_v01522.duplicate(true)


func sanitise_diagnostic_value_v01522(value: Variant) -> Variant:
	return _sanitise_diagnostic_value_v01522(value)


static func normalise_generation_strategy_v01522(strategy: String) -> String:
	var clean := strategy.strip_edges().to_lower()
	if clean == GENERATION_STRATEGY_FAST_FULL:
		return GENERATION_STRATEGY_FAST_FULL
	return GENERATION_STRATEGY_SAFE_SECTION


func _prepare_character_stage(job_value: Dictionary) -> Dictionary:
	var job := super._prepare_character_stage(job_value)
	var strategy := str(job.get("generation_strategy", "")).strip_edges()
	if strategy.is_empty():
		strategy = _pending_generation_strategy_v01522
	strategy = normalise_generation_strategy_v01522(strategy)
	job["generation_strategy"] = strategy
	var metadata := _dictionary_copy_v01522(job.get("metadata", {}))
	metadata["generation_strategy"] = strategy
	job["metadata"] = metadata
	if strategy != GENERATION_STRATEGY_SAFE_SECTION:
		return job

	var context := _dictionary_copy_v01522(job.get("safe_generation_context", {}))
	if context.is_empty():
		context = _pending_safe_context_v01522.duplicate(true)
	job["safe_generation_context"] = context
	if job.has("safe_build_state"):
		return job
	return _initialise_safe_build_v01522(job, context)


func _decorate_strategy_job_v01522(
	job_id: String, strategy: String, safe_context: Dictionary
) -> void:
	for index in range(_queue.size()):
		var job: Dictionary = _queue[index]
		if str(job.get("id", "")) != job_id:
			continue
		_queue[index] = _job_with_strategy_v01522(job, strategy, safe_context)
		return
	if str(_active_job.get("id", "")) == job_id:
		_active_job = _job_with_strategy_v01522(_active_job, strategy, safe_context)


func _job_with_strategy_v01522(
	job_value: Dictionary, strategy: String, safe_context: Dictionary
) -> Dictionary:
	var job := job_value.duplicate(true)
	var resolved := normalise_generation_strategy_v01522(strategy)
	job["generation_strategy"] = resolved
	job["safe_generation_context"] = safe_context.duplicate(true)
	var metadata := _dictionary_copy_v01522(job.get("metadata", {}))
	metadata["generation_strategy"] = resolved
	job["metadata"] = metadata
	return job


func _initialise_safe_build_v01522(job_value: Dictionary, context: Dictionary) -> Dictionary:
	var job := job_value.duplicate(true)
	var template := _dictionary_copy_v01522(context.get("template", {}))
	if template.is_empty():
		return job
	var generation_template := _template_without_interview_sections(template)
	var plan := generation_plan_v01522(generation_template)
	if plan.is_empty():
		return job

	var state := {
		"plan": plan,
		"index": 0,
		"accepted_fields": {},
		"accepted_groups": {},
		"component_repair_attempts": {},
		"field_repair_attempts": {},
		"completed_sections": [],
		"generation_template": generation_template,
		"project": _dictionary_copy_v01522(context.get("project", {})),
		"include_existing_fields": bool(context.get("include_existing_fields", true))
	}
	job["safe_build_state"] = state
	job["safe_original_character_payload"] = _dictionary_copy_v01522(job.get("payload", {}))
	job["safe_delegate_to_parent"] = false
	job["safe_stage"] = "section"
	job["parse_mode"] = "object"
	job["attempt"] = 0
	job["repair_attempts"] = 0
	var metadata := _dictionary_copy_v01522(job.get("metadata", {}))
	metadata["generation_strategy"] = GENERATION_STRATEGY_SAFE_SECTION
	metadata["safe_section_count"] = plan.size()
	metadata["safe_section_build"] = true
	job["metadata"] = metadata
	return _job_for_safe_section_v01522(job, 0)


func _job_for_safe_section_v01522(job_value: Dictionary, section_index: int) -> Dictionary:
	var job := job_value.duplicate(true)
	var state := _dictionary_copy_v01522(job.get("safe_build_state", {}))
	var plan_value: Variant = state.get("plan", [])
	if not plan_value is Array or section_index < 0 or section_index >= plan_value.size():
		return job
	var section_value: Variant = plan_value[section_index]
	if not section_value is Dictionary:
		return job
	var section: Dictionary = section_value
	state["index"] = section_index
	job["safe_build_state"] = state
	job["safe_stage"] = "section"
	job["safe_active_section"] = section.duplicate(true)
	job.erase("safe_pending_group_components")
	job.erase("safe_pending_group_extras")
	job.erase("safe_pending_field_value")
	job["parse_mode"] = "object"
	job["attempt"] = 0
	job["repair_attempts"] = 0
	job["label"] = "Safe Section Build • %d/%d • %s" % [
		section_index + 1,
		plan_value.size(),
		str(section.get("title", "Section"))
	]
	job["payload"] = _safe_section_payload_v01522(job, section)
	return job


func _safe_section_payload_v01522(job: Dictionary, section: Dictionary) -> Dictionary:
	var base_payload := _dictionary_copy_v01522(job.get("safe_original_character_payload", job.get("payload", {})))
	var prompt := _safe_common_context_v01522(job)
	var kind := str(section.get("kind", "standalone_field"))
	if kind == "output_group":
		var group := _dictionary_copy_v01522(section.get("group", {}))
		var component_lines: Array[String] = []
		var component_ids: Array[String] = []
		for raw_component in group.get("components", []):
			if not raw_component is Dictionary or not bool(raw_component.get("enabled", true)):
				continue
			var component: Dictionary = raw_component
			var component_id := str(component.get("id", "")).strip_edges()
			if component_id.is_empty():
				continue
			component_ids.append(component_id)
			var requirement := "required" if bool(component.get("required", true)) else "optional"
			var line := "- %s => %s (%s)" % [
				component_id,
				str(component.get("label", component_id)),
				requirement
			]
			var instruction := str(component.get("instruction", "")).strip_edges()
			if not instruction.is_empty():
				line += ": %s" % instruction
			component_lines.append(line)
		prompt += (
			"\n\nSAFE SECTION BUILD — GENERATE ONLY THIS OUTPUT GROUP:\n"
			+ "Output Group: %s\nTarget Character Card field: %s\n\nCOMPONENTS:\n%s"
			% [
				str(group.get("title", section.get("title", "Output Group"))),
				str(section.get("field_id", "field")),
				_join_string_array(component_lines, "\n")
			]
		)
		prompt += "\n\nReturn one JSON object using only the component IDs above as keys. Each returned component value must be useful plain text."
		if bool(group.get("allow_extra_components", false)):
			prompt += " You may add a small number of genuinely useful extra component keys when the concept strongly benefits from them."
		else:
			prompt += " Do not add extra component keys."
		prompt += " CCF will add component labels and group headings itself, so do not put labels inside the values. Do not return the final Character Card field, other output groups, commentary, or markdown fences."
	else:
		var field := _dictionary_copy_v01522(section.get("field", {}))
		var field_id := str(section.get("field_id", field.get("id", "field")))
		var instruction := str(field.get("generation_prompt", "")).strip_edges()
		prompt += (
			"\n\nSAFE SECTION BUILD — GENERATE ONLY THIS STANDALONE FIELD:\n"
			+ "Field: %s (%s)\nType: %s\nRequired: %s"
			% [
				str(field.get("label", field_id)),
				field_id,
				_field_type_instruction(field),
				"yes" if bool(field.get("required", false)) else "no"
			]
		)
		if not instruction.is_empty():
			prompt += "\nField instruction: %s" % instruction
		prompt += "\n\nReturn one JSON object with exactly one key, `%s`, containing the proposed field value. Do not generate any other Character Card field, commentary, or markdown fences." % field_id

	base_payload["messages"] = [
		{
			"role": "system",
			"content": "You are Character Card Forge's Safe Section Build writer. Generate only the requested section, preserve the authoritative character concept and accepted continuity, and return valid JSON only."
		},
		{"role": "user", "content": prompt}
	]
	return base_payload


func _safe_common_context_v01522(job: Dictionary) -> String:
	var state := _dictionary_copy_v01522(job.get("safe_build_state", {}))
	var project := _dictionary_copy_v01522(state.get("project", {}))
	var template := _dictionary_copy_v01522(state.get("generation_template", {}))
	var metadata := _dictionary_copy_v01522(job.get("metadata", {}))
	var concept := str(metadata.get("concept", "")).strip_edges()
	if concept.is_empty():
		concept = str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()
	var prompt := "Create one section of a complete roleplay character card. Every request in this build is a fresh conversation; the character concept below remains authoritative."
	prompt += "\n\nAUTHORITATIVE CHARACTER CONCEPT:\n%s" % concept

	var global_rules: Array[String] = []
	for raw_rule in template.get("global_generation_instructions", []):
		var rule := str(raw_rule).strip_edges()
		if not rule.is_empty():
			global_rules.append(rule)
	if not global_rules.is_empty():
		prompt += "\n\nACTIVE TEMPLATE RULES:\n- %s" % _join_string_array(global_rules, "\n- ")

	var shared_context := _shared_context_text(project)
	if not shared_context.is_empty():
		prompt += "\n\nSHARED MULTI-CHARACTER PROJECT CONTEXT:\n%s" % shared_context
	var series_context := _series_context_text(project)
	if not series_context.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context
	var relationship_context := _relationship_context_text(project)
	if not relationship_context.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS:\n%s" % relationship_context
	var attachment_context := _workspace_attachment_context_text(project)
	if not attachment_context.is_empty():
		prompt += "\n\nENABLED ATTACHMENT CONTEXT:\n%s" % attachment_context

	if bool(state.get("include_existing_fields", true)):
		var existing_lines: Array[String] = []
		for raw_field in CCFTemplateService.generation_fields(template):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			var value: Variant = CCFStorageService.get_value_at_path(project, str(field.get("path", "")), "")
			var value_text := _value_to_text(value).strip_edges()
			if value_text.is_empty():
				continue
			existing_lines.append("%s: %s" % [str(field.get("label", field.get("id", "Field"))), value_text])
		if not existing_lines.is_empty():
			prompt += "\n\nEXISTING WORKSPACE VALUES — preserve when compatible with the source concept:\n%s" % _join_string_array(existing_lines, "\n\n")

	var interview_questions: Variant = job.get("interview_questions", [])
	var interview_answers: Variant = job.get("interview_answers", {})
	if interview_questions is Array and interview_answers is Dictionary:
		var interview_notes := _render_interview_notes(interview_questions, interview_answers).strip_edges()
		if not interview_notes.is_empty():
			prompt += "\n\nPRIVATE INTERVIEW / Q&A PLANNING NOTES:\n%s" % interview_notes
	var builder_text := str(job.get("builder_planning_context", "")).strip_edges()
	if not builder_text.is_empty():
		prompt += "\n\nCURRENT CHARACTER BUILDER GUIDANCE:\n%s" % builder_text
	prompt += "\n\nPLANNING PRECEDENCE: source concept > manually entered Interview/Q&A > Character Builder guidance > AI-inferred interview notes > existing card values and generic inference."

	var mode_style_value: Variant = job.get("mode_style", {})
	if mode_style_value is Dictionary:
		prompt += "\n\n%s" % _mode_style_block(mode_style_value)

	var accepted_context := _safe_accepted_context_v01522(state)
	if not accepted_context.is_empty():
		prompt += "\n\nALREADY ACCEPTED SAFE-BUILD CONTENT — continuity context only; do not regenerate it:\n%s" % accepted_context
	return prompt


func _safe_accepted_context_v01522(state: Dictionary) -> String:
	var accepted_value: Variant = state.get("accepted_fields", {})
	if not accepted_value is Dictionary or accepted_value.is_empty():
		return ""
	var accepted: Dictionary = accepted_value
	var template := _dictionary_copy_v01522(state.get("generation_template", {}))
	var lines: Array[String] = []
	for raw_field in CCFTemplateService.generation_fields(template):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_id := str(field.get("id", ""))
		if not accepted.has(field_id):
			continue
		var text := _value_to_text(accepted.get(field_id)).strip_edges()
		if not text.is_empty():
			lines.append("%s:\n%s" % [str(field.get("label", field_id)), text])
	return _join_string_array(lines, "\n\n")


func _process_completed_content(content: String) -> void:
	if _active_job.is_empty():
		return
	_active_job["diagnostics_last_assistant_text"] = content
	var parse_mode := str(_active_job.get("parse_mode", "object"))
	var diagnostic_parse := _parse_job_output_with_diagnostics(content, parse_mode)
	if bool(diagnostic_parse.get("ok", false)):
		_active_job["diagnostics_last_parsed_output"] = _sanitise_diagnostic_value_v01522(diagnostic_parse.get("data"))
	else:
		_active_job["diagnostics_last_parse_error"] = str(diagnostic_parse.get("diagnostic", "Unable to parse model output."))

	if (
		str(_active_job.get("type", "")) != "character"
		or normalise_generation_strategy_v01522(str(_active_job.get("generation_strategy", ""))) != GENERATION_STRATEGY_SAFE_SECTION
		or bool(_active_job.get("safe_delegate_to_parent", false))
	):
		super._process_completed_content(content)
		return
	var interview_stage := str(_active_job.get("interview_stage", ""))
	if interview_stage == "planning" or interview_stage == "retry":
		super._process_completed_content(content)
		return

	match str(_active_job.get("safe_stage", "section")):
		"component_repair":
			_process_safe_component_repair_v01522(content)
		"field_repair":
			_process_safe_field_repair_v01522(content)
		_:
			_process_safe_section_v01522(content)


func _process_safe_section_v01522(content: String) -> void:
	var parse_result := _parse_job_output_with_diagnostics(content, "object")
	if not bool(parse_result.get("ok", false)):
		if _start_json_repair(content, "object"):
			return
		_fail_safe_parse_v01522(parse_result)
		return
	var parsed_value: Variant = parse_result.get("data")
	if not parsed_value is Dictionary:
		_handle_failure("Safe Section Build expected a JSON object for the current section.", false)
		return
	var section := _dictionary_copy_v01522(_active_job.get("safe_active_section", {}))
	if str(section.get("kind", "standalone_field")) == "output_group":
		_process_safe_group_result_v01522(section, parsed_value)
	else:
		_process_safe_field_result_v01522(section, parsed_value)


func _process_safe_group_result_v01522(section: Dictionary, raw_data: Dictionary) -> void:
	var group := _dictionary_copy_v01522(section.get("group", {}))
	var candidate := raw_data.duplicate(true)
	var group_id := str(group.get("id", ""))
	if candidate.get("components") is Dictionary:
		candidate = _dictionary_copy_v01522(candidate.get("components", {}))
	elif not group_id.is_empty() and candidate.get(group_id) is Dictionary:
		candidate = _dictionary_copy_v01522(candidate.get(group_id, {}))

	var accepted: Dictionary = {}
	var extras: Array[Dictionary] = []
	var known_keys: Dictionary = {}
	var missing_required: Array[Dictionary] = []
	for raw_component in group.get("components", []):
		if not raw_component is Dictionary or not bool(raw_component.get("enabled", true)):
			continue
		var component: Dictionary = raw_component
		var component_id := str(component.get("id", "")).strip_edges()
		var component_label := str(component.get("label", component_id)).strip_edges()
		known_keys[component_id] = true
		known_keys[component_label] = true
		var value: Variant = null
		if candidate.has(component_id):
			value = candidate.get(component_id)
		elif candidate.has(component_label):
			value = candidate.get(component_label)
		if _value_has_content_v01522(value):
			accepted[component_id] = _value_to_text(value).strip_edges()
		elif bool(component.get("required", true)):
			missing_required.append(component.duplicate(true))

	if bool(group.get("allow_extra_components", false)):
		for raw_key in candidate:
			var key := str(raw_key)
			if known_keys.has(key) or not _value_has_content_v01522(candidate.get(raw_key)):
				continue
			extras.append(
				{
					"label": key.replace("_", " ").capitalize(),
					"value": _value_to_text(candidate.get(raw_key)).strip_edges()
				}
			)

	_active_job["safe_pending_group_components"] = accepted
	_active_job["safe_pending_group_extras"] = extras
	if not missing_required.is_empty():
		_active_job["diagnostics_validation"] = {
			"ok": false,
			"kind": "missing_component",
			"section": str(section.get("title", "Output Group")),
			"missing": _component_labels_v01522(missing_required)
		}
		_start_safe_component_repair_v01522(section, missing_required[0])
		return
	_accept_safe_group_v01522(section)


func _start_safe_component_repair_v01522(section: Dictionary, component: Dictionary) -> void:
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var attempts := _dictionary_copy_v01522(state.get("component_repair_attempts", {}))
	var group := _dictionary_copy_v01522(section.get("group", {}))
	var repair_key := "%s:%s" % [str(group.get("id", "group")), str(component.get("id", "component"))]
	var attempt_count := int(attempts.get(repair_key, 0))
	if attempt_count >= SAFE_COMPONENT_REPAIR_LIMIT:
		_handle_failure(
			"Safe Section Build could not complete %s → %s after a focused component repair."
			% [str(section.get("title", "Output Group")), str(component.get("label", component.get("id", "Component")))],
			false
		)
		return
	attempts[repair_key] = attempt_count + 1
	state["component_repair_attempts"] = attempts
	_active_job["safe_build_state"] = state
	_active_job["safe_repair_component"] = component.duplicate(true)
	_active_job["safe_stage"] = "component_repair"
	_active_job["parse_mode"] = "field"
	_active_job["attempt"] = 0
	_active_job["repair_attempts"] = 0
	_active_job["label"] = "Safe repair • %s → %s" % [
		str(section.get("title", "Output Group")),
		str(component.get("label", component.get("id", "Component")))
	]
	var prompt := _safe_common_context_v01522(_active_job)
	var pending := _dictionary_copy_v01522(_active_job.get("safe_pending_group_components", {}))
	if not pending.is_empty():
		prompt += "\n\nALREADY ACCEPTED COMPONENTS IN THIS OUTPUT GROUP — do not rewrite them:\n%s" % _render_component_context_v01522(group, pending)
	prompt += (
		"\n\nFOCUSED MISSING-COMPONENT REPAIR:\n"
		+ "Output Group: %s\nMissing component: %s\nInstruction: %s\n\n"
		+ "Generate ONLY this missing component. Return valid JSON exactly as {\"value\": <component text>}. Do not regenerate the output group, other components, or any other Character Card field."
		% [
			str(section.get("title", "Output Group")),
			str(component.get("label", component.get("id", "Component"))),
			str(component.get("instruction", "")).strip_edges()
		]
	)
	_active_job["payload"] = _payload_for_safe_prompt_v01522(
		_active_job,
		"You are Character Card Forge's focused Safe Section repair writer. Fill only the named missing component and return valid JSON only.",
		prompt
	)
	_emit_queue_changed()
	call_deferred("_start_active_request")


func _process_safe_component_repair_v01522(content: String) -> void:
	var parse_result := _parse_job_output_with_diagnostics(content, "field")
	if not bool(parse_result.get("ok", false)):
		if _start_json_repair(content, "field"):
			return
		_fail_safe_parse_v01522(parse_result)
		return
	var value: Variant = parse_result.get("data")
	var section := _dictionary_copy_v01522(_active_job.get("safe_active_section", {}))
	var component := _dictionary_copy_v01522(_active_job.get("safe_repair_component", {}))
	if not _value_has_content_v01522(value):
		_start_safe_component_repair_v01522(section, component)
		return
	var pending := _dictionary_copy_v01522(_active_job.get("safe_pending_group_components", {}))
	pending[str(component.get("id", "component"))] = _value_to_text(value).strip_edges()
	_active_job["safe_pending_group_components"] = pending

	var group := _dictionary_copy_v01522(section.get("group", {}))
	for raw_component in group.get("components", []):
		if not raw_component is Dictionary or not bool(raw_component.get("enabled", true)) or not bool(raw_component.get("required", true)):
			continue
		var required_component: Dictionary = raw_component
		var component_id := str(required_component.get("id", ""))
		if not _value_has_content_v01522(pending.get(component_id)):
			_start_safe_component_repair_v01522(section, required_component)
			return
	_accept_safe_group_v01522(section)


func _accept_safe_group_v01522(section: Dictionary) -> void:
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var accepted_groups := _dictionary_copy_v01522(state.get("accepted_groups", {}))
	var group := _dictionary_copy_v01522(section.get("group", {}))
	var group_id := str(group.get("id", "generation_group"))
	accepted_groups[group_id] = {
		"components": _dictionary_copy_v01522(_active_job.get("safe_pending_group_components", {})),
		"extras": _array_copy_v01522(_active_job.get("safe_pending_group_extras", []))
	}
	state["accepted_groups"] = accepted_groups
	state["accepted_fields"] = _assembled_safe_fields_v01522(state)
	var completed: Array = _array_copy_v01522(state.get("completed_sections", []))
	completed.append({"id": group_id, "title": str(section.get("title", group_id)), "kind": "output_group"})
	state["completed_sections"] = completed
	_active_job["safe_build_state"] = state
	_active_job["diagnostics_validation"] = {"ok": true, "section": str(section.get("title", group_id)), "kind": "output_group"}
	_advance_safe_build_v01522()


func _process_safe_field_result_v01522(section: Dictionary, data: Dictionary) -> void:
	var field := _dictionary_copy_v01522(section.get("field", {}))
	var field_id := str(section.get("field_id", field.get("id", "field")))
	var has_value := data.has(field_id) or data.has("value")
	var value: Variant = data.get(field_id, data.get("value", null))
	if not has_value and data.size() == 1:
		for raw_key in data:
			value = data.get(raw_key)
			has_value = true
			break
	var issues := _standalone_field_issues_v01522(field, value, has_value)
	if not issues.is_empty():
		_active_job["safe_pending_field_value"] = value
		_active_job["diagnostics_validation"] = {
			"ok": false,
			"kind": "standalone_field",
			"section": str(section.get("title", field_id)),
			"issues": issues
		}
		_start_safe_field_repair_v01522(section, issues)
		return
	_accept_safe_field_v01522(section, value, has_value)


func _start_safe_field_repair_v01522(section: Dictionary, issues: Array) -> void:
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var attempts := _dictionary_copy_v01522(state.get("field_repair_attempts", {}))
	var field_id := str(section.get("field_id", "field"))
	var attempt_count := int(attempts.get(field_id, 0))
	if attempt_count >= SAFE_FIELD_REPAIR_LIMIT:
		_handle_failure(
			"Safe Section Build could not complete %s after a focused field repair. %s"
			% [str(section.get("title", field_id)), _join_string_array(_issue_texts_v01522(issues), " ")],
			false
		)
		return
	attempts[field_id] = attempt_count + 1
	state["field_repair_attempts"] = attempts
	_active_job["safe_build_state"] = state
	_active_job["safe_stage"] = "field_repair"
	_active_job["safe_field_repair_issues"] = issues.duplicate(true)
	_active_job["parse_mode"] = "field"
	_active_job["attempt"] = 0
	_active_job["repair_attempts"] = 0
	_active_job["label"] = "Safe repair • %s" % str(section.get("title", field_id))
	var field := _dictionary_copy_v01522(section.get("field", {}))
	var prompt := _safe_common_context_v01522(_active_job)
	prompt += (
		"\n\nFOCUSED FIELD REPAIR:\nField: %s (%s)\nProblems to correct:\n- %s"
		% [
			str(field.get("label", field_id)),
			field_id,
			_join_string_array(_issue_texts_v01522(issues), "\n- ")
		]
	)
	var previous: Variant = _active_job.get("safe_pending_field_value", null)
	if _value_has_content_v01522(previous):
		prompt += "\n\nPrevious value to improve rather than unrelatedly rewrite:\n%s" % _value_to_text(previous)
	var instruction := str(field.get("generation_prompt", "")).strip_edges()
	if not instruction.is_empty():
		prompt += "\n\nField instruction: %s" % instruction
	prompt += "\n\nReturn ONLY a complete replacement value for this field as valid JSON exactly shaped {\"value\": <replacement>}. Do not generate any other field."
	_active_job["payload"] = _payload_for_safe_prompt_v01522(
		_active_job,
		"You are Character Card Forge's focused Safe Section field repair writer. Repair only the named field and return valid JSON only.",
		prompt
	)
	_emit_queue_changed()
	call_deferred("_start_active_request")


func _process_safe_field_repair_v01522(content: String) -> void:
	var parse_result := _parse_job_output_with_diagnostics(content, "field")
	if not bool(parse_result.get("ok", false)):
		if _start_json_repair(content, "field"):
			return
		_fail_safe_parse_v01522(parse_result)
		return
	var value: Variant = parse_result.get("data")
	var section := _dictionary_copy_v01522(_active_job.get("safe_active_section", {}))
	var field := _dictionary_copy_v01522(section.get("field", {}))
	var issues := _standalone_field_issues_v01522(field, value, true)
	if not issues.is_empty():
		_active_job["safe_pending_field_value"] = value
		_start_safe_field_repair_v01522(section, issues)
		return
	_accept_safe_field_v01522(section, value, true)


func _accept_safe_field_v01522(section: Dictionary, value: Variant, has_value: bool) -> void:
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var accepted := _dictionary_copy_v01522(state.get("accepted_fields", {}))
	var field_id := str(section.get("field_id", "field"))
	if has_value and _value_has_content_v01522(value):
		accepted[field_id] = value
	state["accepted_fields"] = accepted
	var completed: Array = _array_copy_v01522(state.get("completed_sections", []))
	completed.append({"id": field_id, "title": str(section.get("title", field_id)), "kind": "standalone_field"})
	state["completed_sections"] = completed
	_active_job["safe_build_state"] = state
	_active_job["diagnostics_validation"] = {"ok": true, "section": str(section.get("title", field_id)), "kind": "standalone_field"}
	_advance_safe_build_v01522()


func _advance_safe_build_v01522() -> void:
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var next_index := int(state.get("index", 0)) + 1
	var plan_value: Variant = state.get("plan", [])
	if not plan_value is Array or next_index >= plan_value.size():
		_finish_safe_build_v01522()
		return
	_active_job = _job_for_safe_section_v01522(_active_job, next_index)
	_emit_queue_changed()
	call_deferred("_start_active_request")


func _finish_safe_build_v01522() -> void:
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	state["accepted_fields"] = _assembled_safe_fields_v01522(state)
	_active_job["safe_build_state"] = state
	var final_data := _dictionary_copy_v01522(state.get("accepted_fields", {}))
	var metadata := _dictionary_copy_v01522(_active_job.get("metadata", {}))
	metadata["generation_strategy"] = GENERATION_STRATEGY_SAFE_SECTION
	metadata["safe_completed_sections"] = _array_copy_v01522(state.get("completed_sections", []))
	metadata["safe_completed_section_count"] = metadata["safe_completed_sections"].size()
	_active_job["metadata"] = metadata
	_active_job["safe_delegate_to_parent"] = true
	_active_job["safe_stage"] = "final_validation"
	_active_job["parse_mode"] = "object"
	_active_job["label"] = "Validating Safe Section Build"
	_active_job["diagnostics_last_parsed_output"] = final_data.duplicate(true)
	var contract_value: Variant = metadata.get("generation_contract", {})
	if contract_value is Dictionary and not contract_value.is_empty():
		_active_job["diagnostics_validation"] = CCFGenerationContractService.validate_generated_data(final_data, contract_value)
	_emit_queue_changed()
	# Reuse the established contract, concept-fidelity, repair and fail-closed chain on
	# the assembled candidate without making another model request unless that chain
	# identifies a genuine remaining problem.
	super._process_completed_content(JSON.stringify(final_data))


func _assembled_safe_fields_v01522(state: Dictionary) -> Dictionary:
	var accepted := _dictionary_copy_v01522(state.get("accepted_fields", {}))
	var accepted_groups := _dictionary_copy_v01522(state.get("accepted_groups", {}))
	var template := _dictionary_copy_v01522(state.get("generation_template", {}))
	var groups_by_field: Dictionary = {}
	for raw_group in CCFTemplateService.enabled_generation_groups(template):
		if not raw_group is Dictionary:
			continue
		var group: Dictionary = raw_group
		var field_id := str(group.get("output_field_id", ""))
		if not groups_by_field.has(field_id):
			groups_by_field[field_id] = []
		var field_groups: Array = groups_by_field.get(field_id, [])
		field_groups.append(group)
		groups_by_field[field_id] = field_groups
	for raw_field_id in groups_by_field:
		var field_id := str(raw_field_id)
		var groups_value: Variant = groups_by_field.get(field_id, [])
		if not groups_value is Array:
			continue
		var groups: Array = groups_value
		var rendered_groups: Array[String] = []
		for raw_group in groups:
			if not raw_group is Dictionary:
				continue
			var group: Dictionary = raw_group
			var group_id := str(group.get("id", ""))
			var accepted_group_value: Variant = accepted_groups.get(group_id, {})
			if not accepted_group_value is Dictionary:
				continue
			var rendered := _render_group_body_v01522(group, accepted_group_value)
			if rendered.is_empty():
				continue
			if groups.size() > 1:
				rendered = "%s:\n%s" % [str(group.get("title", group_id)), rendered]
			rendered_groups.append(rendered)
		if not rendered_groups.is_empty():
			accepted[field_id] = _join_string_array(rendered_groups, "\n\n")
	return accepted


func _render_group_body_v01522(group: Dictionary, accepted_group: Dictionary) -> String:
	var components := _dictionary_copy_v01522(accepted_group.get("components", {}))
	var lines: Array[String] = []
	for raw_component in group.get("components", []):
		if not raw_component is Dictionary or not bool(raw_component.get("enabled", true)):
			continue
		var component: Dictionary = raw_component
		var component_id := str(component.get("id", ""))
		if not _value_has_content_v01522(components.get(component_id)):
			continue
		lines.append("%s: %s" % [str(component.get("label", component_id)), _value_to_text(components.get(component_id)).strip_edges()])
	if bool(group.get("allow_extra_components", false)):
		for raw_extra in _array_copy_v01522(accepted_group.get("extras", [])):
			if raw_extra is Dictionary and _value_has_content_v01522(raw_extra.get("value")):
				lines.append("%s: %s" % [str(raw_extra.get("label", "Extra")), _value_to_text(raw_extra.get("value")).strip_edges()])
	return _join_string_array(lines, "\n")


func _standalone_field_issues_v01522(field: Dictionary, value: Variant, has_value: bool) -> Array:
	var issues: Array = []
	var field_id := str(field.get("id", "field"))
	var required := bool(field.get("required", false))
	if required and (not has_value or not _value_has_content_v01522(value)):
		issues.append("Required field is missing or empty.")
		return issues
	if not has_value or not _value_has_content_v01522(value):
		return issues
	var field_type := str(field.get("type", "multiline"))
	match field_type:
		"tags":
			if not value is Array:
				issues.append("Expected an array of tag strings.")
		"checkbox":
			if not value is bool:
				issues.append("Expected a JSON boolean.")
		"number":
			if not (value is int or value is float):
				issues.append("Expected a JSON number.")
		"select":
			var options_value: Variant = field.get("options", [])
			if options_value is Array and not options_value.is_empty() and not options_value.has(str(value)):
				issues.append("Expected one of the configured select options.")
		_:
			if not value is String:
				issues.append("Expected text.")
	if issues.is_empty():
		var metadata := _dictionary_copy_v01522(_active_job.get("metadata", {}))
		var contract_value: Variant = metadata.get("generation_contract", {})
		if contract_value is Dictionary and not contract_value.is_empty():
			var report := CCFGenerationContractService.validate_generated_data({field_id: value}, contract_value)
			for raw_issue in report.get("issues", []):
				if raw_issue is Dictionary and str(raw_issue.get("field_id", "")) == field_id and str(raw_issue.get("kind", "")) != "missing_field":
					issues.append(str(raw_issue.get("reason", "Field does not satisfy its generation contract.")))
	return issues


func _payload_for_safe_prompt_v01522(job: Dictionary, system_text: String, user_text: String) -> Dictionary:
	var base_payload := _dictionary_copy_v01522(job.get("safe_original_character_payload", job.get("payload", {})))
	base_payload["messages"] = [
		{"role": "system", "content": system_text},
		{"role": "user", "content": user_text}
	]
	return base_payload


func _render_component_context_v01522(group: Dictionary, values: Dictionary) -> String:
	var lines: Array[String] = []
	for raw_component in group.get("components", []):
		if not raw_component is Dictionary:
			continue
		var component: Dictionary = raw_component
		var component_id := str(component.get("id", ""))
		if _value_has_content_v01522(values.get(component_id)):
			lines.append("%s: %s" % [str(component.get("label", component_id)), _value_to_text(values.get(component_id))])
	return _join_string_array(lines, "\n")


func _fail_safe_parse_v01522(parse_result: Dictionary) -> void:
	var section := _dictionary_copy_v01522(_active_job.get("safe_active_section", {}))
	_handle_failure(
		"Safe Section Build could not parse %s as the required JSON shape. %s"
		% [
			str(section.get("title", "current section")),
			str(parse_result.get("diagnostic", "No usable JSON was found."))
		],
		false
	)


func _start_active_request() -> void:
	if not _active_job.is_empty():
		var request_snapshot := {
			"timestamp": Time.get_datetime_string_from_system(true),
			"label": str(_active_job.get("label", "Generation")),
			"stage": _diagnostic_stage_v01522(),
			"attempt": int(_active_job.get("attempt", 0)) + 1,
			"payload": _sanitise_diagnostic_value_v01522(_active_job.get("payload", {}))
		}
		_active_job["diagnostics_last_request"] = request_snapshot
		_append_diagnostic_event_v01522("request", request_snapshot)
	super._start_active_request()


func _on_request_completed(
	result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
) -> void:
	if not _active_job.is_empty():
		var body_text := body.get_string_from_utf8()
		var parsed_response: Variant = JSON.parse_string(body_text)
		var extracted := ""
		if parsed_response is Dictionary:
			extracted = _extract_content(parsed_response)
		var response_snapshot := {
			"timestamp": Time.get_datetime_string_from_system(true),
			"stage": _diagnostic_stage_v01522(),
			"network_result": result,
			"response_code": response_code,
			"raw_body": body_text,
			"extracted_assistant_text": extracted
		}
		_active_job["diagnostics_last_response"] = response_snapshot
		_active_job["diagnostics_last_raw_response"] = body_text
		_active_job["diagnostics_last_assistant_text"] = extracted
		_append_diagnostic_event_v01522("response", response_snapshot)
	super._on_request_completed(result, response_code, headers, body)


func _start_json_repair(malformed_content: String, parse_mode: String) -> bool:
	var started := super._start_json_repair(malformed_content, parse_mode)
	if started and not _active_job.is_empty():
		var repair := {
			"kind": "json_repair",
			"stage": _diagnostic_stage_v01522(),
			"malformed_assistant_text": malformed_content,
			"request_payload": _sanitise_diagnostic_value_v01522(_active_job.get("payload", {}))
		}
		_active_job["diagnostics_last_repair"] = repair
		_append_diagnostic_event_v01522("repair_request", repair)
	return started


func _start_semantic_repair(
	current_data: Dictionary, report: Dictionary, contract: Dictionary
) -> void:
	super._start_semantic_repair(current_data, report, contract)
	if not _active_job.is_empty():
		var repair := {
			"kind": "semantic_repair",
			"validation_report": report.duplicate(true),
			"request_payload": _sanitise_diagnostic_value_v01522(_active_job.get("payload", {}))
		}
		_active_job["diagnostics_last_repair"] = repair
		_active_job["diagnostics_validation"] = report.duplicate(true)
		_append_diagnostic_event_v01522("repair_request", repair)


func _start_concept_fidelity_retry(
	current_data: Dictionary, report: Dictionary, contract: Dictionary
) -> void:
	super._start_concept_fidelity_retry(current_data, report, contract)
	if not _active_job.is_empty():
		var repair := {
			"kind": "concept_fidelity_correction",
			"validation_report": report.duplicate(true),
			"request_payload": _sanitise_diagnostic_value_v01522(_active_job.get("payload", {}))
		}
		_active_job["diagnostics_last_repair"] = repair
		_append_diagnostic_event_v01522("repair_request", repair)


func _handle_failure(message: String, retryable: bool) -> void:
	if _active_job.is_empty():
		return
	var attempt := int(_active_job.get("attempt", 1))
	var max_retries := int(_active_job.get("max_retries", 0))
	var terminal := not (retryable and attempt <= max_retries)
	if terminal:
		var bundle := _build_failure_diagnostics_v01522(message)
		var job_id := str(_active_job.get("id", ""))
		_failed_diagnostics_by_job_v01522[job_id] = bundle.duplicate(true)
		_diagnostic_history_v01522.append(bundle.duplicate(true))
		while _diagnostic_history_v01522.size() > DIAGNOSTIC_HISTORY_LIMIT:
			var removed: Dictionary = _diagnostic_history_v01522.pop_front()
			_failed_diagnostics_by_job_v01522.erase(str(removed.get("job_id", "")))
		diagnostics_available.emit(job_id, str(_active_job.get("type", "")), bundle)
	else:
		_append_diagnostic_event_v01522(
			"retry",
			{"message": message, "attempt": attempt, "maximum_retries": max_retries}
		)
	super._handle_failure(message, retryable)


func _build_failure_diagnostics_v01522(message: String) -> Dictionary:
	var metadata := _dictionary_copy_v01522(_active_job.get("metadata", {}))
	var section := _dictionary_copy_v01522(_active_job.get("safe_active_section", {}))
	var validation: Variant = _active_job.get("diagnostics_validation", {})
	if (not validation is Dictionary or validation.is_empty()) and metadata.get("generation_contract_report") is Dictionary:
		validation = metadata.get("generation_contract_report")
	var bundle := {
		"format_version": DIAGNOSTIC_FORMAT_VERSION,
		"captured_at": Time.get_datetime_string_from_system(true),
		"job_id": str(_active_job.get("id", "")),
		"job_type": str(_active_job.get("type", "")),
		"label": str(_active_job.get("label", "Generation")),
		"failure_stage": _diagnostic_stage_v01522(),
		"failure_reason": message,
		"active_section": str(section.get("title", "")),
		"active_section_kind": str(section.get("kind", "")),
		"provider": {
			"profile_name": str(_active_job.get("profile_name", "")),
			"model": str(_active_job.get("model", ""))
		},
		"generation_strategy": str(metadata.get("generation_strategy", _active_job.get("generation_strategy", ""))),
		"mode_style": _dictionary_copy_v01522(metadata.get("mode_style", {})),
		"request": _active_job.get("diagnostics_last_request", {}),
		"raw_api_response": str(_active_job.get("diagnostics_last_raw_response", "")),
		"extracted_assistant_text": str(_active_job.get("diagnostics_last_assistant_text", "")),
		"parsed_output": _active_job.get("diagnostics_last_parsed_output", null),
		"parse_error": str(_active_job.get("diagnostics_last_parse_error", "")),
		"validation_report": validation,
		"repair": _active_job.get("diagnostics_last_repair", {}),
		"metadata": metadata,
		"events": _array_copy_v01522(_active_job.get("diagnostic_events", []))
	}
	return _sanitise_diagnostic_value_v01522(bundle)


func _append_diagnostic_event_v01522(kind: String, payload: Dictionary) -> void:
	if _active_job.is_empty():
		return
	var events: Array = _array_copy_v01522(_active_job.get("diagnostic_events", []))
	events.append({"kind": kind, "data": payload.duplicate(true)})
	_active_job["diagnostic_events"] = events


func _diagnostic_stage_v01522() -> String:
	if _active_job.is_empty():
		return "idle"
	var interview_stage := str(_active_job.get("interview_stage", ""))
	if interview_stage == "planning" or interview_stage == "retry":
		return "interview_%s" % interview_stage
	var safe_stage := str(_active_job.get("safe_stage", "")).strip_edges()
	if not safe_stage.is_empty():
		return "safe_%s" % safe_stage
	var fidelity_stage := str(_active_job.get("concept_fidelity_stage", "")).strip_edges()
	if not fidelity_stage.is_empty() and fidelity_stage != "pending":
		return "concept_fidelity_%s" % fidelity_stage
	if int(_active_job.get("semantic_repair_attempts", 0)) > 0:
		return "semantic_repair"
	if int(_active_job.get("repair_attempts", 0)) > 0:
		return "json_repair"
	return "generation"


func _sanitise_diagnostic_value_v01522(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for raw_key in value:
			var key := str(raw_key)
			var lowered := key.to_lower()
			if lowered in ["api_key", "authorization", "proxy_authorization", "password", "secret", "access_token", "refresh_token", "headers"]:
				result[key] = "[REDACTED]"
			else:
				result[key] = _sanitise_diagnostic_value_v01522(value.get(raw_key))
		return result
	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(_sanitise_diagnostic_value_v01522(item))
		return result_array
	if value is String:
		return _redact_known_secrets_v01522(value)
	return value


func _redact_known_secrets_v01522(text: String) -> String:
	var result := text
	if _active_job.is_empty():
		return result
	var headers_value: Variant = _active_job.get("headers", PackedStringArray())
	if headers_value is PackedStringArray:
		for header in headers_value:
			var header_text := str(header)
			var separator := header_text.find(":")
			if separator < 0:
				continue
			var header_name := header_text.substr(0, separator).strip_edges().to_lower()
			if header_name not in ["authorization", "proxy-authorization", "x-api-key", "api-key"]:
				continue
			var secret_value := header_text.substr(separator + 1).strip_edges()
			if not secret_value.is_empty():
				result = result.replace(secret_value, "[REDACTED]")
				if secret_value.to_lower().begins_with("bearer "):
					var bare := secret_value.substr(7).strip_edges()
					if not bare.is_empty():
						result = result.replace(bare, "[REDACTED]")
	return result


func _component_labels_v01522(components: Array) -> Array[String]:
	var labels: Array[String] = []
	for raw_component in components:
		if raw_component is Dictionary:
			labels.append(str(raw_component.get("label", raw_component.get("id", "Component"))))
	return labels


func _issue_texts_v01522(issues: Array) -> Array[String]:
	var texts: Array[String] = []
	for issue in issues:
		texts.append(str(issue))
	return texts


func _value_has_content_v01522(value: Variant) -> bool:
	if value == null:
		return false
	if value is String:
		return not value.strip_edges().is_empty()
	if value is Array:
		return not value.is_empty()
	if value is Dictionary:
		return not value.is_empty()
	return true


func _dictionary_copy_v01522(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _array_copy_v01522(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []
