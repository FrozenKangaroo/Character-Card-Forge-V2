extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0207_GENERATION_CURRENT_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _run() -> void:
	var current := CCFGenerationServiceCurrent.new()
	var historical := CCFGenerationServiceV0195.new()
	var capabilities := current.text_routing_capabilities_v0195()
	var current_script := current.get_script() as Script
	var behavior_matches := true
	for case_value in [
		[HTTPRequest.RESULT_CANT_CONNECT, 0, ""],
		[HTTPRequest.RESULT_SUCCESS, 404, ""],
		[HTTPRequest.RESULT_SUCCESS, 429, ""],
		[HTTPRequest.RESULT_SUCCESS, 503, ""],
		[HTTPRequest.RESULT_SUCCESS, 403, '{"error":"refused"}'],
	]:
		var case: Array = case_value
		var current_category: String = current.call(
			"_technical_failure_category_v0195", case[0], case[1], case[2]
		)
		var historical_category: String = historical.call(
			"_technical_failure_category_v0195", case[0], case[1], case[2]
		)
		if current_category != historical_category:
			behavior_matches = false
			break
	if not _require(
		current_script != null
		and current_script.resource_path == "res://scripts/services/generation_service_current.gd"
		and current.has_method("queue_ai_review_v0183")
		and current.has_method("queue_compact_derivative_v0186")
		and current.has_method("queue_split_character_set_v0190")
		and bool(capabilities.get("single_technical_fallback", false))
		and not bool(capabilities.get("content_failure_fallback", true))
		and behavior_matches,
		"The semantic service must preserve review, derivative, split and routing behavior."
	):
		current.free()
		historical.free()
		return
	current.free()
	historical.free()

	var app_scene := load("res://scenes/main.tscn") as PackedScene
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace := app.get("_workspace") as CCFWorkspaceV0195View
	var active_service: CCFGenerationServiceCurrent = null
	var all_workers_current := true
	if workspace != null:
		active_service = workspace.get("_generation_service") as CCFGenerationServiceCurrent
		var workers: Array = workspace.get("_worker_services_v01526")
		for worker_value in workers:
			if not worker_value is CCFGenerationServiceCurrent:
				all_workers_current = false
				break
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.20.7", "Godot rewrite • v0.20.8",
			"Godot rewrite • v0.20.9", "Godot rewrite • v0.21.0",
			"Godot rewrite • v0.21.1", "Godot rewrite • v0.21.2", "Godot rewrite • v0.21.3"
		]:
			version_found = true
			break
	if not _require(
		workspace != null
		and active_service != null
		and all_workers_current
		and version_found,
		"The live Workspace must use the current service for every isolated AI worker."
	):
		return

	app.queue_free()
	await process_frame
	print("V0207_GENERATION_CURRENT_OK")
	quit(0)
