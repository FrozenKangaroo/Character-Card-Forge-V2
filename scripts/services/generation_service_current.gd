class_name CCFGenerationServiceCurrent
extends "res://scripts/services/generation_service_v0180_hotfix1.gd"

# Semantic current Text-generation boundary. The v0.18.3, v0.18.6, v0.19.0 and
# v0.19.5 implementations remain available as historical compatibility evidence,
# while the live runtime composes their public behavior here without four active
# inheritance hops.
const AI_REVIEW_SERVICE_CURRENT = preload(
	"res://scripts/services/ai_review_service_v0183.gd"
)
const COMPACT_DERIVATIVE_SERVICE_CURRENT = preload(
	"res://scripts/services/compact_derivative_service_v0186.gd"
)
const RICH_AUTHORING_SERVICE_CURRENT = preload(
	"res://scripts/services/rich_authoring_service_v0190.gd"
)
const IDEA_CUSTOM_LENGTH_V0211 = preload(
	"res://scripts/services/idea_generator_custom_length_v0211.gd"
)
const IDEA_BATCHING_V0211 = preload(
	"res://scripts/services/idea_generator_batching_v0211.gd"
)
const IDEA_DIVERSITY_V0214 = preload(
	"res://scripts/services/idea_diversity_guardrails_v0214.gd"
)
const IDEA_FINAL_REVIEW_V0218 = preload(
	"res://scripts/services/idea_final_review_service_v0218.gd"
)

const ROUTING_FORMAT_VERSION_V0195 := 1
const ROUTING_PROFILE_KEY_V0195 := "_ccf_text_routing_v0195"


func queue_idea_source_title_v0213(
	source_context: String,
	profile: Dictionary,
	retry_count: int,
	project_id: String = "",
	source_id: String = ""
) -> Dictionary:
	var clean_context := source_context.strip_edges()
	if clean_context.is_empty():
		return {"ok": false, "error": "Idea Source context is required for naming."}
	var messages := [
		{
			"role": "system",
			"content": (
				"You name reusable character-idea Series and scenario engines. Return JSON only as an object with exactly one key, title. The title must be concise, distinctive and describe the reusable engine rather than one generated character."
			)
		},
		{
			"role": "user",
			"content": (
				"Suggest one editable reusable Idea Source name for this structured input. Do not generate an Idea or rename any existing user title.\n\n%s"
				% clean_context
			)
		}
	]
	return _queue_chat_job(
		"idea_source_title",
		"Suggest Idea Source name",
		profile,
		messages,
		"object",
		{
			"project_id": project_id,
			"idea_source_id": source_id,
			"idea_source_title_contract": 1
		},
		retry_count
	)


func queue_idea_generation_with_custom_length_v0211(
	seed_text: String,
	profile: Dictionary,
	idea_count: int,
	retry_count: int,
	project_id: String = "",
	series_context: String = "",
	target_characters: int = CCFIdeaGeneratorCustomLengthV0211.DEFAULT_TARGET_CHARACTERS
) -> Dictionary:
	var target := IDEA_CUSTOM_LENGTH_V0211.normalise_target_characters(
		target_characters
	)
	var result := super.queue_idea_generation(
		seed_text,
		profile,
		idea_count,
		retry_count,
		project_id,
		series_context
	)
	if not bool(result.get("ok", false)):
		return result
	var budget := _decorate_queued_idea_custom_length_v0211(
		str(result.get("job_id", "")), target
	)
	result["target_characters_per_idea"] = target
	result["request_max_tokens"] = int(budget.get("effective_output_tokens", 0))
	result["budget_limited"] = bool(budget.get("budget_limited", false))
	return result


func idea_custom_length_capabilities_v0211() -> Dictionary:
	return {
		"contract_version": IDEA_CUSTOM_LENGTH_V0211.CONTRACT_VERSION,
		"minimum_target_characters": IDEA_CUSTOM_LENGTH_V0211.MIN_TARGET_CHARACTERS,
		"maximum_target_characters": IDEA_CUSTOM_LENGTH_V0211.MAX_TARGET_CHARACTERS,
		"default_target_characters": IDEA_CUSTOM_LENGTH_V0211.DEFAULT_TARGET_CHARACTERS,
		"tolerance_percent": IDEA_CUSTOM_LENGTH_V0211.TARGET_TOLERANCE_PERCENT,
		"profile_output_cap_preserved": true,
		"advisory_not_validation_failure": true,
		"actual_counts_in_metadata": true
	}


func decorate_idea_batch_job_v0211(
	job_id: String,
	group_id: String,
	batch_index: int,
	request_count: int,
	requested_total: int,
	anti_repeat_context: String = "",
	request_kind: String = "normal"
) -> bool:
	if job_id.is_empty() or group_id.is_empty():
		return false
	for index in range(_queue.size()):
		var job_value: Variant = _queue[index]
		if not job_value is Dictionary:
			continue
		var job: Dictionary = job_value
		if str(job.get("id", "")) != job_id or str(job.get("type", "")) != "ideas":
			continue
		_queue[index] = _idea_job_with_batch_metadata_v0211(
			job, group_id, batch_index, request_count, requested_total,
			anti_repeat_context, request_kind
		)
		return true
	if (
		not _active_job.is_empty()
		and str(_active_job.get("id", "")) == job_id
		and str(_active_job.get("type", "")) == "ideas"
	):
		_active_job = _idea_job_with_batch_metadata_v0211(
			_active_job, group_id, batch_index, request_count, requested_total,
			anti_repeat_context, request_kind
		)
		return true
	return false


func idea_batching_capabilities_v0211() -> Dictionary:
	return IDEA_BATCHING_V0211.capabilities()


func _idea_job_with_batch_metadata_v0211(
	job_value: Dictionary,
	group_id: String,
	batch_index: int,
	request_count: int,
	requested_total: int,
	anti_repeat_context: String = "",
	request_kind: String = "normal"
) -> Dictionary:
	var job := job_value.duplicate(true)
	var payload_value: Variant = job.get("payload", {})
	var payload: Dictionary = (
		(payload_value as Dictionary).duplicate(true)
		if payload_value is Dictionary
		else {}
	)
	var messages_value: Variant = payload.get("messages", [])
	var messages: Array = (
		messages_value.duplicate(true) if messages_value is Array else []
	)
	var instruction := IDEA_BATCHING_V0211.prompt_instruction(
		batch_index, request_count, requested_total
	)
	var clean_anti_repeat := anti_repeat_context.strip_edges()
	if not clean_anti_repeat.is_empty():
		instruction += "\n\n" + clean_anti_repeat
	if request_kind == "top_up":
		instruction += (
			"\n\nFINAL ONE-SHOT RECOVERY REQUEST:\n"
			+ "- These are replacement ideas for still-unfilled accepted slots.\n"
			+ "- Make every replacement materially distinct from both accepted and rejected ledger entries.\n"
			+ "- This recovery is attempted once; prioritize usable, structurally novel results."
		)
	for message_index in range(messages.size()):
		if not messages[message_index] is Dictionary:
			continue
		var message: Dictionary = (
			messages[message_index] as Dictionary
		).duplicate(true)
		if str(message.get("role", "")) != "system":
			continue
		message["content"] = str(message.get("content", "")) + "\n\n" + instruction
		messages[message_index] = message
		break
	payload["messages"] = messages
	job["payload"] = payload
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = (
		(metadata_value as Dictionary).duplicate(true)
		if metadata_value is Dictionary
		else {}
	)
	metadata["idea_batch_contract_version"] = IDEA_BATCHING_V0211.CONTRACT_VERSION
	metadata["idea_batch_group_id"] = group_id
	metadata["idea_batch_index"] = batch_index
	metadata["idea_batch_request_count"] = request_count
	metadata["idea_batch_requested_total"] = requested_total
	metadata["idea_batch_request_size"] = int(metadata.get("idea_count", 1))
	metadata["idea_batch_request_kind"] = request_kind
	metadata["idea_diversity_context_injected"] = not clean_anti_repeat.is_empty()
	job["metadata"] = metadata
	job["label"] = "%s • %s %d/%d" % [
		str(job.get("label", "Generate character ideas")),
		"recovery" if request_kind == "top_up" else "request",
		batch_index + 1,
		request_count
	]
	return job


func queue_idea_similarity_review_v0214(
	session: Dictionary,
	profile: Dictionary,
	retry_count: int,
	project_id: String = ""
) -> Dictionary:
	var accepted_value: Variant = session.get("accepted", [])
	if not accepted_value is Array or (accepted_value as Array).is_empty():
		return {"ok": false, "error": "At least one accepted idea is required for final review."}
	var check_adherence := bool(session.get("final_review_check_adherence", false))
	var check_similarity := bool(session.get("final_review_check_similarity", false))
	if not check_adherence and not check_similarity:
		check_similarity = str(session.get("final_review_mode", "off")) != "off"
	if check_similarity and not check_adherence and (accepted_value as Array).size() < 2:
		return {"ok": false, "error": "At least two accepted ideas are required for similarity-only review."}
	var prompt := IDEA_FINAL_REVIEW_V0218.final_review_prompt(session)
	var generation_context := IDEA_DIVERSITY_V0214.normalise_generation_context(
		session.get("generation_context", {})
	)
	var result := _queue_chat_job(
		"idea_similarity_review",
		"Final advisory review of generated ideas",
		profile,
		[
			{
				"role": "system",
				"content": (
					"You provide an advisory final review of generated roleplay ideas. Check only the requested dimensions: adherence to frozen user requirements and/or scenario-level similarity. Requested invariants are not duplicate evidence. Never choose a winner, reject an Idea or imply that a finding must be followed. Return valid JSON only."
				)
			},
			{"role": "user", "content": prompt}
		],
		"object",
		{
			"project_id": project_id,
			"idea_diversity_contract_version": IDEA_DIVERSITY_V0214.CONTRACT_VERSION,
			"idea_similarity_review_mode": str(session.get("final_review_mode", "off")),
			"idea_final_review_contract_version": IDEA_FINAL_REVIEW_V0218.CONTRACT_VERSION,
			"idea_review_check_adherence": check_adherence,
			"idea_review_check_similarity": check_similarity,
			"idea_similarity_review_count": IDEA_FINAL_REVIEW_V0218.review_scope_ids(
				session
			).size(),
			"idea_similarity_reference_count": (
				(accepted_value as Array).size()
				- IDEA_FINAL_REVIEW_V0218.review_scope_ids(session).size()
			),
			"idea_similarity_context_present": not generation_context.is_empty(),
			"idea_similarity_context_mode": str(generation_context.get("prompt_mode", "")),
			"idea_similarity_source_context_present": not str(
				generation_context.get("idea_source_context", "")
			).is_empty()
		},
		retry_count
	)
	return result


func idea_diversity_capabilities_v0214() -> Dictionary:
	var capabilities := IDEA_DIVERSITY_V0214.capabilities()
	capabilities["final_idea_review"] = IDEA_FINAL_REVIEW_V0218.capabilities()
	return capabilities


func _decorate_queued_idea_custom_length_v0211(
	job_id: String, target_characters: int
) -> Dictionary:
	if job_id.is_empty():
		return {}
	for index in range(_queue.size()):
		var job_value: Variant = _queue[index]
		if not job_value is Dictionary:
			continue
		var job: Dictionary = job_value
		if str(job.get("id", "")) != job_id or str(job.get("type", "")) != "ideas":
			continue
		var queued_decoration := _idea_job_with_custom_length_v0211(
			job, target_characters
		)
		_queue[index] = queued_decoration.get("job", job)
		return queued_decoration.get("budget", {})
	if (
		not _active_job.is_empty()
		and str(_active_job.get("id", "")) == job_id
		and str(_active_job.get("type", "")) == "ideas"
	):
		var active_decoration := _idea_job_with_custom_length_v0211(
			_active_job, target_characters
		)
		_active_job = active_decoration.get("job", _active_job)
		return active_decoration.get("budget", {})
	return {}


func _idea_job_with_custom_length_v0211(
	job_value: Dictionary, target_characters: int
) -> Dictionary:
	var job := job_value.duplicate(true)
	var payload_value: Variant = job.get("payload", {})
	var payload: Dictionary = (
		(payload_value as Dictionary).duplicate(true)
		if payload_value is Dictionary
		else {}
	)
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = (
		(metadata_value as Dictionary).duplicate(true)
		if metadata_value is Dictionary
		else {}
	)
	var profile_limit := int(metadata.get(
		"idea_custom_profile_max_output_tokens",
		payload.get("max_tokens", 6000)
	))
	var budget := IDEA_CUSTOM_LENGTH_V0211.output_budget(
		target_characters,
		int(metadata.get("idea_count", 1)),
		profile_limit
	)
	var instruction := IDEA_CUSTOM_LENGTH_V0211.prompt_instruction(
		target_characters
	)
	var messages_value: Variant = payload.get("messages", [])
	var messages: Array = (
		messages_value.duplicate(true) if messages_value is Array else []
	)
	for message_index in range(messages.size()):
		if not messages[message_index] is Dictionary:
			continue
		var message: Dictionary = (messages[message_index] as Dictionary).duplicate(true)
		if str(message.get("role", "")) != "system":
			continue
		var content := str(message.get("content", ""))
		if not content.contains("CUSTOM IDEA LENGTH TARGET:"):
			message["content"] = content + "\n\n" + instruction
			messages[message_index] = message
		break
	payload["messages"] = messages
	payload["max_tokens"] = int(budget.get("effective_output_tokens", profile_limit))
	job["payload"] = payload
	metadata["idea_detail_contract_version"] = 2
	metadata["idea_detail_level"] = "custom"
	metadata["idea_detail_label"] = "Custom"
	metadata["idea_custom_length_contract_version"] = (
		IDEA_CUSTOM_LENGTH_V0211.CONTRACT_VERSION
	)
	metadata["idea_custom_target_characters"] = int(
		budget.get("target_characters_per_idea", target_characters)
	)
	metadata["idea_custom_tolerance_percent"] = (
		IDEA_CUSTOM_LENGTH_V0211.TARGET_TOLERANCE_PERCENT
	)
	metadata["idea_custom_requested_output_tokens"] = int(
		budget.get("requested_output_tokens", 0)
	)
	metadata["idea_custom_profile_max_output_tokens"] = int(
		budget.get("profile_max_output_tokens", profile_limit)
	)
	metadata["idea_output_max_tokens"] = int(
		budget.get("effective_output_tokens", profile_limit)
	)
	metadata["idea_custom_budget_limited"] = bool(
		budget.get("budget_limited", false)
	)
	job["metadata"] = metadata
	return {"job": job, "budget": budget}


func _start_idea_semantic_repair(ideas: Array, issues: Array) -> void:
	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = (
		metadata_value if metadata_value is Dictionary else {}
	)
	var target := int(metadata.get("idea_custom_target_characters", 0))
	super._start_idea_semantic_repair(ideas, issues)
	if target <= 0 or _active_job.is_empty():
		return
	var decorated := _idea_job_with_custom_length_v0211(
		_active_job, target
	)
	_active_job = decorated.get("job", _active_job)


func _validate_idea_batch(ideas: Array, idea_seed_text: String) -> Dictionary:
	var result := super._validate_idea_batch(ideas, idea_seed_text)
	if _active_job.is_empty():
		return result
	var metadata_value: Variant = _active_job.get("metadata", {})
	if not metadata_value is Dictionary:
		return result
	var metadata: Dictionary = (metadata_value as Dictionary).duplicate(true)
	_record_idea_validation_ledger_v0214(ideas, result, metadata)
	var target := int(metadata.get("idea_custom_target_characters", 0))
	if target <= 0:
		_active_job["metadata"] = metadata
		return result
	var accepted_value: Variant = result.get("valid_ideas", [])
	var accepted: Array = accepted_value if accepted_value is Array else []
	var counts := IDEA_CUSTOM_LENGTH_V0211.actual_counts(accepted)
	var target_met := 0
	for actual_count in counts:
		if IDEA_CUSTOM_LENGTH_V0211.count_within_target(actual_count, target):
			target_met += 1
	metadata["idea_actual_character_counts"] = counts
	metadata["idea_custom_target_met_count"] = target_met
	metadata["idea_custom_result_count"] = counts.size()
	_active_job["metadata"] = metadata
	return result


func _record_idea_validation_ledger_v0214(
	raw_ideas: Array, validation: Dictionary, metadata: Dictionary
) -> void:
	var semantic_attempts := int(metadata.get("semantic_repair_attempts", 0))
	metadata["idea_diversity_validation_candidate_count"] = int(
		metadata.get("idea_diversity_validation_candidate_count", 0)
	) + raw_ideas.size()
	if semantic_attempts <= 0:
		metadata["idea_diversity_initial_generated_candidate_count"] = int(
			metadata.get("idea_diversity_initial_generated_candidate_count", 0)
		) + raw_ideas.size()
	else:
		metadata["idea_diversity_semantic_repair_candidate_count"] = int(
			metadata.get("idea_diversity_semantic_repair_candidate_count", 0)
		) + raw_ideas.size()
		var recorded_repairs := int(metadata.get(
			"idea_diversity_recorded_semantic_repair_attempts", 0
		))
		if semantic_attempts > recorded_repairs:
			metadata["idea_diversity_semantic_repair_pass_count"] = int(
				metadata.get("idea_diversity_semantic_repair_pass_count", 0)
			) + (semantic_attempts - recorded_repairs)
			metadata["idea_diversity_recorded_semantic_repair_attempts"] = (
				semantic_attempts
			)
	# Retain the original metadata key for diagnostic/backwards compatibility.
	# It now explicitly aliases validation-pass candidates and is not shown as raw.
	metadata["idea_diversity_raw_candidate_count"] = int(
		metadata.get("idea_diversity_validation_candidate_count", 0)
	)
	var accepted_signatures: Dictionary = {}
	var valid_value: Variant = validation.get("valid_ideas", [])
	if valid_value is Array:
		for accepted_value in valid_value as Array:
			if accepted_value is Dictionary:
				var signature := _idea_validation_signature_v0214(
					accepted_value as Dictionary
				)
				accepted_signatures[signature] = int(accepted_signatures.get(signature, 0)) + 1
	var issues_value: Variant = validation.get("issues", [])
	var issues: Array = issues_value if issues_value is Array else []
	var rejected_value: Variant = metadata.get(
		"idea_diversity_validation_rejections", []
	)
	var rejected: Array = (
		(rejected_value as Array).duplicate(true)
		if rejected_value is Array
		else []
	)
	for index in range(raw_ideas.size()):
		var idea_value: Variant = raw_ideas[index]
		if not idea_value is Dictionary:
			rejected.append({
				"summary": str(idea_value),
				"reason": _validation_issue_for_index_v0214(issues, index)
			})
			continue
		var signature := _idea_validation_signature_v0214(
			idea_value as Dictionary
		)
		var accepted_remaining := int(accepted_signatures.get(signature, 0))
		if accepted_remaining > 0:
			accepted_signatures[signature] = accepted_remaining - 1
			continue
		rejected.append({
			"idea": (idea_value as Dictionary).duplicate(true),
			"reason": _validation_issue_for_index_v0214(issues, index)
		})
	metadata["idea_diversity_validation_rejections"] = rejected


func _idea_validation_signature_v0214(idea: Dictionary) -> String:
	var parts: Array[String] = []
	for field_id in [
		"title", "character_name", "character_role", "source_anchor",
		"roleplay_hook", "concept"
	]:
		parts.append(str(idea.get(field_id, "")).strip_edges())
	return "\u001f".join(parts)


func _validation_issue_for_index_v0214(issues: Array, index: int) -> String:
	var prefix := "Idea %d" % (index + 1)
	for issue_value in issues:
		var issue := str(issue_value)
		if issue.begins_with(prefix):
			return issue
	return "Rejected by generation validation."


func recover_safe_text_candidate_v0180_hotfix1(
	section: Dictionary, content: String
) -> Dictionary:
	var recovered := super.recover_safe_text_candidate_v0180_hotfix1(
		section, content
	)
	if not bool(recovered.get("ok", false)):
		return recovered
	var field_id := str(
		section.get(
			"field_id",
			(section.get("field", {}) as Dictionary).get("id", "")
		)
	)
	var cleaned := clean_generated_text_v0209(
		field_id, str(recovered.get("value", ""))
	)
	recovered["value"] = str(cleaned.get("value", ""))
	if bool(cleaned.get("removed_trailing_wrapper", false)):
		recovered["source"] = (
			str(recovered.get("source", "plain_text"))
			+ "_trailing_wrapper_removed"
		)
	return recovered


func clean_generated_text_v0209(
	field_id: String, generated_text: String
) -> Dictionary:
	var cleaned := generated_text.strip_edges()
	if field_id not in ["first_message", "first_mes", "greeting"]:
		return {"value": cleaned, "removed_trailing_wrapper": false}
	var expression := RegEx.new()
	var compiled := expression.compile(
		"(?s)\\n\\s*\\{\\s*\"(?:first_message|first_mes|greeting)\"\\s*:"
	)
	if compiled != OK:
		return {"value": cleaned, "removed_trailing_wrapper": false}
	var matched := expression.search(cleaned)
	if matched == null:
		return {"value": cleaned, "removed_trailing_wrapper": false}
	var authored_prefix := cleaned.substr(0, matched.get_start()).strip_edges()
	if authored_prefix.is_empty():
		return {"value": cleaned, "removed_trailing_wrapper": false}
	return {"value": authored_prefix, "removed_trailing_wrapper": true}


func _accept_safe_field_v01522(
	section: Dictionary, value: Variant, has_value: bool
) -> void:
	var field_id := str(
		section.get(
			"field_id",
			(section.get("field", {}) as Dictionary).get("id", "")
		)
	)
	var accepted_value: Variant = value
	if has_value and value is String:
		accepted_value = clean_generated_text_v0209(
			field_id, str(value)
		).get("value", value)
	super._accept_safe_field_v01522(section, accepted_value, has_value)


func _front_porch_type_instruction_v0172(field: Dictionary) -> String:
	if str(field.get("id", "")) == "fp_work_days":
		return (
			"one JSON integer array using Monday=1, Tuesday=2, Wednesday=3, "
			+ "Thursday=4, Friday=5, Saturday=6, Sunday=7; for a normal "
			+ "weekday schedule return exactly [1,2,3,4,5], never day-name prose"
		)
	if str(field.get("id", "")) == "fp_work_hours":
		return (
			"one exact Front Porch clock range string such as 9am–5pm "
			+ "or 9:30am–5:15pm; use actual start and end times, never prose"
		)
	return super._front_porch_type_instruction_v0172(field)


func _prepare_front_porch_fields_v0175(
	fields: Array[Dictionary]
) -> Array[Dictionary]:
	var prepared := super._prepare_front_porch_fields_v0175(fields)
	for index in range(prepared.size()):
		var field := prepared[index]
		var field_id := str(field.get("id", ""))
		if field_id not in ["fp_work_days", "fp_work_hours"]:
			continue
		var guidance := str(field.get("generation_prompt", "")).strip_edges()
		if not guidance.is_empty():
			guidance += " "
		if field_id == "fp_work_days":
			guidance += (
				"Return only a JSON integer array where Monday=1, Tuesday=2, "
				+ "Wednesday=3, Thursday=4, Friday=5, Saturday=6 and Sunday=7. "
				+ "Example weekday schedule: [1,2,3,4,5]. Never return day-name prose."
			)
		else:
			guidance += (
				"Return only a real start–end clock range compatible with Front Porch, "
				+ "for example 9am–5pm or 9:30am–5:15pm. Do not describe holidays, "
				+ "availability, flexible schedules or days off in this field."
			)
		field["generation_prompt"] = guidance
		prepared[index] = field
	return prepared


func queue_ai_review_v0183(
	project: Dictionary,
	character_id: String,
	profile: Dictionary,
	retry_count: int = 1
) -> Dictionary:
	var request := AI_REVIEW_SERVICE_CURRENT.build_request(project, character_id)
	if not bool(request.get("ok", false)):
		return request
	return _queue_chat_job(
		"ai_review",
		"AI character review",
		profile,
		request.get("messages", []),
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"character_id": character_id,
			"content_hash": str(request.get("content_hash", "")),
			"rubric_version": AI_REVIEW_SERVICE_CURRENT.RUBRIC_VERSION
		},
		retry_count
	)


func queue_compact_derivative_v0186(
	project: Dictionary,
	character_id: String,
	options: Dictionary,
	profile: Dictionary,
	retry_count: int = 1
) -> Dictionary:
	var request := COMPACT_DERIVATIVE_SERVICE_CURRENT.build_request(
		project, character_id, options
	)
	if not bool(request.get("ok", false)):
		return request
	return _queue_chat_job(
		"compact_derivative",
		"Compact/lite derivative preview",
		profile,
		request.get("messages", []),
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"character_id": character_id,
			"source_hash": str(request.get("source_hash", "")),
			"compact_options": request.get("options", {}).duplicate(true)
		},
		retry_count
	)


func queue_split_character_set_v0190(
	project: Dictionary,
	batch_id: String,
	retry_character_ids: Array[String],
	profile: Dictionary,
	retry_count: int = 1
) -> Dictionary:
	var request := RICH_AUTHORING_SERVICE_CURRENT.build_split_request(
		project, batch_id, retry_character_ids
	)
	if not bool(request.get("ok", false)):
		return request
	return _queue_chat_job(
		"split_character_set_v0190",
		"Generate split character set",
		profile,
		request.get("messages", []),
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"batch_id": batch_id,
			"model": str(profile.get("model", "")),
			"profile_id": str(profile.get("id", profile.get("profile_id", ""))),
			"profile_name": str(profile.get("name", "")),
			"requested_character_ids": request.get(
				"requested_character_ids", []
			).duplicate(true)
		},
		retry_count
	)


func text_routing_capabilities_v0195() -> Dictionary:
	return {
		"format_version": ROUTING_FORMAT_VERSION_V0195,
		"primary_is_default": true,
		"fast_suggestion_route": true,
		"deep_review_route": true,
		"single_technical_fallback": true,
		"content_failure_fallback": false,
		"fallback_chains": false,
		"actual_producer_provenance": true
	}


func _queue_chat_job(
	job_type: String,
	label: String,
	profile: Dictionary,
	messages: Array,
	parse_mode: String,
	metadata: Dictionary,
	retry_count: int
) -> Dictionary:
	var routed_metadata := metadata.duplicate(true)
	var routing_value: Variant = profile.get(ROUTING_PROFILE_KEY_V0195, {})
	var routing: Dictionary = (
		routing_value.duplicate(true) if routing_value is Dictionary else {}
	)
	if not routing.is_empty():
		routed_metadata["text_routing"] = {
			"format_version": ROUTING_FORMAT_VERSION_V0195,
			"requested_task": str(routing.get("requested_task", "primary")),
			"requested_role": str(routing.get("requested_role", "text")),
			"selected_profile_id": str(routing.get("selected_profile_id", "")),
			"inherited_primary": bool(routing.get("inherited_primary", false)),
			"fallback_enabled": bool(routing.get("fallback_enabled", false)),
			"fallback_used": false
		}
		routed_metadata["profile_id"] = str(
			routing.get("selected_profile_id", profile.get("id", ""))
		)
	var result := super._queue_chat_job(
		job_type,
		label,
		profile,
		messages,
		parse_mode,
		routed_metadata,
		retry_count
	)
	if not bool(result.get("ok", false)) or routing.is_empty():
		return result
	var job_id := str(result.get("job_id", ""))
	for index in range(_queue.size()):
		var queued_value: Variant = _queue[index]
		if not queued_value is Dictionary:
			continue
		var queued: Dictionary = queued_value
		if str(queued.get("id", "")) != job_id:
			continue
		queued["text_routing_v0195"] = routing.duplicate(true)
		queued["fallback_used_v0195"] = false
		_queue[index] = queued
		break
	return result


func _on_request_completed(
	result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
) -> void:
	if not _active_job.is_empty():
		_active_job.erase("technical_failure_category_v0195")
		var category := _technical_failure_category_v0195(
			result, response_code, body.get_string_from_utf8()
		)
		if not category.is_empty():
			_active_job["technical_failure_category_v0195"] = category
	super._on_request_completed(result, response_code, headers, body)


func _start_active_request() -> void:
	if not _active_job.is_empty():
		_active_job.erase("technical_failure_category_v0195")
	super._start_active_request()


func _handle_failure(message: String, retryable: bool) -> void:
	if _active_job.is_empty():
		return
	var attempt := int(_active_job.get("attempt", 1))
	var maximum_retries := int(_active_job.get("max_retries", 0))
	var terminal := not (retryable and attempt <= maximum_retries)
	if not terminal:
		super._handle_failure(message, retryable)
		return

	var category := str(
		_active_job.get("technical_failure_category_v0195", "")
	)
	if category.is_empty() and message.begins_with("Could not start API request"):
		category = "request_start"
	if _can_use_fallback_v0195(category):
		_start_fallback_v0195(category, message)
		return
	if bool(_active_job.get("fallback_used_v0195", false)):
		var routing := _routing_from_active_job_v0195()
		var fallback_profile: Dictionary = routing.get("fallback_profile", {})
		message = "Fallback profile %s also failed. %s" % [
			str(fallback_profile.get("name", "Fallback Text")), message
		]
	super._handle_failure(message, retryable)


func _can_use_fallback_v0195(category: String) -> bool:
	if category not in [
		"network", "request_start", "endpoint_or_model", "rate_limit", "service"
	]:
		return false
	if bool(_active_job.get("fallback_used_v0195", false)):
		return false
	var routing := _routing_from_active_job_v0195()
	if routing.is_empty() or not bool(routing.get("fallback_enabled", false)):
		return false
	var fallback_value: Variant = routing.get("fallback_profile", {})
	if not fallback_value is Dictionary or fallback_value.is_empty():
		return false
	var fallback_profile: Dictionary = fallback_value
	var fallback_id := str(fallback_profile.get("id", "")).strip_edges()
	var selected_id := str(routing.get("selected_profile_id", "")).strip_edges()
	if fallback_id.is_empty() or fallback_id == selected_id:
		return false
	return (
		not str(fallback_profile.get("base_url", "")).strip_edges().is_empty()
		and not str(fallback_profile.get("model", "")).strip_edges().is_empty()
	)


func _start_fallback_v0195(category: String, failure_message: String) -> void:
	_release_scheduler_lease_v01526()
	var routing := _routing_from_active_job_v0195()
	var fallback_profile: Dictionary = routing.get("fallback_profile", {}).duplicate(true)
	if str(_active_job.get("type", "")).begins_with("collaborator_"):
		fallback_profile = CCFCollaboratorTokenBudgetCurrent.request_profile(fallback_profile)
	var previous_profile := {
		"profile_id": str(routing.get("selected_profile_id", "")),
		"profile_name": str(_active_job.get("profile_name", "")),
		"model": str(_active_job.get("model", "")),
		"attempts": int(_active_job.get("attempt", 1))
	}
	var fallback_record := {
		"used": true,
		"category": category,
		"reason": failure_message,
		"from": previous_profile,
		"to": {
			"profile_id": str(fallback_profile.get("id", "")),
			"profile_name": str(fallback_profile.get("name", "Fallback Text")),
			"model": str(fallback_profile.get("model", ""))
		}
	}

	_active_job["fallback_used_v0195"] = true
	_active_job["technical_failure_category_v0195"] = ""
	_active_job["url"] = _completion_url(
		str(fallback_profile.get("base_url", ""))
	)
	_active_job["headers"] = _request_headers(fallback_profile)
	_active_job["profile_name"] = str(
		fallback_profile.get("name", "Fallback Text")
	)
	_active_job["model"] = str(fallback_profile.get("model", ""))
	_active_job["attempt"] = 0
	_active_job["max_retries"] = 0
	var payload: Dictionary = _active_job.get("payload", {}).duplicate(true)
	payload["model"] = str(fallback_profile.get("model", ""))
	payload["temperature"] = float(fallback_profile.get("temperature", 0.8))
	payload["max_tokens"] = int(
		fallback_profile.get("max_output_tokens", 6000)
	)
	_active_job["payload"] = payload
	var metadata: Dictionary = _active_job.get("metadata", {}).duplicate(true)
	metadata["profile_id"] = str(fallback_profile.get("id", ""))
	metadata["fallback"] = fallback_record.duplicate(true)
	var public_routing: Dictionary = metadata.get("text_routing", {}).duplicate(true)
	public_routing["fallback_used"] = true
	public_routing["producing_profile_id"] = str(
		fallback_profile.get("id", "")
	)
	metadata["text_routing"] = public_routing
	_active_job["metadata"] = metadata
	_append_diagnostic_event_v01522("text_fallback", fallback_record)

	job_started.emit(
		str(_active_job.get("id", "")),
		str(_active_job.get("type", "")),
		"Fallback Text: %s → %s" % [
			str(previous_profile.get("profile_name", "Primary Text")),
			str(fallback_profile.get("name", "Fallback Text"))
		]
	)
	call_deferred("_start_active_request")


func _routing_from_active_job_v0195() -> Dictionary:
	var value: Variant = _active_job.get("text_routing_v0195", {})
	return value if value is Dictionary else {}


func _technical_failure_category_v0195(
	result: int, response_code: int, response_body: String = ""
) -> String:
	if result != HTTPRequest.RESULT_SUCCESS:
		return "network"
	if response_code in [404, 408, 410]:
		return "endpoint_or_model"
	if response_code in [400, 422]:
		var detail := response_body.to_lower()
		var names_model := detail.contains("model") or detail.contains("endpoint")
		var unavailable := (
			detail.contains("not found")
			or detail.contains("unavailable")
			or detail.contains("not available")
			or detail.contains("does not exist")
			or detail.contains("no endpoints")
		)
		if names_model and unavailable:
			return "endpoint_or_model"
	if response_code == 429:
		return "rate_limit"
	if response_code >= 500:
		return "service"
	return ""
