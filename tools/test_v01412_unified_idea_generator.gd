extends SceneTree


func _init() -> void:
	var window := FileAccess.get_file_as_string("res://scripts/ui/idea_generator_window_v01412.gd")
	var inherited_workflows := FileAccess.get_file_as_string("res://scripts/ui/concept_studio_window_v01411.gd")
	assert(window.contains("title = \"Idea Generator\""), "Unified tool must retain the established Idea Generator name.")
	assert(window.contains("AI Ideas"), "Unified Idea Generator must include the AI Ideas tab.")
	assert(inherited_workflows.contains("Structured Builder"), "Unified Idea Generator must retain Structured Builder through inheritance.")
	assert(window.contains("attach_ai_idea_window"), "Existing AI Ideas UI must be embedded into the unified window.")
	assert(window.contains("_hide_embedded_close_buttons"), "Embedded AI Ideas must remove its duplicate Close control.")
	assert(window.contains("_embedded_ai_window.hide()"), "Legacy native Idea Generator shell must remain hidden.")
	assert(not window.contains("Open AI Idea Generator"), "AI Ideas must not require a second-window launch button.")
	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01412.gd")
	assert(workspace.contains("_route_existing_idea_generator_button"), "Existing Idea Generator entry must route to the unified window.")
	assert(workspace.contains("button.pressed.get_connections()"), "Legacy Idea Generator callbacks must be replaced, not left active beside the unified callback.")
	assert(workspace.contains("button.pressed.disconnect(callback)"), "Legacy button callbacks must be disconnected to prevent an empty native window.")
	assert(workspace.contains("_add_concept_studio_route"), "Redundant Concept Studio route override is missing.")
	assert(workspace.contains("pass"), "Redundant Concept Studio menu entry must be suppressed.")
	assert(workspace.contains("Choose AI Ideas or Structured Builder"), "Unified workflow status guidance is missing.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01412.gd")
	assert(main_source.contains("WORKSPACE_V01412"), "v0.14.12 workspace is not installed.")
	var successor := FileAccess.get_file_as_string("res://scripts/main_v01413.gd")
	if not successor.is_empty():
		assert(successor.contains("main_v01412.gd"), "Newer shells must retain the v0.14.12 unified Idea Generator through inheritance.")
	print("v0.14.12 unified Idea Generator regression passed")
	quit(0)
