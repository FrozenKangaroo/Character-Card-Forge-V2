class_name CCFLorebookContextServiceV01415
extends RefCounted

const DEFAULT_TOKEN_BUDGET := 2048
const CHARS_PER_TOKEN_ESTIMATE := 4


static func activation_corpus(project: Dictionary, extra_text: String = "") -> String:
	var parts: Array[String] = []
	var concept := str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()
	if not concept.is_empty():
		parts.append(concept)
	var shared_value: Variant = project.get("shared_context", {})
	if shared_value is Dictionary:
		for field_id in ["title", "premise", "setting", "situation", "shared_rules"]:
			var value := str((shared_value as Dictionary).get(field_id, "")).strip_edges()
			if not value.is_empty():
				parts.append(value)
	var character_value: Variant = project.get("character", {})
	if character_value is Dictionary:
		for field_id in ["name", "description", "personality", "scenario", "first_message"]:
			var value := str((character_value as Dictionary).get(field_id, "")).strip_edges()
			if not value.is_empty():
				parts.append(value)
	var clean_extra := extra_text.strip_edges()
	if not clean_extra.is_empty():
		parts.append(clean_extra)
	return "\n".join(parts)


static func generation_context_for_project(project: Dictionary, extra_text: String = "") -> String:
	var corpus := activation_corpus(project, extra_text)
	var sections: Array[String] = []
	var project_book: Variant = project.get("lorebook", {})
	var project_context := _context_for_book(project_book, corpus, "Project Lorebook")
	if not project_context.is_empty():
		sections.append(project_context)
	var character_value: Variant = project.get("character", {})
	if character_value is Dictionary:
		var character_context := _context_for_book(
			(character_value as Dictionary).get("character_book", {}), corpus, "Character Lorebook"
		)
		if not character_context.is_empty():
			sections.append(character_context)
	return "\n\n".join(sections)


static func active_entries_for_book(raw_book: Variant, corpus: String) -> Array[Dictionary]:
	if not raw_book is Dictionary:
		return []
	var raw_entries: Variant = (raw_book as Dictionary).get("entries", [])
	if not raw_entries is Array:
		return []
	var active: Array[Dictionary] = []
	for index in range((raw_entries as Array).size()):
		var raw_entry: Variant = (raw_entries as Array)[index]
		if not raw_entry is Dictionary:
			continue
		var entry: Dictionary = (raw_entry as Dictionary).duplicate(true)
		if _entry_is_active(entry, corpus):
			entry["_source_index"] = index
			active.append(entry)
	active.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var priority_a := int(a.get("priority", 100))
		var priority_b := int(b.get("priority", 100))
		if priority_a != priority_b:
			return priority_a > priority_b
		return int(a.get("insertion_order", a.get("_source_index", 0))) < int(b.get("insertion_order", b.get("_source_index", 0)))
	)
	return active


static func describe_activation(raw_book: Variant, corpus: String) -> Array[String]:
	var lines: Array[String] = []
	for entry in active_entries_for_book(raw_book, corpus):
		var entry_name := str(entry.get("name", "")).strip_edges()
		if entry_name.is_empty():
			entry_name = "Unnamed lore entry"
		var reason := "constant" if bool(entry.get("constant", false)) else "key match"
		lines.append("%s — %s" % [entry_name, reason])
	return lines


static func _context_for_book(raw_book: Variant, corpus: String, fallback_name: String) -> String:
	if not raw_book is Dictionary:
		return ""
	var book: Dictionary = raw_book
	var active := active_entries_for_book(book, corpus)
	if active.is_empty():
		return ""
	var token_budget := maxi(64, int(book.get("token_budget", DEFAULT_TOKEN_BUDGET)))
	var char_budget := token_budget * CHARS_PER_TOKEN_ESTIMATE
	var used_chars := 0
	var blocks: Array[String] = []
	for entry in active:
		var content := str(entry.get("content", "")).strip_edges()
		if content.is_empty():
			continue
		var entry_name := str(entry.get("name", "Lore Entry")).strip_edges()
		var block := "[%s]\n%s" % [entry_name, content]
		if used_chars + block.length() > char_budget:
			var remaining := char_budget - used_chars
			if remaining > 80:
				blocks.append(block.left(remaining).strip_edges() + "…")
			break
		blocks.append(block)
		used_chars += block.length()
	var book_name := str(book.get("name", fallback_name)).strip_edges()
	if book_name.is_empty():
		book_name = fallback_name
	if blocks.is_empty():
		return ""
	return "%s — activated entries:\n%s" % [book_name, "\n\n".join(blocks)]


static func _entry_is_active(entry: Dictionary, corpus: String) -> bool:
	if not bool(entry.get("enabled", true)):
		return false
	var content := str(entry.get("content", "")).strip_edges()
	if content.is_empty():
		return false
	if bool(entry.get("constant", false)):
		return true
	var keys := _string_array(entry.get("keys", []))
	if keys.is_empty():
		return false
	var case_sensitive := bool(entry.get("case_sensitive", false))
	if not _matches_any(corpus, keys, case_sensitive):
		return false
	if bool(entry.get("selective", false)):
		var secondary := _string_array(entry.get("secondary_keys", []))
		if not secondary.is_empty() and not _matches_any(corpus, secondary, case_sensitive):
			return false
	return true


static func _matches_any(text: String, values: Array[String], case_sensitive: bool) -> bool:
	var haystack := text if case_sensitive else text.to_lower()
	for value in values:
		var needle := value if case_sensitive else value.to_lower()
		if not needle.is_empty() and haystack.contains(needle):
			return true
	return false


static func _string_array(raw: Variant) -> Array[String]:
	var values: Array[String] = []
	if raw is Array:
		for item in raw:
			var value := str(item).strip_edges()
			if not value.is_empty():
				values.append(value)
	elif raw is String:
		for item in str(raw).split(","):
			var value := str(item).strip_edges()
			if not value.is_empty():
				values.append(value)
	return values
