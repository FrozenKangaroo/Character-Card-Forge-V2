class_name CCFInterviewGenerationService
extends CCFParityGenerationService

const MAX_MISSING_ANSWER_RETRIES := 2
const DEFAULT_INTERVIEW_PATH := "res://data/generation_interviews/default.json"


func queue_character_generation(
	project: Dictionary,
	template: Dictionary,
	profile: Dictionary,
	include_existing_fields: bool,
	retry_count: int
) -> Dictionary:
	var question_plan: Dictionary = _question_plan(template, project)
	var generation_template: Dictionary = _template_without_interview_sections(template)
	var result: Dictionary = super.queue_character_generation(
		project, generation_template, profile, include_existing_fields, retry_count
	)
	if not bool(result.get("ok", false)):
		return result

	var questions_value: Variant = question_plan.get("questions", [])
	if not questions_value is Array or questions_value.is_empty():
		return result

	var job_id := str(result.get("job_id", ""))
	if job_id.is_empty():
		return result
	_decorate_character_job_with_interview(job_id, question_plan)
	return result


func _process_completed_content(content: String) -> void:
	if _active_job.is_empty() or str(_active_job.get("type", "")) != "character":
		super._process_completed_content(content)
		return
	var stage := str(_active_job.get("interview_stage", ""))
	if stage == "planning" or stage == "retry":
		_process_interview_content(content)
		return
	super._process_completed_content(content)


func _question_plan(template: Dictionary, project: Dictionary) -> Dictionary:
	var questions: Array[Dictionary] = []
	var has_interview_section := false
	for raw_section in template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		if str(section.get("kind", "standard")) != "interview":
			continue
		has_interview_section = true
		for raw_field in section.get("fields", []):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			if not bool(field.get("generate", false)):
				continue
			var field_id := str(field.get("id", "")).strip_edges()
			if field_id.is_empty():
				continue
			var label := str(field.get("label", field_id)).strip_edges()
			var question := str(field.get("generation_prompt", "")).strip_edges()
			if question.is_empty():
				question = label
			questions.append(
				{
					"id": field_id,
					"label": label,
					"question": question,
					"required": bool(field.get("required", false)),
					"path": str(field.get("path", "")).strip_edges(),
					"source": "template"
				}
			)

	if not has_interview_section:
		questions = _read_default_questions()

	var answers: Dictionary = {}
	var manual_ids: Array[String] = []
	for question in questions:
		var path := str(question.get("path", "")).strip_edges()
		if path.is_empty():
			continue
		var manual_text := _value_to_text(
			CCFStorageService.get_value_at_path(project, path, "")
		).strip_edges()
		if manual_text.is_empty():
			continue
		var question_id := str(question.get("id", ""))
		answers[question_id] = manual_text
		manual_ids.append(question_id)

	return {
		"questions": questions,
		"answers": answers,
		"manual_ids": manual_ids,
		"concept": str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges(),
		"uses_default_questions": not has_interview_section
	}


func _template_without_interview_sections(template: Dictionary) -> Dictionary:
	var result := template.duplicate(true)
	var kept_sections: Array = []
	var interview_field_ids: Dictionary = {}
	for raw_section in template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		if str(section.get("kind", "standard")) == "interview":
			for raw_field in section.get("fields", []):
				if raw_field is Dictionary:
					interview_field_ids[str(raw_field.get("id", ""))] = true
			continue
		kept_sections.append(section.duplicate(true))
	result["sections"] = kept_sections

	var kept_groups: Array = []
	var groups_value: Variant = result.get("generation_groups", [])
	if groups_value is Array:
		for raw_group in groups_value:
			if not raw_group is Dictionary:
				continue
			var output_field_id := str(raw_group.get("output_field_id", ""))
			if interview_field_ids.has(output_field_id):
				continue
			kept_groups.append(raw_group.duplicate(true))
	result["generation_groups"] = kept_groups
	return result


func _decorate_character_job_with_interview(job_id: String, question_plan: Dictionary) -> void:
	for index in range(_queue.size()):
		var job: Dictionary = _queue[index]
		if str(job.get("id", "")) != job_id:
			continue
		_queue[index] = _configure_interview_job(job, question_plan)
		return
	if str(_active_job.get("id", "")) == job_id:
		_active_job = _configure_interview_job(_active_job, question_plan)


func _configure_interview_job(job_value: Dictionary, question_plan: Dictionary) -> Dictionary:
	var job := job_value.duplicate(true)
	var questions_value: Variant = question_plan.get("questions", [])
	var questions: Array = questions_value.duplicate(true) if questions_value is Array else []
	var answers_value: Variant = question_plan.get("answers", {})
	var answers: Dictionary = answers_value.duplicate(true) if answers_value is Dictionary else {}
	var manual_ids_value: Variant = question_plan.get("manual_ids", [])
	var manual_ids: Array = manual_ids_value.duplicate() if manual_ids_value is Array else []
	var original_payload_value: Variant = job.get("payload", {})
	var original_payload: Dictionary = (
		original_payload_value.duplicate(true) if original_payload_value is Dictionary else {}
	)

	job["interview_questions"] = questions
	job["interview_answers"] = answers
	job["interview_manual_ids"] = manual_ids
	job["interview_retry_attempts"] = 0
	job["interview_character_payload"] = original_payload
	job["interview_uses_default_questions"] = bool(question_plan.get("uses_default_questions", false))

	var unanswered := _unanswered_questions(questions, answers, false)
	if unanswered.is_empty():
		return _prepare_character_stage(job)

	job["interview_stage"] = "planning"
	job["label"] = "Planning character interview"
	job["attempt"] = 0
	job["repair_attempts"] = 0
	job["payload"] = _build_interview_payload(
		original_payload,
		str(question_plan.get("concept", "")),
		unanswered,
		answers,
		false
	)
	return job


func _process_interview_content(content: String) -> void:
	var parse_result: Dictionary = _parse_job_output_with_diagnostics(content, "object")
	if not bool(parse_result.get("ok", false)):
		_active_job["label"] = "Repairing interview response JSON"
		_emit_queue_changed()
		if _start_json_repair(content, "object"):
			return
		var diagnostic := str(parse_result.get("diagnostic", "No valid JSON object was found."))
		_handle_failure(
			"The private generation interview could not be parsed as JSON. %s No character generation was started."
			% diagnostic,
			false
		)
		return

	var parsed_value: Variant = parse_result.get("data", {})
	if not parsed_value is Dictionary:
		_handle_failure(
			"The private generation interview returned the wrong data shape. No character generation was started.",
			false
		)
		return

	var questions_value: Variant = _active_job.get("interview_questions", [])
	var questions: Array = questions_value if questions_value is Array else []
	var answers_value: Variant = _active_job.get("interview_answers", {})
	var answers: Dictionary = answers_value.duplicate(true) if answers_value is Dictionary else {}
	_merge_interview_answers(questions, answers, parsed_value)
	_active_job["interview_answers"] = answers

	var missing_required := _unanswered_questions(questions, answers, true)
	if not missing_required.is_empty():
		var retry_attempts := int(_active_job.get("interview_retry_attempts", 0))
		if retry_attempts < MAX_MISSING_ANSWER_RETRIES:
			_start_missing_answer_retry(missing_required)
			return
		var labels: Array[String] = []
		for raw_question in missing_required:
			if raw_question is Dictionary:
				labels.append(str(raw_question.get("label", raw_question.get("id", "Question"))))
		_handle_failure(
			"The private generation interview still had unanswered required questions after %d targeted retries: %s. No character generation was started."
			% [MAX_MISSING_ANSWER_RETRIES, _join_string_array(labels, ", ")],
			false
		)
		return

	_start_character_after_interview()


func _start_missing_answer_retry(missing_questions: Array) -> void:
	_active_job["interview_retry_attempts"] = int(
		_active_job.get("interview_retry_attempts", 0)
	) + 1
	_active_job["interview_stage"] = "retry"
	_active_job["label"] = "Completing missing interview answers"
	_active_job["attempt"] = 0
	_active_job["repair_attempts"] = 0

	var base_payload_value: Variant = _active_job.get("interview_character_payload", {})
	var base_payload: Dictionary = (
		base_payload_value.duplicate(true) if base_payload_value is Dictionary else {}
	)
	var answers_value: Variant = _active_job.get("interview_answers", {})
	var answers: Dictionary = answers_value if answers_value is Dictionary else {}
	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
	_active_job["payload"] = _build_interview_payload(
		base_payload,
		str(metadata.get("concept", "")),
		missing_questions,
		answers,
		true
	)
	_emit_queue_changed()
	call_deferred("_start_active_request")


func _start_character_after_interview() -> void:
	_active_job = _prepare_character_stage(_active_job)
	_emit_queue_changed()
	call_deferred("_start_active_request")


func _prepare_character_stage(job_value: Dictionary) -> Dictionary:
	var job := job_value.duplicate(true)
	var questions_value: Variant = job.get("interview_questions", [])
	var questions: Array = questions_value if questions_value is Array else []
	var answers_value: Variant = job.get("interview_answers", {})
	var answers: Dictionary = answers_value if answers_value is Dictionary else {}
	var manual_ids_value: Variant = job.get("interview_manual_ids", [])
	var manual_ids: Array = manual_ids_value if manual_ids_value is Array else []
	var payload_value: Variant = job.get("interview_character_payload", {})
	var payload: Dictionary = payload_value.duplicate(true) if payload_value is Dictionary else {}
	var notes := _render_interview_notes(questions, answers)
	payload = _payload_with_interview_notes(payload, notes)

	var answered_count := 0
	var optional_missing_count := 0
	for raw_question in questions:
		if not raw_question is Dictionary:
			continue
		var question: Dictionary = raw_question
		var question_id := str(question.get("id", ""))
		if _answer_has_content(answers.get(question_id, null)):
			answered_count += 1
		elif not bool(question.get("required", false)):
			optional_missing_count += 1

	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	metadata["generation_interview"] = {
		"used": not questions.is_empty(),
		"question_count": questions.size(),
		"answered_count": answered_count,
		"manual_answer_count": manual_ids.size(),
		"ai_answer_count": maxi(0, answered_count - manual_ids.size()),
		"missing_optional_count": optional_missing_count,
		"missing_answer_retries": int(job.get("interview_retry_attempts", 0)),
		"uses_default_questions": bool(job.get("interview_uses_default_questions", false))
	}
	job["metadata"] = metadata
	job["interview_stage"] = "character"
	job["label"] = "Full character generation"
	job["payload"] = payload
	job["attempt"] = 0
	job["repair_attempts"] = 0
	return job


func _build_interview_payload(
	base_payload_value: Dictionary,
	concept: String,
	questions: Array,
	known_answers: Dictionary,
	missing_only: bool
) -> Dictionary:
	var payload := base_payload_value.duplicate(true)
	payload["temperature"] = minf(float(payload.get("temperature", 0.8)), 0.65)
	payload["max_tokens"] = mini(int(payload.get("max_tokens", 6000)), 2600)

	var question_lines: Array[String] = []
	var requested_ids: Array[String] = []
	for raw_question in questions:
		if not raw_question is Dictionary:
			continue
		var question: Dictionary = raw_question
		var question_id := str(question.get("id", "")).strip_edges()
		if question_id.is_empty():
			continue
		requested_ids.append(question_id)
		var requirement := "required" if bool(question.get("required", false)) else "optional"
		question_lines.append(
			"- %s (%s) — %s: %s"
			% [question_id, requirement, str(question.get("label", question_id)), str(question.get("question", ""))]
		)

	var prompt := (
		"Complete a private planning interview before writing the character card. These answers are internal generation notes only; do not write the final card yet and do not imitate a questionnaire in the eventual card."
	)
	if missing_only:
		prompt = "Complete only the missing required answers from an earlier private character-planning interview. Preserve the known answers and do not write the character card yet."
	if not concept.strip_edges().is_empty():
		prompt += "\n\nAUTHORITATIVE CHARACTER CONCEPT:\n%s" % concept.strip_edges()
	var known_text := _render_interview_notes(_questions_from_active_or_empty(), known_answers)
	if not known_text.is_empty():
		prompt += "\n\nKNOWN INTERVIEW ANSWERS — preserve these; do not contradict them:\n%s" % known_text
	prompt += "\n\nQUESTIONS TO ANSWER:\n%s" % _join_string_array(question_lines, "\n")
	prompt += (
		"\n\nReturn one JSON object using exactly these question IDs as keys: %s. Each value must be a useful plain-text answer. "
		+ "Do not return the final card, markdown fences, commentary, or extra keys. Ground answers in the supplied concept; infer sensible connective detail only where the concept leaves room."
	) % _join_string_array(requested_ids, ", ")
	payload["messages"] = [
		{
			"role": "system",
			"content": "You are Character Card Forge's private pre-generation interview planner. Resolve useful character-writing questions without replacing explicit source facts. Return JSON only."
		},
		{"role": "user", "content": prompt}
	]
	return payload


func _payload_with_interview_notes(payload_value: Dictionary, notes: String) -> Dictionary:
	var payload := payload_value.duplicate(true)
	if notes.strip_edges().is_empty():
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
	last_message["content"] = (
		str(last_message.get("content", ""))
		+ "\n\nPRIVATE PRE-GENERATION INTERVIEW NOTES — planning context only; do not copy the question/answer framing into card fields and do not mention that an interview occurred:\n"
		+ notes
		+ "\nUse these notes to deepen and connect the requested fields while keeping the authoritative concept and explicit template requirements higher priority."
	)
	messages[last_index] = last_message
	payload["messages"] = messages
	return payload


func _merge_interview_answers(
	questions: Array, answers: Dictionary, response_data: Dictionary
) -> void:
	var source: Dictionary = response_data
	var nested_value: Variant = response_data.get("answers", null)
	if nested_value is Dictionary:
		source = nested_value
	for raw_question in questions:
		if not raw_question is Dictionary:
			continue
		var question: Dictionary = raw_question
		var question_id := str(question.get("id", ""))
		if question_id.is_empty() or _answer_has_content(answers.get(question_id, null)):
			continue
		var value: Variant = source.get(question_id, null)
		if not _answer_has_content(value):
			var label := str(question.get("label", ""))
			value = source.get(label, null)
		if _answer_has_content(value):
			answers[question_id] = _value_to_text(value).strip_edges()


func _unanswered_questions(
	questions: Array, answers: Dictionary, required_only: bool
) -> Array:
	var result: Array = []
	for raw_question in questions:
		if not raw_question is Dictionary:
			continue
		var question: Dictionary = raw_question
		if required_only and not bool(question.get("required", false)):
			continue
		var question_id := str(question.get("id", ""))
		if not _answer_has_content(answers.get(question_id, null)):
			result.append(question)
	return result


func _answer_has_content(value: Variant) -> bool:
	if value == null:
		return false
	return not _value_to_text(value).strip_edges().is_empty()


func _render_interview_notes(questions: Array, answers: Dictionary) -> String:
	var lines: Array[String] = []
	for raw_question in questions:
		if not raw_question is Dictionary:
			continue
		var question: Dictionary = raw_question
		var question_id := str(question.get("id", ""))
		var answer := _value_to_text(answers.get(question_id, "")).strip_edges()
		if answer.is_empty():
			continue
		lines.append("%s: %s" % [str(question.get("label", question_id)), answer])
	return _join_string_array(lines, "\n")


func _questions_from_active_or_empty() -> Array:
	if _active_job.is_empty():
		return []
	var questions_value: Variant = _active_job.get("interview_questions", [])
	return questions_value if questions_value is Array else []


func _read_default_questions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FileAccess.file_exists(DEFAULT_INTERVIEW_PATH):
		return result
	var file: FileAccess = FileAccess.open(DEFAULT_INTERVIEW_PATH, FileAccess.READ)
	if file == null:
		return result
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return result
	var questions_value: Variant = parsed.get("questions", [])
	if not questions_value is Array:
		return result
	for raw_question in questions_value:
		if not raw_question is Dictionary:
			continue
		var question: Dictionary = raw_question
		var question_id := str(question.get("id", "")).strip_edges()
		var question_text := str(question.get("question", "")).strip_edges()
		if question_id.is_empty() or question_text.is_empty():
			continue
		result.append(
			{
				"id": question_id,
				"label": str(question.get("label", question_id)).strip_edges(),
				"question": question_text,
				"required": bool(question.get("required", true)),
				"path": "",
				"source": "default"
			}
		)
	return result
