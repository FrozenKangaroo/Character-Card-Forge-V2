extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0183_AI_REVIEW_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _replace_character(project: Dictionary, record: Dictionary) -> void:
	var character_id := str(record.get("character_id", ""))
	var index := CCFStorageService.character_index(project, character_id)
	var characters: Array = project.get("characters", []).duplicate(true)
	characters[index] = record.duplicate(true)
	project["characters"] = characters


func _run() -> void:
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var record := CCFStorageService.get_character(project, character_id)
	var card: Dictionary = record.get("character", {}).duplicate(true)
	card["name"] = "Mira Vale"
	card["description"] = "A precise astronomer with silver-streaked hair."
	card["personality"] = "Curious, patient, and privately competitive."
	card["scenario"] = "Mira and {{user}} maintain a remote observatory."
	card["first_message"] = "Mira looks up from the telescope. \"You made it.\""
	card["alternate_greetings"] = ["The dome opens to a field of stars."]
	card["character_book"] = {"entries": [{
		"name": "Observatory", "keys": ["observatory"],
		"content": "The observatory is isolated above the cloud line."
	}]}
	record["character"] = card
	var metadata: Dictionary = record.get("metadata", {}).duplicate(true)
	metadata["name"] = "Mira Vale"
	record["metadata"] = metadata
	_replace_character(project, record)

	var request := CCFAIReviewServiceV0183.build_request(project, character_id)
	if not _require(
		bool(request.get("ok", false))
		and request.get("messages", []).size() == 2
		and str(request.get("messages", [])[1].get("content", "")).contains("deterministic_health_report")
		and CCFAIReviewServiceV0183.rubric().size() == 8,
		"AI Review requests must combine the deterministic report, card context and visible eight-part rubric."
	):
		return

	var raw_result := {
		"scores": {
			"consistency": 8,
			"clarity": 7,
			"depth": 6,
			"scenario_quality": 8,
			"greeting_quality": 7,
			"lore_quality": 6,
			"prompt_efficiency": 9,
			"roleplay_readiness": 8
		},
		"summary": "A coherent card with room for a sharper personality hook.",
		"findings": [
			{
				"id": "personality_specificity",
				"category": "depth",
				"severity": "warning",
				"title": "Personality could be more specific",
				"explanation": (
					"One behavioral detail would improve scene consistency. "
					+ "This deliberately long explanation must remain readable outside a tooltip. ".repeat(12)
				),
				"field_paths": ["character.personality"]
			},
			{
				"id": "intentional_isolation",
				"category": "scenario_quality",
				"severity": "info",
				"title": "The setting is deliberately narrow",
				"explanation": "Keep it if intimate observatory scenes are intentional.",
				"field_paths": ["character.scenario"]
			}
		],
		"proposals": [
			{
				"path": "character.personality",
				"new_value": "Curious, patient, privately competitive, and prone to counting seconds while anxious.",
				"reason": "Adds observable behavior without changing the concept.",
				"finding_ids": ["personality_specificity"]
			},
			{
				"path": "character.scenario",
				"new_value": "Mira and {{user}} maintain a remote observatory during a winter storm.",
				"reason": "Adds pressure, but the author may prefer the quiet original.",
				"finding_ids": ["intentional_isolation"]
			},
			{
				"path": "character.character_id",
				"new_value": "unsafe-id",
				"reason": "This forbidden proposal must be ignored."
			}
		]
	}
	var validated := CCFAIReviewServiceV0183.validate_result(
		project, character_id, raw_result
	)
	if not _require(
		bool(validated.get("ok", false))
		and float(validated.get("overall_score", 0.0)) == 7.5
		and validated.get("findings", []).size() == 2
		and validated.get("proposals", []).size() == 2
		and str(validated.get("proposals", [])[0].get("path", "")) == "character.personality",
		"Rubric scoring must be computed locally and proposals must be restricted to reviewed editable paths."
	):
		return
	var recorded := CCFAIReviewServiceV0183.record_review(
		project,
		character_id,
		validated,
		{"model": "test/model", "profile_name": "Test Profile"}
	)
	project = recorded.get("project", project)
	var review: Dictionary = recorded.get("review", {})
	var review_id := str(review.get("review_id", ""))
	if not _require(
		bool(recorded.get("ok", false))
		and not review_id.is_empty()
		and not CCFAIReviewServiceV0183.review_is_stale(project, character_id, review)
		and str(review.get("model", "")) == "test/model"
		and str(review.get("content_hash", "")) == str(request.get("content_hash", "")),
		"Review history must retain model/profile, rubric result and the reviewed content hash without changing card content."
	):
		return

	var applied := CCFAIReviewServiceV0183.apply_review_decisions(
		project,
		character_id,
		review_id,
		[
			{
				"path": "character.personality",
				"action": "approve",
				"value": "Curious, patient, competitive, and counts seconds while anxious."
			},
			{"action": "dismiss_finding", "finding_id": "intentional_isolation"}
		]
	)
	project = applied.get("project", project)
	record = CCFStorageService.get_character(project, character_id)
	var applied_review := CCFAIReviewServiceV0183.get_review(
		project, character_id, review_id
	)
	if not _require(
		bool(applied.get("ok", false))
		and int(applied.get("accepted_count", 0)) == 1
		and str(record.get("character", {}).get("personality", "")).contains("counts seconds")
		and applied_review.get("dismissed_finding_ids", []).has("intentional_isolation")
		and applied_review.get("decisions", []).size() == 3
		and str(applied_review.get("decisions", [])[1].get("action", "")) == "reject"
		and str(applied_review.get("status", "")) == "applied"
		and CCFRevisionServiceV0181.list_revisions(record).size() == 2,
		"Only explicit approvals may change fields, dismissed findings must remain recorded and each accepted batch must create recovery checkpoints."
	):
		return
	if not _require(
		CCFAIReviewServiceV0183.review_is_stale(project, character_id, applied_review),
		"An earlier review must become stale after its approved content changes are applied."
	):
		return
	var rereview_request := CCFAIReviewServiceV0183.build_request(project, character_id)
	if not _require(
		str(rereview_request.get("messages", [])[1].get("content", "")).contains(
			"intentional_isolation"
		),
		"A later review request must include bounded prior author decisions so intentional dismissals are not rediscovered blindly."
	):
		return
	var exported := CCFCardFormatService.export_character_v2(project, character_id)
	if not _require(
		not JSON.stringify(exported).contains("ai_review_v0183")
		and not JSON.stringify(
			CCFRevisionServiceV0181.list_revisions(record)
		).contains("ai_review_v0183"),
		"Private AI Review history must not leak into ordinary card export or recursively enter revision snapshots."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.18.3 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0183View,
		"The live app must install the v0.18.3 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0183View
	var window_value: Variant = workspace.get("_ai_review_window_v0183")
	var button_value: Variant = workspace.get("_ai_review_button_v0183")
	var worker_value: Variant = workspace.get("_generation_service")
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.18.3", "Godot rewrite • v0.18.4",
			"Godot rewrite • v0.18.5", "Godot rewrite • v0.18.6",
			"Godot rewrite • v0.19.0", "Godot rewrite • v0.19.1"
		]:
			version_found = true
			break
	if not _require(
		window_value is CCFAIReviewWindowV0183
		and button_value is Button
		and (button_value as Button).text == "AI Review"
		and worker_value is CCFGenerationServiceV0183
		and version_found,
		"The live v0.18.3-or-later Workspace must retain AI Review and its generation service."
	):
		return
	var tabs_found := false
	for node in (window_value as CCFAIReviewWindowV0183).find_children(
		"*", "TabContainer", true, false
	):
		if node is TabContainer and node.get_tab_count() == 4:
			tabs_found = true
			break
	if not _require(
		tabs_found,
		"AI Review must separate score/rubric, findings, selective changes and the full report."
	):
		return
	var review_window := window_value as CCFAIReviewWindowV0183
	review_window.set("_project_data", project.duplicate(true))
	review_window.set("_character_id", character_id)
	review_window.call("_refresh_history")
	var finding_detail_value: Variant = review_window.get("_finding_detail")
	var proposal_rows_value: Variant = review_window.get("_proposal_rows")
	var report_text_value: Variant = review_window.get("_report_text")
	var report_dialog_value: Variant = review_window.get("_report_dialog")
	if not _require(
		finding_detail_value is TextEdit
		and (finding_detail_value as TextEdit).text.contains(
			"deliberately long explanation"
		)
		and proposal_rows_value is Array
		and (proposal_rows_value as Array).size() == 2
		and (proposal_rows_value as Array)[0].get("decision") is OptionButton
		and (proposal_rows_value as Array)[0].get("current") is TextEdit
		and (proposal_rows_value as Array)[0].get("proposed") is TextEdit
		and report_text_value is TextEdit
		and (report_text_value as TextEdit).text.contains("SELECTIVE CHANGES (2)")
		and (report_text_value as TextEdit).text.contains(
			"This deliberately long explanation"
		)
		and report_dialog_value is FileDialog,
		"Long findings need a wrapped detail pane, selective changes need full-height editors with visible decision menus, and a complete exportable text report must be available."
	):
		return
	var report_path := "/tmp/ccf_v0183_ai_review_report_test.txt"
	review_window.call("_save_report", report_path)
	if not _require(
		FileAccess.file_exists(report_path)
		and FileAccess.get_file_as_string(report_path).contains(
			"CHARACTER CARD FORGE — AI REVIEW REPORT"
		),
		"The complete text-only AI Review report must export as a readable .txt file."
	):
		return
	app.queue_free()
	await process_frame
	print("v0.18.3 AI Review, Rating and Selective Improvement regression passed")
	quit(0)
