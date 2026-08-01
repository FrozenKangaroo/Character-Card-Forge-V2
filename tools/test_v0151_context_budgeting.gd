extends SceneTree


func _init() -> void:
	var settings_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v0151.gd")
	for marker in [
		"Context window tokens",
		"context_window_tokens",
		"Set Context Window to 0 if the provider/model limit is unknown",
		"max_output_tokens"
	]:
		assert(settings_source.contains(marker), "v0.15.1 settings are missing %s." % marker)

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
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene.contains("main_v0151.gd"), "Main scene must use the v0.15.1 shell.")

	print("v0.15.1 context-window budgeting regression passed")
	quit(0)
