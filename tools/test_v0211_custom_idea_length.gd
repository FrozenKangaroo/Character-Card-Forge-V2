extends SceneTree

const CUSTOM_LENGTH = preload(
	"res://scripts/services/idea_generator_custom_length_v0211.gd"
)
const GENERATION_CURRENT = preload(
	"res://scripts/services/generation_service_current.gd"
)

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_length_contract()
	if not _failed:
		await _test_live_workspace()
	if _failed:
		quit(1)
		return
	print("V0211_CUSTOM_IDEA_LENGTH_OK")
	quit(0)


func _test_length_contract() -> void:
	_require(
		CUSTOM_LENGTH.normalise_target_characters(1)
		== CUSTOM_LENGTH.MIN_TARGET_CHARACTERS,
		"Custom targets below the supported range must clamp safely."
	)
	_require(
		CUSTOM_LENGTH.normalise_target_characters(999999)
		== CUSTOM_LENGTH.MAX_TARGET_CHARACTERS,
		"Custom targets above the supported range must clamp safely."
	)
	var uncapped := CUSTOM_LENGTH.output_budget(2000, 2, 10000)
	_require(
		int(uncapped.get("effective_output_tokens", 0))
		== int(uncapped.get("requested_output_tokens", -1))
		and not bool(uncapped.get("budget_limited", true)),
		"A feasible custom target must derive its output allowance without using the whole profile maximum."
	)
	var capped := CUSTOM_LENGTH.output_budget(8000, 3, 5000)
	_require(
		int(capped.get("effective_output_tokens", 0)) == 5000
		and bool(capped.get("budget_limited", false)),
		"A large target must remain capped by the configured model/profile maximum output."
	)
	var instruction := CUSTOM_LENGTH.prompt_instruction(8000)
	_require(
		instruction.contains("approximately 8000 characters")
		and instruction.contains("soft authoring target")
		and instruction.contains("{{user}} agency"),
		"The custom prompt must state the target while retaining quality and agency contracts."
	)

	var service := GENERATION_CURRENT.new()
	root.add_child(service)
	var fixture_job := {
		"id": "custom-length-fixture",
		"type": "ideas",
		"payload": {
			"max_tokens": 10000,
			"messages": [
				{
					"role": "system",
					"content": "BASE IDEA CONTRACT — preserve {{user}} agency."
				},
				{"role": "user", "content": "Generate two ideas."}
			]
		},
		"metadata": {"idea_count": 2, "seed": ""}
	}
	var decoration: Dictionary = service.call(
		"_idea_job_with_custom_length_v0211", fixture_job, 2000
	)
	var decorated: Dictionary = decoration.get("job", {})
	var payload: Dictionary = decorated.get("payload", {})
	var messages: Array = payload.get("messages", [])
	var system_text := str((messages[0] as Dictionary).get("content", ""))
	var budget: Dictionary = decoration.get("budget", {})
	_require(
		system_text.contains("CUSTOM IDEA LENGTH TARGET")
		and system_text.contains("approximately 2000 characters"),
		"Custom length guidance must reach the queued system prompt."
	)
	_require(
		int(payload.get("max_tokens", 0))
		== int(budget.get("effective_output_tokens", -1))
		and int(payload.get("max_tokens", 0)) < 10000,
		"The request must use the derived allowance rather than blindly spending the profile maximum."
	)
	var metadata: Dictionary = decorated.get("metadata", {})
	_require(
		str(metadata.get("idea_detail_level", "")) == "custom"
		and int(metadata.get("idea_custom_target_characters", 0)) == 2000
		and int(metadata.get("idea_custom_profile_max_output_tokens", 0)) == 10000,
		"Queued metadata must retain the custom target and provider/profile ceiling."
	)

	service.set("_active_job", decorated)
	var ideas := [
		_valid_idea("Near target", _concept_of_length(2000)),
		_valid_idea("Model miss", _concept_of_length(900))
	]
	var validation: Dictionary = service.call(
		"_validate_idea_batch", ideas, ""
	)
	var accepted: Array = validation.get("valid_ideas", [])
	_require(
		accepted.size() == 2,
		"Missing a soft character target must not reject or repair an otherwise valid idea."
	)
	var completed_metadata: Dictionary = (
		service.get("_active_job") as Dictionary
	).get("metadata", {})
	var actual_counts: Array = completed_metadata.get(
		"idea_actual_character_counts", []
	)
	_require(
		actual_counts.size() == 2
		and int(actual_counts[0]) == 2000
		and int(actual_counts[1]) == 900
		and int(completed_metadata.get("idea_custom_target_met_count", 0)) == 1,
		"Completed metadata must report actual concept lengths and target-range compliance."
	)
	service.queue_free()


func _test_live_workspace() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current application scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceCurrent,
		"The live shell must install the current Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceCurrent
	var selector := workspace.find_child(
		"IdeaDetailLevelSelectorV0167", true, false
	) as OptionButton
	var target := workspace.find_child(
		"IdeaCustomTargetCharactersV0211", true, false
	) as SpinBox
	var panel := workspace.find_child(
		"IdeaCustomLengthPanelV0211", true, false
	) as VBoxContainer
	if not _require(
		selector != null and target != null and panel != null,
		"The live Idea Generator must expose the Custom detail controls."
	):
		return
	var ids: Array[String] = []
	for index in range(selector.item_count):
		ids.append(str(selector.get_item_metadata(index)))
	_require(
		ids == ["quick", "standard", "detailed", "extended", "custom"],
		"Quick, Standard, Detailed and Extended must remain unchanged before Custom."
	)
	_require(not panel.visible, "Custom controls must stay hidden for the default Standard preset.")
	selector.select(4)
	workspace.call("_on_idea_detail_selected_v0167", 4)
	target.value = 7750
	await process_frame
	var capabilities := workspace.idea_custom_length_capabilities_v0211()
	_require(
		str(capabilities.get("selected_level", "")) == "custom"
		and int(capabilities.get("target_characters", 0)) == 7750
		and bool(capabilities.get("custom_controls_visible", false))
		and bool(capabilities.get("presets_preserved", false)),
		"Selecting Custom must reveal and retain the current per-idea character target."
	)
	var service_capabilities: Dictionary = capabilities.get("service", {})
	_require(
		bool(service_capabilities.get("profile_output_cap_preserved", false))
		and bool(service_capabilities.get("advisory_not_validation_failure", false))
		and bool(service_capabilities.get("actual_counts_in_metadata", false)),
		"The live generation service must advertise safe budget capping and advisory result measurement."
	)
	selector.select(1)
	workspace.call("_on_idea_detail_selected_v0167", 1)
	await process_frame
	_require(
		not panel.visible,
		"Returning to a preset must hide Custom controls without removing the preset."
	)
	app.queue_free()
	await process_frame


func _valid_idea(title: String, concept: String) -> Dictionary:
	return {
		"title": title,
		"character_name": "Mika",
		"character_role": "Mika is {{user}}'s travelling companion.",
		"source_anchor": "",
		"roleplay_hook": "Mika asks {{user}} to choose the next stop.",
		"concept": concept,
		"tags": ["travel"]
	}


func _concept_of_length(target_length: int) -> String:
	var prefix := "Mika travels beside {{user}}. "
	if target_length <= prefix.length():
		return prefix.left(target_length)
	return prefix + "x".repeat(target_length - prefix.length())


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
