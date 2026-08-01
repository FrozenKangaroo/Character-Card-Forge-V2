extends SceneTree


func _init() -> void:
	var settings_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v0151.gd")
	for marker in [
		"Context window tokens",
		"context_window_tokens",
		"Set Context Window to 0 if the provider/model limit is unknown"
	]:
		assert(settings_source.contains(marker), "v0.15.1 settings are missing %s." % marker)
	var base_settings_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view.gd")
	assert(base_settings_source.contains("Maximum output tokens"), "Character AI Settings must retain a separate Maximum Output Tokens control.")
	assert(settings_source.contains("Maximum Output Tokens is only the response limit"), "v0.15.1 Settings must explain the distinction between context capacity and response output limits.")

	var collaborator_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v0151.gd")
	for marker in [
		"context limit unknown",
		"response reserve",
		"headroom",
		"configured_output",
		"available_input",
		"context_window <= 0",
		"return true"
	]:
		assert(collaborator_source.contains(marker), "v0.15.1 Collaborator budgeting is missing %s." % marker)
	assert(collaborator_source.contains("mini(configured_output, maximum_reserve)"), "Output reserve must be clamped below the total context window.")
	assert(collaborator_source.contains("CONTEXT_WARNING_PERCENT_V0151"), "Collaborator should warn before the context is fully exhausted.")
	assert(collaborator_source.contains("CONTEXT_CRITICAL_PERCENT_V0151"), "Collaborator should expose a critical near-limit warning.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0151.gd")
	assert(workspace_source.contains("CHARACTER_COLLABORATOR_WINDOW_V0151"), "Workspace must install the corrected v0.15.1 Collaborator window.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0151.gd")
	assert(main_source.contains("SETTINGS_V0151"), "v0.15.1 shell must install the context-window-aware Settings view.")
	assert(main_source.contains("WORKSPACE_V0151"), "v0.15.1 shell must install the corrected Workspace.")

	var v0152_settings := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v0152.gd")
	assert(v0152_settings.contains("MAX_OUTPUT_TOKENS_V0152 := 4194304"), "v0.15.2 must allow output-token limits well beyond 131,072.")
	assert(v0152_settings.contains("allow_greater = true"), "Maximum Output Tokens must permit manually entered future model limits above the configured spinner range.")
	assert(not v0152_settings.contains("131072"), "v0.15.2 must not reintroduce the old 131,072 output-token ceiling.")
	var main_v0152 := FileAccess.get_file_as_string("res://scripts/main_v0152.gd")
	assert(main_v0152.contains("main_v0151.gd") and main_v0152.contains("SETTINGS_V0152"), "v0.15.2 must preserve v0.15.1 and install the large-output Settings view.")
	assert(_active_main_inherits_from("res://scripts/main_v0151.gd"), "The active main shell must preserve v0.15.1 context budgeting through direct use or inheritance.")

	print("v0.15.1/v0.15.2 context-window and large-output budgeting regression passed")
	quit(0)


func _active_main_inherits_from(target_path: String) -> bool:
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var regex := RegEx.new()
	regex.compile("res://scripts/main_[^\\\"]+\\.gd")
	var match_result := regex.search(scene)
	if match_result == null:
		return false
	var current_path := match_result.get_string()
	var visited: Dictionary = {}
	while not current_path.is_empty() and not visited.has(current_path):
		if current_path == target_path:
			return true
		visited[current_path] = true
		var source := FileAccess.get_file_as_string(current_path)
		var extends_regex := RegEx.new()
		extends_regex.compile("extends \\\"(res://scripts/main_[^\\\"]+\\.gd)\\\"")
		var extends_match := extends_regex.search(source)
		if extends_match == null:
			break
		current_path = extends_match.get_string(1)
	return false
