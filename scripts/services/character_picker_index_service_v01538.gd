class_name CCFCharacterPickerIndexServiceV01538
extends RefCounted


static func build_index(project_rows: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for raw_project_row in project_rows:
		if not raw_project_row is Dictionary:
			continue
		var project_row: Dictionary = raw_project_row
		var project_id := str(project_row.get("project_id", "")).strip_edges()
		if project_id.is_empty():
			continue
		var project_label := str(project_row.get("name", "Untitled Project")).strip_edges()
		if project_label.is_empty():
			project_label = "Untitled Project"
		var project_tags := string_array(project_row.get("all_tags", project_row.get("tags", [])))
		var collections := string_array(project_row.get("collections", []))
		var project_search_parts: Array[String] = [
			project_label,
			str(project_row.get("summary", "")),
			str(project_row.get("series_id", "")),
			str(project_row.get("folder", "")),
			" ".join(project_tags),
			" ".join(collections)
		]
		for raw_character_row in project_row.get("characters", []):
			if not raw_character_row is Dictionary:
				continue
			var character_row: Dictionary = raw_character_row
			var character_id := str(character_row.get("character_id", "")).strip_edges()
			if character_id.is_empty():
				continue
			var character_label := str(character_row.get("name", "Untitled Character")).strip_edges()
			if character_label.is_empty():
				character_label = "Untitled Character"
			var character_tags := string_array(character_row.get("tags", []))
			var search_parts := project_search_parts.duplicate()
			search_parts.append_array([
				character_label,
				str(character_row.get("summary", "")),
				str(character_row.get("role", "")),
				str(character_row.get("creator", "")),
				str(character_row.get("character_version", "")),
				" ".join(character_tags),
				project_id,
				character_id
			])
			rows.append({
				"project_id": project_id,
				"project_name": project_label,
				"character_id": character_id,
				"character_name": character_label,
				"role": str(character_row.get("role", "")).strip_edges(),
				"tags": character_tags,
				"project_tags": project_tags,
				"series_id": str(project_row.get("series_id", "")).strip_edges(),
				"folder": str(project_row.get("folder", "")).strip_edges(),
				"collections": collections,
				"updated_at": str(project_row.get("updated_at", "")),
				"search_text": "\n".join(search_parts).to_lower()
			})
	rows.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			var first_character := str(first.get("character_name", "")).to_lower()
			var second_character := str(second.get("character_name", "")).to_lower()
			if first_character == second_character:
				return str(first.get("project_name", "")).to_lower() < str(second.get("project_name", "")).to_lower()
			return first_character < second_character
	)
	return rows


static func filter_rows(rows: Array, query: String, limit: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var terms := query.strip_edges().to_lower().split(" ", false)
	var resolved_limit := maxi(1, limit)
	for raw_row in rows:
		if not raw_row is Dictionary:
			continue
		var row: Dictionary = raw_row
		if not matches_terms(row, terms):
			continue
		result.append(row.duplicate(true))
		if result.size() >= resolved_limit:
			break
	return result


static func count_matches(rows: Array, query: String) -> int:
	var terms := query.strip_edges().to_lower().split(" ", false)
	var count := 0
	for raw_row in rows:
		if raw_row is Dictionary and matches_terms(raw_row, terms):
			count += 1
	return count


static func matches_terms(row: Dictionary, terms: PackedStringArray) -> bool:
	var haystack := str(row.get("search_text", "")).to_lower()
	for raw_term in terms:
		var term := str(raw_term).strip_edges()
		if not term.is_empty() and not haystack.contains(term):
			return false
	return true


static func string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for raw_value in value:
		var text_value := str(raw_value).strip_edges()
		if not text_value.is_empty() and text_value not in result:
			result.append(text_value)
	return result
