class_name CCFSupportReportServiceV0202
extends RefCounted

const REPORT_FORMAT_VERSION := 1


static func capabilities() -> Dictionary:
	return {
		"format_version": REPORT_FORMAT_VERSION,
		"privacy_safe_by_default": true,
		"credentials_omitted": true,
		"endpoint_addresses_omitted": true,
		"library_paths_omitted": true,
		"character_content_omitted": true,
		"model_identifiers_opt_in": true,
		"explicit_export": true,
		"explicit_issue_tracker_handoff": true,
	}


static func build_report(
	settings: Dictionary,
	application_version: String,
	include_model_identifiers := false
) -> Dictionary:
	var engine_version: Dictionary = Engine.get_version_info()
	var storage_status := CCFStorageService.library_storage_status_v0200()
	var library_mode := str(storage_status.get("mode", "local"))
	var report := {
		"report_format_version": REPORT_FORMAT_VERSION,
		"created_at_utc": Time.get_datetime_string_from_system(true),
		"privacy": {
			"character_and_project_content": "omitted",
			"prompts_and_conversations": "omitted",
			"credentials_and_session_data": "omitted",
			"endpoint_addresses": "omitted",
			"library_and_file_paths": "omitted",
			"custom_profile_names": "omitted",
			"model_identifiers": (
				"included_by_user_choice"
				if include_model_identifiers
				else "omitted_by_default"
			),
		},
		"application": {
			"name": "Character Card Forge",
			"version": application_version,
			"debug_build": OS.has_feature("editor") or OS.has_feature("debug"),
		},
		"engine": {
			"version": str(engine_version.get("string", Engine.get_version_info())),
			"rendering_method": RenderingServer.get_current_rendering_method(),
			"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
			"display_server": DisplayServer.get_name(),
		},
		"system": {
			"operating_system": OS.get_name(),
			"operating_system_version": OS.get_version(),
			"distribution": OS.get_distribution_name(),
			"architecture": Engine.get_architecture_name(),
			"processor_threads": OS.get_processor_count(),
			"screen_count": DisplayServer.get_screen_count(),
			"window_size": _vector_to_dictionary(DisplayServer.window_get_size()),
		},
		"library": {
			"storage_mode": library_mode,
			"location_kind": (
				"user_selected_portable_folder"
				if library_mode == "portable"
				else "application_storage"
			),
			"available": bool(storage_status.get("available", false)),
			"manifest_present": bool(storage_status.get("manifest_present", false)),
			"single_writer": bool(storage_status.get("single_writer", true)),
			"automatic_cloud_sync": bool(
				storage_status.get("automatic_cloud_sync", false)
			),
		},
		"settings": {
			"automatic_update_checks": bool(
				(settings.get("updates", {}) as Dictionary).get(
					"automatic_checks", true
				)
			),
			"ai_roles": _role_summaries(settings, include_model_identifiers),
		},
	}
	return report


static func report_text(report: Dictionary) -> String:
	return JSON.stringify(report, "  ")


static func _role_summaries(
	settings: Dictionary, include_model_identifiers: bool
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var roles := [
		{
			"role": "primary_text",
			"profile": CCFSettingsService.profile_for_text_task(
				settings, CCFSettingsService.TEXT_TASK_PRIMARY
			),
		},
		{
			"role": "fast_text",
			"profile": CCFSettingsService.profile_for_text_task(
				settings, CCFSettingsService.TEXT_TASK_FAST
			),
		},
		{
			"role": "deep_review_text",
			"profile": CCFSettingsService.profile_for_text_task(
				settings, CCFSettingsService.TEXT_TASK_DEEP
			),
		},
		{
			"role": "vision",
			"profile": CCFSettingsService.profile_for_role(
				settings, CCFSettingsService.ROLE_VISION
			),
		},
		{
			"role": "image",
			"profile": CCFSettingsService.profile_for_role(
				settings, CCFSettingsService.ROLE_IMAGE
			),
		},
	]
	for role_value in roles:
		var role: Dictionary = role_value
		var profile: Dictionary = role.get("profile", {})
		var model_identifier := str(profile.get("model", "")).strip_edges()
		var summary := {
			"role": str(role.get("role", "unknown")),
			"configured": not str(profile.get("base_url", "")).strip_edges().is_empty(),
			"endpoint_scope": _endpoint_scope(str(profile.get("base_url", ""))),
			"credential_configured": not str(profile.get("api_key", "")).is_empty(),
			"model_identifier_configured": not model_identifier.is_empty(),
		}
		if str(role.get("role", "")) == "image":
			summary["backend"] = CCFSettingsService.image_backend(profile)
		if include_model_identifiers:
			summary["model_identifier"] = (
				model_identifier if not model_identifier.is_empty() else "automatic"
			)
		result.append(summary)
	return result


static func _endpoint_scope(base_url: String) -> String:
	var lowered := base_url.strip_edges().to_lower()
	if lowered.is_empty():
		return "not_configured"
	if (
		lowered.contains("127.0.0.1")
		or lowered.contains("localhost")
		or lowered.contains("[::1]")
	):
		return "local_computer"
	return "remote_service"


static func _vector_to_dictionary(value: Vector2i) -> Dictionary:
	return {"width": value.x, "height": value.y}
