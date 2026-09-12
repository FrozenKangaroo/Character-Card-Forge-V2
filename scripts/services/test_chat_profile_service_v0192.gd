class_name CCFTestChatProfileServiceV0192
extends RefCounted

const PROFILE_FILE := CCFStorageService.SETTINGS_DIR + "/test_chat_profiles_v0192.json"
const FORMAT_VERSION := 1


static func capabilities() -> Dictionary:
	return {
		"local_only": true,
		"separate_from_card_data": true,
		"persona_reference": true,
		"runtime_observation": true,
		"credentials_persisted": false,
		"api_keys_persisted": false,
		"mutates_front_porch_settings": false
	}


static func load_profiles() -> Array[Dictionary]:
	CCFStorageService.ensure_directories()
	if not FileAccess.file_exists(PROFILE_FILE):
		return []
	var file := FileAccess.open(PROFILE_FILE, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return []
	var result: Array[Dictionary] = []
	for profile_value in (parsed as Dictionary).get("profiles", []):
		if profile_value is Dictionary:
			result.append(sanitise_profile(profile_value))
	return result


static func save_profile(profile: Dictionary) -> Dictionary:
	var clean := sanitise_profile(profile)
	if str(clean.get("name", "")).is_empty():
		return {"ok": false, "error": "Give the Test Profile a name."}
	if str(clean.get("profile_id", "")).is_empty():
		clean["profile_id"] = _new_id()
	var profiles := load_profiles()
	var replaced := false
	for profile_index in range(profiles.size()):
		if str(profiles[profile_index].get("profile_id", "")) == str(clean.get("profile_id", "")):
			profiles[profile_index] = clean
			replaced = true
			break
	if not replaced:
		profiles.append(clean)
	var written := _write_profiles(profiles)
	if not bool(written.get("ok", false)):
		return written
	return {"ok": true, "profile": clean, "profiles": profiles}


static func delete_profile(profile_id: String) -> Dictionary:
	var clean_id := profile_id.strip_edges()
	var profiles := load_profiles()
	var retained: Array[Dictionary] = []
	for profile in profiles:
		if str(profile.get("profile_id", "")) != clean_id:
			retained.append(profile)
	var written := _write_profiles(retained)
	if not bool(written.get("ok", false)):
		return written
	return {"ok": true, "profiles": retained}


static func sanitise_profile(raw: Variant) -> Dictionary:
	var source: Dictionary = raw if raw is Dictionary else {}
	return {
		"profile_id": str(source.get("profile_id", "")).strip_edges(),
		"name": str(source.get("name", "")).strip_edges().left(80),
		"persona_id": str(source.get("persona_id", "")).strip_edges().left(200),
		"expected_runtime": str(source.get("expected_runtime", "")).strip_edges().left(240),
		"notes": str(source.get("notes", "")).strip_edges().left(2000),
		"updated_at": Time.get_datetime_string_from_system(true)
	}


static func _write_profiles(profiles: Array[Dictionary]) -> Dictionary:
	CCFStorageService.ensure_directories()
	var file := FileAccess.open(PROFILE_FILE, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not save local Test Profiles."}
	file.store_string(JSON.stringify({
		"format_version": FORMAT_VERSION,
		"profiles": profiles
	}, "  "))
	file.close()
	return {"ok": true}


static func _new_id() -> String:
	return "%d-%s" % [
		Time.get_ticks_usec(),
		str(randi()).sha256_text().substr(0, 10)
	]
