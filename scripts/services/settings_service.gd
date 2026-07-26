class_name CCFSettingsService
extends RefCounted

const SETTINGS_FILE := CCFStorageService.SETTINGS_DIR + "/app_settings.json"
const SETTINGS_FORMAT_VERSION := 4
const ROLE_TEXT := "text"
const ROLE_VISION := "vision"
const ROLE_IMAGE := "image"


static func default_settings() -> Dictionary:
	return {
		"format_version": SETTINGS_FORMAT_VERSION,
		"active_api_profile_id": "default",
		"provider_roles": {
			"text_profile_id": "default",
			"vision_profile_id": "default",
			"image_profile_id": "default"
		},
		"api_profiles": [_default_profile()],
		"generation": {
			"include_existing_fields": true,
			"retry_count": 1,
			"default_idea_count": 6,
			"attachment_context_character_limit": 24000,
			"default_image_size": "1024x1024",
			"default_image_prompt_style": "auto"
		},
		"ui": {"last_view": "dashboard"}
	}


static func load_settings() -> Dictionary:
	CCFStorageService.ensure_directories()
	if not FileAccess.file_exists(SETTINGS_FILE):
		var defaults := default_settings()
		save_settings(defaults)
		return defaults
	var file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file == null:
		return default_settings()
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return default_settings()
	return _normalise(parsed)


static func save_settings(settings: Dictionary) -> Dictionary:
	CCFStorageService.ensure_directories()
	var file := FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not save application settings."}
	file.store_string(JSON.stringify(_normalise(settings), "  "))
	file.close()
	return {"ok": true}


static func active_profile(settings: Dictionary) -> Dictionary:
	return profile_by_id(settings, str(settings.get("active_api_profile_id", "default")))


static func profile_for_role(settings: Dictionary, role: String) -> Dictionary:
	var role_key := "%s_profile_id" % role
	var provider_roles = settings.get("provider_roles", {})
	var profile_id := ""
	if provider_roles is Dictionary:
		profile_id = str(provider_roles.get(role_key, "")).strip_edges()
	if profile_id.is_empty():
		profile_id = str(settings.get("active_api_profile_id", "default"))
	return profile_by_id(settings, profile_id)


static func role_profile_id(settings: Dictionary, role: String) -> String:
	return str(profile_for_role(settings, role).get("id", "default"))


static func set_role_profile(settings: Dictionary, role: String, profile_id: String) -> void:
	var resolved := profile_by_id(settings, profile_id)
	var provider_roles: Dictionary = settings.get("provider_roles", {}).duplicate(true)
	provider_roles["%s_profile_id" % role] = str(resolved.get("id", "default"))
	settings["provider_roles"] = provider_roles


static func profile_by_id(settings: Dictionary, profile_id: String) -> Dictionary:
	var profiles = settings.get("api_profiles", [])
	if profiles is Array:
		for profile in profiles:
			if profile is Dictionary and str(profile.get("id", "")) == profile_id:
				return _normalise_profile(profile)
		if not profiles.is_empty() and profiles[0] is Dictionary:
			return _normalise_profile(profiles[0])
	return _default_profile()


static func replace_active_profile(settings: Dictionary, profile: Dictionary) -> void:
	var active_id := str(settings.get("active_api_profile_id", "default"))
	replace_profile_by_id(settings, active_id, profile)


static func replace_profile_by_id(settings: Dictionary, profile_id: String, profile: Dictionary) -> void:
	var profiles: Array = settings.get("api_profiles", []).duplicate(true)
	var replacement := _normalise_profile(profile)
	replacement["id"] = profile_id
	var replaced := false
	for index in range(profiles.size()):
		if profiles[index] is Dictionary and str(profiles[index].get("id", "")) == profile_id:
			profiles[index] = replacement
			replaced = true
			break
	if not replaced:
		profiles.append(replacement)
	settings["api_profiles"] = profiles


static func create_profile(settings: Dictionary, display_name := "New Profile") -> Dictionary:
	var profile_id := _new_profile_id()
	var profile := _default_profile()
	profile["id"] = profile_id
	profile["name"] = display_name
	var profiles: Array = settings.get("api_profiles", []).duplicate(true)
	profiles.append(profile)
	settings["api_profiles"] = profiles
	settings["active_api_profile_id"] = profile_id
	set_role_profile(settings, ROLE_TEXT, profile_id)
	return profile


static func duplicate_active_profile(settings: Dictionary) -> Dictionary:
	var source := active_profile(settings).duplicate(true)
	var profile_id := _new_profile_id()
	source["id"] = profile_id
	source["name"] = "%s Copy" % str(source.get("name", "Profile"))
	var profiles: Array = settings.get("api_profiles", []).duplicate(true)
	profiles.append(source)
	settings["api_profiles"] = profiles
	settings["active_api_profile_id"] = profile_id
	set_role_profile(settings, ROLE_TEXT, profile_id)
	return source


static func delete_active_profile(settings: Dictionary) -> Dictionary:
	var profiles: Array = settings.get("api_profiles", []).duplicate(true)
	if profiles.size() <= 1:
		return {"ok": false, "error": "At least one API profile must remain."}
	var active_id := str(settings.get("active_api_profile_id", ""))
	var filtered: Array = []
	for profile in profiles:
		if profile is Dictionary and str(profile.get("id", "")) != active_id:
			filtered.append(profile)
	if filtered.is_empty():
		return {"ok": false, "error": "Could not remove the active profile."}
	settings["api_profiles"] = filtered
	var fallback_id := str(filtered[0].get("id", "default"))
	settings["active_api_profile_id"] = fallback_id
	var provider_roles: Dictionary = settings.get("provider_roles", {}).duplicate(true)
	for role_key in ["text_profile_id", "vision_profile_id", "image_profile_id"]:
		if str(provider_roles.get(role_key, "")) == active_id:
			provider_roles[role_key] = fallback_id
	settings["provider_roles"] = provider_roles
	return {"ok": true}


static func _normalise(settings: Dictionary) -> Dictionary:
	var defaults := default_settings()
	var result := defaults.duplicate(true)
	var incoming_format := int(settings.get("format_version", 2))

	result["format_version"] = SETTINGS_FORMAT_VERSION
	result["active_api_profile_id"] = str(
		settings.get("active_api_profile_id", defaults["active_api_profile_id"])
	)

	var profiles: Array = []
	var incoming_profiles = settings.get("api_profiles", [])
	if incoming_profiles is Array:
		for profile in incoming_profiles:
			if profile is Dictionary:
				profiles.append(_normalise_profile(profile))
	if profiles.is_empty():
		profiles.append(_default_profile())
	result["api_profiles"] = profiles

	var active_exists := false
	for profile in profiles:
		if str(profile.get("id", "")) == str(result.get("active_api_profile_id", "")):
			active_exists = true
			break
	if not active_exists:
		result["active_api_profile_id"] = str(profiles[0].get("id", "default"))

	var provider_roles: Dictionary = defaults.get("provider_roles", {}).duplicate(true)
	var incoming_roles = settings.get("provider_roles", {})
	if incoming_roles is Dictionary:
		provider_roles.merge(incoming_roles, true)
	# Settings format v2 used one active profile for all work. v3 introduced
	# explicit text/vision assignments. v4 adds image generation without
	# disturbing choices already made for the earlier roles.
	if incoming_format < 3:
		provider_roles["text_profile_id"] = str(result.get("active_api_profile_id", "default"))
		provider_roles["vision_profile_id"] = str(result.get("active_api_profile_id", "default"))
	if incoming_format < 4:
		provider_roles["image_profile_id"] = str(result.get("active_api_profile_id", "default"))
	for role_key in ["text_profile_id", "vision_profile_id", "image_profile_id"]:
		var requested_id := str(provider_roles.get(role_key, "")).strip_edges()
		if not _profile_id_exists(profiles, requested_id):
			provider_roles[role_key] = str(result.get("active_api_profile_id", "default"))
	result["provider_roles"] = provider_roles

	var generation_settings: Dictionary = defaults.get("generation", {}).duplicate(true)
	var incoming_generation = settings.get("generation", {})
	if incoming_generation is Dictionary:
		generation_settings.merge(incoming_generation, true)
	generation_settings["retry_count"] = clampi(
		int(generation_settings.get("retry_count", 1)), 0, 5
	)
	generation_settings["default_idea_count"] = clampi(
		int(generation_settings.get("default_idea_count", 6)), 1, 12
	)
	generation_settings["attachment_context_character_limit"] = clampi(
		int(generation_settings.get("attachment_context_character_limit", 24000)),
		2000,
		120000
	)
	var image_size_text := str(generation_settings.get("default_image_size", "1024x1024")).strip_edges()
	generation_settings["default_image_size"] = (
		image_size_text if not image_size_text.is_empty() else "1024x1024"
	)
	var image_prompt_style := str(
		generation_settings.get("default_image_prompt_style", "auto")
	).strip_edges().to_lower()
	if not image_prompt_style in ["auto", "natural", "stable_diffusion"]:
		image_prompt_style = "auto"
	generation_settings["default_image_prompt_style"] = image_prompt_style
	result["generation"] = generation_settings

	var ui_settings: Dictionary = defaults.get("ui", {}).duplicate(true)
	var incoming_ui = settings.get("ui", {})
	if incoming_ui is Dictionary:
		ui_settings.merge(incoming_ui, true)
	result["ui"] = ui_settings
	return result


static func _normalise_profile(profile: Dictionary) -> Dictionary:
	var result := _default_profile()
	result.merge(profile, true)
	var profile_id := str(result.get("id", "")).strip_edges()
	if profile_id.is_empty():
		profile_id = _new_profile_id()
	result["id"] = profile_id
	var display_name := str(result.get("name", "")).strip_edges()
	result["name"] = display_name if not display_name.is_empty() else "Profile"
	result["temperature"] = clampf(float(result.get("temperature", 0.8)), 0.0, 2.0)
	result["max_output_tokens"] = maxi(128, int(result.get("max_output_tokens", 6000)))
	result["vision_detail"] = str(result.get("vision_detail", "auto"))
	if not result["vision_detail"] in ["auto", "low", "high"]:
		result["vision_detail"] = "auto"
	return result


static func _default_profile() -> Dictionary:
	return {
		"id": "default",
		"name": "Default",
		"base_url": "http://127.0.0.1:1234/v1",
		"api_key": "",
		"model": "",
		"temperature": 0.8,
		"max_output_tokens": 6000,
		"vision_detail": "auto"
	}


static func _profile_id_exists(profiles: Array, profile_id: String) -> bool:
	for profile in profiles:
		if profile is Dictionary and str(profile.get("id", "")) == profile_id:
			return true
	return false


static func _new_profile_id() -> String:
	return "profile_%s_%s" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
