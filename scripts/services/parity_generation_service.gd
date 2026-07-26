class_name CCFParityGenerationService
extends CCFGenerationService

const MAX_SEMANTIC_REPAIR_ATTEMPTS := 1


func queue_character_generation(
	project: Dictionary,
	template: Dictionary,
	profile: Dictionary,
	include_existing_fields: bool,
	retry_count: int
) -> Dictionary:
	var result: Dictionary = super.queue_character_generation(
		project, template, profile, include_existing_fields, retry_count
	)
	if not bool(result.get("ok", false)):
		return result

	var job_id := str(result.get("job_id", ""))
	if job_id.is_empty():
		return result
	var contract := CCFGenerationContractService.contract_for_template(template)
	_decorate_character_job(job_id, contract)
	return result


func _process_completed_content(content: String) -> void:
	if _active_job.is_empty() or str(_active_job.get("type", "")) != "character":
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
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	var contract_value: Variant = metadata.get("generation_contract", {})
	var contract: Dictionary = contract_value if contract_value is Dictionary else {}
	if contract.is_empty():
		super._process_completed_content(content)
		return

	var report := CCFGenerationContractService.validate_generated_data(parsed_data, contract)
	var semantic_attempts := int(_active_job.get("semantic_repair_attempts", 0))
	if not bool(report.get("ok", false)) and semantic_attempts < MAX_SEMANTIC_REPAIR_ATTEMPTS:
		_start_semantic_repair(parsed_data, report, contract)
		return

	metadata["generation_contract_report"] = report.duplicate(true)
	metadata["semantic_repair_attempts"] = semantic_attempts
	metadata["semantic_repair_used"] = semantic_attempts > 0
	_active_job["metadata"] = metadata
	super._process_completed_content(content)


func _decorate_character_job(job_id: String, contract: Dictionary) -> void:
	var contract_text := CCFGenerationContractService.prompt_text(contract)
	for index in range(_queue.size()):
		var job: Dictionary = _queue[index]
		if str(job.get("id", "")) != job_id:
			continue
		job["semantic_repair_attempts"] = 0
		var metadata_value: Variant = job.get("metadata", {})
		var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
		metadata["generation_contract"] = contract.duplicate(true)
		job["metadata"] = metadata
		job["payload"] = _payload_with_contract(job.get("payload", {}), contract_text)
		_queue[index] = job
		return

	if str(_active_job.get("id", "")) == job_id:
		_active_job["semantic_repair_attempts"] = 0
		var active_metadata_value: Variant = _active_job.get("metadata", {})
		var active_metadata: Dictionary = (
			active_metadata_value.duplicate(true) if active_metadata_value is Dictionary else {}
		)
		active_metadata["generation_contract"] = contract.duplicate(true)
		_active_job["metadata"] = active_metadata
		_active_job["payload"] = _payload_with_contract(
			_active_job.get("payload", {}), contract_text
		)


func _payload_with_contract(payload_value: Variant, contract_text: String) -> Dictionary:
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
	if str(last_message.get("role", "")) == "user":
		var current_content := str(last_message.get("content", ""))
		last_message["content"] = (
			current_content
			+ "\n\n"
			+ contract_text
			+ "\nTreat this contract as part of the requested output shape. Do not omit required keys or labelled components merely to be concise."
		)
		messages[last_index] = last_message
		payload["messages"] = messages
	return payload


func _start_semantic_repair(
	current_data: Dictionary, report: Dictionary, contract: Dictionary
) -> void:
	_active_job["semantic_repair_attempts"] = int(
		_active_job.get("semantic_repair_attempts", 0)
	) + 1
	_active_job["label"] = "Repairing incomplete character generation"

	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	metadata["semantic_repair_trigger_report"] = report.duplicate(true)
	_active_job["metadata"] = metadata

	var payload_value: Variant = _active_job.get("payload", {})
	var payload: Dictionary = payload_value.duplicate(true) if payload_value is Dictionary else {}
	payload["temperature"] = minf(float(payload.get("temperature", 0.8)), 0.35)

	var field_ids: Array[String] = []
	var raw_field_ids: Variant = metadata.get("field_ids", [])
	if raw_field_ids is Array:
		for raw_field_id in raw_field_ids:
			var field_id := str(raw_field_id).strip_edges()
			if not field_id.is_empty():
				field_ids.append(field_id)

	var concept := str(metadata.get("concept", "")).strip_edges()
	var user_prompt := "The previous character-card generation returned valid JSON, but it did not satisfy the generation completeness contract. Repair the existing result instead of starting over."
	if not concept.is_empty():
		user_prompt += "\n\nSOURCE CONCEPT — authoritative; do not replace its established facts:\n%s" % concept
	user_prompt += "\n\nCURRENT GENERATED JSON — preserve all useful content that already satisfies the request:\n%s" % JSON.stringify(current_data, "  ")
	user_prompt += "\n\nMISSING OR INCOMPLETE ITEMS:\n%s" % CCFGenerationContractService.repair_instructions(report)
	user_prompt += "\n\n%s" % CCFGenerationContractService.prompt_text(contract)
	if not field_ids.is_empty():
		user_prompt += "\n\nReturn the complete repaired JSON object using the original requested top-level keys: %s." % _join_string_array(field_ids, ", ")
	else:
		user_prompt += "\n\nReturn the complete repaired JSON object."
	user_prompt += " Do not return a diff, explanation, markdown fence, or only the missing fragments. Preserve good existing material while filling or correcting only what is necessary."

	payload["messages"] = [
		{
			"role": "system",
			"content": "You are Character Card Forge's generation-completeness repair pass. Preserve established character facts and good prose, fill missing required content, and return valid JSON only."
		},
		{"role": "user", "content": user_prompt}
	]
	_active_job["payload"] = payload
	_emit_queue_changed()
	call_deferred("_start_active_request")


func _join_string_array(values: Array[String], separator: String) -> String:
	var result := ""
	for index in range(values.size()):
		if index > 0:
			result += separator
		result += values[index]
	return result
