class_name CCFSettingsService
extends RefCounted

const SETTINGS_FILE := CCFStorageService.SETTINGS_DIR + "/app_settings.json"
const SETTINGS_FORMAT_VERSION := 9
const ROLE_TEXT := "text"
const ROLE_TEXT_FAST := "text_fast"
const ROLE_TEXT_DEEP := "text_deep"
const ROLE_TEXT_FALLBACK := "text_fallback"
const ROLE_VISION := "vision"
const ROLE_IMAGE := "image"
const TEXT_TASK_PRIMARY := "primary"
const TEXT_TASK_FAST := "fast"
const TEXT_TASK_DEEP := "deep"
const USE_PRIMARY_PROFILE_ID := "__use_primary__"
const PROFILE_KIND_AI := "ai"
const PROFILE_KIND_IMAGE := "image"
const IMAGE_BACKEND_OPENAI := "openai_compatible"
const IMAGE_BACKEND_AUTOMATIC1111 := "automatic1111"


static func default_settings() -> Dictionary:
	return {
		"format_version": SETTINGS_FORMAT_VERSION,
		"active_api_profile_id": "default",
		"provider_roles": {
			"text_profile_id": "default",
			"text_fast_profile_id": USE_PRIMARY_PROFILE_ID,
			"text_deep_profile_id": USE_PRIMARY_PROFILE_ID,
			"text_fallback_profile_id": USE_PRIMARY_PROFILE_ID,
			"vision_profile_id": "default",
			"image_profile_id": "image_default"
		},
		"api_profiles": [_default_ai_profile()],
		"image_profiles": [_default_image_profile()],
		"generation": {
			"include_existing_fields": true,
			"retry_count": 1,
			"default_idea_count": 6,
			"attachment_context_character_limit": 24000,
			"text_fallback_enabled": false,
			"default_image_size": "1024x1024",
			"default_image_prompt_style": "auto"
		},
		"updates": {
			"automatic_checks": true
		},
		"library_storage": {
			"mode": "local",
			"portable_root": "",
			"writer_id": _new_profile_id("writer"),
			"thumbnail_cache_max_mb": 512,
			"thumbnail_cache_max_age_days": 90,
			"virtualization_buffer_rows": 2
		},
		"ui": {"last_view": "dashboard"}
	}


static func load_settings() -> Dictionary:
	CCFStorageService.ensure_directories()
	if not FileAccess.file_exists(SETTINGS_FILE):
		var defaults: Dictionary = default_settings()
		save_settings(defaults)
		CCFStorageService.configure_library_storage_v0200(defaults)
		return defaults
	var file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file == null:
		var defaults: Dictionary = default_settings()
		CCFStorageService.configure_library_storage_v0200(defaults)
		return defaults
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		var defaults: Dictionary = default_settings()
		CCFStorageService.configure_library_storage_v0200(defaults)
		return defaults
	var normalised := _normalise(parsed)
	CCFStorageService.configure_library_storage_v0200(normalised)
	return normalised


static func save_settings(settings: Dictionary) -> Dictionary:
	CCFStorageService.ensure_directories()
	var normalised := _normalise(settings)
	var file := FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not save application settings."}
	file.store_string(JSON.stringify(normalised, "  "))
	file.close()
	CCFStorageService.configure_library_storage_v0200(normalised)
	return {"ok": true}


static func active_profile(settings: Dictionary) -> Dictionary:
	return profile_by_id(settings, str(settings.get("active_api_profile_id", "default")))


static func profile_for_role(settings: Dictionary, role: String) -> Dictionary:
	if role == ROLE_IMAGE:
		return image_profile_by_id(settings, role_profile_id(settings, ROLE_IMAGE))
	if role == ROLE_TEXT:
		return profile_for_text_task(settings, TEXT_TASK_PRIMARY)
	var role_key := "%s_profile_id" % role
	var provider_roles = settings.get("provider_roles", {})
	var profile_id := ""
	if provider_roles is Dictionary:
		profile_id = str(provider_roles.get(role_key, "")).strip_edges()
	if profile_id.is_empty():
		profile_id = str(settings.get("active_api_profile_id", "default"))
	return profile_by_id(settings, profile_id)


static func profile_for_text_task(settings: Dictionary, task: String) -> Dictionary:
	var requested_task := task.strip_edges().to_lower()
	if requested_task not in [TEXT_TASK_PRIMARY, TEXT_TASK_FAST, TEXT_TASK_DEEP]:
		requested_task = TEXT_TASK_PRIMARY
	var primary_id := _primary_text_profile_id(settings)
	var selected_id := primary_id
	var requested_role := ROLE_TEXT
	if requested_task == TEXT_TASK_FAST:
		requested_role = ROLE_TEXT_FAST
	elif requested_task == TEXT_TASK_DEEP:
		requested_role = ROLE_TEXT_DEEP
	if requested_role != ROLE_TEXT:
		var optional_id := _optional_text_role_profile_id(settings, requested_role)
		if optional_id != USE_PRIMARY_PROFILE_ID:
			selected_id = optional_id

	var profile := profile_by_id(settings, selected_id).duplicate(true)
	var generation: Dictionary = settings.get("generation", {})
	var fallback_enabled := bool(generation.get("text_fallback_enabled", false))
	var fallback_id := _optional_text_role_profile_id(settings, ROLE_TEXT_FALLBACK)
	var fallback_profile: Dictionary = {}
	if fallback_enabled and fallback_id != USE_PRIMARY_PROFILE_ID and fallback_id != selected_id:
		fallback_profile = profile_by_id(settings, fallback_id).duplicate(true)
	profile["_ccf_text_routing_v0195"] = {
		"format_version": 1,
		"requested_task": requested_task,
		"requested_role": requested_role,
		"primary_profile_id": primary_id,
		"selected_profile_id": selected_id,
		"inherited_primary": requested_role != ROLE_TEXT and selected_id == primary_id,
		"fallback_enabled": fallback_enabled,
		"fallback_profile": fallback_profile
	}
	return profile


static func role_profile_id(settings: Dictionary, role: String) -> String:
	if role in [ROLE_TEXT_FAST, ROLE_TEXT_DEEP, ROLE_TEXT_FALLBACK]:
		return _optional_text_role_profile_id(settings, role)
	var role_key := "%s_profile_id" % role
	var provider_roles = settings.get("provider_roles", {})
	var requested := ""
	if provider_roles is Dictionary:
		requested = str(provider_roles.get(role_key, "")).strip_edges()
	if role == ROLE_IMAGE:
		var image_profile: Dictionary = image_profile_by_id(settings, requested)
		return str(image_profile.get("id", "image_default"))
	if requested.is_empty():
		requested = str(settings.get("active_api_profile_id", "default"))
	var ai_profile: Dictionary = profile_by_id(settings, requested)
	return str(ai_profile.get("id", "default"))


static func set_role_profile(settings: Dictionary, role: String, profile_id: String) -> void:
	var resolved_id := profile_id
	if role == ROLE_IMAGE:
		resolved_id = str(image_profile_by_id(settings, profile_id).get("id", "image_default"))
	elif role in [ROLE_TEXT_FAST, ROLE_TEXT_DEEP, ROLE_TEXT_FALLBACK]:
		resolved_id = profile_id.strip_edges()
		if resolved_id != USE_PRIMARY_PROFILE_ID and not _profile_id_exists(
			settings.get("api_profiles", []), resolved_id
		):
			resolved_id = USE_PRIMARY_PROFILE_ID
	else:
		resolved_id = str(profile_by_id(settings, profile_id).get("id", "default"))
	var provider_roles: Dictionary = settings.get("provider_roles", {}).duplicate(true)
	provider_roles["%s_profile_id" % role] = resolved_id
	settings["provider_roles"] = provider_roles


static func profile_by_id(settings: Dictionary, profile_id: String) -> Dictionary:
	var profiles = settings.get("api_profiles", [])
	if profiles is Array:
		for profile in profiles:
			if profile is Dictionary and str(profile.get("id", "")) == profile_id:
				return _normalise_ai_profile(profile)
		if not profiles.is_empty() and profiles[0] is Dictionary:
			return _normalise_ai_profile(profiles[0])
	return _default_ai_profile()


static func image_profiles(settings: Dictionary) -> Array:
	var result: Array = []
	var profiles = settings.get("image_profiles", [])
	if profiles is Array:
		for profile in profiles:
			if profile is Dictionary:
				result.append(_normalise_image_profile(profile))
	if result.is_empty():
		result.append(_default_image_profile())
	return result


static func image_profile_by_id(settings: Dictionary, profile_id: String) -> Dictionary:
	var profiles: Array = image_profiles(settings)
	for profile in profiles:
		if profile is Dictionary and str(profile.get("id", "")) == profile_id:
			return profile
	if not profiles.is_empty() and profiles[0] is Dictionary:
		return profiles[0]
	return _default_image_profile()


static func replace_active_profile(settings: Dictionary, profile: Dictionary) -> void:
	replace_profile_by_id(settings, str(settings.get("active_api_profile_id", "default")), profile)


static func replace_profile_by_id(settings: Dictionary, profile_id: String, profile: Dictionary) -> void:
	var profiles: Array = settings.get("api_profiles", []).duplicate(true)
	var replacement: Dictionary = _normalise_ai_profile(profile)
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


static func replace_image_profile_by_id(settings: Dictionary, profile_id: String, profile: Dictionary) -> void:
	var profiles: Array = settings.get("image_profiles", []).duplicate(true)
	var replacement: Dictionary = _normalise_image_profile(profile)
	replacement["id"] = profile_id
	var replaced := false
	for index in range(profiles.size()):
		if profiles[index] is Dictionary and str(profiles[index].get("id", "")) == profile_id:
			profiles[index] = replacement
			replaced = true
			break
	if not replaced:
		profiles.append(replacement)
	settings["image_profiles"] = profiles


static func create_profile(settings: Dictionary, display_name := "New Profile") -> Dictionary:
	var profile_id := _new_profile_id("profile")
	var profile: Dictionary = _default_ai_profile()
	profile["id"] = profile_id
	profile["name"] = display_name
	var profiles: Array = settings.get("api_profiles", []).duplicate(true)
	profiles.append(profile)
	settings["api_profiles"] = profiles
	settings["active_api_profile_id"] = profile_id
	set_role_profile(settings, ROLE_TEXT, profile_id)
	return profile


static func duplicate_active_profile(settings: Dictionary) -> Dictionary:
	var source: Dictionary = active_profile(settings).duplicate(true)
	var profile_id := _new_profile_id("profile")
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
		return {"ok": false, "error": "At least one character AI profile must remain."}
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
	for role_key in ["text_profile_id", "vision_profile_id"]:
		if str(provider_roles.get(role_key, "")) == active_id:
			provider_roles[role_key] = fallback_id
	for role_key in [
		"text_fast_profile_id", "text_deep_profile_id", "text_fallback_profile_id"
	]:
		if str(provider_roles.get(role_key, "")) == active_id:
			provider_roles[role_key] = USE_PRIMARY_PROFILE_ID
	settings["provider_roles"] = provider_roles
	return {"ok": true}


static func create_image_profile(settings: Dictionary, display_name := "Local Stable Diffusion") -> Dictionary:
	var profile_id := _new_profile_id("image")
	var profile: Dictionary = _default_image_profile()
	profile["id"] = profile_id
	profile["name"] = display_name
	var profiles: Array = settings.get("image_profiles", []).duplicate(true)
	profiles.append(profile)
	settings["image_profiles"] = profiles
	set_role_profile(settings, ROLE_IMAGE, profile_id)
	return profile


static func duplicate_image_profile(settings: Dictionary, profile_id: String) -> Dictionary:
	var source: Dictionary = image_profile_by_id(settings, profile_id).duplicate(true)
	var new_id := _new_profile_id("image")
	source["id"] = new_id
	source["name"] = "%s Copy" % str(source.get("name", "Image Provider"))
	var profiles: Array = settings.get("image_profiles", []).duplicate(true)
	profiles.append(source)
	settings["image_profiles"] = profiles
	set_role_profile(settings, ROLE_IMAGE, new_id)
	return source


static func delete_image_profile(settings: Dictionary, profile_id: String) -> Dictionary:
	var profiles: Array = settings.get("image_profiles", []).duplicate(true)
	if profiles.size() <= 1:
		return {"ok": false, "error": "At least one image provider must remain."}
	var provider_roles: Dictionary = settings.get("provider_roles", {}).duplicate(true)
	var was_default := str(provider_roles.get("image_profile_id", "")) == profile_id
	var filtered: Array = []
	for profile in profiles:
		if profile is Dictionary and str(profile.get("id", "")) != profile_id:
			filtered.append(profile)
	if filtered.is_empty():
		return {"ok": false, "error": "Could not remove the image provider."}
	settings["image_profiles"] = filtered
	if was_default:
		provider_roles["image_profile_id"] = str(filtered[0].get("id", "image_default"))
		settings["provider_roles"] = provider_roles
	return {"ok": true}


static func image_backend(profile: Dictionary) -> String:
	var backend := str(profile.get("image_backend", IMAGE_BACKEND_OPENAI)).strip_edges().to_lower()
	if backend not in [IMAGE_BACKEND_OPENAI, IMAGE_BACKEND_AUTOMATIC1111]:
		return IMAGE_BACKEND_OPENAI
	return backend


static func image_settings(profile: Dictionary) -> Dictionary:
	return _normalise_image_settings(profile.get("image_settings", {}))


static func _normalise(settings: Dictionary) -> Dictionary:
	var defaults: Dictionary = default_settings()
	var result: Dictionary = defaults.duplicate(true)
	var incoming_format := int(settings.get("format_version", 2))
	result["format_version"] = SETTINGS_FORMAT_VERSION

	var raw_profiles = settings.get("api_profiles", [])
	var ai_profiles: Array = []
	if raw_profiles is Array:
		for profile in raw_profiles:
			if profile is Dictionary:
				ai_profiles.append(_normalise_ai_profile(profile))
	if ai_profiles.is_empty():
		ai_profiles.append(_default_ai_profile())
	result["api_profiles"] = ai_profiles
	result["active_api_profile_id"] = str(settings.get("active_api_profile_id", "default"))
	if not _profile_id_exists(ai_profiles, str(result["active_api_profile_id"])):
		result["active_api_profile_id"] = str(ai_profiles[0].get("id", "default"))

	var provider_roles: Dictionary = defaults.get("provider_roles", {}).duplicate(true)
	var incoming_roles = settings.get("provider_roles", {})
	if incoming_roles is Dictionary:
		provider_roles.merge(incoming_roles, true)
	if incoming_format < 3:
		provider_roles["text_profile_id"] = str(result["active_api_profile_id"])
		provider_roles["vision_profile_id"] = str(result["active_api_profile_id"])
	for role_key in ["text_profile_id", "vision_profile_id"]:
		if not _profile_id_exists(ai_profiles, str(provider_roles.get(role_key, ""))):
			provider_roles[role_key] = str(result["active_api_profile_id"])
	for role_key in [
		"text_fast_profile_id", "text_deep_profile_id", "text_fallback_profile_id"
	]:
		var optional_id := str(
			provider_roles.get(role_key, USE_PRIMARY_PROFILE_ID)
		).strip_edges()
		if optional_id.is_empty() or (
			optional_id != USE_PRIMARY_PROFILE_ID
			and not _profile_id_exists(ai_profiles, optional_id)
		):
			optional_id = USE_PRIMARY_PROFILE_ID
		provider_roles[role_key] = optional_id

	var image_profile_list: Array = []
	if incoming_format >= 6:
		var incoming_image_profiles = settings.get("image_profiles", [])
		if incoming_image_profiles is Array:
			for profile in incoming_image_profiles:
				if profile is Dictionary:
					image_profile_list.append(_normalise_image_profile(profile))
	else:
		image_profile_list.append(_migrate_v5_image_profile(settings, provider_roles))
	if image_profile_list.is_empty():
		image_profile_list.append(_default_image_profile())
	result["image_profiles"] = image_profile_list
	var requested_image_id := str(provider_roles.get("image_profile_id", "")).strip_edges()
	if incoming_format < 6 or not _profile_id_exists(image_profile_list, requested_image_id):
		provider_roles["image_profile_id"] = str(image_profile_list[0].get("id", "image_default"))
	result["provider_roles"] = provider_roles

	var generation_settings: Dictionary = defaults.get("generation", {}).duplicate(true)
	var incoming_generation = settings.get("generation", {})
	if incoming_generation is Dictionary:
		generation_settings.merge(incoming_generation, true)
	generation_settings["retry_count"] = clampi(int(generation_settings.get("retry_count", 1)), 0, 5)
	generation_settings["default_idea_count"] = clampi(int(generation_settings.get("default_idea_count", 6)), 1, 12)
	generation_settings["attachment_context_character_limit"] = clampi(int(generation_settings.get("attachment_context_character_limit", 24000)), 2000, 120000)
	generation_settings["text_fallback_enabled"] = bool(
		generation_settings.get("text_fallback_enabled", false)
	)
	var image_size_text := str(generation_settings.get("default_image_size", "1024x1024")).strip_edges()
	generation_settings["default_image_size"] = image_size_text if not image_size_text.is_empty() else "1024x1024"
	var image_prompt_style := str(generation_settings.get("default_image_prompt_style", "auto")).strip_edges().to_lower()
	if image_prompt_style not in ["auto", "natural", "stable_diffusion"]:
		image_prompt_style = "auto"
	generation_settings["default_image_prompt_style"] = image_prompt_style
	result["generation"] = generation_settings

	var update_settings: Dictionary = defaults.get("updates", {}).duplicate(true)
	var incoming_updates = settings.get("updates", {})
	if incoming_updates is Dictionary:
		update_settings.merge(incoming_updates, true)
	update_settings["automatic_checks"] = bool(
		update_settings.get("automatic_checks", true)
	)
	result["updates"] = update_settings

	var library_storage: Dictionary = defaults.get("library_storage", {}).duplicate(true)
	var incoming_library_storage: Variant = settings.get("library_storage", {})
	if incoming_library_storage is Dictionary:
		library_storage.merge(incoming_library_storage, true)
	var storage_mode := str(library_storage.get("mode", "local")).strip_edges().to_lower()
	if storage_mode not in ["local", "portable"]:
		storage_mode = "local"
	library_storage["mode"] = storage_mode
	library_storage["portable_root"] = str(
		library_storage.get("portable_root", "")
	).strip_edges()
	var writer_id := str(library_storage.get("writer_id", "")).strip_edges()
	if writer_id.is_empty():
		writer_id = _new_profile_id("writer")
	library_storage["writer_id"] = writer_id
	library_storage["thumbnail_cache_max_mb"] = clampi(
		int(library_storage.get("thumbnail_cache_max_mb", 512)), 64, 4096
	)
	library_storage["thumbnail_cache_max_age_days"] = clampi(
		int(library_storage.get("thumbnail_cache_max_age_days", 90)), 7, 3650
	)
	library_storage["virtualization_buffer_rows"] = clampi(
		int(library_storage.get("virtualization_buffer_rows", 2)), 1, 8
	)
	result["library_storage"] = library_storage

	var ui_settings: Dictionary = defaults.get("ui", {}).duplicate(true)
	var incoming_ui = settings.get("ui", {})
	if incoming_ui is Dictionary:
		ui_settings.merge(incoming_ui, true)
	result["ui"] = ui_settings
	return result


static func _migrate_v5_image_profile(settings: Dictionary, provider_roles: Dictionary) -> Dictionary:
	var legacy_id := str(provider_roles.get("image_profile_id", settings.get("active_api_profile_id", "default")))
	var legacy: Dictionary = _default_ai_profile()
	var raw_profiles = settings.get("api_profiles", [])
	if raw_profiles is Array:
		for candidate in raw_profiles:
			if candidate is Dictionary and str(candidate.get("id", "")) == legacy_id:
				legacy = candidate.duplicate(true)
				break
	var migrated: Dictionary = _default_image_profile()
	migrated["id"] = "image_default"
	migrated["name"] = "%s Image" % str(legacy.get("name", "Default"))
	migrated["image_backend"] = image_backend(legacy)
	migrated["image_settings"] = _normalise_image_settings(legacy.get("image_settings", {}))
	if migrated["image_backend"] == IMAGE_BACKEND_AUTOMATIC1111:
		var legacy_url := str(legacy.get("base_url", "")).strip_edges()
		if legacy_url.contains("/api/v1") or legacy_url.ends_with("/v1"):
			migrated["base_url"] = "http://127.0.0.1:7860"
		else:
			migrated["base_url"] = legacy_url if not legacy_url.is_empty() else "http://127.0.0.1:7860"
		migrated["api_key"] = ""
		migrated["model"] = ""
	else:
		migrated["base_url"] = str(legacy.get("base_url", ""))
		migrated["api_key"] = str(legacy.get("api_key", ""))
		migrated["model"] = str(legacy.get("model", ""))
	return _normalise_image_profile(migrated)


static func _normalise_ai_profile(profile: Dictionary) -> Dictionary:
	var result: Dictionary = _default_ai_profile()
	result.merge(profile, true)
	result["profile_kind"] = PROFILE_KIND_AI
	result.erase("image_backend")
	result.erase("image_settings")
	var profile_id := str(result.get("id", "")).strip_edges()
	result["id"] = profile_id if not profile_id.is_empty() else _new_profile_id("profile")
	var display_name := str(result.get("name", "")).strip_edges()
	result["name"] = display_name if not display_name.is_empty() else "Profile"
	result["temperature"] = clampf(float(result.get("temperature", 0.8)), 0.0, 2.0)
	result["max_output_tokens"] = maxi(128, int(result.get("max_output_tokens", 6000)))
	result["vision_detail"] = str(result.get("vision_detail", "auto"))
	if result["vision_detail"] not in ["auto", "low", "high"]:
		result["vision_detail"] = "auto"
	return result


static func _normalise_image_profile(profile: Dictionary) -> Dictionary:
	var result: Dictionary = _default_image_profile()
	result.merge(profile, true)
	result["profile_kind"] = PROFILE_KIND_IMAGE
	var profile_id := str(result.get("id", "")).strip_edges()
	result["id"] = profile_id if not profile_id.is_empty() else _new_profile_id("image")
	var display_name := str(result.get("name", "")).strip_edges()
	result["name"] = display_name if not display_name.is_empty() else "Image Provider"
	result["image_backend"] = image_backend(result)
	result["image_settings"] = _normalise_image_settings(result.get("image_settings", {}))
	result["base_url"] = str(result.get("base_url", "")).strip_edges()
	result["api_key"] = str(result.get("api_key", "")).strip_edges()
	result["model"] = str(result.get("model", "")).strip_edges()
	return result


static func _normalise_image_settings(raw_settings: Variant) -> Dictionary:
	var result: Dictionary = _default_image_settings()
	if raw_settings is Dictionary:
		result.merge(raw_settings, true)
	result["sampler"] = str(result.get("sampler", "Euler a")).strip_edges()
	result["steps"] = clampi(int(result.get("steps", 28)), 1, 150)
	result["cfg_scale"] = clampf(float(result.get("cfg_scale", 7.0)), 1.0, 30.0)
	result["seed"] = int(result.get("seed", -1))
	result["batch_size"] = clampi(int(result.get("batch_size", 1)), 1, 8)
	return result


static func _default_image_settings() -> Dictionary:
	return {"sampler": "Euler a", "steps": 28, "cfg_scale": 7.0, "seed": -1, "batch_size": 1}


static func _default_ai_profile() -> Dictionary:
	return {
		"id": "default",
		"profile_kind": PROFILE_KIND_AI,
		"name": "Default",
		"base_url": "http://127.0.0.1:1234/v1",
		"api_key": "",
		"model": "",
		"temperature": 0.8,
		"max_output_tokens": 6000,
		"vision_detail": "auto"
	}


static func _default_image_profile() -> Dictionary:
	return {
		"id": "image_default",
		"profile_kind": PROFILE_KIND_IMAGE,
		"name": "Local Stable Diffusion",
		"base_url": "http://127.0.0.1:7860",
		"api_key": "",
		"model": "",
		"image_backend": IMAGE_BACKEND_AUTOMATIC1111,
		"image_settings": _default_image_settings()
	}


static func _profile_id_exists(profiles: Array, profile_id: String) -> bool:
	for profile in profiles:
		if profile is Dictionary and str(profile.get("id", "")) == profile_id:
			return true
	return false


static func _primary_text_profile_id(settings: Dictionary) -> String:
	var provider_roles = settings.get("provider_roles", {})
	var requested := ""
	if provider_roles is Dictionary:
		requested = str(provider_roles.get("text_profile_id", "")).strip_edges()
	if requested.is_empty():
		requested = str(settings.get("active_api_profile_id", "default"))
	return str(profile_by_id(settings, requested).get("id", "default"))


static func _optional_text_role_profile_id(settings: Dictionary, role: String) -> String:
	var provider_roles = settings.get("provider_roles", {})
	var requested := USE_PRIMARY_PROFILE_ID
	if provider_roles is Dictionary:
		requested = str(
			provider_roles.get("%s_profile_id" % role, USE_PRIMARY_PROFILE_ID)
		).strip_edges()
	if requested.is_empty() or requested == USE_PRIMARY_PROFILE_ID:
		return USE_PRIMARY_PROFILE_ID
	if not _profile_id_exists(settings.get("api_profiles", []), requested):
		return USE_PRIMARY_PROFILE_ID
	return requested


static func _new_profile_id(prefix: String) -> String:
	return "%s_%s_%s" % [prefix, Time.get_unix_time_from_system(), randi_range(1000, 9999)]
