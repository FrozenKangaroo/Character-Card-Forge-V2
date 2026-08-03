class_name CCFImageCapabilityCacheServiceV01528
extends RefCounted

const CACHE_KEY := "discovered_capabilities"
const CACHE_FORMAT_VERSION := 1


static func capabilities_from_profile(profile: Dictionary) -> Dictionary:
	var raw_value: Variant = profile.get(CACHE_KEY, {})
	return normalise_capabilities(raw_value)


static func store_for_profile(
	settings: Dictionary, profile_id: String, capabilities: Dictionary
) -> Dictionary:
	var clean_profile_id := profile_id.strip_edges()
	if clean_profile_id.is_empty():
		return {"ok": false, "error": "No Image provider profile was selected."}
	var updated_settings := settings.duplicate(true)
	var profile := CCFSettingsService.image_profile_by_id(
		updated_settings, clean_profile_id
	).duplicate(true)
	profile[CACHE_KEY] = normalise_capabilities(capabilities)
	CCFSettingsService.replace_image_profile_by_id(
		updated_settings, clean_profile_id, profile
	)
	var save_result := CCFSettingsService.save_settings(updated_settings)
	if not bool(save_result.get("ok", false)):
		return save_result
	return {
		"ok": true,
		"settings": CCFSettingsService.load_settings(),
		"capabilities": profile[CACHE_KEY]
	}


static func normalise_capabilities(raw_value: Variant) -> Dictionary:
	var source: Dictionary = raw_value if raw_value is Dictionary else {}
	return {
		"format_version": CACHE_FORMAT_VERSION,
		"backend": str(source.get("backend", "")).strip_edges(),
		"backend_label": str(source.get("backend_label", "")).strip_edges(),
		"models": _normalise_string_array(source.get("models", [])),
		"samplers": _normalise_string_array(source.get("samplers", [])),
		"supports_negative_prompt": bool(source.get("supports_negative_prompt", false)),
		"supports_seed": bool(source.get("supports_seed", false)),
		"supports_sampler": bool(source.get("supports_sampler", false)),
		"supports_steps": bool(source.get("supports_steps", false)),
		"supports_cfg_scale": bool(source.get("supports_cfg_scale", false)),
		"supports_batch": bool(source.get("supports_batch", true)),
		"discovery_note": str(source.get("discovery_note", "")).strip_edges(),
		"discovered_at": str(
			source.get("discovered_at", Time.get_datetime_string_from_system(true))
		).strip_edges()
	}


static func _normalise_string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not raw_value is Array:
		return result
	for raw_entry in raw_value:
		var entry := str(raw_entry).strip_edges()
		if not entry.is_empty() and entry not in result:
			result.append(entry)
	result.sort()
	return result
