class_name CCFCharacterCollaboratorWindowV01537Provenance
extends "res://scripts/ui/character_collaborator_window_v01537.gd"


func active_source_context_v01533() -> Dictionary:
	if _suppress_legacy_source_v01537:
		return {}
	var sources := active_source_contexts_v01537()
	var primary := SOURCE_SERVICE_V01537.legacy_primary_source(sources)
	if primary.is_empty():
		return {}
	var provenance_value: Variant = primary.get("provenance", {})
	var provenance: Dictionary = (
		(provenance_value as Dictionary).duplicate(true)
		if provenance_value is Dictionary
		else {}
	)
	var derivation_value: Variant = provenance.get("derivation", {})
	var derivation: Dictionary = (
		(derivation_value as Dictionary).duplicate(true)
		if derivation_value is Dictionary
		else {}
	)
	var source_summaries: Array[Dictionary] = []
	for source in sources:
		source_summaries.append({
			"source_context_id": str(source.get("source_context_id", "")),
			"source_type": str(source.get("source_type", "")),
			"label": str(source.get("label", "Source material")),
			"source_role": str(source.get("source_role", SOURCE_SERVICE_V01537.ROLE_REFERENCE)),
			"author_intent": str(source.get("author_intent", "reference_context")),
			"excluded_user_persona_count": int(source.get("excluded_user_persona_count", 0))
		})
	derivation["collaborator_sources_v01537"] = source_summaries
	derivation["collaborator_source_count_v01537"] = source_summaries.size()
	provenance["derivation"] = derivation
	primary["provenance"] = provenance
	return primary


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["completion_multi_source_lineage"] = true
	return result
