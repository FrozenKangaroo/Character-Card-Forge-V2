class_name CCFImageCollaboratorHandoffServiceV0170
extends RefCounted

const SOURCE_SERVICE_V01537 = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)
const RESULT_SERVICE_V01610 = preload(
	"res://scripts/services/image_result_workflow_service_v01610.gd"
)

const HANDOFF_FORMAT_VERSION := 1
const MODE_EXISTING_TARGET := "existing_character_target"
const MODE_NEW_COLLABORATOR := "new_collaborator"


static func from_result(
	project: Dictionary,
	character: Dictionary,
	record: Dictionary,
	resolved_image_path: String
) -> Dictionary:
	var project_id := str(project.get("project_id", "")).strip_edges()
	var character_id := str(character.get("character_id", "")).strip_edges()
	var image_path := resolved_image_path.strip_edges()
	if project_id.is_empty() or character_id.is_empty() or record.is_empty():
		return {}
	if image_path.is_empty() or str(record.get("path", "")).strip_edges().is_empty():
		return {}

	var snapshot := RESULT_SERVICE_V01610.snapshot_from_record(record)
	var character_name := _character_name(character)
	if character_name.is_empty():
		character_name = "Unnamed Character"
	var image_id := str(record.get("image_id", "")).strip_edges()
	var label := "%s — generated image" % character_name
	if not image_id.is_empty():
		label += " (%s)" % image_id

	return SOURCE_SERVICE_V01537.upgrade_source({
		"format": SOURCE_SERVICE_V01537.FORMAT,
		"format_version": SOURCE_SERVICE_V01537.FORMAT_VERSION,
		"source_type": SOURCE_SERVICE_V01537.TYPE_IMAGE_STUDIO_RESULT,
		"label": label,
		"snapshot": {
			"image": {
				"image_id": image_id,
				"project_relative_path": str(record.get("path", "")),
				"resolved_path": image_path,
				"width": int(record.get("width", 0)),
				"height": int(record.get("height", 0)),
				"created_at": str(record.get("created_at", "")),
				"favourite": bool(record.get("favourite_v01610", false))
			},
			"generation": _generation_snapshot(snapshot),
			"evidence_boundary": {
				"raw_image_preserved": true,
				"text_model_can_inspect_pixels": false,
				"generation_metadata_is_creative_provenance": true,
				"vision_analysis_is_separate_supplementary_evidence": true
			}
		},
		"provenance": {
			"origin": "image_studio_result",
			"handoff_format_version": HANDOFF_FORMAT_VERSION,
			"project_id": project_id,
			"project_name": _project_name(project),
			"character_id": character_id,
			"character_name": character_name,
			"image_id": image_id,
			"source_path": image_path,
			"project_relative_path": str(record.get("path", "")),
			"result_workflow_version": str(record.get("result_workflow_version", "legacy")),
			"captured_from": "image_studio_gallery"
		},
		"captured_at": Time.get_datetime_string_from_system(true),
		"author_intent": "visual_reference_context",
		"source_role": SOURCE_SERVICE_V01537.ROLE_REFERENCE
	})


static func capabilities() -> Dictionary:
	return {
		"version": "0.17.0",
		"format_version": HANDOFF_FORMAT_VERSION,
		"structured_image_source": true,
		"raw_image_provenance": true,
		"exact_generation_snapshot": true,
		"existing_character_target_mode": true,
		"new_collaborator_mode": true,
		"optional_linked_vision": true,
		"vision_evidence_separate": true,
		"canonical_writes_automatic": false
	}


static func _generation_snapshot(snapshot: Dictionary) -> Dictionary:
	return {
		"format_version": int(snapshot.get("format_version", 0)),
		"profile_id": str(snapshot.get("profile_id", "")),
		"profile_name": str(snapshot.get("profile_name", "")),
		"backend": str(snapshot.get("backend", "")),
		"model": str(snapshot.get("model", "")),
		"size": str(snapshot.get("size", "")),
		"prompt_style": str(snapshot.get("prompt_style", "auto")),
		"composed_prompt": str(snapshot.get("composed_prompt", "")),
		"negative_prompt": str(snapshot.get("negative_prompt", "")),
		"sampler": str(snapshot.get("sampler", "")),
		"steps": int(snapshot.get("steps", 0)),
		"cfg_scale": float(snapshot.get("cfg_scale", 0.0)),
		"seed": int(snapshot.get("seed", -1)),
		"provider_parameters": _safe_provider_parameters(
			snapshot.get("provider_parameters", {})
		),
		"image_operation": str(snapshot.get("image_operation", "text_to_image")),
		"source_image_id": str(snapshot.get("source_image_id", "")),
		"denoise_strength": float(snapshot.get("denoise_strength", 0.0)),
		"mask_blur": int(snapshot.get("mask_blur", 0))
	}


static func _character_name(character: Dictionary) -> String:
	var candidates: Array[String] = [str(character.get("name", ""))]
	var character_value: Variant = character.get("character", {})
	if character_value is Dictionary:
		candidates.append(str((character_value as Dictionary).get("name", "")))
	var metadata_value: Variant = character.get("metadata", {})
	if metadata_value is Dictionary:
		candidates.append(str((metadata_value as Dictionary).get("name", "")))
	for candidate in candidates:
		var clean := candidate.strip_edges()
		if not clean.is_empty():
			return clean
	return "Unnamed Character"


static func _project_name(project: Dictionary) -> String:
	var direct := str(project.get("name", "")).strip_edges()
	if not direct.is_empty():
		return direct
	var metadata_value: Variant = project.get("metadata", {})
	if metadata_value is Dictionary:
		var metadata_name := str(
			(metadata_value as Dictionary).get("name", "")
		).strip_edges()
		if not metadata_name.is_empty():
			return metadata_name
	return "Untitled Project"


static func _safe_provider_parameters(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var result := {}
	for raw_key in (value as Dictionary).keys():
		var key := str(raw_key)
		var normalised := key.to_lower().replace("-", "_").replace(" ", "_")
		if (
			"api_key" in normalised
			or "apikey" in normalised
			or "secret" in normalised
			or "password" in normalised
			or "authorization" in normalised
			or "access_token" in normalised
			or normalised == "token"
			or normalised.ends_with("_token")
			or "bearer" in normalised
			or "private_key" in normalised
		):
			continue
		var item: Variant = (value as Dictionary).get(raw_key)
		if item is Dictionary:
			result[raw_key] = _safe_provider_parameters(item)
		elif item is Array:
			result[raw_key] = _safe_array(item as Array)
		else:
			result[raw_key] = item
	return result


static func _safe_array(value: Array) -> Array:
	var result: Array = []
	for item in value:
		if item is Dictionary:
			result.append(_safe_provider_parameters(item))
		elif item is Array:
			result.append(_safe_array(item as Array))
		else:
			result.append(item)
	return result
