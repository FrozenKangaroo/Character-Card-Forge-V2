class_name CCFFrontPorchChatServiceV0192
extends CCFFrontPorchSyncServiceV0185

signal stream_connected_v0192
signal stream_token_v0192(text: String)
signal stream_done_v0192
signal stream_error_v0192(message_text: String)
signal stream_chat_updated_v0192
signal stream_generating_v0193_hotfix1

const CONTRACT_PATH := "res://data/front_porch_chat_contract_v0192.json"
const MAX_IMPORT_BYTES := 256 * 1024 * 1024

var _stream_peer: WebSocketPeer
var _stream_open := false


static func capabilities_v0192() -> Dictionary:
	return {
		"verified_chat_state": true,
		"character_selection": true,
		"session_listing_and_selection": true,
		"explicit_fresh_chat": true,
		"send_and_stop": true,
		"websocket_stream": true,
		"persona_selection": true,
		"fpchat_import_export": true,
		"sillytavern_jsonl_import_export": true,
		"local_test_profiles": true,
		"per_chat_model_selection": false,
		"per_chat_preset_selection": false,
		"group_test_chat": false,
		"raw_database_writes": false,
		"credentials_persisted": false,
		"automatic_chat_creation": false
	}


static func contract() -> Dictionary:
	var file := FileAccess.open(CONTRACT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return (parsed as Dictionary).duplicate(true) if parsed is Dictionary else {}


static func sessions_path(character_id: String) -> String:
	return "/api/chat/sessions?characterId=%s" % character_id.strip_edges().uri_encode()


static func import_chat_path(mismatch_mode := "") -> String:
	var clean_mode := mismatch_mode.strip_edges()
	if clean_mode in ["full", "dialogue"]:
		return "/api/chat/import?mismatch=%s" % clean_mode.uri_encode()
	return "/api/chat/import"


static func classify_chat_response(raw: Dictionary, fallback: String) -> Dictionary:
	var failure := _transport_failure(raw)
	if not failure.is_empty():
		return failure
	var response_code := int(raw.get("response_code", 0))
	var payload: Variant = _payload(raw)
	if response_code >= 200 and response_code < 300 and payload is Dictionary:
		return {"ok": true, "payload": payload, "response_code": response_code}
	if response_code == 401:
		return {
			"ok": false,
			"auth_required": true,
			"response_code": response_code,
			"error": "Front Porch login expired. Connect again and retry."
		}
	return _http_failure(response_code, payload, fallback)


static func stream_event_name_v0193_hotfix1(stream_event: Dictionary) -> String:
	# Front Porch's supported multiplexed stream uses `event`. Keep `type` as a
	# compatibility fallback for early development builds of the endpoint.
	return str(
		stream_event.get("event", stream_event.get("type", ""))
	).strip_edges().to_lower()


static func stream_error_text_v0193_hotfix1(stream_event: Dictionary) -> String:
	for key in ["message", "error", "data"]:
		var value := str(stream_event.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return "Front Porch generation failed."


func verify_chat_contract() -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	var state_result := await chat_state()
	if not bool(state_result.get("ok", false)):
		return state_result
	var persona_result := await personas()
	if not bool(persona_result.get("ok", false)):
		return persona_result
	var runtime_result := await _json_request(HTTPClient.METHOD_GET, "/api/backend/status")
	var runtime_payload: Dictionary = {}
	if bool(runtime_result.get("ok", false)):
		runtime_payload = runtime_result.get("payload", {}).duplicate(true)
	return {
		"ok": true,
		"chat_state": state_result.get("payload", {}),
		"personas": persona_result.get("personas", []),
		"runtime": runtime_payload,
		"capabilities": capabilities_v0192()
	}


func chat_state() -> Dictionary:
	return await _json_request(HTTPClient.METHOD_GET, "/api/chat/state")


func personas() -> Dictionary:
	var result := await _json_request(HTTPClient.METHOD_GET, "/api/personas")
	if not bool(result.get("ok", false)):
		return result
	var payload: Dictionary = result.get("payload", {})
	var persona_value: Variant = payload.get("personas", [])
	return {
		"ok": true,
		"personas": persona_value.duplicate(true) if persona_value is Array else []
	}


func select_character(character_id: String) -> Dictionary:
	return await _json_request(
		HTTPClient.METHOD_POST,
		"/api/chat/select",
		{"characterId": character_id.strip_edges()}
	)


func start_fresh(character_id: String, persona_id := "") -> Dictionary:
	var payload := {"characterId": character_id.strip_edges()}
	if not persona_id.strip_edges().is_empty():
		payload["personaId"] = persona_id.strip_edges()
	return await _json_request(HTTPClient.METHOD_POST, "/api/chat/start-fresh", payload)


func list_sessions(character_id: String) -> Dictionary:
	var result := await _json_request(
		HTTPClient.METHOD_GET, sessions_path(character_id)
	)
	if not bool(result.get("ok", false)):
		return result
	var payload: Dictionary = result.get("payload", {})
	var sessions_value: Variant = payload.get("sessions", [])
	return {
		"ok": true,
		"sessions": sessions_value.duplicate(true) if sessions_value is Array else []
	}


func select_session(session_id: String) -> Dictionary:
	return await _json_request(
		HTTPClient.METHOD_POST,
		"/api/chat/session",
		{"sessionId": session_id.strip_edges()}
	)


func send_message(message_text: String) -> Dictionary:
	if message_text.strip_edges().is_empty():
		return {"ok": false, "error": "Enter a test message first."}
	return await _json_request(
		HTTPClient.METHOD_POST, "/api/chat/send", {"text": message_text}
	)


func stop_generation() -> Dictionary:
	return await _json_request(HTTPClient.METHOD_POST, "/api/chat/stop", {})


func delete_session(session_id: String) -> Dictionary:
	return await _json_request(
		HTTPClient.METHOD_POST,
		"/api/chat/session",
		{
			"action": "delete",
			"sessionId": session_id.strip_edges(),
			"startReplacement": false
		}
	)


func export_current(format_id: String) -> Dictionary:
	var path := "/api/chat/export.fpchat" if format_id == "fpchat" else "/api/chat/export.jsonl"
	var raw := await _perform_binary_request(
		HTTPClient.METHOD_GET, path, _session_headers()
	)
	var failure := _transport_failure(raw)
	if not failure.is_empty():
		return failure
	var response_code := int(raw.get("response_code", 0))
	if response_code == 401:
		clear_session()
		return {"ok": false, "auth_required": true, "error": "Front Porch login expired."}
	if response_code < 200 or response_code >= 300:
		var error_body := (raw.get("bytes", PackedByteArray()) as PackedByteArray).get_string_from_utf8()
		return _http_failure(response_code, JSON.parse_string(error_body), "Front Porch could not export this chat.")
	return {
		"ok": true,
		"bytes": raw.get("bytes", PackedByteArray()),
		"headers": raw.get("headers", PackedStringArray())
	}


func import_chat(chat_bytes: PackedByteArray, mismatch_mode := "") -> Dictionary:
	if chat_bytes.is_empty():
		return {"ok": false, "error": "The selected chat file is empty."}
	if chat_bytes.size() > MAX_IMPORT_BYTES:
		return {"ok": false, "error": "The selected chat exceeds Front Porch's 256 MB import limit."}
	var headers := _session_headers()
	headers.append("Content-Type: application/octet-stream")
	var raw := await _perform_raw_request(
		HTTPClient.METHOD_POST,
		import_chat_path(mismatch_mode),
		chat_bytes,
		headers
	)
	var result := classify_chat_response(raw, "Front Porch could not import this chat.")
	if int(result.get("response_code", 0)) == 409:
		var conflict_payload: Dictionary = result.get("payload", {}) if result.get("payload", {}) is Dictionary else {}
		if str(conflict_payload.get("error", "")) == "character_mismatch":
			result["character_mismatch"] = true
			result["package_name"] = str(conflict_payload.get("packageName", "Unknown"))
			result["active_name"] = str(conflict_payload.get("activeName", "Unknown"))
	if bool(result.get("auth_required", false)):
		clear_session()
	return result


func connect_stream() -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "error": "Connect to Front Porch before opening the live stream."}
	disconnect_stream()
	_stream_peer = WebSocketPeer.new()
	_stream_peer.handshake_headers = PackedStringArray(["Cookie: %s" % _session_cookie])
	var stream_url := base_url()
	if stream_url.begins_with("https://"):
		stream_url = "wss://" + stream_url.trim_prefix("https://")
	else:
		stream_url = "ws://" + stream_url.trim_prefix("http://")
	var connect_error := _stream_peer.connect_to_url(stream_url + "/api/ws")
	if connect_error != OK:
		_stream_peer = null
		return {"ok": false, "error": "Could not open Front Porch's live chat stream."}
	return {"ok": true}


func stream_is_active() -> bool:
	return (
		_stream_peer != null
		and _stream_peer.get_ready_state() in [
			WebSocketPeer.STATE_CONNECTING, WebSocketPeer.STATE_OPEN
		]
	)


func poll_stream() -> void:
	if _stream_peer == null:
		return
	_stream_peer.poll()
	var ready_state := _stream_peer.get_ready_state()
	if ready_state == WebSocketPeer.STATE_OPEN and not _stream_open:
		_stream_open = true
		stream_connected_v0192.emit()
	if ready_state == WebSocketPeer.STATE_CLOSED:
		_stream_peer = null
		_stream_open = false
		return
	while _stream_peer != null and _stream_peer.get_available_packet_count() > 0:
		var packet_text := _stream_peer.get_packet().get_string_from_utf8()
		var parsed: Variant = JSON.parse_string(packet_text)
		if not parsed is Dictionary:
			continue
		var stream_event := parsed as Dictionary
		match stream_event_name_v0193_hotfix1(stream_event):
			"token":
				stream_token_v0192.emit(str(stream_event.get("data", "")))
			"done":
				stream_done_v0192.emit()
			"error":
				stream_error_v0192.emit(
					stream_error_text_v0193_hotfix1(stream_event)
				)
			"chat_updated":
				stream_chat_updated_v0192.emit()
			"generating":
				stream_generating_v0193_hotfix1.emit()


func disconnect_stream() -> void:
	if _stream_peer != null:
		_stream_peer.close()
	_stream_peer = null
	_stream_open = false


func _json_request(
	method: HTTPClient.Method, path: String, payload: Variant = null
) -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	var body := ""
	var headers := _session_headers()
	if payload != null:
		body = JSON.stringify(payload)
		headers.append("Content-Type: application/json; charset=utf-8")
	var raw := await _perform_request(method, path, body, headers)
	var result := classify_chat_response(raw, "Front Porch chat request failed.")
	if bool(result.get("auth_required", false)):
		clear_session()
	return result
