class_name CCFSimilarIdeaSourceServiceV0213
extends RefCounted

const IDEA_SOURCE_SERVICE = preload(
	"res://scripts/services/idea_source_service_v0213.gd"
)


static func extract_source(
	character_record: Dictionary,
	project_context: Dictionary = {},
	similarity_mode: String = "balanced"
) -> Dictionary:
	# Work exclusively on deep copies: deriving a source must never alter a card.
	var source_record := character_record.duplicate(true)
	var card_value: Variant = source_record.get("character", {})
	var card: Dictionary = (
		(card_value as Dictionary).duplicate(true)
		if card_value is Dictionary else {}
	)
	var character_name := str(card.get("name", "")).strip_edges()
	var scenario := str(card.get("scenario", "")).strip_edges()
	var description := str(card.get("description", "")).strip_edges()
	var personality := str(card.get("personality", "")).strip_edges()
	var first_message := str(card.get("first_message", "")).strip_edges()
	var source := IDEA_SOURCE_SERVICE.new().blank_source()
	source["title"] = ""
	source["description"] = (
		"Reusable scenario engine extracted from an existing card. Review before generating or saving."
	)
	source["summary"] = (
		"Analyse the supplied source-card evidence for its repeatable relationship, conflict, tension and reveal engine; then create genuinely new concepts."
	)
	source["core_premise"] = (
		"Rebuild the repeatable relationship, conflict and reveal engine found in the source-card evidence: who is connected, what destabilises that structure, what remains hidden and what forces interaction."
	)
	source["setup"] = (
		"Use the source only as analytical evidence. Retain the underlying engine, not the original cast or prose."
	)
	source["core_variables"] = [
		"relationship structure", "setting role", "conflict or tension engine",
		"third-party role", "ground truth", "secrecy and reveal mechanism",
		"opening situation"
	]
	source["generation_rules"] = [
		"Create new characters and scenarios rather than an Alternative Version of the source card.",
		"Identify the reusable engine before ideating, then vary multiple structural axes.",
		"Keep every idea internally coherent and usable as a standalone roleplay-card concept."
	]
	source["guardrails"] = [
		"Do not copy exact dialogue, biography, scene prose or incidental hobbies.",
		"Do not perform a cosmetic rename or merely change appearance, job and location.",
		"Do not mutate or overwrite the source card."
	]
	source["diversity_axes"] = [
		"personalities", "settings", "relationship duration", "third-party identity",
		"inciting trigger", "secrecy structure", "opening beat", "reveal mechanism"
	]
	source["elements_not_to_copy"] = [
		"character names", "exact appearance", "exact dialogue", "exact biography",
		"incidental hobbies", "exact workplace", "exact ages beyond required adult status",
		"highly specific scene prose"
	]
	var tags_value: Variant = card.get("tags", [])
	if tags_value is Array:
		source["tags"] = (tags_value as Array).duplicate(true)
	var evidence_parts: Array[String] = []
	_append_evidence(evidence_parts, "Description", description)
	_append_evidence(evidence_parts, "Personality", personality)
	_append_evidence(evidence_parts, "Scenario", scenario)
	_append_evidence(evidence_parts, "Opening message", first_message)
	if not project_context.is_empty():
		var shared_value: Variant = project_context.get("shared_context", {})
		if shared_value is Dictionary and not (shared_value as Dictionary).is_empty():
			evidence_parts.append("Project context:\n%s" % JSON.stringify(shared_value, "  "))
	source["sections"] = [{
		"id": "source-card-evidence",
		"label": "Source card evidence for abstraction (do not copy verbatim)",
		"content": "\n\n".join(evidence_parts)
	}]
	source["notes"] = (
		"Extracted locally as an editable source. The generation model performs the final abstraction. Matching Series metadata is advisory only."
	)
	source["similarity_mode"] = _normalise_mode(similarity_mode)
	source["origin"] = {
		"type": "existing_card_similarity",
		"source_character_id": str(source_record.get("character_id", "")),
		"source_character_name": character_name,
		"extracted_at": Time.get_datetime_string_from_system(true)
	}
	return source


static func analysis_prompt(source: Dictionary, similarity_mode: String) -> String:
	var service := IDEA_SOURCE_SERVICE.new()
	return (
		"CARD-TO-IDEA-SOURCE EXTRACTION\n"
		+ "Analyse the source-card evidence, infer the reusable engine, discard surface specifics, and generate new standalone Ideas.\n\n"
		+ service.generation_context(source, _normalise_mode(similarity_mode))
	)


static func capabilities() -> Dictionary:
	return {
		"source_card_immutable": true,
		"default_similarity": "balanced",
		"similarity_modes": ["close", "balanced", "loose"],
		"alternative_version_unchanged": true,
		"editable_before_generation": true,
		"saveable_as_idea_source": true,
		"cosmetic_renames_rejected": true
	}


static func _normalise_mode(mode: String) -> String:
	var clean := mode.strip_edges().to_lower()
	return clean if clean in ["close", "balanced", "loose"] else "balanced"


static func _append_evidence(parts: Array[String], label: String, value: String) -> void:
	if not value.is_empty():
		parts.append("%s:\n%s" % [label, value])
