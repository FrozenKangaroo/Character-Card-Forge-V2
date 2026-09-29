extends SceneTree

const DIVERSITY = preload(
	"res://scripts/services/idea_diversity_guardrails_v0214.gd"
)
const BATCHING = preload(
	"res://scripts/services/idea_generator_batching_v0211.gd"
)
const GENERATION_CURRENT = preload(
	"res://scripts/services/generation_service_current.gd"
)

var _failed := false


class FakeGenerationService:
	extends CCFGenerationService

	var requests: Array[int] = []
	var seeds: Array[String] = []
	var decorations: Array[Dictionary] = []
	var review_sessions: Array[Dictionary] = []
	var review_requests := 0
	var next_id := 1

	func queue_idea_generation_with_detail_v0167(
		_seed_text: String,
		_profile: Dictionary,
		idea_count: int,
		_retry_count: int,
		_project_id: String = "",
		_series_context: String = "",
		_detail_level_id: String = "standard"
	) -> Dictionary:
		requests.append(idea_count)
		seeds.append(_seed_text)
		var job_id := "fake-idea-%d" % next_id
		next_id += 1
		return {"ok": true, "job_id": job_id, "queued_ahead": 0}

	func decorate_idea_batch_job_v0211(
		job_id: String,
		_group_id: String,
		batch_index: int,
		request_count: int,
		requested_total: int,
		anti_repeat_context: String = "",
		request_kind: String = "normal"
	) -> bool:
		decorations.append({
			"job_id": job_id,
			"batch_index": batch_index,
			"request_count": request_count,
			"requested_total": requested_total,
			"anti_repeat_context": anti_repeat_context,
			"request_kind": request_kind
		})
		return true

	func queue_idea_similarity_review_v0214(
		_session: Dictionary,
		_profile: Dictionary,
		_retry_count: int,
		_project_id: String = ""
	) -> Dictionary:
		review_requests += 1
		review_sessions.append(_session.duplicate(true))
		return {"ok": true, "job_id": "fake-review-%d" % review_requests}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_adaptive_batch_sizes()
	_test_title_and_structural_signals()
	_test_anti_repeat_prompt_and_job_decoration()
	_test_validation_ledger_metadata()
	_test_reporting_telemetry()
	_test_generation_context_review_prompt()
	_test_final_review_modes()
	_test_one_shot_top_up()
	_test_contract_compatibility()
	if not _failed:
		await _test_live_controls()
	if _failed:
		quit(1)
		return
	print("V0214_MULTI_BATCH_DIVERSITY_OK")
	quit(0)


func _test_adaptive_batch_sizes() -> void:
	var complete := DIVERSITY.create_session(21, 12)
	_require(
		DIVERSITY.next_normal_request_size(complete) == 12,
		"A 21-target session must initially request 12."
	)
	DIVERSITY.mark_request_started(complete, 12, "normal")
	DIVERSITY.record_batch(complete, _ideas("Complete", 12), [], "normal", 12)
	_require(
		DIVERSITY.accepted_count(complete) == 12
		and DIVERSITY.next_normal_request_size(complete) == 9,
		"When all 12 survive, the second request must remain 9."
	)

	var one_rejected := DIVERSITY.create_session(21, 12)
	DIVERSITY.mark_request_started(one_rejected, 12, "normal")
	DIVERSITY.record_batch(
		one_rejected,
		_ideas("Accepted", 11),
		[{
			"idea": _idea("Rejected Candidate", "A malformed premise that validation rejected."),
			"reason": "generation validation: missing roleplay_hook"
		}],
		"normal",
		12
	)
	_require(
		DIVERSITY.accepted_count(one_rejected) == 11
		and DIVERSITY.rejected_count(one_rejected) == 1
		and DIVERSITY.next_normal_request_size(one_rejected) == 10,
		"Rejected results must not count toward the target; the next request must expand from 9 to 10."
	)

	var larger := DIVERSITY.create_session(30, 12)
	DIVERSITY.mark_request_started(larger, 12, "normal")
	DIVERSITY.record_batch(larger, _ideas("First", 9), [], "normal", 12)
	_require(
		DIVERSITY.next_normal_request_size(larger) == 12,
		"A 30-target session with only 9 accepted must request 12 next."
	)
	DIVERSITY.mark_request_started(larger, 12, "normal")
	DIVERSITY.record_batch(larger, _ideas("Second", 11), [], "normal", 12)
	_require(
		DIVERSITY.accepted_count(larger) == 20
		and DIVERSITY.next_normal_request_size(larger) == 10,
		"After 20 accepted ideas, the final normal request must adapt to 10."
	)
	var summary := DIVERSITY.summary(one_rejected)
	_require(
		int(summary.get("initial_generated_candidate_count", 0)) == 12
		and int(summary.get("semantic_repair_pass_count", 0)) == 0
		and int(summary.get("semantic_repair_candidate_count", 0)) == 0
		and int(summary.get("validation_candidate_count", 0)) == 12
		and int(summary.get("accepted_count", 0)) == 11
		and int(summary.get("rejected_count", 0)) == 1,
		"Initial, repair, validation, accepted and rejected counts must remain separate."
	)


func _test_title_and_structural_signals() -> void:
	_require(
		DIVERSITY.titles_need_comparison("The Boss's Secret", "The Boss’s Secret")
		and DIVERSITY.titles_need_comparison("THE BOSS'S SECRET", "the boss's secret!")
		and DIVERSITY.titles_need_comparison("Conference Secret", "Conference Secrets"),
		"Exact, case/punctuation and obvious near-title variants must warn."
	)
	var same_title := DIVERSITY.create_session(2, 2)
	DIVERSITY.record_batch(same_title, [
		_idea("Shared Title", "A detective hides evidence to protect a sibling, creating an investigation conflict."),
		_idea("Shared Title", "Two rival chefs inherit one restaurant and must cooperate while competing for ownership.")
	])
	_require(
		DIVERSITY.accepted_count(same_title) == 2
		and (same_title.get("title_warnings", []) as Array).size() == 1,
		"A matching title must warn without automatically rejecting structurally different ideas."
	)

	var cosmetic := DIVERSITY.create_session(2, 2)
	DIVERSITY.record_batch(cosmetic, [
		_idea_named(
			"Conference Consequences", "Elena",
			"Elena has a one-time affair with her manager during work travel. The known manager paternity and concealed encounter drive the ongoing conflict."
		),
		_idea_named(
			"The Business Trip", "Maya",
			"Maya has a one-time affair with her manager during work travel. The known manager paternity and concealed encounter drive the ongoing conflict."
		)
	])
	_require(
		DIVERSITY.accepted_count(cosmetic) == 1
		and DIVERSITY.rejected_count(cosmetic) == 1,
		"Cosmetic character renaming must not make the same scenario structure novel."
	)

	var meaningful := DIVERSITY.create_session(3, 3)
	DIVERSITY.record_batch(meaningful, [
		_idea("Accidental Boundary", "A secret one-time encounter breaks contraception accidentally; paternity is known and the absent third party creates guilt."),
		_idea("Deliberate Choice", "An openly permitted ongoing outside relationship becomes a conflict when conception is deliberate; every party knows and the third party demands involvement."),
		_idea("Uncertain Future", "A consensual open relationship faces uncertain paternity after several allowed partners; nobody knows the father and disclosure changes the household.")
	])
	_require(
		DIVERSITY.accepted_count(meaningful) == 3,
		"Meaningful differences in intent, consent, duration, knowledge and consequences must survive."
	)
	var different_titles_same_engine := DIVERSITY.create_session(2, 2)
	var shared_engine := "An archivist steals one forbidden letter to protect a friend; discovery by the curator is the reveal and the theft drives an ongoing loyalty conflict."
	DIVERSITY.record_batch(different_titles_same_engine, [
		_idea("The Missing Letter", shared_engine),
		_idea("Archive After Hours", shared_engine)
	])
	_require(
		DIVERSITY.accepted_count(different_titles_same_engine) == 1,
		"Different titles must not make an otherwise identical structural fingerprint distinct."
	)


func _test_anti_repeat_prompt_and_job_decoration() -> void:
	var session := DIVERSITY.create_session(4, 2)
	DIVERSITY.record_batch(
		session,
		[_idea("Accepted Branch", "An estranged friend returns with evidence that changes the character's central objective.")],
		[{"idea": _idea("Rejected Branch", "The same estranged friend returns with the same evidence."), "reason": "too similar"}],
		"normal",
		2
	)
	var guardrail := DIVERSITY.anti_repeat_prompt(session)
	_require(
		guardrail.contains("ALREADY ACCEPTED IN THIS GENERATION")
		and guardrail.contains("REJECTED AS DUPLICATE / INVALID / TOO SIMILAR")
		and guardrail.contains("Changing names")
		and guardrail.contains("prefer branches not yet represented"),
		"Later-batch context must include accepted and rejected memory plus structural diversity guidance."
	)
	var service := GENERATION_CURRENT.new()
	root.add_child(service)
	var fixture_job := {
		"id": "diversity-decoration",
		"type": "ideas",
		"label": "Generate ideas",
		"payload": {"messages": [
			{"role": "system", "content": "BASE CONTRACT"},
			{"role": "user", "content": "IDEA SOURCE\nAdditional Direction: explore friends and online meetings."}
		]},
		"metadata": {"idea_count": 2}
	}
	service.set("_queue", [fixture_job] as Array[Dictionary])
	_require(
		service.decorate_idea_batch_job_v0211(
			"diversity-decoration", "session", 1, 2, 4, guardrail, "normal"
		),
		"A later request must accept diversity-ledger decoration."
	)
	var queue: Array = service.get("_queue")
	var decorated: Dictionary = queue[0]
	var messages: Array = (decorated.get("payload", {}) as Dictionary).get("messages", [])
	_require(
		str((messages[0] as Dictionary).get("content", "")).contains("Accepted Branch")
		and str((messages[1] as Dictionary).get("content", "")).contains("IDEA SOURCE")
		and str((messages[1] as Dictionary).get("content", "")).contains("Additional Direction"),
		"Anti-repeat context must augment the system contract without replacing the Idea Source or Additional Direction."
	)
	service.queue_free()


func _test_validation_ledger_metadata() -> void:
	var service := GENERATION_CURRENT.new()
	root.add_child(service)
	service.set("_active_job", {
		"id": "validation-ledger",
		"type": "ideas",
		"metadata": {"seed": "fixture {{user}}"}
	})
	var valid := {
		"title": "Valid",
		"character_name": "Elena",
		"character_role": "Elena is a colleague connected to {{user}}",
		"source_anchor": "fixture",
		"roleplay_hook": "Elena presents the evidence while leaving {{user}}'s response open.",
		"concept": "Elena discovers a forged report involving {{user}} and must decide whether to expose her supervisor without determining {{user}}'s reaction.",
		"tags": ["mystery"]
	}
	var invalid := {
		"title": "Invalid",
		"character_name": "",
		"character_role": "",
		"source_anchor": "fixture",
		"roleplay_hook": "",
		"concept": "An incomplete candidate.",
		"tags": []
	}
	var validation := service.call(
		"_validate_idea_batch", [valid, invalid], "fixture {{user}}"
	) as Dictionary
	var active: Dictionary = service.get("_active_job")
	var metadata: Dictionary = active.get("metadata", {})
	var rejections_value: Variant = metadata.get(
		"idea_diversity_validation_rejections", []
	)
	_require(
		(validation.get("valid_ideas", []) as Array).size() == 1
		and int(metadata.get("idea_diversity_raw_candidate_count", 0)) == 2
		and int(metadata.get("idea_diversity_initial_generated_candidate_count", 0)) == 2
		and int(metadata.get("idea_diversity_semantic_repair_pass_count", 0)) == 0
		and int(metadata.get("idea_diversity_semantic_repair_candidate_count", 0)) == 0
		and int(metadata.get("idea_diversity_validation_candidate_count", 0)) == 2
		and rejections_value is Array
		and (rejections_value as Array).size() == 1
		and str(((rejections_value as Array)[0] as Dictionary).get("reason", "")).contains("Idea 2"),
		"Generation validation must expose only rejected candidates to the temporary diversity ledger while retaining raw count."
	)
	service.queue_free()


func _test_reporting_telemetry() -> void:
	var service := GENERATION_CURRENT.new()
	root.add_child(service)
	service.set("_active_job", {
		"id": "reporting-telemetry",
		"type": "ideas",
		"metadata": {"seed": "fixture {{user}}"}
	})
	var first_candidates := _ideas("Initial", 12)
	service.call("_validate_idea_batch", first_candidates, "fixture {{user}}")
	var active: Dictionary = service.get("_active_job")
	var metadata: Dictionary = active.get("metadata", {}).duplicate(true)
	metadata["semantic_repair_attempts"] = 1
	active["metadata"] = metadata
	service.set("_active_job", active)
	var repaired_candidates := _ideas("Repaired", 12)
	service.call("_validate_idea_batch", repaired_candidates, "fixture {{user}}")
	active = service.get("_active_job")
	metadata = active.get("metadata", {})
	_require(
		int(metadata.get("idea_diversity_initial_generated_candidate_count", 0)) == 12
		and int(metadata.get("idea_diversity_semantic_repair_pass_count", 0)) == 1
		and int(metadata.get("idea_diversity_semantic_repair_candidate_count", 0)) == 12
		and int(metadata.get("idea_diversity_validation_candidate_count", 0)) == 24,
		"One 12-candidate generation batch plus one full repair must report 12 initial, one repair pass, 12 repaired and 24 validation candidates."
	)
	var repaired_session := DIVERSITY.create_session(12, 12)
	DIVERSITY.mark_request_started(repaired_session, 12, "normal")
	DIVERSITY.record_batch(
		repaired_session,
		repaired_candidates,
		[],
		"normal",
		24,
		{
			"initial_generated_candidate_count": 12,
			"semantic_repair_pass_count": 1,
			"semantic_repair_candidate_count": 12,
			"validation_candidate_count": 24
		}
	)
	var repaired_summary := DIVERSITY.summary(repaired_session)
	_require(
		int(repaired_summary.get("generation_batch_count", 0)) == 1
		and int(repaired_summary.get("validation_candidate_count", 0)) == 24,
		"A semantic repair must not be counted as a second generation batch."
	)
	var real_shape := DIVERSITY.create_session(36, 12, true, "reject", true)
	for index in range(4):
		var request_kind := "top_up" if index == 3 else "normal"
		DIVERSITY.mark_request_started(real_shape, 12, request_kind)
		DIVERSITY.record_batch(
			real_shape,
			_ideas("Telemetry %d" % index, 12),
			[],
			request_kind,
			24 if index < 3 else 12,
			{
				"initial_generated_candidate_count": 12,
				"semantic_repair_pass_count": 1 if index < 3 else 0,
				"semantic_repair_candidate_count": 12 if index < 3 else 0,
				"validation_candidate_count": 24 if index < 3 else 12
			}
		)
	var real_summary := DIVERSITY.summary(real_shape)
	_require(
		int(real_summary.get("generation_batch_count", 0)) == 4
		and int(real_summary.get("initial_generated_candidate_count", 0)) == 48
		and int(real_summary.get("semantic_repair_pass_count", 0)) == 3
		and int(real_summary.get("semantic_repair_candidate_count", 0)) == 36
		and int(real_summary.get("validation_candidate_count", 0)) == 84,
		"The real-world telemetry shape must report four batches, 48 initial, three repairs, 36 repaired and 84 validation candidates."
	)
	service.queue_free()


func _test_final_review_modes() -> void:
	var clusters: Array[Dictionary] = [{
		"idea_ids": ["idea-001", "idea-002"],
		"classification": "duplicate",
		"reason": "Same initiating event, secrecy structure and reveal."
	}, {
		"idea_ids": ["idea-002", "idea-003"],
		"classification": "near_duplicate",
		"reason": "Shared trope but different consent structure."
	}, {
		"idea_ids": ["idea-001", "idea-003"],
		"classification": "related_distinct",
		"reason": "Requested premise is shared, but the relationship and consequences differ."
	}]
	var off := DIVERSITY.create_session(3, 3, true, "off")
	DIVERSITY.record_batch(off, _ideas("Off", 3))
	_require(
		str(off.get("final_review_mode", "")) == "off"
		and not bool(off.get("final_review_started", false)),
		"Off must not schedule or imply a final review call."
	)
	var flag := DIVERSITY.create_session(3, 3, true, "flag")
	DIVERSITY.record_batch(flag, _ideas("Flag", 3))
	DIVERSITY.apply_final_review(flag, clusters)
	_require(
		DIVERSITY.accepted_count(flag) == 3
		and (flag.get("final_review_clusters", []) as Array).size() == 3,
		"Flag mode must report clusters without deleting ideas."
	)
	var review_service := GENERATION_CURRENT.new()
	root.add_child(review_service)
	var queued_review := review_service.queue_idea_similarity_review_v0214(
		flag,
		{
			"name": "Fixture",
			"base_url": "https://example.invalid/v1",
			"model": "fixture-model",
			"max_output_tokens": 2048
		},
		0,
		"fixture-project"
	)
	var review_queue: Array = review_service.get("_queue")
	var review_job: Dictionary = review_queue[0] if not review_queue.is_empty() else {}
	var review_messages: Array = (review_job.get("payload", {}) as Dictionary).get("messages", [])
	var review_metadata: Dictionary = review_job.get("metadata", {})
	_require(
		bool(queued_review.get("ok", false))
		and str(review_job.get("type", "")) == "idea_similarity_review"
		and str(review_job.get("parse_mode", "")) == "object"
		and str((review_messages[1] as Dictionary).get("content", "")).contains("related_distinct"),
		"Enabled final review must use one compact structured comparison request with three-way classifications."
	)
	_require(
		not bool(review_metadata.get("idea_similarity_context_present", true))
		and str(review_metadata.get("idea_similarity_context_mode", "")).is_empty()
		and not bool(review_metadata.get("idea_similarity_source_context_present", true)),
		"Legacy sessions without captured context must queue safely with lightweight context diagnostics."
	)
	review_service.queue_free()
	var reject := DIVERSITY.create_session(3, 3, true, "reject")
	DIVERSITY.record_batch(reject, _ideas("Reject", 3))
	var result := DIVERSITY.apply_final_review(reject, clusters)
	_require(
		DIVERSITY.accepted_count(reject) == 2
		and (result.get("rejected_ids", []) as Array) == ["idea-002"]
		and DIVERSITY.rejected_count(reject) == 1,
		"Reject mode must remove only later members of clear duplicate clusters."
	)
	var retained_titles: Array[String] = []
	for retained_value in DIVERSITY.accepted_ideas(reject):
		if retained_value is Dictionary:
			retained_titles.append(str((retained_value as Dictionary).get("title", "")))
	_require(
		"Reject 3" in retained_titles,
		"Near-duplicate and related-but-distinct ideas must survive conservative rejection."
	)


func _test_generation_context_review_prompt() -> void:
	var additional_direction := (
		"Focus on bride-to-be scenarios with one final pre-wedding experience, "
		+ "consensual submission to another dominant person, a temporary arrangement, "
		+ "marriage to {{user}} afterward, and pregnancy discovered afterward."
	)
	var source_context := (
		"IDEA SOURCE: She Got Pregnant\n"
		+ "Core premise: explore consequences and relationship uncertainty.\n"
		+ "Diversity axes: prior history, permission, boundaries, reveal, consequences."
	)
	var context := {
		"prompt_mode": "additional_direction",
		"seed_text": additional_direction,
		"series_context": "SERIES CONTEXT: pre-wedding relationship stories",
		"idea_source_id": "source-pregnancy",
		"idea_source_title": "She Got Pregnant",
		"idea_source_context": source_context
	}
	var session := DIVERSITY.create_session(4, 2, true, "reject", false, context)
	DIVERSITY.mark_request_started(session, 2, "normal")
	DIVERSITY.record_batch(session, [
		_idea(
			"The Trainer's Rules",
			"Her established personal trainer proposes the permitted final weekend; negotiated boundaries, long trust and an open post-wedding reveal shape the consequences."
		),
		_idea(
			"The Online Dominant Arrives",
			"A long-term online dominant meets her physically for the first time; remote history, cautious permission and uncertainty about disclosure shape the consequences."
		)
	])
	DIVERSITY.mark_request_started(session, 2, "normal")
	DIVERSITY.record_batch(session, [
		_idea(
			"The Gallery Weekend",
			"An artist enters through a private commission, with explicit limits and a delayed reveal that changes the marriage."
		),
		_idea(
			"The Resort Weekend",
			"A resort acquaintance enters through a spontaneous invitation, with public permission and immediate emotional consequences."
		)
	])
	var prompt := DIVERSITY.final_review_prompt(session)
	_require(
		prompt.contains("Prompt mode: Additional Direction")
		and prompt.contains(additional_direction)
		and prompt.contains("Active Idea Source: She Got Pregnant")
		and prompt.contains(source_context)
		and prompt.contains("SERIES CONTEXT")
		and prompt.contains("requested traits as shared invariants")
		and prompt.contains("After accounting for those requested invariants")
		and prompt.contains("relationship to a third party")
		and prompt.contains("prefer near_duplicate")
		and prompt.contains("occupation labels")
		and prompt.contains("The Trainer's Rules")
		and prompt.contains("The Online Dominant Arrives"),
		"Final review must preserve Additional Direction and canonical source context while distinguishing requested invariants from discretionary structure."
	)
	var stored_context: Dictionary = session.get("generation_context", {})
	_require(
		str(stored_context.get("seed_text", "")) == additional_direction
		and str(stored_context.get("idea_source_context", "")) == source_context
		and int(session.get("normal_requests_completed", 0)) == 2,
		"The same frozen Additional Direction and Idea Source context must survive multiple batches."
	)
	var primary := DIVERSITY.create_session(2, 2, true, "flag", false, {
		"prompt_mode": "primary_prompt",
		"seed_text": "Generate ten ideas about detectives trapped overnight in an abandoned hotel."
	})
	DIVERSITY.record_batch(primary, _ideas("Detective", 2))
	var primary_prompt := DIVERSITY.final_review_prompt(primary)
	_require(
		primary_prompt.contains("Prompt mode: Primary prompt")
		and primary_prompt.contains("detectives trapped overnight in an abandoned hotel"),
		"Ordinary generation must carry its original primary prompt into final review."
	)
	var legacy := DIVERSITY.create_session(2, 2)
	DIVERSITY.record_batch(legacy, _ideas("Legacy", 2))
	_require(
		DIVERSITY.final_review_prompt(legacy).contains(
			"No stored generation context is available for this legacy session."
		),
		"A session without generation context must still produce a valid review prompt."
	)


func _test_one_shot_top_up() -> void:
	var enabled := DIVERSITY.create_session(30, 12, true, "off", true)
	DIVERSITY.record_batch(enabled, _ideas("Initial", 27), [], "normal", 30)
	_require(
		DIVERSITY.next_top_up_request_size(enabled) == 3,
		"A 27/30 result must offer one recovery request for 3."
	)
	var recovery_prompt := DIVERSITY.anti_repeat_prompt(enabled)
	_require(
		recovery_prompt.contains("Initial 1")
		and recovery_prompt.contains("ALREADY ACCEPTED"),
		"The recovery request must receive the full accepted ledger."
	)
	DIVERSITY.mark_request_started(enabled, 3, "top_up")
	DIVERSITY.record_batch(enabled, _ideas("Recovery", 2), [], "top_up", 3)
	_require(
		DIVERSITY.accepted_count(enabled) == 29
		and DIVERSITY.next_top_up_request_size(enabled) == 0,
		"A partial top-up must stop at 29/30 without scheduling a second recovery call."
	)
	var disabled := DIVERSITY.create_session(30, 12, true, "off", false)
	DIVERSITY.record_batch(disabled, _ideas("No Recovery", 27))
	_require(
		DIVERSITY.next_top_up_request_size(disabled) == 0,
		"Disabled top-up must never produce a recovery request."
	)
	var recovery_dedupe := DIVERSITY.create_session(3, 3, true, "off", true)
	var repeated := _idea("Existing", "One structural premise with the same initiating event and reveal.")
	DIVERSITY.record_batch(recovery_dedupe, [repeated])
	DIVERSITY.mark_request_started(recovery_dedupe, 2, "top_up")
	DIVERSITY.record_batch(recovery_dedupe, [
		_idea("Renamed Duplicate", "One structural premise with the same initiating event and reveal."),
		_idea("Novel Recovery", "A different relationship, objective, opening situation and consequence create a new engine.")
	], [], "top_up", 2)
	_require(
		DIVERSITY.accepted_count(recovery_dedupe) == 2
		and DIVERSITY.rejected_count(recovery_dedupe) == 1
		and DIVERSITY.next_top_up_request_size(recovery_dedupe) == 0,
		"Recovery results must still be deduplicated and must never trigger another recovery."
	)


func _test_contract_compatibility() -> void:
	var capabilities := DIVERSITY.capabilities()
	_require(
		bool(capabilities.get("session_only_ledger", false))
		and not bool(capabilities.get("schema_changes", true))
		and BATCHING.normalise_ideas_per_request(99) == 12
		and BATCHING.request_plan(6, 12) == [6],
		"Diversity state must remain runtime-only while existing provider limits and single-batch behavior stay bounded."
	)
	var source_session := DIVERSITY.create_session(2, 1)
	var source_guardrail := DIVERSITY.anti_repeat_prompt(source_session)
	_require(
		source_guardrail.is_empty(),
		"The first request must not add empty ledger noise to ordinary or Idea Source prompts."
	)


func _test_live_controls() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current application scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace := app.get("_workspace") as CCFWorkspaceCurrent
	if not _require(workspace != null, "The current Workspace must load."):
		return
	var prevent := workspace.find_child("PreventRepeatsAcrossBatchesV0214", true, false) as CheckButton
	var final_review := workspace.find_child("FinalAISimilarityCheckV0214", true, false) as OptionButton
	var top_up := workspace.find_child("FinalIdeaTopUpV0214", true, false) as CheckButton
	var report := workspace.find_child("IdeaSimilarityReviewReportV0214", true, false) as TextEdit
	var report_window := workspace.get("_idea_similarity_review_window_v0214") as Window
	_require(
		prevent != null and prevent.button_pressed
		and final_review != null and final_review.item_count == 3 and final_review.selected == 0
		and top_up != null and not top_up.button_pressed
		and report != null
		and report_window != null
		and report_window.force_native
		and not report_window.transient
		and not report_window.exclusive,
		"The live UI must default extra AI calls off and expose an independently movable native review report."
	)
	_test_live_completion_reporting(workspace)
	_test_live_adaptive_sequence(workspace)
	app.queue_free()
	await process_frame


func _test_live_completion_reporting(workspace: CCFWorkspaceCurrent) -> void:
	workspace.set("_idea_batch_requested_total_v0211", 36)
	workspace.call(
		"_set_completed_idea_batch_status_v0211",
		_ideas("Reported", 24),
		{
			"idea_diversity_summary": {
				"generation_batch_count": 4,
				"initial_generated_candidate_count": 48,
				"semantic_repair_pass_count": 3,
				"semantic_repair_candidate_count": 36,
				"validation_candidate_count": 84,
				"rejected_count": 31,
				"title_warning_count": 25,
				"final_review_mode": "reject",
				"final_top_up_started": true
			},
			"idea_title_duplicate_warnings": []
		}
	)
	var status := workspace.get("_idea_status") as Label
	_require(
		status.text == (
			"24/36 unique ideas accepted after final recovery across 4 generation batches • 31 rejected candidates • 25 similarity warnings."
		)
		and status.tooltip_text.contains("Initial generated candidates: 48")
		and status.tooltip_text.contains("Semantic repair passes: 3")
		and status.tooltip_text.contains("Repaired candidates processed: 36")
		and status.tooltip_text.contains("Total validation-pass candidates: 84")
		and not status.text.contains(" raw")
		and not status.text.contains("provider request"),
		"The real-world completion shape must use concise outcome wording while retaining clearly labelled 84-candidate diagnostics."
	)


func _test_live_adaptive_sequence(workspace: CCFWorkspaceCurrent) -> void:
	var fake := FakeGenerationService.new()
	workspace.add_child(fake)
	workspace.set("_generation_service", fake)
	workspace.call("_reset_idea_batch_state_v0211")
	var seed_editor := workspace.get("_idea_seed") as TextEdit
	seed_editor.text = "Original Additional Direction"
	var plan: Array[int] = [12, 9]
	workspace.call("_queue_batched_ideas_v0211", 21, plan)
	_require(
		fake.requests == [12]
		and fake.decorations.size() == 1
		and str(fake.decorations[0].get("anti_repeat_context", "")).is_empty(),
		"A live generation session must queue only the first request initially, with no empty-ledger prompt noise (requests=%s decorations=%s status=%s detail=%s)."
		% [str(fake.requests), str(fake.decorations), str((workspace.get("_idea_status") as Label).text), str(workspace.get("_selected_idea_detail_level_v0167"))]
	)
	seed_editor.text = "Changed while generation was running"
	workspace.call(
		"_handle_completed_idea_batch_v0211",
		"fake-idea-1",
		_ideas("Live First", 11),
		{
			"idea_batch_request_kind": "normal",
			"idea_diversity_raw_candidate_count": 12,
			"idea_diversity_validation_rejections": [{
				"idea": _idea("Live Rejected", "A rejected live-session fixture."),
				"reason": "generation validation"
			}],
			"idea_detail_level": "standard",
			"project_id": ""
		}
	)
	_require(
		fake.requests == [12, 10]
		and fake.seeds == ["Original Additional Direction", "Original Additional Direction"]
		and fake.decorations.size() == 2
		and str(fake.decorations[1].get("anti_repeat_context", "")).contains("Live First 1")
		and str(fake.decorations[1].get("anti_repeat_context", "")).contains("Live Rejected"),
		"After 11/12 survive, the live second request must adapt to 10, preserve the original direction, and receive accepted plus rejected memory (requests=%s seeds=%s decorations=%s)."
		% [str(fake.requests), str(fake.seeds), str(fake.decorations)]
	)
	workspace.call(
		"_handle_completed_idea_batch_v0211",
		"fake-idea-2",
		_ideas("Live Second", 10),
		{
			"idea_batch_request_kind": "normal",
			"idea_diversity_raw_candidate_count": 10,
			"idea_diversity_validation_rejections": [],
			"idea_detail_level": "standard",
			"project_id": ""
		}
	)
	var generator := workspace.get("_idea_generator_v01532") as CCFIdeaGeneratorWindowCurrent
	var captured: Array = generator.get("_last_generated_ideas_v01532")
	var status := workspace.get("_idea_status") as Label
	_require(
		captured.size() == 21
		and status.text.contains("21/21 unique ideas accepted")
		and status.text.contains("2 generation batches")
		and status.text.contains("1 rejected candidate")
		and not status.text.contains(" raw")
		and not status.text.contains("provider request")
		and status.tooltip_text.contains("Initial generated candidates: 22")
		and status.tooltip_text.contains("Total validation-pass candidates: 22")
		and fake.requests == [12, 10],
		"The live session must finish at the accepted target without prequeuing or making an uncontrolled extra request (captured=%d status=%s requests=%s)."
		% [captured.size(), status.text, str(fake.requests)]
	)
	_test_live_one_shot_top_up(workspace, fake)
	_test_live_final_review(workspace, fake)
	fake.queue_free()


func _test_live_one_shot_top_up(
	workspace: CCFWorkspaceCurrent, fake: FakeGenerationService
) -> void:
	fake.requests.clear()
	fake.seeds.clear()
	fake.decorations.clear()
	fake.next_id = 1
	var top_up := workspace.find_child("FinalIdeaTopUpV0214", true, false) as CheckButton
	top_up.button_pressed = true
	var plan: Array[int] = [3]
	workspace.call("_reset_idea_batch_state_v0211")
	workspace.call("_queue_batched_ideas_v0211", 3, plan)
	workspace.call(
		"_handle_completed_idea_batch_v0211",
		"fake-idea-1",
		_ideas("Top Up Initial", 2),
		{
			"idea_batch_request_kind": "normal",
			"idea_diversity_raw_candidate_count": 2,
			"idea_diversity_validation_rejections": [],
			"idea_detail_level": "standard",
			"project_id": ""
		}
	)
	_require(
		fake.requests == [3, 1]
		and str(fake.decorations[1].get("request_kind", "")) == "top_up"
		and str(fake.decorations[1].get("anti_repeat_context", "")).contains("Top Up Initial"),
		"A short normal phase must queue exactly one ledger-aware recovery request for the missing count."
	)
	workspace.call(
		"_handle_completed_idea_batch_v0211",
		"fake-idea-2",
		_ideas("Top Up Recovery", 1),
		{
			"idea_batch_request_kind": "top_up",
			"idea_diversity_raw_candidate_count": 1,
			"idea_diversity_validation_rejections": [],
			"idea_detail_level": "standard",
			"project_id": ""
		}
	)
	var generator := workspace.get("_idea_generator_v01532") as CCFIdeaGeneratorWindowCurrent
	var captured: Array = generator.get("_last_generated_ideas_v01532")
	var status := workspace.get("_idea_status") as Label
	_require(
		fake.requests == [3, 1]
		and captured.size() == 3
		and status.text.contains("3/3 unique ideas accepted after final recovery"),
		"Recovery must stop after its one allowed request even when session orchestration is live."
	)
	top_up.button_pressed = false


func _test_live_final_review(
	workspace: CCFWorkspaceCurrent, fake: FakeGenerationService
) -> void:
	fake.requests.clear()
	fake.seeds.clear()
	fake.decorations.clear()
	fake.review_sessions.clear()
	fake.review_requests = 0
	fake.next_id = 1
	var review := workspace.find_child("FinalAISimilarityCheckV0214", true, false) as OptionButton
	review.select(1)
	var seed_editor := workspace.get("_idea_seed") as TextEdit
	seed_editor.text = "Detectives trapped overnight in an abandoned hotel"
	workspace.call("_reset_idea_batch_state_v0211")
	var plan: Array[int] = [2]
	workspace.call("_queue_batched_ideas_v0211", 2, plan)
	seed_editor.text = "Mutable UI text changed after generation began"
	workspace.call(
		"_handle_completed_idea_batch_v0211",
		"fake-idea-1",
		_ideas("Review", 2),
		{
			"idea_batch_request_kind": "normal",
			"idea_diversity_raw_candidate_count": 2,
			"idea_diversity_validation_rejections": [],
			"idea_detail_level": "standard",
			"project_id": ""
		}
	)
	_require(
		fake.review_requests == 1
		and fake.review_sessions.size() == 1
		and str((fake.review_sessions[0].get("generation_context", {}) as Dictionary).get(
			"seed_text", ""
		)) == "Detectives trapped overnight in an abandoned hotel"
		and str(workspace.get("_idea_diversity_review_job_id_v0214")) == "fake-review-1",
		"Flag mode must queue exactly one final AI comparison using the generation-start context snapshot rather than mutable UI text."
	)
	workspace.call(
		"_on_job_completed",
		"fake-review-1",
		"idea_similarity_review",
		{"clusters": [{
			"idea_ids": ["idea-001", "idea-002"],
			"classification": "near_duplicate",
			"reason": "Shared setup but materially different reveal and consequences."
		}]},
		{}
	)
	var generator := workspace.get("_idea_generator_v01532") as CCFIdeaGeneratorWindowCurrent
	var report := workspace.find_child("IdeaSimilarityReviewReportV0214", true, false) as TextEdit
	_require(
		fake.review_requests == 1
		and bool(workspace.get("_idea_review_awaiting_user_v0218"))
		and report.text.contains("Near Duplicate")
		and report.text.contains("advisory only"),
		"Compatibility flag review must show the classified cluster and pause for advisory user selection without making a second review call."
	)
	workspace.call("_apply_final_idea_review_v0218")
	var captured: Array = generator.get("_last_generated_ideas_v01532")
	_require(
		captured.size() == 2
		and not bool(workspace.get("_idea_review_awaiting_user_v0218"))
		and fake.review_requests == 1,
		"Applying the compatibility review with every default checkbox retained must keep both Ideas and finalize once."
	)
	review.select(0)


func _ideas(prefix: String, count: int) -> Array:
	var result: Array = []
	for index in range(count):
		result.append(_idea(
			"%s %d" % [prefix, index + 1],
			"%s scenario %d uses relationship axis %d, initiating event %d, reveal mechanism %d and consequence %d."
			% [prefix, index + 1, index + 1, index + 31, index + 61, index + 91]
		))
	return result


func _idea(title: String, concept: String) -> Dictionary:
	return _idea_named(title, title.replace(" ", ""), concept)


func _idea_named(title: String, character_name: String, concept: String) -> Dictionary:
	return {
		"title": title,
		"character_name": character_name,
		"character_role": "A generated character connected to {{user}}",
		"source_anchor": "fixture",
		"roleplay_hook": "The next meaningful decision remains with {{user}}.",
		"concept": concept,
		"tags": ["diversity-test"]
	}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
