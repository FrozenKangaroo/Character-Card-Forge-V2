extends SceneTree

const MANUAL = preload("res://scripts/ui/manual_guided_window_v0148.gd")


func _init() -> void:
	var manual := MANUAL.new()
	var greetings := manual._normalise_alternative_greetings([
		"First alternate.",
		"Second alternate."
	])
	assert(greetings.size() == 2, "Manual Guided must preserve separate alternative greeting entries.")
	assert(greetings[0] == "First alternate.", "Alternative greeting order must be preserved.")
	assert(greetings[1] == "Second alternate.", "Alternative greeting order must be preserved.")

	var source := FileAccess.get_file_as_string("res://scripts/ui/manual_guided_window_v0148.gd")
	assert(source.contains("+ Add Alternative Greeting"), "Manual Guided needs an add-alternative-greeting action.")
	assert(source.contains("_remove_alternative_greeting"), "Manual Guided needs per-greeting removal.")
	assert(source.contains("_move_alternative_greeting"), "Manual Guided needs greeting ordering controls.")
	assert(source.contains("character.alternate_greetings") or FileAccess.get_file_as_string("res://scripts/ui/workspace_v0148.gd").contains("character.alternate_greetings"), "Manual Guided alternatives must apply to the interoperable Character Card field.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0148.gd")
	assert(workspace_source.contains("character.alternate_greetings"), "Workspace must apply Manual Guided alternatives as an array.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0148.gd")
	assert(main_source.contains("0.14.8"), "v0.14.8 development label is missing.")

	manual.free()
	print("v0.14.8 Manual Guided alternative greetings regression passed")
	quit(0)
