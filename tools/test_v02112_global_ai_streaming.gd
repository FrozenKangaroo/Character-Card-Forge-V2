extends SceneTree

const DECODER = preload(
	"res://scripts/services/openai_stream_decoder_v02112.gd"
)
const STRUCTURED = preload(
	"res://scripts/services/incremental_json_stream_v02112.gd"
)
const CLASSIFIER = preload(
	"res://scripts/services/stream_content_classifier_v02112.gd"
)
const GENERATION = preload(
	"res://scripts/services/generation_service_current.gd"
)
const DIVERSITY = preload(
	"res://scripts/services/idea_diversity_guardrails_v0214.gd"
)
const BATCHING = preload(
	"res://scripts/services/idea_generator_batching_v0211.gd"
)
const IDEA_WINDOW = preload(
	"res://scripts/ui/idea_generator_window_current.gd"
)

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_settings_persistence()
	_test_sse_reconstruction_and_completed_body()
	_test_reasoning_separation()
	_test_structured_hostile_boundaries()
	_test_malformed_and_incomplete_streams()
	await _test_job_attempt_isolation_and_cancellation()
	await _test_fast_path_and_optional_comparison()
	await _test_provisional_idea_scrolling_and_resets()
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


func _test_reasoning_separation() -> void:
	var decoder := DECODER.new()
	var reasoning_event := "data: %s\n\n" % JSON.stringify({
		"choices": [{
			"delta": {
				"reasoning_content": "private reasoning with [{\"title\":\"False Idea\"}]"
			},
			"finish_reason": null
		}]
	})
	var decoded := decoder.feed_bytes(reasoning_event.to_utf8_buffer())
	_require(
		bool(decoded.get("reasoning_detected", false))
		and (decoded.get("deltas", []) as Array).is_empty(),
		"Dedicated provider reasoning must be detected without becoming final content."
	)
	var block_decoder := DECODER.new()
	var block_event := "data: %s\n\n" % JSON.stringify({
		"choices": [{
			"delta": {"content": [
				{"type": "thinking", "text": "private"},
				{"type": "output_text", "text": "final"}
			]},
			"finish_reason": null
		}]
	})
	var block_result := block_decoder.feed_bytes(block_event.to_utf8_buffer())
	_require(
		bool(block_result.get("reasoning_detected", false))
		and block_result.get("deltas", []) == ["final"],
		"Reasoning content blocks must be suppressed while final text blocks remain."
	)

	var classifier := CLASSIFIER.new()
	var final_text := ""
	var reasoning_seen := false
	for piece in [
		"  <thi",
		"nk>Planning [{\"title\":\"Reasoning Idea\",\"concept\":\"Never show\"}]",
		"</thi",
		"nk>\n[{\"title\":\"Final Idea\",\"concept\":\"Safe final\"}]"
	]:
		var classified := classifier.feed_content(piece)
		reasoning_seen = reasoning_seen or bool(classified.get("reasoning_detected", false))
		for final_delta in classified.get("final_deltas", []):
			final_text += str(final_delta)
	var finish_result := classifier.finish()
	for final_delta in finish_result.get("final_deltas", []):
		final_text += str(final_delta)
	var parser := STRUCTURED.new()
	var units := parser.feed(final_text)
	_require(
		reasoning_seen
		and not final_text.contains("Reasoning Idea")
		and (units.get("items", []) as Array).size() == 1
		and str(((units.get("items", []) as Array)[0] as Dictionary).get("title", ""))
		== "Final Idea",
		"A reasoning tag split across arbitrary chunks must not leak valid-looking reasoning JSON into provisional Ideas."
	)

	var literal_classifier := CLASSIFIER.new()
	var literal := "[{\"title\":\"Literal\",\"concept\":\"Mentions <think> as text\"}]"
	var literal_result := literal_classifier.feed_content(literal)
	_require(
		literal_result.get("final_deltas", []) == [literal],
		"Tag heuristics must not strip tag-like text after the final JSON answer has begun."
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


func _test_fast_path_and_optional_comparison() -> void:
	var service := GENERATION.new()
	root.add_child(service)
	await process_frame
	var completions: Array = []
	service.job_completed.connect(func(
		_job_id: String, _job_type: String, data: Variant, metadata: Dictionary
	) -> void:
		completions.append({"data": data, "metadata": metadata})
	)
	service.set("_active_job", {
		"id": "fast_ideas",
		"type": "ideas",
		"attempt": 1,
		"repair_attempts": 0,
		"model": "fake",
		"profile_name": "fake",
		"metadata": {"idea_fast_path_v02112": true}
	})
	service.call(
		"_process_completed_content",
		"[{\"title\":\"Fast\",\"concept\":\"Structurally usable immediately\"}]"
	)
	_require(
		completions.size() == 1
		and bool((completions[0] as Dictionary).get("metadata", {}).get(
			"idea_fast_path_used_v02112", false
		))
		and int((completions[0] as Dictionary).get("metadata", {}).get(
			"semantic_repair_attempts", -1
		)) == 0
		and not service.has_active_job(),
		"All-options-off Idea JSON must complete directly without semantic repair or another AI job."
	)
	service.queue_free()

	var duplicate_idea := {
		"title": "Same title",
		"character_name": "Rika",
		"concept": "Rika finds the same locked room twice."
	}
	var fast_session := DIVERSITY.create_session(2, 2, false, "off", false, {})
	fast_session["final_review_check_adherence"] = false
	fast_session["final_review_check_similarity"] = false
	var fast_result := DIVERSITY.record_batch(
		fast_session, [duplicate_idea, duplicate_idea], [], "normal"
	)
	var fast_records: Array = fast_session.get("accepted", [])
	_require(
		int(fast_result.get("accepted_count", 0)) == 2
		and (fast_records[0] as Dictionary).get("structural_tokens", []) == []
		and str((fast_records[0] as Dictionary).get("fingerprint", "")).is_empty(),
		"When every optional check is off, local fingerprints, tokens, and duplicate comparisons must be skipped."
	)
	var guarded_session := DIVERSITY.create_session(2, 2, true, "off", false, {})
	var guarded_result := DIVERSITY.record_batch(
		guarded_session, [duplicate_idea, duplicate_idea], [], "normal"
	)
	_require(
		int(guarded_result.get("accepted_count", 0)) == 1
		and int(guarded_result.get("rejected_count", 0)) == 1,
		"Prevent Repeats must retain its existing duplicate rejection behavior."
	)
	_require(
		BATCHING.request_plan(20, 12) == [12, 8],
		">12 Ideas must retain sequential 12-plus-remainder batching."
	)


func _test_provisional_idea_scrolling_and_resets() -> void:
	var window := IDEA_WINDOW.new()
	window.size = Vector2i(1000, 760)
	root.add_child(window)
	window.show()
	await process_frame
	await process_frame
	var scroll := window.find_child("ProvisionalIdeasScrollV02112", true, false) as ScrollContainer
	var list := window.find_child("ProvisionalIdeasListV02112", true, false) as VBoxContainer
	_require(
		scroll != null and list != null and list.get_parent() == scroll,
		"Provisional Ideas must live inside a bounded ScrollContainer."
	)
	window.call("begin_provisional_ideas_v02112", "batch_1", {
		"idea_batch_group_id": "group",
		"idea_batch_index": 0,
		"idea_batch_request_count": 2,
		"idea_batch_request_size": 12
	})
	for index in range(13):
		window.call("append_provisional_idea_v02112", "batch_1", {
			"title": "Idea %d" % (index + 1),
			"concept": "A deliberately long provisional concept %d that ensures the scroll region contains more content than its visible page." % (index + 1)
		})
	await process_frame
	await process_frame
	var bar := scroll.get_v_scroll_bar()
	scroll.scroll_vertical = int(bar.max_value)
	await process_frame
	_require(
		bool(window.call("provisional_should_follow_v02112")),
		"Provisional output should follow new Ideas while the user is already near the bottom."
	)
	scroll.scroll_vertical = 0
	await process_frame
	_require(
		bar.max_value <= bar.page
		or not bool(window.call("provisional_should_follow_v02112")),
		"Provisional output must not yank a user who deliberately scrolled upward."
	)
	window.call("discard_provisional_attempt_v02112", "batch_1", "retry", {})
	await process_frame
	var notice := window.find_child("ProvisionalIdeasNoticeV02112", true, false) as Label
	_require(
		notice != null
		and notice.visible
		and notice.text.contains("retrying")
		and notice.text.contains("discarded"),
		"Retry/reset must clear abandoned provisional cards and explain why."
	)
	window.call("discard_provisional_attempt_v02112", "batch_1", "provider_unsupported", {})
	_require(
		notice.text.contains("continuing normally"),
		"Transport fallback must remain visible instead of silently clearing provisional output."
	)
	window.hide()
	window.queue_free()


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
