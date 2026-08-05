extends SceneTree

const GENERATION_SERVICE = preload(
	"res://scripts/services/generation_service_v01537_hotfix1.gd"
)

const SCENARIO_BODY := "You and Cherry have been dating for almost six months. Tonight, after a romantic dinner, Cherry invites {{user}} back to her apartment. The scene establishes a hidden complication, a convenience-store errand, an incoming message, and a decision point that should remain in the Scenario field. This paragraph is intentionally long enough to exercise CCF's cross-section fingerprint guard rather than a short-text heuristic. The outcome remains open and the player keeps agency over {{user}}."
const FIRST_MESSAGE_BODY := "*The evening had been warm and affectionate until Cherry's expression changed.* She pauses, covers the shift with a smile, asks {{user}} to pick something up from the nearby store, and waits for an answer. Her phone buzzes on the nightstand and she glances at it before looking back. This is deliberately a long opening-message fixture so CCF can distinguish an opening scene from an unrelated personality-history component without relying on explicit sexual content."


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service := GENERATION_SERVICE.new()
	root.add_child(service)
	var caps := service.safe_section_guard_capabilities_v01537_hotfix1()
	assert(bool(caps.get("exact_standalone_field_key", false)), "Hotfix must require the exact standalone field key.")
	assert(bool(caps.get("generic_value_key_repair_only", false)), "Generic value output must be restricted to focused repair.")
	assert(bool(caps.get("parallel_children_use_hotfix_guard", false)), "Parallel Safe Section workers must use the hotfix guard.")

	var concept := "# TEST BLUEPRINT\n\n## ROLEPLAY SCENARIO\n%s\n\n## FIRST MESSAGE REQUIREMENTS\nRequirements remain separate.\n\n### Final First Message Text:\n%s\n\n## LOREBOOK\nSee structured lorebook entries below.\n" % [SCENARIO_BODY, FIRST_MESSAGE_BODY]
	var state := {"concept": concept}

	var turn_ons_field := {
		"kind": "standalone_field",
		"id": "turn_ons",
		"field_id": "turn_ons",
		"title": "Turn-ons",
		"field": {"id": "turn_ons", "label": "Turn-ons", "type": "multiline", "required": true}
	}
	var wrong_key := service.validate_safe_section_candidate_v01537_hotfix1(
		turn_ons_field,
		{"scenario": SCENARIO_BODY},
		state
	)
	assert(not bool(wrong_key.get("ok", true)), "An unrelated one-key object must not be accepted as the requested standalone field.")
	assert(str((wrong_key.get("issues", []) as Array)[0]).contains("exact key"), "Wrong-key rejection must explain the field-identity mismatch.")

	var right_key_wrong_content := service.validate_safe_section_candidate_v01537_hotfix1(
		turn_ons_field,
		{"turn_ons": SCENARIO_BODY},
		state
	)
	assert(not bool(right_key_wrong_content.get("ok", true)), "Correctly keyed Scenario content must still be rejected when routed into Turn-ons.")
	assert(not (right_key_wrong_content.get("issues", []) as Array).is_empty(), "Cross-section contamination must produce a diagnostic issue.")

	var personality_group := {
		"id": "personality_structure",
		"title": "Personality structure",
		"output_field_id": "personality",
		"allow_extra_components": false,
		"components": [
			{"id": "turn_ons", "label": "Turn-ons", "enabled": true, "required": true},
			{"id": "turn_offs", "label": "Turn-offs", "enabled": true, "required": true},
			{"id": "kinks", "label": "Kinks", "enabled": true, "required": true},
			{"id": "virginity_history", "label": "How they lost their virginity", "enabled": true, "required": true}
		]
	}
	var personality_section := {
		"kind": "output_group",
		"id": "personality_structure",
		"title": "Personality structure",
		"field_id": "personality",
		"group": personality_group
	}
	var contaminated_group := service.validate_safe_section_candidate_v01537_hotfix1(
		personality_section,
		{
			"turn_ons": SCENARIO_BODY,
			"turn_offs": SCENARIO_BODY,
			"kinks": "Lorebook Entries:\n\n1. **Key: cherry**\n   - Structured recall material that belongs in the Lorebook rather than a Kinks component.",
			"virginity_history": FIRST_MESSAGE_BODY
		},
		state
	)
	assert(not bool(contaminated_group.get("ok", true)), "The Cherry/Jerry-shaped Personality contamination fixture must be rejected.")
	var contamination: Dictionary = contaminated_group.get("contamination", {})
	assert(not contamination.is_empty(), "Group contamination must identify an offending component.")

	var label_key_group := service.validate_safe_section_candidate_v01537_hotfix1(
		personality_section,
		{
			"Turn-ons": "Confidence and playful teasing.",
			"Turn-offs": "Dishonesty and unnecessary cruelty.",
			"Kinks": "Roleplay and consensual power exchange.",
			"How they lost their virginity": "A private past relationship, described briefly."
		},
		state
	)
	assert(not bool(label_key_group.get("ok", true)), "Component labels must not substitute for the requested component IDs.")
	assert(not (label_key_group.get("missing_keys", []) as Array).is_empty(), "Label-key output should report missing exact component IDs.")

	var clean_group := service.validate_safe_section_candidate_v01537_hotfix1(
		personality_section,
		{
			"turn_ons": "Confident partners, playful teasing, and feeling deliberately chosen.",
			"turn_offs": "Being pressured, having her boundaries dismissed, and empty flattery.",
			"kinks": "Consensual roleplay and negotiated power exchange.",
			"virginity_history": "Her first relationship developed slowly and remains a private part of her past."
		},
		state
	)
	assert(bool(clean_group.get("ok", false)), "A clean, correctly keyed Personality group must remain valid.")

	var assembled_personality := (
		"Turn-ons: %s\n\nTurn-offs: %s\n\nKinks: Lorebook Entries:\n\n1. **Key: cherry**\nA structured recall entry.\n\nHow they lost their virginity: %s"
		% [SCENARIO_BODY, SCENARIO_BODY, FIRST_MESSAGE_BODY]
	)
	var assembled_issues := service.assembled_contamination_issues_v01537_hotfix1(
		{"personality": assembled_personality, "scenario": SCENARIO_BODY},
		state
	)
	assert(not assembled_issues.is_empty(), "Final assembled validation must catch contamination even if an earlier section-level check is bypassed.")

	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null, "The v0.15.37-hotfix1 main scene must load.")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	assert(app.has_method("_update_build_version_label_v01537_hotfix1"), "The active shell must be v0.15.37-hotfix1.")
	var workspace_value: Variant = app.get("_workspace")
	assert(workspace_value is CCFWorkspaceV01537Hotfix1View, "The real app must install the hotfix1 Workspace.")
	var workspace := workspace_value as CCFWorkspaceV01537Hotfix1View
	var workspace_caps := workspace.safe_section_guard_capabilities_v01537_hotfix1()
	assert(bool(workspace_caps.get("assembled_cross_field_guard", false)), "The live Workspace must expose the assembled contamination guard.")

	app.queue_free()
	service.queue_free()
	await process_frame
	print("v0.15.37-hotfix1 Safe Section contamination regression passed")
	quit(0)
