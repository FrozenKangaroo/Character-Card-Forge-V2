class_name CCFTemplateContractGuardGenerationService
extends CCFModeStyleGenerationService

const TEMPLATE_STRUCTURE_RULE := "The active template generation contract is authoritative for JSON keys, enabled/disabled generation components, exact required component labels, marker rules, and output bindings. Mode & Style changes wording, density, tone, and First Message presentation only. It must never replace required labelled component structure with free-form prose."
const STRUCTURE_REPAIR_MARKER := "TEMPLATE STRUCTURE REPAIR RULE — mandatory:"


# v0.13.3 introduced a helper-name collision: CCFModeStyleGenerationService defined
# _decorate_character_job(), which unintentionally overrode the parity service helper
# that attaches the semantic generation contract. Route both dictionary shapes here so
# the parent chain can keep its existing API while contract metadata is never lost.
func _decorate_character_job(job_id: String, value: Dictionary) -> void:
	if value.has("required_fields") and value.has("field_rules"):
		_decorate_generation_contract(job_id, value)
		return
	super._decorate_character_job(job_id, value)


func _decorate_generation_contract(job_id: String, contract: Dictionary) -> void:
	var contract_text := CCFGenerationContractService.prompt_text(contract)
	for index in range(_queue.size()):
		var job: Dictionary = _queue[index]
		if str(job.get("id", "")) != job_id:
			continue
		job["semantic_repair_attempts"] = 0
		var metadata_value: Variant = job.get("metadata", {})
		var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
		metadata["generation_contract"] = contract.duplicate(true)
		metadata["generation_contract_attached"] = true
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
		active_metadata["generation_contract_attached"] = true
		_active_job["metadata"] = active_metadata
		_active_job["payload"] = _payload_with_contract(
			_active_job.get("payload", {}), contract_text
		)


func _process_completed_content(content: String) -> void:
	if _active_job.is_empty() or str(_active_job.get("type", "")) != "character":
		super._process_completed_content(content)
		return

	# Interview planning/retry responses are not character-card output and are handled by
	# CCFInterviewGenerationService further up the inheritance chain.
	var interview_stage := str(_active_job.get("interview_stage", ""))
	if interview_stage == "planning" or interview_stage == "retry":
		super._process_completed_content(content)
		return

	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = (
		metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	)
	var contract_value: Variant = metadata.get("generation_contract", {})
	if not contract_value is Dictionary or contract_value.is_empty():
		metadata["template_contract_blocked_preview"] = true
		metadata["template_contract_missing"] = true
		_active_job["metadata"] = metadata
		_handle_failure(
			"Character generation could not continue because the active template contract was not attached to the generation job. Nothing was offered for application. This is an internal generation-pipeline error, not a problem with the character template.",
			false
		)
		return

	var parse_mode := str(_active_job.get("parse_mode", "object"))
	var parse_result: Dictionary = _parse_job_output_with_diagnostics(content, parse_mode)
	if bool(parse_result.get("ok", false)):
		var parsed_value: Variant = parse_result.get("data")
		if parsed_value is Dictionary:
			var report := CCFGenerationContractService.validate_generated_data(
				parsed_value, contract_value
			)
			var semantic_attempts := int(_active_job.get("semantic_repair_attempts", 0))
			if not bool(report.get("ok", false)) and semantic_attempts >= 1:
				metadata["generation_contract_report"] = report.duplicate(true)
				metadata["semantic_repair_attempts"] = semantic_attempts
				metadata["semantic_repair_used"] = true
				metadata["template_contract_blocked_preview"] = true
				_active_job["metadata"] = metadata
				var details := CCFGenerationContractService.repair_instructions(report)
				_handle_failure(
					"Character generation still did not satisfy the active template after the bounded repair pass. Nothing was offered for application, so the template structure was preserved.\n\n%s"
					% details,
					false
				)
				return

	super._process_completed_content(content)


func _start_semantic_repair(
	current_data: Dictionary, report: Dictionary, contract: Dictionary
) -> void:
	super._start_semantic_repair(current_data, report, contract)
	if _active_job.is_empty():
		return
	var payload_value: Variant = _active_job.get("payload", {})
	var payload: Dictionary = payload_value.duplicate(true) if payload_value is Dictionary else {}
	var messages_value: Variant = payload.get("messages", [])
	if not messages_value is Array or messages_value.is_empty():
		return
	var messages: Array = messages_value.duplicate(true)
	var last_index := messages.size() - 1
	var last_value: Variant = messages[last_index]
	if not last_value is Dictionary:
		return
	var last_message: Dictionary = last_value.duplicate(true)
	if str(last_message.get("role", "")) != "user":
		return
	var current_content := str(last_message.get("content", ""))
	if current_content.contains(STRUCTURE_REPAIR_MARKER):
		return
	last_message["content"] = (
		current_content
		+ "\n\n"
		+ STRUCTURE_REPAIR_MARKER
		+ "\n"
		+ TEMPLATE_STRUCTURE_RULE
		+ "\nFor every missing_component issue, emit the configured label exactly at the start of its own line as `Label: content`. Preserve good prose inside those labelled components; do not flatten structured Description or Personality fields into an unlabelled narrative paragraph."
	)
	messages[last_index] = last_message
	payload["messages"] = messages
	_active_job["payload"] = payload


func _mode_style_block(mode_style: Dictionary, include_marker: bool = true) -> String:
	var block := super._mode_style_block(mode_style, include_marker)
	return block + "\nTemplate Structure: " + TEMPLATE_STRUCTURE_RULE
