extends SceneTree


func _init() -> void:
	var settings_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v01522.gd")
	assert(settings_source.contains('extends "res://scripts/ui/settings_view_v0159.gd"'), "v0.15.22 Generation Strategy settings must preserve the full v0.15.9 settings inheritance chain.")

	var context_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v0151.gd")
	assert(context_source.contains("Context window tokens"), "The Text-model context/input token setting must remain available.")
	assert(context_source.contains('profile["context_window_tokens"]'), "Context window tokens must continue to persist per API profile.")

	var output_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v0152.gd")
	assert(output_source.contains("MAX_OUTPUT_TOKENS_V0152 := 4194304"), "Maximum Output Tokens must not regress to the old 131,072 hard cap.")
	assert(output_source.contains("_max_tokens.allow_greater = true"), "Maximum Output Tokens must continue to allow provider-specific values above the UI ceiling.")

	var vision_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v0159.gd")
	assert(vision_source.contains("Vision context window tokens"), "The v0.15.22 settings replacement must also retain separate Vision token controls.")
	assert(vision_source.contains("Vision maximum output tokens"), "The v0.15.22 settings replacement must retain Vision output-token controls.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01523.gd")
	assert(main_source.contains('BUILD_DISPLAY_VERSION_V01523 := "0.15.23"'), "The v0.15.23 regression-fix shell must expose its build version.")
	assert(_active_shell_inherits_from("res://scripts/main_v01523.gd"), "The active scene must use or inherit v0.15.23.")

	print("v0.15.23 token settings regression passed")
	quit(0)


func _active_shell_inherits_from(target_path: String) -> bool:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	if root == null:
		return false
	var current := root.get_script() as Script
	while current != null:
		if current.resource_path == target_path:
			root.free()
			return true
		current = current.get_base_script()
	root.free()
	return false
