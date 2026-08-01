class_name CCFCharacterVariantServiceV01420
extends RefCounted

const VARIANT_FORMAT_VERSION := 1
const RECORD_TYPE := "linked_variant"
const WORKSPACE_CONTEXT_KEYS := [
	"project_id",
	"container_project_id",
	"shared_context",
	"project_metadata",
	"relationships",
	"project_characters",
	"project_attachments",
	"attachment_context_character_limit",
	"card_workflows"
]


static func is_variant(record: Dictionary) -> bool:
	return str(record.get("record_type", "")) == RECORD_TYPE and record.get("variant", {}) is Dictionary


static func create_variant(base_character: Dictionary, label: String = "Variant") -> Dictionary:
	var base_id := str(base_character.get("character_id", "")).strip_edges()
	if base_id.is_empty():
		return {}
	var now := Time.get_datetime_string_from_system(true)
	var clean_label := label.strip_edges()
	if clean_label.is_empty():
		clean_label = "Variant"
	var record := CCFStorageService.new_character_record(clean_label)
	record["record_type"] = RECORD_TYPE
	record["variant"] = {
		"format_version": VARIANT_FORMAT_VERSION,
		"base_character_id": base_id,
		"label": clean_label,
		"overrides": {},
		"created_at": now
	}
	# Linked variants deliberately avoid duplicating the base card/assets. The
	# full character is reconstructed only while editing or exporting.
	record["character"] = {"name": clean_label}
	record["assets"] = {}
	record["attachments"] = []
	return record


static func resolve_character(project: Dictionary, character_id: String) -> Dictionary:
	return _resolve_character(project, character_id, {})


static func _resolve_character(project: Dictionary, character_id: String, visited: Dictionary) -> Dictionary:
	if character_id.is_empty() or visited.has(character_id):
		return {}
	visited[character_id] = true
	var record := _find_character(project, character_id)
	if record.is_empty():
		return {}
	if not is_variant(record):
		return record.duplicate(true)
	var variant_data: Dictionary = record.get("variant", {})
	var base_id := str(variant_data.get("base_character_id", ""))
	var base := _resolve_character(project, base_id, visited)
	if base.is_empty():
		return {}
	var overrides_value: Variant = variant_data.get("overrides", {})
	var overrides: Dictionary = overrides_value if overrides_value is Dictionary else {}
	var resolved := _deep_merge(base, overrides)
	resolved["character_id"] = character_id
	resolved["record_type"] = RECORD_TYPE
	resolved["variant"] = variant_data.duplicate(true)
	var metadata: Dictionary = resolved.get("metadata", {}).duplicate(true)
	var label := str(variant_data.get("label", "Variant")).strip_edges()
	if not label.is_empty():
		metadata["name"] = label
		var card: Dictionary = resolved.get("character", {}).duplicate(true)
		var character_overrides: Variant = overrides.get("character", {})
		if not (character_overrides is Dictionary and (character_overrides as Dictionary).has("name")):
			card["name"] = label
		resolved["character"] = card
	resolved["metadata"] = metadata
	return resolved


static func workspace_document(project: Dictionary, variant_id: String) -> Dictionary:
	var resolved := resolve_character(project, variant_id)
	if resolved.is_empty():
		return {}
	var project_id := str(project.get("project_id", ""))
	resolved["container_project_id"] = project_id
	resolved["project_id"] = CCFStorageService.workspace_owner_id(project_id, variant_id)
	resolved["shared_context"] = project.get("shared_context", {}).duplicate(true)
	resolved["project_metadata"] = project.get("metadata", {}).duplicate(true)
	resolved["relationships"] = project.get("relationships", []).duplicate(true)
	resolved["project_attachments"] = project.get("attachments", []).duplicate(true)
	resolved["project_characters"] = CCFStorageService.project_character_summaries(project)
	resolved["card_workflows"] = project.get("card_workflows", []).duplicate(true)
	return resolved


static func update_variant_from_resolved(project: Dictionary, variant_id: String, edited_resolved: Dictionary) -> Dictionary:
	var record := _find_character(project, variant_id)
	if not is_variant(record):
		return {"ok": false, "error": "Character is not a linked variant."}
	var variant_data: Dictionary = record.get("variant", {}).duplicate(true)
	var base_id := str(variant_data.get("base_character_id", ""))
	var base := resolve_character(project, base_id)
	if base.is_empty():
		return {"ok": false, "error": "Linked variant base character could not be resolved."}
	var comparison := _strip_runtime_context(edited_resolved)
	var base_comparison := _strip_runtime_context(base)
	var diff := _deep_diff(base_comparison, comparison)
	variant_data["overrides"] = diff
	record["variant"] = variant_data
	var edited_metadata: Variant = comparison.get("metadata", {})
	if edited_metadata is Dictionary:
		var display_name := str((edited_metadata as Dictionary).get("name", "")).strip_edges()
		if not display_name.is_empty():
			variant_data["label"] = display_name
			record["variant"] = variant_data
			var sparse_metadata: Dictionary = record.get("metadata", {}).duplicate(true)
			sparse_metadata["name"] = display_name
			record["metadata"] = sparse_metadata
	if not _replace_character(project, variant_id, record):
		return {"ok": false, "error": "Linked variant could not be updated."}
	return {"ok": true, "override_count": count_leaf_overrides(diff), "overrides": diff}


static func materialize_variant(project: Dictionary, variant_id: String, keep_id: bool = true) -> Dictionary:
	var resolved := resolve_character(project, variant_id)
	if resolved.is_empty():
		return {}
	resolved.erase("record_type")
	resolved.erase("variant")
	if not keep_id:
		var fresh := CCFStorageService.new_character_record()
		resolved["character_id"] = str(fresh.get("character_id", ""))
	resolved["updated_at"] = Time.get_datetime_string_from_system(true)
	return resolved


static func project_with_materialized_character(project: Dictionary, character_id: String) -> Dictionary:
	var copy := project.duplicate(true)
	var raw := _find_character(project, character_id)
	if raw.is_empty() or not is_variant(raw):
		return copy
	var full := materialize_variant(project, character_id, true)
	if full.is_empty():
		return copy
	_replace_character(copy, character_id, full)
	return copy


static func convert_to_full_character(project: Dictionary, variant_id: String) -> Dictionary:
	var full := materialize_variant(project, variant_id, true)
	if full.is_empty():
		return {"ok": false, "error": "Linked variant could not be materialised."}
	if not _replace_character(project, variant_id, full):
		return {"ok": false, "error": "Linked variant could not be converted."}
	return {"ok": true, "character": full}


static func dependent_variant_ids(project: Dictionary, base_character_id: String) -> Array[String]:
	var result: Array[String] = []
	var characters_value: Variant = project.get("characters", [])
	if not characters_value is Array:
		return result
	for raw_character in characters_value:
		if not raw_character is Dictionary or not is_variant(raw_character):
			continue
		var variant_data: Dictionary = raw_character.get("variant", {})
		if str(variant_data.get("base_character_id", "")) == base_character_id:
			result.append(str(raw_character.get("character_id", "")))
	return result


static func count_leaf_overrides(value: Variant) -> int:
	if not value is Dictionary:
		return 1
	var total := 0
	for child in (value as Dictionary).values():
		if child is Dictionary:
			total += count_leaf_overrides(child)
		else:
			total += 1
	return total


static func _strip_runtime_context(source: Dictionary) -> Dictionary:
	var cleaned := source.duplicate(true)
	for key in WORKSPACE_CONTEXT_KEYS:
		cleaned.erase(key)
	for key in ["character_id", "record_type", "variant", "created_at", "updated_at"]:
		cleaned.erase(key)
	return cleaned


static func _deep_diff(base: Variant, edited: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not base is Dictionary or not edited is Dictionary:
		return result
	var base_dict: Dictionary = base
	var edited_dict: Dictionary = edited
	for raw_key in edited_dict.keys():
		var key := str(raw_key)
		var edited_value: Variant = edited_dict.get(raw_key)
		if not base_dict.has(raw_key):
			result[key] = edited_value.duplicate(true) if edited_value is Dictionary or edited_value is Array else edited_value
			continue
		var base_value: Variant = base_dict.get(raw_key)
		if base_value is Dictionary and edited_value is Dictionary:
			var nested := _deep_diff(base_value, edited_value)
			if not nested.is_empty():
				result[key] = nested
		elif base_value != edited_value:
			result[key] = edited_value.duplicate(true) if edited_value is Array else edited_value
	return result


static func _deep_merge(base: Dictionary, overrides: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for raw_key in overrides.keys():
		var key := str(raw_key)
		var override_value: Variant = overrides.get(raw_key)
		if result.get(key) is Dictionary and override_value is Dictionary:
			result[key] = _deep_merge(result.get(key), override_value)
		else:
			result[key] = override_value.duplicate(true) if override_value is Dictionary or override_value is Array else override_value
	return result


static func _find_character(project: Dictionary, character_id: String) -> Dictionary:
	var characters_value: Variant = project.get("characters", [])
	if not characters_value is Array:
		return {}
	for raw_character in characters_value:
		if raw_character is Dictionary and str(raw_character.get("character_id", "")) == character_id:
			return (raw_character as Dictionary).duplicate(true)
	return {}


static func _replace_character(project: Dictionary, character_id: String, replacement: Dictionary) -> bool:
	var characters_value: Variant = project.get("characters", [])
	if not characters_value is Array:
		return false
	var characters: Array = characters_value.duplicate(true)
	for index in range(characters.size()):
		var raw_character: Variant = characters[index]
		if raw_character is Dictionary and str(raw_character.get("character_id", "")) == character_id:
			characters[index] = replacement.duplicate(true)
			project["characters"] = characters
			return true
	return false
