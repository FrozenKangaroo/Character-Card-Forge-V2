extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0167_IDEA_DETAIL_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var levels := CCFIdeaGeneratorDetailLevelServiceV0167.new()
	if not _require(levels.is_valid(), "The v0.16.7 detail-level catalog must be valid."):
		return
	if not _require(levels.default_level_id() == "standard", "Standard must remain the default detail level."):
		return
	var ordered := levels.ordered_levels()
	var ids: Array[String] = []
	for level in ordered:
		ids.append(str(level.get("id", "")))
	if not _require(ids == ["quick", "standard", "detailed", "extended"], "Detail levels must stay ordered Quick, Standard, Detailed, Extended."):
		return
	if not _require(levels.normalise_level_id("future-invalid") == "standard", "Unknown detail levels must fall back to Standard."):
		return
	if not _require(levels.output_budget_hint_for("quick") < levels.output_budget_hint_for("standard"), "Quick must request a smaller output budget than Standard."):
		return
	if not _require(levels.output_budget_hint_for("extended") > levels.output_budget_hint_for("detailed"), "Extended must request a larger output budget than Detailed."):
		return

	var service := CCFGenerationServiceV0167.new()
	root.add_child(service)
	var fixture_job: Dictionary = {
		"id": "idea-fixture",
		"type": "ideas",
		"payload": {
			"max_tokens": 1000,
			"messages": [
				{"role": "system", "content": "BASE SYSTEM CONTRACT\n{{user}} remains roleplayer-controlled."},
				{"role": "user", "content": "SOURCE PREMISE: rainy university campus"}
			]
		},
		"metadata": {"idea_user_agency_contract_version": 1}
	}
	var fixture_queue: Array[Dictionary] = [fixture_job]
	service.set("_queue", fixture_queue)
	service.call("_decorate_queued_idea_detail_v0167", "idea-fixture", "detailed")
	var decorated_queue: Array = service.get("_queue")
	if not _require(decorated_queue.size() == 1, "Detail decoration must preserve the queued idea job."):
		return
	var decorated: Dictionary = decorated_queue[0]
	var payload: Dictionary = decorated.get("payload", {})
	var messages: Array = payload.get("messages", [])
	var system_text := str((messages[0] as Dictionary).get("content", ""))
	if not _require(system_text.contains("IDEA DETAIL LEVEL — Detailed"), "Selected detail instruction must reach the queued system prompt."):
		return
	if not _require(system_text.contains("{{user}}"), "Detail decoration must preserve explicit {{user}} agency guidance."):
		return
	if not _require(system_text.contains("invent unnecessary {{user}} backstory"), "Detail prompt must explicitly forbid unnecessary invented {{user}} backstory."):
		return
	if not _require(int(payload.get("max_tokens", 0)) == 1400, "Detailed must scale the provider output budget using its catalog hint."):
		return
	var metadata: Dictionary = decorated.get("metadata", {})
	if not _require(str(metadata.get("idea_detail_level", "")) == "detailed", "Queued metadata must preserve the selected detail level."):
		return
	if not _require(int(metadata.get("idea_user_agency_contract_version", 0)) == 1, "v0.16.7 must preserve the previous Idea Generator user-agency contract metadata."):
		return

	# Also cover the idle-worker race where a just-queued job has already moved
	# to _active_job before the detail-level decorator runs.
	var active_fixture := fixture_job.duplicate(true)
	active_fixture["id"] = "active-idea-fixture"
	service.set("_queue", [] as Array[Dictionary])
	service.set("_active_job", active_fixture)
	service.call(
		"_decorate_queued_idea_detail_v0167", "active-idea-fixture", "extended"
	)
	var active_decorated: Dictionary = service.get("_active_job")
	var active_payload: Dictionary = active_decorated.get("payload", {})
	var active_messages: Array = active_payload.get("messages", [])
	if not _require(
		str((active_messages[0] as Dictionary).get("content", "")).contains(
			"IDEA DETAIL LEVEL — Extended"
		),
		"Immediately active Idea jobs must receive the selected detail instruction."
	):
		return
	if not _require(
		int(active_payload.get("max_tokens", 0)) == 1800,
		"Extended must scale an immediately active Idea job's output budget."
	):
		return
	service.queue_free()
	await process_frame

	CCFStorageService.ensure_directories()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.16.7 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v0167"), "The active application shell must identify v0.16.7."):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(workspace_value is CCFWorkspaceV0167View, "The real application must install the v0.16.7 workspace."):
		return
	var workspace := workspace_value as CCFWorkspaceV0167View
	var selector := workspace.find_child("IdeaDetailLevelSelectorV0167", true, false) as OptionButton
	if not _require(selector != null, "The live Idea Generator controller must expose the v0.16.7 detail selector."):
		return
	if not _require(selector.item_count == 4, "The live selector must expose all four data-driven detail levels."):
		return
	if not _require(str(selector.get_selected_metadata()) == "standard", "The live selector must open on Standard."):
		return
	selector.select(0)
	workspace.call("_on_idea_detail_selected_v0167", 0)
	var capabilities := workspace.idea_detail_level_capabilities_v0167()
	if not _require(str(capabilities.get("selected_level", "")) == "quick", "Changing the selector must persist for the current Idea Generator session."):
		return
	if not _require(bool(capabilities.get("provider_budget_forwarding", false)), "The workspace must advertise provider output-budget forwarding."):
		return

	var predecessor_capabilities: Dictionary = workspace.idea_user_agency_capabilities_v01533_hotfix3()
	if not _require(bool(predecessor_capabilities.get("semantic_validation", false)), "v0.16.7 must preserve v0.15.33 user-agency semantic validation."):
		return

	app.queue_free()
	await process_frame
	print("v0.16.7 Idea Generator detail-level regression passed")
	quit(0)
