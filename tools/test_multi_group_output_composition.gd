extends SceneTree


func _init() -> void:
	var template := {
		"format_version": 3,
		"template_id": "multi_group_test",
		"name": "Multi-group test",
		"sections": [
			{
				"id": "character",
				"title": "Character",
				"kind": "standard",
				"fields": [
					{
						"id": "personality",
						"label": "Personality",
						"type": "multiline",
						"path": "character.personality",
						"generate": true,
						"required": true
					}
				]
			}
		],
		"generation_groups": [
			_group("personality_structure", "Personality Structure", "mind", "Mind"),
			_group("sexual_traits", "Sexual Traits", "experience_level", "Experience Level"),
			_group("background", "Background", "backstory", "Backstory")
		]
	}

	var contract := CCFGenerationContractService.contract_for_template(template)
	var field_rules: Dictionary = contract.get("field_rules", {})
	var personality_rule: Dictionary = field_rules.get("personality", {})
	var groups: Array = personality_rule.get("generation_groups", [])
	_assert(groups.size() == 3, "All groups bound to personality must remain in the contract.")
	_assert(str(groups[0].get("title", "")) == "Personality Structure", "Group order must be preserved.")
	_assert(str(groups[1].get("title", "")) == "Sexual Traits", "Second group order must be preserved.")
	_assert(str(groups[2].get("title", "")) == "Background", "Third group order must be preserved.")

	var prompt := CCFGenerationContractService.prompt_text(contract)
	var personality_position := prompt.find("Personality Structure")
	var sexual_position := prompt.find("Sexual Traits")
	var background_position := prompt.find("Background")
	_assert(personality_position >= 0, "Prompt must include the first group.")
	_assert(sexual_position > personality_position, "Prompt must append the second group after the first.")
	_assert(background_position > sexual_position, "Prompt must append the third group after the second.")
	_assert(prompt.contains("never replace an earlier group"), "Prompt must explicitly forbid overwrite behavior.")

	var overwritten_result := {
		"personality": "Background\nBackstory: She grew up near the coast and later moved to the city."
	}
	var overwritten_report := CCFGenerationContractService.validate_generated_data(
		overwritten_result, contract
	)
	_assert(not bool(overwritten_report.get("ok", true)), "A last-group-only result must fail validation.")
	_assert(_has_issue_for_group(overwritten_report, "Personality Structure"), "Missing first group must be reported.")
	_assert(_has_issue_for_group(overwritten_report, "Sexual Traits"), "Missing middle group must be reported.")

	var complete_result := {
		"personality": (
			"Personality Structure\n"
			+ "Mind: Thoughtful, curious, and privately stubborn.\n\n"
			+ "Sexual Traits\n"
			+ "Experience Level: Limited but self-aware.\n\n"
			+ "Background\n"
			+ "Backstory: She grew up near the coast and later moved to the city."
		)
	}
	var complete_report := CCFGenerationContractService.validate_generated_data(
		complete_result, contract
	)
	_assert(bool(complete_report.get("ok", false)), "A composed field containing all groups must pass validation.")

	print("Multi-group output composition regression passed.")
	quit(0)


func _group(group_id: String, title: String, component_id: String, label: String) -> Dictionary:
	return {
		"id": group_id,
		"title": title,
		"output_field_id": "personality",
		"enabled": true,
		"allow_extra_components": false,
		"components": [
			{
				"id": component_id,
				"label": label,
				"enabled": true,
				"required": true,
				"instruction": "Provide useful character-card detail."
			}
		]
	}


func _has_issue_for_group(report: Dictionary, group_title: String) -> bool:
	var issues: Variant = report.get("issues", [])
	if not issues is Array:
		return false
	for raw_issue in issues:
		if raw_issue is Dictionary and str(raw_issue.get("group_title", "")) == group_title:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
