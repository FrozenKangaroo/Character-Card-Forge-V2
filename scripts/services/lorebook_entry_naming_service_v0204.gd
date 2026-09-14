class_name CCFLorebookEntryNamingServiceV0204
extends RefCounted


static func normalise_book_names(
	raw_book: Dictionary, planned_names: Array[String] = []
) -> Dictionary:
	var book := raw_book.duplicate(true)
	var entries_value: Variant = book.get("entries", [])
	if not entries_value is Array:
		book["entries"] = []
		return book
	var entries: Array = []
	var use_planned_order := planned_names.size() == (entries_value as Array).size()
	for index in range((entries_value as Array).size()):
		var raw_entry: Variant = (entries_value as Array)[index]
		if not raw_entry is Dictionary:
			continue
		var entry := (raw_entry as Dictionary).duplicate(true)
		var planned_name := planned_names[index] if use_planned_order else ""
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
	var result: Array[String] = []
	var in_lorebook := false
	var numbered_entry := RegEx.new()
	if numbered_entry.compile("^\\s*\\d+[.)]\\s+(.+)$") != OK:
		return result
	for raw_line in blueprint.split("\n"):
		var line := str(raw_line).strip_edges()
		var heading := line.trim_prefix("#").strip_edges().trim_suffix(":")
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
		if keyword_index >= 0:
			title = title.left(keyword_index).strip_edges()
		var note_index := title.find(" - ")
		if note_index >= 0:
			title = title.left(note_index).strip_edges()
		if not title.is_empty() and not _is_warning_title(title):
			result.append(title)
	return result


static func _is_section_heading(line: String) -> bool:
	var clean := line.trim_prefix("#").strip_edges().trim_suffix(":")
	if clean.is_empty() or clean.begins_with("-") or clean[0].is_valid_int():
		return false
	return clean == clean.to_upper()


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
