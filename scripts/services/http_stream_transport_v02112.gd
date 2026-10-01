class_name CCFHTTPStreamTransportV02112
extends Node

signal stream_opened(request_token: int, response_code: int, headers: PackedStringArray)
signal body_chunk(request_token: int, chunk: PackedByteArray)
signal request_finished(request_token: int, response_code: int, headers: PackedStringArray)
signal request_failed(request_token: int, message: String, retryable: bool)

var _client: HTTPClient
var _request_token := 0
var _cancelled := false


func start_request(
	url: String,
	headers: PackedStringArray,
	body: String,
	timeout_seconds: float,
	request_token: int
) -> Error:
	cancel()
	_request_token = request_token
	_cancelled = false
	_client = HTTPClient.new()
	var endpoint := _parse_url(url)
	if not bool(endpoint.get("ok", false)):
		return ERR_INVALID_PARAMETER
	var tls: TLSOptions = null
	if bool(endpoint.get("tls", false)):
		tls = TLSOptions.client()
	var connect_error := _client.connect_to_host(
		str(endpoint.get("host", "")), int(endpoint.get("port", -1)), tls
	)
	if connect_error != OK:
		return connect_error
	_run_request(endpoint, headers, body, maxf(1.0, timeout_seconds), request_token)
	return OK


func cancel() -> void:
	_cancelled = true
	_request_token += 1
	if _client != null:
		_client.close()
	_client = null


func _run_request(
	endpoint: Dictionary,
	headers: PackedStringArray,
	body: String,
	timeout_seconds: float,
	request_token: int
) -> void:
	var started_at := Time.get_ticks_msec()
	while _is_current(request_token) and _client.get_status() in [
		HTTPClient.STATUS_RESOLVING,
		HTTPClient.STATUS_CONNECTING
	]:
		var poll_error := _client.poll()
		if poll_error != OK:
			_fail_current(request_token, "Streaming connection failed (error %s)." % poll_error, true)
			return
		if _timed_out(started_at, timeout_seconds):
			_fail_current(request_token, "Streaming connection timed out.", true)
			return
		await get_tree().process_frame
	if not _is_current(request_token):
		return
	if _client.get_status() != HTTPClient.STATUS_CONNECTED:
		_fail_current(request_token, "Could not connect to the streaming endpoint.", true)
		return
	var request_error := _client.request(
		HTTPClient.METHOD_POST, str(endpoint.get("path", "/")), headers, body
	)
	if request_error != OK:
		_fail_current(request_token, "Could not start streaming request (error %s)." % request_error, true)
		return
	while _is_current(request_token) and _client.get_status() == HTTPClient.STATUS_REQUESTING:
		var poll_error := _client.poll()
		if poll_error != OK:
			_fail_current(request_token, "Streaming request failed (error %s)." % poll_error, true)
			return
		if _timed_out(started_at, timeout_seconds):
			_fail_current(request_token, "Streaming request timed out.", true)
			return
		await get_tree().process_frame
	if not _is_current(request_token):
		return
	var response_code := _client.get_response_code()
	var response_headers := _client.get_response_headers()
	stream_opened.emit(request_token, response_code, response_headers)
	while _is_current(request_token) and _client.get_status() == HTTPClient.STATUS_BODY:
		var chunk := _client.read_response_body_chunk()
		if not chunk.is_empty():
			body_chunk.emit(request_token, chunk)
			started_at = Time.get_ticks_msec()
		else:
			var poll_error := _client.poll()
			if poll_error != OK:
				_fail_current(request_token, "Streaming body failed (error %s)." % poll_error, true)
				return
			if _timed_out(started_at, timeout_seconds):
				_fail_current(request_token, "Streaming response timed out.", true)
				return
			await get_tree().process_frame
	if not _is_current(request_token):
		return
	if _client.get_status() not in [HTTPClient.STATUS_CONNECTED, HTTPClient.STATUS_DISCONNECTED]:
		_fail_current(request_token, "The streaming response ended unexpectedly.", true)
		return
	request_finished.emit(request_token, response_code, response_headers)


func _fail_current(request_token: int, message: String, retryable: bool) -> void:
	if not _is_current(request_token):
		return
	if _client != null:
		_client.close()
	request_failed.emit(request_token, message, retryable)


func _is_current(request_token: int) -> bool:
	return not _cancelled and request_token == _request_token and _client != null


func _timed_out(started_at: int, timeout_seconds: float) -> bool:
	return float(Time.get_ticks_msec() - started_at) / 1000.0 >= timeout_seconds


static func _parse_url(url: String) -> Dictionary:
	var clean := url.strip_edges()
	var tls := false
	if clean.begins_with("https://"):
		tls = true
		clean = clean.substr(8)
	elif clean.begins_with("http://"):
		clean = clean.substr(7)
	else:
		return {"ok": false}
	var slash := clean.find("/")
	var authority := clean if slash < 0 else clean.substr(0, slash)
	var path := "/" if slash < 0 else clean.substr(slash)
	var host := authority
	var port := 443 if tls else 80
	if authority.begins_with("["):
		var bracket := authority.find("]")
		if bracket < 0:
			return {"ok": false}
		host = authority.substr(1, bracket - 1)
		if bracket + 1 < authority.length() and authority.substr(bracket + 1, 1) == ":":
			port = int(authority.substr(bracket + 2))
	else:
		var colon := authority.rfind(":")
		if colon > 0 and authority.find(":") == colon:
			host = authority.substr(0, colon)
			port = int(authority.substr(colon + 1))
	if host.is_empty() or port <= 0:
		return {"ok": false}
	return {"ok": true, "host": host, "port": port, "path": path, "tls": tls}
