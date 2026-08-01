extends SceneTree


func _init() -> void:
	var window := FileAccess.get_file_as_string("res://scripts/ui/idea_generator_window_v01412.gd")
	var inherited_workflows := FileAccess.get_file_as_string("res://scripts/ui/concept_studio_window_v01411.gd")
	assert(window.contains("title = \"Idea Generator\""), "Unified tool must retain the established Idea Generator name.")
	assert(window.contains("AI Ideas"), "Unified Idea Generator must include the AI Ideas tab.")
	assert(inherited_workflows.contains("Structured Builder"), "Unified Idea Generator must retain Structured Builder through inheritance.")
	assert(window.contains("attach_ai_idea_window"), "Existing AI Ideas UI must be embedded into the unified window.")
	assert(not window.contains("Open AI Idea Generator"), "AI Ideas must not require a second-window launch button.")
	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01412.gd")
	assert(workspace.contains("_route_existing_idea_generator_button"), "Existing Idea Generator entry must route to the unified window.")
	assert(workspace.contains("_add_concept_studio_route"), "Redundant Concept Studio route override is missing.")
	assert(workspace.contains("pass"), "Redundant Concept Studio menu entry must be suppressed.")
	assert(workspace.contains("Choose AI Ideas or Structured Builder"), "Unified workflow status guidance is missing.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01412.gd")
	assert(main_source.contains("WORKSPACE_V01412"), "v0.14.12 workspace is not installed.")
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene.contains("main_v01412.gd"), "Main scene must use the v0.14.12 shell.")
	print("v0.14.12 unified Idea Generator regression passed")
	quit(0)
