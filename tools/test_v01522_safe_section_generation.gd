extends SceneTree


func _init() -> void:
	var service := CCFGenerationServiceV01522.new()
	var capabilities := service.strategy_capabilities_v01522()
	assert(str(capabilities.get("default", "")) == "safe_section", "Safe Section Build must be the default generation strategy.")
	assert(bool(capabilities.get("component_level_repair", false)), "Safe generation must advertise focused component repair.")
	assert(CCFGenerationServiceV01522.normalise_generation_strategy_v01522("") == "safe_section", "Missing/legacy strategy settings must migrate safely to Safe Section Build.")
	assert(CCFGenerationServiceV01522.normalise_generation_strategy_v01522("fast_full") == "fast_full", "Fast Full Card must remain an explicit opt-in strategy.")

	var template := CCFTemplateService.load_default_template().duplicate(true)
	var groups: Array = template.get("generation_groups", []).duplicate(true)
	groups.append(
		{
			"id": "sexual_traits",
			"title": "Sexual Traits",
			"output_field_id": "personality",
			"enabled": true,
			"allow_extra_components": false,
			"components": [
				{
					"id": "experience_level",
					"label": "Experience Level",
					"enabled": true,
					"required": true,
					"instruction": "Describe the character's established experience level."
				},
				{
					"id": "protection",
					"label": "Protection",
					"enabled": true,
					"required": true,
					"instruction": "Describe established protection preferences when relevant."
				}
			]
		}
	)
	template["generation_groups"] = groups
	template = CCFTemplateService.normalise_template(template)
	var plan := service.generation_plan_v01522(template)
	assert(not plan.is_empty(), "Safe Section Build must create a data-driven generation plan.")

	var description_groups := 0
	var personality_groups := 0
	var standalone_personality := 0
	var scenario_sections := 0
	var first_message_sections := 0
	var sexual_group_found := false
	for raw_section in plan:
		assert(raw_section is Dictionary, "Every safe generation plan item must be a dictionary section.")
		var section: Dictionary = raw_section
		var kind := str(section.get("kind", ""))
		var field_id := str(section.get("field_id", ""))
		if kind == "output_group" and field_id == "description":
			description_groups += 1
		if kind == "output_group" and field_id == "personality":
			personality_groups += 1
			if str(section.get("title", "")) == "Sexual Traits":
				sexual_group_found = true
		if kind == "standalone_field" and field_id == "personality":
			standalone_personality += 1
		if kind == "standalone_field" and field_id == "scenario":
			scenario_sections += 1
		if kind == "standalone_field" and field_id == "first_message":
			first_message_sections += 1
	assert(description_groups == 1, "Description's enabled Output Group must become one safe-build section.")
	assert(personality_groups == 2, "Multiple enabled Output Groups targeting Personality must remain separate safe-build sections.")
	assert(sexual_group_found, "A separately configured Sexual Traits Output Group must remain its own safe-build section.")
	assert(standalone_personality == 0, "A field targeted by Generation Output Groups must not also be generated as a duplicate standalone section.")
	assert(scenario_sections == 1, "Scenario must be a standalone safe-build section when it has no Generation Output Group.")
	assert(first_message_sections == 1, "First Message must be a standalone safe-build section when it has no Generation Output Group.")

	var accepted_groups := {
		"personality_structure": {
			"components": {
				"mind": "Playful, perceptive, and stubborn.",
				"emotional_tendencies": "Masks worry with teasing.",
				"likes": "Arcades and late-night ramen.",
				"dislikes": "Being patronised.",
				"boundaries": "Refuses cruelty toward friends.",
				"relationship_behavior": "Teases {{user}} but becomes fiercely supportive.",
				"speech_style": "Casual, quick, and lightly sarcastic."
			},
			"extras": []
		},
		"sexual_traits": {
			"components": {
				"experience_level": "Moderate and self-aware.",
				"protection": "Prefers clear planning and mutual responsibility."
			},
			"extras": []
		}
	}
	var assembled := service._assembled_safe_fields_v01522(
		{
			"generation_template": template,
			"accepted_fields": {},
			"accepted_groups": accepted_groups
		}
	)
	var personality_text := str(assembled.get("personality", ""))
	assert(personality_text.contains("Personality structure:"), "When multiple Output Groups target one field, the first group title must be retained as a section heading.")
	assert(personality_text.contains("Sexual Traits:"), "Later Output Groups must append after earlier groups instead of overwriting them.")
	assert(personality_text.contains("Protection: Prefers clear planning"), "Configured component labels must be materialised by CCF in template order.")

	var redacted: Variant = service.sanitise_diagnostic_value_v01522(
		{
			"api_key": "super-secret-key",
			"authorization": "Bearer super-secret-key",
			"max_tokens": 6000,
			"messages": [{"role": "user", "content": "debug me"}]
		}
	)
	assert(redacted is Dictionary, "Diagnostic sanitisation must preserve inspectable structure.")
	assert(str(redacted.get("api_key", "")) == "[REDACTED]", "API keys must never be exposed in Generation Diagnostics.")
	assert(str(redacted.get("authorization", "")) == "[REDACTED]", "Authorization headers must never be exposed in Generation Diagnostics.")
	assert(int(redacted.get("max_tokens", 0)) == 6000, "Non-secret generation settings such as token limits must remain visible for debugging.")

	var settings_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v01522.gd")
	assert(settings_source.contains("Generation strategy"), "Character AI settings must expose the new Generation Strategy separately from Mode & Style.")
	assert(settings_source.contains("Safe Section Build — Recommended"), "The settings UI must identify Safe Section Build as recommended.")
	assert(settings_source.contains("Fast Full Card"), "The faster one-request strategy must remain available as an explicit choice.")
	assert(settings_source.contains("separate from Generation Mode / Style"), "The UI must explain that strategy and existing Generation Mode are different controls.")

	var diagnostics_source := FileAccess.get_file_as_string("res://scripts/ui/generation_diagnostics_window_v01522.gd")
	for marker in ["Raw API Response", "Assistant Text", "Parsed Output", "Validation", "Save Diagnostic Bundle", "Credentials are redacted"]:
		assert(diagnostics_source.contains(marker), "Generation Diagnostics is missing %s." % marker)

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01522.gd")
	assert(workspace_source.contains("queue_character_generation_with_strategy"), "The live Workspace Generate Character action must route through the strategy-aware service.")
	assert(workspace_source.contains("View Diagnostics…"), "Terminal generation failures must expose a View Diagnostics action.")
	assert(workspace_source.contains('extends "res://scripts/ui/workspace_v01521.gd"'), "v0.15.22 must preserve v0.15.21 Collaborator attachment behavior through inheritance.")

	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01522.gd")
	for marker in ["SAFE SECTION BUILD — GENERATE ONLY THIS OUTPUT GROUP", "FOCUSED MISSING-COMPONENT REPAIR", "safe_pending_group_components", "raw_api_response", "diagnostics_available"]:
		assert(service_source.contains(marker), "v0.15.22 generation service is missing %s." % marker)
	assert(service is CCFGenerationServiceV01517, "v0.15.22 must extend the restored v0.15.17 parity/Blueprint generation service rather than bypass it.")
	assert(service is CCFConceptFidelityGenerationService, "v0.15.22 must retain concept-fidelity validation.")
	assert(service is CCFModeStyleGenerationService, "v0.15.22 must retain existing Generation Mode & Style guidance.")
	assert(service is CCFInterviewGenerationService, "v0.15.22 must retain Interview/Q&A planning.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01522.gd")
	assert(main_source.contains('BUILD_DISPLAY_VERSION_V01522 := "0.15.22"'), "The v0.15.22 shell must expose its build version.")
	assert(_active_shell_inherits_from("res://scripts/main_v01522.gd"), "The active scene must use or inherit v0.15.22.")

	service.free()
	print("v0.15.22 Safe Section Build + Generation Diagnostics regression passed")
	quit(0)


func _active_shell_inherits_from(target_path: String) -> bool:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	if root == null:
		return false
	var current := root.get_script() as Script
	while current != null:
		if current.resource_path == target_path:
			root.free()
			return true
		current = current.get_base_script()
	root.free()
	return false
