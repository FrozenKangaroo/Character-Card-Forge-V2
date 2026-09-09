class_name CCFGenerationServiceV0180Hotfix1
extends "res://scripts/services/generation_service_v0175.gd"

const SAFE_TEXT_RECOVERY_VERSION_V0180_HOTFIX1 := 1
const TEXT_FIELD_TYPES_V0180_HOTFIX1 := [
	"", "line", "multiline", "string", "text", "textarea"
]


func safe_text_recovery_capabilities_v0180_hotfix1() -> Dictionary:
	return {
		"version": "0.18.0-hotfix1",
		"recovery_version": SAFE_TEXT_RECOVERY_VERSION_V0180_HOTFIX1,
		"standalone_plain_text_wrapper": true,
		"json_string_wrapper": true,
		"focused_text_repair_wrapper": true,
		"component_text_repair_wrapper": true,
		"exact_remote_repair_schema": true,
		"conservative_unterminated_string_repair": true,
		"typed_fields_remain_strict": true,
		"semantic_validation_retained": true,
		"contamination_guard_retained": true
	}


func create_parallel_child_service_v0180_hotfix1() -> CCFGenerationServiceV0180Hotfix1:
	return CCFGenerationServiceV0180Hotfix1.new()


func _fill_parallel_wave_v01526() -> void:
	# v0.15.37's contamination guard intentionally creates typed child services,
	# so the hotfix must keep that exact wiring while upgrading each child to the
	# recovery-aware class. Otherwise only sequential builds would receive it.
	var wave_value: Variant = _parallel_coordinator_v01526.get(
		"wave_indices", []
	)
	var wave: Array = wave_value if wave_value is Array else []
	var cursor := int(_parallel_coordinator_v01526.get("wave_cursor", 0))
	var running_value: Variant = _parallel_coordinator_v01526.get("running", {})
	var running: Dictionary = (
		running_value if running_value is Dictionary else {}
	)
	var config := (
		_scheduler_v01526.config() if _scheduler_v01526 != null else {}
	)
	var per_character_limit := maxi(
		1, int(config.get("max_sections_per_character", 1))
	)
	while cursor < wave.size() and running.size() < per_character_limit:
		var section_index := int(wave[cursor])
		cursor += 1
		var child := create_parallel_child_service_v0180_hotfix1()
		var child_id := "%s:section:%03d:%03d" % [
			_scheduler_worker_id_v01526,
			section_index,
			_parallel_child_serial_v01526
		]
		_parallel_child_serial_v01526 += 1
		add_child(child)
		child.configure_scheduler_v01526(
			_scheduler_v01526,
			child_id,
			"Safe Section",
			700000 + _parallel_child_serial_v01526 * 100,
			str(_active_job.get("id", "character"))
		)
		child.parallel_safe_section_completed.connect(
			_on_parallel_section_completed_v01526
		)
		child.job_failed.connect(
			_on_parallel_section_failed_v01526.bind(child_id)
		)
		child.job_cancelled.connect(
			_on_parallel_section_cancelled_v01526.bind(child_id)
		)
		child.diagnostics_available.connect(
			_on_parallel_child_diagnostics_v01526
		)
		var snapshot := _dictionary_copy_v01522(
			_parallel_coordinator_v01526.get("wave_snapshot", {})
		)
		var plan_value: Variant = snapshot.get("plan", [])
		var plan: Array = plan_value if plan_value is Array else []
		if (
			section_index < 0
			or section_index >= plan.size()
			or not plan[section_index] is Dictionary
		):
			child.queue_free()
			_parallel_coordinator_v01526["failed"] = true
			_handle_failure(
				"Parallel Safe Section Build encountered an invalid section plan.",
				false
			)
			return
		var section: Dictionary = plan[section_index]
		var result := child.queue_parallel_safe_section_v01526(
			_active_job.duplicate(true), snapshot, section, section_index
		)
		if not bool(result.get("ok", false)):
			child.queue_free()
			_parallel_coordinator_v01526["failed"] = true
			_handle_failure(
				str(result.get("error", "Could not start parallel section.")),
				false
			)
			return
		running[child_id] = {
			"service": child, "section_index": section_index
		}
	_parallel_coordinator_v01526["wave_cursor"] = cursor
	_parallel_coordinator_v01526["running"] = running
	_emit_queue_changed()


func _process_safe_section_v01522(content: String) -> void:
	var parse_result := _parse_job_output_with_diagnostics(content, "object")
	if bool(parse_result.get("ok", false)):
		super._process_safe_section_v01522(content)
		return
	var section := _dictionary_copy_v01522(
		_active_job.get("safe_active_section", {})
	)
	var recovered := recover_safe_text_candidate_v0180_hotfix1(
		section, content
	)
	if not bool(recovered.get("ok", false)):
		super._process_safe_section_v01522(content)
		return
	var field_id := str(section.get("field_id", "field"))
	_record_local_text_recovery_v0180_hotfix1(
		section,
		str(recovered.get("source", "plain_text")),
		str(recovered.get("value", ""))
	)
	# Route the locally wrapped value through the existing exact-key, semantic,
	# content and cross-field contamination guards. Recovery changes transport
	# shape only; it does not bypass acceptance policy.
	_process_safe_field_result_v01522(
		section, {field_id: str(recovered.get("value", ""))}
	)


func _process_safe_field_repair_v01522(content: String) -> void:
	var parse_result := _parse_job_output_with_diagnostics(content, "field")
	if bool(parse_result.get("ok", false)):
		super._process_safe_field_repair_v01522(content)
		return
	var section := _dictionary_copy_v01522(
		_active_job.get("safe_active_section", {})
	)
	var recovered := recover_safe_text_candidate_v0180_hotfix1(
		section, content
	)
	if not bool(recovered.get("ok", false)):
		super._process_safe_field_repair_v01522(content)
		return
	_record_local_text_recovery_v0180_hotfix1(
		section,
		"focused_%s" % str(recovered.get("source", "plain_text")),
		str(recovered.get("value", ""))
	)
	super._process_safe_field_repair_v01522(
		JSON.stringify({"value": str(recovered.get("value", ""))})
	)


func _process_safe_component_repair_v01522(content: String) -> void:
	var parse_result := _parse_job_output_with_diagnostics(content, "field")
	if bool(parse_result.get("ok", false)):
		super._process_safe_component_repair_v01522(content)
		return
	var recovered := _plain_text_value_v0180_hotfix1(content)
	if not bool(recovered.get("ok", false)):
		super._process_safe_component_repair_v01522(content)
		return
	var section := _dictionary_copy_v01522(
		_active_job.get("safe_active_section", {})
	)
	_record_local_text_recovery_v0180_hotfix1(
		section,
		"component_%s" % str(recovered.get("source", "plain_text")),
		str(recovered.get("value", ""))
	)
	super._process_safe_component_repair_v01522(
		JSON.stringify({"value": str(recovered.get("value", ""))})
	)


func recover_safe_text_candidate_v0180_hotfix1(
	section: Dictionary, content: String
) -> Dictionary:
	if str(section.get("kind", "standalone_field")) != "standalone_field":
		return {"ok": false, "reason": "Only standalone fields can be mapped without guessing."}
	var field := _dictionary_copy_v01522(section.get("field", {}))
	var field_type := str(field.get("type", "multiline")).to_lower()
	if not field_type in TEXT_FIELD_TYPES_V0180_HOTFIX1:
		return {
			"ok": false,
			"reason": "Typed field `%s` still requires valid JSON." % field_type
		}
	return _plain_text_value_v0180_hotfix1(content)


func _plain_text_value_v0180_hotfix1(content: String) -> Dictionary:
	var cleaned := content.strip_edges()
	if cleaned.is_empty():
		return {"ok": false, "reason": "Empty text cannot be recovered."}
	if cleaned.begins_with("```"):
		var first_newline := cleaned.find("\n")
		if first_newline < 0 or not cleaned.ends_with("```"):
			return {"ok": false, "reason": "Incomplete fenced output requires normal repair."}
		cleaned = cleaned.substr(
			first_newline + 1,
			cleaned.length() - first_newline - 4
		).strip_edges()
		if cleaned.is_empty():
			return {"ok": false, "reason": "Empty fenced text cannot be recovered."}
	var parser := JSON.new()
	if parser.parse(cleaned) == OK:
		var parsed_value: Variant = parser.data
		if parsed_value is String and not str(parsed_value).strip_edges().is_empty():
			return {
				"ok": true,
				"value": str(parsed_value).strip_edges(),
				"source": "json_string"
			}
		return {
			"ok": false,
			"reason": "Valid non-string JSON must retain its declared structure."
		}
	# Do not reinterpret a malformed object or array as authored prose. Those
	# shapes continue through bounded JSON repair with an exact schema.
	if (
		(cleaned.begins_with("{") and not cleaned.begins_with("{{"))
		or cleaned.begins_with("[")
	):
		return {
			"ok": false,
			"reason": "JSON-shaped output requires structural repair."
		}
	return {"ok": true, "value": cleaned, "source": "plain_text"}


func _repair_common_json(text: String) -> String:
	var repaired := super._repair_common_json(text)
	var parser := JSON.new()
	if parser.parse(repaired) == OK:
		return repaired
	var candidate := _close_unterminated_root_string_v0180_hotfix1(repaired)
	if candidate != repaired and parser.parse(candidate) == OK:
		return candidate
	return repaired


func _close_unterminated_root_string_v0180_hotfix1(text: String) -> String:
	var cleaned := text.strip_edges()
	if cleaned.is_empty() or not (
		cleaned.begins_with("{") or cleaned.begins_with("[")
	):
		return text
	var closing_stack: Array[String] = []
	var in_string := false
	var escaped := false
	for index in range(cleaned.length()):
		var character := cleaned[index]
		if in_string:
			if escaped:
				escaped = false
			elif character == "\\":
				escaped = true
			elif character == '"':
				in_string = false
			continue
		if character == '"':
			in_string = true
		elif character == "{":
			closing_stack.append("}")
		elif character == "[":
			closing_stack.append("]")
		elif character == "}" or character == "]":
			if closing_stack.is_empty() or closing_stack[-1] != character:
				return text
			closing_stack.pop_back()
	if not in_string:
		return text
	var trailing_start := cleaned.length()
	while trailing_start > 0 and (
		cleaned[trailing_start - 1] == "}"
		or cleaned[trailing_start - 1] == "]"
	):
		trailing_start -= 1
	var with_inserted_quote := (
		cleaned.substr(0, trailing_start)
		+ '"'
		+ cleaned.substr(trailing_start)
	)
	var parser := JSON.new()
	if parser.parse(with_inserted_quote) == OK:
		return with_inserted_quote
	var with_completed_tail := cleaned + '"'
	for index in range(closing_stack.size() - 1, -1, -1):
		with_completed_tail += closing_stack[index]
	if parser.parse(with_completed_tail) == OK:
		return with_completed_tail
	return text


func _start_json_repair(
	malformed_content: String, parse_mode: String
) -> bool:
	var started := super._start_json_repair(malformed_content, parse_mode)
	if not started or _active_job.is_empty():
		return started
	var exact_shape := _exact_safe_repair_shape_v0180_hotfix1(parse_mode)
	if exact_shape.is_empty():
		return started
	var payload := _dictionary_copy_v01522(_active_job.get("payload", {}))
	var messages_value: Variant = payload.get("messages", [])
	if not messages_value is Array or messages_value.size() < 2:
		return started
	var messages: Array = messages_value.duplicate(true)
	var user_message: Dictionary = (
		messages[1].duplicate(true) if messages[1] is Dictionary else {}
	)
	user_message["content"] = (
		"EXPECTED STRUCTURE: %s\n\nOUTPUT TO REPAIR:\n%s"
		% [exact_shape, malformed_content]
	)
	messages[1] = user_message
	payload["messages"] = messages
	_active_job["payload"] = payload
	_update_latest_repair_diagnostic_v0180_hotfix1(
		malformed_content, payload, exact_shape
	)
	return started


func _exact_safe_repair_shape_v0180_hotfix1(
	parse_mode: String
) -> String:
	var stage := str(_active_job.get("safe_stage", ""))
	if not stage in ["section", "field_repair", "component_repair"]:
		return ""
	var section := _dictionary_copy_v01522(
		_active_job.get("safe_active_section", {})
	)
	if stage == "field_repair" and parse_mode == "field":
		var field := _dictionary_copy_v01522(section.get("field", {}))
		return (
			'one JSON object with exactly the key "value"; its value must be replacement %s'
			% _field_type_instruction(field)
		)
	if stage == "component_repair" and parse_mode == "field":
		return (
			'one JSON object with exactly the key "value"; its value must be complete replacement text'
		)
	if stage != "section" or parse_mode != "object":
		return ""
	if str(section.get("kind", "standalone_field")) == "standalone_field":
		var field := _dictionary_copy_v01522(section.get("field", {}))
		var field_id := str(section.get("field_id", field.get("id", "field")))
		return 'one JSON object with exactly the key "%s"; its value must be %s' % [
			field_id, _field_type_instruction(field)
		]
	var group := _dictionary_copy_v01522(section.get("group", {}))
	var component_ids: Array[String] = []
	for raw_component in group.get("components", []):
		if raw_component is Dictionary and bool(raw_component.get("enabled", true)):
			component_ids.append(str(raw_component.get("id", "component")))
	if component_ids.is_empty():
		return ""
	var quoted_ids: Array[String] = []
	for component_id in component_ids:
		quoted_ids.append('"%s"' % component_id)
	return (
		"one JSON object with exactly these text-valued component keys: %s"
		% ", ".join(quoted_ids)
	)


func _record_local_text_recovery_v0180_hotfix1(
	section: Dictionary, source: String, value: String
) -> void:
	var record := {
		"kind": "local_safe_text_wrapper",
		"version": SAFE_TEXT_RECOVERY_VERSION_V0180_HOTFIX1,
		"section": str(section.get("title", section.get("field_id", "Field"))),
		"field_id": str(section.get("field_id", "")),
		"source": source,
		"character_count": value.length(),
		"content_fingerprint": _content_fingerprint_v01537_hotfix1(value),
		"validation_boundary": "existing_semantic_and_contamination_guards"
	}
	var recoveries: Array = _array_copy_v01522(
		_active_job.get("safe_text_recoveries_v0180_hotfix1", [])
	)
	recoveries.append(record.duplicate(true))
	_active_job["safe_text_recoveries_v0180_hotfix1"] = recoveries
	var metadata := _dictionary_copy_v01522(_active_job.get("metadata", {}))
	metadata["safe_text_recoveries_v0180_hotfix1"] = recoveries.duplicate(true)
	_active_job["metadata"] = metadata
	_append_diagnostic_event_v01522("local_text_recovery", record)


func _update_latest_repair_diagnostic_v0180_hotfix1(
	malformed_content: String,
	payload: Dictionary,
	exact_shape: String
) -> void:
	var repair := {
		"kind": "json_repair",
		"stage": _diagnostic_stage_v01522(),
		"malformed_assistant_text": malformed_content,
		"exact_expected_shape": exact_shape,
		"request_payload": _sanitise_diagnostic_value_v01522(payload)
	}
	_active_job["diagnostics_last_repair"] = repair
	var events: Array = _array_copy_v01522(
		_active_job.get("diagnostic_events", [])
	)
	if (
		not events.is_empty()
		and events[-1] is Dictionary
		and str(events[-1].get("kind", "")) == "repair_request"
	):
		events[-1] = {"kind": "repair_request", "data": repair.duplicate(true)}
		_active_job["diagnostic_events"] = events
