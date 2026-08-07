class_name CCFCollaboratorCardVisionServiceV01539
extends RefCounted

const SOURCE_SERVICE_V01537 = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)

const MODE_CARD_AND_VISION := "card_and_vision"
const MODE_CARD_ONLY := "card_only"
const MODE_VISION_ONLY := "vision_only"


static func capabilities() -> Dictionary:
	return {
		"version": "0.15.39",
		"character_card_png_dual_ingestion": true,
		"card_and_vision_mode": true,
		"card_only_mode": true,
		"vision_only_mode": true,
		"analyse_attached_card_later": true,
		"vision_context_linked_to_structured_source": true,
		"vision_does_not_overwrite_card_metadata": true,
		"raw_card_source_preserved": true,
		"embedded_user_persona_excluded": true
	}


static func ingestion_plan(mode: String) -> Dictionary:
	match mode:
		MODE_CARD_ONLY:
			return {
				"mode": MODE_CARD_ONLY,
				"use_card_metadata": true,
				"use_vision": false
			}
		MODE_VISION_ONLY:
			return {
				"mode": MODE_VISION_ONLY,
				"use_card_metadata": false,
				"use_vision": true
			}
		_:
			return {
				"mode": MODE_CARD_AND_VISION,
				"use_card_metadata": true,
				"use_vision": true
			}


static func is_visual_card_source(source: Dictionary) -> bool:
	if str(source.get("source_type", "")) != SOURCE_SERVICE_V01537.TYPE_EXTERNAL_CARD:
		return false
	var path := source_image_path(source)
	return path.get_extension().to_lower() in ["png", "apng"]


static func source_image_path(source: Dictionary) -> String:
	var provenance_value: Variant = source.get("provenance", {})
	if not provenance_value is Dictionary:
		return ""
	return str((provenance_value as Dictionary).get("source_path", "")).strip_edges()


static func annotate_vision_context(
	context_item: Dictionary,
	source_context_id: String
) -> Dictionary:
	var result := context_item.duplicate(true)
	var clean_id := source_context_id.strip_edges()
	if clean_id.is_empty():
		return result
	result["linked_source_context_id"] = clean_id
	result["linked_source_kind"] = "character_card_image"
	result["context_provenance"] = "vision_description_linked_to_character_card_source"
	return result


static func mark_source_vision_analysis(
	source: Dictionary,
	context_item: Dictionary,
	metadata: Dictionary = {}
) -> Dictionary:
	var result := SOURCE_SERVICE_V01537.upgrade_source(source)
	if result.is_empty():
		return {}
	var provenance_value: Variant = result.get("provenance", {})
	var provenance: Dictionary = (
		(provenance_value as Dictionary).duplicate(true)
		if provenance_value is Dictionary
		else {}
	)
	provenance["visual_analysis"] = {
		"status": "available",
		"context_id": str(context_item.get("context_id", "")),
		"source_path": str(context_item.get("source_path", source_image_path(result))),
		"vision_profile_id": str(metadata.get("vision_profile_id", context_item.get("vision_profile_id", ""))),
		"vision_profile_name": str(metadata.get("vision_profile_name", context_item.get("vision_profile_name", ""))),
		"vision_model": str(metadata.get("vision_model", metadata.get("model", context_item.get("vision_model", "")))),
		"analysed_at": Time.get_datetime_string_from_system(true),
		"relationship": "supplementary_visual_evidence"
	}
	result["provenance"] = provenance
	return SOURCE_SERVICE_V01537.upgrade_source(result)


static func source_has_linked_vision(
	source: Dictionary,
	context_items: Variant
) -> bool:
	var source_id := str(source.get("source_context_id", "")).strip_edges()
	if source_id.is_empty() or not context_items is Array:
		return false
	for raw_item in context_items as Array:
		if not raw_item is Dictionary:
			continue
		if (
			str((raw_item as Dictionary).get("linked_source_context_id", "")) == source_id
			and str((raw_item as Dictionary).get("type", "")) == "vision_reference"
		):
			return true
	return false
