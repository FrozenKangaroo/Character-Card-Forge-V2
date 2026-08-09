class_name CCFGenerationDiagnosticsWindowV01540Hotfix7
extends "res://scripts/ui/generation_diagnostics_window_v01525.gd"

const VIEW_STRING_LIMIT_V01540_HOTFIX7 := 220000
const VIEW_TOTAL_TEXT_BUDGET_V01540_HOTFIX7 := 500000
const VIEW_TAIL_CHAR_LIMIT_V01540_HOTFIX7 := 10000
const TAB_PLACEHOLDER_V01540_HOTFIX7 := "Select this tab to render its bounded diagnostic content."

var _tabs_v01540_hotfix7: TabContainer
var _rendered_tabs_v01540_hotfix7: Dictionary = {}


func _ready() -> void:
	super._ready()
	_tabs_v01540_hotfix7 = _overview.get_parent() as TabContainer
	if (
		_tabs_v01540_hotfix7 != null
		and not _tabs_v01540_hotfix7.tab_changed.is_connected(
			_on_diagnostic_tab_changed_v01540_hotfix7
		)
	):
		_tabs_v01540_hotfix7.tab_changed.connect(
			_on_diagnostic_tab_changed_v01540_hotfix7
		)


func show_diagnostics(bundle: Dictionary) -> void:
	# Do not deep-copy an arbitrary provider payload into the UI. Build a bounded,
	# binary-free view model first, then render only the Overview tab immediately.
	var budget := {"remaining": VIEW_TOTAL_TEXT_BUDGET_V01540_HOTFIX7}
	var compact_value: Variant = _compact_view_value_v01540_hotfix7(bundle, budget)
	_bundle = {}
	if compact_value is Dictionary:
		_bundle = compact_value
	_rendered_tabs_v01540_hotfix7.clear()

	_render_overview_v01540_hotfix7()
	_request.text = TAB_PLACEHOLDER_V01540_HOTFIX7
	_raw_response.text = TAB_PLACEHOLDER_V01540_HOTFIX7
	_assistant_text.text = TAB_PLACEHOLDER_V01540_HOTFIX7
	_parsed_output.text = TAB_PLACEHOLDER_V01540_HOTFIX7
	_validation.text = TAB_PLACEHOLDER_V01540_HOTFIX7
	_repair.text = TAB_PLACEHOLDER_V01540_HOTFIX7
	_events.text = TAB_PLACEHOLDER_V01540_HOTFIX7
	_rendered_tabs_v01540_hotfix7[0] = true

	_status.text = "Credentials and embedded binary/image data are omitted. Large text is bounded for responsive display."
	title = "Generation Diagnostics — %s" % str(
		_bundle.get("label", "Failed generation")
	)
	if _tabs_v01540_hotfix7 != null:
		_tabs_v01540_hotfix7.current_tab = 0
	popup_centered(Vector2i(1080, 780))


func diagnostic_viewer_capabilities_v01540_hotfix7() -> Dictionary:
	return {
		"version": "0.15.40-hotfix7",
		"lazy_tab_rendering": true,
		"bounded_view_model": true,
		"embedded_binary_omitted": true,
		"copy_and_save_use_bounded_bundle": true,
		"per_string_character_limit": VIEW_STRING_LIMIT_V01540_HOTFIX7,
		"total_text_character_budget": VIEW_TOTAL_TEXT_BUDGET_V01540_HOTFIX7
	}


func _on_diagnostic_tab_changed_v01540_hotfix7(tab_index: int) -> void:
	_render_tab_v01540_hotfix7(tab_index)


func _render_tab_v01540_hotfix7(tab_index: int) -> void:
	if bool(_rendered_tabs_v01540_hotfix7.get(tab_index, false)):
		return
	match tab_index:
		1:
			_request.text = _bounded_pretty_v01540_hotfix7(
				_bundle.get("request", {})
			)
		2:
			_raw_response.text = _bounded_plain_text_v01540_hotfix7(
				str(_bundle.get("raw_api_response", "")),
				"No raw response body was available."
			)
		3:
			_assistant_text.text = _bounded_plain_text_v01540_hotfix7(
				str(_bundle.get("extracted_assistant_text", "")),
				"No assistant text was extracted from the provider response."
			)
		4:
			var parsed_text := _bounded_pretty_v01540_hotfix7(
				_bundle.get("parsed_output", null)
			)
			var parse_error := str(_bundle.get("parse_error", "")).strip_edges()
			if not parse_error.is_empty():
				parsed_text = "PARSE ERROR:\n%s\n\nPARSED OUTPUT:\n%s" % [
					parse_error,
					parsed_text
				]
			_parsed_output.text = _limit_display_text_v01540_hotfix7(parsed_text)
		5:
			_validation.text = _bounded_pretty_v01540_hotfix7(
				_bundle.get("validation_report", {})
			)
		6:
			_repair.text = _bounded_pretty_v01540_hotfix7(
				_bundle.get("repair", {})
			)
		7:
			_events.text = _bounded_pretty_v01540_hotfix7(
				_bundle.get("events", [])
			)
		_:
			pass
	_rendered_tabs_v01540_hotfix7[tab_index] = true


func _render_overview_v01540_hotfix7() -> void:
	var section := str(_bundle.get("active_section", "")).strip_edges()
	var overview_lines: Array[String] = []
	overview_lines.append(
		"Failure: %s" % str(
			_bundle.get("failure_reason", "Unknown generation failure.")
		)
	)
	overview_lines.append(
		"Stage: %s" % str(_bundle.get("failure_stage", "unknown"))
	)
	if not section.is_empty():
		overview_lines.append("Section: %s" % section)
	overview_lines.append(
		"Job: %s (%s)" % [
			str(_bundle.get("job_id", "")),
			str(_bundle.get("job_type", ""))
		]
	)
	overview_lines.append(
		"Generation strategy: %s" % str(
			_bundle.get("generation_strategy", "")
		)
	)
	var provider_value: Variant = _bundle.get("provider", {})
	if provider_value is Dictionary:
		var provider: Dictionary = provider_value
		overview_lines.append(
			"Provider profile: %s" % str(provider.get("profile_name", ""))
		)
		overview_lines.append("Model: %s" % str(provider.get("model", "")))
	overview_lines.append(
		"Captured: %s" % str(_bundle.get("captured_at", ""))
	)

	var budget_value: Variant = _bundle.get("token_budget", {})
	if budget_value is Dictionary and not budget_value.is_empty():
		var token_budget: Dictionary = budget_value
		overview_lines.append("")
		overview_lines.append("Token budget")
		var configured := int(
			token_budget.get("configured_character_max_output_tokens", 0)
		)
		var requested := int(token_budget.get("request_max_tokens", 0))
		if configured > 0:
			overview_lines.append(
				"Configured Text maximum output: %s tokens" % _format_token_count_v01525(configured)
			)
		if requested > 0:
			overview_lines.append(
				"This request max_tokens: %s" % _format_token_count_v01525(requested)
			)
		if bool(token_budget.get("hidden_stage_caps_allowed", true)) == false:
			overview_lines.append("Per-stage hidden output caps: disabled")

	var termination_value: Variant = _bundle.get("provider_termination", {})
	if termination_value is Dictionary and not termination_value.is_empty():
		var termination: Dictionary = termination_value
		overview_lines.append("")
		overview_lines.append("Provider termination")
		if bool(termination.get("limit_reached", false)):
			overview_lines.append("OUTPUT LIMIT REACHED")
		var finish_reason := str(termination.get("finish_reason", "")).strip_edges()
		if not finish_reason.is_empty():
			overview_lines.append("Finish reason: %s" % finish_reason)
		var incomplete_reason := str(
			termination.get("incomplete_reason", "")
		).strip_edges()
		if not incomplete_reason.is_empty():
			overview_lines.append("Incomplete reason: %s" % incomplete_reason)
		var prompt_tokens := int(termination.get("prompt_tokens", 0))
		var completion_tokens := int(termination.get("completion_tokens", 0))
		var total_tokens := int(termination.get("total_tokens", 0))
		if prompt_tokens > 0:
			overview_lines.append(
				"Provider input tokens: %s" % _format_token_count_v01525(prompt_tokens)
			)
		if completion_tokens > 0:
			overview_lines.append(
				"Provider output tokens: %s" % _format_token_count_v01525(completion_tokens)
			)
		if total_tokens > 0:
			overview_lines.append(
				"Provider total tokens: %s" % _format_token_count_v01525(total_tokens)
			)
		var summary := str(termination.get("summary", "")).strip_edges()
		if not summary.is_empty():
			overview_lines.append(summary)

	overview_lines.append("")
	overview_lines.append(
		"Safety: embedded image/binary payloads are omitted from diagnostics; large text is bounded so opening this window cannot synchronously lay out multi-megabyte request bodies."
	)
	_overview.text = _limit_display_text_v01540_hotfix7(
		"\n".join(overview_lines)
	)


func _compact_view_value_v01540_hotfix7(
	value: Variant,
	budget: Dictionary
) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for raw_key in value:
			var key := str(raw_key)
			var lowered := key.to_lower()
			if lowered in [
				"api_key",
				"authorization",
				"proxy_authorization",
				"password",
				"secret",
				"access_token",
				"refresh_token",
				"headers"
			]:
				result[key] = "[REDACTED]"
			else:
				result[key] = _compact_view_value_v01540_hotfix7(
					value.get(raw_key),
					budget
				)
		return result
	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(
				_compact_view_value_v01540_hotfix7(item, budget)
			)
		return result_array
	if value is String:
		var clean := _omit_data_uri_for_view_v01540_hotfix7(value)
		return _bounded_view_string_v01540_hotfix7(clean, budget)
	return value


func _omit_data_uri_for_view_v01540_hotfix7(text: String) -> String:
	var result := text
	var search_from := 0
	var replacements := 0
	while replacements < 16:
		var data_start := result.find("data:", search_from)
		if data_start < 0:
			break
		var base64_marker := result.find(";base64,", data_start)
		if base64_marker < 0:
			search_from = data_start + 5
			continue
		var payload_start := base64_marker + 8
		var payload_end := payload_start
		while payload_end < result.length():
			var codepoint := result.unicode_at(payload_end)
			if not (
				(codepoint >= 65 and codepoint <= 90)
				or (codepoint >= 97 and codepoint <= 122)
				or (codepoint >= 48 and codepoint <= 57)
				or codepoint == 43
				or codepoint == 47
				or codepoint == 61
			):
				break
			payload_end += 1
		var mime := result.substr(
			data_start + 5,
			base64_marker - data_start - 5
		).strip_edges()
		if mime.is_empty():
			mime = "application/octet-stream"
		var encoded_chars := maxi(0, payload_end - payload_start)
		var replacement := (
			"[BINARY DATA OMITTED — MIME: %s; encoded characters: %d]"
			% [mime, encoded_chars]
		)
		result = result.left(data_start) + replacement + result.substr(payload_end)
		search_from = data_start + replacement.length()
		replacements += 1
	return result


func _bounded_view_string_v01540_hotfix7(
	text: String,
	budget: Dictionary
) -> String:
	var original_chars := text.length()
	var remaining := maxi(0, int(budget.get("remaining", 0)))
	if remaining <= 0:
		return "[TEXT OMITTED — diagnostics display budget exhausted; original characters: %d]" % original_chars
	var allowed := mini(VIEW_STRING_LIMIT_V01540_HOTFIX7, remaining)
	if original_chars <= allowed:
		budget["remaining"] = remaining - original_chars
		return text
	var marker := (
		"\n\n[TEXT TRUNCATED FOR RESPONSIVE DIAGNOSTICS DISPLAY — original characters: %d]\n\n"
		% original_chars
	)
	var fifth_of_allowed := int(floor(float(allowed) / 5.0))
	var tail_chars := mini(
		VIEW_TAIL_CHAR_LIMIT_V01540_HOTFIX7,
		maxi(0, fifth_of_allowed)
	)
	var head_chars := maxi(0, allowed - tail_chars - marker.length())
	var bounded := text.left(head_chars) + marker
	if tail_chars > 0:
		bounded += text.right(tail_chars)
	budget["remaining"] = maxi(0, remaining - bounded.length())
	return bounded


func _bounded_pretty_v01540_hotfix7(value: Variant) -> String:
	return _limit_display_text_v01540_hotfix7(_pretty(value))


func _bounded_plain_text_v01540_hotfix7(
	text: String,
	empty_fallback: String
) -> String:
	if text.is_empty():
		return empty_fallback
	return _limit_display_text_v01540_hotfix7(text)


func _limit_display_text_v01540_hotfix7(text: String) -> String:
	if text.length() <= VIEW_STRING_LIMIT_V01540_HOTFIX7:
		return text
	var marker := (
		"\n\n[RENDERED TAB TRUNCATED — original characters: %d]\n"
		% text.length()
	)
	var head_chars := maxi(
		0,
		VIEW_STRING_LIMIT_V01540_HOTFIX7 - marker.length()
	)
	return text.left(head_chars) + marker
