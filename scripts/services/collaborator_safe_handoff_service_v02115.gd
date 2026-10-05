class_name CCFCollaboratorSafeHandoffServiceV02115
extends RefCounted

const STRATEGY_SAFE_SECTION := "safe_section"
const STRATEGY_SINGLE_RESPONSE := "single_response"
const DEFAULT_STRATEGY := STRATEGY_SAFE_SECTION

const BLUEPRINT_SECTIONS: Array[String] = [
	"CHARACTER IDENTITY",
	"RELATIONSHIP TO {{user}}",
	"APPEARANCE",
	"PERSONALITY & BEHAVIOUR",
	"HISTORY",
	"SETTING / WORLD FACTS",
	"ROLEPLAY SCENARIO",
	"FIRST MESSAGE REQUIREMENTS",
	"EXAMPLE DIALOGUE / VOICE",
	"ALTERNATIVE GREETINGS",
	"LOREBOOK",
	"SYSTEM / BEHAVIOURAL RULES",
	"OPTIONAL / ALTERNATE DIRECTIONS",
]


static func normalise_strategy(value: String) -> String:
	if value.strip_edges().to_lower() == STRATEGY_SINGLE_RESPONSE:
		return STRATEGY_SINGLE_RESPONSE
	return STRATEGY_SAFE_SECTION


static func strategy_from_settings(settings: Dictionary) -> String:
	var generation_value: Variant = settings.get("generation", {})
	if not generation_value is Dictionary:
		return DEFAULT_STRATEGY
	return normalise_strategy(
		str((generation_value as Dictionary).get(
			"collaborator_handoff_strategy", DEFAULT_STRATEGY
		))
	)


static func section_heading(index: int) -> String:
	if index < 0 or index >= BLUEPRINT_SECTIONS.size():
		return ""
	return BLUEPRINT_SECTIONS[index]


static func assembled_blueprint(section_values: Array) -> String:
	var blocks := _section_blocks(section_values)
	for index in range(section_values.size(), BLUEPRINT_SECTIONS.size()):
		blocks.append("%s\nNone established." % BLUEPRINT_SECTIONS[index])
	return "\n\n".join(blocks)


static func assembled_accepted_sections(section_values: Array) -> String:
	return "\n\n".join(_section_blocks(section_values))


static func accepted_sections_before_problem(
	section_values: Array, assessment: Dictionary
) -> Array:
	var problem_index := clampi(
		int(assessment.get("first_problem_index", 0)),
		0,
		mini(section_values.size(), BLUEPRINT_SECTIONS.size())
	)
	var accepted: Array = []
	for index in range(problem_index):
		accepted.append(section_values[index])
	return accepted


static func _section_blocks(section_values: Array) -> Array[String]:
	var blocks: Array[String] = []
	for index in range(mini(section_values.size(), BLUEPRINT_SECTIONS.size())):
		var value := ""
		value = str(section_values[index]).strip_edges()
		if value.is_empty():
			value = "None established."
		blocks.append("%s\n%s" % [BLUEPRINT_SECTIONS[index], value])
	return blocks


static func assess_blueprint(concept: String) -> Dictionary:
	var clean := concept.strip_edges()
	if clean.is_empty():
		return _problem(0, 0, "Generation Concept is empty.", {})
	var offsets := _heading_offsets(clean)
	for index in range(BLUEPRINT_SECTIONS.size()):
		var heading := BLUEPRINT_SECTIONS[index]
		if not offsets.has(heading):
			var boundary := _boundary_for_missing(index, clean.length(), offsets)
			return _problem(
				index,
				boundary,
				"Required section %s is missing." % heading,
				offsets
			)
		var start := int(offsets.get(heading, 0))
		if index > 0:
			var previous := BLUEPRINT_SECTIONS[index - 1]
			if start <= int(offsets.get(previous, -1)):
				return _problem(
					index,
					start,
					"Section %s is out of order." % heading,
					offsets
				)
		var body_start := _line_end_after(clean, start)
		var body_end := clean.length()
		for later_index in range(index + 1, BLUEPRINT_SECTIONS.size()):
			var later_heading := BLUEPRINT_SECTIONS[later_index]
			if offsets.has(later_heading):
				body_end = int(offsets.get(later_heading, clean.length()))
				break
		var body := clean.substr(body_start, maxi(0, body_end - body_start)).strip_edges()
		if body.is_empty() or _looks_truncated(body):
			return _problem(
				index,
				start,
				"Section %s is empty or appears incomplete." % heading,
				offsets
			)
	return {
		"complete": true,
		"first_problem_index": -1,
		"first_problem_heading": "",
		"prefix": clean,
		"reason": "",
		"heading_offsets": offsets,
	}


static func stitch_replacement_tail(prefix: String, replacement_tail: String) -> String:
	var clean_prefix := prefix.rstrip(" \t\r\n")
	var clean_tail := replacement_tail.strip_edges()
	if clean_prefix.is_empty():
		return clean_tail
	if clean_tail.is_empty():
		return clean_prefix
	return clean_prefix + "\n\n" + clean_tail


static func extract_partial_concept_from_json(raw: String) -> String:
	var key_index := raw.find('"concept_prompt"')
	if key_index < 0:
		return ""
	var colon_index := raw.find(":", key_index + 16)
	if colon_index < 0:
		return ""
	var quote_index := colon_index + 1
	while quote_index < raw.length() and raw[quote_index] in [" ", "\t", "\r", "\n"]:
		quote_index += 1
	if quote_index >= raw.length() or raw[quote_index] != '"':
		return ""
	var output := ""
	var escaped := false
	var index := quote_index + 1
	while index < raw.length():
		var character := raw[index]
		if escaped:
			match character:
				'"': output += '"'
				"\\": output += "\\"
				"/": output += "/"
				"b": output += "\b"
				"f": output += "\f"
				"n": output += "\n"
				"r": output += "\r"
				"t": output += "\t"
				"u":
					if index + 4 >= raw.length():
						return output.strip_edges()
					var digits := raw.substr(index + 1, 4)
					var valid_unicode := true
					for digit in digits:
						if str(digit).to_lower() not in "0123456789abcdef":
							valid_unicode = false
							break
					if not valid_unicode:
						return output.strip_edges()
					output += String.chr(digits.hex_to_int())
					index += 4
				_: output += character
			escaped = false
			index += 1
			continue
		if character == "\\":
			escaped = true
			index += 1
			continue
		if character == '"':
			break
		output += character
		index += 1
	return output.strip_edges()


static func tail_repair_prompt(
	partial_concept: String,
	assessment: Dictionary,
	source_context_text: String = ""
) -> String:
	var problem_index := clampi(
		int(assessment.get("first_problem_index", 0)),
		0,
		BLUEPRINT_SECTIONS.size() - 1
	)
	var remaining: Array[String] = []
	for index in range(problem_index, BLUEPRINT_SECTIONS.size()):
		remaining.append(BLUEPRINT_SECTIONS[index])
	var source_block := ""
	if not source_context_text.strip_edges().is_empty():
		source_block = (
			"\n\nAUTHORITATIVE ORIGINAL COLLABORATOR SOURCE — use this to restore facts "
			+ "that never reached the truncated output:\n"
			+ source_context_text.strip_edges()
		)
	return """Repair only the incomplete tail of this Character Card Forge Generation Concept.

The application has already accepted every section before %s. Do not repeat or rewrite that accepted prefix. Return a replacement beginning with the exact heading %s and continuing through every remaining heading below, in order. Every heading must be present. Use `None established.` when the collaboration provides no material for a section.

REMAINING REQUIRED HEADINGS:
%s

ACCEPTED PREFIX AND MALFORMED/INCOMPLETE SOURCE FOR CONTINUITY:
%s%s

Return one JSON object with exactly these keys:
- replacement_tail: the corrected blueprint tail beginning with %s;
- suggested_name: the settled character name if known, otherwise an empty string;
- alternate_greetings: complete playable alternatives grounded in the source, or [];
- lorebook: a Character Card-compatible Character Book object with name and entries.

Return JSON only.""" % [
		section_heading(problem_index),
		section_heading(problem_index),
		"\n".join(remaining),
		partial_concept,
		source_block,
		section_heading(problem_index),
	]


static func section_request_prompt(
	heading: String,
	source_context: String,
	accepted_sections: String
) -> String:
	var continuity := ""
	if not accepted_sections.strip_edges().is_empty():
		continuity = (
			"\n\nALREADY ACCEPTED EARLIER BLUEPRINT SECTIONS — continuity context only; "
			+ "do not rewrite them:\n" + accepted_sections.strip_edges()
		)
	return """Build exactly one section of a loss-minimising Character Card Forge Generation Concept.

SECTION: %s

Preserve accepted author decisions and concrete details. Later corrections override earlier suggestions. Rejected ideas are not canon. Preserve literal {{user}} and {{char}} placeholders. Return `None established.` only when the collaboration genuinely contains no relevant material. Do not add the section heading inside section_text.

AUTHORITATIVE COLLABORATOR SOURCE:
%s%s

Return one valid JSON object in exactly this shape:
{"section_text":"complete section body"}

Return JSON only.""" % [heading, source_context, continuity]


static func source_context(
	conversation_messages: Array,
	context_blocks: Array[String],
	memory_summary: String
) -> String:
	var blocks: Array[String] = []
	var clean_memory := memory_summary.strip_edges()
	if not clean_memory.is_empty():
		blocks.append(
			"COMPRESSED EARLIER MEMORY (lossy; newer verbatim decisions win):\n%s"
			% clean_memory
		)
	var clean_references: Array[String] = []
	for raw_context in context_blocks:
		var context := str(raw_context).strip_edges()
		if not context.is_empty():
			clean_references.append(context)
	if not clean_references.is_empty():
		blocks.append("REFERENCE CONTEXT:\n%s" % "\n\n---\n\n".join(clean_references))
	var transcript: Array[String] = []
	for raw_message in conversation_messages:
		if not raw_message is Dictionary:
			continue
		var role := str((raw_message as Dictionary).get("role", "")).strip_edges()
		var content := str((raw_message as Dictionary).get("content", "")).strip_edges()
		if content.is_empty():
			continue
		transcript.append("%s:\n%s" % [role.capitalize(), content])
	if not transcript.is_empty():
		blocks.append("CURRENT COLLABORATION TRANSCRIPT:\n%s" % "\n\n".join(transcript))
	return "\n\n".join(blocks)


static func _problem(
	index: int,
	boundary: int,
	reason: String,
	offsets: Dictionary
) -> Dictionary:
	return {
		"complete": false,
		"first_problem_index": index,
		"first_problem_heading": section_heading(index),
		"boundary": boundary,
		"reason": reason,
		"heading_offsets": offsets,
	}


static func accepted_prefix(concept: String, assessment: Dictionary) -> String:
	var boundary := clampi(int(assessment.get("boundary", 0)), 0, concept.length())
	return concept.substr(0, boundary).rstrip(" \t\r\n")


static func _heading_offsets(text: String) -> Dictionary:
	var offsets: Dictionary = {}
	var position := 0
	for line in text.split("\n", true):
		var normalized := _normalise_heading(str(line))
		for expected in BLUEPRINT_SECTIONS:
			if normalized == _normalise_heading(expected) and not offsets.has(expected):
				offsets[expected] = position
				break
		position += str(line).length() + 1
	return offsets


static func _normalise_heading(value: String) -> String:
	var clean := value.strip_edges()
	while clean.begins_with("#") or clean.begins_with("-"):
		clean = clean.substr(1).strip_edges()
	while clean.begins_with("*") or clean.begins_with("_"):
		clean = clean.substr(1).strip_edges()
	while clean.ends_with("*") or clean.ends_with("_") or clean.ends_with(":"):
		clean = clean.left(clean.length() - 1).strip_edges()
	return clean.to_upper()


static func _line_end_after(text: String, start: int) -> int:
	var newline := text.find("\n", start)
	return text.length() if newline < 0 else newline + 1


static func _boundary_for_missing(
	missing_index: int,
	default_boundary: int,
	offsets: Dictionary
) -> int:
	for later_index in range(missing_index + 1, BLUEPRINT_SECTIONS.size()):
		var later := BLUEPRINT_SECTIONS[later_index]
		if offsets.has(later):
			return int(offsets.get(later, default_boundary))
	return default_boundary


static func _looks_truncated(body: String) -> bool:
	var clean := body.strip_edges()
	if clean.is_empty():
		return true
	if clean.to_lower() == "none established.":
		return false
	if clean.ends_with("...") or clean.ends_with("…"):
		return true
	var last := clean.right(1)
	if last in [":", ",", ";", "-", "(", "[", "{"]:
		return true
	var final_word := clean.to_lower().split(" ", false)[-1].strip_edges()
	return final_word in [
		"a", "an", "and", "as", "at", "because", "but", "by", "for", "from",
		"if", "in", "into", "of", "or", "the", "to", "unless", "when", "where",
		"while", "with", "without",
	]
