class_name CCFImageProviderSettingsViewV01528
extends "res://scripts/ui/image_provider_settings_view.gd"


func _load_selected_profile() -> void:
	super._load_selected_profile()
	if _profile_selector == null or _profile_selector.selected < 0:
		return
	var profile := CCFSettingsService.image_profile_by_id(
		_settings, str(_profile_selector.get_selected_metadata())
	)
	var cached := CCFImageCapabilityCacheServiceV01528.capabilities_from_profile(
		profile
	)
	var model_count := int(cached.get("models", []).size())
	var sampler_count := int(cached.get("samplers", []).size())
	if model_count > 0 or sampler_count > 0:
		_status.text += " Cached discovery: %d model/checkpoint(s), %d sampler(s)." % [
			model_count, sampler_count
		]


func _on_capabilities_loaded(capabilities: Dictionary) -> void:
	if _profile_selector == null or _profile_selector.selected < 0:
		_status.text = "Discovery completed, but no Image provider profile is selected to receive the result."
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	var cache_result := CCFImageCapabilityCacheServiceV01528.store_for_profile(
		_settings, profile_id, capabilities
	)
	if not bool(cache_result.get("ok", false)):
		_status.text = "Connection successful, but discovered models/samplers could not be saved: %s" % str(
			cache_result.get("error", "Unknown settings error")
		)
		return
	_settings = cache_result.get("settings", _settings).duplicate(true)
	var cached: Dictionary = cache_result.get("capabilities", {})
	_status.text = "Connection successful: %d model/checkpoint(s), %d sampler(s) discovered and saved for Image Studio." % [
		int(cached.get("models", []).size()),
		int(cached.get("samplers", []).size())
	]
	settings_saved.emit(_settings.duplicate(true))
