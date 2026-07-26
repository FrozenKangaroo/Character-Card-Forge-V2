class_name CCFGenerationService
extends Node

signal job_started(job_id: String, job_type: String, label: String)
signal job_completed(job_id: String, job_type: String, data: Variant, metadata: Dictionary)
signal job_failed(job_id: String, job_type: String, message: String)
signal job_cancelled(job_id: String, job_type: String)
signal queue_changed(pending_count: int, active_job_id: String, active_label: String)

var _request: HTTPRequest
var _queue: Array[Dictionary] = []
var _active_job: Dictionary = {}
var _next_job_number := 1


func _ready() -> void:
	_create_request_node()


func queue_character_generation(
	project: Dictionary,
	template: Dictionary,
	profile: Dictionary,
	include_existing_fields: bool,
	retry_count: int
) -> Dictionary:
	var concept := (
		str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()
	)
	if concept.is_empty():
		return {"ok": false, "error": "Enter a generation concept before generating."}

	var fields := CCFTemplateService.generation_fields(template)
	if fields.is_empty():
		return {"ok": false, "error": "The active template has no AI-generatable fields."}

	var field_lines: Array[String] = []
	var existing_lines: Array[String] = []
	var field_ids: Array[String] = []
	for field in fields:
		var field_id := str(field.get("id", "field"))
		var label := str(field.get("label", field_id))
		var type_instruction := _field_type_instruction(field)
		var required_note := "required" if bool(field.get("required", false)) else "optional"
		var custom_instruction := str(field.get("generation_prompt", "")).strip_edges()
		var line := "- %s: %s (%s, %s)" % [field_id, label, type_instruction, required_note]
		if not custom_instruction.is_empty():
			line += " — %s" % custom_instruction
		field_ids.append(field_id)
		field_lines.append(line)
		if include_existing_fields:
			var current_value = CCFStorageService.get_value_at_path(
				project, str(field.get("path", "")), ""
			)
			var rendered_value := _value_to_text(current_value)
			if not rendered_value.strip_edges().is_empty():
				existing_lines.append("%s: %s" % [field_id, rendered_value])

	var global_rules: Array[String] = []
	for rule in template.get("global_generation_instructions", []):
		var rule_text := str(rule).strip_edges()
		if not rule_text.is_empty():
			global_rules.append(rule_text)

	var policy := CCFTemplateService.output_policy(template)
	var policy_mode := str(policy.get("mode", "strict"))
	var user_prompt := (
		"Create a complete roleplay character from the concept below.\n\nCONCEPT:\n%s\n\nREQUESTED JSON FIELDS:\n%s"
		% [concept, _join_values(field_lines, "\n")]
	)
	var shared_context_text := _shared_context_text(project)
	if not shared_context_text.is_empty():
		user_prompt += "\n\nSHARED MULTI-CHARACTER PROJECT CONTEXT:\n%s" % shared_context_text
		user_prompt += "\nKeep this character consistent with the shared project context while preserving their individual identity."
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		user_prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context_text
		user_prompt += "\nTreat the series bible as continuity and style guidance. Do not copy it verbatim into card fields."
	var relationship_context_text := _relationship_context_text(project)
	if not relationship_context_text.is_empty():
		user_prompt += "\n\nESTABLISHED RELATIONSHIPS FOR THIS CHARACTER:\n%s" % relationship_context_text
		user_prompt += "\nRespect these relationship dynamics without letting them replace the character's individual personality."
	var attachment_context_text := _workspace_attachment_context_text(project)
	if not attachment_context_text.is_empty():
		user_prompt += "\n\nENABLED ATTACHMENT CONTEXT:\n%s" % attachment_context_text
		user_prompt += "\nUse attachment text and notes as supporting context. Image metadata is descriptive only unless a separate vision analysis has been reviewed."
	if not existing_lines.is_empty():
		user_prompt += (
			"\n\nEXISTING VALUES TO PRESERVE OR IMPROVE WHEN USEFUL:\n%s"
			% _join_values(existing_lines, "\n")
		)
	if policy_mode == "strict":
		user_prompt += "\n\nReturn one JSON object using only the requested keys. Do not add commentary or markdown fences."
	else:
		user_prompt += "\n\nReturn one JSON object containing the requested keys. You may add genuinely useful extra keys when the concept strongly benefits from them, but keep extras concise and avoid duplicating requested fields."
	user_prompt += "\nUse JSON booleans for checkbox fields, JSON numbers for number fields, and arrays of strings for tags. Return valid JSON only."

	var system_text := "You are Character Card Forge, an expert character-card writing assistant."
	if not global_rules.is_empty():
		system_text += " " + _join_values(global_rules, " ")
	var messages := [
		{"role": "system", "content": system_text}, {"role": "user", "content": user_prompt}
	]

	return _queue_chat_job(
		"character",
		"Full character generation",
		profile,
		messages,
		"object",
		{
			"field_ids": field_ids,
			"concept": concept,
			"template_id": str(template.get("template_id", "default")),
			"output_policy": policy.duplicate(true),
			"project_id": str(project.get("project_id", ""))
		},
		retry_count
	)


func queue_field_suggestion(
	project: Dictionary,
	template: Dictionary,
	field: Dictionary,
	profile: Dictionary,
	retry_count: int
) -> Dictionary:
	var field_id := str(field.get("id", "field"))
	var field_label := str(field.get("label", field_id))
	var field_path := str(field.get("path", ""))
	if field_path.is_empty():
		return {"ok": false, "error": "This field does not have a valid project path."}

	var concept := (
		str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()
	)
	if concept.is_empty():
		return {
			"ok": false, "error": "Enter a generation concept before requesting a field suggestion."
		}

	var context_lines: Array[String] = []
	for context_field in CCFTemplateService.generation_fields(template):
		var context_path := str(context_field.get("path", ""))
		var context_value = CCFStorageService.get_value_at_path(project, context_path, "")
		var rendered_value := _value_to_text(context_value)
		if not rendered_value.strip_edges().is_empty():
			context_lines.append(
				(
					"%s: %s"
					% [
						str(context_field.get("label", context_field.get("id", "Field"))),
						rendered_value
					]
				)
			)

	var current_value := _value_to_text(
		CCFStorageService.get_value_at_path(project, field_path, "")
	)
	var prompt := (
		"Write or improve one character-card field.\n\nCONCEPT:\n%s\n\nTARGET FIELD:\n%s\nTYPE:\n%s"
		% [concept, field_label, _field_type_instruction(field)]
	)
	var shared_context_text := _shared_context_text(project)
	if not shared_context_text.is_empty():
		prompt += "\n\nSHARED MULTI-CHARACTER PROJECT CONTEXT:\n%s" % shared_context_text
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context_text
	var relationship_context_text := _relationship_context_text(project)
	if not relationship_context_text.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS FOR THIS CHARACTER:\n%s" % relationship_context_text
	var attachment_context_text := _workspace_attachment_context_text(project)
	if not attachment_context_text.is_empty():
		prompt += "\n\nENABLED ATTACHMENT CONTEXT:\n%s" % attachment_context_text
	var custom_instruction := str(field.get("generation_prompt", "")).strip_edges()
	if not custom_instruction.is_empty():
		prompt += "\n\nFIELD-SPECIFIC INSTRUCTION OR QUESTION:\n%s" % custom_instruction
	if not current_value.strip_edges().is_empty():
		prompt += "\n\nCURRENT VALUE:\n%s" % current_value
	if not context_lines.is_empty():
		prompt += "\n\nOTHER CHARACTER CONTEXT:\n%s" % _join_values(context_lines, "\n\n")
	prompt += '\n\nReturn valid JSON only in this exact shape: {"value": <the proposed field value>}.'
	var field_type := str(field.get("type", "multiline"))
	if field_type == "tags":
		prompt += " The value must be an array of short tag strings."
	elif field_type == "checkbox":
		prompt += " The value must be true or false."
	elif field_type == "number":
		prompt += " The value must be a JSON number."
	elif field_type == "select":
		prompt += " The value must be one of: %s." % _join_values(field.get("options", []), ", ")

	var messages := [
		{
			"role": "system",
			"content":
			"You are Character Card Forge, an expert roleplay character-card editor. Keep the suggestion consistent with supplied character context and avoid contradicting established details."
		},
		{"role": "user", "content": prompt}
	]

	return _queue_chat_job(
		"field",
		"Suggest %s" % field_label,
		profile,
		messages,
		"field",
		{
			"field": field.duplicate(true),
			"field_id": field_id,
			"field_path": field_path,
			"project_id": str(project.get("project_id", ""))
		},
		retry_count
	)


func queue_vision_analysis(
	project: Dictionary,
	template: Dictionary,
	attachment: Dictionary,
	profile: Dictionary,
	analysis_mode: String,
	retry_count: int
) -> Dictionary:
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

	var mode := analysis_mode if analysis_mode in ["concept", "full_card"] else "concept"
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
		"- concept_prompt: a detailed generation-ready character concept grounded in the visible evidence"
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
		if mode == "concept" and not field_id in ["name", "description", "personality", "tags"]:
			continue
		preview_fields.append(field.duplicate(true))
		field_ids.append(field_id)
		field_lines.append(
			"- %s: %s (%s)" % [
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
		"Analyse the attached visual reference for Character Card Forge. Distinguish direct visual evidence from creative inference. Do not identify a real person or claim certainty about facts that are not visible."
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
		prompt += "\n\nCURRENT CHARACTER CONCEPT — use for continuity, but propose rather than overwrite:\n%s" % existing_concept
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context_text
	var relationship_context_text := _relationship_context_text(project)
	if not relationship_context_text.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS FOR CONTINUITY:\n%s" % relationship_context_text
	var attachment_context_text := _workspace_attachment_context_text(project)
	if not attachment_context_text.is_empty():
		prompt += "\n\nOTHER ENABLED ATTACHMENT CONTEXT:\n%s" % attachment_context_text
	if mode == "full_card":
		prompt += "\n\nCreate controlled full-card suggestions. Visual facts should remain faithful to the image; personality, history, and roleplay hooks must be clearly plausible creative proposals rather than presented as observed facts."
	else:
		prompt += "\n\nExtract a concise but useful character concept and visual-description foundation. Keep non-visual personality suggestions conservative and roleplay-oriented."
	prompt += "\n\nRETURNED JSON KEYS:\n%s" % _join_values(field_lines, "\n")
	prompt += "\n\nReturn one valid JSON object using only those keys. Do not add markdown fences or commentary. Tags must be arrays of short strings, checkbox values must be booleans, and number fields must be JSON numbers."

	var detail := str(profile.get("vision_detail", "auto"))
	if not detail in ["auto", "low", "high"]:
		detail = "auto"
	var messages := [
		{
			"role": "system",
			"content": "You are Character Card Forge's multimodal character-reference analyst. Produce reviewable suggestions, never silently overwrite project data, and return valid JSON only."
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
			"analysis_mode": mode,
			"project_id": str(project.get("project_id", ""))
		},
		retry_count
	)


func queue_controlled_build(
	project: Dictionary,
	template: Dictionary,
	target_fields: Array,
	profile: Dictionary,
	mode: String,
	scope_label: String,
	revision_instruction: String,
	retry_count: int
) -> Dictionary:
	if target_fields.is_empty():
		return {"ok": false, "error": "Select at least one AI-generatable field."}

	var target_ids: Array[String] = []
	var target_lines: Array[String] = []
	var target_current_lines: Array[String] = []
	var target_paths: Dictionary = {}
	for field in target_fields:
		if not field is Dictionary or not bool(field.get("generate", false)):
			continue
		var field_id := str(field.get("id", "")).strip_edges()
		var field_path := str(field.get("path", "")).strip_edges()
		if field_id.is_empty() or field_path.is_empty() or target_ids.has(field_id):
			continue
		target_ids.append(field_id)
		target_paths[field_path] = true
		var target_line := (
			"- %s: %s (%s)"
			% [field_id, str(field.get("label", field_id)), _field_type_instruction(field)]
		)
		var custom_instruction := str(field.get("generation_prompt", "")).strip_edges()
		if not custom_instruction.is_empty():
			target_line += " — %s" % custom_instruction
		target_lines.append(target_line)
		var current_value := (
			_value_to_text(CCFStorageService.get_value_at_path(project, field_path, ""))
			. strip_edges()
		)
		if not current_value.is_empty():
			target_current_lines.append("%s: %s" % [field_id, current_value])

	if target_ids.is_empty():
		return {"ok": false, "error": "The selected fields are not valid generation targets."}

	var protected_lines: Array[String] = []
	for context_field in CCFTemplateService.generation_fields(template):
		var context_path := str(context_field.get("path", ""))
		if target_paths.has(context_path):
			continue
		var context_value := (
			_value_to_text(CCFStorageService.get_value_at_path(project, context_path, ""))
			. strip_edges()
		)
		if not context_value.is_empty():
			protected_lines.append(
				(
					"%s: %s"
					% [
						str(context_field.get("label", context_field.get("id", "Field"))),
						context_value
					]
				)
			)

	var concept := (
		str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()
	)
	if concept.is_empty() and target_current_lines.is_empty() and protected_lines.is_empty():
		return {
			"ok": false,
			"error":
			"Add a generation concept or some existing character content before using a controlled build."
		}

	var global_rules: Array[String] = []
	for rule in template.get("global_generation_instructions", []):
		var rule_text := str(rule).strip_edges()
		if not rule_text.is_empty():
			global_rules.append(rule_text)

	var prompt := "Perform a controlled partial build for a roleplay character card."
	if not concept.is_empty():
		prompt += "\n\nCHARACTER CONCEPT:\n%s" % concept
	prompt += "\n\nONLY THESE JSON KEYS MAY BE RETURNED:\n%s" % _join_values(target_lines, "\n")
	var shared_context_text := _shared_context_text(project)
	if not shared_context_text.is_empty():
		prompt += "\n\nSHARED MULTI-CHARACTER PROJECT CONTEXT:\n%s" % shared_context_text
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE — protected continuity and style context:\n%s" % series_context_text
	var relationship_context_text := _relationship_context_text(project)
	if not relationship_context_text.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS FOR THIS CHARACTER — context only, do not rewrite unrelated relationship data:\n%s" % relationship_context_text
	var attachment_context_text := _workspace_attachment_context_text(project)
	if not attachment_context_text.is_empty():
		prompt += "\n\nENABLED ATTACHMENT CONTEXT — context only, do not rewrite unrelated fields:\n%s" % attachment_context_text
	if not target_current_lines.is_empty():
		if mode == "revision":
			prompt += (
				"\n\nEXISTING TARGET VALUES TO REVISE:\n%s"
				% _join_values(target_current_lines, "\n\n")
			)
		else:
			prompt += (
				"\n\nCURRENT TARGET VALUES — preserve useful established details while improving or completing them:\n%s"
				% _join_values(target_current_lines, "\n\n")
			)
	if not protected_lines.is_empty():
		prompt += (
			"\n\nPROTECTED CHARACTER CONTEXT — use this for consistency, but do not return or rewrite these fields:\n%s"
			% _join_values(protected_lines, "\n\n")
		)
	if mode == "revision":
		prompt += "\n\nREVISION INSTRUCTIONS:\n%s" % revision_instruction.strip_edges()
		prompt += "\nRevise only the selected target fields. Preserve established facts unless the revision instructions explicitly ask for a change."
	elif mode == "safe_section":
		prompt += "\n\nThis is a Safe Section Build. Complete the selected section cohesively while leaving every field outside it untouched."
	else:
		prompt += "\n\nThis is a Custom Section Build. Generate exactly the selected subset and do not infer that unselected fields should be rewritten."
	prompt += "\n\nReturn one valid JSON object using only the allowed keys listed above. Do not add commentary or markdown fences. Use JSON booleans for checkbox fields, JSON numbers for number fields, and arrays of strings for tags."

	var system_text := "You are Character Card Forge's controlled character-card editor. Scope discipline is mandatory: never rewrite content outside the explicitly requested fields."
	if not global_rules.is_empty():
		system_text += " " + _join_values(global_rules, " ")

	var messages := [
		{"role": "system", "content": system_text}, {"role": "user", "content": prompt}
	]

	return _queue_chat_job(
		"controlled_build",
		"Controlled build: %s" % scope_label,
		profile,
		messages,
		"object",
		{
			"field_ids": target_ids,
			"scope_label": scope_label,
			"controlled_mode": mode,
			"revision_instruction": revision_instruction,
			"template_id": str(template.get("template_id", "default")),
			"output_policy": {"mode": "strict", "unexpected_fields": "ignore"},
			"project_id": str(project.get("project_id", ""))
		},
		retry_count
	)


func queue_idea_generation(
	seed_text: String,
	profile: Dictionary,
	idea_count: int,
	retry_count: int,
	project_id: String = "",
	series_context: String = ""
) -> Dictionary:
	var safe_count := clampi(idea_count, 1, 12)
	var idea_seed := seed_text.strip_edges()
	var prompt := "Generate %d distinct roleplay character concepts." % safe_count
	if not idea_seed.is_empty():
		prompt += (
			" Use the following theme, fragments, constraints, or inspiration:\n\n%s" % idea_seed
		)
	else:
		prompt += " Make the concepts varied in genre, personality, role, and dramatic hook."
	var clean_series_context := series_context.strip_edges()
	if not clean_series_context.is_empty():
		prompt += (
			"\n\nASSIGNED SERIES BIBLE:\n%s"
			+ "\n\nKeep every concept compatible with this series while still making the ideas distinct."
		) % clean_series_context
	prompt += "\n\nReturn a JSON array only. Each array item must be an object with exactly these keys: title, concept, tags. title is a short working character name or concept title, concept is a detailed generation-ready paragraph, and tags is an array of short strings."

	var messages := [
		{
			"role": "system",
			"content":
			"You are Character Card Forge's Idea Generator. Produce specific, roleplay-ready concepts with strong hooks rather than generic archetypes. Return valid JSON only."
		},
		{"role": "user", "content": prompt}
	]

	return _queue_chat_job(
		"ideas",
		"Generate %d character ideas" % safe_count,
		profile,
		messages,
		"ideas",
		{"idea_count": safe_count, "seed": idea_seed, "project_id": project_id},
		retry_count
	)


func queue_builder_fill(
	builder_state: Dictionary,
	builder_fields: Array,
	profile: Dictionary,
	scope_label: String,
	retry_count: int,
	project_id: String = "",
	series_context: String = ""
) -> Dictionary:
	if builder_fields.is_empty():
		return {"ok": false, "error": "The selected builder step has no fields to generate."}

	var requested_lines: Array[String] = []
	var allowed_paths: Array[String] = []
	for builder_field in builder_fields:
		if not builder_field is Dictionary:
			continue
		var field_path := str(builder_field.get("path", ""))
		if field_path.is_empty():
			continue
		var label := str(builder_field.get("label", builder_field.get("id", field_path)))
		var field_type := str(builder_field.get("type", "line"))
		requested_lines.append(
			"- %s: %s (%s)" % [field_path, label, _builder_type_instruction(field_type)]
		)
		allowed_paths.append(field_path)

	if allowed_paths.is_empty():
		return {"ok": false, "error": "The selected builder step has no valid field paths."}

	var existing_context := _builder_state_context(builder_state)
	var prompt := "Fill the selected Character Card Forge guided-builder fields with creative, internally consistent details."
	prompt += "\n\nREQUESTED FIELDS:\n%s" % _join_values(requested_lines, "\n")
	if not existing_context.is_empty():
		prompt += "\n\nEXISTING BUILDER CONTEXT:\n%s" % existing_context
	if not series_context.strip_edges().is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context.strip_edges()
	prompt += "\n\nReturn one nested JSON object matching the dot-separated paths above. Only include requested fields. Use arrays of short strings for tag fields. Do not add commentary or markdown fences."

	var messages := [
		{
			"role": "system",
			"content":
			"You are Character Card Forge's guided Character Builder. Create specific roleplay-ready details with useful contradictions and hooks. Respect all supplied builder context and return valid JSON only."
		},
		{"role": "user", "content": prompt}
	]

	return _queue_chat_job(
		"builder_fill",
		"AI fill: %s" % scope_label,
		profile,
		messages,
		"object",
		{"allowed_paths": allowed_paths, "scope_label": scope_label, "project_id": project_id},
		retry_count
	)


func queue_builder_extract(
	concept: String,
	builder_fields: Array,
	profile: Dictionary,
	retry_count: int,
	project_id: String = "",
	series_context: String = ""
) -> Dictionary:
	var clean_concept := concept.strip_edges()
	if clean_concept.is_empty():
		return {"ok": false, "error": "The current character does not have a concept to analyse."}

	var requested_lines: Array[String] = []
	var allowed_paths: Array[String] = []
	for builder_field in builder_fields:
		if not builder_field is Dictionary:
			continue
		var field_path := str(builder_field.get("path", ""))
		if field_path.is_empty():
			continue
		var label := str(builder_field.get("label", builder_field.get("id", field_path)))
		var field_type := str(builder_field.get("type", "line"))
		requested_lines.append(
			"- %s: %s (%s)" % [field_path, label, _builder_type_instruction(field_type)]
		)
		allowed_paths.append(field_path)

	var prompt := "Extract structured Character Builder details from the character concept below. Do not invent details unless a modest inference is necessary to express information already strongly implied by the concept. Omit fields that cannot be supported."
	prompt += "\n\nCHARACTER CONCEPT:\n%s" % clean_concept
	prompt += "\n\nAVAILABLE BUILDER FIELDS:\n%s" % _join_values(requested_lines, "\n")
	if not series_context.strip_edges().is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context.strip_edges()
	prompt += "\n\nReturn one nested JSON object matching the dot-separated paths above. Use arrays of short strings for tag fields. Do not add commentary or markdown fences."

	var messages := [
		{
			"role": "system",
			"content":
			"You are Character Card Forge's concept analyser. Convert freeform character concepts into structured builder notes conservatively and return valid JSON only."
		},
		{"role": "user", "content": prompt}
	]

	return _queue_chat_job(
		"builder_extract",
		"Analyse concept for Character Builder",
		profile,
		messages,
		"object",
		{"allowed_paths": allowed_paths, "project_id": project_id},
		retry_count
	)


func queue_group_scene_generation(
	project: Dictionary,
	selected_character_ids: Array[String],
	instructions: String,
	profile: Dictionary,
	retry_count: int
) -> Dictionary:
	if selected_character_ids.size() < 2:
		return {"ok": false, "error": "Select at least two characters for group generation."}

	var character_blocks: Array[String] = []
	var valid_character_ids: Array[String] = []
	for character_id in selected_character_ids:
		var character_record := CCFStorageService.get_character(project, character_id)
		if character_record.is_empty():
			continue
		valid_character_ids.append(character_id)
		var character_data = character_record.get("character", {})
		var metadata = character_record.get("metadata", {})
		var concept = character_record.get("concept", {})
		var lines: Array[String] = []
		lines.append("CHARACTER ID: %s" % character_id)
		lines.append("NAME: %s" % CCFStorageService.character_display_name(character_record))
		if metadata is Dictionary:
			var role := str(metadata.get("role", "")).strip_edges()
			if not role.is_empty():
				lines.append("GROUP ROLE: %s" % role)
		if concept is Dictionary:
			var concept_text := str(concept.get("prompt", "")).strip_edges()
			if not concept_text.is_empty():
				lines.append("CONCEPT: %s" % concept_text)
		if character_data is Dictionary:
			for field_id in ["description", "personality", "scenario"]:
				var value := str(character_data.get(field_id, "")).strip_edges()
				if not value.is_empty():
					lines.append("%s: %s" % [field_id.to_upper(), value])
		character_blocks.append(_join_values(lines, "\n"))

	if valid_character_ids.size() < 2:
		return {"ok": false, "error": "At least two selected characters must still exist in the project."}

	var shared_context = project.get("shared_context", {})
	var shared_lines: Array[String] = []
	if shared_context is Dictionary:
		for field_id in ["title", "premise", "setting", "situation", "shared_rules"]:
			var value := str(shared_context.get(field_id, "")).strip_edges()
			if not value.is_empty():
				shared_lines.append("%s: %s" % [field_id.replace("_", " ").to_upper(), value])

	var prompt := "Create a coherent shared roleplay scene setup for the selected characters. The characters must remain individually recognisable and consistent with their supplied information."
	if not shared_lines.is_empty():
		prompt += "\n\nEXISTING SHARED PROJECT CONTEXT TO PRESERVE OR IMPROVE:\n%s" % _join_values(shared_lines, "\n")
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context_text
	prompt += "\n\nSELECTED CHARACTERS:\n\n%s" % _join_values(character_blocks, "\n\n---\n\n")
	var relationship_context_text := CCFRelationshipService.context_for_characters(
		project, valid_character_ids
	)
	if not relationship_context_text.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS AMONG THE SELECTED CHARACTERS:\n%s" % relationship_context_text
	var attachment_context_text := _project_attachment_context_text(project, valid_character_ids)
	if not attachment_context_text.is_empty():
		prompt += "\n\nENABLED ATTACHMENT CONTEXT:\n%s" % attachment_context_text
	var clean_instructions := instructions.strip_edges()
	if not clean_instructions.is_empty():
		prompt += "\n\nUSER INSTRUCTIONS:\n%s" % clean_instructions
	prompt += (
		"\n\nReturn one valid JSON object with exactly two top-level keys: shared_context and characters. "
		+ "shared_context must be an object that may contain title, premise, setting, situation, shared_rules, and notes. "
		+ "characters must be an array with one object for each selected character, using exactly character_id and scenario. "
		+ "The scenario should describe that character's place in the shared opening situation without rewriting their identity. "
		+ "Use the exact CHARACTER ID values supplied above. Return JSON only with no commentary or markdown fences."
	)

	var messages := [
		{
			"role": "system",
			"content": "You are Character Card Forge's multi-character scene designer. Build a shared roleplay setup that respects every selected character, avoids flattening distinct personalities, and keeps continuity across the group."
		},
		{"role": "user", "content": prompt}
	]

	return _queue_chat_job(
		"group_scene",
		"Generate shared group scene",
		profile,
		messages,
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"selected_character_ids": valid_character_ids,
			"instructions": clean_instructions
		},
		retry_count
	)


func queue_relationship_generation(
	project: Dictionary,
	selected_character_ids: Array[String],
	instructions: String,
	profile: Dictionary,
	retry_count: int
) -> Dictionary:
	if selected_character_ids.size() < 2:
		return {"ok": false, "error": "Select at least two characters for relationship generation."}

	var valid_character_ids: Array[String] = []
	var character_blocks: Array[String] = []
	for character_id in selected_character_ids:
		var character_record := CCFStorageService.get_character(project, character_id)
		if character_record.is_empty():
			continue
		valid_character_ids.append(character_id)
		var lines: Array[String] = []
		lines.append("CHARACTER ID: %s" % character_id)
		lines.append("NAME: %s" % CCFStorageService.character_display_name(character_record))
		var metadata = character_record.get("metadata", {})
		if metadata is Dictionary:
			var group_role := str(metadata.get("role", "")).strip_edges()
			if not group_role.is_empty():
				lines.append("GROUP ROLE: %s" % group_role)
		var concept = character_record.get("concept", {})
		if concept is Dictionary:
			var concept_text := str(concept.get("prompt", "")).strip_edges()
			if not concept_text.is_empty():
				lines.append("CONCEPT: %s" % concept_text)
		var character_data = character_record.get("character", {})
		if character_data is Dictionary:
			for field_id in ["description", "personality", "scenario"]:
				var field_value := str(character_data.get(field_id, "")).strip_edges()
				if not field_value.is_empty():
					lines.append("%s: %s" % [field_id.to_upper(), field_value])
		character_blocks.append(_join_values(lines, "\n"))

	if valid_character_ids.size() < 2:
		return {"ok": false, "error": "At least two selected characters must still exist in the project."}

	var pair_lines: Array[String] = []
	for first_index in range(valid_character_ids.size()):
		for second_index in range(first_index + 1, valid_character_ids.size()):
			var first_id := valid_character_ids[first_index]
			var second_id := valid_character_ids[second_index]
			pair_lines.append("- %s | %s" % [first_id, second_id])

	var prompt := "Create a coherent relationship matrix for every requested pair of selected roleplay characters. Relationships may be positive, negative, mixed, secret, evolving, or asymmetrical. Preserve each character's established identity and do not flatten everyone into the same dynamic."
	var shared_context_text := _shared_context_text(project)
	if not shared_context_text.is_empty():
		prompt += "\n\nSHARED PROJECT CONTEXT:\n%s" % shared_context_text
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context_text
	var existing_relationships := CCFRelationshipService.context_for_characters(
		project, valid_character_ids
	)
	if not existing_relationships.is_empty():
		prompt += "\n\nEXISTING RELATIONSHIPS TO PRESERVE OR THOUGHTFULLY IMPROVE:\n%s" % existing_relationships
	var attachment_context_text := _project_attachment_context_text(project, valid_character_ids)
	if not attachment_context_text.is_empty():
		prompt += "\n\nENABLED ATTACHMENT CONTEXT:\n%s" % attachment_context_text
	prompt += "\n\nSELECTED CHARACTERS:\n\n%s" % _join_values(character_blocks, "\n\n---\n\n")
	prompt += "\n\nREQUIRED PAIRS — return exactly one relationship object for every pair:\n%s" % _join_values(pair_lines, "\n")
	var clean_instructions := instructions.strip_edges()
	if not clean_instructions.is_empty():
		prompt += "\n\nUSER INSTRUCTIONS:\n%s" % clean_instructions
	prompt += (
		"\n\nReturn one valid JSON object with exactly one top-level key: relationships. "
		+ "relationships must be an array. Every item must contain character_a_id, character_b_id, label, status, summary, a_to_b, b_to_a, dynamic, notes, tags, and intensity. "
		+ "Use the exact CHARACTER ID values supplied above. tags must be an array of short strings and intensity must be an integer from 0 to 100. "
		+ "a_to_b describes the first listed character's feelings or behaviour toward the second; b_to_a describes the reverse direction. Return JSON only."
	)

	var messages := [
		{
			"role": "system",
			"content": "You are Character Card Forge's relationship designer. Create nuanced, asymmetric, roleplay-useful relationship dynamics with clear continuity and exact character identifiers."
		},
		{"role": "user", "content": prompt}
	]

	return _queue_chat_job(
		"relationship_generation",
		"Generate relationship matrix",
		profile,
		messages,
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"selected_character_ids": valid_character_ids,
			"instructions": clean_instructions
		},
		retry_count
	)


func queue_card_workflow_generation(
	project: Dictionary,
	selected_character_ids: Array[String],
	workflow_mode: String,
	instructions: String,
	profile: Dictionary,
	retry_count: int
) -> Dictionary:
	if selected_character_ids.size() < 2:
		return {"ok": false, "error": "Select at least two characters for a multi-character card workflow."}
	var valid_modes := ["multi_single", "split_batch", "group_card"]
	var selected_mode := workflow_mode if workflow_mode in valid_modes else "multi_single"
	var valid_character_ids: Array[String] = []
	var character_blocks: Array[String] = []
	for character_id in selected_character_ids:
		var character_record := CCFStorageService.get_character(project, character_id)
		if character_record.is_empty():
			continue
		valid_character_ids.append(character_id)
		var lines: Array[String] = []
		lines.append("CHARACTER ID: %s" % character_id)
		lines.append("NAME: %s" % CCFStorageService.character_display_name(character_record))
		var metadata = character_record.get("metadata", {})
		if metadata is Dictionary:
			var group_role := str(metadata.get("role", "")).strip_edges()
			if not group_role.is_empty():
				lines.append("GROUP ROLE: %s" % group_role)
		var character_data = character_record.get("character", {})
		if character_data is Dictionary:
			for field_id in ["description", "personality", "scenario", "first_message"]:
				var field_value := str(character_data.get(field_id, "")).strip_edges()
				if not field_value.is_empty():
					lines.append("%s: %s" % [field_id.to_upper(), field_value])
		character_blocks.append(_join_values(lines, "\n"))
	if valid_character_ids.size() < 2:
		return {"ok": false, "error": "At least two selected characters must still exist in the project."}

	var mode_instruction: String
	match selected_mode:
		"multi_single":
			mode_instruction = "Design one combined character card in which the selected characters coexist as a coherent ensemble controlled by one card. Define how the card presents and balances each member without merging their identities."
		"split_batch":
			mode_instruction = "Design a coordinated batch of separate character cards generated from one shared project setup. Each card must stand alone while remaining continuity-compatible with the others."
		"group_card":
			mode_instruction = "Design a group-card output focused on the collective, shared premise, and interaction structure while keeping each member individually recognisable."
		_:
			mode_instruction = "Design a coherent multi-character output workflow."
	var prompt: String = mode_instruction
	var shared_context_text := _shared_context_text(project)
	if not shared_context_text.is_empty():
		prompt += "\n\nSHARED PROJECT CONTEXT:\n%s" % shared_context_text
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context_text
	var relationship_context_text := CCFRelationshipService.context_for_characters(
		project, valid_character_ids
	)
	if not relationship_context_text.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS:\n%s" % relationship_context_text
	var attachment_context_text := _project_attachment_context_text(project, valid_character_ids)
	if not attachment_context_text.is_empty():
		prompt += "\n\nENABLED ATTACHMENT CONTEXT:\n%s" % attachment_context_text
	prompt += "\n\nSELECTED CHARACTERS:\n\n%s" % _join_values(character_blocks, "\n\n---\n\n")
	var clean_instructions := instructions.strip_edges()
	if not clean_instructions.is_empty():
		prompt += "\n\nUSER WORKFLOW INSTRUCTIONS:\n%s" % clean_instructions
	prompt += (
		"\n\nReturn one valid JSON object with exactly these top-level keys: title, summary, shared_scenario, opening_message, notes, members. "
		+ "members must be an array with exactly one object for each selected character, using character_id, role_in_output, card_direction, scenario_direction, and opening_direction. "
		+ "Use the exact CHARACTER ID values supplied above. The directions should be practical instructions for later card generation, not generic praise. Return JSON only."
	)
	var messages := [
		{
			"role": "system",
			"content": "You are Character Card Forge's multi-character card architect. Plan coherent card outputs that preserve individual character identity, established relationships, and shared continuity."
		},
		{"role": "user", "content": prompt}
	]
	return _queue_chat_job(
		"multi_card_workflow",
		"Generate card workflow plan",
		profile,
		messages,
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"selected_character_ids": valid_character_ids,
			"workflow_mode": selected_mode,
			"instructions": clean_instructions
		},
		retry_count
	)


func queue_series_generation(
	seed_text: String,
	existing_series: Dictionary,
	profile: Dictionary,
	retry_count: int
) -> Dictionary:
	var clean_seed := seed_text.strip_edges()
	var existing_lines: Array[String] = []
	for field_id in [
		"name",
		"description",
		"setting_guidance",
		"canon_notes",
		"visual_direction",
		"generation_rules"
	]:
		var value := str(existing_series.get(field_id, "")).strip_edges()
		if not value.is_empty():
			existing_lines.append("%s: %s" % [field_id.replace("_", " ").capitalize(), value])
	for field_id in ["aliases", "categories", "default_tags", "matching_keywords"]:
		var raw_values: Variant = existing_series.get(field_id, [])
		if raw_values is Array and not raw_values.is_empty():
			existing_lines.append(
				"%s: %s" % [field_id.replace("_", " ").capitalize(), _join_values(raw_values, ", ")]
		)
	if clean_seed.is_empty() and existing_lines.is_empty():
		return {"ok": false, "error": "Provide source notes or existing series content first."}
	var prompt := "Create or improve a reusable Character Card Forge series bible. It may describe an original setting, an existing franchise-inspired continuity, a campaign, or a shared character collection. Keep guidance practical for later character-card generation."
	if not clean_seed.is_empty():
		prompt += "\n\nSOURCE NOTES:\n%s" % clean_seed
	if not existing_lines.is_empty():
		prompt += "\n\nEXISTING SERIES CONTENT TO PRESERVE OR IMPROVE:\n%s" % _join_values(existing_lines, "\n")
	prompt += (
		"\n\nReturn one valid JSON object with exactly these keys: name, aliases, description, categories, setting_guidance, canon_notes, visual_direction, generation_rules, default_tags, matching_keywords. "
		+ "aliases, categories, default_tags, and matching_keywords must be arrays of concise strings. matching_keywords should contain distinctive terms useful for automatically matching character projects to this series. "
		+ "generation_rules should be actionable continuity constraints rather than generic writing advice. Return JSON only."
	)
	var messages := [
		{
			"role": "system",
			"content": "You are Character Card Forge's series-bible designer. Produce concise, reusable continuity, setting, style, and generation guidance without inventing unnecessary canon."
		},
		{"role": "user", "content": prompt}
	]
	return _queue_chat_job(
		"series_generation",
		"Generate series bible",
		profile,
		messages,
		"object",
		{"series_id": str(existing_series.get("series_id", ""))},
		retry_count
	)


func cancel_active_job() -> void:
	if _active_job.is_empty() or _request == null:
		return
	var cancelled_id := str(_active_job.get("id", ""))
	var cancelled_type := str(_active_job.get("type", ""))
	_request.cancel_request()
	_active_job.clear()
	_create_request_node()
	job_cancelled.emit(cancelled_id, cancelled_type)
	_emit_queue_changed()
	call_deferred("_start_next_job")


func clear_pending_jobs() -> int:
	var removed_count := _queue.size()
	_queue.clear()
	_emit_queue_changed()
	return removed_count


func has_active_job() -> bool:
	return not _active_job.is_empty()


func active_job_id() -> String:
	return str(_active_job.get("id", ""))


func pending_count() -> int:
	return _queue.size()


static func estimate_tokens(text: String) -> int:
	if text.is_empty():
		return 0
	return maxi(1, int(ceil(float(text.length()) / 4.0)))


func _create_request_node() -> void:
	if _request != null:
		if _request.request_completed.is_connected(_on_request_completed):
			_request.request_completed.disconnect(_on_request_completed)
		if _request.get_parent() == self:
			remove_child(_request)
		_request.queue_free()
	_request = HTTPRequest.new()
	_request.timeout = 300.0
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)


func _queue_chat_job(
	job_type: String,
	label: String,
	profile: Dictionary,
	messages: Array,
	parse_mode: String,
	metadata: Dictionary,
	retry_count: int
) -> Dictionary:
	var base_url := str(profile.get("base_url", "")).strip_edges()
	var model := str(profile.get("model", "")).strip_edges()
	if base_url.is_empty():
		return {"ok": false, "error": "Set an API base URL in Settings first."}
	if model.is_empty():
		return {"ok": false, "error": "Set a model in the selected provider profile first."}

	var job_id := "job_%06d" % _next_job_number
	_next_job_number += 1
	var job := {
		"id": job_id,
		"type": job_type,
		"label": label,
		"url": _completion_url(base_url),
		"headers": _request_headers(profile),
		"payload":
		{
			"model": model,
			"temperature": float(profile.get("temperature", 0.8)),
			"max_tokens": int(profile.get("max_output_tokens", 6000)),
			"messages": messages
		},
		"parse_mode": parse_mode,
		"metadata": metadata.duplicate(true),
		"profile_name": str(profile.get("name", "Default")),
		"model": model,
		"max_retries": clampi(retry_count, 0, 5),
		"attempt": 0,
		"repair_attempts": 0
	}
	_queue.append(job)
	var queued_ahead := _queue.size() - 1
	if not _active_job.is_empty():
		queued_ahead += 1
	_emit_queue_changed()
	call_deferred("_start_next_job")
	return {"ok": true, "job_id": job_id, "queued_ahead": queued_ahead}


func _start_next_job() -> void:
	if not _active_job.is_empty() or _queue.is_empty():
		return
	_active_job = _queue.pop_front()
	job_started.emit(
		str(_active_job.get("id", "")),
		str(_active_job.get("type", "")),
		str(_active_job.get("label", "Generation"))
	)
	_emit_queue_changed()
	_start_active_request()


func _start_active_request() -> void:
	if _active_job.is_empty():
		return
	_active_job["attempt"] = int(_active_job.get("attempt", 0)) + 1
	var request_error := _request.request(
		str(_active_job.get("url", "")),
		_active_job.get("headers", PackedStringArray()),
		HTTPClient.METHOD_POST,
		JSON.stringify(_active_job.get("payload", {}))
	)
	if request_error != OK:
		_handle_failure("Could not start API request (error %s)." % request_error, true)


func _on_request_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if _active_job.is_empty():
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_handle_failure("Network request failed (result %s)." % result, true)
		return

	var body_text := body.get_string_from_utf8()
	var parsed_response = JSON.parse_string(body_text)
	if response_code < 200 or response_code >= 300:
		var detail := _extract_error_detail(parsed_response, body_text)
		var retryable := (
			response_code == 408
			or response_code == 409
			or response_code == 429
			or response_code >= 500
		)
		_handle_failure("API error %s: %s" % [response_code, detail.left(1000)], retryable)
		return
	if not parsed_response is Dictionary:
		_handle_failure("The API returned an invalid JSON response envelope.", false)
		return

	var content := _extract_content(parsed_response)
	if content.is_empty():
		_handle_failure("The API response did not contain assistant text.", false)
		return

	_process_completed_content(content)


func _process_completed_content(content: String) -> void:
	var parse_mode := str(_active_job.get("parse_mode", "object"))
	var parse_result := _parse_job_output_with_diagnostics(content, parse_mode)
	if not bool(parse_result.get("ok", false)):
		if _start_json_repair(content, parse_mode):
			return
		var diagnostic := str(parse_result.get("diagnostic", "No valid JSON value was found."))
		var repair_note := (
			" Automatic repair was attempted once."
			if int(_active_job.get("repair_attempts", 0)) > 0
			else ""
		)
		_handle_failure(
			(
				"The model response could not be parsed as the expected JSON structure.%s %s No project data was changed."
				% [repair_note, diagnostic]
			),
			false
		)
		return

	var parsed_data = parse_result.get("data")
	var finished_job := _active_job.duplicate(true)
	_active_job.clear()
	var completed_metadata: Dictionary = finished_job.get("metadata", {}).duplicate(true)
	completed_metadata["model"] = str(finished_job.get("model", ""))
	completed_metadata["profile_name"] = str(finished_job.get("profile_name", ""))
	completed_metadata["attempts"] = int(finished_job.get("attempt", 1))
	completed_metadata["response_repair_attempts"] = int(finished_job.get("repair_attempts", 0))
	completed_metadata["parse_strategy"] = str(parse_result.get("strategy", "direct"))
	job_completed.emit(
		str(finished_job.get("id", "")),
		str(finished_job.get("type", "")),
		parsed_data,
		completed_metadata
	)
	_emit_queue_changed()
	call_deferred("_start_next_job")


func _handle_failure(message: String, retryable: bool) -> void:
	if _active_job.is_empty():
		return
	var attempt := int(_active_job.get("attempt", 1))
	var max_retries := int(_active_job.get("max_retries", 0))
	if retryable and attempt <= max_retries:
		call_deferred("_start_active_request")
		return

	var failed_job := _active_job.duplicate(true)
	_active_job.clear()
	job_failed.emit(str(failed_job.get("id", "")), str(failed_job.get("type", "")), message)
	_emit_queue_changed()
	call_deferred("_start_next_job")


func _parse_job_output_with_diagnostics(content: String, parse_mode: String) -> Dictionary:
	var candidates := _json_candidates(content)
	var candidate_index := 0
	for candidate in candidates:
		var parsed_value = JSON.parse_string(str(candidate))
		var strategy := "direct" if candidate_index == 0 else "extracted_json"
		if parsed_value == null:
			var repaired_candidate := _repair_common_json(str(candidate))
			if repaired_candidate != str(candidate):
				parsed_value = JSON.parse_string(repaired_candidate)
				if parsed_value != null:
					strategy = "local_json_repair"
		if parsed_value != null:
			var normalised := _normalise_parsed_output(parsed_value, parse_mode)
			if bool(normalised.get("ok", false)):
				normalised["strategy"] = strategy
				return normalised
		candidate_index += 1
	return {
		"ok": false,
		"diagnostic":
		(
			"Expected %s output, but the assistant response did not contain a usable matching JSON structure."
			% _expected_shape_description(parse_mode)
		)
	}


func _normalise_parsed_output(parsed_value: Variant, parse_mode: String) -> Dictionary:
	match parse_mode:
		"object":
			if parsed_value is Dictionary:
				if parsed_value.size() == 1:
					for wrapper_key in ["result", "data", "character", "fields"]:
						var wrapped = parsed_value.get(wrapper_key)
						if wrapped is Dictionary:
							return {"ok": true, "data": wrapped}
				return {"ok": true, "data": parsed_value}
		"field":
			if parsed_value is Dictionary and parsed_value.has("value"):
				return {"ok": true, "data": parsed_value.get("value")}
		"ideas":
			if parsed_value is Array:
				return {"ok": true, "data": _normalise_ideas(parsed_value)}
			if parsed_value is Dictionary:
				var ideas = parsed_value.get("ideas", [])
				if ideas is Array:
					return {"ok": true, "data": _normalise_ideas(ideas)}
	return {"ok": false}


func _json_candidates(content: String) -> Array[String]:
	var candidates: Array[String] = []
	var cleaned := content.strip_edges()
	if cleaned.is_empty():
		return candidates

	if cleaned.begins_with("```"):
		var first_newline := cleaned.find("\n")
		if first_newline >= 0:
			cleaned = cleaned.substr(first_newline + 1)
		if cleaned.ends_with("```"):
			cleaned = cleaned.substr(0, cleaned.length() - 3).strip_edges()
	candidates.append(cleaned)

	var extracted := _extract_balanced_json(cleaned)
	if not extracted.is_empty() and extracted != cleaned:
		candidates.append(extracted)
	return candidates


func _extract_balanced_json(text: String) -> String:
	var start := -1
	var opening := ""
	var closing := ""
	for index in range(text.length()):
		var character := text[index]
		if character == "{" or character == "[":
			start = index
			opening = character
			closing = "}" if character == "{" else "]"
			break
	if start < 0:
		return ""

	var depth := 0
	var in_string := false
	var escaped := false
	for index in range(start, text.length()):
		var character := text[index]
		if in_string:
			if escaped:
				escaped = false
			elif character == "\\":
				escaped = true
			elif character == '"':
				in_string = false
			continue
		if character == '"':
			in_string = true
			continue
		if character == opening:
			depth += 1
		elif character == closing:
			depth -= 1
			if depth == 0:
				return text.substr(start, index - start + 1)
	return ""


func _repair_common_json(text: String) -> String:
	var repaired := text
	repaired = repaired.replace("“", '"').replace("”", '"').replace("‘", "'").replace("’", "'")
	var trailing_comma_regex := RegEx.new()
	if trailing_comma_regex.compile(",\\s*([}\\]])") == OK:
		repaired = trailing_comma_regex.sub(repaired, "$1", true)
	return repaired


func _start_json_repair(malformed_content: String, parse_mode: String) -> bool:
	if int(_active_job.get("repair_attempts", 0)) >= 1:
		return false
	_active_job["repair_attempts"] = int(_active_job.get("repair_attempts", 0)) + 1
	var payload: Dictionary = _active_job.get("payload", {}).duplicate(true)
	payload["temperature"] = 0.0
	payload["messages"] = [
		{
			"role": "system",
			"content":
			"You are a JSON repair tool. Convert the supplied malformed or incorrectly wrapped assistant output into the requested JSON structure. Preserve the original content and values as faithfully as possible. Return JSON only with no markdown fences or commentary."
		},
		{
			"role": "user",
			"content":
			(
				"EXPECTED STRUCTURE: %s\n\nOUTPUT TO REPAIR:\n%s"
				% [_expected_shape_description(parse_mode), malformed_content]
			)
		}
	]
	_active_job["payload"] = payload
	call_deferred("_start_active_request")
	return true


func _expected_shape_description(parse_mode: String) -> String:
	match parse_mode:
		"field":
			return 'a JSON object in the exact shape {"value": <value>}'
		"ideas":
			return "a JSON array of character-idea objects, or an object with an ideas array"
		_:
			return "one JSON object"


func _normalise_ideas(raw_ideas: Array) -> Array:
	var ideas: Array = []
	for raw_idea in raw_ideas:
		if not raw_idea is Dictionary:
			continue
		var concept := str(raw_idea.get("concept", "")).strip_edges()
		if concept.is_empty():
			continue
		var tags: Array[String] = []
		var raw_tags = raw_idea.get("tags", [])
		if raw_tags is Array:
			for raw_tag in raw_tags:
				var clean_tag := str(raw_tag).strip_edges()
				if not clean_tag.is_empty() and not tags.has(clean_tag):
					tags.append(clean_tag)
		elif not str(raw_tags).strip_edges().is_empty():
			for raw_tag in str(raw_tags).split(",", false):
				var clean_tag := raw_tag.strip_edges()
				if not clean_tag.is_empty() and not tags.has(clean_tag):
					tags.append(clean_tag)
		ideas.append(
			{
				"title": str(raw_idea.get("title", "Untitled idea")).strip_edges(),
				"concept": concept,
				"tags": tags
			}
		)
	return ideas


func _workspace_attachment_context_text(project: Dictionary) -> String:
	var limit := int(
		project.get(
			"attachment_context_character_limit",
			CCFAttachmentService.DEFAULT_CONTEXT_CHARACTER_LIMIT
		)
	)
	var report := CCFAttachmentService.context_report_for_workspace(project, limit)
	return str(report.get("text", ""))


func _project_attachment_context_text(
	project: Dictionary, character_ids: Array[String]
) -> String:
	var limit := int(
		project.get(
			"attachment_context_character_limit",
			CCFAttachmentService.DEFAULT_CONTEXT_CHARACTER_LIMIT
		)
	)
	var report := CCFAttachmentService.context_report_for_characters(
		project, character_ids, limit
	)
	return str(report.get("text", ""))


func _builder_state_context(builder_state: Dictionary) -> String:
	var lines: Array[String] = []
	for section_key in ["foundation", "personality", "background", "scene"]:
		var section_value = builder_state.get(section_key, {})
		if not section_value is Dictionary:
			continue
		for field_key in section_value:
			var value_text := _value_to_text(section_value.get(field_key)).strip_edges()
			if not value_text.is_empty():
				lines.append("%s.%s: %s" % [section_key, str(field_key), value_text])
	return _join_values(lines, "\n")


func _builder_type_instruction(field_type: String) -> String:
	if field_type == "tags":
		return "JSON array of short strings"
	if field_type == "multiline":
		return "detailed text"
	return "short text"


func _extract_content(response: Dictionary) -> String:
	var choices = response.get("choices", [])
	if choices is Array and not choices.is_empty() and choices[0] is Dictionary:
		var first_choice: Dictionary = choices[0]
		var message = first_choice.get("message", {})
		if message is Dictionary:
			var content = message.get("content", "")
			if content is String:
				return content
			if content is Array:
				var parts: Array[String] = []
				for item in content:
					if item is Dictionary and str(item.get("type", "")) == "text":
						parts.append(str(item.get("text", "")))
				return _join_values(parts, "\n")
		if first_choice.has("text"):
			return str(first_choice.get("text", ""))
	return ""


func _extract_json_value(text: String) -> Variant:
	var cleaned := text.strip_edges()
	if cleaned.begins_with("```"):
		var first_newline := cleaned.find("\n")
		if first_newline >= 0:
			cleaned = cleaned.substr(first_newline + 1)
		if cleaned.ends_with("```"):
			cleaned = cleaned.substr(0, cleaned.length() - 3).strip_edges()

	var direct = JSON.parse_string(cleaned)
	if direct != null:
		return direct

	var object_start := cleaned.find("{")
	var array_start := cleaned.find("[")
	var start := -1
	var closing := ""
	if object_start >= 0 and (array_start < 0 or object_start < array_start):
		start = object_start
		closing = "}"
	elif array_start >= 0:
		start = array_start
		closing = "]"
	if start < 0:
		return null

	var finish := cleaned.rfind(closing)
	if finish <= start:
		return null
	return JSON.parse_string(cleaned.substr(start, finish - start + 1))


func _extract_error_detail(parsed_response: Variant, fallback: String) -> String:
	if parsed_response is Dictionary and parsed_response.has("error"):
		var api_error = parsed_response.get("error")
		if api_error is Dictionary:
			return str(api_error.get("message", fallback))
		return str(api_error)
	return fallback


func _request_headers(profile: Dictionary) -> PackedStringArray:
	var headers := PackedStringArray(["Content-Type: application/json"])
	var api_key := str(profile.get("api_key", "")).strip_edges()
	if not api_key.is_empty():
		headers.append("Authorization: Bearer %s" % api_key)
	return headers


func _completion_url(base_url: String) -> String:
	var url := base_url.strip_edges().trim_suffix("/")
	if url.ends_with("/chat/completions"):
		return url
	return url + "/chat/completions"


func _emit_queue_changed() -> void:
	queue_changed.emit(
		_queue.size(), str(_active_job.get("id", "")), str(_active_job.get("label", ""))
	)


func _shared_context_text(project: Dictionary) -> String:
	var raw_context = project.get("shared_context", {})
	if not raw_context is Dictionary:
		return ""
	var lines: Array[String] = []
	for field_id in ["title", "premise", "setting", "situation", "shared_rules"]:
		var value := str(raw_context.get(field_id, "")).strip_edges()
		if value.is_empty():
			continue
		lines.append("%s: %s" % [field_id.replace("_", " ").capitalize(), value])
	return _join_values(lines, "\n")


func _series_context_text(project: Dictionary) -> String:
	return CCFSeriesService.generation_context_for_project(project)


func _relationship_context_text(project: Dictionary) -> String:
	return CCFRelationshipService.context_for_character(
		project, str(project.get("character_id", ""))
	)


func _field_type_instruction(field: Dictionary) -> String:
	var field_type := str(field.get("type", "multiline"))
	match field_type:
		"tags":
			return "array of short strings"
		"number":
			return "number between %s and %s" % [field.get("minimum", 0), field.get("maximum", 100)]
		"checkbox":
			return "boolean true/false"
		"select":
			return "one of: %s" % _join_values(field.get("options", []), ", ")
		"line":
			return "short text"
		_:
			return "multiline text"


func _value_to_text(value: Variant) -> String:
	if value is Array:
		return _join_values(value, ", ")
	return str(value)


func _join_values(values: Array, separator: String) -> String:
	var result := ""
	for index in range(values.size()):
		if index > 0:
			result += separator
		result += str(values[index])
	return result
