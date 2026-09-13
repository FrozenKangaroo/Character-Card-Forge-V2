extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0192_TEST_CHAT_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _find_button(root: Node, button_text: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if node is Button and node.text == button_text:
			return node
	return null


func _write_text(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.close()
	return true


func _write_fpchat(path: String, document: Dictionary) -> bool:
	var writer := ZIPPacker.new()
	if writer.open(path) != OK:
		return false
	if writer.start_file("chat.json") != OK:
		writer.close()
		return false
	if writer.write_file(JSON.stringify(document).to_utf8_buffer()) != OK:
		writer.close()
		return false
	writer.close_file()
	writer.close()
	return true


func _run() -> void:
	var runtime_capabilities := CCFFrontPorchChatServiceV0192.capabilities_v0192()
	var contract := CCFFrontPorchChatServiceV0192.contract()
	if not _require(
		bool(runtime_capabilities.get("verified_chat_state", false))
		and bool(runtime_capabilities.get("websocket_stream", false))
		and bool(runtime_capabilities.get("fpchat_import_export", false))
		and bool(runtime_capabilities.get("sillytavern_jsonl_import_export", false))
		and not bool(runtime_capabilities.get("per_chat_model_selection", true))
		and not bool(runtime_capabilities.get("raw_database_writes", true))
		and not bool(runtime_capabilities.get("automatic_chat_creation", true))
		and str(contract.get("runtime", {}).get("state", {}).get("path", "")) == "/api/chat/state"
		and str(contract.get("runtime", {}).get("stream", {}).get("path", "")) == "/api/ws",
		"The v0.19.2 contract must expose verified Front Porch chat/stream/transfer boundaries without inventing model switches or database writes."
	):
		return
	if not _require(
		CCFFrontPorchChatServiceV0192.sessions_path("char a") == "/api/chat/sessions?characterId=char%20a"
		and CCFFrontPorchChatServiceV0192.import_chat_path("full") == "/api/chat/import?mismatch=full"
		and CCFFrontPorchChatServiceV0192.import_chat_path("unknown") == "/api/chat/import"
		and CCFFrontPorchChatServiceV0192.stream_event_name_v0193_hotfix1({"event": "done"}) == "done"
		and CCFFrontPorchChatServiceV0192.stream_event_name_v0193_hotfix1({"event": "chat_updated"}) == "chat_updated"
		and CCFFrontPorchChatServiceV0192.stream_event_name_v0193_hotfix1({"type": "token"}) == "token"
		and CCFFrontPorchChatServiceV0192.stream_error_text_v0193_hotfix1({"event": "error", "data": "Provider stopped"}) == "Provider stopped"
		and str(contract.get("runtime", {}).get("stream", {}).get("event_field", "")) == "event",
		"Front Porch session and mismatch paths must be deterministic and encoded."
	):
		return
	var classified := CCFFrontPorchChatServiceV0192.classify_chat_response({
		"network_result": 0,
		"response_code": 200,
		"body": "{\"status\":\"ok\"}"
	}, "failed")
	if not _require(
		bool(classified.get("ok", false))
		and str(classified.get("payload", {}).get("status", "")) == "ok",
		"Successful supported chat responses must retain their JSON payload."
	):
		return

	var sanitised := CCFTestChatProfileServiceV0192.sanitise_profile({
		"profile_id": "profile-a",
		"name": "Comparison A",
		"persona_id": "persona-a",
		"expected_runtime": "OpenAI-compatible / model-a",
		"notes": "Check the opening.",
		"password": "must-not-persist",
		"api_key": "must-not-persist"
	})
	var profile_save := CCFTestChatProfileServiceV0192.save_profile(sanitised)
	var profile_file_text := FileAccess.get_file_as_string(
		CCFTestChatProfileServiceV0192.PROFILE_FILE
	)
	if not _require(
		bool(profile_save.get("ok", false))
		and CCFTestChatProfileServiceV0192.load_profiles().size() == 1
		and not profile_file_text.contains("must-not-persist")
		and not profile_file_text.contains("api_key")
		and not profile_file_text.contains("password"),
		"Local Test Profiles must remain separate and must never persist credentials."
	):
		return

	var jsonl_path := "user://v0192_fixture.jsonl"
	var jsonl_text := "\n".join([
		JSON.stringify({"user_name": "Alex", "character_name": "Mara", "create_date": "2026-09-13"}),
		JSON.stringify({"name": "Alex", "is_user": true, "mes": "Hello", "send_date": "one"}),
		JSON.stringify({"name": "Mara", "is_user": false, "mes": "Welcome.", "send_date": "two"})
	]) + "\n"
	if not _require(_write_text(jsonl_path, jsonl_text), "The JSONL fixture could not be written."):
		return
	var jsonl_inspection := CCFChatExchangeServiceV0192.inspect_path(jsonl_path)
	var rendered_jsonl := CCFChatExchangeServiceV0192.sillytavern_jsonl(
		jsonl_inspection.get("messages", []), "Alex", "Mara"
	)
	if not _require(
		bool(jsonl_inspection.get("ok", false))
		and str(jsonl_inspection.get("format", "")) == "sillytavern_jsonl"
		and int(jsonl_inspection.get("message_count", 0)) == 2
		and rendered_jsonl.contains("\"is_user\":true")
		and rendered_jsonl.contains("Welcome."),
		"SillyTavern JSONL must inspect and export through a normalized message boundary."
	):
		return
	var json_path := "user://v0192_fixture.json"
	if not _require(
		_write_text(json_path, JSON.stringify({
			"user_name": "Alex",
			"character_name": "Mara",
			"messages": [
				{"name": "Alex", "is_user": true, "mes": "JSON hello"},
				{"name": "Mara", "is_user": false, "mes": "JSON welcome"}
			]
		})),
		"The compatible JSON fixture could not be written."
	):
		return
	var json_inspection := CCFChatExchangeServiceV0192.inspect_path(json_path)
	if not _require(
		bool(json_inspection.get("ok", false))
		and str(json_inspection.get("format", "")) == "sillytavern_json"
		and int(json_inspection.get("message_count", 0)) == 2,
		"Compatible SillyTavern JSON must be previewed alongside JSONL."
	):
		return

	var fpchat_document := {
		"format": "fpai_chat",
		"version": 1,
		"chat_metadata": {"user_name": "Alex", "character_name": "Mara"},
		"messages": [
			{"name": "Alex", "is_user": true, "mes": "Hello", "send_date": "one"},
			{"name": "Mara", "is_user": false, "mes": "Welcome.", "send_date": "two"}
		],
		"fpai": {
			"version": 1,
			"kind": "timeline",
			"future_private_field": {"preserve": true}
		}
	}
	var fpchat_path := "user://v0192_fixture.fpchat"
	if not _require(_write_fpchat(fpchat_path, fpchat_document), "The .fpchat fixture could not be written."):
		return
	var fpchat_inspection := CCFChatExchangeServiceV0192.inspect_path(fpchat_path)
	var stored := CCFChatExchangeServiceV0192.store_managed_copy(
		fpchat_path, "project-a", "character-a"
	)
	var managed_record: Dictionary = stored.get("record", {})
	if not _require(
		bool(fpchat_inspection.get("ok", false))
		and str(fpchat_inspection.get("format", "")) == "fpchat"
		and bool(fpchat_inspection.get("opaque_full_state", false))
		and bool(stored.get("ok", false))
		and FileAccess.get_file_as_bytes(str(managed_record.get("managed_path", ""))) == FileAccess.get_file_as_bytes(fpchat_path)
		and str(managed_record.get("sha256", "")).length() == 64,
		"Front Porch packages must validate and be preserved byte-for-byte with provenance outside card data."
	):
		return

	var unsafe_path := "user://v0192_unsafe.fpchat"
	var unsafe_writer := ZIPPacker.new()
	if unsafe_writer.open(unsafe_path) == OK:
		unsafe_writer.start_file("../chat.json")
		unsafe_writer.write_file(JSON.stringify(fpchat_document).to_utf8_buffer())
		unsafe_writer.close_file()
		unsafe_writer.close()
	var unsafe_inspection := CCFChatExchangeServiceV0192.inspect_path(unsafe_path)
	if not _require(
		not bool(unsafe_inspection.get("ok", true)),
		"Chat packages containing traversal paths must be rejected."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	var app := packed.instantiate()
	get_root().add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	var test_window_value: Variant = workspace_value.get("_test_chat_window_v0192") if workspace_value is CCFWorkspaceV0192View else null
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.19.2",
			"Godot rewrite • v0.19.3",
			"Godot rewrite • v0.19.3-hotfix1",
			"Godot rewrite • v0.19.4"
		]:
			version_found = true
			break
	if not _require(
		workspace_value is CCFWorkspaceV0192View
		and test_window_value is CCFTestChatWindowV0192
		and not (test_window_value as Window).visible
		and (test_window_value as Window).force_native
		and _find_button(workspace_value, "Test Chat") != null
		and _find_button(test_window_value, "Connect & Verify") != null
		and _find_button(test_window_value, "Start Fresh…") != null
		and _find_button(test_window_value, "Delete with Backup…") != null
		and _find_button(test_window_value, "Choose & Preview Chat…") != null
		and version_found,
		"The current app must retain the hidden detachable v0.19.2 Test Chat with explicit runtime and exchange actions."
	):
		return
	var service_source := FileAccess.get_file_as_string(
		"res://scripts/services/front_porch_chat_service_v0192.gd"
	)
	var window_source := FileAccess.get_file_as_string(
		"res://scripts/ui/test_chat_window_v0192.gd"
	)
	if not _require(
		not service_source.to_lower().contains("sqlite")
		and not window_source.to_lower().contains("sqlite")
		and window_source.contains("store_download")
		and window_source.contains("store_managed_copy"),
		"Test Chat must use supported APIs and preserve recoverable copies around transfer/deletion."
	):
		return
	app.queue_free()
	await process_frame
	print("V0192_TEST_CHAT_OK")
	quit(0)
