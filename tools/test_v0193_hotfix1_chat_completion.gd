extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0193_HOTFIX1_CHAT_COMPLETION_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _run() -> void:
	var contract := CCFFrontPorchChatServiceV0192.contract()
	var stream_contract: Dictionary = contract.get("runtime", {}).get("stream", {})
	if not _require(
		str(stream_contract.get("event_field", "")) == "event"
		and (stream_contract.get("events", []) as Array).has("done")
		and CCFFrontPorchChatServiceV0192.stream_event_name_v0193_hotfix1(
			{"event": "token", "data": "Hello"}
		) == "token"
		and CCFFrontPorchChatServiceV0192.stream_event_name_v0193_hotfix1(
			{"event": "done"}
		) == "done"
		and CCFFrontPorchChatServiceV0192.stream_event_name_v0193_hotfix1(
			{"event": "chat_updated"}
		) == "chat_updated",
		"The Front Porch server event envelope must use the supported `event` discriminator."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	var app := packed.instantiate()
	get_root().add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	var test_window_value: Variant = (
		workspace_value.get("_test_chat_window_v0192")
		if workspace_value is CCFWorkspaceV0192View else null
	)
	if not _require(
		test_window_value is CCFTestChatWindowV0192,
		"The hotfix must retain the v0.19.2 Test Chat surface."
	):
		return
	var test_window := test_window_value as CCFTestChatWindowV0192
	var status_value: Variant = test_window.get("_chat_status")
	if not _require(
		status_value is Label,
		"The Test Chat completion status must remain available."
	):
		return
	var status := status_value as Label
	test_window.set("_generation_pending_v0193_hotfix1", true)
	status.text = "Generating in Front Porch… Stop remains available."
	test_window.call("_render_state", {
		"messages": [],
		"isGenerating": true,
		"isSettlingTurn": false
	})
	if not _require(
		bool(test_window.get("_generation_pending_v0193_hotfix1"))
		and status.text.begins_with("Generating"),
		"An active Front Porch generation must retain the pending indicator."
	):
		return
	test_window.call("_render_state", {
		"messages": [{"sender": "Mara", "text": "Finished reply"}],
		"isGenerating": false,
		"isSettlingTurn": false
	})
	if not _require(
		not bool(test_window.get("_generation_pending_v0193_hotfix1"))
		and status.text == "Generation complete."
		and str((test_window.get("_transcript") as TextEdit).text).contains("Finished reply"),
		"Canonical idle chat state must clear a stranded generation indicator and render the completed reply."
	):
		return

	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.19.3-hotfix1", "Godot rewrite • v0.19.4",
			"Godot rewrite • v0.19.5", "Godot rewrite • v0.20.0",
			"Godot rewrite • v0.20.0-hotfix1"
		]:
			version_found = true
			break
	if not _require(
		version_found,
		"The application shell must identify the v0.19.3-hotfix1 candidate."
	):
		return
	app.queue_free()
	await process_frame
	print("V0193_HOTFIX1_CHAT_COMPLETION_OK")
	quit(0)
