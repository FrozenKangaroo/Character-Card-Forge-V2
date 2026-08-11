class_name CCFImageCapabilityCacheServiceV0161
extends RefCounted

const CACHE_KEY := "normalized_image_capabilities"
const CACHE_FORMAT_VERSION := 1


static func capabilities_from_profile(profile: Dictionary) -> Dictionary:
	var stored: Variant = profile.get(CACHE_KEY, {})
	if stored is Dictionary and not stored.is_empty():
		return _normalise_document(stored)
	var legacy := CCFImageCapabilityCacheServiceV01528.capabilities_from_profile(profile)
	return CCFImageModelCapabilityServiceV0161.normalise_discovery(profile, legacy)


static func store_for_profile(
	settings: Dictionary,
	profile_id: String,
	raw_capabilities: Dictionary,
	model_id: String = ""
) -> Dictionary:
	var clean_profile_id := profile_id.strip_edges()
	if clean_profile_id.is_empty():
		return {"ok": false, "error": "No Image provider profile was selected."}
	var updated_settings := settings.duplicate(true)
	var profile := CCFSettingsService.image_profile_by_id(updated_settings, clean_profile_id).duplicate(true)
	if profile.is_empty():
		return {"ok": false, "error": "The selected Image provider profile no longer exists."}
	var normalized := CCFImageModelCapabilityServiceV0161.normalise_discovery(
		profile,
		raw_capabilities,
		model_id
	)
	profile[CACHE_KEY] = _normalise_document(normalized)
	CCFSettingsService.replace_image_profile_by_id(updated_settings, clean_profile_id, profile)
	var save_result := CCFSettingsService.save_settings(updated_settings)
	if not bool(save_result.get("ok", false)):
		return save_result
	return {
		"ok": true,
		"settings": CCFSettingsService.load_settings(),
		"capabilities": profile[CACHE_KEY]
	}


static func store_provider_model_for_profile(
	settings: Dictionary,
	profile_id: String,
	model_record: Dictionary
) -> Dictionary:
	var clean_profile_id := profile_id.strip_edges()
	if clean_profile_id.is_empty():
		return {"ok": false, "error": "No Image provider profile was selected."}
	var updated_settings := settings.duplicate(true)
	var profile := CCFSettingsService.image_profile_by_id(updated_settings, clean_profile_id).duplicate(true)
	if profile.is_empty():
		return {"ok": false, "error": "The selected Image provider profile no longer exists."}
	var normalized := CCFImageModelCapabilityServiceV0161.normalise_provider_model_record(profile, model_record)
	profile[CACHE_KEY] = _normalise_document(normalized)
	CCFSettingsService.replace_image_profile_by_id(updated_settings, clean_profile_id, profile)
	var save_result := CCFSettingsService.save_settings(updated_settings)
	if not bool(save_result.get("ok", false)):
		return save_result
	return {
		"ok": true,
		"settings": CCFSettingsService.load_settings(),
		"capabilities": profile[CACHE_KEY]
	}


static func with_user_overrides(profile: Dictionary, overrides: Dictionary) -> Dictionary:
	return CCFImageModelCapabilityServiceV0161.apply_user_overrides(
		capabilities_from_profile(profile),
		overrides
	)


static func _normalise_document(raw_value: Variant) -> Dictionary:
	var source: Dictionary = raw_value if raw_value is Dictionary else {}
	var result := source.duplicate(true)
	result["format_version"] = CACHE_FORMAT_VERSION
	if not result.get("operations", {}) is Dictionary:
		result["operations"] = {}
	if not result.get("parameters", {}) is Dictionary:
		result["parameters"] = {}
	if not result.get("models", []) is Array:
		result["models"] = []
	if not result.get("discovery", {}) is Dictionary:
		result["discovery"] = {
			"source": CCFImageModelCapabilityServiceV0161.SOURCE_INFERRED,
			"confidence": CCFImageModelCapabilityServiceV0161.CONFIDENCE_INFERRED,
			"note": "",
			"discovered_at": ""
		}
	return result
