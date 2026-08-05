class_name CCFGenerationServiceV01537Hotfix1
extends "res://scripts/services/generation_service_v01536_hotfix2.gd"

const SAFE_SECTION_GUARD_VERSION_V01537_HOTFIX1 := 1
const LONG_CONTENT_MIN_V01537_HOTFIX1 := 180
const SOURCE_SECTION_MIN_V01537_HOTFIX1 := 220


func safe_section_guard_capabilities_v01537_hotfix1() -> Dictionary:
	return {
		"version": "0.15.37-hotfix1",
		"guard_version": SAFE_SECTION_GUARD_VERSION_V01537_HOTFIX1,
		"exact_standalone_field_key": true,
		"exact_group_component_ids": true,
		"generic_value_key_repair_only": true,
		"duplicate_component_guard": true,
		"reserved_source_section_guard": true,
		"artifact_structure_guard": true,
		"assembled_cross_field_guard": true,
		"acceptance_diagnostics": true,
		"parallel_children_use_hotfix_guard": true
	}


func validate_safe_section_candidate_v01537_hotfix1(
	section: Dictionary,
	raw_data: Dictionary,
	state: Dictionary = {}
) -> Dictionary:
	var kind := str(section.get("kind", "standalone_field"))
	if kind == "output_group":
		var group := _dictionary_copy_v01522(section.get("group", {}))
		var candidate := _unwrap_group_candidate_v01537_hotfix1(group, raw_data)
		var accepted: Dictionary = {}
		var missing: Array[String] = []
		var returned_keys := _dictionary_keys_v01537_hotfix1(candidate)
		for raw_component in group.get("components", []):
			if not raw_component is Dictionary or not bool(raw_component.get("enabled", true)):
				continue
			var component: Dictionary = raw_component
			var component_id := str(component.get("id", "")).strip_edges()
			if component_id.is_empty():
				continue
			if candidate.has(component_id) and _value_has_content_v01522(candidate.get(component_id)):
				accepted[component_id] = _value_to_text(candidate.get(component_id)).strip_edges()
			elif bool(component.get("required", true)):
				missing.append(component_id)
		var contamination := _first_group_contamination_v01537_hotfix1(group, accepted, state)
		return {
			"ok": missing.is_empty() and contamination.is_empty(),
			"kind": "output_group",
			"requested_keys": _enabled_component_ids_v01537_hotfix1(group),
			"returned_keys": returned_keys,
			"missing_keys": missing,
			"contamination": contamination
		}

	var field_id := str(section.get("field_id", section.get("id", "field"))).strip_edges()
	var returned_keys := _dictionary_keys_v01537_hotfix1(raw_data)
	var issues: Array[String] = []
	if not raw_data.has(field_id):
		issues.append("Expected exact key `%s`; returned keys were: %s" % [field_id, ", ".join(returned_keys)])
	elif raw_data.size() != 1:
		issues.append("Expected exactly one key `%s`; extra keys are not accepted." % field_id)
	else:
		var value := raw_data.get(field_id)
		for issue in _safe_value_contamination_issues_v01537_hotfix1(
			field_id,
			str(section.get("title", field_id)),
			_value_to_text(value),
			state
		):
			issues.append(str(issue))
	return {
		"ok": issues.is_empty(),
		"kind": "standalone_field",
		"requested_key": field_id,
		"returned_keys": returned_keys,
		"issues": issues
	}


func assembled_contamination_issues_v01537_hotfix1(
	assembled: Dictionary,
	state: Dictionary = {}
) -> Array[String]:
	var issues: Array[String] = []
	var string_fields: Array[Dictionary] = []
	for raw_key in assembled:
		var field_id := str(raw_key)
		var value: Variant = assembled.get(raw_key)
		if not value is String:
			continue
		var text := str(value).strip_edges()
		if text.is_empty():
			continue
		string_fields.append({"id": field_id, "text": text})
		for issue in _safe_value_contamination_issues_v01537_hotfix1(
			field_id, field_id, text, state
		):
			issues.append("%s: %s" % [field_id, str(issue)])
		var paragraph_seen: Dictionary = {}
		for raw_paragraph in text.split("\n\n", false):
			var paragraph := _normalise_long_text_v01537_hotfix1(str(raw_paragraph))
			if paragraph.length() < LONG_CONTENT_MIN_V01537_HOTFIX1:
				continue
			if paragraph_seen.has(paragraph):
				issues.append(
					"%s repeats the same long content block inside one field; this resembles cross-section contamination."
					% field_id
				)
				break
			paragraph_seen[paragraph] = true

	for left_index in range(string_fields.size()):
		for right_index in range(left_index + 1, string_fields.size()):
			var left: Dictionary = string_fields[left_index]
			var right: Dictionary = string_fields[right_index]
			if _same_long_content_v01537_hotfix1(str(left.get("text", "")), str(right.get("text", ""))):
				issues.append(
					"%s and %s contain the same long generated content; one section appears to have been routed into another."
					% [str(left.get("id", "field")), str(right.get("id", "field"))]
				)
	return _dedupe_strings_v01537_hotfix1(issues)


func _process_safe_field_result_v01522(section: Dictionary, data: Dictionary) -> void:
	var field := _dictionary_copy_v01522(section.get("field", {}))
	var field_id := str(section.get("field_id", field.get("id", "field"))).strip_edges()
	var returned_keys := _dictionary_keys_v01537_hotfix1(data)
	if not data.has(field_id) or data.size() != 1:
		var identity_issue := (
			"Safe Section Build expected exactly one JSON key `%s`; returned keys: %s. "
			+ "CCF no longer treats an unrelated one-key object as the requested field."
		) % [field_id, ", ".join(returned_keys)]
		_active_job["safe_pending_field_value"] = null
		_active_job["diagnostics_validation"] = {
			"ok": false,
			"kind": "field_identity_mismatch",
			"requested_key": field_id,
			"returned_keys": returned_keys,
			"acceptance_route": "rejected_before_value_acceptance"
		}
		_start_safe_field_repair_v01522(section, [identity_issue])
		return

	var value: Variant = data.get(field_id)
	var issues := _standalone_field_issues_v01522(field, value, true)
	for contamination_issue in _safe_value_contamination_issues_v01537_hotfix1(
		field_id,
		str(section.get("title", field_id)),
		_value_to_text(value),
		_dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	):
		issues.append(str(contamination_issue))
	if not issues.is_empty():
		_active_job["safe_pending_field_value"] = value
		_active_job["diagnostics_validation"] = {
			"ok": false,
			"kind": "standalone_field",
			"section": str(section.get("title", field_id)),
			"requested_key": field_id,
			"returned_keys": returned_keys,
			"issues": issues,
			"content_fingerprint": _content_fingerprint_v01537_hotfix1(_value_to_text(value))
		}
		_start_safe_field_repair_v01522(section, issues)
		return
	_record_safe_acceptance_v01537_hotfix1(
		field_id, returned_keys, "exact_standalone_key", _value_to_text(value)
	)
	_accept_safe_field_v01522(section, value, true)


func _process_safe_field_repair_v01522(content: String) -> void:
	var parse_result := _parse_job_output_with_diagnostics(content, "field")
	if not bool(parse_result.get("ok", false)):
		if _start_json_repair(content, "field"):
			return
		_fail_safe_parse_v01522(parse_result)
		return
	var value: Variant = parse_result.get("data")
	var section := _dictionary_copy_v01522(_active_job.get("safe_active_section", {}))
	var field := _dictionary_copy_v01522(section.get("field", {}))
	var field_id := str(section.get("field_id", field.get("id", "field")))
	var issues := _standalone_field_issues_v01522(field, value, true)
	for contamination_issue in _safe_value_contamination_issues_v01537_hotfix1(
		field_id,
		str(section.get("title", field_id)),
		_value_to_text(value),
		_dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	):
		issues.append(str(contamination_issue))
	if not issues.is_empty():
		_active_job["safe_pending_field_value"] = value
		_active_job["diagnostics_validation"] = {
			"ok": false,
			"kind": "field_repair_contamination",
			"requested_key": field_id,
			"acceptance_route": "generic_value_repair_only",
			"issues": issues,
			"content_fingerprint": _content_fingerprint_v01537_hotfix1(_value_to_text(value))
		}
		_start_safe_field_repair_v01522(section, issues)
		return
	_record_safe_acceptance_v01537_hotfix1(
		field_id, ["value"], "focused_repair_value", _value_to_text(value)
	)
	_accept_safe_field_v01522(section, value, true)


func _process_safe_group_result_v01522(section: Dictionary, raw_data: Dictionary) -> void:
	var group := _dictionary_copy_v01522(section.get("group", {}))
	var candidate := _unwrap_group_candidate_v01537_hotfix1(group, raw_data)
	var accepted: Dictionary = {}
	var extras: Array[Dictionary] = []
	var known_ids: Dictionary = {}
	var missing_required: Array[Dictionary] = []
	for raw_component in group.get("components", []):
		if not raw_component is Dictionary or not bool(raw_component.get("enabled", true)):
			continue
		var component: Dictionary = raw_component
		var component_id := str(component.get("id", "")).strip_edges()
		if component_id.is_empty():
			continue
		known_ids[component_id] = true
		var value: Variant = candidate.get(component_id, null)
		if candidate.has(component_id) and _value_has_content_v01522(value):
			accepted[component_id] = _value_to_text(value).strip_edges()
		elif bool(component.get("required", true)):
			missing_required.append(component.duplicate(true))

	if bool(group.get("allow_extra_components", false)):
		for raw_key in candidate:
			var key := str(raw_key)
			if known_ids.has(key) or not _value_has_content_v01522(candidate.get(raw_key)):
				continue
			extras.append({
				"label": key.replace("_", " ").capitalize(),
				"value": _value_to_text(candidate.get(raw_key)).strip_edges()
			})

	_active_job["safe_pending_group_components"] = accepted
	_active_job["safe_pending_group_extras"] = extras
	if not missing_required.is_empty():
		_active_job["diagnostics_validation"] = {
			"ok": false,
			"kind": "missing_component",
			"section": str(section.get("title", "Output Group")),
			"requested_keys": _enabled_component_ids_v01537_hotfix1(group),
			"returned_keys": _dictionary_keys_v01537_hotfix1(candidate),
			"missing": _component_labels_v01522(missing_required)
		}
		_start_safe_component_repair_v01522(section, missing_required[0])
		return

	var contamination := _first_group_contamination_v01537_hotfix1(
		group,
		accepted,
		_dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	)
	if not contamination.is_empty():
		_repair_group_contamination_v01537_hotfix1(section, group, contamination)
		return

	for component_id in accepted:
		_record_safe_acceptance_v01537_hotfix1(
			str(component_id),
			_dictionary_keys_v01537_hotfix1(candidate),
			"exact_group_component_id",
			str(accepted.get(component_id, ""))
		)
	_accept_safe_group_v01522(section)


func _process_safe_component_repair_v01522(content: String) -> void:
	var parse_result := _parse_job_output_with_diagnostics(content, "field")
	if not bool(parse_result.get("ok", false)):
		if _start_json_repair(content, "field"):
			return
		_fail_safe_parse_v01522(parse_result)
		return
	var value: Variant = parse_result.get("data")
	var section := _dictionary_copy_v01522(_active_job.get("safe_active_section", {}))
	var component := _dictionary_copy_v01522(_active_job.get("safe_repair_component", {}))
	if not _value_has_content_v01522(value):
		_start_safe_component_repair_v01522(section, component)
		return
	var pending := _dictionary_copy_v01522(_active_job.get("safe_pending_group_components", {}))
	var component_id := str(component.get("id", "component"))
	pending[component_id] = _value_to_text(value).strip_edges()
	_active_job["safe_pending_group_components"] = pending
	var group := _dictionary_copy_v01522(section.get("group", {}))

	for raw_component in group.get("components", []):
		if not raw_component is Dictionary or not bool(raw_component.get("enabled", true)) or not bool(raw_component.get("required", true)):
			continue
		var required_component: Dictionary = raw_component
		var required_id := str(required_component.get("id", ""))
		if not _value_has_content_v01522(pending.get(required_id)):
			_start_safe_component_repair_v01522(section, required_component)
			return

	var contamination := _first_group_contamination_v01537_hotfix1(
		group,
		pending,
		_dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	)
	if not contamination.is_empty():
		_repair_group_contamination_v01537_hotfix1(section, group, contamination)
		return
	_record_safe_acceptance_v01537_hotfix1(
		component_id, ["value"], "focused_component_repair", _value_to_text(value)
	)
	_accept_safe_group_v01522(section)


func _finish_safe_build_v01522() -> void:
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var assembled := _assembled_safe_fields_v01522(state)
	var issues := assembled_contamination_issues_v01537_hotfix1(assembled, state)
	if not issues.is_empty():
		_active_job["diagnostics_validation"] = {
			"ok": false,
			"kind": "assembled_cross_section_contamination",
			"issues": issues
		}
		_handle_failure(
			"Safe Section Build rejected the assembled card because generated sections appear to contain routed/duplicated content from other sections. %s"
			% " ".join(issues),
			false
		)
		return
	super._finish_safe_build_v01522()


func _finish_parallel_safe_build_v01526() -> void:
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var assembled := _assembled_safe_fields_v01522(state)
	var issues := assembled_contamination_issues_v01537_hotfix1(assembled, state)
	if not issues.is_empty():
		_active_job["diagnostics_validation"] = {
			"ok": false,
			"kind": "assembled_cross_section_contamination",
			"issues": issues,
			"parallel": true
		}
		_parallel_coordinator_v01526 = {}
		_handle_failure(
			"Parallel Safe Section Build rejected the assembled card because generated sections appear to contain routed/duplicated content from other sections. %s"
			% " ".join(issues),
			false
		)
		return
	super._finish_parallel_safe_build_v01526()


func _fill_parallel_wave_v01526() -> void:
	var wave_value: Variant = _parallel_coordinator_v01526.get("wave_indices", [])
	var wave: Array = wave_value if wave_value is Array else []
	var cursor := int(_parallel_coordinator_v01526.get("wave_cursor", 0))
	var running_value: Variant = _parallel_coordinator_v01526.get("running", {})
	var running: Dictionary = running_value if running_value is Dictionary else {}
	var config := _scheduler_v01526.config() if _scheduler_v01526 != null else {}
	var per_character_limit := maxi(1, int(config.get("max_sections_per_character", 1)))
	while cursor < wave.size() and running.size() < per_character_limit:
		var section_index := int(wave[cursor])
		cursor += 1
		var child := CCFGenerationServiceV01537Hotfix1.new()
		var child_id := "%s:section:%03d:%03d" % [
			_scheduler_worker_id_v01526, section_index, _parallel_child_serial_v01526
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
		child.parallel_safe_section_completed.connect(_on_parallel_section_completed_v01526)
		child.job_failed.connect(_on_parallel_section_failed_v01526.bind(child_id))
		child.job_cancelled.connect(_on_parallel_section_cancelled_v01526.bind(child_id))
		child.diagnostics_available.connect(_on_parallel_child_diagnostics_v01526)
		var snapshot := _dictionary_copy_v01522(
			_parallel_coordinator_v01526.get("wave_snapshot", {})
		)
		var plan_value: Variant = snapshot.get("plan", [])
		var plan: Array = plan_value if plan_value is Array else []
		if section_index < 0 or section_index >= plan.size() or not plan[section_index] is Dictionary:
			child.queue_free()
			_parallel_coordinator_v01526["failed"] = true
			_handle_failure("Parallel Safe Section Build encountered an invalid section plan.", false)
			return
		var section: Dictionary = plan[section_index]
		var result := child.queue_parallel_safe_section_v01526(
			_active_job.duplicate(true), snapshot, section, section_index
		)
		if not bool(result.get("ok", false)):
			child.queue_free()
			_parallel_coordinator_v01526["failed"] = true
			_handle_failure(str(result.get("error", "Could not start parallel section.")), false)
			return
		running[child_id] = {"service": child, "section_index": section_index}
	_parallel_coordinator_v01526["wave_cursor"] = cursor
	_parallel_coordinator_v01526["running"] = running
	_emit_queue_changed()


func _repair_group_contamination_v01537_hotfix1(
	section: Dictionary,
	group: Dictionary,
	contamination: Dictionary
) -> void:
	var component_id := str(contamination.get("component_id", ""))
	var pending := _dictionary_copy_v01522(_active_job.get("safe_pending_group_components", {}))
	pending.erase(component_id)
	_active_job["safe_pending_group_components"] = pending
	_active_job["diagnostics_validation"] = {
		"ok": false,
		"kind": "cross_section_contamination",
		"section": str(section.get("title", "Output Group")),
		"component_id": component_id,
		"reason": str(contamination.get("reason", "Generated component resembles content routed from another section.")),
		"content_fingerprint": str(contamination.get("content_fingerprint", ""))
	}
	for raw_component in group.get("components", []):
		if raw_component is Dictionary and str(raw_component.get("id", "")) == component_id:
			_start_safe_component_repair_v01522(section, raw_component)
			return
	_handle_failure(
		"Safe Section Build detected contamination in an unknown component `%s`." % component_id,
		false
	)


func _first_group_contamination_v01537_hotfix1(
	group: Dictionary,
	values: Dictionary,
	state: Dictionary
) -> Dictionary:
	var component_lookup: Dictionary = {}
	for raw_component in group.get("components", []):
		if raw_component is Dictionary:
			component_lookup[str(raw_component.get("id", ""))] = raw_component

	for raw_id in values:
		var component_id := str(raw_id)
		var component_value := str(values.get(raw_id, ""))
		var component_value_meta: Dictionary = component_lookup.get(component_id, {})
		var component_label := str(component_value_meta.get("label", component_id))
		var value_issues := _safe_value_contamination_issues_v01537_hotfix1(
			component_id, component_label, component_value, state
		)
		if not value_issues.is_empty():
			return {
				"component_id": component_id,
				"reason": str(value_issues[0]),
				"content_fingerprint": _content_fingerprint_v01537_hotfix1(component_value)
			}

	var ids: Array[String] = []
	for raw_id in values:
		ids.append(str(raw_id))
	for left_index in range(ids.size()):
		for right_index in range(left_index + 1, ids.size()):
			var left_id := ids[left_index]
			var right_id := ids[right_index]
			var left_text := str(values.get(left_id, ""))
			var right_text := str(values.get(right_id, ""))
			if _same_long_content_v01537_hotfix1(left_text, right_text):
				return {
					"component_id": right_id,
					"reason": "Component duplicates another long component value in the same output group; this matches the reported Scenario/Personality contamination pattern.",
					"content_fingerprint": _content_fingerprint_v01537_hotfix1(right_text)
				}
	return {}


func _safe_value_contamination_issues_v01537_hotfix1(
	target_id: String,
	target_label: String,
	text: String,
	state: Dictionary
) -> Array[String]:
	var issues: Array[String] = []
	var clean := text.strip_edges()
	if clean.is_empty():
		return issues
	var lowered := clean.to_lower()
	var target := (target_id + " " + target_label).to_lower()

	if not _target_allows_lorebook_v01537_hotfix1(target):
		if lowered.begins_with("lorebook entries:") or lowered.contains("\n1. **key:") or lowered.contains("\n1. key:"):
			issues.append("Value contains Lorebook-entry structure inside a non-Lorebook field.")
	if not _target_allows_first_message_v01537_hotfix1(target):
		if lowered.begins_with("final first message") or lowered.begins_with("first message:"):
			issues.append("Value contains First Message structure inside a different field.")
	if not _target_allows_scenario_v01537_hotfix1(target):
		if lowered.begins_with("roleplay scenario:") or lowered.begins_with("scenario:"):
			issues.append("Value contains Scenario structure inside a different field.")

	var concept := _concept_from_state_v01537_hotfix1(state)
	if not concept.is_empty() and clean.length() >= SOURCE_SECTION_MIN_V01537_HOTFIX1:
		var reserved := {
			"scenario": _extract_markdown_section_v01537_hotfix1(concept, ["roleplay scenario"]),
			"first_message": _extract_markdown_section_v01537_hotfix1(concept, ["final first message text", "first message"]),
			"lorebook": _extract_markdown_section_v01537_hotfix1(concept, ["lorebook"])
		}
		for raw_section_name in reserved:
			var section_name := str(raw_section_name)
			var source_text := str(reserved.get(raw_section_name, "")).strip_edges()
			if source_text.length() < SOURCE_SECTION_MIN_V01537_HOTFIX1:
				continue
			if _target_allows_reserved_section_v01537_hotfix1(target, section_name):
				continue
			if _same_long_content_v01537_hotfix1(clean, source_text) or _normalise_long_text_v01537_hotfix1(clean).contains(_normalise_long_text_v01537_hotfix1(source_text)):
				issues.append(
					"Value reproduces the authoritative `%s` source section inside `%s`; this looks like cross-section routing contamination."
					% [section_name, target_label]
				)
	return _dedupe_strings_v01537_hotfix1(issues)


func _unwrap_group_candidate_v01537_hotfix1(group: Dictionary, raw_data: Dictionary) -> Dictionary:
	var candidate := raw_data.duplicate(true)
	var group_id := str(group.get("id", ""))
	if candidate.get("components") is Dictionary:
		return _dictionary_copy_v01522(candidate.get("components", {}))
	if not group_id.is_empty() and candidate.get(group_id) is Dictionary:
		return _dictionary_copy_v01522(candidate.get(group_id, {}))
	return candidate


func _enabled_component_ids_v01537_hotfix1(group: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for raw_component in group.get("components", []):
		if raw_component is Dictionary and bool(raw_component.get("enabled", true)):
			var component_id := str(raw_component.get("id", "")).strip_edges()
			if not component_id.is_empty():
				result.append(component_id)
	return result


func _dictionary_keys_v01537_hotfix1(value: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for raw_key in value:
		result.append(str(raw_key))
	result.sort()
	return result


func _normalise_long_text_v01537_hotfix1(text: String) -> String:
	var lowered := text.to_lower().strip_edges()
	var result := ""
	var previous_space := false
	for index in range(lowered.length()):
		var character := lowered.substr(index, 1)
		var code := character.unicode_at(0)
		var is_word := (
			(code >= 48 and code <= 57)
			or (code >= 97 and code <= 122)
			or character == "{"
			or character == "}"
		)
		if is_word:
			result += character
			previous_space = false
		elif not previous_space:
			result += " "
			previous_space = true
	return result.strip_edges()


func _same_long_content_v01537_hotfix1(left: String, right: String) -> bool:
	var left_norm := _normalise_long_text_v01537_hotfix1(left)
	var right_norm := _normalise_long_text_v01537_hotfix1(right)
	if left_norm.length() < LONG_CONTENT_MIN_V01537_HOTFIX1 or right_norm.length() < LONG_CONTENT_MIN_V01537_HOTFIX1:
		return false
	if left_norm == right_norm:
		return true
	var shorter := left_norm if left_norm.length() <= right_norm.length() else right_norm
	var longer := right_norm if left_norm.length() <= right_norm.length() else left_norm
	return longer.contains(shorter) and float(shorter.length()) / float(longer.length()) >= 0.90


func _concept_from_state_v01537_hotfix1(state: Dictionary) -> String:
	var explicit := str(state.get("concept", "")).strip_edges()
	if not explicit.is_empty():
		return explicit
	var metadata := _dictionary_copy_v01522(_active_job.get("metadata", {}))
	var concept := str(metadata.get("concept", "")).strip_edges()
	if not concept.is_empty():
		return concept
	var project := _dictionary_copy_v01522(state.get("project", {}))
	return str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()


func _extract_markdown_section_v01537_hotfix1(text: String, target_names: Array) -> String:
	var targets: Array[String] = []
	for raw_target in target_names:
		targets.append(str(raw_target).strip_edges().to_lower().trim_suffix(":"))
	var found := false
	var found_level := 0
	var lines: Array[String] = []
	for raw_line in text.split("\n", true):
		var line := str(raw_line)
		var stripped := line.strip_edges()
		if stripped.begins_with("#"):
			var level := 0
			while level < stripped.length() and stripped.substr(level, 1) == "#":
				level += 1
			var heading := stripped.substr(level).strip_edges().to_lower().trim_suffix(":")
			if found and level <= found_level:
				break
			if not found and heading in targets:
				found = true
				found_level = level
				continue
		if found:
			lines.append(line)
	return "\n".join(lines).strip_edges()


func _target_allows_reserved_section_v01537_hotfix1(target: String, section_name: String) -> bool:
	match section_name:
		"scenario":
			return _target_allows_scenario_v01537_hotfix1(target)
		"first_message":
			return _target_allows_first_message_v01537_hotfix1(target)
		"lorebook":
			return _target_allows_lorebook_v01537_hotfix1(target)
	return false


func _target_allows_scenario_v01537_hotfix1(target: String) -> bool:
	return (
		target.contains("scenario")
		or target.contains("roleplay hook")
		or target.contains("plot")
		or target.contains("setting")
	)


func _target_allows_first_message_v01537_hotfix1(target: String) -> bool:
	return (
		target.contains("first message")
		or target.contains("first_mes")
		or target.contains("greeting")
		or target.contains("opening message")
	)


func _target_allows_lorebook_v01537_hotfix1(target: String) -> bool:
	return target.contains("lorebook") or target.contains("worldbook") or target.contains("world info")


func _record_safe_acceptance_v01537_hotfix1(
	requested_key: String,
	returned_keys: Array,
	acceptance_route: String,
	text: String
) -> void:
	var events_value: Variant = _active_job.get("safe_acceptance_diagnostics_v01537_hotfix1", [])
	var events: Array = events_value.duplicate(true) if events_value is Array else []
	events.append({
		"requested_key": requested_key,
		"returned_keys": returned_keys.duplicate(),
		"acceptance_route": acceptance_route,
		"content_fingerprint": _content_fingerprint_v01537_hotfix1(text)
	})
	while events.size() > 96:
		events.pop_front()
	_active_job["safe_acceptance_diagnostics_v01537_hotfix1"] = events


func _content_fingerprint_v01537_hotfix1(text: String) -> String:
	var normalised := _normalise_long_text_v01537_hotfix1(text)
	return "%s:%d:%d" % [str(normalised.hash()), normalised.length(), text.length()]


func _dedupe_strings_v01537_hotfix1(values: Array) -> Array[String]:
	var result: Array[String] = []
	for raw_value in values:
		var value := str(raw_value)
		if not value.is_empty() and value not in result:
			result.append(value)
	return result
