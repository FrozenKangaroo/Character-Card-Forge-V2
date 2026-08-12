class_name CCFImageLocalModelProfileServiceV0165
extends RefCounted

const FORMAT_VERSION := 1
const PROFILE_KEY := "local_model_profiles_v0165"
const FAMILY_CATALOG_PATH := "res://data/image_local_model_families_v1.json"


static func family_catalog() -> Dictionary:
	if not FileAccess.file_exists(FAMILY_CATALOG_PATH):
		return {"format_version": FORMAT_VERSION, "families": []}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FAMILY_CATALOG_PATH))
	if not parsed is Dictionary:
		return {"format_version": FORMAT_VERSION, "families": []}
	var result: Dictionary = parsed.duplicate(true)
	if not result.get("families", []) is Array:
		result["families"] = []
	return result


static func family_definition(family_id: String) -> Dictionary:
	var clean_id := family_id.strip_edges()
	for raw_family in family_catalog().get("families", []):
		if raw_family is Dictionary and str(raw_family.get("id", "")).strip_edges() == clean_id:
			return (raw_family as Dictionary).duplicate(true)
	return {}


static func checkpoint_profile(profile: Dictionary, checkpoint_id: String) -> Dictionary:
	var clean_id := checkpoint_id.strip_edges()
	if clean_id.is_empty():
		return _empty_checkpoint_profile("")
	var stored: Variant = profile.get(PROFILE_KEY, {})
	if stored is Dictionary:
		var found: Variant = stored.get(clean_id, {})
		if found is Dictionary:
			return _normalise_checkpoint_profile(clean_id, found)
	return _empty_checkpoint_profile(clean_id)


static func store_checkpoint_profile(
	settings: Dictionary,
	profile_id: String,
	checkpoint_id: String,
	checkpoint_profile_value: Dictionary
) -> Dictionary:
	var clean_profile_id := profile_id.strip_edges()
	var clean_checkpoint_id := checkpoint_id.strip_edges()
	if clean_profile_id.is_empty():
		return {"ok": false, "error": "No Image provider profile was selected."}
	if clean_checkpoint_id.is_empty():
		return {"ok": false, "error": "No local checkpoint/model is selected."}
	var updated_settings := settings.duplicate(true)
	var image_profile := CCFSettingsService.image_profile_by_id(updated_settings, clean_profile_id).duplicate(true)
	if image_profile.is_empty():
		return {"ok": false, "error": "The selected Image provider profile no longer exists."}
	if CCFSettingsService.image_backend(image_profile) != CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111:
		return {"ok": false, "error": "Local checkpoint profiles only apply to Forge / Automatic1111 Image profiles."}
	var stored_profiles: Dictionary = (
		image_profile.get(PROFILE_KEY, {}).duplicate(true)
		if image_profile.get(PROFILE_KEY, {}) is Dictionary
		else {}
	)
	stored_profiles[clean_checkpoint_id] = _normalise_checkpoint_profile(
		clean_checkpoint_id, checkpoint_profile_value
	)
	image_profile[PROFILE_KEY] = stored_profiles
	CCFSettingsService.replace_image_profile_by_id(updated_settings, clean_profile_id, image_profile)
	var save_result := CCFSettingsService.save_settings(updated_settings)
	if not bool(save_result.get("ok", false)):
		return save_result
	return {
		"ok": true,
		"settings": CCFSettingsService.load_settings(),
		"checkpoint_profile": stored_profiles[clean_checkpoint_id]
	}


static func clear_checkpoint_profile(
	settings: Dictionary,
	profile_id: String,
	checkpoint_id: String
) -> Dictionary:
	var clean_profile_id := profile_id.strip_edges()
	var clean_checkpoint_id := checkpoint_id.strip_edges()
	var updated_settings := settings.duplicate(true)
	var image_profile := CCFSettingsService.image_profile_by_id(updated_settings, clean_profile_id).duplicate(true)
	if image_profile.is_empty():
		return {"ok": false, "error": "The selected Image provider profile no longer exists."}
	var stored_profiles: Dictionary = (
		image_profile.get(PROFILE_KEY, {}).duplicate(true)
		if image_profile.get(PROFILE_KEY, {}) is Dictionary
		else {}
	)
	stored_profiles.erase(clean_checkpoint_id)
	image_profile[PROFILE_KEY] = stored_profiles
	CCFSettingsService.replace_image_profile_by_id(updated_settings, clean_profile_id, image_profile)
	var save_result := CCFSettingsService.save_settings(updated_settings)
	if not bool(save_result.get("ok", false)):
		return save_result
	return {"ok": true, "settings": CCFSettingsService.load_settings()}


static func apply_to_capabilities(
	capability_document: Dictionary,
	checkpoint_profile_value: Dictionary
) -> Dictionary:
	var result := capability_document.duplicate(true)
	var local_profile := _normalise_checkpoint_profile(
		str(result.get("model_id", checkpoint_profile_value.get("checkpoint_id", ""))),
		checkpoint_profile_value
	)
	var family_id := str(local_profile.get("family_id", "generic"))
	var family := family_definition(family_id)
	result["local_model_profile_v0165"] = local_profile.duplicate(true)
	result["model_family"] = family_id
	result["model_family_label"] = str(family.get("name", family_id))
	result["model_family_defaults"] = (
		family.get("preferred_defaults", {}).duplicate(true)
		if family.get("preferred_defaults", {}) is Dictionary
		else {}
	)
	var overrides: Dictionary = (
		local_profile.get("capability_overrides", {})
		if local_profile.get("capability_overrides", {}) is Dictionary
		else {}
	)
	if not overrides.is_empty():
		result = CCFImageModelCapabilityServiceV0161.apply_user_overrides(result, overrides)
	return result


static func effective_defaults(checkpoint_profile_value: Dictionary) -> Dictionary:
	var profile_value := _normalise_checkpoint_profile(
		str(checkpoint_profile_value.get("checkpoint_id", "")), checkpoint_profile_value
	)
	var family := family_definition(str(profile_value.get("family_id", "generic")))
	var defaults: Dictionary = (
		family.get("preferred_defaults", {}).duplicate(true)
		if family.get("preferred_defaults", {}) is Dictionary
		else {}
	)
	var checkpoint_defaults: Dictionary = (
		profile_value.get("preferred_defaults", {})
		if profile_value.get("preferred_defaults", {}) is Dictionary
		else {}
	)
	defaults.merge(checkpoint_defaults, true)
	return defaults


static func _empty_checkpoint_profile(checkpoint_id: String) -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"checkpoint_id": checkpoint_id,
		"family_id": "generic",
		"notes": "",
		"preferred_defaults": {},
		"capability_overrides": {
			"operations": {},
			"parameters": {}
		}
	}


static func _normalise_checkpoint_profile(checkpoint_id: String, raw_value: Variant) -> Dictionary:
	var source: Dictionary = raw_value if raw_value is Dictionary else {}
	var result := _empty_checkpoint_profile(checkpoint_id)
	result["family_id"] = str(source.get("family_id", "generic")).strip_edges()
	if family_definition(str(result["family_id"])).is_empty():
		result["family_id"] = "generic"
	result["notes"] = str(source.get("notes", ""))
	result["preferred_defaults"] = (
		source.get("preferred_defaults", {}).duplicate(true)
		if source.get("preferred_defaults", {}) is Dictionary
		else {}
	)
	result["capability_overrides"] = (
		source.get("capability_overrides", {}).duplicate(true)
		if source.get("capability_overrides", {}) is Dictionary
		else {"operations": {}, "parameters": {}}
	)
	if not (result["capability_overrides"] as Dictionary).get("operations", {}) is Dictionary:
		(result["capability_overrides"] as Dictionary)["operations"] = {}
	if not (result["capability_overrides"] as Dictionary).get("parameters", {}) is Dictionary:
		(result["capability_overrides"] as Dictionary)["parameters"] = {}
	return result
