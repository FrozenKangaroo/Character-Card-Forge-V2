class_name CCFBuilderPrecedenceGenerationService
extends CCFInterviewContextGenerationService

const PLANNING_PRECEDENCE_VERSION := 1
const BUILDER_CONTEXT_MARKER := "CURRENT CHARACTER BUILDER GUIDANCE — deliberate planning context:"
const PRECEDENCE_MARKER := "PLANNING SOURCE PRECEDENCE — use this order when sources disagree:"
const REPAIR_CONTEXT_MARKER := "PLANNING CONTEXT TO PRESERVE DURING SEMANTIC REPAIR:"

var _pending_builder_report: Dictionary = {}


func queue_character_generation(
	project: Dictionary,
	template: Dictionary,
	profile: Dictionary,
	include_existing_fields: bool,
	retry_count: int
) -> Dictionary:
	_pending_builder_report = _builder_context_report(project)
	var result: Dictionary = super.queue_character_generation(
		project, template, profile, include_existing_fields, retry_count
	)
	var report := _pending_builder_report.duplicate(true)
	_pending_builder_report = {}
	if not bool(result.get("ok", false)):
		return result
	var job_id := str(result.get("job_id", ""))
	if not job_id.is_empty():
		_decorate_character_job_with_builder_context(job_id, report)
	return result


func _build_interview_payload(
	base_payload_value: Dictionary,
	concept: String,
	questions: Array,
	known_answers: Dictionary,
	missing_only: bool
) -> Dictionary:
	var payload := super._build_interview_payload(
		base_payload_value, concept, questions, known_answers, missing_only
	)
	return _payload_with_builder_context(payload, _current_builder_context_text())


func _prepare_character_stage(job_value: Dictionary) -> Dictionary:
	var job := super._prepare_character_stage(job_value)
	var builder_text := str(job.get("builder_planning_context", "")).strip_edges()
	if builder_text.is_empty():
		builder_text = _current_builder_context_text()
	job["payload"] = _payload_with_builder_context(job.get("payload", {}), builder_text)
	job["payload"] = _payload_with_precedence_rules(
		job.get("payload", {}), _interview_notes_for_source(job, true)
	)
	return job


func _start_semantic_repair(
	current_data: Dictionary, report: Dictionary, contract: Dictionary
) -> void:
	# The parent creates the bounded repair request and defers the HTTP start. Extend
	# that request before the deferred call runs so a repair cannot forget planning context.
	super._start_semantic_repair(current_data, report, contract)
	if _active_job.is_empty():
		return
	_active_job["payload"] = _payload_with_repair_context(
		_active_job.get("payload", {}), _repair_planning_context()
	)


func _decorate_character_job_with_builder_context(job_id: String, report: Dictionary) -> void:
	for index in range(_queue.size()):
		var job: Dictionary = _queue[index]
		if str(job.get("id", "")) != job_id:
			continue
		_queue[index] = _job_with_builder_report(job, report)
		return
	if str(_active_job.get("id", "")) == job_id:
		_active_job = _job_with_builder_report(_active_job, report)


func _job_with_builder_report(job_value: Dictionary, report: Dictionary) -> Dictionary:
	var job := job_value.duplicate(true)
	var builder_text := str(report.get("text", "")).strip_edges()
	job["builder_planning_context"] = builder_text
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	metadata["builder_context"] = {
		"used": not builder_text.is_empty(),
		"field_count": int(report.get("field_count", 0)),
		"step_count": int(report.get("step_count", 0))
	}
	metadata["planning_precedence"] = {
		"version": PLANNING_PRECEDENCE_VERSION,
		"order": [
			"source_concept",
			"manual_interview_answers",
			"builder_guidance",
			"ai_interview_answers",
			"existing_card_values_and_generic_inference"
		]
	}
	job["metadata"] = metadata
	if builder_text.is_empty():
		return job
	job["payload"] = _payload_with_builder_context(job.get("payload", {}), builder_text)
	var character_payload_value: Variant = job.get("interview_character_payload", null)
	if character_payload_value is Dictionary:
		job["interview_character_payload"] = _payload_with_builder_context(
			character_payload_value, builder_text
		)
	return job


func _payload_with_builder_context(payload_value: Variant, builder_text: String) -> Dictionary:
	var clean_builder := builder_text.strip_edges()
	var payload: Dictionary = payload_value.duplicate(true) if payload_value is Dictionary else {}
	if clean_builder.is_empty():
		return payload
	var messages_value: Variant = payload.get("messages", [])
	if not messages_value is Array or messages_value.is_empty():
		return payload
	var messages: Array = messages_value.duplicate(true)
	var last_index := messages.size() - 1
	var last_value: Variant = messages[last_index]
	if not last_value is Dictionary:
		return payload
	var last_message: Dictionary = last_value.duplicate(true)
	if str(last_message.get("role", "")) != "user":
		return payload
	var current_content := str(last_message.get("content", ""))
	if current_content.contains(BUILDER_CONTEXT_MARKER):
		return payload
	last_message["content"] = (
		current_content
		+ "\n\n"
		+ BUILDER_CONTEXT_MARKER
		+ "\n"
		+ clean_builder
		+ "\nTreat these stored Builder details as deliberate planning guidance. They outrank AI-inferred interview details and generic assumptions, but they must not replace an explicit conflicting fact from the source concept or a manually entered Interview / Q&A answer. Do not rewrite unrelated facts to resolve a local detail."
	)
	messages[last_index] = last_message
	payload["messages"] = messages
	return payload


func _payload_with_precedence_rules(payload_value: Variant, manual_interview_notes: String) -> Dictionary:
	var payload: Dictionary = payload_value.duplicate(true) if payload_value is Dictionary else {}
	var messages_value: Variant = payload.get("messages", [])
	if not messages_value is Array or messages_value.is_empty():
		return payload
	var messages: Array = messages_value.duplicate(true)
	var last_index := messages.size() - 1
	var last_value: Variant = messages[last_index]
	if not last_value is Dictionary:
		return payload
	var last_message: Dictionary = last_value.duplicate(true)
	if str(last_message.get("role", "")) != "user":
		return payload
	var current_content := str(last_message.get("content", ""))
	if current_content.contains(PRECEDENCE_MARKER):
		return payload
	var block := PRECEDENCE_MARKER
	block += "\n1. Source concept — explicit facts are highest priority."
	block += "\n2. Manually entered Interview / Q&A answers — authoritative planning detail unless they conflict with the source concept."
	block += "\n3. Current Character Builder guidance — deliberate structured planning detail unless it conflicts with either source above."
	block += "\n4. AI-inferred interview answers — connective suggestions only; they must yield to the sources above."
	block += "\n5. Existing card values and generic inference — preserve when compatible, but do not use them to override explicit planning."
	block += "\nWhen two high-priority planning sources appear to disagree, preserve the source concept and prefer the more specific directly stated detail. Never silently rewrite unrelated facts just to make one field easier to complete."
	var manual_notes := manual_interview_notes.strip_edges()
	if not manual_notes.is_empty():
		block += "\n\nMANUALLY ENTERED INTERVIEW / Q&A ANSWERS — priority level 2:\n%s" % manual_notes
	last_message["content"] = current_content + "\n\n" + block
	messages[last_index] = last_message
	payload["messages"] = messages
	return payload


func _payload_with_repair_context(payload_value: Variant, context_text: String) -> Dictionary:
	var clean_context := context_text.strip_edges()
	var payload: Dictionary = payload_value.duplicate(true) if payload_value is Dictionary else {}
	if clean_context.is_empty():
		return payload
	var messages_value: Variant = payload.get("messages", [])
	if not messages_value is Array or messages_value.is_empty():
		return payload
	var messages: Array = messages_value.duplicate(true)
	var last_index := messages.size() - 1
	var last_value: Variant = messages[last_index]
	if not last_value is Dictionary:
		return payload
	var last_message: Dictionary = last_value.duplicate(true)
	if str(last_message.get("role", "")) != "user":
		return payload
	var current_content := str(last_message.get("content", ""))
	if current_content.contains(REPAIR_CONTEXT_MARKER):
		return payload
	last_message["content"] = current_content + "\n\n" + REPAIR_CONTEXT_MARKER + "\n" + clean_context
	messages[last_index] = last_message
	payload["messages"] = messages
	return payload


func _repair_planning_context() -> String:
	if _active_job.is_empty():
		return ""
	var sections: Array[String] = []
	var manual_notes := _interview_notes_for_source(_active_job, true)
	if not manual_notes.is_empty():
		sections.append("MANUAL INTERVIEW / Q&A ANSWERS — authoritative after the source concept:\n%s" % manual_notes)
	var builder_text := str(_active_job.get("builder_planning_context", "")).strip_edges()
	if not builder_text.is_empty():
		sections.append("CHARACTER BUILDER GUIDANCE — preserve unless it conflicts with the concept or manual Q&A:\n%s" % builder_text)
	var ai_notes := _interview_notes_for_source(_active_job, false)
	if not ai_notes.is_empty():
		sections.append("AI-INFERRED INTERVIEW NOTES — lower-priority connective planning:\n%s" % ai_notes)
	if sections.is_empty():
		return ""
	sections.append(
		"Priority remains: source concept > manual Interview/Q&A > Builder guidance > AI interview > existing values/generic inference. Repair only the missing or invalid material; do not rewrite unrelated established facts."
	)
	return _join_string_array(sections, "\n\n")


func _interview_notes_for_source(job: Dictionary, manual_source: bool) -> String:
	var questions_value: Variant = job.get("interview_questions", [])
	var answers_value: Variant = job.get("interview_answers", {})
	var manual_ids_value: Variant = job.get("interview_manual_ids", [])
	if not questions_value is Array or not answers_value is Dictionary:
		return ""
	var manual_ids: Dictionary = {}
	if manual_ids_value is Array:
		for raw_id in manual_ids_value:
			manual_ids[str(raw_id)] = true
	var lines: Array[String] = []
	for raw_question in questions_value:
		if not raw_question is Dictionary:
			continue
		var question: Dictionary = raw_question
		var question_id := str(question.get("id", ""))
		var is_manual := manual_ids.has(question_id)
		if manual_source != is_manual:
			continue
		var answer := _value_to_text(answers_value.get(question_id, "")).strip_edges()
		if answer.is_empty():
			continue
		lines.append("%s: %s" % [str(question.get("label", question_id)), answer])
	return _join_string_array(lines, "\n")


func _current_builder_context_text() -> String:
	var pending_text := str(_pending_builder_report.get("text", "")).strip_edges()
	if not pending_text.is_empty():
		return pending_text
	if not _active_job.is_empty():
		return str(_active_job.get("builder_planning_context", "")).strip_edges()
	return ""


func _builder_context_report(project: Dictionary) -> Dictionary:
	var workspace_value: Variant = project.get("workspace", {})
	if not workspace_value is Dictionary:
		return {"text": "", "field_count": 0, "step_count": 0}
	var builder_value: Variant = workspace_value.get("builder", {})
	if not builder_value is Dictionary:
		return {"text": "", "field_count": 0, "step_count": 0}
	var state := CCFBuilderService.normalise_state(builder_value)
	var step_lines: Dictionary = {}
	var step_order: Array[String] = []
	var field_count := 0
	for raw_field in CCFBuilderService.all_fields():
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_path := str(field.get("path", "")).strip_edges()
		if field_path.is_empty():
			continue
		var value_text := _value_to_text(
			CCFStorageService.get_value_at_path(state, field_path, "")
		).strip_edges()
		if value_text.is_empty():
			continue
		var step_title := str(field.get("step_title", field.get("step_id", "Builder"))).strip_edges()
		if step_title.is_empty():
			step_title = "Builder"
		if not step_lines.has(step_title):
			step_lines[step_title] = []
			step_order.append(step_title)
		var lines: Array = step_lines[step_title]
		lines.append("%s: %s" % [str(field.get("label", field_path)), value_text])
		step_lines[step_title] = lines
		field_count += 1
	var sections: Array[String] = []
	for step_title in step_order:
		var lines_value: Variant = step_lines.get(step_title, [])
		if not lines_value is Array or lines_value.is_empty():
			continue
		var typed_lines: Array[String] = []
		for raw_line in lines_value:
			typed_lines.append(str(raw_line))
		sections.append("%s\n%s" % [step_title.to_upper(), _join_string_array(typed_lines, "\n")])
	return {
		"text": _join_string_array(sections, "\n\n"),
		"field_count": field_count,
		"step_count": sections.size()
	}
