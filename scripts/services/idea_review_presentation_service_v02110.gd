class_name CCFIdeaReviewPresentationServiceV02110
extends RefCounted

const ORDERED_FIELDS := [
	["concept", "Concept"],
	["character_name", "Character Name"],
	["character_role", "Character Role"],
	["source_anchor", "Source Anchor"],
	["roleplay_hook", "Roleplay Hook"],
	["tags", "Tags"]
]


static func detail_sections(record: Dictionary) -> Array[Dictionary]:
	var idea_value: Variant = record.get("idea", {})
	if not idea_value is Dictionary:
		return []
	var idea: Dictionary = idea_value
	var result: Array[Dictionary] = []
	var included: Dictionary = {"title": true}
	for field_value in ORDERED_FIELDS:
		var field: Array = field_value
		var key := str(field[0])
		included[key] = true
		_append_section(result, key, str(field[1]), idea.get(key, null))

	var extra_keys: Array[String] = []
	for key_value in idea.keys():
		var key := str(key_value)
		if included.has(key) or key.begins_with("_"):
			continue
		extra_keys.append(key)
	extra_keys.sort()
	for key in extra_keys:
		_append_section(
			result,
			key,
			key.replace("_", " ").capitalize(),
			idea.get(key, null)
		)
	return result


static func _append_section(
	result: Array[Dictionary], key: String, label: String, value: Variant
) -> void:
	var text := _display_text(value).strip_edges()
	if text.is_empty():
		return
	result.append({
		"key": key,
		"label": label,
		"text": text,
		"prominent": key == "concept"
	})


static func _display_text(value: Variant) -> String:
	if value == null:
		return ""
	if value is String or value is StringName:
		return str(value)
	if value is Array:
		var parts: Array[String] = []
		for item in value as Array:
			var item_text := _display_text(item).strip_edges()
			if not item_text.is_empty():
				parts.append(item_text)
		return ", ".join(parts)
	if value is Dictionary:
		return JSON.stringify(value, "  ") if not (value as Dictionary).is_empty() else ""
	if value is bool:
		return "Yes" if bool(value) else "No"
	return str(value)
