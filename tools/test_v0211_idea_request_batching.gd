extends SceneTree

const BATCHING = preload(
	"res://scripts/services/idea_generator_batching_v0211.gd"
)
const GENERATION_CURRENT = preload(
	"res://scripts/services/generation_service_current.gd"
)

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_batch_contract()
	if not _failed:
		await _test_live_workspace_aggregation()
	if _failed:
		quit(1)
		return
	print("V0211_IDEA_REQUEST_BATCHING_OK")
	quit(0)


func _test_batch_contract() -> void:
	_require(
		BATCHING.request_plan(6, 12) == [6],
		"The existing six-idea default must remain one provider request."
	)
	var one_at_a_time := BATCHING.request_plan(25, 1)
	_require(
		one_at_a_time.size() == 25
		and one_at_a_time.all(func(value: int) -> bool: return value == 1),
		"One-at-a-time mode must create one bounded request for every requested idea."
	)
	_require(
		BATCHING.request_plan(50, 12) == [12, 12, 12, 12, 2],
		"The maximum total must split into provider-safe requests with a final remainder."
	)
	_require(
		BATCHING.request_plan(999, 999) == [12, 12, 12, 12, 2],
		"Total and per-request values must remain bounded to 50 and 12."
	)
	var service := GENERATION_CURRENT.new()
	root.add_child(service)
	var fixture_job := {
		"id": "batch-fixture",
		"type": "ideas",
		"label": "Generate 2 character ideas",
		"payload": {
			"messages": [
				{"role": "system", "content": "BASE IDEA CONTRACT"},
				{"role": "user", "content": "Generate two ideas."}
			]
		},
		"metadata": {"idea_count": 2, "project_id": "fixture"}
	}
	service.set("_queue", [fixture_job] as Array[Dictionary])
	var decorated := service.decorate_idea_batch_job_v0211(
		"batch-fixture", "batch-group", 1, 3, 6
	)
	var queue: Array = service.get("_queue")
	var job: Dictionary = queue[0]
	var metadata: Dictionary = job.get("metadata", {})
	var messages: Array = (job.get("payload", {}) as Dictionary).get(
		"messages", []
	)
	_require(
		decorated
		and str(metadata.get("idea_batch_group_id", "")) == "batch-group"
		and int(metadata.get("idea_batch_index", -1)) == 1
		and int(metadata.get("idea_batch_request_count", 0)) == 3
		and int(metadata.get("idea_batch_requested_total", 0)) == 6,
		"Queued child jobs must retain stable aggregation metadata."
	)
	_require(
		str((messages[0] as Dictionary).get("content", "")).contains(
			"request 2 of 3"
		)
		and str(job.get("label", "")).contains("request 2/3"),
		"Each provider request must receive visible batch identity without changing its requested idea count."
	)
	service.queue_free()


func _test_live_workspace_aggregation() -> void:
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
	var count_value: Variant = workspace.get("_idea_count")
	var count := count_value as SpinBox
	var per_request := workspace.find_child(
		"IdeasPerRequestV0211", true, false
	) as SpinBox
	var plan_hint := workspace.find_child(
		"IdeaBatchPlanHintV0211", true, false
	) as Label
	if not _require(
		count != null and per_request != null and plan_hint != null,
		"The live Idea Generator must expose total and per-request controls plus the request plan."
	):
		return
	_require(
		int(count.max_value) == 50
		and int(per_request.min_value) == 1
		and int(per_request.max_value) == 12
		and int(per_request.value) == 12,
		"The total must increase to 50 while the provider-safe default remains up to 12 ideas per request."
	)
	var settings_view_value: Variant = app.get("_settings_view")
	var default_count: SpinBox = (
		settings_view_value.get("_idea_count")
		if settings_view_value is Control
		else null
	)
	_require(
		default_count != null and int(default_count.max_value) == 50,
		"Settings must allow a saved default of up to 50 ideas."
	)
	count.value = 25
	per_request.value = 1
	workspace.call("_refresh_idea_batch_plan_v0211")
	var capabilities := workspace.idea_batching_capabilities_v0211()
	var plan_value: Variant = capabilities.get("request_plan", [])
	_require(
		plan_value is Array
		and (plan_value as Array).size() == 25
		and plan_hint.text.contains("25 sequential provider requests")
		and plan_hint.text.contains("one idea at a time"),
		"The UI must disclose the exact provider request count before one-at-a-time generation."
	)
	var service_capabilities: Dictionary = capabilities.get("service", {})
	_require(
		int(service_capabilities.get("maximum_total_ideas", 0)) == 50
		and int(service_capabilities.get("maximum_ideas_per_request", 0)) == 12
		and bool(service_capabilities.get("partial_success_preserved", false)),
		"The live service must advertise bounded batching and partial-success preservation."
	)

	workspace.set("_idea_batch_group_id_v0211", "aggregate-fixture")
	workspace.set("_idea_batch_requested_total_v0211", 5)
	workspace.set("_idea_batch_expected_requests_v0211", 3)
	workspace.set("_idea_batch_job_indices_v0211", {"job-a": 0, "job-b": 1, "job-c": 2})
	var generate_button_value: Variant = workspace.get("_idea_generate_button")
	var generate_button := generate_button_value as Button
	generate_button.disabled = true
	var metadata := {
		"idea_batch_group_id": "aggregate-fixture",
		"idea_detail_level": "standard",
		"project_id": ""
	}
	workspace.call(
		"_handle_completed_idea_batch_v0211",
		"job-a",
		[_idea("Idea 1"), _idea("Idea 2")],
		metadata
	)
	workspace.call(
		"_handle_completed_idea_batch_v0211",
		"job-b",
		[_idea("Idea 3"), _idea("Idea 4")],
		metadata
	)
	workspace.call(
		"_handle_completed_idea_batch_v0211",
		"job-c",
		[_idea("Idea 5")],
		metadata
	)
	var generator_value: Variant = workspace.get("_idea_generator_v01532")
	var captured: Array = (
		(generator_value as CCFIdeaGeneratorWindowCurrent).get(
			"_last_generated_ideas_v01532"
		)
		if generator_value is CCFIdeaGeneratorWindowCurrent
		else []
	)
	var idea_status_value: Variant = workspace.get("_idea_status")
	var idea_status := idea_status_value as Label
	_require(
		captured.size() == 5
		and str((captured[0] as Dictionary).get("title", "")) == "Idea 1"
		and str((captured[4] as Dictionary).get("title", "")) == "Idea 5",
		"Successful request results must combine in request order before Notebook capture."
	)
	_require(
		not generate_button.disabled
		and idea_status.text.contains("Generated 5/5 usable ideas across 3 provider requests"),
		"The Generate action must re-enable only after the logical batch finishes."
	)

	workspace.set("_idea_batch_group_id_v0211", "partial-fixture")
	workspace.set("_idea_batch_requested_total_v0211", 2)
	workspace.set("_idea_batch_expected_requests_v0211", 2)
	workspace.set("_idea_batch_job_indices_v0211", {"job-good": 0, "job-fail": 1})
	generate_button.disabled = true
	workspace.call(
		"_handle_completed_idea_batch_v0211",
		"job-good",
		[_idea("Preserved Result")],
		{"idea_batch_group_id": "partial-fixture", "idea_detail_level": "standard"}
	)
	workspace.call("_on_job_failed", "job-fail", "ideas", "Small model timed out.")
	captured = (generator_value as CCFIdeaGeneratorWindowCurrent).get(
		"_last_generated_ideas_v01532"
	)
	_require(
		captured.size() == 1
		and str((captured[0] as Dictionary).get("title", "")) == "Preserved Result"
		and idea_status.text.contains("successful results were kept"),
		"A failed child request must not discard successful ideas from the same run."
	)
	app.queue_free()
	await process_frame


func _idea(title: String) -> Dictionary:
	return {
		"title": title,
		"character_name": title,
		"character_role": "Roleplay character",
		"source_anchor": "",
		"roleplay_hook": "%s leaves the next decision to {{user}}." % title,
		"concept": "%s is a distinct roleplay-ready concept for {{user}}." % title,
		"tags": ["batch-test"]
	}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
