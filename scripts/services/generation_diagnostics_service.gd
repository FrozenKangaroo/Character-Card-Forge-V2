class_name CCFGenerationDiagnosticsService
extends RefCounted

const TOTAL_STAGES := 6


static func stage_for_label(active_label: String) -> Dictionary:
	var clean := active_label.strip_edges().to_lower()
	if clean.contains("interview") or clean.contains("planning"):
		return {"id": "planning", "index": 1, "label": "Planning"}
	if clean.contains("repairing incomplete") or clean.contains("repairing"):
		return {"id": "repair", "index": 5, "label": "Repairing"}
	if clean.contains("concept drift") or clean.contains("fidelity"):
		return {"id": "fidelity", "index": 4, "label": "Fidelity check"}
	if clean.contains("validat") or clean.contains("contract"):
		return {"id": "validation", "index": 3, "label": "Validating"}
	if clean.contains("full character") or clean.contains("generat"):
		return {"id": "generation", "index": 2, "label": "Generating"}
	return {"id": "generation", "index": 2, "label": "Generating"}


static func progress_text(active_label: String, pending_count: int) -> String:
	if active_label.strip_edges().is_empty():
		return "AI queue: idle" if pending_count <= 0 else "AI queue: %d waiting" % pending_count
	var stage := stage_for_label(active_label)
	var text := "Stage %d/%d • %s • %s" % [
		int(stage.get("index", 2)),
		TOTAL_STAGES,
		str(stage.get("label", "Generating")),
		active_label.strip_edges()
	]
	if pending_count > 0:
		text += " • %d queued" % pending_count
	return text


static func preview_lines(metadata: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	_append_interview(lines, metadata)
	_append_builder(lines, metadata)
	_append_mode_style(lines, metadata)
	_append_validation(lines, metadata)
	_append_fidelity(lines, metadata)
	_append_json_repair(lines, metadata)
	return lines


static func preview_text(metadata: Dictionary) -> String:
	var lines := preview_lines(metadata)
	if lines.is_empty():
		return "No additional generation diagnostics were recorded for this result."
	return "Generation checks\n" + "\n".join(lines)


static func _append_interview(lines: Array[String], metadata: Dictionary) -> void:
	var value: Variant = metadata.get("generation_interview", {})
	if not value is Dictionary:
		return
	var report: Dictionary = value
	if not bool(report.get("used", false)):
		lines.append("• Planning interview: not used")
		return
	var source := "bundled default" if bool(report.get("uses_default_questions", false)) else "template-defined"
	lines.append(
		"• Planning interview: %d/%d answered (%d manual, %d AI; %d retry%s; %s)"
		% [
			int(report.get("answered_count", 0)),
			int(report.get("question_count", 0)),
			int(report.get("manual_answer_count", 0)),
			int(report.get("ai_answer_count", 0)),
			int(report.get("missing_answer_retries", 0)),
			"" if int(report.get("missing_answer_retries", 0)) == 1 else "s",
			source
		]
	)


static func _append_builder(lines: Array[String], metadata: Dictionary) -> void:
	var value: Variant = metadata.get("builder_context", {})
	if not value is Dictionary:
		return
	var report: Dictionary = value
	if bool(report.get("used", false)):
		lines.append(
			"• Builder guidance: used (%d field%s across %d step%s)"
			% [
				int(report.get("field_count", 0)),
				"" if int(report.get("field_count", 0)) == 1 else "s",
				int(report.get("step_count", 0)),
				"" if int(report.get("step_count", 0)) == 1 else "s"
			]
		)
	else:
		lines.append("• Builder guidance: not used")

	var precedence_value: Variant = metadata.get("planning_precedence", {})
	if precedence_value is Dictionary and not precedence_value.is_empty():
		lines.append("• Planning precedence: concept → manual Q&A → Builder → AI interview → existing values")


static func _append_mode_style(lines: Array[String], metadata: Dictionary) -> void:
	var value: Variant = metadata.get("mode_style", {})
	if not value is Dictionary:
		return
	var report: Dictionary = value
	if report.is_empty():
		return
	var custom_suffix := " • custom greeting instructions" if bool(report.get("custom_instructions", false)) else ""
	lines.append(
		"• Mode & Style: %s • %s • %s • %s%s"
		% [
			_title_case_id(str(report.get("generation_mode", "full"))),
			_title_case_id(str(report.get("writing_style", "balanced"))),
			_title_case_id(str(report.get("first_message_style", "cinematic"))),
			_title_case_id(str(report.get("first_message_length", "detailed"))),
			custom_suffix
		]
	)


static func _append_validation(lines: Array[String], metadata: Dictionary) -> void:
	var value: Variant = metadata.get("generation_contract_report", {})
	if not value is Dictionary:
		return
	var report: Dictionary = value
	var passed := bool(report.get("ok", false))
	var semantic_attempts := int(metadata.get("semantic_repair_attempts", 0))
	if passed:
		lines.append(
			"• Template validation: passed%s"
			% (" after %d semantic repair pass%s" % [semantic_attempts, "" if semantic_attempts == 1 else "es"] if semantic_attempts > 0 else " without semantic repair")
		)
	else:
		lines.append("• Template validation: remaining contract issues were recorded")


static func _append_fidelity(lines: Array[String], metadata: Dictionary) -> void:
	var value: Variant = metadata.get("concept_fidelity", {})
	if not value is Dictionary:
		return
	var report: Dictionary = value
	if not bool(report.get("checked", false)):
		return
	var retry_attempts := int(report.get("retry_attempts", 0))
	var remaining := bool(report.get("remaining_clear_drift", report.get("clear_drift", false)))
	var result_text := "passed" if not remaining else "completed with remaining clear drift"
	lines.append(
		"• Concept fidelity: %s (%d anchor%s checked; %d retry%s)"
		% [
			result_text,
			int(report.get("anchor_count", 0)),
			"" if int(report.get("anchor_count", 0)) == 1 else "s",
			retry_attempts,
			"" if retry_attempts == 1 else "s"
		]
	)


static func _append_json_repair(lines: Array[String], metadata: Dictionary) -> void:
	var repair_attempts := int(metadata.get("response_repair_attempts", 0))
	var parse_strategy := str(metadata.get("parse_strategy", "direct"))
	if repair_attempts > 0:
		lines.append("• Response parsing: %d JSON repair pass%s used" % [repair_attempts, "" if repair_attempts == 1 else "es"])
	elif parse_strategy == "local_json_repair":
		lines.append("• Response parsing: minor JSON issues repaired locally")
	else:
		lines.append("• Response parsing: direct JSON")


static func _title_case_id(value: String) -> String:
	var clean := value.strip_edges().replace("_", " ")
	if clean.is_empty():
		return "Default"
	var words := clean.split(" ", false)
	var result: Array[String] = []
	for raw_word in words:
		var word := str(raw_word)
		result.append(word.substr(0, 1).to_upper() + word.substr(1))
	return " ".join(result)
