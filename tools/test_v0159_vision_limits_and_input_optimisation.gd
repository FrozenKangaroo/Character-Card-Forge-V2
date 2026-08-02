extends SceneTree


func _init() -> void:
	var settings_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v0159.gd")
	assert(settings_source.contains("vision_context_window_tokens"), "v0.15.9 Settings must expose a separate Vision context window.")
	assert(settings_source.contains("vision_max_output_tokens"), "v0.15.9 Settings must expose a separate Vision maximum output limit.")
	assert(settings_source.contains("Vision context window tokens"), "Vision context control must be labelled clearly.")
	assert(settings_source.contains("Vision maximum output tokens"), "Vision output control must be labelled clearly.")

	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v0159.gd")
	assert(service_source.contains("vision_context_window_tokens"), "Vision requests must consume the Vision context limit.")
	assert(service_source.contains("vision_max_output_tokens"), "Vision requests must consume the Vision output limit.")
	assert(service_source.contains("routed_profile[\"max_output_tokens\"] = vision_output"), "Vision requests must not inherit the Text output limit.")
	assert(service_source.contains("Vision Maximum Output Tokens"), "Invalid Vision token configuration must return a clear error.")
	assert(service_source.contains("AUTO_MAX_VISION_DIMENSION_V0159 := 4096"), "Auto preprocessing needs a dimension threshold.")
	assert(service_source.contains("AUTO_MAX_VISION_BYTES_V0159 := 8 * 1024 * 1024"), "Auto preprocessing needs a file-size threshold.")
	assert(service_source.contains("if not needs_resize and not needs_compression"), "Small images must bypass preprocessing unchanged.")
	assert(service_source.contains("save_webp"), "Oversized images should be safely re-encoded for Vision input.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0159.gd")
	assert(workspace_source.contains("GENERATION_SERVICE_V0159"), "Workspace must install the v0.15.9 service.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0159.gd")
	assert(main_source.contains("SETTINGS_V0159"), "The v0.15.9 shell must install the new Settings view.")
	assert(main_source.contains("WORKSPACE_V0159"), "The v0.15.9 shell must install the new Workspace.")
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene_source.contains("main_v0159.gd"), "The active scene must use v0.15.9.")
	var roadmap_source := FileAccess.get_file_as_string("res://roadmap.md")
	assert(roadmap_source.contains("v0.15.9 development candidate"), "The project roadmap must track the active v0.15.9 development phase.")
	assert(roadmap_source.contains("Independent Vision Token Limits & Input Optimisation"), "The roadmap must record the v0.15.9 feature set.")

	print("v0.15.9 Vision limits and input optimisation regression passed")
	quit(0)
