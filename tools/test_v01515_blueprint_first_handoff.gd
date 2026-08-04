extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01515.gd")
	assert(service_source.contains("queue_collaborator_blueprint"), "v0.15.15 needs a dedicated Blueprint handoff job.")
	assert(service_source.contains("LOSS-MINIMISING CHARACTER GENERATION BLUEPRINT"), "Blueprint generation must explicitly prioritise detail retention.")
	assert(service_source.contains("ALTERNATIVE GREETINGS"), "Blueprint source must preserve alternative-greeting intent.")
	assert(service_source.contains("LOREBOOK"), "Blueprint source must preserve lorebook intent.")
	assert(service_source.contains("Do not return the normal Character Card fields separately"), "Blueprint mode must target Generation Concept rather than prematurely filling fields.")
	assert(service_source.contains("queue_collaborator_detailed_draft"), "The legacy-style detailed Workspace handoff must remain available as an option.")
	assert(service_source.contains("alternate_greetings"), "Detailed handoff must return Alternative Greetings.")
	assert(service_source.contains("lorebook"), "Detailed handoff must return Character Lorebook data.")
	assert(service_source.contains("Preserve the same level of specificity"), "Detailed handoff must explicitly resist detail loss.")

	var collaborator_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v01515.gd")
	assert(collaborator_source.contains("Blueprint → Generation Concept (Recommended)"), "Blueprint must be the visible recommended/default handoff mode.")
	assert(collaborator_source.contains("Detailed Workspace Draft"), "The direct field-filling handoff must remain selectable.")
	assert(collaborator_source.contains("_handoff_mode_v01515.select(HANDOFF_BLUEPRINT_V01515)"), "Blueprint must be selected by default.")
	assert(collaborator_source.contains("queue_collaborator_blueprint"), "Blueprint mode must route to the dedicated generation job.")
	assert(collaborator_source.contains("queue_collaborator_detailed_draft"), "Detailed mode must route to the detailed draft job.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01515.gd")
	assert(workspace_source.contains("concept.prompt"), "Blueprint handoff must write the generated blueprint into Generation Concept.")
	assert(workspace_source.contains("character.alternate_greetings"), "Detailed draft handoff must write Alternative Greetings.")
	assert(workspace_source.contains("character.character_book"), "Detailed draft handoff must write the Character Lorebook.")
	assert(workspace_source.contains("handoff_mode"), "Workspace provenance must distinguish handoff modes.")
	assert(workspace_source.contains("CHARACTER_COLLABORATOR_WINDOW_V01515"), "Workspace must install the v0.15.15 Collaborator window.")
	assert(workspace_source.contains("GENERATION_SERVICE_V01515"), "Workspace must install the v0.15.15 generation service.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01515.gd")
	assert(main_source.contains("BUILD_DISPLAY_VERSION_V01515 := \"0.15.15\""), "The v0.15.15 shell must expose the build version.")
	assert(_active_shell_inherits_v01515(), "The active scene must use v0.15.15 or a later shell inheriting from it.")

	print("v0.15.15 blueprint-first Collaborator handoff regression passed")
	quit(0)


func _active_shell_inherits_v01515() -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/"
	var marker_at := scene_source.find(marker)
	if marker_at < 0:
		return false
	var end_at := scene_source.find("\"", marker_at)
	if end_at < 0:
		return false
	var path := scene_source.substr(marker_at, end_at - marker_at)
	var visited: Dictionary = {}
	for _depth in range(64):
		if path == "res://scripts/main_v01515.gd":
			return true
		if path.is_empty() or visited.has(path) or not FileAccess.file_exists(path):
			return false
		visited[path] = true
		var source := FileAccess.get_file_as_string(path)
		var extends_marker := "extends \""
		var extends_at := source.find(extends_marker)
		if extends_at < 0:
			return false
		var start_at := extends_at + extends_marker.length()
		var next_end := source.find("\"", start_at)
		if next_end < 0:
			return false
		path = source.substr(start_at, next_end - start_at)
	return false
