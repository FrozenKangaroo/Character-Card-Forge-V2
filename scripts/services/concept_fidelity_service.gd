class_name CCFConceptFidelityService
extends RefCounted

const FORMAT_VERSION := 1
const MAX_ADVISORY_LITERALS := 8


static func build_plan(concept: String, authoritative_name: String = "") -> Dictionary:
	var clean_concept := concept.strip_edges()
	var anchors: Array[Dictionary] = []
	var clean_name := authoritative_name.strip_edges()
	if _usable_name(clean_name):
		anchors.append(
			{
				"kind": "name",
				"label": "Character name",
				"value": clean_name,
				"severity": "critical",
				"retry_on_missing": true
			}
		)

	_append_age_anchors(anchors, clean_concept)
	_append_cup_size_anchors(anchors, clean_concept)
	_append_advisory_literals(anchors, clean_concept)
	return {
		"format_version": FORMAT_VERSION,
		"concept": clean_concept,
		"authoritative_name": clean_name,
		"anchors": anchors
	}


static func validate_candidate(plan: Dictionary, candidate: Dictionary) -> Dictionary:
	var anchors_value: Variant = plan.get("anchors", [])
	var anchors: Array = anchors_value if anchors_value is Array else []
	var candidate_text := _flatten_candidate(candidate)
	var candidate_compact := _compact(candidate_text)
	var issues: Array[Dictionary] = []
	var checked_count := 0
	var critical_missing_count := 0
	var advisory_missing_count := 0

	for raw_anchor in anchors:
		if not raw_anchor is Dictionary:
			continue
		var anchor: Dictionary = raw_anchor
		checked_count += 1
		if _anchor_present(anchor, candidate, candidate_text, candidate_compact):
			continue
		var severity := str(anchor.get("severity", "advisory"))
		var issue := {
			"kind": str(anchor.get("kind", "literal")),
			"label": str(anchor.get("label", "Concept marker")),
			"value": str(anchor.get("value", "")),
			"severity": severity,
			"retry_on_missing": bool(anchor.get("retry_on_missing", false)),
			"reason": _missing_reason(anchor, candidate)
		}
		issues.append(issue)
		if severity == "critical" and bool(anchor.get("retry_on_missing", false)):
			critical_missing_count += 1
		else:
			advisory_missing_count += 1

	return {
		"format_version": FORMAT_VERSION,
		"checked": true,
		"anchor_count": checked_count,
		"missing_count": issues.size(),
		"critical_missing_count": critical_missing_count,
		"advisory_missing_count": advisory_missing_count,
		"clear_drift": critical_missing_count > 0,
		"issues": issues,
		"summary": (
			"Concept fidelity markers preserved."
			if issues.is_empty()
			else "%d concept-fidelity marker(s) need attention." % issues.size()
		)
	}


static func retry_instructions(report: Dictionary) -> String:
	var lines: Array[String] = []
	var issues_value: Variant = report.get("issues", [])
	if not issues_value is Array:
		return ""
	for raw_issue in issues_value:
		if not raw_issue is Dictionary or not bool(raw_issue.get("retry_on_missing", false)):
			continue
		var issue: Dictionary = raw_issue
		lines.append(
			"- %s: preserve the explicit concept fact `%s`. %s"
			% [
				str(issue.get("label", "Concept fact")),
				str(issue.get("value", "")),
				str(issue.get("reason", "The generated card did not preserve it clearly."))
			]
		)
	return "\n".join(lines)


static func metadata_report(report: Dictionary, retry_attempts: int) -> Dictionary:
	return {
		"format_version": int(report.get("format_version", FORMAT_VERSION)),
		"checked": bool(report.get("checked", false)),
		"anchor_count": int(report.get("anchor_count", 0)),
		"missing_count": int(report.get("missing_count", 0)),
		"critical_missing_count": int(report.get("critical_missing_count", 0)),
		"advisory_missing_count": int(report.get("advisory_missing_count", 0)),
		"clear_drift": bool(report.get("clear_drift", false)),
		"retry_attempts": retry_attempts,
		"retry_used": retry_attempts > 0,
		"issues": report.get("issues", []).duplicate(true) if report.get("issues", []) is Array else [],
		"summary": str(report.get("summary", ""))
	}


static func _append_age_anchors(anchors: Array[Dictionary], concept: String) -> void:
	var seen: Dictionary = {}
	var patterns := [
		"(?i)\\b([1-9][0-9]{0,2})\\s*[- ]?\\s*years?\\s*[- ]?\\s*old\\b",
		"(?i)\\bage\\s*[:=]?\\s*([1-9][0-9]{0,2})\\b",
		"(?i)\\b([1-9][0-9]{0,2})\\s*(?:yo|y/o)\\b"
	]
	for pattern in patterns:
		var regex := RegEx.new()
		if regex.compile(pattern) != OK:
			continue
		for match_value in regex.search_all(concept):
			var match: RegExMatch = match_value
			var age_text := match.get_string(1)
			if seen.has(age_text):
				continue
			seen[age_text] = true
			var age := int(age_text)
			var variants: Array[String] = [age_text]
			var words := _number_words(age)
			if not words.is_empty():
				variants.append(words)
			anchors.append(
				{
					"kind": "age",
					"label": "Explicit age",
					"value": "%d years old" % age,
					"variants": variants,
					"severity": "critical",
					"retry_on_missing": true
				}
			)


static func _append_cup_size_anchors(anchors: Array[Dictionary], concept: String) -> void:
	var regex := RegEx.new()
	if regex.compile("(?i)\\b([A-K])\\s*[- ]?cup\\b") != OK:
		return
	var seen: Dictionary = {}
	for match_value in regex.search_all(concept):
		var match: RegExMatch = match_value
		var cup := match.get_string(1).to_upper()
		if seen.has(cup):
			continue
		seen[cup] = true
		anchors.append(
			{
				"kind": "measurement",
				"label": "Explicit cup size",
				"value": "%s-cup" % cup,
				"variants": ["%s cup" % cup, "%s-cup" % cup, "%scup" % cup],
				"severity": "critical",
				"retry_on_missing": true
			}
		)


static func _append_advisory_literals(anchors: Array[Dictionary], concept: String) -> void:
	var collected := 0
	for pattern in ['"([^"\\n]{3,48})"', "`([^`\\n]{3,48})`"]:
		var regex := RegEx.new()
		if regex.compile(pattern) != OK:
			continue
		for match_value in regex.search_all(concept):
			if collected >= MAX_ADVISORY_LITERALS:
				return
			var match: RegExMatch = match_value
			var literal := match.get_string(1).strip_edges()
			if literal.is_empty() or literal.contains("{{"):
				continue
			anchors.append(
				{
					"kind": "quoted_literal",
					"label": "Quoted concept marker",
					"value": literal,
					"variants": [literal],
					"severity": "advisory",
					"retry_on_missing": false
				}
			)
			collected += 1


static func _anchor_present(
	anchor: Dictionary,
	candidate: Dictionary,
	candidate_text: String,
	candidate_compact: String
) -> bool:
	var kind := str(anchor.get("kind", "literal"))
	if kind == "name":
		var expected := str(anchor.get("value", "")).strip_edges()
		var generated_name := str(candidate.get("name", "")).strip_edges()
		return _name_matches(expected, generated_name)

	var variants_value: Variant = anchor.get("variants", [str(anchor.get("value", ""))])
	var variants: Array = variants_value if variants_value is Array else []
	var lower_text := candidate_text.to_lower()
	for raw_variant in variants:
		var variant := str(raw_variant).strip_edges()
		if variant.is_empty():
			continue
		if lower_text.contains(variant.to_lower()):
			return true
		var compact_variant := _compact(variant)
		if not compact_variant.is_empty() and candidate_compact.contains(compact_variant):
			return true
	return false


static func _missing_reason(anchor: Dictionary, candidate: Dictionary) -> String:
	var kind := str(anchor.get("kind", "literal"))
	if kind == "name":
		var generated_name := str(candidate.get("name", "")).strip_edges()
		if generated_name.is_empty():
			return "The generated name is empty."
		return "The generated name is `%s`, which does not preserve the supplied name." % generated_name
	if kind == "age":
		return "The explicit numeric age is not clearly preserved anywhere in the generated card."
	if kind == "measurement":
		return "The distinctive explicit measurement is not clearly preserved anywhere in the generated card."
	return "The literal marker is not present in the generated card."


static func _name_matches(expected: String, generated: String) -> bool:
	var clean_expected := expected.strip_edges().to_lower()
	var clean_generated := generated.strip_edges().to_lower()
	if clean_expected.is_empty() or clean_generated.is_empty():
		return false
	if clean_expected == clean_generated:
		return true
	return clean_generated.begins_with(clean_expected + " ")


static func _usable_name(value: String) -> bool:
	var clean := value.strip_edges()
	if clean.is_empty():
		return false
	var lower := clean.to_lower()
	return not (
		lower.begins_with("untitled character")
		or lower == "untitled"
		or lower == "character"
		or lower == "unknown"
	)


static func _flatten_candidate(value: Variant) -> String:
	var parts: Array[String] = []
	_append_value_text(value, parts)
	return "\n".join(parts)


static func _append_value_text(value: Variant, parts: Array[String]) -> void:
	if value == null:
		return
	if value is Dictionary:
		for key in value:
			parts.append(str(key))
			_append_value_text(value.get(key), parts)
		return
	if value is Array:
		for item in value:
			_append_value_text(item, parts)
		return
	parts.append(str(value))


static func _compact(value: String) -> String:
	var lower := value.to_lower()
	var result := ""
	for index in range(lower.length()):
		var code := lower.unicode_at(index)
		if (code >= 48 and code <= 57) or (code >= 97 and code <= 122):
			result += lower.substr(index, 1)
	return result


static func _number_words(value: int) -> String:
	if value < 0 or value > 99:
		return ""
	var ones := [
		"zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
		"ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"
	]
	if value < 20:
		return ones[value]
	var tens := ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
	var tens_value := int(floor(float(value) / 10.0))
	var remainder := value % 10
	if remainder == 0:
		return tens[tens_value]
	return "%s %s" % [tens[tens_value], ones[remainder]]
