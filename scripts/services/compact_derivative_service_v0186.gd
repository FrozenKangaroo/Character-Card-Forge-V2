class_name CCFCompactDerivativeServiceV0186
extends RefCounted

const VERSION := "0.18.6"
const PROVENANCE_KEY := "compact_derivative_v0186"
const SOURCE_HASH_VERSION := 1

const LEVELS := [
	{"id": "gentle", "label": "Gentle", "ratio": 0.80, "description": "Remove repetition while retaining most texture."},
	{"id": "balanced", "label": "Balanced", "ratio": 0.60, "description": "Tighten every major field while preserving voice and hooks."},
	{"id": "aggressive", "label": "Aggressive", "ratio": 0.40, "description": "Prioritise playable essentials and distinctive traits."},
	{"id": "extreme", "label": "Extreme", "ratio": 0.25, "description": "Keep only the smallest coherent roleplay-ready core."}
]

const COMPRESSIBLE_FIELDS := [
	{"path": "character.description", "label": "Description", "type": "text"},
	{"path": "character.personality", "label": "Personality", "type": "text"},
	{"path": "character.scenario", "label": "Scenario", "type": "text"},
	{"path": "character.first_message", "label": "First Message", "type": "text"},
	{"path": "character.example_dialogue", "label": "Example Dialogue", "type": "text"},
	{"path": "character.creator_notes", "label": "Creator Notes", "type": "text"},
	{"path": "character.system_prompt", "label": "System Prompt", "type": "text"},
	{"path": "character.post_history_instructions", "label": "Post-History Instructions", "type": "text"}
]


static func capabilities() -> Dictionary:
	return {
		"version": VERSION,
		"independent_character_only": true,
		"source_content_hash_guard": true,
		"private_lineage": true,
		"target_token_budget": true,
		"compression_levels": true,
		"preservation_controls": true,
		"complete_field_comparison": true,
		"editable_before_save": true,
		"revision_checkpoint": true,
		"private_model_provenance": true,
		"source_overwrite": false,
		"automatic_save": false
	}


static func default_options(project: Dictionary, character_id: String) -> Dictionary:
	var before := estimated_tokens(project, character_id)
	return {
		"compression_level": "balanced",
		"target_tokens": maxi(256, int(round(float(before) * 0.60))),
		"preserve_lorebook": true,
		"preserve_greetings": true,
		"preserve_examples": true,
		"preserve_front_porch": true,
		"preserve_adult_traits": true,
		"preserve_tags": true,
		"preserve_image_prompt": true
	}


static func estimated_tokens(project: Dictionary, character_id: String) -> int:
	return int(
		CCFCardInspectionServiceV0182.token_report(project, character_id).get(
			"total_tokens", 0
		)
	)


static func suggested_target(before_tokens: int, level_id: String) -> int:
	var ratio := 0.60
	for level in LEVELS:
		if str(level.get("id", "")) == level_id:
			ratio = float(level.get("ratio", ratio))
			break
	return maxi(128, int(round(float(before_tokens) * ratio)))


static func source_content_hash(project: Dictionary, character_id: String) -> String:
	var source := CCFStorageService.get_character(project, character_id)
	if source.is_empty():
		return ""
	var snapshot := CCFRevisionServiceV0181.snapshot_character(source)
	return JSON.stringify(_canonical(snapshot)).sha256_text()


static func build_request(
	project: Dictionary, character_id: String, options: Dictionary
) -> Dictionary:
	var source := CCFStorageService.get_character(project, character_id)
	if source.is_empty():
		return {"ok": false, "error": "The selected source character could not be found."}
	var authored_fields := {}
	for field in COMPRESSIBLE_FIELDS:
		var path := str(field.get("path", ""))
		if path == "character.example_dialogue" and bool(options.get("preserve_examples", true)):
			continue
		authored_fields[path] = CCFStorageService.get_value_at_path(source, path, "")
	var context := {
		"source_name": CCFStorageService.character_display_name(source),
		"source_fields": authored_fields,
		"target_tokens": clampi(int(options.get("target_tokens", 1000)), 128, 1000000),
		"compression_level": str(options.get("compression_level", "balanced")),
		"preserved_material": preservation_summary(options),
		"rules": [
			"Preserve character identity, voice, agency, scenario logic and roleplay usability.",
			"Remove repetition and ornamental phrasing before removing distinctive facts.",
			"Do not add new backstory, user identity, user preferences or relationship history.",
			"Return a complete replacement string for every supplied source field.",
			"Do not include preserved material in another field merely to evade its preservation control."
		]
	}
	var schema_fields := {}
	for path in authored_fields.keys():
		schema_fields[path] = "complete replacement text"
	var messages := [
		{
			"role": "system",
			"content": (
				"You create compact derivatives of finished AI roleplay character cards. "
				+ "Compress only the supplied fields toward the requested whole-card token budget. "
				+ "Return strict JSON only and never claim to have changed the source card."
			)
		},
		{
			"role": "user",
			"content": "REQUIRED JSON SHAPE:\n%s\n\nCOMPRESSION INPUT:\n%s" % [
				JSON.stringify({"summary": "brief compression note", "fields": schema_fields}, "  "),
				JSON.stringify(context, "  ")
			]
		}
	]
	return {
		"ok": true,
		"messages": messages,
		"source_hash": source_content_hash(project, character_id),
		"requested_paths": authored_fields.keys(),
		"options": normalise_options(options)
	}


static func validate_result(
	project: Dictionary,
	character_id: String,
	raw_result: Variant,
	options: Dictionary
) -> Dictionary:
	if not raw_result is Dictionary:
		return {"ok": false, "error": "Compact generation did not return a JSON object."}
	var fields_value: Variant = (raw_result as Dictionary).get("fields", {})
	if not fields_value is Dictionary:
		return {"ok": false, "error": "Compact generation omitted its field replacements."}
	var source := CCFStorageService.get_character(project, character_id)
	if source.is_empty():
		return {"ok": false, "error": "The source character is no longer available."}
	var candidate := build_candidate(source, options)
	var requested := build_request(project, character_id, options)
	for path_value in requested.get("requested_paths", []):
		var path := str(path_value)
		if not (fields_value as Dictionary).has(path):
			return {"ok": false, "error": "Compact generation omitted %s." % path}
		var proposed: Variant = (fields_value as Dictionary).get(path)
		if not proposed is String:
			return {"ok": false, "error": "Compact generation returned a non-text value for %s." % path}
		CCFStorageService.set_value_at_path(candidate, path, str(proposed).strip_edges())
	return {
		"ok": true,
		"candidate": candidate,
		"summary": str((raw_result as Dictionary).get("summary", "")).strip_edges(),
		"source_hash": str(requested.get("source_hash", "")),
		"before_tokens": estimated_tokens(project, character_id),
		"after_tokens": estimate_record_tokens(candidate),
		"options": normalise_options(options)
	}


static func build_candidate(source: Dictionary, options: Dictionary) -> Dictionary:
	var candidate := source.duplicate(true)
	candidate.erase(CCFRevisionServiceV0181.HISTORY_KEY)
	candidate.erase("ai_review_v0183")
	candidate.erase(CCFRevisionServiceV0181.LINEAGE_KEY)
	var workspace: Dictionary = candidate.get("workspace", {}).duplicate(true)
	workspace.erase(CCFFrontPorchSyncServiceV0185.BINDING_KEY)
	candidate["workspace"] = workspace
	if not bool(options.get("preserve_lorebook", true)):
		CCFStorageService.set_value_at_path(candidate, "character.character_book", {})
	if not bool(options.get("preserve_greetings", true)):
		CCFStorageService.set_value_at_path(candidate, "character.alternate_greetings", [])
	if not bool(options.get("preserve_examples", true)):
		CCFStorageService.set_value_at_path(candidate, "character.example_dialogue", "")
	if not bool(options.get("preserve_tags", true)):
		CCFStorageService.set_value_at_path(candidate, "metadata.tags", [])
	_apply_front_porch_preservation(candidate, options)
	if not bool(options.get("preserve_image_prompt", true)):
		var generation: Dictionary = candidate.get("generation", {}).duplicate(true)
		generation.erase("image_style_default_v0169")
		generation.erase("image_prompt")
		generation.erase("image_prompt_material")
		candidate["generation"] = generation
	return candidate


static func _apply_front_porch_preservation(
	candidate: Dictionary, options: Dictionary
) -> void:
	var extensions_value: Variant = CCFStorageService.get_value_at_path(
		candidate, "character.card_extensions", {}
	)
	if not extensions_value is Dictionary:
		return
	var extensions := (extensions_value as Dictionary).duplicate(true)
	var front_porch_value: Variant = extensions.get("front_porch", {})
	if not front_porch_value is Dictionary:
		return
	var front_porch := (front_porch_value as Dictionary).duplicate(true)
	var realism_value: Variant = front_porch.get("realism_engine", {})
	var realism: Dictionary = (
		(realism_value as Dictionary).duplicate(true)
		if realism_value is Dictionary
		else {}
	)
	var intimate_value: Variant = realism.get("intimate_preferences", null)
	var keep_front_porch := bool(options.get("preserve_front_porch", true))
	var keep_adult := bool(options.get("preserve_adult_traits", true))
	if keep_front_porch:
		if not keep_adult:
			realism.erase("intimate_preferences")
			front_porch["realism_engine"] = realism
		extensions["front_porch"] = front_porch
	else:
		extensions.erase("front_porch")
		if keep_adult and intimate_value != null:
			extensions["front_porch"] = {
				"version": str(front_porch.get("version", "2.5")),
				"realism_engine": {
					"intimate_preferences": (
						intimate_value.duplicate(true)
						if intimate_value is Dictionary or intimate_value is Array
						else intimate_value
					)
				}
			}
	CCFStorageService.set_value_at_path(
		candidate, "character.card_extensions", extensions
	)


static func create_derivative(
	project: Dictionary,
	source_character_id: String,
	candidate: Dictionary,
	requested_name: String,
	options: Dictionary,
	request_metadata: Dictionary,
	expected_source_hash: String
) -> Dictionary:
	var current_hash := source_content_hash(project, source_character_id)
	if current_hash.is_empty() or current_hash != expected_source_hash:
		return {"ok": false, "stale": true, "error": "The source character changed after the preview was generated. Generate a fresh compact preview."}
	if candidate.is_empty():
		return {"ok": false, "error": "No compact preview is available."}
	var source := CCFStorageService.get_character(project, source_character_id)
	var derivative := candidate.duplicate(true)
	var new_id := Crypto.new().generate_random_bytes(16).hex_encode()
	var now_text := Time.get_datetime_string_from_system(true)
	var clean_name := requested_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "%s (Compact)" % CCFStorageService.character_display_name(source)
	derivative["character_id"] = new_id
	derivative["created_at"] = now_text
	derivative["updated_at"] = now_text
	derivative.erase(CCFRevisionServiceV0181.HISTORY_KEY)
	derivative.erase("ai_review_v0183")
	var metadata: Dictionary = derivative.get("metadata", {}).duplicate(true)
	metadata["name"] = clean_name
	derivative["metadata"] = metadata
	var character_data: Dictionary = derivative.get("character", {}).duplicate(true)
	character_data["name"] = clean_name
	derivative["character"] = character_data
	var latest_revision_id := ""
	var revisions := CCFRevisionServiceV0181.list_revisions(source)
	if not revisions.is_empty():
		latest_revision_id = str(revisions[-1].get("revision_id", ""))
	var lineage := {
		"source_project_id": str(project.get("project_id", "")),
		"source_character_id": source_character_id,
		"source_revision_id": latest_revision_id,
		"source_content_hash": expected_source_hash,
		"source_hash_version": SOURCE_HASH_VERSION,
		"derivation_kind": "compact_lite",
		"created_at": now_text
	}
	derivative[CCFRevisionServiceV0181.LINEAGE_KEY] = lineage
	derivative[PROVENANCE_KEY] = {
		"format_version": 1,
		"created_at": now_text,
		"model": str(request_metadata.get("model", "")),
		"profile_name": str(request_metadata.get("profile_name", "")),
		"profile_id": str(request_metadata.get("profile_id", "")),
		"compression_level": str(options.get("compression_level", "balanced")),
		"target_tokens": int(options.get("target_tokens", 0)),
		"estimated_result_tokens": estimate_record_tokens(derivative),
		"preservation": normalise_options(options),
		"source_content_hash": expected_source_hash
	}
	CCFRevisionServiceV0181.create_checkpoint(
		derivative,
		"Compact derivative created",
		"Initial recovery point for an independent compact/lite derivative.",
		"compact_derivative",
		lineage,
		true
	)
	var updated := project.duplicate(true)
	var characters: Array = updated.get("characters", []).duplicate(true)
	characters.append(derivative)
	updated["characters"] = characters
	return {"ok": true, "project": updated, "character_id": new_id, "character": derivative}


static func comparison_rows(source: Dictionary, candidate: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for field in COMPRESSIBLE_FIELDS:
		var path := str(field.get("path", ""))
		rows.append({
			"path": path,
			"label": str(field.get("label", path)),
			"source": CCFStorageService.get_value_at_path(source, path, ""),
			"candidate": CCFStorageService.get_value_at_path(candidate, path, "")
		})
	return rows


static func estimate_record_tokens(record: Dictionary) -> int:
	var parts := PackedStringArray()
	for field in COMPRESSIBLE_FIELDS:
		parts.append(str(CCFStorageService.get_value_at_path(record, str(field.get("path", "")), "")))
	parts.append(JSON.stringify(CCFStorageService.get_value_at_path(record, "character.alternate_greetings", [])))
	parts.append(JSON.stringify(CCFStorageService.get_value_at_path(record, "character.character_book", {})))
	return CCFCardInspectionServiceV0182.estimate_tokens("\n".join(parts))


static func normalise_options(options: Dictionary) -> Dictionary:
	var level_id := str(options.get("compression_level", "balanced"))
	if not level_id in ["gentle", "balanced", "aggressive", "extreme"]:
		level_id = "balanced"
	return {
		"compression_level": level_id,
		"target_tokens": clampi(int(options.get("target_tokens", 1000)), 128, 1000000),
		"preserve_lorebook": bool(options.get("preserve_lorebook", true)),
		"preserve_greetings": bool(options.get("preserve_greetings", true)),
		"preserve_examples": bool(options.get("preserve_examples", true)),
		"preserve_front_porch": bool(options.get("preserve_front_porch", true)),
		"preserve_adult_traits": bool(options.get("preserve_adult_traits", true)),
		"preserve_tags": bool(options.get("preserve_tags", true)),
		"preserve_image_prompt": bool(options.get("preserve_image_prompt", true))
	}


static func preservation_summary(options: Dictionary) -> Array[String]:
	var labels: Array[String] = []
	for entry in [
		["preserve_lorebook", "Lorebook material"],
		["preserve_greetings", "Alternative greetings"],
		["preserve_examples", "Example dialogue"],
		["preserve_front_porch", "Front Porch extension/state fields"],
		["preserve_adult_traits", "Adult traits"],
		["preserve_tags", "Tags"],
		["preserve_image_prompt", "Image-prompt material"]
	]:
		if bool(options.get(str(entry[0]), true)):
			labels.append(str(entry[1]))
	return labels


static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		var keys: Array = (value as Dictionary).keys()
		keys.sort_custom(func(left: Variant, right: Variant) -> bool: return str(left) < str(right))
		for key in keys:
			result[str(key)] = _canonical((value as Dictionary).get(key))
		return result
	if value is Array:
		var result: Array = []
		for item in value as Array:
			result.append(_canonical(item))
		return result
	return value
