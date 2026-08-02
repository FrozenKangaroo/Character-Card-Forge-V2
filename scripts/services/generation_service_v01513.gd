class_name CCFGenerationServiceV01513
extends "res://scripts/services/generation_service_v01512.gd"


func queue_full_character_synthesis(
	project: Dictionary,
	template: Dictionary,
	profile: Dictionary,
	retry_count: int
) -> Dictionary:
	var output_fields := CCFTemplateService.generation_fields(template)
	if output_fields.is_empty():
		return {"ok": false, "error": "The active template has no AI-generatable fields."}

	var source_lines: Array[String] = []
	var concept := str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()
	if not concept.is_empty():
		source_lines.append("Generation Concept:\n%s" % concept)

	for raw_section in template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		for raw_field in section.get("fields", []):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			var field_path := str(field.get("path", "")).strip_edges()
			if field_path.is_empty() or field_path == "concept.prompt":
				continue
			var current_value: Variant = CCFStorageService.get_value_at_path(project, field_path, "")
			var rendered := _value_to_text(current_value).strip_edges()
			if rendered.is_empty():
				continue
			var label := str(field.get("label", field.get("id", field_path)))
			source_lines.append("%s:\n%s" % [label, rendered])

	var generation_value: Variant = project.get("generation", {})
	if generation_value is Dictionary:
		var generation: Dictionary = generation_value
		var mode := str(generation.get("mode", "")).strip_edges()
		var style := str(generation.get("style", "")).strip_edges()
		if not mode.is_empty():
			source_lines.append("Generation Mode: %s" % mode)
		if not style.is_empty():
			source_lines.append("Generation Style: %s" % style)

	if source_lines.is_empty():
		return {"ok": false, "error": "Add some character information to the Workspace before generating."}

	var field_lines: Array[String] = []
	var field_ids: Array[String] = []
	for raw_field in output_fields:
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_id := str(field.get("id", "field")).strip_edges()
		if field_id.is_empty():
			continue
		var label := str(field.get("label", field_id))
		var required_note := "required" if bool(field.get("required", false)) else "optional in the card schema, but REQUIRED in this synthesis response"
		var line := "- %s: %s (%s, %s)" % [field_id, label, _field_type_instruction(field), required_note]
		var custom_instruction := str(field.get("generation_prompt", "")).strip_edges()
		if not custom_instruction.is_empty():
			line += " — %s" % custom_instruction
		field_ids.append(field_id)
		field_lines.append(line)

	var global_rules: Array[String] = []
	for rule in template.get("global_generation_instructions", []):
		var rule_text := str(rule).strip_edges()
		if not rule_text.is_empty():
			global_rules.append(rule_text)

	var prompt := """Synthesize the COMPLETE final roleplay character from ALL supplied Workspace material.

FULL SYNTHESIS CONTRACT — FOLLOW EVERY RULE:
1. Populated Workspace fields are authoritative source material and established canon. Preserve their facts, relationships, boundaries, names, chronology, and intended premise.
2. You are NOT filling blanks. You are performing a complete editorial synthesis of the whole character.
3. Return EVERY key listed under ACTIVE TEMPLATE OUTPUT FIELDS exactly once, even if that field already contains source text and even if the template marks it optional.
4. For EVERY returned field, produce a finished final-form value suitable for the card. Reconcile information across fields so the result reads as one deliberately authored character.
5. Actively improve structure, prose, consistency, specificity, roleplay usefulness, and cross-field continuity where useful. Do not merely omit or echo a field because it was already populated.
6. Do not change established facts merely to make wording different. If existing wording is already strong, preserve its meaning while normalising it into the active template's finished style.
7. Personality, description, scenario, first message, example dialogue, history/advanced material and other returned fields must agree with one another.
8. No requested output key may be missing, null, or replaced by commentary. Use the correct JSON type for every field.

COMPLETE WORKSPACE SOURCE MATERIAL:
%s

ACTIVE TEMPLATE OUTPUT FIELDS — EVERY KEY BELOW MUST BE RETURNED:
%s""" % [_join_values(source_lines, "\n\n"), _join_values(field_lines, "\n")]

	var shared_context_text := _shared_context_text(project)
	if not shared_context_text.is_empty():
		prompt += "\n\nSHARED MULTI-CHARACTER PROJECT CONTEXT:\n%s" % shared_context_text
	var series_context_text := _series_context_text(project)
	if not series_context_text.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % series_context_text
	var relationship_context_text := _relationship_context_text(project)
	if not relationship_context_text.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS:\n%s" % relationship_context_text
	var attachment_context_text := _workspace_attachment_context_text(project)
	if not attachment_context_text.is_empty():
		prompt += "\n\nENABLED ATTACHMENT CONTEXT:\n%s" % attachment_context_text

	var policy := CCFTemplateService.output_policy(template)
	var policy_mode := str(policy.get("mode", "strict"))
	if policy_mode == "strict":
		prompt += "\n\nReturn one JSON object using only the requested template keys. Every requested key is mandatory for this full synthesis. Do not add commentary or markdown fences."
	else:
		prompt += "\n\nReturn one JSON object containing EVERY requested template key. Concise useful extras are allowed only when the template policy permits them."
	prompt += "\nUse JSON booleans for checkbox fields, JSON numbers for number fields, and arrays of strings for tags. Return valid JSON only. Before answering, verify that the JSON contains every requested key."

	var system_text := "You are Character Card Forge, an expert character-card synthesis editor. Materialise the author's existing character into a complete active-template card. Preserve canon while producing a finished value for every requested field; never treat populated fields as already completed work."
	if not global_rules.is_empty():
		system_text += " " + _join_values(global_rules, " ")

	return _queue_chat_job(
		"character",
		"Full character synthesis",
		profile,
		[
			{"role": "system", "content": system_text},
			{"role": "user", "content": prompt}
		],
		"object",
		{
			"field_ids": field_ids,
			"concept": concept,
			"template_id": str(template.get("template_id", "default")),
			"output_policy": policy.duplicate(true),
			"project_id": str(project.get("project_id", "")),
			"generation_scope": "full_workspace_synthesis",
			"preserve_existing_facts": true,
			"require_all_output_fields": true,
			"preview_include_unchanged": true
		},
		retry_count
	)
