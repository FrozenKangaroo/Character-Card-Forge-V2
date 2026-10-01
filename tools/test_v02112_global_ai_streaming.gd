extends SceneTree

const DECODER = preload(
	"res://scripts/services/openai_stream_decoder_v02112.gd"
)
const STRUCTURED = preload(
	"res://scripts/services/incremental_json_stream_v02112.gd"
)
const GENERATION = preload(
	"res://scripts/services/generation_service_current.gd"
)

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_settings_persistence()
	_test_sse_reconstruction_and_completed_body()
	_test_structured_hostile_boundaries()
	_test_malformed_and_incomplete_streams()
	await _test_job_attempt_isolation_and_cancellation()
	_test_final_parser_and_provider_policy()
	if _failed:
		quit(1)
		return
	print("V02112_GLOBAL_AI_STREAMING_OK")
	quit(0)


func _test_settings_persistence() -> void:
	var settings := CCFSettingsService.default_settings()
	_require(
		not bool((settings.get("generation", {}) as Dictionary).get("stream_ai_responses", true)),
		"Streaming must default off for compatibility."
	)
	(settings["generation"] as Dictionary)["stream_ai_responses"] = true
	var saved := CCFSettingsService.save_settings(settings)
	var loaded := CCFSettingsService.load_settings()
	_require(
		bool(saved.get("ok", false))
		and bool((loaded.get("generation", {}) as Dictionary).get("stream_ai_responses", false)),
		"The global streaming preference must persist through the normal settings service."
	)
	var enabled_service := GENERATION.new()
	var enabled_queue: Dictionary = enabled_service.call(
		"_queue_chat_job",
		"test",
		"Streaming enabled",
		{"name": "Test", "base_url": "https://example.test/v1", "model": "model"},
		[{"role": "user", "content": "Test"}],
		"object",
		{},
		0
	)
	var enabled_jobs: Array = enabled_service.get("_queue")
	_require(
		bool(enabled_queue.get("ok", false))
		and bool((enabled_jobs[0] as Dictionary).get("stream_preferred_v02112", false)),
		"Queued text jobs must inherit the enabled global streaming preference."
	)
	enabled_service.free()
	(loaded["generation"] as Dictionary)["stream_ai_responses"] = false
	CCFSettingsService.save_settings(loaded)
	var disabled_service := GENERATION.new()
	disabled_service.call(
		"_queue_chat_job",
		"test",
		"Streaming disabled",
		{"name": "Test", "base_url": "https://example.test/v1", "model": "model"},
		[{"role": "user", "content": "Test"}],
		"object",
		{},
		0
	)
	var disabled_jobs: Array = disabled_service.get("_queue")
	_require(
		not bool((disabled_jobs[0] as Dictionary).get("stream_preferred_v02112", true)),
		"Streaming off must preserve the completed-response request path."
	)
	disabled_service.free()


func _test_sse_reconstruction_and_completed_body() -> void:
	var expected := (
		"[{\"title\":\"Ice { Station }\",\"concept\":\"An escaped \\\"quote\\\" "
		+ "and a slash \\\\ survive.\"},{\"title\":\"雪\",\"concept\":\"Unicode\"}]"
	)
	var pieces := [
		expected.substr(0, 7),
		expected.substr(7, 19),
		expected.substr(26, 31),
		expected.substr(57)
	]
	var wire := PackedByteArray()
	for piece in pieces:
		wire.append_array(
			("data: %s\n\n" % JSON.stringify({
				"choices": [{"delta": {"content": piece}, "finish_reason": null}]
			})).to_utf8_buffer()
		)
	wire.append_array(
		("data: %s\n\n" % JSON.stringify({
			"choices": [{"delta": {}, "finish_reason": "stop"}]
		})).to_utf8_buffer()
	)
	wire.append_array("data: [DONE]\n\n".to_utf8_buffer())
	var decoder := DECODER.new()
	var reconstructed := ""
	var cursor := 0
	var hostile_sizes := [1, 2, 7, 3, 11, 1, 5, 13]
	var size_index := 0
	while cursor < wire.size():
		var length := mini(hostile_sizes[size_index % hostile_sizes.size()], wire.size() - cursor)
		var decoded := decoder.feed_bytes(wire.slice(cursor, cursor + length))
		for delta in decoded.get("deltas", []):
			reconstructed += str(delta)
		cursor += length
		size_index += 1
	var tail := decoder.finish()
	for delta in tail.get("deltas", []):
		reconstructed += str(delta)
	_require(
		reconstructed == expected and decoder.done_received(),
		"Hostile network chunk boundaries must reconstruct assistant text exactly."
	)

	var ordinary_text := JSON.stringify({
		"choices": [{"message": {"content": "ordinary completed response"}}]
	})
	var ordinary := DECODER.new()
	ordinary.feed_bytes(ordinary_text.to_utf8_buffer())
	ordinary.finish()
	_require(
		not ordinary.saw_sse_event() and ordinary.raw_text() == ordinary_text,
		"An endpoint that ignores stream=true must retain its ordinary response body exactly."
	)


func _test_structured_hostile_boundaries() -> void:
	var source := (
		"[{\"title\":\"First\",\"concept\":\"A comma, brace } and escaped \\\"quote\\\"\","
		+ "\"nested\":{\"list\":[1,{\"value\":\"x\\\\y\"}]}},"
		+ "{\"title\":\"Second\",\"concept\":\"雪 station\"}]"
	)
	var parser := STRUCTURED.new()
	var items: Array = []
	var first_emitted_at := -1
	for index in range(source.length()):
		var units := parser.feed(source.substr(index, 1))
		for item in units.get("items", []):
			items.append(item)
			if first_emitted_at < 0:
				first_emitted_at = index
	_require(
		items.size() == 2
		and str((items[0] as Dictionary).get("title", "")) == "First"
		and str((items[1] as Dictionary).get("title", "")) == "Second"
		and first_emitted_at < source.length() - 1,
		"A JSON array must emit only complete members and may emit the first before the root closes."
	)

	var incomplete := STRUCTURED.new()
	var incomplete_units := incomplete.feed("[{\"title\":\"Half written")
	_require(
		(incomplete_units.get("items", []) as Array).is_empty(),
		"An incomplete Idea object must never be surfaced provisionally."
	)

	var object_parser := STRUCTURED.new()
	var object_source := (
		"{\"name\":\"Rika\",\"personality\":\"Energetic, but {careful}\","
		+ "\"details\":{\"likes\":[\"tea\",\"snow\"]}}"
	)
	var fields: Array = []
	for split in ["{\"na", "me\":\"Rika\",\"person", "ality\":\"Energetic, but {care", "ful}\",", "\"details\":{\"likes\":[\"tea\",\"snow\"]}}"]:
		var units := object_parser.feed(split)
		fields.append_array(units.get("fields", []))
	_require(
		fields.size() == 3
		and str((fields[0] as Dictionary).get("name", "")) == "name"
		and str((fields[1] as Dictionary).get("name", "")) == "personality"
		and (fields[2] as Dictionary).get("value") is Dictionary,
		"Completed object fields must survive nested content and arbitrary chunk splits."
	)


func _test_malformed_and_incomplete_streams() -> void:
	var malformed := DECODER.new()
	var result := malformed.feed_bytes("data: {not valid json}\n\n".to_utf8_buffer())
	_require(
		not str(result.get("error", "")).is_empty(),
		"Malformed provider events must produce a clean protocol error."
	)
	var ended := DECODER.new()
	ended.feed_bytes(("data: %s\n\n" % JSON.stringify({
		"choices": [{"delta": {"content": "partial"}, "finish_reason": null}]
	})).to_utf8_buffer())
	ended.finish()
	_require(
		ended.saw_sse_event() and not ended.done_received(),
		"Unexpected stream termination must remain distinguishable from normal completion."
	)


func _test_job_attempt_isolation_and_cancellation() -> void:
	var service := GENERATION.new()
	root.add_child(service)
	await process_frame
	var reset_events: Array = []
	var cancelled_events: Array = []
	var delta_events: Array = []
	var item_events: Array = []
	service.job_stream_reset.connect(func(job_id: String, _job_type: String, metadata: Dictionary) -> void:
		reset_events.append({"job_id": job_id, "reason": metadata.get("reason", "")})
	)
	service.job_cancelled.connect(func(job_id: String, _job_type: String) -> void:
		cancelled_events.append(job_id)
	)
	service.job_stream_delta.connect(func(job_id: String, _job_type: String, delta: String, _metadata: Dictionary) -> void:
		delta_events.append({"job_id": job_id, "delta": delta})
	)
	service.job_stream_item.connect(func(job_id: String, _job_type: String, item: Variant, _metadata: Dictionary) -> void:
		item_events.append({"job_id": job_id, "item": item})
	)
	service.set("_active_job", {
		"id": "job_units", "type": "ideas", "attempt": 1, "parse_mode": "ideas",
		"stream_request_token_v02112": 8,
		"stream_attempt_open_v02112": true,
		"stream_provisional_emitted_v02112": false,
		"stream_content_v02112": ""
	})
	service.call("_emit_stream_deltas_v02112", ["[{\"title\":\"One\""])
	_require(item_events.is_empty(), "A fragmented Idea must not emit a provisional job item.")
	service.call("_emit_stream_deltas_v02112", [",\"concept\":\"Complete\"}]"])
	var unit_job: Dictionary = service.get("_active_job")
	_require(
		delta_events.size() == 2
		and item_events.size() == 1
		and str((item_events[0] as Dictionary).get("job_id", "")) == "job_units"
		and str(unit_job.get("stream_content_v02112", "")) == "[{\"title\":\"One\",\"concept\":\"Complete\"}]",
		"Provider-independent job events must reconstruct one response and emit only its complete Idea."
	)
	service.call("_reset_stream_attempt_v02112", "test_complete")
	service.set("_active_job", {
		"id": "job_cancel", "type": "ideas", "attempt": 1,
		"stream_request_token_v02112": 12,
		"stream_attempt_open_v02112": true,
		"stream_provisional_emitted_v02112": true,
		"stream_content_v02112": "partial"
	})
	_require(
		bool(service.call("_stream_event_is_current_v02112", 12))
		and not bool(service.call("_stream_event_is_current_v02112", 11)),
		"Only the current request token may mutate a streaming job."
	)
	service.cancel_active_job()
	_require(
		reset_events.size() == 2
		and str((reset_events[-1] as Dictionary).get("reason", "")) == "cancelled"
		and cancelled_events == ["job_cancel"]
		and not service.has_active_job(),
		"Cancellation must discard provisional output and emit the normal cancelled lifecycle."
	)

	service.set("_active_job", {
		"id": "job_retry", "type": "character", "attempt": 2,
		"stream_request_token_v02112": 22,
		"stream_attempt_open_v02112": true,
		"stream_provisional_emitted_v02112": true,
		"stream_content_v02112": "failed partial"
	})
	service.call("_reset_stream_attempt_v02112", "retry")
	var retry_job: Dictionary = service.get("_active_job")
	_require(
		str(retry_job.get("stream_content_v02112", "x")).is_empty()
		and not bool(retry_job.get("stream_provisional_emitted_v02112", true)),
		"A retry must clear the failed attempt's provisional buffer."
	)
	service.set("_active_job", {
		"id": "job_new", "type": "ideas", "attempt": 1,
		"stream_request_token_v02112": 31,
		"stream_attempt_open_v02112": true
	})
	_require(
		not bool(service.call("_stream_event_is_current_v02112", 22))
		and bool(service.call("_stream_event_is_current_v02112", 31)),
		"Delayed events from an old job or attempt must not contaminate the current job."
	)
	service.set("_active_job", {})
	service.queue_free()


func _test_final_parser_and_provider_policy() -> void:
	var service := GENERATION.new()
	var final_result: Dictionary = service.call(
		"_parse_job_output_with_diagnostics",
		"[{\"title\":\"Final\",\"concept\":\"Validated through the established parser\"}]",
		"ideas"
	)
	_require(
		bool(final_result.get("ok", false))
		and (final_result.get("data", []) as Array).size() == 1,
		"Streamed content must still pass through the established final parser."
	)
	_require(
		bool(service.call(
			"_endpoint_can_stream_v02112",
			"https://example.test/v1/chat/completions",
			{}
		))
		and not bool(service.call(
			"_endpoint_can_stream_v02112",
			"https://example.test/v1/chat/completions",
			{"streaming_supported": false}
		))
		and not bool(service.call(
			"_endpoint_can_stream_v02112", "file:///not-http", {}
		)),
		"Provider capability policy must permit compatible endpoints and honor an explicit opt-out."
	)
	service.free()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
