class_name CCFGenerationServiceV0167
extends "res://scripts/services/generation_service_v01533_hotfix3.gd"

const DETAIL_LEVEL_SERVICE_V0167 = preload(
	"res://scripts/services/idea_generator_detail_level_service_v0167.gd"
)
const IDEA_DETAIL_CONTRACT_VERSION_V0167 := 1

var _detail_levels_v0167 := DETAIL_LEVEL_SERVICE_V0167.new()


func queue_idea_generation_with_detail_v0167(
	seed_text: String,
	profile: Dictionary,
	idea_count: int,
	retry_count: int,
	project_id: String = "",
	series_context: String = "",
	detail_level_id: String = "standard"
) -> Dictionary:
	var normalised_level := _detail_levels_v0167.normalise_level_id(detail_level_id)
	var result := super.queue_idea_generation(
		seed_text,
		profile,
		idea_count,
		retry_count,
		project_id,
		series_context
	)
	if bool(result.get("ok", false)):
		_decorate_queued_idea_detail_v0167(
			str(result.get("job_id", "")), normalised_level
		)
	return result


func idea_detail_level_capabilities_v0167() -> Dictionary:
	return {
		"format_version": IDEA_DETAIL_CONTRACT_VERSION_V0167,
		"catalog_format_version": _detail_levels_v0167.catalog_format_version(),
		"default_level": _detail_levels_v0167.default_level_id(),
		"levels": _detail_levels_v0167.ordered_levels(),
		"prompt_contract": true,
		"output_budget_scaling": true,
		"user_agency_contract_preserved": true
	}


func _decorate_queued_idea_detail_v0167(job_id: String, detail_level_id: String) -> void:
	if job_id.is_empty():
		return
	var normalised_level := _detail_levels_v0167.normalise_level_id(detail_level_id)
	for index in range(_queue.size()):
		var job_value: Variant = _queue[index]
		if not job_value is Dictionary:
			continue
		var job: Dictionary = (job_value as Dictionary).duplicate(true)
		if str(job.get("id", "")) != job_id or str(job.get("type", "")) != "ideas":
			continue
		_queue[index] = _decorate_idea_job_detail_v0167(job, normalised_level)
		return

	# A newly queued job may begin immediately when this worker is idle. In
	# that case it has already moved from _queue to _active_job by the time the
	# inherited queue call returns, so decorate the active record as well.
	if (
		not _active_job.is_empty()
		and str(_active_job.get("id", "")) == job_id
		and str(_active_job.get("type", "")) == "ideas"
	):
		_active_job = _decorate_idea_job_detail_v0167(
			_active_job.duplicate(true), normalised_level
		)


func _decorate_idea_job_detail_v0167(
	job: Dictionary, detail_level_id: String
) -> Dictionary:
	var normalised_level := _detail_levels_v0167.normalise_level_id(detail_level_id)
	var instruction := _detail_levels_v0167.prompt_instruction_for(normalised_level)
	var label := _detail_levels_v0167.label_for(normalised_level)
	var budget_hint := _detail_levels_v0167.output_budget_hint_for(normalised_level)
	var payload_value: Variant = job.get("payload", {})
	if not payload_value is Dictionary:
		return job
	var payload: Dictionary = (payload_value as Dictionary).duplicate(true)
	var messages_value: Variant = payload.get("messages", [])
	var messages: Array = messages_value.duplicate(true) if messages_value is Array else []
	var detail_block := (
		"IDEA DETAIL LEVEL — %s:\n%s\n"
		+ "Apply this only to the depth and richness of each generated idea. "
		+ "Do not weaken the existing {{user}} agency contract, invent unnecessary {{user}} backstory, or choose {{user}}'s actions/reactions."
	) % [label, instruction]
	for message_index in range(messages.size()):
		if not messages[message_index] is Dictionary:
			continue
		var message: Dictionary = (messages[message_index] as Dictionary).duplicate(true)
		if str(message.get("role", "")) == "system":
			message["content"] = str(message.get("content", "")) + "\n\n" + detail_block
			messages[message_index] = message
			break
	payload["messages"] = messages
	var base_max_tokens := maxi(1, int(payload.get("max_tokens", 6000)))
	payload["max_tokens"] = maxi(
		256, int(round(float(base_max_tokens) * budget_hint))
	)
	job["payload"] = payload
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = (
		(metadata_value as Dictionary).duplicate(true)
		if metadata_value is Dictionary
		else {}
	)
	metadata["idea_detail_contract_version"] = IDEA_DETAIL_CONTRACT_VERSION_V0167
	metadata["idea_detail_level"] = normalised_level
	metadata["idea_detail_label"] = label
	metadata["idea_output_budget_hint"] = budget_hint
	metadata["idea_output_max_tokens"] = int(payload.get("max_tokens", 0))
	job["metadata"] = metadata
	return job
