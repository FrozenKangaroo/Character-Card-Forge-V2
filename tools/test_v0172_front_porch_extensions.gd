extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0172_FRONT_PORCH_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var service := CCFFrontPorchExtensionServiceV0172.new()
	var capabilities := service.capabilities()
	if not _require(
		str(capabilities.get("front_porch_extension_version", "")) == "2.5"
		and int(capabilities.get("group_count", 0)) == 4
		and int(capabilities.get("field_count", 0)) >= 50
		and bool(capabilities.get("unknown_field_round_trip", false))
		and not bool(capabilities.get("raw_database_writes", true)),
		"The catalog must expose the complete optional Front Porch 2.5 authoring boundary."
	):
		return

	var clean_project := CCFStorageService.new_project()
	var clean_id := CCFStorageService.active_character_id(clean_project)
	var clean_document := CCFStorageService.character_workspace_document(
		clean_project, clean_id
	)
	var empty_enabled: Dictionary = {}
	var default_values: Dictionary = {}
	for field in service.all_fields():
		var field_id := str(field.get("id", ""))
		empty_enabled[field_id] = false
		default_values[field_id] = field.get("default", "")
	var clean_result := service.apply_control_values(
		clean_document, empty_enabled, default_values, false
	)
	if not _require(
		bool(clean_result.get("ok", false))
		and not bool(clean_result.get("has_extension", true))
		and not _path_exists(
			clean_document, "character.card_extensions.front_porch"
		),
		"Leaving every optional field unset must not emit a Front Porch extension."
	):
		return

	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(
		project, character_id
	)
	CCFStorageService.set_value_at_path(document, "concept.prompt", "A night librarian who protects a supernatural archive.")
	CCFStorageService.set_value_at_path(
		document,
		"character.card_extensions.front_porch",
		{
			"version": "3.0-future",
			"realism_engine": {
				"future_metric": 17,
				"intimate_preferences": {
					"into": ["gentle teasing"],
					"future_boundary_mode": "preserve"
				}
			},
			"future_top_level": {"enabled": true}
		}
	)
	CCFStorageService.set_value_at_path(document, "character.tts_voice", "porch-voice-17")
	var enabled := _included_map(service, document)
	enabled["fp_ambitions"] = true
	enabled["fp_work_days"] = true
	enabled["fp_birthday"] = true
	var values := _value_map(service, document)
	values["fp_ambitions"] = ["keep the archive safe", "identify the midnight visitor"]
	values["fp_work_days"] = [1, 3, 5]
	values["fp_birthday"] = "1990-10-12"
	var apply_result := service.apply_control_values(
		document, enabled, values, false
	)
	if not _require(
		bool(apply_result.get("ok", false)),
		"Valid manual Front Porch values must apply cleanly."
	):
		return
	var extension_value: Variant = CCFStorageService.get_value_at_path(
		document, "character.card_extensions.front_porch", {}
	)
	var extension: Dictionary = extension_value if extension_value is Dictionary else {}
	var realism_value: Variant = extension.get("realism_engine", {})
	var realism: Dictionary = realism_value if realism_value is Dictionary else {}
	var intimate_value: Variant = realism.get("intimate_preferences", {})
	var intimate: Dictionary = intimate_value if intimate_value is Dictionary else {}
	if not _require(
		str(extension.get("version", "")) == "3.0-future"
		and int(realism.get("future_metric", 0)) == 17
		and str(intimate.get("future_boundary_mode", "")) == "preserve"
		and intimate.get("into", []) == ["gentle teasing"]
		and realism.get("ambitions", []) == [
			"keep the archive safe", "identify the midnight visitor"
		]
		and realism.get("workDays", []) == [1, 3, 5],
		"Known edits must preserve future extension versions, unknown keys and hidden adult data."
	):
		return
	CCFStorageService.set_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine.greeting_seeds",
		[{"future_seed_key": "keep", "character_emotion": "watchful"}]
	)
	var seed_enabled := {"seed_character_emotion": true, "seed_trust_level": true}
	var seed_values := {"seed_character_emotion": "quietly delighted", "seed_trust_level": 7}
	var seed_result := service.apply_greeting_seed_values(
		document, 0, true, seed_enabled, seed_values
	)
	var greeting_seeds := service.greeting_seeds(document)
	var first_seed: Dictionary = (
		greeting_seeds[0] as Dictionary
		if not greeting_seeds.is_empty() and greeting_seeds[0] is Dictionary
		else {}
	)
	if not _require(
		bool(seed_result.get("ok", false))
		and str(first_seed.get("future_seed_key", "")) == "keep"
		and str(first_seed.get("character_emotion", "")) == "quietly delighted"
		and int(first_seed.get("trust_level", 0)) == 7,
		"Per-alternative greeting seeds must be sparse, editable and future-field preserving."
	):
		return
	CCFStorageService.set_value_at_path(
		document, "character.alternate_greetings", ["A second archive opening."]
	)

	var invalid_enabled := _included_map(service, document)
	var invalid_values := _value_map(service, document)
	invalid_enabled["fp_birthday"] = true
	invalid_values["fp_birthday"] = "2024-02-29"
	var invalid_result := service.apply_control_values(
		document, invalid_enabled, invalid_values, false
	)
	if not _require(
		not bool(invalid_result.get("ok", true))
		and "; ".join(invalid_result.get("errors", [])).contains("February 29"),
		"Invalid Front Porch dates must be reported instead of silently accepted."
	):
		return

	CCFStorageService.update_character(project, document)
	var card := CCFCardFormatService.export_character_v2(project, character_id)
	var data_value: Variant = card.get("data", {})
	var data: Dictionary = data_value if data_value is Dictionary else {}
	if not _require(
		str(data.get("tts_voice", "")) == "porch-voice-17"
		and _path_exists(data, "extensions.front_porch.realism_engine.future_metric"),
		"Character Card V2 export must carry TTS and Front Porch extension data."
	):
		return
	var imported := CCFCardFormatService.import_card_to_project(card, "json")
	if not _require(
		bool(imported.get("ok", false)),
		"The exported Front Porch-enabled card must import again."
	):
		return
	var imported_project: Dictionary = imported.get("project", {})
	var imported_id := CCFStorageService.active_character_id(imported_project)
	var reexported := CCFCardFormatService.export_character_v2(
		imported_project, imported_id
	)
	if not _require(
		_path_exists(
			reexported, "data.extensions.front_porch.realism_engine.future_metric"
		)
		and str(
			CCFStorageService.get_value_at_path(
				CCFStorageService.get_character(imported_project, imported_id),
				"character.tts_voice",
				""
			)
		) == "porch-voice-17",
		"Front Porch and TTS data must survive a complete card import/export round trip."
	):
		return

	var generator := CCFGenerationServiceV0172.new()
	var life_fields := service.fields_for_group("character_life")
	var ai_fields: Array[Dictionary] = []
	for field in life_fields:
		if str(field.get("id", "")) in ["fp_ambitions", "fp_likes"]:
			ai_fields.append(field)
	var queue_result := generator.queue_front_porch_fields_v0172(
		document,
		ai_fields,
		{
			"name": "Offline regression",
			"base_url": "http://127.0.0.1:1/v1",
			"model": "front-porch-regression",
			"max_output_tokens": 2048
		},
		0,
		"Character Life"
	)
	var queued_value: Variant = generator.get("_queue")
	var queued: Array = queued_value if queued_value is Array else []
	var queued_job: Dictionary = queued[0] if not queued.is_empty() else {}
	var metadata_value: Variant = queued_job.get("metadata", {})
	var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
	var payload_value: Variant = queued_job.get("payload", {})
	var payload: Dictionary = payload_value if payload_value is Dictionary else {}
	var prompt_text := JSON.stringify(payload.get("messages", []))
	if not _require(
		bool(queue_result.get("ok", false))
		and str(queued_job.get("type", "")) == "front_porch_fields"
		and metadata.get("field_ids", []) == ["fp_ambitions", "fp_likes"]
		and metadata.get("preview_fields", []).size() == 2
		and prompt_text.contains("Never invent durable history")
		and prompt_text.contains("review screen"),
		"Front Porch AI generation must be scoped, agency-safe and review-first."
	):
		return
	generator.free()

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.17.2 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(
		app.has_method("_update_build_version_label_v0172"),
		"The active application shell must identify v0.17.2."
	):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0172View,
		"The application must install the v0.17.2 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0172View
	workspace.load_project(
		project,
		CCFTemplateService.load_template("default"),
		{}
	)
	await process_frame
	var workspace_capabilities := workspace.front_porch_capabilities_v0172()
	if not _require(
		bool(workspace_capabilities.get("workspace_tab", false))
		and int(workspace_capabilities.get("group_tabs", 0)) == 4
		and bool(workspace_capabilities.get("alternative_greeting_seeds", false))
		and bool(workspace_capabilities.get("manual_authoring", false))
		and bool(workspace_capabilities.get("selective_ai_review", false))
		and bool(workspace_capabilities.get("generation_service", false))
		and not bool(workspace_capabilities.get("direct_sqlite_writes", true)),
		"The live Workspace must expose optional manual and AI-assisted Front Porch authoring without SQLite access."
	):
		return
	var preview_fields: Array[Dictionary] = [
		service.field_by_id("fp_ambitions"),
		service.field_by_id("fp_birthday")
	]
	workspace.call(
		"_show_generation_preview",
		{
			"fp_ambitions": ["catalogue the impossible annex"],
			"fp_birthday": "2024-02-29"
		},
		{
			"project_id": str(workspace.get("_project").get("project_id", "")),
			"field_ids": ["fp_ambitions", "fp_birthday"],
			"preview_fields": preview_fields,
			"front_porch_generation_contract": 1,
			"front_porch_scope": "Regression Preview",
			"output_policy": {"unexpected_fields": "ignore"}
		},
		"Front Porch — Regression Preview"
	)
	workspace.call("_apply_preview")
	var captured_project := workspace.current_project()
	var captured_id := CCFStorageService.active_character_id(captured_project)
	var captured_character := CCFStorageService.get_character(
		captured_project, captured_id
	)
	if not _require(
		CCFStorageService.get_value_at_path(
			captured_character,
			"character.card_extensions.front_porch.realism_engine.workDays",
			[]
		) == [1, 3, 5]
		and CCFStorageService.get_value_at_path(
			captured_character,
			"character.card_extensions.front_porch.realism_engine.ambitions",
			[]
		) == ["catalogue the impossible annex"]
		and str(
			CCFStorageService.get_value_at_path(
				captured_character,
				"character.card_extensions.front_porch.realism_engine.birthday",
				""
			)
		) == "1990-10-12"
		and _path_exists(
			captured_character,
			"character.card_extensions.front_porch.realism_engine.greeting_seeds"
		),
		"Live Workspace review must apply valid proposals, reject invalid dates, and keep typed work days and greeting seeds."
	):
		return
	app.queue_free()
	await process_frame
	print("v0.17.2 Front Porch character extensions regression passed")
	quit(0)


func _included_map(
	service: CCFFrontPorchExtensionServiceV0172, document: Dictionary
) -> Dictionary:
	var result: Dictionary = {}
	for field in service.all_fields():
		result[str(field.get("id", ""))] = service.is_included(document, field)
	return result


func _value_map(
	service: CCFFrontPorchExtensionServiceV0172, document: Dictionary
) -> Dictionary:
	var result: Dictionary = {}
	for field in service.all_fields():
		result[str(field.get("id", ""))] = service.value_for(document, field)
	return result


func _path_exists(data: Dictionary, path: String) -> bool:
	var current: Variant = data
	for part in path.split(".", false):
		if not current is Dictionary or not (current as Dictionary).has(part):
			return false
		current = (current as Dictionary).get(part)
	return true
