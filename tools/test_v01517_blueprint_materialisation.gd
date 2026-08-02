extends SceneTree


func _init() -> void:
	var service := CCFGenerationServiceV01517.new()
	assert(service is CCFParityGenerationService, "v0.15.17 must retain the restored semantic generation pipeline.")
	assert(service is CCFInterviewGenerationService, "v0.15.17 must retain the private Interview/Q&A stage.")
	assert(service is CCFTemplateContractGuardGenerationService, "v0.15.17 must retain active-template contract enforcement.")
	assert(service.has_method("queue_collaborator_blueprint"), "Blueprint handoff must remain available.")
	assert(service.has_method("queue_blueprint_supplemental_material"), "Existing Blueprint characters need a supplementary materialisation path.")
	assert(service.has_method("build_interview_review_v01517"), "Interview answers must be recoverable for readable Workspace review.")

	var review := service.build_interview_review_v01517(
		{
			"interview_questions": [
				{
					"id": "voice",
					"label": "Voice",
					"question": "How does she speak?",
					"required": true
				},
				{
					"id": "fear",
					"label": "Fear",
					"question": "What does she fear?",
					"required": false
				}
			],
			"interview_answers": {
				"voice": "Warm, direct, and lightly teasing.",
				"fear": "Losing the people she depends on."
			},
			"interview_manual_ids": ["fear"]
		}
	)
	var entries_value: Variant = review.get("entries", [])
	assert(entries_value is Array and entries_value.size() == 2, "Readable Interview review must retain every answered question.")
	var entries: Array = entries_value
	assert(str((entries[0] as Dictionary).get("source", "")) == "ai", "AI Interview answers must remain marked as AI-sourced.")
	assert(str((entries[1] as Dictionary).get("source", "")) == "manual", "Manual Interview answers must retain manual provenance.")
	assert(str((entries[0] as Dictionary).get("answer", "")).contains("lightly teasing"), "Interview answer text must survive review construction.")

	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01517.gd")
	assert(service_source.contains('metadata["generation_interview_review"]'), "The completed character job must carry readable Interview review metadata.")
	assert(service_source.contains("alternate_greetings"), "Blueprint handoff must return structured Alternative Greetings.")
	assert(service_source.contains("lorebook"), "Blueprint handoff must return structured Lorebook data.")
	assert(service_source.contains("queue_blueprint_supplemental_material"), "Older Blueprint characters must be able to materialise missing supplementary data from their existing concept.")
	assert(service_source.contains("AUTHORITATIVE GENERATION BLUEPRINT"), "Supplementary extraction must use the existing Blueprint as authoritative source material.")

	var workspace := CCFWorkspaceV01517View.new()
	workspace._template = {"template_id": "my-default-custom"}
	assert(workspace._active_template_id_v01517() == "my-default-custom", "Collaborator handoff must preserve the active custom template ID.")
	workspace._project = {
		"concept": {"prompt": "# CHARACTER\nDetailed source\n# ALTERNATIVE GREETINGS\nA second opening\n# LOREBOOK\nSide character facts"},
		"character": {"alternate_greetings": [], "character_book": {}},
		"provenance": {
			"character_collaborator": {
				"handoff_mode": "blueprint",
				"source": "character_collaborator_v01515"
			}
		}
	}
	var supplement_request := workspace._blueprint_supplement_request_v01517()
	assert(bool(supplement_request.get("needed", false)), "A pre-v0.15.17 Blueprint with missing supplements must request materialisation.")
	assert(bool(supplement_request.get("fill_alternate_greetings", false)), "Missing Alternative Greetings must be detected.")
	assert(bool(supplement_request.get("fill_lorebook", false)), "Missing Lorebook entries must be detected.")

	var provenance: Dictionary = workspace._project.get("provenance", {})
	var collaborator: Dictionary = provenance.get("character_collaborator", {})
	collaborator["structured_supplements"] = true
	provenance["character_collaborator"] = collaborator
	workspace._project["provenance"] = provenance
	assert(not bool(workspace._blueprint_supplement_request_v01517().get("needed", true)), "Once Blueprint supplements are materialised/reviewed they must not be regenerated on every Generate Character click.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01517.gd")
	assert(workspace_source.contains('"generation.template_id", _active_template_id_v01517()'), "Both Collaborator handoff paths must stamp the active template onto the new character before switching Workspace character.")
	assert(workspace_source.contains('"character.alternate_greetings"'), "Blueprint supplementary material must land in the existing Alternative Greetings data path.")
	assert(workspace_source.contains('"character.character_book"'), "Blueprint supplementary material must land in the existing Character Lorebook data path.")
	assert(workspace_source.contains("queue_character_generation"), "Normal template fields must still use the validated character-generation pipeline.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01517.gd")
	assert(main_source.contains('BUILD_DISPLAY_VERSION_V01517 := "0.15.17"'), "The v0.15.17 shell must continue to expose its own build version.")
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(
		scene_source.contains("res://scripts/main_v015"),
		"The active scene must remain on the inherited v0.15 app-shell line."
	)

	workspace.free()
	service.free()
	print("v0.15.17 Blueprint materialisation regression passed")
	quit(0)
