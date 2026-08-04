class_name CCFCollaboratorSourceContextServiceV01533
extends RefCounted

const FORMAT := "character_card_forge_collaborator_source"
const FORMAT_VERSION := 1

const TYPE_GENERATED_IDEA := "generated_idea"
const TYPE_SAVED_IDEA := "saved_idea"
const TYPE_STRUCTURED_BUILDER := "structured_builder"
const TYPE_CHARACTER := "character"


static func from_generated_idea(idea: Dictionary, generation_metadata: Dictionary = {}) -> Dictionary:
	var snapshot := _idea_snapshot(idea)
	return _build_source(
		TYPE_GENERATED_IDEA,
		str(snapshot.get("title", "Generated Idea")),
		snapshot,
		{
			"origin": "idea_generator",
			"saved_to_notebook": false,
			"seed_prompt": str(generation_metadata.get("seed", "")),
			"idea_contract_version": str(generation_metadata.get("idea_contract_version", "")),
			"project_id": str(generation_metadata.get("project_id", ""))
		}
	)


static func from_saved_idea(idea: Dictionary) -> Dictionary:
	var snapshot := _idea_snapshot(idea)
	return _build_source(
		TYPE_SAVED_IDEA,
		str(snapshot.get("title", "Saved Idea")),
		snapshot,
		{
			"origin": "idea_notebook",
			"saved_to_notebook": true,
			"idea_id": str(idea.get("id", "")),
			"notebook_id": str(idea.get("notebook_id", "")),
			"idea_format": str(idea.get("format", "")),
			"idea_format_version": int(idea.get("format_version", 0))
		}
	)


static func from_structured_builder(
	ingredients: Array,
	custom_instructions: String = "",
	builder_metadata: Dictionary = {}
) -> Dictionary:
	var clean_ingredients: Array[Dictionary] = []
	var concept_lines: Array[String] = []
	for raw in ingredients:
		if not raw is Dictionary:
			continue
		var ingredient: Dictionary = raw
		var value := str(ingredient.get("value", "")).strip_edges()
		if value.is_empty():
			continue
		var label := str(ingredient.get("label", ingredient.get("id", "Field"))).strip_edges()
		if label.is_empty():
			label = "Field"
		clean_ingredients.append({
			"id": str(ingredient.get("id", "")),
			"label": label,
			"value": value,
			"multi_select": bool(ingredient.get("multi_select", false))
		})
		concept_lines.append("%s: %s" % [label, value])
	var extra := custom_instructions.strip_edges()
	if not extra.is_empty():
		concept_lines.append("Custom instructions: %s" % extra)
	if concept_lines.is_empty():
		return {}
	var concept := (
		"Create a coherent, playable character concept from these selected ingredients. Treat every listed ingredient as authoritative unless the custom instructions explicitly override it.\n\n"
		+ "\n".join(concept_lines)
	)
	var snapshot := {
		"title": "Structured Builder Idea",
		"ingredients": clean_ingredients,
		"custom_instructions": extra,
		"concept": concept
	}
	return _build_source(
		TYPE_STRUCTURED_BUILDER,
		"Structured Builder Idea",
		snapshot,
		{
			"origin": "structured_builder",
			"options_format_version": int(builder_metadata.get("options_format_version", 0)),
			"ingredient_count": clean_ingredients.size()
		}
	)


static func from_character(
	character: Dictionary,
	project_id: String = "",
	project_name: String = ""
) -> Dictionary:
	var snapshot := character.duplicate(true)
	var label := _character_label(character)
	return _build_source(
		TYPE_CHARACTER,
		label,
		snapshot,
		{
			"origin": "workspace_character",
			"character_id": str(character.get("character_id", character.get("id", ""))),
			"project_id": project_id,
			"project_name": project_name
		}
	)


static func normalise(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var source_type := str(source.get("source_type", "")).strip_edges()
	if source_type not in [TYPE_GENERATED_IDEA, TYPE_SAVED_IDEA, TYPE_STRUCTURED_BUILDER, TYPE_CHARACTER]:
		return {}
	var snapshot_value: Variant = source.get("snapshot", {})
	if not snapshot_value is Dictionary:
		return {}
	var provenance_value: Variant = source.get("provenance", {})
	var result := {
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
		"author_intent": str(source.get("author_intent", "develop_from_source")).strip_edges()
	}
	if str(result["source_context_id"]).is_empty():
		result["source_context_id"] = _new_source_id()
	if str(result["label"]).is_empty():
		result["label"] = "Source material"
	if str(result["captured_at"]).is_empty():
		result["captured_at"] = Time.get_datetime_string_from_system(true)
	return result


static func is_valid(source: Dictionary) -> bool:
	return not normalise(source).is_empty()


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
		_:
			return "Source"


static func display_summary(source: Dictionary) -> String:
	var clean := normalise(source)
	if clean.is_empty():
		return ""
	var snapshot: Dictionary = clean.get("snapshot", {})
	match str(clean.get("source_type", "")):
		TYPE_GENERATED_IDEA, TYPE_SAVED_IDEA, TYPE_STRUCTURED_BUILDER:
			var concept := str(snapshot.get("concept", "")).strip_edges().replace("\n", " ")
			return _truncate(concept, 260)
		TYPE_CHARACTER:
			var description := str(snapshot.get("description", "")).strip_edges().replace("\n", " ")
			if description.is_empty():
				description = str(snapshot.get("personality", "")).strip_edges().replace("\n", " ")
			return _truncate(description, 260)
		_:
			return ""


static func model_context_block(source: Dictionary) -> String:
	var clean := normalise(source)
	if clean.is_empty():
		return ""
	var snapshot: Dictionary = clean.get("snapshot", {})
	var provenance: Dictionary = clean.get("provenance", {})
	var lines: Array[String] = [
		"COLLABORATOR SOURCE CONTEXT — READ-ONLY AUTHORITATIVE REFERENCE",
		"Source type: %s" % display_type(clean),
		"Source label: %s" % str(clean.get("label", "Source material")),
		"Author intent: %s" % str(clean.get("author_intent", "develop_from_source")),
		"",
		"SOURCE-HANDLING RULES:",
		"- This snapshot is source material supplied by the author. Never silently modify the stored source itself.",
		"- Treat facts explicitly established by the source as authoritative unless the author asks to change, branch, retcon, age, advance, reinterpret, or replace them.",
		"- Keep three categories conceptually distinct: ESTABLISHED SOURCE FACTS, AUTHOR-REQUESTED CHANGES, and NEW/PROPOSED DETAILS.",
		"- New details may deepen gaps, but do not casually contradict established facts.",
		"- A derivative character may become fully standalone later; provenance is continuity metadata, not a requirement that the source remain present.",
		"",
		"STRUCTURED SOURCE SNAPSHOT:",
		JSON.stringify(snapshot, "  ", false)
	]
	if not provenance.is_empty():
		lines.append("")
		lines.append("SOURCE PROVENANCE:")
		lines.append(JSON.stringify(provenance, "  ", false))
	return "\n".join(lines)


static func _build_source(
	source_type: String,
	label: String,
	snapshot: Dictionary,
	provenance: Dictionary
) -> Dictionary:
	return normalise({
		"format": FORMAT,
		"format_version": FORMAT_VERSION,
		"source_context_id": _new_source_id(),
		"source_type": source_type,
		"label": label,
		"snapshot": snapshot.duplicate(true),
		"provenance": provenance.duplicate(true),
		"captured_at": Time.get_datetime_string_from_system(true),
		"author_intent": "develop_from_source"
	})


static func _idea_snapshot(idea: Dictionary) -> Dictionary:
	var tags_value: Variant = idea.get("tags", [])
	var tags: Array = tags_value.duplicate(true) if tags_value is Array else []
	return {
		"title": str(idea.get("title", "Untitled idea")),
		"character_name": str(idea.get("character_name", "")),
		"character_role": str(idea.get("character_role", "")),
		"source_anchor": str(idea.get("source_anchor", "")),
		"roleplay_hook": str(idea.get("roleplay_hook", "")),
		"concept": str(idea.get("concept", "")),
		"tags": tags
	}


static func _character_label(character: Dictionary) -> String:
	var direct := str(character.get("name", "")).strip_edges()
	if not direct.is_empty():
		return direct
	var fields_value: Variant = character.get("fields", {})
	if fields_value is Dictionary:
		var fields: Dictionary = fields_value
		var field_name := str(fields.get("name", "")).strip_edges()
		if not field_name.is_empty():
			return field_name
	return "Existing Character"


static func _new_source_id() -> String:
	return "source_%d_%d" % [Time.get_unix_time_from_system(), randi_range(100000, 999999)]


static func _truncate(text: String, limit: int) -> String:
	if text.length() <= limit:
		return text
	return text.substr(0, maxi(0, limit - 1)).strip_edges() + "…"
