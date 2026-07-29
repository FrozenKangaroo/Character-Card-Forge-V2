extends SceneTree


func _init() -> void:
	var failures: Array[String] = []

	var planning := CCFGenerationDiagnosticsService.stage_for_label("Planning character interview")
	_expect(int(planning.get("index", 0)) == 1, "planning stage should be 1/6", failures)
	var fidelity := CCFGenerationDiagnosticsService.stage_for_label("Correcting concept drift")
	_expect(str(fidelity.get("id", "")) == "fidelity", "concept drift retry should map to fidelity stage", failures)
	var repair := CCFGenerationDiagnosticsService.stage_for_label("Repairing incomplete character generation")
	_expect(int(repair.get("index", 0)) == 5, "semantic repair should be stage 5/6", failures)

	var metadata := {
		"generation_interview": {
			"used": true,
			"question_count": 4,
			"answered_count": 4,
			"manual_answer_count": 1,
			"ai_answer_count": 3,
			"missing_answer_retries": 1,
			"uses_default_questions": true
		},
		"builder_context": {"used": true, "field_count": 3, "step_count": 2},
		"planning_precedence": {"version": 1},
		"mode_style": {
			"generation_mode": "full",
			"writing_style": "balanced",
			"first_message_style": "cinematic",
			"first_message_length": "detailed",
			"custom_instructions": false
		},
		"generation_contract_report": {"ok": true},
		"semantic_repair_attempts": 1,
		"concept_fidelity": {
			"checked": true,
			"anchor_count": 2,
			"retry_attempts": 1,
			"remaining_clear_drift": false
		},
		"parse_strategy": "direct",
		"response_repair_attempts": 0
	}
	var text := CCFGenerationDiagnosticsService.preview_text(metadata)
	_expect(text.contains("Planning interview"), "preview should mention interview participation", failures)
	_expect(text.contains("Builder guidance"), "preview should mention Builder participation", failures)
	_expect(text.contains("Mode & Style"), "preview should mention Mode & Style", failures)
	_expect(text.contains("Template validation: passed"), "preview should report contract validation", failures)
	_expect(text.contains("Concept fidelity: passed"), "preview should report fidelity result", failures)
	_expect(not text.contains("SOURCE CONCEPT"), "diagnostics must not expose private planning scratchpad", failures)

	if failures.is_empty():
		print("generation diagnostics regression: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
