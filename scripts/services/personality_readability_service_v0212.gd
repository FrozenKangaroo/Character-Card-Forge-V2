class_name CCFPersonalityReadabilityServiceV0212
extends RefCounted

const CONTRACT_VERSION := 1
const MINIMUM_STRUCTURED_HEADINGS := 2
const DEFAULT_HEADINGS: Array[String] = [
	"Personality structure",
	"Mind",
	"Moral Alignment",
	"Emotional Tendencies",
	"Decision Style",
	"Occupation",
	"Likes",
	"Dislikes",
	"Hobbies",
	"Skills",
	"Boundaries",
	"Risk Tolerance",
	"Secrecy",
	"Relationship Behavior toward {{user}}",
	"Loyalty",
	"Speech Style",
	"Flaw",
	"Secret",
	"Sexual Traits",
	"Experience Level",
	"Number of Sexual Partners",
	"Sexual History",
	"Sexual Nature",
	"Infidelity Tendency",
	"Preferences",
	"Turn-ons",
	"Turn-offs",
	"Kinks",
	"Fantasy",
	"Behavioral Tendencies",
	"How they lost their virginity",
	"Protection",
	"Favourite Position",
	"Background",
	"Backstory",
	"Relationships",
	"Beliefs"
]


static func format_for_display(
	raw_text: String, template_headings: Array = []
) -> Dictionary:
	var source := raw_text.replace("\r\n", "\n").replace("\r", "\n")
	var headings := _normalised_headings(template_headings)
	for discovered in _discover_line_headings(source):
		_append_unique_heading(headings, discovered)
	var with_breaks := _insert_missing_line_breaks(source, headings)
	var display_lines: Array[String] = []
	var heading_count := 0
	for line_value in with_breaks.split("\n", true):
		var line := str(line_value)
		if _line_starts_with_heading(line, headings):
			heading_count += 1
			if not display_lines.is_empty() and not display_lines[-1].is_empty():
				display_lines.append("")
		display_lines.append(line)
	return {
		"display_text": "\n".join(display_lines),
		"heading_count": heading_count,
		"readable_view_recommended": heading_count >= MINIMUM_STRUCTURED_HEADINGS,
		"stored_text": raw_text,
		"stored_text_unchanged": true,
		"visual_only": true
	}


static func capabilities() -> Dictionary:
	return {
		"contract_version": CONTRACT_VERSION,
		"minimum_structured_headings": MINIMUM_STRUCTURED_HEADINGS,
		"visual_only": true,
		"stored_text_unchanged": true,
		"exports_unchanged": true,
		"token_estimates_unchanged": true,
		"inline_known_headings_supported": true,
		"custom_template_headings_supported": true
	}


static func _normalised_headings(template_headings: Array) -> Array[String]:
	var result: Array[String] = []
	for heading in DEFAULT_HEADINGS:
		_append_unique_heading(result, heading)
	for heading_value in template_headings:
		_append_unique_heading(result, str(heading_value))
	result.sort_custom(
		func(left: String, right: String) -> bool:
			return left.length() > right.length()
	)
	return result


static func _append_unique_heading(
	headings: Array[String], heading_value: String
) -> void:
	var clean := heading_value.strip_edges().trim_suffix(":")
	if clean.is_empty() or clean.length() > 80:
		return
	for existing in headings:
		if existing.to_lower() == clean.to_lower():
			return
	headings.append(clean)


static func _discover_line_headings(text: String) -> Array[String]:
	var result: Array[String] = []
	for line_value in text.split("\n", true):
		var heading := _generic_heading_at_line_start(str(line_value))
		if not heading.is_empty():
			_append_unique_heading(result, heading)
	return result


static func _generic_heading_at_line_start(line: String) -> String:
	var clean := line.strip_edges()
	var colon_index := clean.find(":")
	if colon_index <= 0 or colon_index > 80:
		return ""
	var candidate := clean.substr(0, colon_index).strip_edges()
	if candidate.is_empty() or candidate.contains("/") or candidate.contains("\\"):
		return ""
	for disallowed in [".", "!", "?", ";", ","]:
		if candidate.contains(disallowed):
			return ""
	var first := candidate.substr(0, 1)
	if not candidate.begins_with("{{") and (
		first == first.to_lower() or first == first.to_upper() and first.to_lower() == first
	):
		return ""
	return candidate


static func _insert_missing_line_breaks(
	text: String, headings: Array[String]
) -> String:
	if text.is_empty():
		return text
	var insertion_positions: Dictionary = {}
	for heading in headings:
		var needle := "%s:" % heading
		var search_from := 0
		while search_from < text.length():
			var position := text.findn(needle, search_from)
			if position < 0:
				break
			if _is_heading_occurrence(text, position, needle.length()):
				if position > 0 and text.substr(position - 1, 1) != "\n":
					insertion_positions[position] = true
			search_from = position + needle.length()
	if insertion_positions.is_empty():
		return text
	var result := ""
	for index in range(text.length()):
		if insertion_positions.has(index):
			while result.ends_with(" ") or result.ends_with("\t"):
				result = result.substr(0, result.length() - 1)
			result += "\n"
		result += text.substr(index, 1)
	return result


static func _is_heading_occurrence(
	text: String, position: int, needle_length: int
) -> bool:
	if position < 0 or position + needle_length > text.length():
		return false
	var after_index := position + needle_length
	if after_index < text.length():
		var after := text.substr(after_index, 1)
		if after not in [" ", "\t", "\n"]:
			return false
	if position == 0:
		return true
	var before := text.substr(position - 1, 1)
	if before == "\n":
		return true
	if before not in [" ", "\t"]:
		return false
	var scan := position - 1
	while scan >= 0 and text.substr(scan, 1) in [" ", "\t"]:
		scan -= 1
	if scan < 0:
		return true
	return text.substr(scan, 1) in [".", "!", "?"]


static func _line_starts_with_heading(
	line: String, headings: Array[String]
) -> bool:
	var clean := line.strip_edges()
	for heading in headings:
		if clean.to_lower().begins_with(("%s:" % heading).to_lower()):
			return true
	return not _generic_heading_at_line_start(clean).is_empty()
