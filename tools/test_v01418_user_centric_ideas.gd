extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01418.gd")
	for required_text in [
		"SILLYTAVERN ROLEPLAY CONTRACT",
		"character_role must explain who the generated character is to {{user}}",
		"roleplay_hook",
		"A concept that could remove {{user}}",
		"_seed_requests_detached_pov",
		"character_third_person_user_centric"
	]:
		assert(service_source.contains(required_text), "v0.14.18 Idea Generator is missing %s." % required_text)

	var service := CCFGenerationServiceV01418.new()
	var seed := "{{user}} is sleeping with his friend's girlfriend when her boyfriend calls and invites {{user}} over for dinner with them later. She finds the risk exciting."
	var valid_idea := {
		"title": "The Reckless Girlfriend",
		"character_name": "Claire",
		"character_role": "{{user}}'s friend's girlfriend",
		"source_anchor": "his friend's girlfriend",
		"roleplay_hook": "Claire and {{user}} must hide their affair during the dinner her boyfriend just invited {{user}} to attend.",
		"concept": "Claire is {{user}}'s friend's girlfriend and has been secretly sleeping with {{user}}. Her boyfriend's sudden invitation puts Claire and {{user}} together in a dangerous social situation where she becomes increasingly excited by the risk of discovery.",
		"tags": ["affair", "risk", "dinner"]
	}
	var good_report := service._validate_idea_batch([valid_idea], seed)
	assert(good_report.get("issues", []).is_empty(), "A grounded {{user}}-centric roleplay idea should pass.")
	assert(good_report.get("valid_ideas", []).size() == 1, "A valid user-centric idea must reach the UI.")

	var detached_story := valid_idea.duplicate(true)
	detached_story["character_role"] = "Liam's girlfriend"
	detached_story["roleplay_hook"] = "Claire has to survive dinner without Liam learning about the affair."
	detached_story["concept"] = "Claire is Liam's girlfriend. She has been cheating with his friend and must conceal the affair during dinner."
	var detached_report := service._validate_idea_batch([detached_story], seed)
	assert(not detached_report.get("issues", []).is_empty(), "A normal Idea Generator result must not erase {{user}} from the roleplay framing.")

	var explicit_observer_seed := "Create an observer card without {{user}}; the character is an omniscient narrator watching a royal court."
	assert(service._seed_requests_detached_pov(explicit_observer_seed), "Explicit detached/narrator requests must be recognised as exceptions.")

	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01418.gd")
	assert(workspace.contains("GENERATION_SERVICE_V01418"), "Workspace must install the v0.14.18 generation service.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01418.gd")
	assert(main_source.contains("extends \"res://scripts/main_v01417.gd\""), "v0.14.18 must preserve the detachable Lorebook layer.")
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene.contains("main_v01418.gd"), "Main scene must use the v0.14.18 shell.")
	print("v0.14.18 user-centric Idea Generator regression passed")
	service.free()
	quit(0)
