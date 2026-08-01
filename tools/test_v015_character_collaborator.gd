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

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v015.gd")
	assert(main_source.contains("main_v01422.gd"), "v0.15 must preserve v0.14.22 graph work through inheritance.")
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene.contains("main_v015.gd"), "Main scene must use the v0.15 shell.")

	var sample := "one two three four five six seven eight"
	assert(CCFGenerationService.estimate_tokens(sample) > 0, "Context token estimation must remain available to the Collaborator.")

	print("v0.15 Character Collaborator regression passed")
	quit(0)
