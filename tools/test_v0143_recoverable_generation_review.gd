extends SceneTree

var _completed := false
var _failed := false
var _completed_data: Variant = null
var _completed_metadata: Dictionary = {}


func _init() -> void:
	var service := CCFGenerationServiceV0143.new()
	root.add_child(service)
	service.job_completed.connect(_on_completed)
	service.job_failed.connect(_on_failed)

	var contract := {
		"format_version": 3,
		"template_id": "test",
		"required_fields": [
			{"id": "name", "label": "Name", "type": "line"},
			{"id": "personality", "label": "Personality", "type": "multiline"}
		],
		"field_rules": {
			"personality": {"minimum_characters": 120}
		}
	}
	service._active_job = {
		"id": "recoverable-review-test",
		"type": "character",
		"label": "Full character generation",
		"parse_mode": "object",
		"attempt": 2,
		"repair_attempts": 0,
		"semantic_repair_attempts": 1,
		"model": "test-model",
		"profile_name": "Test profile",
		"metadata": {
			"project_id": "test-project",
			"field_ids": ["name", "personality"],
			"generation_contract": contract,
			"generation_contract_attached": true,
			"output_policy": {"mode": "strict", "unexpected_fields": "ignore"}
		}
	}

	var candidate := {
		"name": "Rina",
		"personality": "Bright, stubborn, affectionate, and competitive."
	}
	service._process_completed_content(JSON.stringify(candidate))

	assert(_completed, "A parseable candidate must complete into Preview after review still fails post-repair.")
	assert(not _failed, "Recoverable contract review failure must not emit job_failed.")
	assert(_completed_data is Dictionary, "Recovered generation must preserve the generated dictionary.")
	assert(_completed_data.get("name", "") == "Rina", "Recovered generation changed usable candidate data.")
	var recovery_value: Variant = _completed_metadata.get("review_recovery", {})
	assert(recovery_value is Dictionary, "Recoverable review metadata was not attached.")
	assert(bool(recovery_value.get("recoverable", false)), "Recovery metadata must identify the candidate as recoverable.")
	assert(int(recovery_value.get("issue_count", 0)) >= 1, "Review diagnostics must preserve validation issues.")
	assert(not bool(_completed_metadata.get("template_contract_blocked_preview", true)), "Recoverable review output must not block Preview.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0143.gd")
	assert(workspace_source.contains("Review found issues — generated data was not discarded"), "Preview warning UI is missing.")
	assert(workspace_source.contains("AI Suggest"), "Preview recovery guidance must point to the existing field-level AI Suggest workflow.")

	service.queue_free()
	print("v0.14.3 recoverable generation review regression passed")
	quit(0)


func _on_completed(_job_id: String, _job_type: String, data: Variant, metadata: Dictionary) -> void:
	_completed = true
	_completed_data = data
	_completed_metadata = metadata.duplicate(true)


func _on_failed(_job_id: String, _job_type: String, _message: String) -> void:
	_failed = true
