extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v015.gd")
	for marker in [
		"queue_collaborator_reply",
		"queue_collaborator_summary",
		"queue_collaborator_vision_summary",
		"queue_collaborator_character",
		"collaborator_text",
		"REFERENCE CONTEXT",
		"COMPRESSED EARLIER CONVERSATION MEMORY"
	]:
		assert(service_source.contains(marker), "v0.15 Collaborator service is missing %s." % marker)
	var live_service := CCFGenerationServiceV015.new()
	assert(live_service.has_method("queue_collaborator_reply"), "The v0.15 generation service must expose live Collaborator reply support.")
	assert(live_service.has_method("queue_collaborator_summary"), "The v0.15 generation service must expose Collaborator summary support.")
	live_service.free()

	var window_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v015.gd")
	for marker in [
		"Character Collaborator",
		"New Conversation",
		"Add Current Character",
		"Import JSON / V2 PNG",
		"Add Reference Image",
		"Regenerate Response",
		"Previous Variant",
		"Generate Character → Workspace",
		"Summarise Older Messages",
		"summarisation can lose nuance",
		"context_window_tokens",
		"CCFCardFormatService.load_card_file",
		"ROLE_VISION"
	]:
		assert(window_source.contains(marker), "Character Collaborator window is missing %s." % marker)
	assert(window_source.contains("force_native = true"), "Collaborator file dialogs must be native/detachable from the main window.")
	assert(window_source.contains("memory_summary"), "Collaborator sessions must preserve compressed memory separately from the original transcript.")
	assert(window_source.contains("summarized_through"), "Collaborator sessions must track which old messages are represented by compressed memory.")
	assert(window_source.contains("variants"), "Regenerated assistant responses must retain earlier variants instead of destroying them.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v015.gd")
	assert(workspace_source.contains("Character Collaborator…"), "Workspace Author menu must expose Character Collaborator.")
	assert(workspace_source.contains("collaborator_sessions"), "Collaborator sessions must persist in project data.")
	assert(workspace_source.contains("character_draft_ready"), "Collaborator must hand generated drafts back to Workspace.")
	assert(workspace_source.contains("GENERATION_SERVICE_V015"), "Workspace must install the v0.15 Collaborator-aware generation service.")
	assert(workspace_source.contains("_ensure_collaborator_generation_service_v015"), "Workspace must verify the live generation service before opening Collaborator.")
	assert(workspace_source.contains("has_method(\"queue_collaborator_reply\")"), "Workspace must reject stale pre-Collaborator generation services.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v015.gd")
	assert(main_source.contains("main_v01422.gd"), "v0.15 must preserve v0.14.22 graph work through inheritance.")
	assert(_active_shell_inherits("res://scripts/main_v015.gd"), "The active main shell must preserve v0.15 Character Collaborator through direct use or inheritance.")

	var sample := "one two three four five six seven eight"
	assert(CCFGenerationService.estimate_tokens(sample) > 0, "Context token estimation must remain available to the Collaborator.")

	print("v0.15 Character Collaborator regression passed")
	quit(0)


func _active_shell_inherits(target_path: String) -> bool:
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/main_"
	var start := scene.find(marker)
	if start < 0:
		return false
	var finish := scene.find(".gd", start)
	if finish < 0:
		return false
	var current_path := scene.substr(start, finish + 3 - start)
	var visited := {}
	while true:
		if current_path == target_path:
			return true
		if current_path.is_empty() or visited.has(current_path):
			return false
		visited[current_path] = true
		if not FileAccess.file_exists(current_path):
			return false
		var source := FileAccess.get_file_as_string(current_path)
		var extends_marker := "extends \"res://scripts/"
		var extends_start := source.find(extends_marker)
		if extends_start < 0:
			return false
		extends_start += "extends \"".length()
		var extends_finish := source.find("\"", extends_start)
		if extends_finish < 0:
			return false
		current_path = source.substr(extends_start, extends_finish - extends_start)
	return false
