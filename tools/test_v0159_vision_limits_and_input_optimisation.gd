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
	assert(_active_shell_inherits_v0159(), "The active scene must use v0.15.9 or a later shell derived from it.")
	var roadmap_source := FileAccess.get_file_as_string("res://roadmap.md")
	assert(roadmap_source.contains("v0.15.9 — Independent Vision Token Limits & Input Optimisation"), "The roadmap must retain the v0.15.9 feature history.")

	print("v0.15.9 Vision limits and input optimisation regression passed")
	quit(0)


func _active_shell_inherits_v0159() -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/main_v"
	var start := scene_source.find(marker)
	if start < 0:
		return false
	var finish := scene_source.find(".gd", start)
	if finish < 0:
		return false
	var current_path := scene_source.substr(start, finish - start + 3)
	for _depth in range(32):
		if current_path == "res://scripts/main_v0159.gd":
			return true
		if not FileAccess.file_exists(current_path):
			return false
		var source := FileAccess.get_file_as_string(current_path)
		var extends_marker := "extends \"res://scripts/main_v"
		var extends_start := source.find(extends_marker)
		if extends_start < 0:
			return false
		extends_start += 9
		var extends_end := source.find("\"", extends_start)
		if extends_end < 0:
			return false
		current_path = source.substr(extends_start, extends_end - extends_start)
	return false
