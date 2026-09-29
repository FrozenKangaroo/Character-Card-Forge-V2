extends SceneTree

const REVIEW = preload("res://scripts/services/idea_final_review_service_v0218.gd")
const DIVERSITY = preload("res://scripts/services/idea_diversity_guardrails_v0214.gd")

var _failed := false


class FakeGenerationService:
	extends CCFGenerationService

	var requests: Array[int] = []
	var decorations: Array[Dictionary] = []
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
		var job_id := "v0218-idea-%d" % next_id
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
	_test_review_contract_and_advisory_semantics()
	_test_user_selection_recovery_and_curation_memory()
	await _test_live_review_sequence_and_working_batch()
	if _failed:
		quit(1)
		return
	print("V0218_FINAL_IDEA_REVIEW_CURATION_OK")
	quit(0)


func _test_review_contract_and_advisory_semantics() -> void:
	var context := {
		"prompt_mode": "additional_direction",
		"seed_text": "Keep {{user}} as the detective and use a locked-hotel scenario.",
		"idea_source_id": "source-locked-hotel",
		"idea_source_title": "Locked Hotel",
		"idea_source_context": "The central premise is a detective trapped with a rival.",
		"series_context": "SERIES CONTEXT: one-night mysteries"
	}
	var session := DIVERSITY.create_session(3, 3, true, "off", true, context)
	session["final_review_check_adherence"] = true
	session["final_review_check_similarity"] = true
	DIVERSITY.record_batch(session, _ideas("Review", 3))
	var prompt := REVIEW.final_review_prompt(session)
	_require(
		prompt.contains("Keep {{user}} as the detective")
		and prompt.contains("Active Idea Source")
		and prompt.contains("Locked Hotel")
		and prompt.contains("SERIES CONTEXT")
		and prompt.contains("partial_mismatch")
		and prompt.contains("near_duplicate")
		and prompt.contains("advisory"),
		"The combined final review prompt must preserve frozen direction, Idea Source and Series context while requesting both advisory dimensions."
	)
	var review := REVIEW.normalise_review({
		"ideas": [
			{"idea_id": "idea-001", "adherence": "MATCH", "reason": "Follows the request."},
			{"idea_id": "idea-002", "adherence": "partial_mismatch", "reason": "Weakens the required rivalry."},
			{"idea_id": "idea-003", "adherence": "clear_mismatch", "reason": "Replaces the detective."},
			{"idea_id": "unknown", "adherence": "clear_mismatch", "reason": "Ignore me."},
			{"idea_id": "idea-001", "adherence": "invented", "reason": "Ignore duplicate malformed value."}
		],
		"similarity_clusters": [
			{"idea_ids": ["idea-001", "idea-002", "unknown"], "classification": "duplicate", "reason": "Same engine."},
			{"idea_ids": ["idea-002", "idea-003"], "classification": "near_duplicate", "reason": "Shared setup."},
			{"idea_ids": ["idea-001", "unknown"], "classification": "invented", "reason": "Ignore me."}
		]
	}, session)
	_require(
		(review.get("ideas", []) as Array).size() == 3
		and (review.get("similarity_clusters", []) as Array).size() == 2,
		"Review parsing must normalise valid adherence/similarity findings and ignore malformed or unknown IDs."
	)
	REVIEW.apply_advisory_review(session, review)
	_require(
		DIVERSITY.accepted_count(session) == 3
		and DIVERSITY.rejected_count(session) == 0,
		"Clear duplicate and clear mismatch findings must never remove or reject Ideas automatically."
	)


func _test_user_selection_recovery_and_curation_memory() -> void:
	var session := DIVERSITY.create_session(10, 4, true, "off", true, {
		"prompt_mode": "primary_prompt", "seed_text": "Frozen working-batch request"
	})
	session["final_review_check_adherence"] = true
	session["final_review_check_similarity"] = true
	session["project_id_snapshot"] = "project-a"
	session["seed_snapshot"] = "Frozen working-batch request"
	session["series_context_snapshot"] = "Frozen series"
	session["profile_snapshot"] = {"name": "Fixture"}
	session["detail_level_snapshot"] = "extended"
	DIVERSITY.record_batch(session, _ideas("Keep", 10))
	var kept: Array[String] = []
	for index in range(10):
		if index not in [2, 5, 8]:
			kept.append("idea-%03d" % (index + 1))
	var selection := REVIEW.apply_user_selection(session, kept)
	_require(
		int(selection.get("kept_count", 0)) == 7
		and int(selection.get("rejected_count", 0)) == 3
		and DIVERSITY.next_top_up_request_size(session) == 3,
		"Unchecking three Ideas from a target of ten must create a post-review shortfall of exactly three."
	)
	var memory := DIVERSITY.anti_repeat_prompt(session)
	_require(
		memory.contains("Keep 3") and memory.contains("rejected_by_user_review"),
		"User-rejected Ideas must remain in recovery anti-repeat memory with explicit provenance."
	)
	var curation := REVIEW.create_curation_session(session, {"fixture": true})
	var removed := REVIEW.remove_visible_idea(curation, 0)
	_require(
		bool(removed.get("ok", false))
		and (curation.get("visible_ideas", []) as Array).size() == 6
		and str(((curation.get("rejected", []) as Array)[-1] as Dictionary).get(
			"rejection_reason", ""
		)) == "rejected_by_user_after_generation",
		"Delete This Idea must affect only the temporary visible set while retaining a compact rejected ledger record."
	)
	var extension := REVIEW.create_extension_session(curation, 4, 3)
	var extension_memory := DIVERSITY.anti_repeat_prompt(extension)
	_require(
		DIVERSITY.accepted_count(extension) == 6
		and DIVERSITY.next_normal_request_size(extension) == 3
		and extension_memory.contains("Keep 1")
		and extension_memory.contains("Keep 3")
		and extension_memory.contains("rejected_by_user_after_generation")
		and str(extension.get("seed_snapshot", "")) == "Frozen working-batch request"
		and str(extension.get("series_context_snapshot", "")) == "Frozen series",
		"Generate More must preserve surviving Ideas, frozen creative context and both review/deletion anti-repeat memory while respecting the per-request cap."
	)
	var second_curation := REVIEW.create_curation_session(extension, {})
	var second_extension := REVIEW.create_extension_session(second_curation, 2, 2)
	_require(
		DIVERSITY.next_normal_request_size(second_extension) == 2,
		"Manual Generate More must remain repeatable across separate explicit invocations."
	)


func _test_live_review_sequence_and_working_batch() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current application scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace: CCFWorkspaceCurrent = app.get("_workspace")
	var generator: CCFIdeaGeneratorWindowCurrent = workspace.get("_idea_generator_v01532")
	var live_project: Dictionary = (workspace.get("_project") as Dictionary).duplicate(true)
	live_project["project_id"] = "live-project"
	workspace.set("_project", live_project)
	var fake := FakeGenerationService.new()
	workspace.add_child(fake)
	workspace.set("_generation_service", fake)
	var adherence := workspace.find_child("FinalIdeaReviewAdherenceV0218", true, false) as CheckButton
	var similarity := workspace.find_child("FinalIdeaReviewSimilarityV0218", true, false) as CheckButton
	var generate_more := workspace.find_child("GenerateMoreIdeasV0218", true, false) as Button
	var review_scroll := workspace.find_child("FinalIdeaReviewScrollV0218", true, false) as ScrollContainer
	_require(
		adherence != null and similarity != null and generate_more != null
		and review_scroll != null
		and not adherence.button_pressed and not similarity.button_pressed,
		"The live UI must expose two opt-in advisory review dimensions, a scrollable checklist and Generate More without spending an AI call by default."
	)
	var previous := [_idea("Previous result", "The previous completed batch must remain visible while review waits.")]
	generator.set_last_generated_ideas_v01532(previous, {})
	var session := DIVERSITY.create_session(3, 3, true, "off", true, {
		"prompt_mode": "primary_prompt", "seed_text": "Live frozen request"
	})
	session["final_review_check_adherence"] = true
	session["final_review_check_similarity"] = true
	session["project_id_snapshot"] = "live-project"
	session["seed_snapshot"] = "Live frozen request"
	session["profile_snapshot"] = {}
	session["detail_level_snapshot"] = "standard"
	DIVERSITY.record_batch(session, _ideas("Live", 3))
	workspace.set("_idea_diversity_session_v0214", session)
	workspace.set("_idea_batch_requested_total_v0211", 3)
	workspace.set("_idea_batch_expected_requests_v0211", 1)
	workspace.set("_idea_batch_group_id_v0211", "v0218-live")
	workspace.call("_handle_idea_similarity_review_completed_v0214", {
		"ideas": [
			{"idea_id": "idea-001", "adherence": "match", "reason": "Matches."},
			{"idea_id": "idea-002", "adherence": "partial_mismatch", "reason": "Possible mismatch."},
			{"idea_id": "idea-003", "adherence": "clear_mismatch", "reason": "Clear mismatch."}
		],
		"similarity_clusters": [{
			"idea_ids": ["idea-001", "idea-002"],
			"classification": "near_duplicate",
			"reason": "Similar opening, different consequence."
		}]
	})
	var checks: Array = workspace.get("_idea_review_checks_v0218")
	var captured_before: Array = generator.get("_last_generated_ideas_v01532")
	_require(
		checks.size() == 3 and (checks[0] as CheckBox).button_pressed
		and (checks[1] as CheckBox).button_pressed and (checks[2] as CheckBox).button_pressed
		and bool(workspace.get("_idea_review_awaiting_user_v0218"))
		and not bool(session.get("final_top_up_started", false))
		and fake.requests.is_empty()
		and captured_before.size() == 1
		and str((captured_before[0] as Dictionary).get("title", "")) == "Previous result",
		"AI review completion must leave every Idea checked, pause before top-up and preserve the previous completed result until the user applies review."
	)
	(checks[1] as CheckBox).button_pressed = false
	workspace.call("_apply_final_idea_review_v0218")
	_require(
		fake.requests == [1]
		and str(fake.decorations[0].get("request_kind", "")) == "top_up"
		and str(fake.decorations[0].get("anti_repeat_context", "")).contains("Live 2")
		and str(fake.decorations[0].get("anti_repeat_context", "")).contains("rejected_by_user_review"),
		"Top-up must begin only after Apply Review and request the exact shortfall with user-rejected anti-repeat memory."
	)
	workspace.call("_handle_completed_idea_batch_v0211", "v0218-idea-1", [_idea(
		"Recovery", "A materially distinct replacement with a new relationship and consequence."
	)], {
		"idea_batch_request_kind": "top_up",
		"idea_diversity_validation_candidate_count": 1,
		"idea_diversity_validation_rejections": [],
		"idea_detail_level": "standard",
		"project_id": str((workspace.get("_project") as Dictionary).get("project_id", ""))
	})
	var completed: Array = generator.get("_last_generated_ideas_v01532")
	_require(
		completed.size() == 3 and not bool(workspace.get("_idea_review_awaiting_user_v0218"))
		and not generate_more.disabled,
		"Only genuine pipeline finalization may replace the previous batch and enable post-generation curation."
	)
	workspace.call("_delete_generated_idea_v0218", 0)
	var after_delete: Array = generator.get("_last_generated_ideas_v01532")
	var curation: Dictionary = workspace.get("_idea_curation_session_v0218")
	_require(
		after_delete.size() == 2
		and (curation.get("visible_ideas", []) as Array).size() == 2
		and (curation.get("rejected", []) as Array).size() >= 2,
		"Delete This Idea must immediately synchronize visible, save and develop generated-Idea state while retaining anti-repeat memory."
	)
	curation["review_adherence"] = false
	curation["review_similarity"] = false
	curation["final_top_up_enabled"] = false
	workspace.set("_idea_curation_session_v0218", curation)
	(workspace.get("_idea_generate_more_count_v0218") as SpinBox).value = 2
	workspace.call("_generate_more_ideas_v0218")
	var active: Dictionary = workspace.get("_idea_diversity_session_v0214")
	_require(
		fake.requests == [1, 2]
		and DIVERSITY.accepted_count(active) == 2
		and str(active.get("seed_snapshot", "")) == "Live frozen request"
		and str(fake.decorations[-1].get("anti_repeat_context", "")).contains("rejected_by_user_after_generation"),
		"Manual Generate More must append from the surviving batch with frozen context and deleted/rejected anti-repeat memory."
	)
	workspace.call("_handle_completed_idea_batch_v0211", "v0218-idea-2", _ideas("More", 2), {
		"idea_batch_request_kind": "normal",
		"idea_diversity_validation_candidate_count": 2,
		"idea_diversity_validation_rejections": [],
		"idea_detail_level": "standard",
		"project_id": str((workspace.get("_project") as Dictionary).get("project_id", ""))
	})
	var appended: Array = generator.get("_last_generated_ideas_v01532")
	_require(
		appended.size() == 4
		and str((appended[0] as Dictionary).get("title", "")).begins_with("Live")
		and str((appended[-1] as Dictionary).get("title", "")).begins_with("More"),
		"Generate More completion must append new accepted Ideas without replacing surviving results."
	)
	var other_project := (workspace.get("_project") as Dictionary).duplicate(true)
	other_project["project_id"] = "different-project"
	workspace.set("_project", other_project)
	workspace.call("_open_generate_more_dialog_v0218")
	_require(
		(workspace.get("_idea_curation_session_v0218") as Dictionary).is_empty(),
		"Curation state must not cross project boundaries."
	)
	app.queue_free()
	await process_frame


func _ideas(prefix: String, count: int) -> Array:
	var result: Array = []
	for index in range(count):
		result.append(_idea(
			"%s %d" % [prefix, index + 1],
			"%s scenario %d uses relationship axis %d, initiating event %d, reveal %d and consequence %d."
			% [prefix, index + 1, index + 1, index + 31, index + 61, index + 91]
		))
	return result


func _idea(title: String, concept: String) -> Dictionary:
	return {
		"title": title,
		"character_name": title.replace(" ", ""),
		"character_role": "A generated character connected to {{user}}",
		"source_anchor": "fixture",
		"roleplay_hook": "The next meaningful decision remains with {{user}}.",
		"concept": concept,
		"tags": ["v0218-test"]
	}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
