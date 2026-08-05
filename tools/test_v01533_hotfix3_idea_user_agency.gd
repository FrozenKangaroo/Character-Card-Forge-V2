extends SceneTree

const SERVICE_SCRIPT = preload(
	"res://scripts/services/generation_service_v01533_hotfix3.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_prompt_contract()
	_test_agency_validation()
	_test_repair_contract()
	await _test_real_main_wiring()
	print("v0.15.33-hotfix3 AI Ideas user agency regression passed")
	quit(0)


func _test_prompt_contract() -> void:
	var service := SERVICE_SCRIPT.new() as CCFGenerationServiceV01533Hotfix3
	var queued := service.queue_idea_generation(
		"{{user}} suddenly got a new stepsister after their parents remarried.",
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
	assert(bool(queued.get("ok", false)), "Idea generation fixture must queue successfully.")
	var queue_value: Variant = service.get("_queue")
	assert(queue_value is Array and (queue_value as Array).size() == 1)
	var job: Dictionary = (queue_value as Array)[0]
	var metadata: Dictionary = job.get("metadata", {})
	assert(
		int(metadata.get("idea_user_agency_contract_version", 0)) == 1,
		"Queued Idea jobs must record the user-agency contract version."
	)
	var payload: Dictionary = job.get("payload", {})
	var messages: Array = payload.get("messages", [])
	var rendered := JSON.stringify(messages)
	assert(rendered.contains("USER AGENCY CONTRACT"))
	assert(rendered.contains("controlled exclusively by the person roleplaying"))
	assert(rendered.contains("Never decide or assert {{user}}'s new actions"))
	assert(rendered.contains("whether {{user}} forgives her"))
	service.free()


func _test_agency_validation() -> void:
	var service := SERVICE_SCRIPT.new() as CCFGenerationServiceV01533Hotfix3
	var seed := "{{user}} suddenly got a new stepsister after their parents remarried."
	var invalid_action := _idea(
		"The Confrontation",
		"Hana is {{user}}'s new stepsister. She keeps her distance at home until {{user}} confronts Hana about her guarded behaviour.",
		"Hana's guarded routine creates tension with {{user}}, who confronts her and demands an explanation."
	)
	var invalid_state := _idea(
		"Jealous Household",
		"Hana is {{user}}'s new stepsister and grows close to another family member while {{user}} is jealous of the attention she gives them.",
		"Hana notices the household tension around {{user}} and tries to understand it."
	)
	var open_choice := _idea(
		"A Door Left Open",
		"Hana is {{user}}'s new stepsister and keeps an important secret. The tension centres on whether {{user}} confronts her or lets the subject rest while Hana decides how much to reveal.",
		"Hana tries to keep the secret contained, leaving the next turn open depending on whether {{user}} confronts her."
	)
	var character_focused := _idea(
		"The Guarded Stepsister",
		"Hana is {{user}}'s new stepsister and worries that {{user}} may never accept the changed household. She becomes defensive whenever family expectations push them together.",
		"Hana wants to protect herself from rejection while leaving {{user}} free to approach, avoid, question, or challenge her as the roleplay develops."
	)

	var invalid_action_report := service._validate_idea_batch([invalid_action], seed)
	assert((invalid_action_report.get("valid_ideas", []) as Array).is_empty())
	assert(
		JSON.stringify(invalid_action_report.get("issues", [])).contains("new {{user}} action/reaction"),
		"A model-invented {{user}} confrontation must fail semantic validation."
	)
	var invalid_state_report := service._validate_idea_batch([invalid_state], seed)
	assert((invalid_state_report.get("valid_ideas", []) as Array).is_empty())
	assert(
		JSON.stringify(invalid_state_report.get("issues", [])).contains("new {{user}} feeling/state"),
		"A model-invented {{user}} feeling must fail semantic validation."
	)
	var choice_report := service._validate_idea_batch([open_choice], seed)
	assert(
		(choice_report.get("valid_ideas", []) as Array).size() == 1,
		"Conditional choices such as whether {{user}} confronts the character must remain valid."
	)
	var focused_report := service._validate_idea_batch([character_focused], seed)
	assert(
		(focused_report.get("valid_ideas", []) as Array).size() == 1,
		"Character-focused uncertainty must remain valid when it leaves {{user}}'s response open."
	)

	var established_seed := "{{user}} catches Hana hiding a second phone after dinner."
	var established := {
		"title": "Caught With the Second Phone",
		"character_name": "Hana",
		"character_role": "the person {{user}} catches hiding a second phone",
		"source_anchor": "catches Hana hiding a second phone",
		"roleplay_hook": "After {{user}} catches Hana hiding the phone, Hana must decide whether to explain why she has it or keep deflecting.",
		"concept": "Hana is the person {{user}} catches hiding a second phone after dinner. The discovery puts pressure on Hana to protect her secret while leaving {{user}}'s response entirely open.",
		"tags": ["secret", "family"]
	}
	var established_report := service._validate_idea_batch([established], established_seed)
	assert(
		(established_report.get("valid_ideas", []) as Array).size() == 1,
		"A {{user}} action explicitly established by the source premise must be preservable as setup."
	)
	service.free()


func _test_repair_contract() -> void:
	var service := SERVICE_SCRIPT.new() as CCFGenerationServiceV01533Hotfix3
	service.set(
		"_active_job",
		{
			"metadata": {
				"seed": "{{user}} got a new stepsister.",
				"semantic_repair_attempts": 0,
				"detached_pov_requested": false
			},
			"payload": {"messages": []}
		}
	)
	service._start_idea_semantic_repair(
		[_idea("Repair Me", "Hana is {{user}}'s new stepsister and {{user}} forgives her immediately.", "{{user}} forgives Hana.")],
		["concept asserts a new {{user}} action/reaction"]
	)
	var active_value: Variant = service.get("_active_job")
	assert(active_value is Dictionary)
	var payload: Dictionary = (active_value as Dictionary).get("payload", {})
	var rendered := JSON.stringify(payload.get("messages", []))
	assert(rendered.contains("USER AGENCY CONTRACT"))
	assert(rendered.contains("Preserve only {{user}} actions already established by SOURCE PREMISE"))
	service.free()


func _test_real_main_wiring() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "The real main scene must load for user-agency regression coverage.")
	var app := packed.instantiate()
	root.add_child(app)
	for _frame in range(6):
		await process_frame
	var workspace_value: Variant = app.get("_workspace")
	assert(
		workspace_value is CCFWorkspaceV01533Hotfix3View,
		"The live app must install the v0.15.33-hotfix3 Workspace."
	)
	var workspace := workspace_value as CCFWorkspaceV01533Hotfix3View
	var idea_service_value: Variant = workspace.get("_idea_service_v01526")
	assert(
		idea_service_value is CCFGenerationServiceV01533Hotfix3,
		"The live Idea worker must use the user-agency-aware generation-service leaf."
	)
	var capabilities := workspace.idea_user_agency_capabilities_v01533_hotfix3()
	assert(bool(capabilities.get("prompt_contract", false)))
	assert(bool(capabilities.get("semantic_validation", false)))
	assert(bool(capabilities.get("source_premise_actions_preserved", false)))
	app.queue_free()
	await process_frame


func _idea(title: String, concept: String, hook: String) -> Dictionary:
	return {
		"title": title,
		"character_name": "Hana",
		"character_role": "{{user}}'s new stepsister",
		"source_anchor": "new stepsister",
		"roleplay_hook": hook,
		"concept": concept,
		"tags": ["stepsister", "family"]
	}
