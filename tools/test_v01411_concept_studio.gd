extends SceneTree

func _init() -> void:
	var studio := FileAccess.get_file_as_string("res://scripts/ui/concept_studio_window_v01411.gd")
	assert(studio.contains("AI Ideas"), "Concept Studio must retain the V2 AI Ideas route.")
	assert(studio.contains("Structured Builder"), "Concept Studio must include the V1-style structured workflow.")
	assert(studio.contains("Idea Generator Options"), "Structured options editor is missing.")
	assert(studio.contains("Randomise Unlocked"), "Structured Builder lock-aware randomisation is missing.")
	assert(studio.contains("Reset All Idea Options"), "Option reset workflow is missing.")
	var service := FileAccess.get_file_as_string("res://scripts/services/idea_generator_option_service_v01411.gd")
	assert(service.contains("USER_PATH"), "User Idea Generator option overrides must persist separately.")
	assert(service.contains("reset_field"), "Per-field reset is missing.")
	var defaults := FileAccess.get_file_as_string("res://data/idea_generator_options.json")
	assert(defaults.contains("engages_in_sexual"), "Bundled V1 ingredient families are incomplete.")
	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01411.gd")
	assert(workspace.contains("concept[\"prompt\"] = concept_text"), "Structured selections must write to Main Concept.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01411.gd")
	assert(main_source.contains("WORKSPACE_V01411"), "v0.14.11 workspace is not installed.")
	var successor := FileAccess.get_file_as_string("res://scripts/main_v01412.gd")
	if not successor.is_empty():
		assert(successor.contains("main_v01411.gd"), "Newer shells must retain the v0.14.11 Idea workflows through inheritance.")
	print("v0.14.11 Idea workflow regression passed")
	quit(0)
