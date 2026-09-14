class_name CCFLorebookEntryNamingServiceV0204
extends RefCounted


static func normalise_book_names(
	raw_book: Dictionary,
	planned_entries: Array[Dictionary] = [],
	prefer_planned_names: bool = false
) -> Dictionary:
	var book := raw_book.duplicate(true)
	var entries_value: Variant = book.get("entries", [])
	if not entries_value is Array:
		book["entries"] = []
		return book
	var entries: Array = []
	var claimed_plans: Array[bool] = []
	claimed_plans.resize(planned_entries.size())
	claimed_plans.fill(false)
	for index in range((entries_value as Array).size()):
		var raw_entry: Variant = (entries_value as Array)[index]
		if not raw_entry is Dictionary:
			continue
		var entry := (raw_entry as Dictionary).duplicate(true)
		var plan_index := _matching_plan_index(
			entry, planned_entries, claimed_plans
		)
		var planned_name := ""
		if plan_index >= 0:
			claimed_plans[plan_index] = true
			planned_name = str(planned_entries[plan_index].get("name", ""))
		if prefer_planned_names and not planned_name.is_empty():
			entry["name"] = planned_name
		else:
			entry["name"] = entry_name(entry, index, planned_name)
		entries.append(entry)
	book["entries"] = entries
	return book


static func entry_name(
	raw_entry: Dictionary, index: int, planned_name: String = ""
) -> String:
	var existing := str(raw_entry.get("name", "")).strip_edges()
	var comment := str(raw_entry.get("comment", "")).strip_edges()
	if not existing.is_empty() and not _is_warning_title(existing):
		return existing
	var planned := planned_name.strip_edges()
	if not planned.is_empty() and not _is_warning_title(planned):
		return planned
	if _is_title_like_comment(comment):
		return comment
	var primary := _first_usable_key(raw_entry.get("keys", []))
	if not primary.is_empty():
		return _title_from_key(primary)
	var secondary := _first_usable_key(raw_entry.get("secondary_keys", []))
	if not secondary.is_empty():
		return _title_from_key(secondary)
	if not existing.is_empty():
		return existing
	return "Lore Entry %d" % (index + 1)


static func planned_names_from_blueprint(blueprint: String) -> Array[String]:
	var names: Array[String] = []
	for entry in planned_entries_from_blueprint(blueprint):
		names.append(str(entry.get("name", "")))
	return names


static func planned_entries_from_blueprint(
	blueprint: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var in_lorebook := false
	var numbered_entry := RegEx.new()
	if numbered_entry.compile("^\\s*\\d+[.)]\\s+(.+)$") != OK:
		return result
	for raw_line in blueprint.split("\n"):
		var line := str(raw_line).strip_edges()
		var heading := _heading_text(line)
		if not in_lorebook:
			if heading.to_upper() == "LOREBOOK":
				in_lorebook = true
			continue
		var entry_match := numbered_entry.search(line)
		if entry_match == null:
			if _is_section_heading(line):
				break
			continue
		var title := entry_match.get_string(1).strip_edges().replace("**", "")
		var keyword_index := title.to_lower().find(" (keyword")
		var keywords: Array[String] = []
		if keyword_index >= 0:
			var keyword_section := title.substr(keyword_index)
			title = title.left(keyword_index).strip_edges()
			var colon_index := keyword_section.find(":")
			var closing_index := keyword_section.find(")", colon_index + 1)
			if colon_index >= 0:
				var keyword_text := keyword_section.substr(colon_index + 1)
				if closing_index > colon_index:
					keyword_text = keyword_section.substr(
						colon_index + 1, closing_index - colon_index - 1
					)
				for keyword_value in keyword_text.split(",", false):
					var keyword := str(keyword_value).strip_edges()
					if not keyword.is_empty():
						keywords.append(keyword)
		var note_index := title.find(" - ")
		if note_index >= 0:
			title = title.left(note_index).strip_edges()
		if not title.is_empty() and not _is_warning_title(title):
			result.append({"name": title, "keys": keywords})
	return result


static func _is_section_heading(line: String) -> bool:
	var clean := _heading_text(line)
	if clean.is_empty() or clean.begins_with("-") or clean[0].is_valid_int():
		return false
	return clean == clean.to_upper()


static func _heading_text(line: String) -> String:
	var clean := line.strip_edges()
	while clean.begins_with("#"):
		clean = clean.substr(1).strip_edges()
	return clean.trim_suffix(":").strip_edges()


static func _matching_plan_index(
	entry: Dictionary,
	planned_entries: Array[Dictionary],
	claimed_plans: Array[bool]
) -> int:
	var best_index := -1
	var best_score := 0
	var tied := false
	for plan_index in range(planned_entries.size()):
		if claimed_plans[plan_index]:
			continue
		var score := _identity_score(entry, planned_entries[plan_index])
		if score > best_score:
			best_score = score
			best_index = plan_index
			tied = false
		elif score > 0 and score == best_score:
			tied = true
	return -1 if best_score <= 0 or tied else best_index


static func _identity_score(entry: Dictionary, planned_entry: Dictionary) -> int:
	var planned_name := _normalise_identity(planned_entry.get("name", ""))
	var existing_name := _normalise_identity(entry.get("name", ""))
	if (
		not planned_name.is_empty()
		and existing_name == planned_name
		and not _is_warning_title(str(entry.get("name", "")))
	):
		return 1000

	var entry_terms := _identity_terms(entry)
	var planned_terms := _identity_terms(planned_entry)
	var score := 0
	for entry_term in entry_terms:
		for planned_term in planned_terms:
			if entry_term == planned_term:
				score += 12
			elif (
				entry_term.length() >= 4
				and planned_term.length() >= 4
				and (
					entry_term.contains(planned_term)
					or planned_term.contains(entry_term)
				)
			):
				score += 3

	var content := _normalise_identity(entry.get("content", ""))
	if (
		not planned_name.is_empty()
		and planned_name.length() >= 4
		and content.contains(planned_name)
	):
		score += 8
	return score


static func _identity_terms(value: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var name := _normalise_identity(value.get("name", ""))
	if not name.is_empty() and not _is_warning_title(str(value.get("name", ""))):
		result.append(name)
	for field_name in ["keys", "secondary_keys"]:
		var field_value: Variant = value.get(field_name, [])
		var values: Array = []
		if field_value is Array:
			values = (field_value as Array).duplicate()
		else:
			for raw_value in str(field_value).split(",", false):
				values.append(raw_value)
		for raw_term in values:
			var term := _normalise_identity(raw_term)
			if not term.is_empty() and not result.has(term):
				result.append(term)
	return result


static func _normalise_identity(value: Variant) -> String:
	var result := str(value).strip_edges().to_lower()
	for punctuation in ["'", "\"", ".", ",", ":", ";", "-", "_", "/", "(", ")"]:
		result = result.replace(punctuation, " ")
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result.strip_edges()


static func _is_title_like_comment(comment: String) -> bool:
	return (
		not comment.is_empty()
		and comment.length() <= 120
		and not comment.contains("\n")
		and not _is_warning_title(comment)
	)


static func _is_warning_title(value: String) -> bool:
	var lowered := value.strip_edges().to_lower()
	return (
		lowered.begins_with("content warning")
		or lowered.begins_with("trigger warning")
		or lowered.begins_with("cw:")
		or lowered.begins_with("tw:")
	)


static func _first_usable_key(value: Variant) -> String:
	var candidates: Array = []
	if value is Array:
		candidates = (value as Array).duplicate()
	else:
		for part in str(value).split(",", false):
			candidates.append(part)
	for candidate_value in candidates:
		var candidate := str(candidate_value).strip_edges()
		if not candidate.is_empty() and not _is_warning_title(candidate):
			return candidate
	return ""


static func _title_from_key(key_text: String) -> String:
	var clean := key_text.strip_edges()
	if clean.is_empty():
		return clean
	var words := clean.split(" ", false)
	var titled: Array[String] = []
	for word_value in words:
		var word := str(word_value)
		if word == word.to_lower() and not word.is_empty():
			word = word.left(1).to_upper() + word.substr(1)
		titled.append(word)
	return " ".join(titled)
