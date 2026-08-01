extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01416.gd")
	for required_text in [
		"CHARACTER IDENTITY CONTRACT",
		"POINT-OF-VIEW CONTRACT",
		"character_name",
		"character_role",
		"source_anchor",
		"semantic_repair_attempts",
		"_validate_idea_batch",
		"_start_idea_semantic_repair",
		"_contains_second_person_narration",
		"_role_introduces_unseeded_identity"
	]:
		assert(service_source.contains(required_text), "v0.14.16 Idea Generator is missing %s." % required_text)

	var service := CCFGenerationServiceV01416.new()
	var seed := "{{user}} has been sleeping with his best friend's girlfriend while his best friend is sleeping with {{user}}'s girlfriend. Both girlfriends become pregnant."
	var good_idea := {
		"title": "The Double Betrayal",
		"character_name": "Mika",
		"character_role": "his best friend's girlfriend",
		"source_anchor": "his best friend's girlfriend",
		"concept": "Mika is {{user}}'s best friend's girlfriend. Mika began a secret affair with {{user}}, unaware that her own boyfriend is simultaneously involved with {{user}}'s girlfriend; both women becoming pregnant pushes the hidden arrangement toward collapse.",
		"tags": ["affair", "pregnancy", "double betrayal"]
	}
	var good_report := service._validate_idea_batch([good_idea], seed)
	assert(good_report.get("issues", []).is_empty(), "A grounded third-person idea should pass validation.")
	assert(good_report.get("valid_ideas", []).size() == 1, "A valid idea must reach the result cards.")

	var second_person := good_idea.duplicate(true)
	second_person["concept"] = "Your boyfriend is too rough, so you turn to {{user}} for comfort."
	var pov_report := service._validate_idea_batch([second_person], seed)
	assert(not pov_report.get("issues", []).is_empty(), "Second-person you/your narration must be rejected.")

	var unrelated_mother := good_idea.duplicate(true)
	unrelated_mother["character_name"] = "Eleanor"
	unrelated_mother["character_role"] = "mother of one of the betrayed partners"
	unrelated_mother["source_anchor"] = "girlfriend"
	unrelated_mother["concept"] = "Eleanor is the mother of one of the betrayed partners and starts investigating the pregnancies around {{user}}."
	var mother_report := service._validate_idea_batch([unrelated_mother], seed)
	assert(not mother_report.get("issues", []).is_empty(), "An invented parent/observer viewpoint must be rejected when no parent exists in the premise.")

	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01416.gd")
	assert(workspace.contains("GENERATION_SERVICE_V01416"), "Workspace must install the hardened Idea Generator service.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01416.gd")
	assert(main_source.contains("extends \"res://scripts/main_v01415.gd\""), "v0.14.16 must retain v0.14.15 lorebook support.")
	var successor := FileAccess.get_file_as_string("res://scripts/main_v01417.gd")
	if not successor.is_empty():
		assert(successor.contains("extends \"res://scripts/main_v01416.gd\""), "Newer shells must retain the v0.14.16 Idea Generator contract through inheritance.")
	print("v0.14.16 Idea Generator identity/POV regression passed")
	service.free()
	quit(0)
