class_name CCFGenerationServiceV01512
extends "res://scripts/services/generation_service_v0159.gd"


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

	# Full synthesis deliberately reads every field exposed by the active template,
	# including populated non-generation fields. Existing Workspace data is source
	# material and canon, not a reason to skip generation.
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
	for field in output_fields:
		var field_id := str(field.get("id", "field"))
		var label := str(field.get("label", field_id))
		var required_note := "required" if bool(field.get("required", false)) else "optional"
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

	var prompt := """Synthesize a complete, coherent roleplay character from ALL of the supplied Workspace material.

IMPORTANT GENERATION CONTRACT:
- Treat populated Workspace fields as authoritative source material and established character facts, not as fields to skip.
- Preserve established facts by default. Deepen, reconcile, polish, and format them rather than silently replacing them.
- Use information from different fields together so personality, scenario, greeting, dialogue, history, and other outputs describe one consistent character.
- The active template below is the OUTPUT CONTRACT. Return the requested keys even when their source fields were already populated.
- Do not omit an output merely because the Workspace already contains a value for it.
- Do not invent contradictory premise changes just to make the output different from the source.

COMPLETE WORKSPACE SOURCE MATERIAL:
%s

ACTIVE TEMPLATE OUTPUT FIELDS:
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
		prompt += "\n\nReturn one JSON object using only the requested template keys. Do not add commentary or markdown fences."
	else:
		prompt += "\n\nReturn one JSON object containing every requested template key. Concise useful extras are allowed only when the template policy permits them."
	prompt += "\nUse JSON booleans for checkbox fields, JSON numbers for number fields, and arrays of strings for tags. Return valid JSON only."

	var system_text := "You are Character Card Forge, an expert character-card synthesis editor. Your job is to materialise the author's existing character material into the active template without discarding established canon."
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
			"preserve_existing_facts": true
		},
		retry_count
	)
