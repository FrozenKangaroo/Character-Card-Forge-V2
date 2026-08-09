class_name CCFGenerationServiceV01540Hotfix7
extends "res://scripts/services/generation_service_v01537_hotfix1.gd"

const DIAGNOSTIC_STRING_CHAR_LIMIT_V01540_HOTFIX7 := 180000
const DIAGNOSTIC_TOTAL_TEXT_BUDGET_V01540_HOTFIX7 := 700000
const DIAGNOSTIC_TAIL_CHAR_LIMIT_V01540_HOTFIX7 := 12000
const DATA_URI_REPLACEMENT_LIMIT_V01540_HOTFIX7 := 16


func diagnostic_safety_capabilities_v01540_hotfix7() -> Dictionary:
	return {
		"version": "0.15.40-hotfix7",
		"embedded_data_uris_omitted": true,
		"image_binary_not_retained": true,
		"per_string_character_limit": DIAGNOSTIC_STRING_CHAR_LIMIT_V01540_HOTFIX7,
		"total_text_character_budget": DIAGNOSTIC_TOTAL_TEXT_BUDGET_V01540_HOTFIX7,
		"credentials_redacted": true
	}


func _sanitise_diagnostic_value_v01522(value: Variant) -> Variant:
	var budget := {
		"remaining": DIAGNOSTIC_TOTAL_TEXT_BUDGET_V01540_HOTFIX7
	}
	return _sanitise_diagnostic_value_v01540_hotfix7(value, budget)


func _sanitise_diagnostic_value_v01540_hotfix7(
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
				result[key] = _sanitise_diagnostic_value_v01540_hotfix7(
					value.get(raw_key),
					budget
				)
		return result
	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(
				_sanitise_diagnostic_value_v01540_hotfix7(item, budget)
			)
		return result_array
	if value is String:
		var cleaned := _omit_embedded_data_uris_v01540_hotfix7(value)
		cleaned = _redact_known_secrets_v01522(cleaned)
		return _bounded_diagnostic_string_v01540_hotfix7(cleaned, budget)
	return value


func _omit_embedded_data_uris_v01540_hotfix7(text: String) -> String:
	var result := text
	var search_from := 0
	var replacements := 0
	while replacements < DATA_URI_REPLACEMENT_LIMIT_V01540_HOTFIX7:
		var data_start := result.find("data:", search_from)
		if data_start < 0:
			break
		var base64_marker := result.find(";base64,", data_start)
		if base64_marker < 0:
			search_from = data_start + 5
			continue
		var metadata_end := base64_marker
		var payload_start := base64_marker + 8
		var payload_end := payload_start
		while payload_end < result.length():
			var codepoint := result.unicode_at(payload_end)
			if not _is_base64_codepoint_v01540_hotfix7(codepoint):
				break
			payload_end += 1
		var mime := result.substr(data_start + 5, metadata_end - data_start - 5)
		var separator := mime.find(";")
		if separator >= 0:
			mime = mime.left(separator)
		mime = mime.strip_edges()
		if mime.is_empty():
			mime = "application/octet-stream"
		var encoded_chars := maxi(0, payload_end - payload_start)
		var approximate_bytes := int(floor(float(encoded_chars) * 0.75))
		var replacement := (
			"[BINARY DATA OMITTED FROM DIAGNOSTICS — MIME: %s; encoded characters: %d; approximate decoded bytes: %d]"
			% [mime, encoded_chars, approximate_bytes]
		)
		result = result.left(data_start) + replacement + result.substr(payload_end)
		search_from = data_start + replacement.length()
		replacements += 1
	return result


func _is_base64_codepoint_v01540_hotfix7(codepoint: int) -> bool:
	return (
		(codepoint >= 65 and codepoint <= 90)
		or (codepoint >= 97 and codepoint <= 122)
		or (codepoint >= 48 and codepoint <= 57)
		or codepoint == 43
		or codepoint == 47
		or codepoint == 61
	)


func _bounded_diagnostic_string_v01540_hotfix7(
	text: String,
	budget: Dictionary
) -> String:
	var original_chars := text.length()
	var remaining := maxi(0, int(budget.get("remaining", 0)))
	if remaining <= 0:
		return (
			"[DIAGNOSTIC TEXT OMITTED — bundle text budget exhausted; original characters: %d]"
			% original_chars
		)
	var allowed := mini(
		DIAGNOSTIC_STRING_CHAR_LIMIT_V01540_HOTFIX7,
		remaining
	)
	if original_chars <= allowed:
		budget["remaining"] = remaining - original_chars
		return text

	var marker := (
		"\n\n[DIAGNOSTIC TEXT TRUNCATED — original characters: %d; display-safe capture limit: %d]\n\n"
		% [original_chars, allowed]
	)
	var tail_chars := mini(
		DIAGNOSTIC_TAIL_CHAR_LIMIT_V01540_HOTFIX7,
		maxi(0, allowed / 5)
	)
	var head_chars := maxi(0, allowed - tail_chars - marker.length())
	var bounded := text.left(head_chars) + marker
	if tail_chars > 0:
		bounded += text.right(tail_chars)
	budget["remaining"] = maxi(0, remaining - bounded.length())
	return bounded
