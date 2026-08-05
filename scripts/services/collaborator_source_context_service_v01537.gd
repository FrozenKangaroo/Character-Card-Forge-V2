class_name CCFCollaboratorSourceContextServiceV01537
extends RefCounted

const LEGACY_SOURCE_SERVICE = preload(
	"res://scripts/services/collaborator_source_context_service_v01533.gd"
)

const FORMAT := "character_card_forge_collaborator_source"
const FORMAT_VERSION := 2

const ROLE_TARGET := "target"
const ROLE_REFERENCE := "reference"

const TYPE_GENERATED_IDEA := "generated_idea"
const TYPE_SAVED_IDEA := "saved_idea"
const TYPE_STRUCTURED_BUILDER := "structured_builder"
const TYPE_CHARACTER := "character"
const TYPE_PASTED_TEXT := "pasted_text"
const TYPE_EXTERNAL_CARD := "external_character_card"

const LEGACY_TYPES := [
	TYPE_GENERATED_IDEA,
	TYPE_SAVED_IDEA,
	TYPE_STRUCTURED_BUILDER,
	TYPE_CHARACTER
]

const USER_PERSONA_KEY_NAMES := [
	"userpersona",
	"userprofile",
	"chatuserpersona",
	"roleplayerpersona",
	"personauser"
]


static func from_generated_idea(
	idea: Dictionary,
	generation_metadata: Dictionary = {},
	role: String = ROLE_REFERENCE
) -> Dictionary:
	return upgrade_source(
		LEGACY_SOURCE_SERVICE.from_generated_idea(idea, generation_metadata),
		role
	)


static func from_saved_idea(
	idea: Dictionary,
	role: String = ROLE_REFERENCE
) -> Dictionary:
	return upgrade_source(LEGACY_SOURCE_SERVICE.from_saved_idea(idea), role)


static func from_structured_builder(
	ingredients: Array,
	custom_instructions: String = "",
	builder_metadata: Dictionary = {},
	role: String = ROLE_REFERENCE
) -> Dictionary:
	return upgrade_source(
		LEGACY_SOURCE_SERVICE.from_structured_builder(
			ingredients,
			custom_instructions,
			builder_metadata
		),
		role
	)


static func from_character(
	character: Dictionary,
	project_id: String = "",
	project_name: String = "",
	role: String = ROLE_REFERENCE
) -> Dictionary:
	return upgrade_source(
		LEGACY_SOURCE_SERVICE.from_character(character, project_id, project_name),
		role
	)


static func from_pasted_text(
	text: String,
	label: String = "Pasted source",
	role: String = ROLE_REFERENCE
) -> Dictionary:
	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		return {}

	var parsed: Variant = JSON.parse_string(clean_text)
	if parsed is Dictionary and CCFCardFormatService.detect_card_format(parsed) != "unknown":
		return _from_card_dictionary(
			parsed as Dictionary,
			"pasted_json",
			label,
			"",
			role
		)

	return upgrade_source({
		"format": FORMAT,
		"format_version": FORMAT_VERSION,
		"source_context_id": _new_source_id(),
		"source_type": TYPE_PASTED_TEXT,
		"label": label.strip_edges() if not label.strip_edges().is_empty() else "Pasted source",
		"snapshot": {"text": text},
		"provenance": {
			"origin": "collaborator_paste",
			"content_kind": "pasted_text"
		},
		"captured_at": Time.get_datetime_string_from_system(true),
		"author_intent": "reference_context",
		"source_role": role
	}, role)


static func from_card_file(
	path: String,
	role: String = ROLE_REFERENCE
) -> Dictionary:
	var loaded := CCFCardFormatService.load_card_file(path)
	if not bool(loaded.get("ok", false)):
		return loaded
	var raw_value: Variant = loaded.get("data", {})
	if not raw_value is Dictionary:
		return {"ok": false, "error": "The selected Character Card did not contain a JSON object."}
	var source := _from_card_dictionary(
		raw_value as Dictionary,
		str(loaded.get("source_format", path.get_extension().to_lower())),
		path.get_file(),
		path,
		role
	)
	if source.is_empty():
		return {"ok": false, "error": "The selected file is not a recognised Character Card source."}
	return {
		"ok": true,
		"source": source,
		"detected_format": str(loaded.get("detected_format", "unknown")),
		"source_format": str(loaded.get("source_format", ""))
	}


static func upgrade_source(
	source: Dictionary,
	requested_role: String = ""
) -> Dictionary:
	if source.is_empty():
		return {}
	var source_type := str(source.get("source_type", "")).strip_edges()
	var base: Dictionary = {}
	if source_type in LEGACY_TYPES:
		base = LEGACY_SOURCE_SERVICE.normalise(source)
	elif source_type in [TYPE_PASTED_TEXT, TYPE_EXTERNAL_CARD]:
		var snapshot_value: Variant = source.get("snapshot", {})
		if not snapshot_value is Dictionary:
			return {}
		var provenance_value: Variant = source.get("provenance", {})
		base = {
			"format": FORMAT,
			"format_version": FORMAT_VERSION,
			"source_context_id": str(source.get("source_context_id", "")).strip_edges(),
			"source_type": source_type,
			"label": str(source.get("label", "Source material")).strip_edges(),
			"snapshot": (snapshot_value as Dictionary).duplicate(true),
			"provenance": (
				(provenance_value as Dictionary).duplicate(true)
				if provenance_value is Dictionary
				else {}
			),
			"captured_at": str(source.get("captured_at", "")).strip_edges(),
			"author_intent": str(source.get("author_intent", "reference_context")).strip_edges()
		}
	else:
		return {}

	if base.is_empty():
		return {}
	if str(base.get("source_context_id", "")).is_empty():
		base["source_context_id"] = _new_source_id()
	if str(base.get("captured_at", "")).is_empty():
		base["captured_at"] = Time.get_datetime_string_from_system(true)

	var role := requested_role.strip_edges()
	if role.is_empty():
		role = str(source.get("source_role", ROLE_REFERENCE)).strip_edges()
	if role not in [ROLE_TARGET, ROLE_REFERENCE]:
		role = ROLE_REFERENCE
	if role == ROLE_TARGET and not can_be_target(base):
		role = ROLE_REFERENCE

	var exclusions: Array = []
	var raw_snapshot: Dictionary = base.get("snapshot", {}).duplicate(true)
	var ai_value: Variant = _sanitise_variant(raw_snapshot, "snapshot", exclusions)
	var ai_snapshot: Dictionary = ai_value if ai_value is Dictionary else {}

	base["format"] = FORMAT
	base["format_version"] = FORMAT_VERSION
	base["source_role"] = role
	base["snapshot"] = raw_snapshot
	base["ai_snapshot"] = ai_snapshot
	base["exclusions"] = exclusions
	base["excluded_user_persona_count"] = exclusions.size()
	return base


static func normalise_collection(
	raw_sources: Variant,
	legacy_source: Dictionary = {}
) -> Array[Dictionary]:
	var input: Array = []
	if raw_sources is Array:
		input = (raw_sources as Array).duplicate(true)
	if input.is_empty() and not legacy_source.is_empty():
		input.append(legacy_source)

	var result: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	var target_seen := false
	for raw_value in input:
		if not raw_value is Dictionary:
			continue
		var clean := upgrade_source(raw_value as Dictionary)
		if clean.is_empty():
			continue
		var source_id := str(clean.get("source_context_id", "")).strip_edges()
		if source_id.is_empty() or seen_ids.has(source_id):
			source_id = _new_source_id()
			clean["source_context_id"] = source_id
		seen_ids[source_id] = true
		if str(clean.get("source_role", ROLE_REFERENCE)) == ROLE_TARGET:
			if target_seen or not can_be_target(clean):
				clean["source_role"] = ROLE_REFERENCE
			else:
				target_seen = true
		result.append(clean)
	return result


static func set_target(
	sources: Array[Dictionary],
	source_context_id: String
) -> Array[Dictionary]:
	var clean := normalise_collection(sources)
	var requested_id := source_context_id.strip_edges()
	var found_target := false
	for index in range(clean.size()):
		var source: Dictionary = clean[index].duplicate(true)
		if (
			str(source.get("source_context_id", "")) == requested_id
			and can_be_target(source)
		):
			source["source_role"] = ROLE_TARGET
			found_target = true
		else:
			source["source_role"] = ROLE_REFERENCE
		clean[index] = source
	if not found_target:
		return normalise_collection(sources)
	return clean


static func primary_source(sources: Array[Dictionary]) -> Dictionary:
	for source in normalise_collection(sources):
		if str(source.get("source_role", "")) == ROLE_TARGET:
			return source.duplicate(true)
	var clean := normalise_collection(sources)
	return clean[0].duplicate(true) if not clean.is_empty() else {}


static func legacy_primary_source(sources: Array[Dictionary]) -> Dictionary:
	var primary := primary_source(sources)
	if primary.is_empty():
		return {}
	return {
		"format": str(primary.get("format", FORMAT)),
		"format_version": 1,
		"source_context_id": str(primary.get("source_context_id", "")),
		"source_type": str(primary.get("source_type", "")),
		"label": str(primary.get("label", "Source material")),
		"snapshot": primary.get("snapshot", {}).duplicate(true),
		"provenance": primary.get("provenance", {}).duplicate(true),
		"captured_at": str(primary.get("captured_at", "")),
		"author_intent": str(primary.get("author_intent", "develop_from_source"))
	}


static func can_be_target(source: Dictionary) -> bool:
	if str(source.get("source_type", "")) != TYPE_CHARACTER:
		return false
	var provenance_value: Variant = source.get("provenance", {})
	if not provenance_value is Dictionary:
		return false
	return not str((provenance_value as Dictionary).get("character_id", "")).strip_edges().is_empty()


static func display_type(source: Dictionary) -> String:
	match str(source.get("source_type", "")):
		TYPE_GENERATED_IDEA:
			return "Generated Idea"
		TYPE_SAVED_IDEA:
			return "Idea Notebook"
		TYPE_STRUCTURED_BUILDER:
			return "Structured Builder"
		TYPE_CHARACTER:
			return "Existing Character"
		TYPE_PASTED_TEXT:
			return "Pasted Source"
		TYPE_EXTERNAL_CARD:
			return "Attached Character Card"
		_:
			return "Source"


static func display_summary(source: Dictionary) -> String:
	var clean := upgrade_source(source)
	if clean.is_empty():
		return ""
	var ai_snapshot: Dictionary = clean.get("ai_snapshot", {})
	var source_type := str(clean.get("source_type", ""))
	if source_type == TYPE_PASTED_TEXT:
		return _truncate(str(ai_snapshot.get("text", "")).replace("\n", " "), 260)
	if source_type == TYPE_EXTERNAL_CARD:
		var normalised_value: Variant = ai_snapshot.get("normalised_card", {})
		if normalised_value is Dictionary:
			var data_value: Variant = (normalised_value as Dictionary).get("data", {})
			if data_value is Dictionary:
				var data: Dictionary = data_value
				var text := str(data.get("description", "")).strip_edges()
				if text.is_empty():
					text = str(data.get("personality", "")).strip_edges()
				return _truncate(text.replace("\n", " "), 260)
	return LEGACY_SOURCE_SERVICE.display_summary(legacy_primary_source([clean]))


static func model_context_block(sources: Array[Dictionary]) -> String:
	var clean := normalise_collection(sources)
	if clean.is_empty():
		return ""
	var lines: Array[String] = [
		"MULTI-SOURCE CHARACTER COLLABORATOR CONTEXT — READ-ONLY STRUCTURED REFERENCES",
		"Source count: %d" % clean.size(),
		"",
		"SOURCE-HANDLING RULES:",
		"- Keep every source individually identifiable. Never flatten several characters or ideas into one invented identity.",
		"- A source marked TARGET is the only existing character eligible for later Compare & Apply. REFERENCE sources provide continuity and inspiration only.",
		"- Treat established facts in each source as authoritative unless the author explicitly asks to change, branch, retcon, age, advance, reinterpret, or replace them.",
		"- Distinguish ESTABLISHED SOURCE FACTS, AUTHOR-REQUESTED CHANGES, and NEW/PROPOSED DETAILS.",
		"- If sources conflict, identify the conflict instead of silently choosing or blending incompatible facts.",
		"- A separate embedded UserPersona/user-profile section is extraction or chat-session residue by default. Its contents are excluded and must not define {{user}}.",
		"- {{user}} remains an unspecified roleplayer except for relationship/situation facts established by the actual character source or facts explicitly supplied by the author.",
		"- Character-source statements about that character's relationship to {{user}} remain valid; only the separate roleplayer-persona residue is excluded.",
		""
	]
	for index in range(clean.size()):
		var source: Dictionary = clean[index]
		lines.append("SOURCE %d" % (index + 1))
		lines.append("Role: %s" % str(source.get("source_role", ROLE_REFERENCE)).to_upper())
		lines.append("Type: %s" % display_type(source))
		lines.append("Label: %s" % str(source.get("label", "Source material")))
		lines.append("Source ID: %s" % str(source.get("source_context_id", "")))
		lines.append("Author intent: %s" % str(source.get("author_intent", "reference_context")))
		var exclusion_count := int(source.get("excluded_user_persona_count", 0))
		if exclusion_count > 0:
			lines.append("Embedded UserPersona sections excluded from AI context: %d" % exclusion_count)
		lines.append("AI-FACING SOURCE SNAPSHOT:")
		lines.append(JSON.stringify(source.get("ai_snapshot", {}), "  ", false))
		var provenance_value: Variant = source.get("provenance", {})
		if provenance_value is Dictionary and not (provenance_value as Dictionary).is_empty():
			lines.append("Source provenance:")
			lines.append(JSON.stringify(provenance_value, "  ", false))
		lines.append("")
	return "\n".join(lines)


static func sanitise_text_for_model(text: String) -> Dictionary:
	var exclusions: Array = []
	var clean_value: Variant = _sanitise_string(text, "text", exclusions)
	return {
		"text": str(clean_value),
		"exclusions": exclusions,
		"excluded_user_persona_count": exclusions.size()
	}


static func capabilities() -> Dictionary:
	return {
		"version": "0.15.37",
		"format_version": FORMAT_VERSION,
		"multi_source": true,
		"single_explicit_target": true,
		"reference_sources": true,
		"generated_idea_sources": true,
		"saved_idea_sources": true,
		"existing_character_sources": true,
		"pasted_text_sources": true,
		"json_character_card_sources": true,
		"png_character_card_sources": true,
		"raw_source_preserved": true,
		"ai_facing_normalised_source": true,
		"embedded_user_persona_exclusion": true,
		"user_relationship_facts_preserved": true
	}


static func _from_card_dictionary(
	raw_card: Dictionary,
	source_format: String,
	fallback_label: String,
	source_path: String,
	role: String
) -> Dictionary:
	if CCFCardFormatService.detect_card_format(raw_card) == "unknown":
		return {}
	var normalised := CCFCardFormatService.normalise_to_v2(raw_card)
	if normalised.is_empty():
		return {}
	var data_value: Variant = normalised.get("data", {})
	var label := fallback_label.strip_edges()
	if data_value is Dictionary:
		var card_name := str((data_value as Dictionary).get("name", "")).strip_edges()
		if not card_name.is_empty():
			label = card_name
	if label.is_empty():
		label = "Attached Character Card"
	return upgrade_source({
		"format": FORMAT,
		"format_version": FORMAT_VERSION,
		"source_context_id": _new_source_id(),
		"source_type": TYPE_EXTERNAL_CARD,
		"label": label,
		"snapshot": {
			"raw_card": raw_card.duplicate(true),
			"normalised_card": normalised.duplicate(true)
		},
		"provenance": {
			"origin": "external_character_card",
			"source_format": source_format,
			"source_path": source_path,
			"detected_format": CCFCardFormatService.detect_card_format(raw_card)
		},
		"captured_at": Time.get_datetime_string_from_system(true),
		"author_intent": "reference_context",
		"source_role": role
	}, role)


static func _sanitise_variant(
	value: Variant,
	path: String,
	exclusions: Array
) -> Variant:
	if value is Dictionary:
		var output := {}
		for raw_key in (value as Dictionary).keys():
			var key := str(raw_key)
			var child_path := "%s.%s" % [path, key]
			if _is_user_persona_key(key):
				exclusions.append({
					"kind": "embedded_user_persona",
					"path": child_path,
					"reason": "Separate user-persona field excluded from Collaborator character context."
				})
				continue
			output[raw_key] = _sanitise_variant(
				(value as Dictionary).get(raw_key),
				child_path,
				exclusions
			)
		return output
	if value is Array:
		var output_array: Array = []
		for index in range((value as Array).size()):
			output_array.append(_sanitise_variant(
				(value as Array)[index],
				"%s[%d]" % [path, index],
				exclusions
			))
		return output_array
	if value is String:
		return _sanitise_string(value as String, path, exclusions)
	return value


static func _sanitise_string(
	text: String,
	path: String,
	exclusions: Array
) -> String:
	var clean := text
	var tagged := RegEx.new()
	var compile_error := tagged.compile(
		"(?is)<\\s*user(?:\\s|_)*persona(?:\\s+[^>]*)?>.*?<\\s*/\\s*user(?:\\s|_)*persona\\s*>"
	)
	if compile_error == OK:
		var stripped := tagged.sub(clean, "", true)
		if stripped != clean:
			exclusions.append({
				"kind": "embedded_user_persona",
				"path": path,
				"reason": "Tagged <UserPersona> block excluded from Collaborator character context."
			})
			clean = stripped

	var lines := clean.split("\n", true)
	var output: Array[String] = []
	var dropping := false
	var heading_excluded := false
	for raw_line in lines:
		var line := str(raw_line)
		var trimmed := line.strip_edges()
		var lower := trimmed.to_lower()
		if not dropping and _is_user_persona_heading(lower):
			dropping = true
			heading_excluded = true
			continue
		if dropping:
			if _is_new_source_section(trimmed):
				dropping = false
			else:
				continue
		if not dropping:
			output.append(line)
	if heading_excluded:
		exclusions.append({
			"kind": "embedded_user_persona",
			"path": path,
			"reason": "Separate User Persona heading section excluded from Collaborator character context."
		})
	clean = "\n".join(output)
	return clean.strip_edges()


static func _is_user_persona_key(key: String) -> bool:
	var normalised := key.to_lower().replace(" ", "").replace("_", "").replace("-", "")
	return normalised in USER_PERSONA_KEY_NAMES


static func _is_user_persona_heading(lower: String) -> bool:
	var clean := lower.strip_edges()
	while clean.begins_with("#"):
		clean = clean.trim_prefix("#").strip_edges()
	if clean.ends_with(":"):
		clean = clean.left(clean.length() - 1).strip_edges()
	return clean in [
		"userpersona",
		"user persona",
		"user_persona",
		"{{user}} persona",
		"roleplayer persona"
	]


static func _is_new_source_section(line: String) -> bool:
	var clean := line.strip_edges()
	if clean.is_empty():
		return false
	if clean.begins_with("#"):
		return true
	if clean.begins_with(">"):
		return true
	if clean.begins_with("<") and clean.ends_with(">"):
		return not clean.to_lower().contains("userpersona")
	return false


static func _new_source_id() -> String:
	return "source_%d_%d" % [Time.get_unix_time_from_system(), randi_range(100000, 999999)]


static func _truncate(text: String, limit: int) -> String:
	if text.length() <= limit:
		return text
	return text.substr(0, maxi(0, limit - 1)).strip_edges() + "…"
