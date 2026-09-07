class_name CCFFrontPorchInstallServiceV0173
extends Node

const CONNECTION_FILE := (
	CCFStorageService.SETTINGS_DIR + "/front_porch_connection_v0173.json"
)
const DEFAULT_BASE_URL := "http://127.0.0.1:8085"
const HTTP_REQUEST_SUCCESS := 0
const REQUEST_TIMEOUT_SECONDS := 15.0

var _base_url := DEFAULT_BASE_URL
var _session_cookie := ""
var _authenticated := false


static func default_connection() -> Dictionary:
	return {
		"format_version": 1,
		"base_url": DEFAULT_BASE_URL,
		"username": ""
	}


static func sanitise_connection(raw: Variant) -> Dictionary:
	var result := default_connection()
	if raw is Dictionary:
		result["base_url"] = normalise_base_url(
			str((raw as Dictionary).get("base_url", DEFAULT_BASE_URL))
		)
		result["username"] = str(
			(raw as Dictionary).get("username", "")
		).strip_edges()
	return result


static func load_connection() -> Dictionary:
	CCFStorageService.ensure_directories()
	if not FileAccess.file_exists(CONNECTION_FILE):
		return default_connection()
	var file := FileAccess.open(CONNECTION_FILE, FileAccess.READ)
	if file == null:
		return default_connection()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return sanitise_connection(parsed)


static func save_connection(connection: Dictionary) -> Dictionary:
	var clean := sanitise_connection(connection)
	var validation := validate_base_url(str(clean.get("base_url", "")))
	if not bool(validation.get("ok", false)):
		return validation
	CCFStorageService.ensure_directories()
	var file := FileAccess.open(CONNECTION_FILE, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not save Front Porch connection settings."}
	file.store_string(JSON.stringify(clean, "  "))
	file.close()
	return {"ok": true, "connection": clean}


static func normalise_base_url(value: String) -> String:
	var result := value.strip_edges()
	while result.ends_with("/"):
		result = result.left(result.length() - 1)
	return result if not result.is_empty() else DEFAULT_BASE_URL


static func validate_base_url(value: String) -> Dictionary:
	var url := normalise_base_url(value)
	var lower := url.to_lower()
	var scheme := ""
	if lower.begins_with("http://"):
		scheme = "http"
	elif lower.begins_with("https://"):
		scheme = "https"
	else:
		return {
			"ok": false,
			"error": "Front Porch address must begin with http:// or https://."
		}
	var authority := url.substr(url.find("://") + 3).get_slice("/", 0)
	if authority.is_empty() or authority.contains("@"):
		return {"ok": false, "error": "Front Porch address has an invalid host."}
	var host := authority
	if authority.begins_with("["):
		var close := authority.find("]")
		if close < 0:
			return {"ok": false, "error": "Front Porch address has an invalid host."}
		host = authority.substr(1, close - 1)
	elif authority.contains(":"):
		host = authority.get_slice(":", 0)
	host = host.to_lower()
	var loopback := host in ["127.0.0.1", "localhost", "::1"]
	if scheme == "http" and not loopback:
		return {
			"ok": false,
			"error": (
				"Plain HTTP is only allowed for this computer. Use HTTPS for a "
				+ "Front Porch server on another device."
			)
		}
	return {"ok": true, "base_url": url, "loopback": loopback}


static func import_path(
	filename: String, collision := "ask", replace_id := ""
) -> String:
	var policy := collision if collision in ["ask", "keepBoth", "replace"] else "ask"
	var path := "/api/characters/import?filename=%s&collision=%s" % [
		filename.uri_encode(), policy.uri_encode()
	]
	if policy == "replace" and not replace_id.strip_edges().is_empty():
		path += "&replaceId=%s" % replace_id.strip_edges().uri_encode()
	return path


static func classify_health_response(raw: Dictionary) -> Dictionary:
	var failure := _transport_failure(raw)
	if not failure.is_empty():
		return failure
	var code := int(raw.get("response_code", 0))
	var payload: Variant = _payload(raw)
	if code != 200 or not payload is Dictionary:
		return _http_failure(code, payload, "Front Porch health check failed.")
	if str((payload as Dictionary).get("status", "")) != "ok":
		return {"ok": false, "error": "The server did not identify itself as healthy."}
	return {
		"ok": true,
		"version": str((payload as Dictionary).get("version", "unknown")),
		"setup_required": bool((payload as Dictionary).get("setupRequired", false)),
		"setup_token_required": bool(
			(payload as Dictionary).get("setupTokenRequired", false)
		),
		"secure": bool((payload as Dictionary).get("secure", false)),
		"payload": payload
	}


static func classify_auth_state_response(raw: Dictionary) -> Dictionary:
	var failure := _transport_failure(raw)
	if not failure.is_empty():
		return failure
	var code := int(raw.get("response_code", 0))
	var payload: Variant = _payload(raw)
	if code != 200 or not payload is Dictionary:
		return _http_failure(code, payload, "Could not read Front Porch login state.")
	return {
		"ok": true,
		"authenticated": bool((payload as Dictionary).get("authenticated", false)),
		"setup_required": bool((payload as Dictionary).get("setupRequired", false)),
		"username": str((payload as Dictionary).get("username", "")),
		"totp_enabled": bool((payload as Dictionary).get("totpEnabled", false)),
		"payload": payload
	}


static func classify_login_response(raw: Dictionary) -> Dictionary:
	var failure := _transport_failure(raw)
	if not failure.is_empty():
		return failure
	var code := int(raw.get("response_code", 0))
	var payload: Variant = _payload(raw)
	if code == 200 and payload is Dictionary and bool(payload.get("ok", false)):
		return {"ok": true, "authenticated": true, "payload": payload}
	if code == 401 and payload is Dictionary and bool(payload.get("totpRequired", false)):
		return {
			"ok": false,
			"totp_required": true,
			"error": "Front Porch requires the current two-factor code."
		}
	if code == 409 and payload is Dictionary and bool(payload.get("setupRequired", false)):
		return {
			"ok": false,
			"setup_required": true,
			"error": "Create the Front Porch web login before connecting."
		}
	return _http_failure(code, payload, "Front Porch login failed.")


static func classify_import_response(raw: Dictionary) -> Dictionary:
	var failure := _transport_failure(raw)
	if not failure.is_empty():
		return failure
	var code := int(raw.get("response_code", 0))
	var payload: Variant = _payload(raw)
	if code == 200 and payload is Dictionary:
		var character_id := str(payload.get("id", "")).strip_edges()
		if character_id.is_empty():
			return {
				"ok": false,
				"response_code": code,
				"error": "Front Porch accepted the request but returned no character ID.",
				"payload": payload
			}
		return {
			"ok": true,
			"status": "updated" if bool(payload.get("replaced", false)) else "accepted",
			"character_id": character_id,
			"name": str(payload.get("name", "Untitled Character")),
			"replaced": bool(payload.get("replaced", false)),
			"payload": payload
		}
	if code == 409 and payload is Dictionary:
		var collision_status := str(payload.get("status", payload.get("error", "")))
		if collision_status == "name_collision":
			return {
				"ok": false,
				"collision": true,
				"name": str(payload.get("name", "Untitled Character")),
				"existing": payload.get("existing", []).duplicate(true),
				"response_code": code,
				"payload": payload
			}
	if code == 401:
		return {
			"ok": false,
			"auth_required": true,
			"response_code": code,
			"error": "Front Porch login expired. Connect again and retry."
		}
	return _http_failure(code, payload, "Front Porch declined the character import.")


func configure(base_url: String) -> Dictionary:
	var validation := validate_base_url(base_url)
	if not bool(validation.get("ok", false)):
		return validation
	var next_url := str(validation.get("base_url", DEFAULT_BASE_URL))
	if next_url != _base_url:
		clear_session()
	_base_url = next_url
	return validation


func base_url() -> String:
	return _base_url


func is_authenticated() -> bool:
	return _authenticated and not _session_cookie.is_empty()


func clear_session() -> void:
	_session_cookie = ""
	_authenticated = false


func detect() -> Dictionary:
	var raw := await _perform_request(HTTPClient.METHOD_GET, "/api/health")
	return classify_health_response(raw)


func auth_state() -> Dictionary:
	var raw := await _perform_request(
		HTTPClient.METHOD_GET, "/api/auth/state", "", _session_headers()
	)
	var result := classify_auth_state_response(raw)
	_authenticated = bool(result.get("authenticated", false)) and not _session_cookie.is_empty()
	return result


func login(username: String, password: String, totp_code := "") -> Dictionary:
	var payload := {"username": username, "password": password}
	if not totp_code.strip_edges().is_empty():
		payload["totpCode"] = totp_code.strip_edges()
	var raw := await _perform_request(
		HTTPClient.METHOD_POST,
		"/api/auth/login",
		JSON.stringify(payload),
		PackedStringArray(["Content-Type: application/json; charset=utf-8"])
	)
	var result := classify_login_response(raw)
	if bool(result.get("ok", false)):
		_session_cookie = _session_cookie_from_headers(raw.get("headers", []))
		_authenticated = not _session_cookie.is_empty()
		if not _authenticated:
			return {
				"ok": false,
				"error": "Front Porch logged in but did not return a usable session."
			}
	else:
		clear_session()
	return result


func probe_character_api() -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	var raw := await _perform_request(
		HTTPClient.METHOD_GET,
		"/api/characters?scope=allCharacters&sort=name",
		"",
		_session_headers()
	)
	var failure := _transport_failure(raw)
	if not failure.is_empty():
		return failure
	var code := int(raw.get("response_code", 0))
	if code == 200:
		return {"ok": true, "character_import": true, "raw_database_writes": false}
	if code == 401:
		clear_session()
		return {"ok": false, "auth_required": true, "error": "Front Porch login expired."}
	return _http_failure(code, _payload(raw), "Front Porch character API is unavailable.")


func install_json_card(
	card_json: String,
	filename: String,
	collision := "ask",
	replace_id := ""
) -> Dictionary:
	if card_json.strip_edges().is_empty():
		return {"ok": false, "error": "The character card is empty."}
	return await install_card_bytes(
		card_json.to_utf8_buffer(),
		filename,
		"application/json; charset=utf-8",
		collision,
		replace_id
	)


func install_card_bytes(
	card_bytes: PackedByteArray,
	filename: String,
	content_type: String,
	collision := "ask",
	replace_id := ""
) -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	if card_bytes.is_empty():
		return {"ok": false, "error": "The character card is empty."}
	var headers := _session_headers()
	headers.append("Content-Type: %s" % content_type)
	var raw := await _perform_raw_request(
		HTTPClient.METHOD_POST,
		import_path(filename, collision, replace_id),
		card_bytes,
		headers
	)
	var result := classify_import_response(raw)
	if bool(result.get("auth_required", false)):
		clear_session()
	return result


func capabilities() -> Dictionary:
	return {
		"front_porch_api": true,
		"health_detection": true,
		"cookie_session_auth": true,
		"character_import": true,
		"character_card_png_upload": true,
		"portrait_included_when_available": true,
		"json_definition_fallback": true,
		"collision_ask": true,
		"collision_keep_both": true,
		"collision_replace": true,
		"stable_identity_server_owned": true,
		"portable_json_fallback": true,
		"password_persisted": false,
		"totp_persisted": false,
		"raw_database_writes": false
	}


func _perform_request(
	method: HTTPClient.Method,
	path: String,
	body := "",
	headers := PackedStringArray()
) -> Dictionary:
	if not is_inside_tree():
		return {
			"network_result": -1,
			"response_code": 0,
			"headers": PackedStringArray(),
			"body": "",
			"error": "Front Porch client is not attached to the running app."
		}
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SECONDS
	request.use_threads = true
	add_child(request)
	var start_error := request.request(_base_url + path, headers, method, body)
	if start_error != OK:
		request.queue_free()
		return {
			"network_result": -1,
			"response_code": 0,
			"headers": PackedStringArray(),
			"body": "",
			"error": "Could not start the Front Porch request (%s)." % error_string(start_error)
		}
	var completed: Array = await request.request_completed
	request.queue_free()
	return {
		"network_result": int(completed[0]),
		"response_code": int(completed[1]),
		"headers": completed[2],
		"body": (completed[3] as PackedByteArray).get_string_from_utf8()
	}


func _perform_raw_request(
	method: HTTPClient.Method,
	path: String,
	body: PackedByteArray,
	headers := PackedStringArray()
) -> Dictionary:
	if not is_inside_tree():
		return {
			"network_result": -1,
			"response_code": 0,
			"headers": PackedStringArray(),
			"body": "",
			"error": "Front Porch client is not attached to the running app."
		}
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SECONDS
	request.use_threads = true
	add_child(request)
	var start_error := request.request_raw(
		_base_url + path, headers, method, body
	)
	if start_error != OK:
		request.queue_free()
		return {
			"network_result": -1,
			"response_code": 0,
			"headers": PackedStringArray(),
			"body": "",
			"error": "Could not start the Front Porch request (%s)." % error_string(start_error)
		}
	var completed: Array = await request.request_completed
	request.queue_free()
	return {
		"network_result": int(completed[0]),
		"response_code": int(completed[1]),
		"headers": completed[2],
		"body": (completed[3] as PackedByteArray).get_string_from_utf8()
	}


func _session_headers() -> PackedStringArray:
	var headers := PackedStringArray(["Accept: application/json"])
	if not _session_cookie.is_empty():
		headers.append("Cookie: %s" % _session_cookie)
	return headers


static func _session_cookie_from_headers(headers_value: Variant) -> String:
	if not headers_value is Array and not headers_value is PackedStringArray:
		return ""
	for raw_header in headers_value:
		var header := str(raw_header)
		if not header.to_lower().begins_with("set-cookie:"):
			continue
		var value := header.substr(header.find(":") + 1).strip_edges()
		var first_part := value.get_slice(";", 0).strip_edges()
		if first_part.to_lower().begins_with("fpa_session="):
			return first_part
	return ""


static func _transport_failure(raw: Dictionary) -> Dictionary:
	if int(raw.get("network_result", -1)) == HTTP_REQUEST_SUCCESS:
		return {}
	var message := str(raw.get("error", "")).strip_edges()
	if message.is_empty():
		message = (
			"Could not reach Front Porch. Enable its Web Server and verify the address."
		)
	return {
		"ok": false,
		"network_error": true,
		"response_code": int(raw.get("response_code", 0)),
		"error": message
	}


static func _payload(raw: Dictionary) -> Variant:
	var parsed: Variant = JSON.parse_string(str(raw.get("body", "")))
	return parsed if parsed != null else {}


static func _http_failure(code: int, payload: Variant, fallback: String) -> Dictionary:
	var message := fallback
	if payload is Dictionary:
		var reported := str((payload as Dictionary).get("error", "")).strip_edges()
		if not reported.is_empty():
			message = reported
	return {
		"ok": false,
		"response_code": code,
		"error": "%s (HTTP %d)" % [message, code] if code > 0 else message,
		"payload": payload
	}
