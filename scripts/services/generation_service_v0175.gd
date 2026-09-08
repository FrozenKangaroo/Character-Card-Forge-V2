class_name CCFGenerationServiceV0175
extends "res://scripts/services/generation_service_v0174.gd"


func queue_front_porch_fields_v0172(
	project: Dictionary,
	fields: Array[Dictionary],
	profile: Dictionary,
	retry_count: int,
	scope_label: String,
	extra_metadata: Dictionary = {}
) -> Dictionary:
	return super.queue_front_porch_fields_v0172(
		project,
		_prepare_front_porch_fields_v0175(fields),
		profile,
		retry_count,
		scope_label,
		extra_metadata
	)


func _prepare_front_porch_fields_v0175(
	fields: Array[Dictionary]
) -> Array[Dictionary]:
	var prepared: Array[Dictionary] = []
	for raw_field in fields:
		var field := raw_field.duplicate(true)
		var field_id := str(field.get("id", ""))
		var guidance := str(field.get("generation_prompt", "")).strip_edges()
		match field_id:
			"fp_work_days":
				guidance = _append_front_porch_guidance_v0175(
					guidance,
					"Return a JSON array of unique integers only. Monday is 1 and Sunday is 7. "
					+ "Choose days consistent with the occupation and work brief; if canon gives no schedule, use [1, 2, 3, 4, 5]."
				)
			"fp_birthday":
				guidance = _append_front_porch_guidance_v0175(
					guidance,
					"Return one concrete Gregorian date string in exact YYYY-MM-DD form. "
					+ "It must be a real date and must not be February 29. Treat it as a reviewable suggestion and do not return an age, prose, null, or an empty value."
				)
		if fields.size() == 1:
			guidance = _append_front_porch_guidance_v0175(
				guidance,
				"This is an explicit one-field AI Suggest request. Return the requested key even when canon is sparse. "
				+ "If the field already has a value, propose a reasonable alternative rather than merely copying it."
			)
		if not guidance.is_empty():
			field["generation_prompt"] = guidance
		prepared.append(field)
	return prepared


func _front_porch_type_instruction_v0172(field: Dictionary) -> String:
	match str(field.get("id", "")):
		"fp_work_days":
			return "JSON array of unique whole-number weekday IDs from 1 (Monday) through 7 (Sunday)"
		"fp_birthday":
			return "one non-empty YYYY-MM-DD date string; a real calendar date other than February 29"
	return super._front_porch_type_instruction_v0172(field)


func _append_front_porch_guidance_v0175(
	existing: String, addition: String
) -> String:
	if existing.is_empty():
		return addition
	return existing + " " + addition
