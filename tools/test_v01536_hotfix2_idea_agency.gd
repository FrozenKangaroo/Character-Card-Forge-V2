extends SceneTree

const SERVICE_SCRIPT = preload(
	"res://scripts/services/generation_service_v01536_hotfix2.gd"
)

const REPORTED_SEED := "Without {{user}} realising it, his adult partner gradually develops a deeply established secret sexual or emotional dynamic with another man.\nCore variables\n    • How the affair starts\n    • Affair stage at scenario opening\n    • Attachment to each man\n    • How much the other man influences her behaviour\n    • How skilled she is at deception\n    • Whether she enjoys secrecy\n    • Whether she plans to leave {{user}}\n    • Clues visible to {{user}}\nNotable subtypes / seeds\nSlow Corruption; Double Life; Other Man Gains Influence; Secret Continuation After Promising to Stop"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_detached_pov_detection()
	_test_reported_batch_shape_passes()
	_test_minor_scene_logistics_are_allowed()
	_test_substantive_user_canon_is_rejected()
	_test_meaningful_user_response_is_rejected()
	_test_prompt_and_repair_contract()
	await _test_real_main_wiring()
	print("v0.15.36-hotfix2 AI Ideas agency regression passed")
	quit(0)


func _test_detached_pov_detection() -> void:
	var service := SERVICE_SCRIPT.new() as CCFGenerationServiceV01536Hotfix2
	assert(
		not service._seed_requests_detached_pov(REPORTED_SEED),
		"'Without {{user}} realising it' is a secrecy premise, not a detached POV request."
	)
	assert(
		service._seed_requests_detached_pov(
			"Create an observer card with an omniscient viewpoint over the whole household."
		),
		"Explicit observer/narrator requests must still enable detached POV."
	)
	service.free()


func _test_reported_batch_shape_passes() -> void:
	var service := SERVICE_SCRIPT.new() as CCFGenerationServiceV01536Hotfix2
	var idea := {
		"title": "Slow Corruption at the New Job",
		"character_name": "Elena Voss",
		"character_role": "{{user}}'s wife of four years, who recently started a demanding new position at a marketing firm where a senior colleague has been steadily drawing her into a private dynamic.",
		"source_anchor": "gradually develops a deeply established secret sexual or emotional dynamic with another man",
		"roleplay_hook": "Elena has just come home from another late evening at the office, carrying the warmth of a private text conversation {{user}} cannot see.",
		"concept": "Elena Voss is {{user}}'s adult partner and genuinely loves {{user}} while a senior colleague gradually draws her into a secret emotional dynamic. Elena deletes messages, explains late nights smoothly, and arrives home carrying clues that create tension without deciding how {{user}} responds.",
		"tags": ["slow corruption", "emotional affair", "deception"]
	}
	var report := service._validate_idea_batch([idea], REPORTED_SEED)
	assert(
		(report.get("valid_ideas", []) as Array).size() == 1,
		"A clearly third-person user-centric partner idea must pass even when character_role mentions a supporting colleague. Issues: %s"
		% JSON.stringify(report.get("issues", []))
	)
	service.free()


func _test_minor_scene_logistics_are_allowed() -> void:
	var service := SERVICE_SCRIPT.new() as CCFGenerationServiceV01536Hotfix2
	var idea := _reported_idea(
		"Ordinary Openings",
		"Mara is {{user}}'s adult partner and keeps a secret relationship hidden. The affair began after {{user}} passed out early at an ordinary party. Mara sometimes arranges meetings while {{user}} works late, and the roleplay opens while {{user}} is on a work call in another room. These temporary circumstances give Mara opportunities to manage the secret without defining {{user}}'s personality or reaction.",
		"Mara is hiding a message while {{user}} is on a work call, leaving what happens after the call entirely open."
	)
	var report := service._validate_idea_batch([idea], REPORTED_SEED)
	assert(
		(report.get("valid_ideas", []) as Array).size() == 1,
		"Passed out early / works late / on a work call must remain valid scene logistics. Issues: %s"
		% JSON.stringify(report.get("issues", []))
	)
	service.free()


func _test_substantive_user_canon_is_rejected() -> void:
	var service := SERVICE_SCRIPT.new() as CCFGenerationServiceV01536Hotfix2
	var stable_trait := _reported_idea(
		"Invented Personality",
		"Mara is {{user}}'s adult partner. {{user}} has always been jealous and controlling, which Mara uses to explain why she hides the affair.",
		"Mara comes home carrying a secret while {{user}} remains the person she is hiding it from."
	)
	var profession := _reported_idea(
		"Invented Career",
		"Mara is {{user}}'s adult partner. {{user}} works as a detective, so Mara has built elaborate counter-surveillance habits around the affair.",
		"Mara is trying to keep her secret intact around {{user}}."
	)
	var history := _reported_idea(
		"Invented History",
		"Mara is {{user}}'s adult partner. {{user}}'s childhood trauma created lifelong trust issues that shape every part of their relationship.",
		"Mara is withholding the affair while {{user}} remains free to respond however the roleplay develops."
	)
	for candidate in [stable_trait, profession, history]:
		var report := service._validate_idea_batch([candidate], REPORTED_SEED)
		assert(
			(report.get("valid_ideas", []) as Array).is_empty(),
			"Substantive invented {{user}} canon must fail validation. Candidate: %s"
			% str(candidate.get("title", ""))
		)
	service.free()


func _test_meaningful_user_response_is_rejected() -> void:
	var service := SERVICE_SCRIPT.new() as CCFGenerationServiceV01536Hotfix2
	var forced := _reported_idea(
		"Forced Confrontation",
		"Mara is {{user}}'s adult partner and has kept the affair hidden for months. {{user}} confronts Mara as soon as the suspicious message appears, forcing the conversation into an accusation scene.",
		"Mara is caught off guard when {{user}} is asking who keeps texting her."
	)
	var report := service._validate_idea_batch([forced], REPORTED_SEED)
	assert((report.get("valid_ideas", []) as Array).is_empty())
	var rendered := JSON.stringify(report.get("issues", []))
	assert(
		rendered.contains("meaningful {{user}} action") or rendered.contains("current {{user}} action"),
		"Forced confrontation/dialogue must fail for agency rather than scene-setting reasons. Issues: %s"
		% rendered
	)
	var conditional := _reported_idea(
		"Open Confrontation",
		"Mara is {{user}}'s adult partner and has kept the affair hidden for months. The pressure comes from whether {{user}} confronts her after noticing a clue, while Mara decides how much she is willing to reveal.",
		"Mara tries to contain the secret, leaving the next turn open depending on whether {{user}} confronts her."
	)
	var conditional_report := service._validate_idea_batch([conditional], REPORTED_SEED)
	assert(
		(conditional_report.get("valid_ideas", []) as Array).size() == 1,
		"Conditional user choices must remain valid. Issues: %s"
		% JSON.stringify(conditional_report.get("issues", []))
	)
	service.free()


func _test_prompt_and_repair_contract() -> void:
	var service := SERVICE_SCRIPT.new() as CCFGenerationServiceV01536Hotfix2
	var queued := service.queue_idea_generation(
		REPORTED_SEED,
		{
			"base_url": "https://example.invalid/v1",
			"model": "regression-model",
			"name": "Regression",
			"temperature": 0.8,
			"max_output_tokens": 4096
		},
		3,
		0
	)
	assert(bool(queued.get("ok", false)))
	var queue_value: Variant = service.get("_queue")
	assert(queue_value is Array and (queue_value as Array).size() == 1)
	var job: Dictionary = (queue_value as Array)[0]
	var metadata: Dictionary = job.get("metadata", {})
	assert(not bool(metadata.get("detached_pov_requested", true)))
	assert(int(metadata.get("idea_user_agency_contract_version", 0)) == 2)
	assert(bool(metadata.get("minor_user_scene_logistics_allowed", false)))
	var prompt_text := JSON.stringify(job.get("payload", {}).get("messages", []))
	assert(prompt_text.contains("USER AGENCY & BACKSTORY CONTRACT"))
	assert(prompt_text.contains("Minor temporary scene-setting circumstances ARE allowed"))
	assert(prompt_text.contains("passed out early"))
	assert(prompt_text.contains("works late"))
	assert(prompt_text.contains("work call"))

	service.set(
		"_active_job",
		{
			"metadata": {
				"seed": REPORTED_SEED,
				"semantic_repair_attempts": 0,
				"detached_pov_requested": false
			},
			"payload": {"messages": []}
		}
	)
	service._start_idea_semantic_repair(
		[_reported_idea("Repair Me", "Mara is {{user}}'s partner. {{user}} confronts her immediately.", "Mara faces {{user}}." )],
		["forced response"]
	)
	var active_value: Variant = service.get("_active_job")
	assert(active_value is Dictionary)
	var active: Dictionary = active_value
	var repair_text := JSON.stringify(active.get("payload", {}).get("messages", []))
	assert(repair_text.contains("Minor temporary {{user}} scene logistics are allowed"))
	assert(active.get("diagnostics_validation", {}) is Dictionary)
	assert(not (active.get("diagnostics_validation", {}) as Dictionary).is_empty())
	service.free()


func _test_real_main_wiring() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "The real main scene must load for hotfix2 regression coverage.")
	var app := packed.instantiate()
	root.add_child(app)
	for _frame in range(6):
		await process_frame
	var workspace_value: Variant = app.get("_workspace")
	assert(
		workspace_value is CCFWorkspaceV01536Hotfix2View,
		"The live app must install the v0.15.36-hotfix2 Workspace."
	)
	var workspace := workspace_value as CCFWorkspaceV01536Hotfix2View
	var idea_service_value: Variant = workspace.get("_idea_service_v01526")
	assert(
		idea_service_value is CCFGenerationServiceV01536Hotfix2,
		"The live Idea worker must use the refined hotfix2 service."
	)
	var capabilities := workspace.idea_agency_capabilities_v01536_hotfix2()
	assert(bool(capabilities.get("minor_scene_logistics_allowed", false)))
	assert(bool(capabilities.get("substantive_user_backstory_rejected", false)))
	assert(bool(capabilities.get("detached_pov_requires_explicit_role_request", false)))
	app.queue_free()
	await process_frame


func _reported_idea(title: String, concept: String, hook: String) -> Dictionary:
	return {
		"title": title,
		"character_name": "Mara Vale",
		"character_role": "{{user}}'s adult partner, who has developed a secret emotional or sexual dynamic with another man.",
		"source_anchor": "adult partner",
		"roleplay_hook": hook,
		"concept": concept,
		"tags": ["secret", "relationship"]
	}
