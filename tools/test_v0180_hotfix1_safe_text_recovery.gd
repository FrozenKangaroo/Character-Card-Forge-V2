extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0180_HOTFIX1_SAFE_TEXT_RECOVERY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var service := CCFGenerationServiceV0180Hotfix1.new()
	root.add_child(service)
	var first_message_section := {
		"kind": "standalone_field",
		"id": "first_message",
		"title": "First message",
		"field_id": "first_message",
		"field": {
			"id": "first_message",
			"label": "First message",
			"type": "multiline",
			"required": true
		}
	}
	var plain := "Late light crosses the quiet room.\n\n\"You came,\" she says, turning toward {{user}}."
	var recovered := service.recover_safe_text_candidate_v0180_hotfix1(
		first_message_section, plain
	)
	if not _require(
		bool(recovered.get("ok", false))
		and str(recovered.get("value", "")) == plain
		and str(recovered.get("source", "")) == "plain_text",
		"A standalone multiline field must recover usable plain prose."
	):
		return
	var json_string := service.recover_safe_text_candidate_v0180_hotfix1(
		first_message_section, JSON.stringify(plain)
	)
	if not _require(
		bool(json_string.get("ok", false))
		and str(json_string.get("value", "")) == plain
		and str(json_string.get("source", "")) == "json_string",
		"A valid JSON string must be recoverable as the requested text field."
	):
		return
	var fenced := service.recover_safe_text_candidate_v0180_hotfix1(
		first_message_section, "```text\n%s\n```" % plain
	)
	if not _require(
		bool(fenced.get("ok", false))
		and str(fenced.get("value", "")) == plain,
		"A complete plain-text fence must be unwrapped locally."
	):
		return
	var malformed_object := service.recover_safe_text_candidate_v0180_hotfix1(
		first_message_section, '{"first_message":"unfinished}'
	)
	if not _require(
		not bool(malformed_object.get("ok", true)),
		"Malformed object-shaped output must remain on the structural JSON repair path."
	):
		return
	var tags_section := first_message_section.duplicate(true)
	tags_section["field_id"] = "tags"
	tags_section["field"] = {"id": "tags", "type": "tags"}
	var tags_recovery := service.recover_safe_text_candidate_v0180_hotfix1(
		tags_section, "quiet, observant"
	)
	if not _require(
		not bool(tags_recovery.get("ok", true)),
		"Typed arrays must not be guessed from plain text."
	):
		return
	for typed_field in [
		{"id": "enabled", "type": "checkbox", "sample": "yes"},
		{"id": "rating", "type": "number", "sample": "high"},
		{"id": "mood", "type": "select", "sample": "cheerful"}
	]:
		var typed_section := first_message_section.duplicate(true)
		typed_section["field_id"] = str(typed_field.get("id", "field"))
		typed_section["field"] = typed_field.duplicate(true)
		var typed_recovery := service.recover_safe_text_candidate_v0180_hotfix1(
			typed_section, str(typed_field.get("sample", ""))
		)
		if not _require(
			not bool(typed_recovery.get("ok", true)),
			"%s fields must retain strict JSON typing." % str(typed_field.get("type", "Typed"))
		):
			return

	# Reproduce the repair response from the captured failure: the dialogue's
	# closing quote is escaped, but the surrounding JSON string has no closing
	# quote before the root brace.
	var unterminated := '{"first_message":"She turns. \\"You came.\\"}'
	var repaired: String = service.call("_repair_common_json", unterminated)
	var repaired_parser := JSON.new()
	if not _require(
		repaired != unterminated
		and repaired_parser.parse(repaired) == OK
		and str(repaired_parser.data.get("first_message", "")) == 'She turns. "You came."',
		"A single missing outer string quote before the closing brace must repair locally."
	):
		return

	var parallel_holder := {"result": {}}
	service.parallel_safe_section_completed.connect(
		func(
			_worker_id: String,
			_section_index: int,
			_section_id: String,
			result: Dictionary
		):
			parallel_holder["result"] = result.duplicate(true)
	)
	service.set("_parallel_child_mode_v01526", true)
	service.set("_parallel_child_index_v01526", 0)
	service.set("_active_job", {
		"id": "v0180-hotfix1-plain-text",
		"type": "character",
		"safe_stage": "section",
		"safe_active_section": first_message_section.duplicate(true),
		"safe_build_state": {
			"index": 0,
			"plan": [first_message_section.duplicate(true)],
			"accepted_fields": {},
			"accepted_groups": {},
			"completed_sections": [],
			"project": {},
			"generation_template": {}
		},
		"metadata": {},
		"diagnostic_events": []
	})
	service.call("_process_safe_section_v01522", plain)
	var parallel_result: Dictionary = parallel_holder.get("result", {})
	if not _require(
		str(parallel_result.get("accepted_fields", {}).get("first_message", "")) == plain,
		"Plain prose must pass through the existing exact-key acceptance path."
	):
		return

	var repeated := (
		"The same unusually long paragraph repeats an established section and must "
		+ "remain subject to cross-field contamination detection even after local "
		+ "transport recovery. This sentence is extended to exceed the long-content "
		+ "threshold used by the existing Safe Section guard without relying on a model."
	)
	var contamination := service.validate_safe_section_candidate_v01537_hotfix1(
		first_message_section,
		{"first_message": repeated},
		{
			"concept": (
				"## Roleplay Scenario\n"
				+ repeated
				+ "\n\n## Final First Message Text\nA separate opening remains authoritative."
			)
		}
	)
	if not _require(
		not bool(contamination.get("ok", true))
		and not contamination.get("issues", []).is_empty(),
		"Recovered text must still be rejected when it duplicates another long section."
	):
		return

	service.set("_active_job", {
		"safe_stage": "section",
		"safe_active_section": first_message_section.duplicate(true),
		"repair_attempts": 0,
		"payload": {"messages": [{"role": "system", "content": "repair"}, {"role": "user", "content": "generic"}]},
		"diagnostic_events": []
	})
	var started: bool = service.call(
		"_start_json_repair", unterminated, "object"
	)
	var active_job: Dictionary = service.get("_active_job")
	var repair_payload: Dictionary = active_job.get("payload", {})
	var repair_messages: Array = repair_payload.get("messages", [])
	var repair_prompt := str(repair_messages[1].get("content", ""))
	if not _require(
		started
		and repair_prompt.contains('exactly the key "first_message"')
		and repair_prompt.contains("value must be multiline text")
		and str(active_job.get("diagnostics_last_repair", {}).get("exact_expected_shape", "")).contains("first_message"),
		"Remote repair must receive and diagnose the exact standalone field key and type."
	):
		return
	service.set("_active_job", {})
	await process_frame

	service.set("_active_job", {
		"safe_stage": "section",
		"safe_active_section": tags_section.duplicate(true)
	})
	var tags_shape: String = service.call(
		"_exact_safe_repair_shape_v0180_hotfix1", "object"
	)
	var group_section := {
		"kind": "output_group",
		"group": {
			"id": "voice",
			"components": [
				{"id": "speech_style", "enabled": true},
				{"id": "verbal_tics", "enabled": true},
				{"id": "disabled_note", "enabled": false}
			]
		}
	}
	service.set("_active_job", {
		"safe_stage": "section",
		"safe_active_section": group_section
	})
	var group_shape: String = service.call(
		"_exact_safe_repair_shape_v0180_hotfix1", "object"
	)
	if not _require(
		tags_shape.contains('"tags"')
		and tags_shape.contains("array of short strings")
		and group_shape.contains("speech_style")
		and group_shape.contains("verbal_tics")
		and not group_shape.contains("disabled_note"),
		"Typed fields and output groups must receive their own exact repair schemas."
	):
		return
	service.set("_active_job", {})

	var capabilities := service.safe_text_recovery_capabilities_v0180_hotfix1()
	if not _require(
		bool(capabilities.get("standalone_plain_text_wrapper", false))
		and bool(capabilities.get("typed_fields_remain_strict", false))
		and bool(capabilities.get("semantic_validation_retained", false))
		and bool(capabilities.get("contamination_guard_retained", false)),
		"The hotfix capability boundary must remain explicit."
	):
		return
	var parallel_child := service.create_parallel_child_service_v0180_hotfix1()
	if not _require(
		parallel_child is CCFGenerationServiceV0180Hotfix1,
		"Parallel Safe Section workers must use the recovery-aware service."
	):
		return
	parallel_child.free()

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.18.0-hotfix1 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0180View
		and workspace_value.get("_generation_service") is CCFGenerationServiceV0180Hotfix1,
		"The live v0.18.0 workspace must use the Safe Section recovery service."
	):
		return
	app.queue_free()
	service.queue_free()
	await process_frame
	print("v0.18.0-hotfix1 Safe Section text recovery regression passed")
	quit(0)
