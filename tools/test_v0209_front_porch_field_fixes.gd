extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	push_error(message_text)
	print("V0209_FRONT_PORCH_FIX_ERROR: %s" % message_text)
	quit(1)
	return false


func _run() -> void:
	var standard := CCFFrontPorchWorkScheduleV0209.normalise({
		"start": "09:00", "end": "17:00"
	})
	var minutes := CCFFrontPorchWorkScheduleV0209.normalise("09:30–17:15")
	var imported := CCFFrontPorchWorkScheduleV0209.display_parts("9am–5pm")
	var invalid := CCFFrontPorchWorkScheduleV0209.normalise(
		"None — university holiday break"
	)
	if not _require(
		bool(standard.get("ok", false))
		and str(standard.get("value", "")) == "9am–5pm"
		and str(minutes.get("value", "")) == "9:30am–5:15pm"
		and str(imported.get("start", "")) == "09:00"
		and str(imported.get("end", "")) == "17:00"
		and not bool(invalid.get("ok", true)),
		"Work hours must round-trip Front Porch's picker format and reject prose."
	):
		return

	var extension := CCFFrontPorchExtensionServiceCurrent.new()
	var project := CCFStorageService.new_project()
	var character_id := str(project.get("characters", [])[0].get("character_id", ""))
	var document := CCFStorageService.character_workspace_document(
		project, character_id
	)
	var enabled := {
		"fp_work_hours": true,
		"fp_work_days": true
	}
	var applied := extension.apply_control_values(
		document,
		enabled,
		{
			"fp_work_hours": {"start": "09:30", "end": "17:15"},
			"fp_work_days": PackedStringArray(["1", "3", "5"])
		},
		false
	)
	if not _require(
		bool(applied.get("ok", false))
		and CCFStorageService.get_value_at_path(
			document,
			"character.card_extensions.front_porch.realism_engine.hours",
			""
		) == "9:30am–5:15pm"
		and CCFStorageService.get_value_at_path(
			document,
			"character.card_extensions.front_porch.realism_engine.workDays",
			[]
		) == [1, 3, 5],
		"Work Days preview text and separate work times must persist in the canonical extension."
	):
		return

	var generator := CCFGenerationServiceCurrent.new()
	var clean_first_message := (
		"The door opens and Mika grins.\n\n"
		+ "{\"first_message\":\"The door opens and Mika grins again without closing JSON"
	)
	var cleaned := generator.clean_generated_text_v0209(
		"first_message", clean_first_message
	)
	var preserved := generator.clean_generated_text_v0209(
		"scenario", clean_first_message
	)
	if not _require(
		str(cleaned.get("value", "")) == "The door opens and Mika grins."
		and bool(cleaned.get("removed_trailing_wrapper", false))
		and str(preserved.get("value", "")) == clean_first_message,
		"Generated first messages must discard a trailing duplicate JSON wrapper without changing other fields."
	):
		return

	CCFStorageService.set_value_at_path(
		document, "concept.prompt", "A librarian with a fixed weekday schedule."
	)
	var work_hours_field := extension.field_by_id("fp_work_hours")
	var queued := generator.queue_front_porch_fields_v0172(
		document,
		[work_hours_field],
		{
			"name": "Offline regression",
			"base_url": "http://127.0.0.1:1/v1",
			"model": "front-porch-regression",
			"max_output_tokens": 2048
		},
		0,
		"Work hours"
	)
	var queued_jobs_value: Variant = generator.get("_queue")
	var queued_jobs: Array = queued_jobs_value if queued_jobs_value is Array else []
	var queued_job: Dictionary = queued_jobs[0] if not queued_jobs.is_empty() else {}
	var payload_value: Variant = queued_job.get("payload", {})
	var payload: Dictionary = payload_value if payload_value is Dictionary else {}
	var prompt_text := JSON.stringify(payload.get("messages", []))
	if not _require(
		bool(queued.get("ok", false))
		and prompt_text.contains("actual start and end times")
		and prompt_text.contains("9am–5pm")
		and prompt_text.contains("Do not describe holidays"),
		"Work-hours generation must request Front Porch clock values instead of prose."
	):
		return
	generator.free()

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceCurrent,
		"The live shell must install the current v0.20.9 workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceCurrent
	workspace.load_project(
		project, CCFTemplateService.load_template("default"), {}
	)
	await process_frame
	var start_edit := workspace.find_child("WorkHoursStartV0209", true, false) as LineEdit
	var end_edit := workspace.find_child("WorkHoursEndV0209", true, false) as LineEdit
	if not _require(
		start_edit != null and end_edit != null,
		"Work hours must render as separate Start and End controls."
	):
		return

	workspace.call(
		"_show_generation_preview",
		{"fp_work_days": [2, 4, 6]},
		{
			"project_id": str(workspace.get("_project").get("project_id", "")),
			"field_ids": ["fp_work_days"],
			"preview_fields": [extension.field_by_id("fp_work_days")],
			"front_porch_generation_contract": 1,
			"front_porch_scope": "Work days",
			"output_policy": {"unexpected_fields": "ignore"}
		},
		"Front Porch — Work days"
	)
	var preview_rows_value: Variant = workspace.get("_preview_rows")
	var preview_rows: Array = (
		preview_rows_value if preview_rows_value is Array else []
	)
	if not _require(
		preview_rows.size() == 1 and preview_rows[0].get("editor") is LineEdit,
		"Generated Work Days must remain an editable one-line preview."
	):
		return
	workspace.call("_apply_preview")
	var live_document: Dictionary = workspace.get("_project")
	if not _require(
		CCFStorageService.get_value_at_path(
			live_document,
			"character.card_extensions.front_porch.realism_engine.workDays",
			[]
		) == [2, 4, 6],
		"Applying a Work Days preview must immediately fill the Front Porch field."
	):
		return

	var select_all := workspace.find_child(
		"FrontPorchSelectAll_character_life_V0209", true, false
	) as Button
	if not _require(
		select_all != null,
		"Every Front Porch group must expose a Select All Fields action."
	):
		return
	select_all.pressed.emit()
	var selected_map: Dictionary = workspace.call(
		"_front_porch_enabled_map_v0172"
	)
	for field in extension.fields_for_group("character_life"):
		if bool(field.get("adult", false)):
			continue
		if not _require(
			bool(selected_map.get(str(field.get("id", "")), false)),
			"Select All Fields must select every visible non-adult field in the tab."
		):
			return
	app.queue_free()
	await process_frame
	print("V0209_FRONT_PORCH_FIX_OK")
	quit(0)
