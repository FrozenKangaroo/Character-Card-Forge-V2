class_name CCFGenerationServiceV01311Hotfix
extends "res://scripts/services/generation_service_v01311.gd"

var _creative_runtime: Dictionary = {}


func queue_vision_analysis(
	project: Dictionary,
	template: Dictionary,
	attachment: Dictionary,
	profile: Dictionary,
	analysis_mode: String,
	retry_count: int
) -> Dictionary:
	if analysis_mode not in ["creative_concept", "full_card"]:
		return super.queue_vision_analysis(
			project, template, attachment, profile, analysis_mode, retry_count
		)
	if not CCFAttachmentService.is_vision_compatible(attachment):
		return {"ok": false, "error": "Select an image or GIF attachment for vision analysis."}

	var container_project_id := str(
		project.get("container_project_id", project.get("project_id", ""))
	)
	var image_result := CCFAttachmentService.image_data_url(
		container_project_id, attachment
	)
	if not bool(image_result.get("ok", false)):
		return image_result

	var vision_profile := profile.duplicate(true)
	var text_profile_value: Variant = vision_profile.get("_creative_text_profile", {})
	var text_profile: Dictionary = (
		text_profile_value.duplicate(true) if text_profile_value is Dictionary else {}
	)
	vision_profile.erase("_creative_text_profile")
	if text_profile.is_empty():
		text_profile = vision_profile.duplicate(true)

	var attachment_name := str(attachment.get("display_name", "Image attachment"))
	var preprocess_value: Variant = attachment.get("preprocess", {})
	var preprocess_summary := ""
	if preprocess_value is Dictionary:
		preprocess_summary = str(preprocess_value.get("summary", "")).strip_edges()
	var attachment_notes := str(attachment.get("notes", "")).strip_edges()
	var existing_concept := str(
		CCFStorageService.get_value_at_path(project, "concept.prompt", "")
	).strip_edges()
	var series_context := _series_context_text(project)
	var relationship_context := _relationship_context_text(project)

	var prompt := (
		"Inspect the attached image and return a compact factual VISUAL SEED for a later creative-character pass. "
		+ "This stage is observation only: do not invent personality, occupation, history, motives, relationships, secrets, or a finished character premise."
	)
	prompt += "\n\nATTACHMENT: %s" % attachment_name
	if not preprocess_summary.is_empty():
		prompt += "\nFILE SUMMARY: %s" % preprocess_summary
	if not attachment_notes.is_empty():
		prompt += "\nUSER NOTES — use these to resolve what the image is meant to represent:\n%s" % attachment_notes
	prompt += (
		"\n\nReturn one valid JSON object with exactly these keys:\n"
		+ "visual_identity: array of stable visible character traits;\n"
		+ "presentation: array of clothing/accessories/pose/expression details actually visible;\n"
		+ "environment: array of visible setting, lighting, weather, architecture, or location cues;\n"
		+ "objects: array of notable visible props or objects;\n"
		+ "atmosphere: array of purely visual mood/composition cues without claiming personality;\n"
		+ "ambiguities: array of details that are unclear or should not be assumed.\n"
		+ "Keep each item concise. Return JSON only."
	)

	var detail := str(vision_profile.get("vision_detail", "auto"))
	if detail not in ["auto", "low", "high"]:
		detail = "auto"
	var messages := [
		{
			"role": "system",
			"content": "You are the visual-observation stage of Character Card Forge. Extract reliable visual anchors for a separate creative writer. Be precise, observational, and conservative about anything not literally visible. Return valid JSON only."
		},
		{
			"role": "user",
			"content": [
				{"type": "text", "text": prompt},
				{
					"type": "image_url",
					"image_url": {
						"url": str(image_result.get("data_url", "")),
						"detail": detail
					}
				}
			]
		}
	]
	var concept_field := {
		"id": "concept_prompt",
		"label": "Generation Concept",
		"path": "concept.prompt",
		"type": "multiline",
		"generate": true
	}
	var result := _queue_chat_job(
		"vision_analysis",
		"Creative Concept — analysing image",
		vision_profile,
		messages,
		"object",
		{
			"field_ids": ["concept_prompt"],
			"preview_fields": [concept_field],
			"output_policy": {"mode": "strict", "unexpected_fields": "ignore"},
			"attachment_id": str(attachment.get("attachment_id", "")),
			"attachment_name": attachment_name,
			"analysis_mode": "creative_concept",
			"creative_stage": "vision_seed",
			"creative_pipeline": "vision_seed_then_text_concept",
			"project_id": str(project.get("project_id", ""))
		},
		retry_count
	)
	if bool(result.get("ok", false)):
		var job_id := str(result.get("job_id", ""))
		_creative_runtime[job_id] = {
			"text_profile": text_profile,
			"attachment_name": attachment_name,
			"attachment_notes": attachment_notes,
			"existing_concept": existing_concept,
			"series_context": series_context,
			"relationship_context": relationship_context
		}
	return result


func _process_completed_content(content: String) -> void:
	if _active_job.is_empty():
		return
	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
	if str(metadata.get("creative_stage", "")) == "vision_seed":
		var parse_result := _parse_job_output_with_diagnostics(content, "object")
		if not bool(parse_result.get("ok", false)):
			if _start_json_repair(content, "object"):
				return
			_handle_failure(
				"The visual-seed stage did not return usable JSON. %s"
				% str(parse_result.get("diagnostic", "")),
				false
			)
			return
		var seed_value: Variant = parse_result.get("data", {})
		if not seed_value is Dictionary:
			_handle_failure("The visual-seed stage did not return a JSON object.", false)
			return
		_begin_creative_expansion(seed_value)
		return

	var job_id := str(_active_job.get("id", ""))
	if str(metadata.get("creative_stage", "")) == "concept_expansion":
		_creative_runtime.erase(job_id)
	super._process_completed_content(content)


func _begin_creative_expansion(seed: Dictionary) -> void:
	var job_id := str(_active_job.get("id", ""))
	var runtime_value: Variant = _creative_runtime.get(job_id, {})
	if not runtime_value is Dictionary:
		_handle_failure("Creative Concept lost its second-stage runtime context.", false)
		return
	var runtime: Dictionary = runtime_value
	var text_profile_value: Variant = runtime.get("text_profile", {})
	var text_profile: Dictionary = (
		text_profile_value.duplicate(true) if text_profile_value is Dictionary else {}
	)
	var text_model := str(text_profile.get("model", "")).strip_edges()
	var base_url := str(text_profile.get("base_url", "")).strip_edges()
	if text_model.is_empty():
		_handle_failure(
			"Creative Concept completed visual analysis, but the Text role has no model configured.",
			false
		)
		return
	if base_url.is_empty():
		_handle_failure(
			"Creative Concept completed visual analysis, but the Text role has no API base URL configured.",
			false
		)
		return

	var prompt := (
		"Create an ORIGINAL, generation-ready roleplay character concept from the visual seed below. "
		+ "The visual seed is evidence, not a story. Invent the narrative identity now."
	)
	prompt += "\n\nVISUAL SEED:\n%s" % JSON.stringify(seed, "  ")
	var attachment_notes := str(runtime.get("attachment_notes", "")).strip_edges()
	if not attachment_notes.is_empty():
		prompt += "\n\nUSER IMAGE GUIDANCE — authoritative where it specifies intent:\n%s" % attachment_notes
	var existing_concept := str(runtime.get("existing_concept", "")).strip_edges()
	if not existing_concept.is_empty():
		prompt += "\n\nEXISTING CONCEPT — develop its established intent rather than replacing it:\n%s" % existing_concept
	var series_context := str(runtime.get("series_context", "")).strip_edges()
	if not series_context.is_empty():
		prompt += "\n\nSERIES CONTINUITY:\n%s" % series_context
	var relationship_context := str(runtime.get("relationship_context", "")).strip_edges()
	if not relationship_context.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS:\n%s" % relationship_context
	prompt += (
		"\n\nCREATIVE DEVELOPMENT REQUIREMENTS:\n"
		+ "- Start with a clear core premise, not an image caption.\n"
		+ "- Give the character a coherent identity/role and a strong reason they are interesting to interact with.\n"
		+ "- Develop personality direction with at least one useful contradiction or tension.\n"
		+ "- Give them motivations, an internal or external conflict, and at least one background hook.\n"
		+ "- Include one secret, unresolved complication, obligation, unusual skill, relationship pressure, or other story engine when appropriate.\n"
		+ "- Suggest how {{user}} can naturally enter the character's life and what kinds of roleplay the premise enables.\n"
		+ "- Treat the image's pose/expression as a moment, not proof of a permanent personality.\n"
		+ "- Preserve distinctive visual anchors, but do not spend most of the concept redescribing appearance or scenery.\n"
		+ "- Make invented details reinforce each other rather than adding random traits.\n"
		+ "- This is source material for Character Card Forge's normal Q&A, template, Mode & Style, validation, and generation pipeline; do not write final card fields.\n"
		+ "- Aim for a substantial concept, roughly 350–700 words when the available material supports it."
	)
	prompt += "\n\nReturn one valid JSON object exactly as {\"concept_prompt\": \"<generation-ready concept>\"}. Return JSON only."
	var messages := [
		{
			"role": "system",
			"content": "You are Character Card Forge's creative character-concept writer. Transform factual visual anchors into coherent original roleplay premises with motivations, tensions, hooks, and room for later Q&A-driven development. Do not merely describe the image. Return valid JSON only."
		},
		{"role": "user", "content": prompt}
	]
	var configuration := _request_configuration(text_profile, messages, false)
	if not bool(configuration.get("ok", false)):
		_handle_failure(str(configuration.get("error", "Could not prepare Creative Concept text stage.")), false)
		return

	var previous_model := str(_active_job.get("model", ""))
	var active_metadata: Dictionary = _active_job.get("metadata", {}).duplicate(true)
	active_metadata["creative_stage"] = "concept_expansion"
	active_metadata["vision_seed_model"] = previous_model
	active_metadata["creative_text_model"] = str(configuration.get("model", text_model))
	active_metadata["text_context_window_used"] = int(configuration.get("context_window", 0))
	active_metadata["text_estimated_input_tokens"] = int(configuration.get("estimated_input_tokens", 0))
	active_metadata["text_effective_max_output_tokens"] = int(configuration.get("max_output_tokens", 0))
	_active_job["metadata"] = active_metadata
	_active_job["url"] = _completion_url(base_url)
	_active_job["headers"] = _request_headers(text_profile)
	_active_job["payload"] = {
		"model": str(configuration.get("model", text_model)),
		"temperature": float(text_profile.get("temperature", 0.8)),
		"max_tokens": int(configuration.get("max_output_tokens", 6000)),
		"messages": messages
	}
	_active_job["model"] = str(configuration.get("model", text_model))
	_active_job["profile_name"] = str(text_profile.get("name", "Text role"))
	_active_job["parse_mode"] = "object"
	_active_job["attempt"] = 0
	_active_job["repair_attempts"] = 0
	_active_job["label"] = "Creative Concept — developing character"
	_emit_queue_changed()
	_start_active_request()


func _queue_chat_job(
	job_type: String,
	label: String,
	profile: Dictionary,
	messages: Array,
	parse_mode: String,
	metadata: Dictionary,
	retry_count: int
) -> Dictionary:
	var vision_job := job_type == "vision_analysis"
	var configuration := _request_configuration(profile, messages, vision_job)
	if not bool(configuration.get("ok", false)):
		return {"ok": false, "error": str(configuration.get("error", "Could not prepare request."))}

	var effective := profile.duplicate(true)
	var model := str(configuration.get("model", ""))
	var max_output := int(configuration.get("max_output_tokens", 6000))
	if vision_job:
		effective["model"] = model
		effective["vision_model"] = model
		effective["vision_temperature"] = float(profile.get("vision_temperature", profile.get("temperature", 0.8)))
		effective["vision_output_auto"] = false
		effective["vision_max_output_tokens"] = max_output
	else:
		effective["model"] = model
		effective["text_output_auto"] = false
		effective["max_output_tokens"] = max_output

	var enriched_metadata := metadata.duplicate(true)
	enriched_metadata["request_role"] = "vision" if vision_job else "text"
	enriched_metadata["context_window_used"] = int(configuration.get("context_window", 0))
	enriched_metadata["estimated_input_tokens"] = int(configuration.get("estimated_input_tokens", 0))
	enriched_metadata["effective_max_output_tokens"] = max_output
	return super._queue_chat_job(
		job_type,
		label,
		effective,
		messages,
		parse_mode,
		enriched_metadata,
		retry_count
	)


func _request_configuration(
	profile: Dictionary, messages: Array, vision: bool
) -> Dictionary:
	var model := (
		str(profile.get("vision_model", profile.get("model", ""))).strip_edges()
		if vision
		else str(profile.get("model", "")).strip_edges()
	)
	if model.is_empty():
		return {
			"ok": false,
			"error": "%s model is not configured." % ("Vision" if vision else "Text")
		}
	var context_window := _resolved_context_window(profile, model, vision)
	var requested_output := _resolved_output_limit(profile, model, vision)
	var estimated_input := _estimate_message_tokens(messages)
	var reserve := 1024 if vision else 512
	var effective_output := requested_output
	if context_window > 0:
		var available := context_window - estimated_input - reserve
		if available < 128:
			return {
				"ok": false,
				"error": (
					"The configured %s context window (%d tokens) is too small for this request (approximately %d input tokens before output). Increase the %s context window or enable Auto when the provider publishes the correct limit."
					% [
						"Vision" if vision else "Text",
						context_window,
						estimated_input,
						"Vision" if vision else "Text"
					]
				)
			}
		effective_output = mini(requested_output, available)
	return {
		"ok": true,
		"model": model,
		"context_window": context_window,
		"estimated_input_tokens": estimated_input,
		"max_output_tokens": maxi(128, effective_output)
	}


func _resolved_context_window(profile: Dictionary, model_id: String, vision: bool) -> int:
	var manual_key := "vision_context_window" if vision else "text_context_window"
	var auto_key := "vision_context_auto" if vision else "text_context_auto"
	var manual := maxi(0, int(profile.get(manual_key, 0)))
	if not bool(profile.get(auto_key, true)):
		return manual
	var capability := _capability_for_model(profile, model_id)
	var detected := int(capability.get("context_window", 0))
	return detected if detected > 0 else manual


func _estimate_message_tokens(messages: Array) -> int:
	var characters := _textual_character_count(messages)
	return maxi(1, int(ceil(float(characters) / 4.0)))


func _textual_character_count(value: Variant) -> int:
	if value is String:
		if value.begins_with("data:image/"):
			return 0
		return value.length()
	if value is Array:
		var total := 0
		for item in value:
			total += _textual_character_count(item)
		return total
	if value is Dictionary:
		var total := 0
		for key in value.keys():
			var child: Variant = value.get(key)
			if str(key) == "url" and child is String and child.begins_with("data:image/"):
				continue
			total += str(key).length()
			total += _textual_character_count(child)
		return total
	return str(value).length()


func _handle_failure(message: String, retryable: bool) -> void:
	var job_id := str(_active_job.get("id", "")) if not _active_job.is_empty() else ""
	var attempt := int(_active_job.get("attempt", 1)) if not _active_job.is_empty() else 1
	var max_retries := int(_active_job.get("max_retries", 0)) if not _active_job.is_empty() else 0
	var will_retry := retryable and attempt <= max_retries
	if not will_retry and not job_id.is_empty():
		_creative_runtime.erase(job_id)
	super._handle_failure(message, retryable)
