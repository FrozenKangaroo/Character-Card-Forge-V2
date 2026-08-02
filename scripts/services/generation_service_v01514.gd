class_name CCFGenerationServiceV01514
extends "res://scripts/services/generation_service_v01513.gd"


func queue_full_character_synthesis(
	project: Dictionary,
	template: Dictionary,
	profile: Dictionary,
	retry_count: int
) -> Dictionary:
	var plan := _full_synthesis_plan_v01514(template)
	var output_fields: Array = plan.get("output_fields", [])
	var component_blocks: Array[String] = plan.get("component_blocks", [])
	var enabled_group_ids: Array[String] = plan.get("enabled_group_ids", [])
	var disabled_group_ids: Array[String] = plan.get("disabled_group_ids", [])
	if output_fields.is_empty():
		return {"ok": false, "error": "The active template has no enabled AI generation outputs."}

	var source_lines: Array[String] = []
	var concept := str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()
	if not concept.is_empty():
		source_lines.append("Generation Concept:\n%s" % concept)

	# The entire populated Workspace is source material. Generation Components
	# decide how that source is transformed; source fields are not isolated silos.
	for raw_section in template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		var section_title := str(section.get("title", section.get("id", "Section")))
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
			source_lines.append("[%s / %s]\n%s" % [section_title, label, rendered])

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
		var line := "- %s: %s (%s; REQUIRED in this synthesis response)" % [field_id, label, _field_type_instruction(field)]
		var custom_instruction := str(field.get("generation_prompt", "")).strip_edges()
		if not custom_instruction.is_empty():
			line += "\n  Field instruction: %s" % custom_instruction
		field_ids.append(field_id)
		field_lines.append(line)

	var global_rules: Array[String] = []
	for rule in template.get("global_generation_instructions", []):
		var rule_text := str(rule).strip_edges()
		if not rule_text.is_empty():
			global_rules.append(rule_text)

	var component_plan_text := "No generation groups are defined; use each field's generation instruction directly."
	if not component_blocks.is_empty():
		component_plan_text = _join_values(component_blocks, "\n\n")

	var prompt := """Synthesize the COMPLETE final roleplay character from ALL supplied Workspace material.

AUTHORITATIVE PIPELINE:
1. COMPLETE WORKSPACE SOURCE MATERIAL is the shared fact pool. Information may originate in any populated field; do not assume it belongs only to the field it currently sits in.
2. GENERATION COMPONENT PLAN is the transformation recipe. For every enabled generation group, follow its enabled components in order and use their instructions to decide what belongs in that group's output field.
3. ACTIVE TEMPLATE OUTPUT FIELDS are the destinations/final JSON contract.
4. Disabled generation groups and disabled components MUST NOT contribute generated material. Do not silently reintroduce a disabled component just because related source text exists elsewhere.
5. For grouped outputs, component instructions take precedence over merely paraphrasing the current destination field. Gather relevant facts from the ENTIRE Workspace, reconcile them, then materialise the field according to the enabled component recipe.
6. For ungrouped outputs, follow the field-specific generation instruction and use all relevant Workspace facts.
7. Preserve established canon: names, relationships, chronology, setting, boundaries, explicit traits, scenario beats and author intent. Reorganise and deepen facts; do not invent contradictory premise changes.
8. Return EVERY output key listed below exactly once. Produce final-form card text, not notes about how you would generate it.
9. Make all outputs mutually consistent. Scenario and greeting must describe the same playable opening; personality and dialogue must agree; Description must obey its component boundaries.

COMPLETE WORKSPACE SOURCE MATERIAL:
%s

GENERATION COMPONENT PLAN:
%s

ACTIVE TEMPLATE OUTPUT FIELDS — EVERY KEY BELOW MUST BE RETURNED:
%s""" % [
		_join_values(source_lines, "\n\n"),
		component_plan_text,
		_join_values(field_lines, "\n")
	]

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
		prompt += "\n\nReturn one JSON object using only the requested output keys. Do not add commentary or markdown fences."
	else:
		prompt += "\n\nReturn one JSON object containing every requested output key. Extras are allowed only when the template policy permits them."
	prompt += "\nUse JSON booleans for checkbox fields, JSON numbers for number fields, and arrays of strings for tags. Return valid JSON only. Before answering, verify every requested key is present."

	var system_text := "You are Character Card Forge's component-driven character synthesis editor. Treat the Workspace as source facts, enabled Generation Components as the transformation recipe, and template fields as final destinations. Never flatten component-driven generation into independent field paraphrasing."
	if not global_rules.is_empty():
		system_text += " " + _join_values(global_rules, " ")

	return _queue_chat_job(
		"character",
		"Component-driven full character synthesis",
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
			"generation_scope": "component_driven_full_workspace_synthesis",
			"preserve_existing_facts": true,
			"require_all_output_fields": true,
			"preview_include_unchanged": true,
			"generation_components_authoritative": true,
			"enabled_generation_group_ids": enabled_group_ids,
			"disabled_generation_group_ids": disabled_group_ids
		},
		retry_count
	)


func _full_synthesis_plan_v01514(template: Dictionary) -> Dictionary:
	var all_fields := CCFTemplateService.generation_fields(template)
	var groups := CCFTemplateService.generation_groups(template)
	if groups.is_empty():
		return {
			"output_fields": all_fields,
			"component_blocks": [],
			"enabled_group_ids": [],
			"disabled_group_ids": []
		}

	var grouped_field_ids: Dictionary = {}
	var enabled_group_field_ids: Dictionary = {}
	var component_blocks: Array[String] = []
	var enabled_group_ids: Array[String] = []
	var disabled_group_ids: Array[String] = []

	for raw_group in groups:
		if not raw_group is Dictionary:
			continue
		var group: Dictionary = raw_group
		var group_id := str(group.get("id", "generation_group")).strip_edges()
		var output_field_id := str(group.get("output_field_id", "")).strip_edges()
		if output_field_id.is_empty():
			continue
		grouped_field_ids[output_field_id] = true
		if not bool(group.get("enabled", true)):
			disabled_group_ids.append(group_id)
			continue

		var enabled_components: Array = []
		var components_value: Variant = group.get("components", [])
		if components_value is Array:
			for raw_component in components_value:
				if raw_component is Dictionary and bool(raw_component.get("enabled", true)):
					enabled_components.append(raw_component)
		# A group with every component disabled is intentionally inactive.
		if enabled_components.is_empty():
			disabled_group_ids.append(group_id)
			continue

		enabled_group_ids.append(group_id)
		enabled_group_field_ids[output_field_id] = true
		var output_field := CCFTemplateService.field_by_id(template, output_field_id)
		var output_label := str(output_field.get("label", output_field_id))
		var group_lines: Array[String] = []
		group_lines.append("GROUP: %s → output key '%s' (%s)" % [str(group.get("title", group_id)), output_field_id, output_label])
		group_lines.append("Enabled components, in author-defined order:")
		for raw_component in enabled_components:
			var component: Dictionary = raw_component
			var requirement := "required" if bool(component.get("required", true)) else "optional when relevant"
			var instruction := str(component.get("instruction", "")).strip_edges()
			if instruction.is_empty():
				instruction = "Use the component label as the requested content category."
			group_lines.append("- %s [%s]: %s" % [str(component.get("label", component.get("id", "Component"))), requirement, instruction])
		group_lines.append("Compose ONE coherent final '%s' value from these enabled components. Do not output component subkeys." % output_field_id)
		component_blocks.append(_join_values(group_lines, "\n"))

	var output_fields: Array = []
	for raw_field in all_fields:
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_id := str(field.get("id", "")).strip_edges()
		if grouped_field_ids.has(field_id):
			if enabled_group_field_ids.has(field_id):
				output_fields.append(field)
			continue
		output_fields.append(field)

	return {
		"output_fields": output_fields,
		"component_blocks": component_blocks,
		"enabled_group_ids": enabled_group_ids,
		"disabled_group_ids": disabled_group_ids
	}
