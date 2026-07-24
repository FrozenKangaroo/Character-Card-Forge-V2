class_name CCFSettingsService
extends RefCounted

const SETTINGS_FILE := CCFStorageService.SETTINGS_DIR + "/app_settings.json"

static func default_settings() -> Dictionary:
    return {
        "format_version": 2,
        "active_api_profile_id": "default",
        "api_profiles": [
            _default_profile()
        ],
        "generation": {
            "include_existing_fields": true,
            "retry_count": 1,
            "default_idea_count": 6
        },
        "ui": {
            "last_view": "dashboard"
        }
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
    settings["active_api_profile_id"] = str(filtered[0].get("id", "default"))
    return {"ok": true}

static func _normalise(settings: Dictionary) -> Dictionary:
    var defaults := default_settings()
    var result := defaults.duplicate(true)

    result["format_version"] = 2
    result["active_api_profile_id"] = str(settings.get("active_api_profile_id", defaults["active_api_profile_id"]))

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

    var generation_settings: Dictionary = defaults.get("generation", {}).duplicate(true)
    var incoming_generation = settings.get("generation", {})
    if incoming_generation is Dictionary:
        generation_settings.merge(incoming_generation, true)
    generation_settings["retry_count"] = clampi(int(generation_settings.get("retry_count", 1)), 0, 5)
    generation_settings["default_idea_count"] = clampi(int(generation_settings.get("default_idea_count", 6)), 1, 12)
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
    return result

static func _default_profile() -> Dictionary:
    return {
        "id": "default",
        "name": "Default",
        "base_url": "http://127.0.0.1:1234/v1",
        "api_key": "",
        "model": "",
        "temperature": 0.8,
        "max_output_tokens": 6000
    }

static func _new_profile_id() -> String:
    return "profile_%s_%s" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
