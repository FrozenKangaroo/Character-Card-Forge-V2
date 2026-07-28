class_name CCFModeStyleGenerationService
extends CCFBuilderPrecedenceGenerationService

const MODE_STYLE_MARKER := "MODE & STYLE — author-selected generation guidance:"
const MODE_STYLE_REPAIR_MARKER := "MODE & STYLE TO PRESERVE DURING REPAIR:"

var _pending_mode_style: Dictionary = {}


func queue_character_generation(
	project: Dictionary,
	template: Dictionary,
	profile: Dictionary,
	include_existing_fields: bool,
	retry_count: int
) -> Dictionary:
	_pending_mode_style = normalise_mode_style(project)
	var result: Dictionary = super.queue_character_generation(
		project, template, profile, include_existing_fields, retry_count
	)
	var mode_style := _pending_mode_style.duplicate(true)
	_pending_mode_style = {}
	if not bool(result.get("ok", false)):
		return result
	var job_id := str(result.get("job_id", ""))
	if not job_id.is_empty():
		_decorate_character_job(job_id, mode_style)
	return result


func _prepare_character_stage(job_value: Dictionary) -> Dictionary:
	var job := super._prepare_character_stage(job_value)
	var mode_style_value: Variant = job.get("mode_style", {})
	var mode_style: Dictionary = (
		mode_style_value if mode_style_value is Dictionary else _current_mode_style()
	)
	job["payload"] = _payload_with_mode_style(job.get("payload", {}), mode_style)
	return job


func _start_semantic_repair(
	current_data: Dictionary, report: Dictionary, contract: Dictionary
) -> void:
	super._start_semantic_repair(current_data, report, contract)
	if _active_job.is_empty():
		return
	var mode_style_value: Variant = _active_job.get("mode_style", {})
	var mode_style: Dictionary = mode_style_value if mode_style_value is Dictionary else {}
	_active_job["payload"] = _payload_with_mode_style_repair(
		_active_job.get("payload", {}), mode_style
	)


static func normalise_mode_style(project: Dictionary) -> Dictionary:
	var result := {
		"generation_mode": "full",
		"writing_style": "balanced",
		"first_message_style": "cinematic",
		"first_message_length": "detailed",
		"custom_writing_style": "",
		"first_message_custom_instructions": "",
		"custom_first_message_length": ""
	}
	var generation_value: Variant = project.get("generation", {})
	if generation_value is Dictionary:
		var stored_value: Variant = generation_value.get("mode_style", {})
		if stored_value is Dictionary:
			result.merge(stored_value, true)
	result["generation_mode"] = _allowed(
		str(result.get("generation_mode", "full")), ["full", "lite", "compact_lite"], "full"
	)
	result["writing_style"] = _allowed(
		str(result.get("writing_style", "balanced")),
		["balanced", "immersive", "dialogue_forward", "descriptive", "concise", "custom"],
		"balanced"
	)
	result["first_message_style"] = _allowed(
		str(result.get("first_message_style", "cinematic")),
		["cinematic", "conversational", "immediate_dialogue", "atmospheric", "action_opening", "custom"],
		"cinematic"
	)
	result["first_message_length"] = _allowed(
		str(result.get("first_message_length", "detailed")),
		["brief", "standard", "detailed", "extended", "custom"],
		"detailed"
	)
	for key in ["custom_writing_style", "first_message_custom_instructions", "custom_first_message_length"]:
		result[key] = str(result.get(key, "")).strip_edges()
	return result


func _decorate_character_job(job_id: String, mode_style: Dictionary) -> void:
	for index in range(_queue.size()):
		var job: Dictionary = _queue[index]
		if str(job.get("id", "")) != job_id:
			continue
		_queue[index] = _job_with_mode_style(job, mode_style)
		return
	if str(_active_job.get("id", "")) == job_id:
		_active_job = _job_with_mode_style(_active_job, mode_style)


func _job_with_mode_style(job_value: Dictionary, mode_style: Dictionary) -> Dictionary:
	var job := job_value.duplicate(true)
	job["mode_style"] = mode_style.duplicate(true)
	job["payload"] = _payload_with_mode_style(job.get("payload", {}), mode_style)
	var character_payload_value: Variant = job.get("interview_character_payload", null)
	if character_payload_value is Dictionary:
		job["interview_character_payload"] = _payload_with_mode_style(
			character_payload_value, mode_style
		)
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	metadata["mode_style"] = {
		"generation_mode": str(mode_style.get("generation_mode", "full")),
		"writing_style": str(mode_style.get("writing_style", "balanced")),
		"first_message_style": str(mode_style.get("first_message_style", "cinematic")),
		"first_message_length": str(mode_style.get("first_message_length", "detailed")),
		"custom_instructions": not str(mode_style.get("first_message_custom_instructions", "")).is_empty()
	}
	job["metadata"] = metadata
	return job


func _payload_with_mode_style(payload_value: Variant, mode_style: Dictionary) -> Dictionary:
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
	if current_content.contains(MODE_STYLE_MARKER):
		return payload
	last_message["content"] = current_content + "\n\n" + _mode_style_block(mode_style)
	messages[last_index] = last_message
	payload["messages"] = messages
	return payload


func _payload_with_mode_style_repair(payload_value: Variant, mode_style: Dictionary) -> Dictionary:
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
	if current_content.contains(MODE_STYLE_REPAIR_MARKER):
		return payload
	last_message["content"] = (
		current_content
		+ "\n\n"
		+ MODE_STYLE_REPAIR_MARKER
		+ "\n"
		+ _mode_style_block(mode_style, false)
		+ "\nRepair only what is required for semantic completeness. Do not shorten or restyle an already valid First Message away from these author-selected settings."
	)
	messages[last_index] = last_message
	payload["messages"] = messages
	return payload


func _mode_style_block(mode_style: Dictionary, include_marker: bool = true) -> String:
	var lines: Array[String] = []
	if include_marker:
		lines.append(MODE_STYLE_MARKER)
	lines.append("Generation Mode: %s" % _generation_mode_guidance(str(mode_style.get("generation_mode", "full"))))
	lines.append("Writing Style: %s" % _writing_style_guidance(mode_style))
	lines.append("First Message Style: %s" % _first_message_style_guidance(str(mode_style.get("first_message_style", "cinematic"))))
	lines.append("First Message Length: %s" % _first_message_length_guidance(mode_style))
	var custom_instructions := str(mode_style.get("first_message_custom_instructions", "")).strip_edges()
	if not custom_instructions.is_empty():
		lines.append("First Message Custom Instructions: %s" % custom_instructions)
	lines.append("The First Message settings apply only to the playable opening. Do not make every greeting brief unless Brief is selected. Preserve the Scenario and do not narrate {{user}}'s private choices, thoughts, or feelings as decided facts.")
	return "\n".join(lines)


func _generation_mode_guidance(mode: String) -> String:
	match mode:
		"lite":
			return "Lite — keep secondary prose reasonably compact while still satisfying every enabled required field. Do not shorten the First Message below its separate length target."
		"compact_lite":
			return "Compact Lite — minimise nonessential wording and repetition for smaller-context use while preserving all required content. The First Message still follows its separate length target."
		_:
			return "Full Prompt — favour coherence, richness, and complete roleplay-useful detail rather than aggressive compression."


func _writing_style_guidance(mode_style: Dictionary) -> String:
	var style := str(mode_style.get("writing_style", "balanced"))
	match style:
		"immersive":
			return "Immersive — vivid but purposeful sensory detail, clear emotional texture, and natural scene-aware prose."
		"dialogue_forward":
			return "Dialogue-forward — prioritise distinctive voice, conversational rhythm, and playable interaction while retaining enough action/context to orient the scene."
		"descriptive":
			return "Descriptive — richer concrete detail and atmosphere without burying actionable roleplay information."
		"concise":
			return "Concise — efficient prose with little repetition. This does not override the separately selected First Message length."
		"custom":
			var custom := str(mode_style.get("custom_writing_style", "")).strip_edges()
			return custom if not custom.is_empty() else "Custom selected, but no custom writing-style instruction was supplied; use balanced roleplay prose."
		_:
			return "Balanced — natural roleplay prose with enough detail for personality, scenario, and voice without unnecessary repetition."


func _first_message_style_guidance(style: String) -> String:
	match style:
		"conversational":
			return "Conversational — get {{char}} naturally talking to {{user}} early, with light scene/action context around the dialogue."
		"immediate_dialogue":
			return "Immediate Dialogue — begin with {{char}} speaking or reacting directly, then weave in only the context needed to make the exchange playable."
		"atmospheric":
			return "Atmospheric — establish place, mood, sensory cues, and emotional pressure before or around {{char}}'s first direct interaction with {{user}}."
		"action_opening":
			return "Action Opening — begin with a concrete action/event already happening, then transition naturally into {{char}} interacting with {{user}}."
		"custom":
			return "Custom — follow the greeting-specific custom instructions closely; do not fall back to a generic short greeting."
		_:
			return "Cinematic — establish the visible scene and immediate mood through purposeful action/sensory framing, then move into distinctive natural dialogue with {{user}}."


func _first_message_length_guidance(mode_style: Dictionary) -> String:
	var length_mode := str(mode_style.get("first_message_length", "detailed"))
	match length_mode:
		"brief":
			return "Brief — target roughly 60-160 words. This is the deliberately short-opening option."
		"standard":
			return "Standard — target roughly 180-350 words, with enough action/setting/dialogue to establish a playable opening."
		"extended":
			return "Extended — target roughly 650-1000 words when the scenario supports it, using multiple purposeful beats rather than padding."
		"custom":
			var custom := str(mode_style.get("custom_first_message_length", "")).strip_edges()
			return custom if not custom.is_empty() else "Custom selected without a numeric target; use a substantial opening appropriate to the selected style and scenario rather than defaulting to brief."
		_:
			return "Detailed — target roughly 350-650 words. Establish the scene, {{char}}'s presence and actions, emotional tone, and meaningful dialogue so the roleplay has room to begin."


func _current_mode_style() -> Dictionary:
	if not _pending_mode_style.is_empty():
		return _pending_mode_style.duplicate(true)
	if not _active_job.is_empty():
		var value: Variant = _active_job.get("mode_style", {})
		if value is Dictionary:
			return value.duplicate(true)
	return normalise_mode_style({})


static func _allowed(value: String, allowed: Array, fallback: String) -> String:
	var clean := value.strip_edges().to_lower()
	return clean if allowed.has(clean) else fallback
