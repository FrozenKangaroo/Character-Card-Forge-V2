extends "res://scripts/services/generation_service_v01310_hotfix.gd"


func queue_vision_analysis(
	project: Dictionary,
	template: Dictionary,
	attachment: Dictionary,
	profile: Dictionary,
	analysis_mode: String,
	retry_count: int
) -> Dictionary:
	if analysis_mode != "full_card":
		return super.queue_vision_analysis(project, template, attachment, profile, analysis_mode, retry_count)
	if not CCFAttachmentService.is_vision_compatible(attachment):
		return {"ok": false, "error": "Select an image or GIF attachment for vision analysis."}
	var container_project_id := str(project.get("container_project_id", project.get("project_id", "")))
	var image_result := CCFAttachmentService.image_data_url(container_project_id, attachment)
	if not bool(image_result.get("ok", false)):
		return image_result

	var attachment_name := str(attachment.get("display_name", "Image attachment"))
	var preprocess: Variant = attachment.get("preprocess", {})
	var preprocess_summary := ""
	if preprocess is Dictionary:
		preprocess_summary = str(preprocess.get("summary", "")).strip_edges()
	var attachment_notes := str(attachment.get("notes", "")).strip_edges()
	var existing_concept := str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()

	var prompt := (
		"Use the attached image as the visual seed for an ORIGINAL, generation-ready roleplay character concept. "
		+ "This is Creative Concept mode, not physical-description mode. Preserve clear visible identity anchors, but invent a compelling character beyond what can literally be seen."
	)
	prompt += "\n\nATTACHMENT: %s" % attachment_name
	if not preprocess_summary.is_empty():
		prompt += "\nFILE SUMMARY: %s" % preprocess_summary
	if not attachment_notes.is_empty():
		prompt += "\nUSER NOTES — treat these as authoritative guidance:\n%s" % attachment_notes
	if not existing_concept.is_empty():
		prompt += "\n\nEXISTING CONCEPT — improve/expand this rather than discarding its established intent:\n%s" % existing_concept
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE — keep the concept compatible with this continuity:\n%s" % series_context_text
	var relationship_context_text := _relationship_context_text(project)
	if not relationship_context_text.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS — use these as continuity anchors:\n%s" % relationship_context_text

	prompt += (
		"\n\nCREATIVE CONCEPT RULES:\n"
		+ "- Visible facts are anchors, not the scope of the concept.\n"
		+ "- Do NOT just caption the image or restate appearance, pose, clothing and scenery.\n"
		+ "- When the image provides little narrative information, be MORE creative: invent a coherent identity, role, personality direction, motivations, conflicts, background hooks, secrets, setting possibilities and roleplay potential.\n"
		+ "- Interesting does not mean random. Make invented details reinforce one another into a usable character premise.\n"
		+ "- Preserve distinctive visible features that matter to identity, but do not assume a pose or expression proves a permanent personality trait.\n"
		+ "- The result will be fed into Character Card Forge's normal Q&A/template generation pipeline, so write source material for generation rather than a finished card.\n"
		+ "- Include enough narrative substance that the normal generator has meaningful choices to develop.\n"
		+ "- Do not fill Personality, Scenario, First Message or other final card fields here."
	)
	prompt += "\n\nReturn one valid JSON object in exactly this shape: {\"concept_prompt\": \"<creative generation-ready concept>\"}. Return JSON only."

	var detail := str(profile.get("vision_detail", "auto"))
	if detail not in ["auto", "low", "high"]:
		detail = "auto"
	var messages := [
		{
			"role": "system",
			"content": "You are Character Card Forge's creative character-concept designer. Use visual evidence as inspiration, then develop a coherent original character premise with strong roleplay potential. The requested output is a concept for later generation, not a finished card and not merely an image description."
		},
		{
			"role": "user",
			"content": [
				{"type": "text", "text": prompt},
				{
					"type": "image_url",
					"image_url": {"url": str(image_result.get("data_url", "")), "detail": detail}
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
	return _queue_chat_job(
		"vision_analysis",
		"Creative concept: %s" % attachment_name,
		profile,
		messages,
		"object",
		{
			"field_ids": ["concept_prompt"],
			"preview_fields": [concept_field],
			"output_policy": {"mode": "strict", "unexpected_fields": "ignore"},
			"attachment_id": str(attachment.get("attachment_id", "")),
			"attachment_name": attachment_name,
			"analysis_mode": "creative_concept",
			"project_id": str(project.get("project_id", ""))
		},
		retry_count
	)


func _queue_chat_job(
	job_type: String,
	label: String,
	profile: Dictionary,
	messages: Array,
	parse_mode: String,
	metadata: Dictionary,
	retry_count: int
) -> Dictionary:
	var effective := profile.duplicate(true)
	var vision_job := job_type == "vision_analysis"
	var selected_model := str(profile.get("vision_model", profile.get("model", ""))).strip_edges() if vision_job else str(profile.get("model", "")).strip_edges()
	if vision_job:
		effective["model"] = selected_model
		effective["temperature"] = float(profile.get("vision_temperature", profile.get("temperature", 0.8)))
		effective["max_output_tokens"] = _resolved_output_limit(profile, selected_model, true)
	else:
		effective["temperature"] = float(profile.get("temperature", 0.8))
		effective["max_output_tokens"] = _resolved_output_limit(profile, selected_model, false)
	return super._queue_chat_job(job_type, label, effective, messages, parse_mode, metadata, retry_count)


func _resolved_output_limit(profile: Dictionary, model_id: String, vision: bool) -> int:
	var manual := int(profile.get("vision_max_output_tokens", profile.get("max_output_tokens", 6000))) if vision else int(profile.get("max_output_tokens", 6000))
	manual = maxi(128, manual)
	var auto_key := "vision_output_auto" if vision else "text_output_auto"
	if not bool(profile.get(auto_key, true)):
		return manual
	var capability := _capability_for_model(profile, model_id)
	var detected := int(capability.get("max_output_tokens", 0))
	return detected if detected > 0 else manual


func _capability_for_model(profile: Dictionary, model_id: String) -> Dictionary:
	var capabilities: Variant = profile.get("model_capabilities", {})
	if capabilities is Dictionary:
		var value: Variant = capabilities.get(model_id, {})
		if value is Dictionary:
			return value
	return {}
