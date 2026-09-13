class_name CCFRemoteReferenceFetchServiceV0194
extends Node

const MAX_REDIRECTS := 4
const REQUEST_TIMEOUT_SECONDS := 20.0

var _request: HTTPRequest
var _busy := false


func _ready() -> void:
	_request = HTTPRequest.new()
	_request.body_size_limit = CCFReferenceIngestionServiceV0194.MAX_REMOTE_BYTES + 1
	_request.download_chunk_size = 64 * 1024
	_request.max_redirects = 0
	_request.timeout = REQUEST_TIMEOUT_SECONDS
	_request.use_threads = true
	add_child(_request)


func is_busy() -> bool:
	return _busy


func cancel() -> void:
	if _request != null:
		_request.cancel_request()
	_busy = false


func fetch_preview(source_url: String) -> Dictionary:
	if _busy:
		return {"ok": false, "error": "Another remote reference is already being inspected."}
	var validated := CCFReferenceIngestionServiceV0194.validate_https_url(source_url)
	if not bool(validated.get("ok", false)):
		return validated
	_busy = true
	var current_url := str(validated.get("url", ""))
	var redirect_count := 0
	while redirect_count <= MAX_REDIRECTS:
		var response := await _request_once(current_url)
		if not bool(response.get("ok", false)):
			_busy = false
			return response
		var response_code := int(response.get("response_code", 0))
		var headers: PackedStringArray = response.get("headers", PackedStringArray())
		if response_code in [301, 302, 303, 307, 308]:
			if redirect_count >= MAX_REDIRECTS:
				_busy = false
				return {"ok": false, "error": "The remote reference exceeded the four-redirect limit."}
			var location := header_value(headers, "location")
			var redirected := CCFReferenceIngestionServiceV0194.resolve_redirect_url(
				current_url, location
			)
			if not bool(redirected.get("ok", false)):
				_busy = false
				return redirected
			current_url = str(redirected.get("url", ""))
			redirect_count += 1
			continue
		if response_code < 200 or response_code >= 300:
			_busy = false
			return {
				"ok": false,
				"error": "The remote source returned HTTP %d." % response_code,
				"response_code": response_code
			}
		var content_length := header_value(headers, "content-length").to_int()
		if content_length > CCFReferenceIngestionServiceV0194.MAX_REMOTE_BYTES:
			_busy = false
			return {"ok": false, "error": "The remote reference exceeds the 16 MB download limit."}
		var body: PackedByteArray = response.get("body", PackedByteArray())
		var content_type := header_value(headers, "content-type")
		var filename := suggested_filename(current_url, headers, content_type)
		var inspection := CCFReferenceIngestionServiceV0194.inspect_download(
			body, content_type, filename
		)
		_busy = false
		if not bool(inspection.get("ok", false)):
			return inspection
		inspection["body"] = body
		inspection["source_url"] = str(validated.get("url", ""))
		inspection["final_url"] = current_url
		inspection["redirect_count"] = redirect_count
		inspection["fetched_at"] = Time.get_datetime_string_from_system(true)
		inspection["sha256"] = _sha256_text(body)
		return inspection
	_busy = false
	return {"ok": false, "error": "The remote reference could not be inspected."}


func _request_once(url: String) -> Dictionary:
	_request.cancel_request()
	var request_error := _request.request(
		url,
		PackedStringArray([
			"Accept: application/pdf, text/plain, text/markdown, text/html, application/json, image/png, image/jpeg, image/webp",
			"User-Agent: Character-Card-Forge/%s" % str(
				ProjectSettings.get_setting("application/config/version", "development")
			)
		]),
		HTTPClient.METHOD_GET
	)
	if request_error != OK:
		return {"ok": false, "error": "The HTTPS request could not be started."}
	var completed: Array = await _request.request_completed
	if completed.size() < 4:
		return {"ok": false, "error": "The HTTPS request ended without a complete response."}
	var network_result := int(completed[0])
	if network_result != HTTPRequest.RESULT_SUCCESS:
		return {
			"ok": false,
			"error": _network_error(network_result),
			"network_result": network_result
		}
	return {
		"ok": true,
		"response_code": int(completed[1]),
		"headers": completed[2] as PackedStringArray,
		"body": completed[3] as PackedByteArray
	}


static func header_value(headers: PackedStringArray, wanted_name: String) -> String:
	var prefix := wanted_name.to_lower() + ":"
	for header in headers:
		var header_text := str(header)
		if header_text.to_lower().begins_with(prefix):
			return header_text.substr(header_text.find(":") + 1).strip_edges()
	return ""


static func suggested_filename(
	final_url: String, headers: PackedStringArray, content_type: String
) -> String:
	var disposition := header_value(headers, "content-disposition")
	var filename_regex := RegEx.new()
	filename_regex.compile("(?i)filename\\*?=(?:UTF-8''|\")?([^\";]+)")
	var filename_match := filename_regex.search(disposition)
	if filename_match != null:
		var header_filename := filename_match.get_string(1).strip_edges().uri_decode()
		if not header_filename.is_empty():
			return header_filename.get_file()
	var clean_url := final_url.split("#", false, 1)[0].split("?", false, 1)[0]
	var url_filename := clean_url.get_file().uri_decode()
	if not url_filename.is_empty() and url_filename.contains("."):
		return url_filename
	var clean_type := content_type.split(";", false, 1)[0].to_lower()
	match clean_type:
		"application/pdf": return "remote-reference.pdf"
		"application/json": return "remote-reference.json"
		"text/html", "application/xhtml+xml": return "remote-reference.html"
		"text/markdown": return "remote-reference.md"
		"image/png": return "remote-reference.png"
		"image/jpeg": return "remote-reference.jpg"
		"image/webp": return "remote-reference.webp"
		_: return "remote-reference.txt"


static func _network_error(network_result: int) -> String:
	match network_result:
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "The remote host name could not be resolved."
		HTTPRequest.RESULT_CANT_CONNECT:
			return "The remote host could not be reached."
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "The HTTPS certificate or TLS handshake could not be verified."
		HTTPRequest.RESULT_TIMEOUT:
			return "The remote reference request timed out after 20 seconds."
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "The remote reference exceeded the 16 MB download limit."
		_:
			return "The remote reference request failed before a valid response was received."


static func _sha256_text(body: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(body)
	return context.finish().hex_encode()
