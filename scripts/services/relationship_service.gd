class_name CCFRelationshipService
extends RefCounted


static func pair_key(character_a_id: String, character_b_id: String) -> String:
	var first_id := character_a_id.strip_edges()
	var second_id := character_b_id.strip_edges()
	if first_id.naturalnocasecmp_to(second_id) > 0:
		var swap_id := first_id
		first_id = second_id
		second_id = swap_id
	return "%s::%s" % [first_id, second_id]


static func new_relationship(character_a_id: String, character_b_id: String) -> Dictionary:
	var first_id := character_a_id.strip_edges()
	var second_id := character_b_id.strip_edges()
	if first_id.naturalnocasecmp_to(second_id) > 0:
		var swap_id := first_id
		first_id = second_id
		second_id = swap_id
	return {
		"relationship_id": pair_key(first_id, second_id),
		"character_a_id": first_id,
		"character_b_id": second_id,
		"label": "",
		"status": "",
		"summary": "",
		"a_to_b": "",
		"b_to_a": "",
		"dynamic": "",
		"notes": "",
		"tags": [],
		"intensity": 50,
		"updated_at": Time.get_datetime_string_from_system(true)
	}


static func normalise_relationship(raw_relationship: Dictionary) -> Dictionary:
	var first_id := str(raw_relationship.get("character_a_id", "")).strip_edges()
	var second_id := str(raw_relationship.get("character_b_id", "")).strip_edges()
	if first_id.is_empty() or second_id.is_empty() or first_id == second_id:
		return {}
	var relationship := new_relationship(first_id, second_id)
	var original_first_id := first_id
	if first_id.naturalnocasecmp_to(second_id) > 0:
		var swap_id := first_id
		first_id = second_id
		second_id = swap_id
	var swapped := original_first_id != first_id
	relationship["character_a_id"] = first_id
	relationship["character_b_id"] = second_id
	relationship["relationship_id"] = pair_key(first_id, second_id)
	for field_id in ["label", "status", "summary", "dynamic", "notes"]:
		relationship[field_id] = str(raw_relationship.get(field_id, ""))
	var raw_a_to_b := str(raw_relationship.get("a_to_b", ""))
	var raw_b_to_a := str(raw_relationship.get("b_to_a", ""))
	relationship["a_to_b"] = raw_b_to_a if swapped else raw_a_to_b
	relationship["b_to_a"] = raw_a_to_b if swapped else raw_b_to_a
	var tags: Array[String] = []
	var raw_tags = raw_relationship.get("tags", [])
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
	relationship["tags"] = tags
	relationship["intensity"] = clampi(int(raw_relationship.get("intensity", 50)), 0, 100)
	relationship["updated_at"] = str(
		raw_relationship.get("updated_at", Time.get_datetime_string_from_system(true))
	)
	return relationship


static func normalise_relationships(project: Dictionary) -> Array[Dictionary]:
	var valid_ids: Dictionary = {}
	for summary in CCFStorageService.project_character_summaries(project):
		valid_ids[str(summary.get("character_id", ""))] = true
	var by_pair: Dictionary = {}
	var raw_relationships = project.get("relationships", [])
	if not raw_relationships is Array:
		return []
	for raw_relationship in raw_relationships:
		if not raw_relationship is Dictionary:
			continue
		var relationship := normalise_relationship(raw_relationship)
		if relationship.is_empty():
			continue
		var first_id := str(relationship.get("character_a_id", ""))
		var second_id := str(relationship.get("character_b_id", ""))
		if not valid_ids.has(first_id) or not valid_ids.has(second_id):
			continue
		by_pair[pair_key(first_id, second_id)] = relationship
	var result: Array[Dictionary] = []
	for relationship in by_pair.values():
		if relationship is Dictionary:
			result.append(relationship)
	result.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return str(first.get("relationship_id", "")) < str(second.get("relationship_id", ""))
	)
	return result


static func get_relationship(
	project: Dictionary, character_a_id: String, character_b_id: String
) -> Dictionary:
	var requested_key := pair_key(character_a_id, character_b_id)
	for relationship in normalise_relationships(project):
		if str(relationship.get("relationship_id", "")) == requested_key:
			return relationship.duplicate(true)
	return {}


static func character_name(project: Dictionary, character_id: String) -> String:
	var character := CCFStorageService.get_character(project, character_id)
	if not character.is_empty():
		return CCFStorageService.character_display_name(character)
	var summaries = project.get("project_characters", [])
	if summaries is Array:
		for summary in summaries:
			if summary is Dictionary and str(summary.get("character_id", "")) == character_id:
				return str(summary.get("name", "Untitled Character"))
	return "Unknown Character"


static func context_for_character(project: Dictionary, character_id: String) -> String:
	var focus_id := character_id.strip_edges()
	if focus_id.is_empty():
		return ""
	var lines: Array[String] = []
	var raw_relationships = project.get("relationships", [])
	if not raw_relationships is Array:
		return ""
	for raw_relationship in raw_relationships:
		if not raw_relationship is Dictionary:
			continue
		var relationship := normalise_relationship(raw_relationship)
		if relationship.is_empty():
			continue
		var first_id := str(relationship.get("character_a_id", ""))
		var second_id := str(relationship.get("character_b_id", ""))
		if focus_id != first_id and focus_id != second_id:
			continue
		var other_id := second_id if focus_id == first_id else first_id
		var other_name := character_name(project, other_id)
		var header := "Relationship with %s" % other_name
		var label := str(relationship.get("label", "")).strip_edges()
		var status := str(relationship.get("status", "")).strip_edges()
		if not label.is_empty():
			header += " — %s" % label
		if not status.is_empty():
			header += " (%s)" % status
		var detail_parts: Array[String] = [header]
		var summary := str(relationship.get("summary", "")).strip_edges()
		if not summary.is_empty():
			detail_parts.append("Summary: %s" % summary)
		var directional := str(
			relationship.get("a_to_b", "")
			if focus_id == first_id
			else relationship.get("b_to_a", "")
		).strip_edges()
		if not directional.is_empty():
			detail_parts.append("This character toward %s: %s" % [other_name, directional])
		var reverse_direction := str(
			relationship.get("b_to_a", "")
			if focus_id == first_id
			else relationship.get("a_to_b", "")
		).strip_edges()
		if not reverse_direction.is_empty():
			detail_parts.append("%s toward this character: %s" % [other_name, reverse_direction])
		var dynamic := str(relationship.get("dynamic", "")).strip_edges()
		if not dynamic.is_empty():
			detail_parts.append("Dynamic: %s" % dynamic)
		var tags = relationship.get("tags", [])
		if tags is Array and not tags.is_empty():
			detail_parts.append("Tags: %s" % _join_values(tags, ", "))
		lines.append(_join_values(detail_parts, "\n"))
	return _join_values(lines, "\n\n")


static func context_for_characters(project: Dictionary, character_ids: Array[String]) -> String:
	var selected: Dictionary = {}
	for character_id in character_ids:
		selected[character_id] = true
	var lines: Array[String] = []
	var raw_relationships = project.get("relationships", [])
	if not raw_relationships is Array:
		return ""
	for raw_relationship in raw_relationships:
		if not raw_relationship is Dictionary:
			continue
		var relationship := normalise_relationship(raw_relationship)
		if relationship.is_empty():
			continue
		var first_id := str(relationship.get("character_a_id", ""))
		var second_id := str(relationship.get("character_b_id", ""))
		if not selected.is_empty() and (not selected.has(first_id) or not selected.has(second_id)):
			continue
		var first_name := character_name(project, first_id)
		var second_name := character_name(project, second_id)
		var parts: Array[String] = ["%s ↔ %s" % [first_name, second_name]]
		for field_id in ["label", "status", "summary", "dynamic"]:
			var value := str(relationship.get(field_id, "")).strip_edges()
			if not value.is_empty():
				parts.append("%s: %s" % [field_id.capitalize(), value])
		var first_direction := str(relationship.get("a_to_b", "")).strip_edges()
		if not first_direction.is_empty():
			parts.append("%s → %s: %s" % [first_name, second_name, first_direction])
		var second_direction := str(relationship.get("b_to_a", "")).strip_edges()
		if not second_direction.is_empty():
			parts.append("%s → %s: %s" % [second_name, first_name, second_direction])
		lines.append(_join_values(parts, "\n"))
	return _join_values(lines, "\n\n")


static func has_meaningful_content(relationship: Dictionary) -> bool:
	for field_id in ["label", "status", "summary", "a_to_b", "b_to_a", "dynamic", "notes"]:
		if not str(relationship.get(field_id, "")).strip_edges().is_empty():
			return true
	var tags = relationship.get("tags", [])
	return tags is Array and not tags.is_empty()


static func _join_values(values: Array, separator: String) -> String:
	var result := ""
	for index in range(values.size()):
		if index > 0:
			result += separator
		result += str(values[index])
	return result
