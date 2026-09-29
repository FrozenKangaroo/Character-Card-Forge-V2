extends SceneTree

const REVIEW = preload("res://scripts/services/idea_final_review_service_v0218.gd")
const DIVERSITY = preload("res://scripts/services/idea_diversity_guardrails_v0214.gd")

var _failed := false


class FakeGenerationService:
	extends CCFGenerationService

	var requests: Array[int] = []
	var seeds: Array[String] = []
	var series_contexts: Array[String] = []
	var decorations: Array[Dictionary] = []
	var next_id := 1

	func queue_idea_generation_with_detail_v0167(
		seed_text: String,
		_profile: Dictionary,
		idea_count: int,
		_retry_count: int,
		_project_id: String = "",
		series_context: String = "",
		_detail_level_id: String = "standard"
	) -> Dictionary:
		requests.append(idea_count)
		seeds.append(seed_text)
		series_contexts.append(series_context)
		var job_id := "v0219-idea-%d" % next_id
		next_id += 1
		return {"ok": true, "job_id": job_id, "queued_ahead": 0}

	func decorate_idea_batch_job_v0211(
		job_id: String,
		_group_id: String,
		_batch_index: int,
		_request_count: int,
		_requested_total: int,
		anti_repeat_context: String = "",
		request_kind: String = "normal"
	) -> bool:
		decorations.append({
			"job_id": job_id,
			"anti_repeat_context": anti_repeat_context,
			"request_kind": request_kind
		})
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_frozen_context_seed_and_review_scope()
	await _test_live_dialog_batching_persistence_and_cancel()
	if _failed:
		quit(1)
		return
	print("V0219_EDITABLE_GENERATE_MORE_INSTRUCTION_OK")
	quit(0)


func _test_frozen_context_seed_and_review_scope() -> void:
	var plain := _curation(
		"project-plain",
		"Original plain prompt",
		"",
		"",
		"",
		"SERIES: frozen plain series",
		2
	)
	var plain_extension := REVIEW.create_extension_session(
		plain, 2, 2, "Set this scenario in Antarctica."
	)
	var plain_context: Dictionary = plain_extension.get("generation_context", {})
	_require(
		str(plain_context.get("prompt_mode", "")) == "primary_prompt"
		and str(plain_context.get("seed_text", "")) == "Set this scenario in Antarctica."
		and str(plain_extension.get("seed_snapshot", "")) == "Set this scenario in Antarctica."
		and str(plain_extension.get("series_context_snapshot", "")) == "SERIES: frozen plain series"
		and DIVERSITY.accepted_count(plain_extension) == 2
		and DIVERSITY.anti_repeat_prompt(plain_extension).contains("Remembered rejection"),
		"A plain-prompt extension must use the edited prompt while retaining Series and anti-repeat memory."
	)

	var source_context := "FROZEN IDEA SOURCE CONTEXT\nCanonical engine and constraints."
	var source := _curation(
		"project-source",
		"Focus on workplace scenarios.",
		"source-frozen",
		"She Got Pregnant",
		source_context,
		"SERIES: frozen source series",
		2
	)
	source["review_adherence"] = true
	source["review_similarity"] = true
	source["final_top_up_enabled"] = true
	var antarctic := "Set these at an Antarctic research station."
	var source_extension := REVIEW.create_extension_session(source, 2, 2, antarctic)
	var source_generation_context: Dictionary = source_extension.get(
		"generation_context", {}
	)
	_require(
		REVIEW.extension_prompt_mode(source) == "additional_direction"
		and REVIEW.extension_instruction(source) == "Focus on workplace scenarios."
		and str(source_generation_context.get("seed_text", "")) == antarctic
		and str(source_generation_context.get("idea_source_id", "")) == "source-frozen"
		and str(source_generation_context.get("idea_source_title", "")) == "She Got Pregnant"
		and str(source_generation_context.get("idea_source_context", "")) == source_context
		and str(source_generation_context.get("series_context", "")) == "SERIES: frozen source series"
		and str(source_extension.get("seed_snapshot", "")) == (
			source_context
			+ "\n\nCURRENT IDEA-GENERATOR PROMPT / ADDITIONAL DIRECTION:\n"
			+ antarctic
		),
		"An Idea Source extension must preserve the frozen source and Series while replacing only Additional Direction."
	)
	var blank_direction := REVIEW.create_extension_session(source, 1, 1, "")
	_require(
		str(blank_direction.get("seed_snapshot", "")) == source_context
		and str((blank_direction.get("generation_context", {}) as Dictionary).get(
			"seed_text", "not blank"
		)) == "",
		"Clearing Additional Direction must generate from the frozen Idea Source without an empty direction block."
	)

	DIVERSITY.record_batch(source_extension, _ideas("Antarctic", 2))
	var scope_ids := REVIEW.review_scope_ids(source_extension)
	var baseline_ids: Array = source_extension.get("extension_baseline_ids", [])
	_require(
		scope_ids.size() == 2
		and baseline_ids.size() == 2
		and REVIEW.review_records(source_extension).size() == 2,
		"Manual extension review scope must contain only newly generated candidates."
	)
	var old_first := str(baseline_ids[0])
	var old_second := str(baseline_ids[1])
	var new_first := scope_ids[0]
	var new_second := scope_ids[1]
	var prompt := REVIEW.final_review_prompt(source_extension)
	_require(
		prompt.contains("CURRENT EXTENSION CANDIDATE")
		and prompt.contains("EXISTING RETAINED IDEA — similarity reference only")
		and prompt.contains("Do not judge EXISTING RETAINED IDEAS"),
		"The extension review prompt must clearly separate current candidates from older similarity references."
	)
	var normalised := REVIEW.normalise_review({
		"ideas": [
			{"idea_id": old_first, "adherence": "clear_mismatch", "reason": "Old direction."},
			{"idea_id": new_first, "adherence": "match", "reason": "Matches Antarctica."},
			{"idea_id": new_second, "adherence": "partial_mismatch", "reason": "Weak setting."}
		],
		"similarity_clusters": [
			{"idea_ids": [old_first, old_second], "classification": "near_duplicate", "reason": "Old-old."},
			{"idea_ids": [old_first, new_first], "classification": "near_duplicate", "reason": "New-old."}
		]
	}, source_extension)
	_require(
		(normalised.get("ideas", []) as Array).size() == 2
		and (normalised.get("similarity_clusters", []) as Array).size() == 1,
		"Extension adherence must ignore old Ideas while similarity keeps only clusters containing a new candidate."
	)
	REVIEW.apply_advisory_review(source_extension, normalised)
	var selection := REVIEW.apply_user_selection(source_extension, [new_first])
	_require(
		int(selection.get("reviewed_count", 0)) == 2
		and int(selection.get("kept_count", 0)) == 1
		and DIVERSITY.accepted_count(source_extension) == 3
		and DIVERSITY.next_top_up_request_size(source_extension) == 1
		and str(source_extension.get("seed_snapshot", "")).contains(antarctic)
		and DIVERSITY.anti_repeat_prompt(source_extension).contains(
			"rejected_by_user_review"
		),
		"Applying an extension review must preserve both old Ideas, reject only unchecked new Ideas and request the exact top-up shortfall."
	)
	var successful_curation := REVIEW.create_curation_session(source_extension, {})
	_require(
		REVIEW.extension_instruction(successful_curation) == antarctic,
		"A successfully retained extension must make its instruction the next Generate More prefill."
	)


func _test_live_dialog_batching_persistence_and_cancel() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current application scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace: CCFWorkspaceCurrent = app.get("_workspace")
	var generator: CCFIdeaGeneratorWindowCurrent = workspace.get(
		"_idea_generator_v01532"
	)
	var project: Dictionary = (workspace.get("_project") as Dictionary).duplicate(true)
	project["project_id"] = "v0219-live"
	workspace.set("_project", project)
	var fake := FakeGenerationService.new()
	workspace.add_child(fake)
	workspace.set("_generation_service", fake)
	var curation := _curation(
		"v0219-live", "Original plain prompt", "", "", "", "SERIES LIVE", 2
	)
	curation["review_adherence"] = false
	curation["review_similarity"] = false
	curation["final_top_up_enabled"] = false
	curation["batch_limit"] = 3
	workspace.set("_idea_curation_session_v0218", curation)
	var more_button := workspace.get("_idea_generate_more_v0218") as Button
	more_button.disabled = false
	workspace.call("_open_generate_more_dialog_v0218")
	var instruction := workspace.get(
		"_idea_generate_more_instruction_v0219"
	) as TextEdit
	var instruction_label := workspace.get(
		"_idea_generate_more_instruction_label_v0219"
	) as Label
	var source_row := workspace.get(
		"_idea_generate_more_source_row_v0219"
	) as VBoxContainer
	_require(
		instruction.text == "Original plain prompt"
		and instruction_label.text == "Prompt"
		and not source_row.visible,
		"The first plain-prompt Generate More dialog must prefill the completed batch prompt."
	)
	(workspace.get("_idea_generate_more_count_v0218") as SpinBox).value = 7
	instruction.text = "Set this scenario in Antarctica."
	workspace.call("_generate_more_ideas_v0218")
	_require(
		fake.requests == [3]
		and fake.seeds == ["Set this scenario in Antarctica."]
		and fake.series_contexts == ["SERIES LIVE"],
		"The confirmed edited prompt must drive the first provider batch with frozen Series context."
	)
	workspace.call("_handle_completed_idea_batch_v0211", "v0219-idea-1", _ideas("More A", 3), _metadata("v0219-live"))
	workspace.call("_handle_completed_idea_batch_v0211", "v0219-idea-2", _ideas("More B", 3), _metadata("v0219-live"))
	workspace.call("_handle_completed_idea_batch_v0211", "v0219-idea-3", _ideas("More C", 1), _metadata("v0219-live"))
	_require(
		fake.requests == [3, 3, 1]
		and fake.seeds == [
			"Set this scenario in Antarctica.",
			"Set this scenario in Antarctica.",
			"Set this scenario in Antarctica."
		]
		and (generator.get("_last_generated_ideas_v01532") as Array).size() == 9,
		"Every provider request in one manual extension must use the same edited instruction and append to the old batch."
	)
	workspace.call("_open_generate_more_dialog_v0218")
	_require(
		instruction.text == "Set this scenario in Antarctica.",
		"The next Generate More dialog must prefill the most recently successful instruction."
	)
	instruction.text = "Cancelled edit must not persist."
	workspace.call("_cancel_generate_more_dialog_v0219")
	workspace.call("_open_generate_more_dialog_v0218")
	_require(
		instruction.text == "Set this scenario in Antarctica.",
		"Cancelling an edited dialog must not mutate the completed curation instruction."
	)

	# Replace the live fixture with a frozen-source batch, while the main generator
	# deliberately points at an unrelated current source.
	var frozen_context := "FROZEN SOURCE USED BY WORKING BATCH"
	var source_curation := _curation(
		"v0219-live",
		"Focus on workplace scenarios.",
		"source-frozen",
		"She Got Pregnant",
		frozen_context,
		"SERIES LIVE",
		1
	)
	source_curation["review_adherence"] = false
	source_curation["review_similarity"] = false
	source_curation["final_top_up_enabled"] = false
	workspace.set("_idea_curation_session_v0218", source_curation)
	generator.set("_active_idea_source_v0213", {
		"id": "source-current-unrelated",
		"title": "Unrelated current source",
		"summary": "This must never leak into Generate More."
	})
	workspace.call("_open_generate_more_dialog_v0218")
	_require(
		instruction_label.text == "Additional Direction"
		and source_row.visible
		and (workspace.get("_idea_generate_more_source_value_v0219") as Label).text == "She Got Pregnant"
		and instruction.text == "Focus on workplace scenarios.",
		"A source-backed dialog must show the frozen source read-only and prefill Additional Direction."
	)
	var before_source_request_count := fake.requests.size()
	(workspace.get("_idea_generate_more_count_v0218") as SpinBox).value = 1
	instruction.text = "Set these at an isolated Antarctic research station."
	workspace.call("_generate_more_ideas_v0218")
	var source_seed := fake.seeds[-1]
	_require(
		fake.requests.size() == before_source_request_count + 1
		and source_seed.contains(frozen_context)
		and source_seed.contains("isolated Antarctic research station")
		and not source_seed.contains("Unrelated current source"),
		"The current main-UI Idea Source must never replace the working batch's frozen source."
	)
	var source_job_id := "v0219-idea-%d" % (fake.next_id - 1)
	workspace.call("_handle_completed_idea_batch_v0211", source_job_id, _ideas("Source More", 1), _metadata("v0219-live"))
	workspace.call("_open_generate_more_dialog_v0218")
	_require(
		instruction.text == "Set these at an isolated Antarctic research station.",
		"A successful source extension must persist its latest Additional Direction."
	)
	(workspace.get("_idea_generate_more_count_v0218") as SpinBox).value = 1
	instruction.text = ""
	workspace.call("_generate_more_ideas_v0218")
	_require(
		fake.seeds[-1] == frozen_context,
		"A blank source direction must send only the frozen source context."
	)
	var blank_job_id := "v0219-idea-%d" % (fake.next_id - 1)
	workspace.call("_handle_completed_idea_batch_v0211", blank_job_id, _ideas("Source Blank", 1), _metadata("v0219-live"))
	workspace.call("_open_generate_more_dialog_v0218")
	_require(instruction.text == "", "A successful blank direction must remain the next prefill.")
	var visible_before_cancel := (
		(workspace.get("_idea_curation_session_v0218") as Dictionary).get(
			"visible_ideas", []
		) as Array
	).size()
	instruction.text = "This cancelled request must not persist."
	workspace.call("_generate_more_ideas_v0218")
	var cancelled_job_id := "v0219-idea-%d" % (fake.next_id - 1)
	workspace.call("_on_job_cancelled", cancelled_job_id, "ideas")
	var after_cancel: Dictionary = workspace.get("_idea_curation_session_v0218")
	_require(
		REVIEW.extension_instruction(after_cancel) == ""
		and (after_cancel.get("visible_ideas", []) as Array).size() == visible_before_cancel,
		"Cancelling active generation must preserve the prior completed batch and last successful instruction."
	)
	var other_project := (workspace.get("_project") as Dictionary).duplicate(true)
	other_project["project_id"] = "v0219-other-project"
	workspace.set("_project", other_project)
	workspace.call("_open_generate_more_dialog_v0218")
	_require(
		(workspace.get("_idea_curation_session_v0218") as Dictionary).is_empty(),
		"Generate More instruction and frozen source context must not cross project boundaries."
	)
	app.queue_free()
	await process_frame


func _curation(
	project_id: String,
	instruction: String,
	source_id: String,
	source_title: String,
	source_context: String,
	series_context: String,
	visible_count: int
) -> Dictionary:
	var context := {
		"prompt_mode": "additional_direction" if not source_context.is_empty() else "primary_prompt",
		"seed_text": instruction,
		"series_context": series_context,
		"idea_source_id": source_id,
		"idea_source_title": source_title,
		"idea_source_context": source_context
	}
	var session := DIVERSITY.create_session(visible_count, 3, true, "off", false, context)
	session["project_id_snapshot"] = project_id
	session["seed_snapshot"] = REVIEW.build_extension_seed({
		"generation_context": context,
		"series_context_snapshot": series_context
	}, instruction)
	session["series_context_snapshot"] = series_context
	session["profile_snapshot"] = {}
	session["retry_count_snapshot"] = 1
	session["detail_level_snapshot"] = "standard"
	DIVERSITY.record_batch(session, _ideas("Existing", visible_count))
	var curation := REVIEW.create_curation_session(session, {})
	(curation.get("rejected", []) as Array).append({
		"id": "remembered-rejection",
		"title": "Remembered rejection",
		"fingerprint": "remembered rejection engine",
		"state": "rejected",
		"rejection_reason": "rejected_by_user_review"
	})
	return curation


func _metadata(project_id: String) -> Dictionary:
	return {
		"idea_batch_request_kind": "normal",
		"idea_diversity_validation_candidate_count": 3,
		"idea_diversity_validation_rejections": [],
		"idea_detail_level": "standard",
		"project_id": project_id
	}


func _ideas(prefix: String, count: int) -> Array:
	var result: Array = []
	var palette := _idea_palette(prefix)
	for index in range(count):
		result.append({
			"title": "%s %d" % [prefix, index + 1],
			"character_name": "%sCharacter%d" % [prefix.replace(" ", ""), index + 1],
			"character_role": "A distinct role connected to {{user}}",
			"source_anchor": "v0219 fixture",
			"roleplay_hook": "{{user}} chooses how to respond.",
			"concept": "%s scenario %d uses %s. Its setting axis %d, relationship %d, reveal %d and consequence %d remain materially distinct."
			% [prefix, index + 1, palette, index + 11, index + 31, index + 51, index + 71],
			"tags": ["v0219-test", prefix]
		})
	return result


func _idea_palette(prefix: String) -> String:
	if prefix.contains("Existing"):
		return "lighthouse beekeeper monsoon brass telescope inheritance orchard semaphore"
	if prefix.contains("More A"):
		return "volcanic botanist orchid caravan eclipse pollen obsidian greenhouse pilgrimage"
	if prefix.contains("More B"):
		return "orbital archivist comet cipher vacuum embassy asteroid treaty starlight tribunal"
	if prefix.contains("More C"):
		return "abyssal diplomat coral trench submarine sonar kelp mutiny pressure sanctuary"
	if prefix.contains("Antarctic") or prefix.contains("Source More"):
		return "whiteout glaciologist crevasse aurora generator frostbite station isolation research"
	if prefix.contains("Source Blank"):
		return "icebreaker medic radio blackout ration sled rescue blizzard equipment shelter"
	return "festival violin clocktower courier lantern masquerade canal confession midnight"


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
