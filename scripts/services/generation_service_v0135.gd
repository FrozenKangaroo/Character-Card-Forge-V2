class_name CCFGenerationServiceV0135
extends CCFConceptFidelityGenerationService


func queue_vision_analysis(
	project: Dictionary,
	template: Dictionary,
	attachment: Dictionary,
	profile: Dictionary,
	analysis_mode: String,
	retry_count: int
) -> Dictionary:
	if analysis_mode == "full_card":
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

	var preview_fields: Array = []
	var field_lines: Array[String] = []
	var field_ids: Array[String] = []
	var concept_field := {
		"id": "concept_prompt",
		"label": "Generation Concept",
		"path": "concept.prompt",
		"type": "multiline",
		"generate": true
	}
	preview_fields.append(concept_field)
	field_ids.append("concept_prompt")
	field_lines.append(
		"- concept_prompt: a concise visual-reference concept grounded only in visible evidence; scene details may be included here but must not be presented as personality, history, relationships, or other hidden facts"
	)

	for raw_field in CCFTemplateService.generation_fields(template):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_type := str(field.get("type", "multiline"))
		if not field_type in ["line", "multiline", "tags", "number", "checkbox", "select"]:
			continue
		var field_id := str(field.get("id", "")).strip_edges()
		if field_id.is_empty() or field_ids.has(field_id):
			continue
		if not field_id in ["name", "description", "tags"]:
			continue
		preview_fields.append(field.duplicate(true))
		field_ids.append(field_id)
		if field_id == "description":
			field_lines.append(
				"- description: visible physical traits of the character only. Include observable age range, body/build, face, skin, hair, eyes when visible, clothing/outfit, accessories, and distinguishing physical features when supported. Exclude pose/action, furniture, room/background, location, scenery, lighting, camera composition, personality, mood, history, occupation, relationships, motives, and invented facts."
			)
		elif field_id == "name":
			field_lines.append(
				"- name: preserve a supplied/current character name when one exists; otherwise do not invent a name merely from appearance"
			)
		else:
			field_lines.append(
				"- %s: %s (%s); keep tags visually observable and character-focused rather than personality/history guesses" % [
					field_id,
					str(field.get("label", field_id)),
					_field_type_instruction(field)
				]
			)

	var attachment_name := str(attachment.get("display_name", "Image attachment"))
	var preprocess = attachment.get("preprocess", {})
	var preprocess_summary := ""
	if preprocess is Dictionary:
		preprocess_summary = str(preprocess.get("summary", "")).strip_edges()
	var attachment_notes := str(attachment.get("notes", "")).strip_edges()
	var prompt := (
		"Analyse the attached visual reference for Character Card Forge in DEFAULT VISUAL REFERENCE mode. Distinguish direct visual evidence from inference. Do not identify a real person and do not invent hidden character facts."
	)
	prompt += "\n\nATTACHMENT: %s" % attachment_name
	if not preprocess_summary.is_empty():
		prompt += "\nFILE SUMMARY: %s" % preprocess_summary
	if not attachment_notes.is_empty():
		prompt += "\nUSER NOTES: %s" % attachment_notes
	var existing_concept := str(
		CCFStorageService.get_value_at_path(project, "concept.prompt", "")
	).strip_edges()
	if not existing_concept.is_empty():
		prompt += "\n\nCURRENT CHARACTER CONCEPT — use only to preserve known identity/continuity; do not use it to turn non-visible lore into visual observations:\n%s" % existing_concept
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE — continuity context only; do not copy non-visible lore into Description:\n%s" % series_context_text
	var relationship_context_text := _relationship_context_text(project)
	if not relationship_context_text.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS — identity context only; never infer relationship behavior or personality from the image:\n%s" % relationship_context_text
	var attachment_context_text := _workspace_attachment_context_text(project)
	if not attachment_context_text.is_empty():
		prompt += "\n\nOTHER ENABLED ATTACHMENT CONTEXT — supporting context only; visible evidence from the selected image remains authoritative for Description:\n%s" % attachment_context_text

	prompt += (
		"\n\nDEFAULT MODE RULES:\n"
		+ "- Description is PHYSICAL/VISUAL CHARACTER DESCRIPTION ONLY.\n"
		+ "- Clothing and visible accessories belong in Description because they are part of the visible character presentation.\n"
		+ "- Do not put pose/action, bed/chair/furniture, windows/curtains, room/location, scenery, lighting, camera framing, or other environment details into Description.\n"
		+ "- Do not infer or return Personality in default mode.\n"
		+ "- Do not infer temperament, morality, relationship style, occupation, backstory, motives, preferences, or emotions from appearance.\n"
		+ "- Scene/environment observations may appear in concept_prompt when useful as visual-generation context, but keep them out of Description."
	)
	prompt += "\n\nRETURNED JSON KEYS:\n%s" % _join_values(field_lines, "\n")
	prompt += "\n\nReturn one valid JSON object using only those keys. Omit unsupported values rather than inventing them. Do not add markdown fences or commentary. Tags must be arrays of short strings, checkbox values must be booleans, and number fields must be JSON numbers."

	var detail := str(profile.get("vision_detail", "auto"))
	if not detail in ["auto", "low", "high"]:
		detail = "auto"
	var messages := [
		{
			"role": "system",
			"content": "You are Character Card Forge's multimodal visual-reference analyst. In default mode, describe observable character appearance conservatively, keep environment separate from the character Description, never infer personality from appearance, and return valid JSON only."
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
	return _queue_chat_job(
		"vision_analysis",
		"Vision analysis: %s" % attachment_name,
		profile,
		messages,
		"object",
		{
			"field_ids": field_ids,
			"preview_fields": preview_fields,
			"output_policy": {"mode": "strict", "unexpected_fields": "ignore"},
			"attachment_id": str(attachment.get("attachment_id", "")),
			"attachment_name": attachment_name,
			"analysis_mode": "concept",
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
	var effective_profile := profile.duplicate(true)
	if job_type == "vision_analysis":
		if profile.has("vision_model"):
			effective_profile["model"] = str(profile.get("vision_model", "")).strip_edges()
		else:
			effective_profile["model"] = str(profile.get("model", "")).strip_edges()
	return super._queue_chat_job(
		job_type,
		label,
		effective_profile,
		messages,
		parse_mode,
		metadata,
		retry_count
	)


func _parse_job_output_with_diagnostics(content: String, parse_mode: String) -> Dictionary:
	var candidates := _json_candidates(content)
	var candidate_index := 0
	var first_error := ""
	for candidate in candidates:
		var candidate_text := str(candidate)
		var parse_attempt := _parse_json_quiet(candidate_text)
		var parsed_value: Variant = parse_attempt.get("data") if bool(parse_attempt.get("ok", false)) else null
		var strategy := "direct" if candidate_index == 0 else "extracted_json"
		if parsed_value == null:
			if first_error.is_empty():
				first_error = str(parse_attempt.get("diagnostic", "Malformed JSON."))
			var repaired_candidate := _repair_common_json(candidate_text)
			if repaired_candidate != candidate_text:
				var repaired_attempt := _parse_json_quiet(repaired_candidate)
				if bool(repaired_attempt.get("ok", false)):
					parsed_value = repaired_attempt.get("data")
					strategy = "local_json_repair"
		if parsed_value != null:
			var normalised := _normalise_parsed_output(parsed_value, parse_mode)
			if bool(normalised.get("ok", false)):
				normalised["strategy"] = strategy
				return normalised
		candidate_index += 1
	var diagnostic := (
		"Expected %s output, but the assistant response did not contain a usable matching JSON structure."
		% _expected_shape_description(parse_mode)
	)
	if not first_error.is_empty():
		diagnostic += " First parse failure: %s" % first_error
	return {"ok": false, "diagnostic": diagnostic}


func _parse_json_quiet(text: String) -> Dictionary:
	var parser := JSON.new()
	var error_code: int = parser.parse(text)
	if error_code != OK:
		return {
			"ok": false,
			"diagnostic": "%s at line %d." % [parser.get_error_message(), parser.get_error_line()]
		}
	return {"ok": true, "data": parser.data}
