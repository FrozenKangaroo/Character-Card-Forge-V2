class_name CCFGenerationServiceV0172
extends "res://scripts/services/generation_service_v0167.gd"

const FRONT_PORCH_GENERATION_CONTRACT_V0172 := 1


func queue_front_porch_fields_v0172(
	project: Dictionary,
	fields: Array[Dictionary],
	profile: Dictionary,
	retry_count: int,
	scope_label: String,
	extra_metadata: Dictionary = {}
) -> Dictionary:
	if fields.is_empty():
		return {"ok": false, "error": "Select at least one AI-capable Front Porch field first."}
	var concept := str(
		CCFStorageService.get_value_at_path(project, "concept.prompt", "")
	).strip_edges()
	if concept.is_empty():
		return {"ok": false, "error": "Enter a generation concept before generating Front Porch fields."}

	var field_lines: Array[String] = []
	var field_ids: Array[String] = []
	var preview_fields: Array[Dictionary] = []
	for field in fields:
		var field_id := str(field.get("id", "")).strip_edges()
		if field_id.is_empty():
			continue
		field_ids.append(field_id)
		preview_fields.append(field.duplicate(true))
		var type_text := _front_porch_type_instruction_v0172(field)
		var field_line := "- %s: %s (%s)" % [
			field_id,
			str(field.get("label", field_id)),
			type_text
		]
		var instruction := str(field.get("generation_prompt", "")).strip_edges()
		if not instruction.is_empty():
			field_line += " — " + instruction
		field_lines.append(field_line)
	if field_ids.is_empty():
		return {"ok": false, "error": "The selected Front Porch scope has no usable fields."}

	var character_value: Variant = project.get("character", {})
	var character_context := (
		JSON.stringify(character_value, "  ")
		if character_value is Dictionary
		else "{}"
	)
	var prompt := (
		"Propose optional Front Porch starting-state and character-life fields for a roleplay character.\n\n"
		+ "CHARACTER CONCEPT:\n%s\n\n"
		+ "CURRENT CHARACTER CARD DATA:\n%s\n\n"
		+ "REQUESTED JSON FIELDS:\n%s\n\n"
		+ "Return one valid JSON object using exactly the requested field IDs as keys. "
		+ "These are proposals for a review screen; do not add commentary or markdown fences."
	) % [concept, character_context, "\n".join(field_lines)]
	var shared_context := _shared_context_text(project)
	if not shared_context.is_empty():
		prompt += "\n\nSHARED PROJECT CONTEXT:\n" + shared_context
	var series_context := _series_context_text(project)
	if not series_context.is_empty():
		prompt += "\n\nSERIES CONTINUITY:\n" + series_context
	var relationship_context := _relationship_context_text(project)
	if not relationship_context.is_empty():
		prompt += "\n\nESTABLISHED CHARACTER RELATIONSHIPS:\n" + relationship_context

	var system_text := (
		"You are Character Card Forge's Front Porch interoperability assistant. "
		+ "Create optional character-owned identity and new-conversation seed values that stay consistent with supplied canon. "
		+ "Never invent durable history, personality, actions, feelings, consent or preferences for {{user}}. "
		+ "Relationship numbers describe only an explicitly requested opening state; when evidence is absent, use neutral values. "
		+ "Do not generate stable IDs, avatar IDs, visual colour IDs or TTS provider identifiers."
	)
	var messages := [
		{"role": "system", "content": system_text},
		{"role": "user", "content": prompt}
	]
	var metadata := {
		"project_id": str(project.get("project_id", "")),
		"field_ids": field_ids,
		"preview_fields": preview_fields,
		"front_porch_scope": scope_label,
		"front_porch_generation_contract": FRONT_PORCH_GENERATION_CONTRACT_V0172,
		"output_policy": {"unexpected_fields": "ignore"}
	}
	metadata.merge(extra_metadata, true)
	return _queue_chat_job(
		"front_porch_fields",
		"Generate Front Porch — %s" % scope_label,
		profile,
		messages,
		"object",
		metadata,
		retry_count
	)


func front_porch_generation_capabilities_v0172() -> Dictionary:
	return {
		"version": "0.17.2",
		"contract_version": FRONT_PORCH_GENERATION_CONTRACT_V0172,
		"multi_field_review": true,
		"agency_contract": true,
		"stable_ids_excluded": true,
		"automatic_apply": false
	}


func _front_porch_type_instruction_v0172(field: Dictionary) -> String:
	match str(field.get("type", "line")):
		"tags":
			return "JSON array of concise strings"
		"integer_tags":
			return "JSON array of whole numbers from %d to %d" % [
				int(field.get("minimum", 1)), int(field.get("maximum", 7))
			]
		"number":
			return "whole number from %d to %d" % [
				int(field.get("minimum", -1000000)),
				int(field.get("maximum", 1000000))
			]
		"checkbox":
			return "JSON boolean"
		"select":
			return "one of: %s" % ", ".join(field.get("options", []))
		_:
			return "string"
