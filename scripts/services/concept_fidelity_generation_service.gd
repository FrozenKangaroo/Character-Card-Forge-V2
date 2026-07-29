class_name CCFConceptFidelityGenerationService
extends CCFTemplateContractGuardGenerationService

const MAX_CONCEPT_FIDELITY_RETRIES := 1
const FIDELITY_RETRY_STAGE := "retry"
const FIDELITY_RETRY_MARKER := "CONCEPT FIDELITY CORRECTION — authoritative source facts:"

var _pending_fidelity_plan: Dictionary = {}


func queue_character_generation(
	project: Dictionary,
	template: Dictionary,
	profile: Dictionary,
	include_existing_fields: bool,
	retry_count: int
) -> Dictionary:
	var concept := str(
		CCFStorageService.get_value_at_path(project, "concept.prompt", "")
	).strip_edges()
	var source_name := str(
		CCFStorageService.get_value_at_path(project, "character.name", "")
	).strip_edges()
	_pending_fidelity_plan = CCFConceptFidelityService.build_plan(concept, source_name)
	var result: Dictionary = super.queue_character_generation(
		project, template, profile, include_existing_fields, retry_count
	)
	var plan := _pending_fidelity_plan.duplicate(true)
	_pending_fidelity_plan = {}
	if not bool(result.get("ok", false)):
		return result
	var job_id := str(result.get("job_id", ""))
	if not job_id.is_empty():
		_decorate_job_with_fidelity_plan(job_id, plan)
	return result


func _process_completed_content(content: String) -> void:
	if _active_job.is_empty() or str(_active_job.get("type", "")) != "character":
		super._process_completed_content(content)
		return

	var interview_stage := str(_active_job.get("interview_stage", ""))
	if interview_stage == "planning" or interview_stage == "retry":
		super._process_completed_content(content)
		return

	var parse_mode := str(_active_job.get("parse_mode", "object"))
	var parse_result: Dictionary = _parse_job_output_with_diagnostics(content, parse_mode)
	if not bool(parse_result.get("ok", false)):
		super._process_completed_content(content)
		return
	var parsed_value: Variant = parse_result.get("data")
	if not parsed_value is Dictionary:
		super._process_completed_content(content)
		return
	var parsed_data: Dictionary = parsed_value

	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = (
		metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	)
	var contract_value: Variant = metadata.get("generation_contract", {})
	if not contract_value is Dictionary or contract_value.is_empty():
		super._process_completed_content(content)
		return
	var contract: Dictionary = contract_value
	var contract_report := CCFGenerationContractService.validate_generated_data(
		parsed_data, contract
	)
	if not bool(contract_report.get("ok", false)):
		# Template structure remains authoritative. Let the existing semantic-repair/
		# fail-closed guard run before concept fidelity is considered.
		super._process_completed_content(content)
		return

	var plan_value: Variant = _active_job.get("concept_fidelity_plan", {})
	var plan: Dictionary = plan_value if plan_value is Dictionary else {}
	var fidelity_report := CCFConceptFidelityService.validate_candidate(plan, parsed_data)
	var fidelity_attempts := int(_active_job.get("concept_fidelity_retry_attempts", 0))
	metadata["concept_fidelity"] = CCFConceptFidelityService.metadata_report(
		fidelity_report, fidelity_attempts
	)
	metadata["concept_fidelity_checked"] = true
	_active_job["metadata"] = metadata

	if (
		bool(fidelity_report.get("clear_drift", false))
		and fidelity_attempts < MAX_CONCEPT_FIDELITY_RETRIES
	):
		_start_concept_fidelity_retry(parsed_data, fidelity_report, contract)
		return

	var final_report_value: Variant = metadata.get("concept_fidelity", {})
	if final_report_value is Dictionary:
		var final_report: Dictionary = final_report_value.duplicate(true)
		final_report["remaining_clear_drift"] = bool(
			fidelity_report.get("clear_drift", false)
		)
		metadata["concept_fidelity"] = final_report
		_active_job["metadata"] = metadata
	super._process_completed_content(content)


func _decorate_job_with_fidelity_plan(job_id: String, plan: Dictionary) -> void:
	for index in range(_queue.size()):
		var job: Dictionary = _queue[index]
		if str(job.get("id", "")) != job_id:
			continue
		_queue[index] = _job_with_fidelity_plan(job, plan)
		return
	if str(_active_job.get("id", "")) == job_id:
		_active_job = _job_with_fidelity_plan(_active_job, plan)


func _job_with_fidelity_plan(job_value: Dictionary, plan: Dictionary) -> Dictionary:
	var job := job_value.duplicate(true)
	job["concept_fidelity_plan"] = plan.duplicate(true)
	job["concept_fidelity_retry_attempts"] = 0
	job["concept_fidelity_stage"] = "pending"
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	var anchors_value: Variant = plan.get("anchors", [])
	var anchor_count := anchors_value.size() if anchors_value is Array else 0
	metadata["concept_fidelity_plan"] = {
		"format_version": int(plan.get("format_version", CCFConceptFidelityService.FORMAT_VERSION)),
		"anchor_count": anchor_count,
		"has_authoritative_name": not str(plan.get("authoritative_name", "")).is_empty()
	}
	job["metadata"] = metadata
	return job


func _start_concept_fidelity_retry(
	current_data: Dictionary,
	report: Dictionary,
	contract: Dictionary
) -> void:
	_active_job["concept_fidelity_retry_attempts"] = int(
		_active_job.get("concept_fidelity_retry_attempts", 0)
	) + 1
	_active_job["concept_fidelity_stage"] = FIDELITY_RETRY_STAGE
	_active_job["label"] = "Correcting concept drift"
	_active_job["attempt"] = 0
	_active_job["repair_attempts"] = 0

	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	metadata["concept_fidelity_retry_trigger"] = CCFConceptFidelityService.metadata_report(
		report, int(_active_job.get("concept_fidelity_retry_attempts", 0))
	)
	_active_job["metadata"] = metadata

	var payload_value: Variant = _active_job.get("payload", {})
	var payload: Dictionary = payload_value.duplicate(true) if payload_value is Dictionary else {}
	payload["temperature"] = minf(float(payload.get("temperature", 0.8)), 0.25)

	var concept := str(metadata.get("concept", "")).strip_edges()
	var prompt := (
		"The previous character-card result is structurally valid, but a conservative fidelity check found clear drift from explicit source facts. Correct only those clear fidelity errors. Preserve all useful material, template structure, planning context, and author-selected style that do not conflict with the source concept."
	)
	if not concept.is_empty():
		prompt += "\n\nSOURCE CONCEPT — highest authority:\n%s" % concept
	prompt += "\n\nCURRENT GENERATED JSON — preserve good material:\n%s" % JSON.stringify(
		current_data, "  "
	)
	var retry_notes := CCFConceptFidelityService.retry_instructions(report)
	if not retry_notes.is_empty():
		prompt += "\n\n%s\n%s" % [FIDELITY_RETRY_MARKER, retry_notes]
	prompt += "\n\n%s" % CCFGenerationContractService.prompt_text(contract)
	prompt += "\n\n%s" % TEMPLATE_STRUCTURE_RULE

	var planning_context := _repair_planning_context()
	if not planning_context.is_empty():
		prompt += "\n\nPLANNING CONTEXT TO PRESERVE WHEN COMPATIBLE WITH THE SOURCE CONCEPT:\n%s" % planning_context
	var mode_style := _current_mode_style()
	prompt += "\n\n%s" % _mode_style_block(mode_style)

	var field_ids: Array[String] = []
	var field_ids_value: Variant = metadata.get("field_ids", [])
	if field_ids_value is Array:
		for raw_field_id in field_ids_value:
			var field_id := str(raw_field_id).strip_edges()
			if not field_id.is_empty():
				field_ids.append(field_id)
	if not field_ids.is_empty():
		prompt += "\n\nReturn the complete corrected JSON object using the original requested top-level keys: %s." % _join_string_array(field_ids, ", ")
	else:
		prompt += "\n\nReturn the complete corrected JSON object."
	prompt += " Do not return a diff, explanation, markdown fence, or only corrected fragments. Do not invent new facts merely to make the fidelity check pass."

	payload["messages"] = [
		{
			"role": "system",
			"content": "You are Character Card Forge's conservative concept-fidelity correction pass. The source concept is authoritative. Correct explicit drift while preserving good character-card content and exact template structure. Return valid JSON only."
		},
		{"role": "user", "content": prompt}
	]
	_active_job["payload"] = payload
	_emit_queue_changed()
	call_deferred("_start_active_request")
