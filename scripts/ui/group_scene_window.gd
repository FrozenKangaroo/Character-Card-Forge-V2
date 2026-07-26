class_name CCFGroupSceneWindow
extends Window

signal project_refresh_requested
signal result_apply_requested(
	shared_context: Dictionary, character_scenarios: Dictionary, metadata: Dictionary
)

var _generation_service: CCFGenerationService
var _project: Dictionary = {}
var _settings: Dictionary = {}
var _project_id := ""
var _job_id := ""
var _character_checks: Dictionary = {}
var _instructions: TextEdit
var _generate_button: Button
var _status: Label
var _project_summary: Label
var _character_box: VBoxContainer
var _result_root: VBoxContainer
var _shared_result_rows: Dictionary = {}
var _character_result_rows: Dictionary = {}
var _result_metadata: Dictionary = {}


func _ready() -> void:
	visible = false
	title = "Group Scene Generator"
	size = Vector2i(1120, 820)
	min_size = Vector2i(820, 600)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(_hide_window)
	_build_ui()
	hide()


func set_generation_service(service: CCFGenerationService) -> void:
	_generation_service = service


func open_for_project(project: Dictionary, settings: Dictionary) -> void:
	_project = project.duplicate(true)
	_settings = settings.duplicate(true)
	_project_id = str(project.get("project_id", ""))
	_result_metadata.clear()
	_rebuild_character_selection()
	_clear_results()
	_project_summary.text = _project_summary_text()
	_status.text = "Select at least two characters, then generate a shared scene setup."
	CCFToolWindowStateService.show_window(self, "group_scene_generator", Vector2i(1120, 820))


func update_project_context(project: Dictionary, settings: Dictionary) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	_project = project.duplicate(true)
	_settings = settings.duplicate(true)
	_project_summary.text = _project_summary_text()
	_rebuild_character_selection()


func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and _project_id == project_id


func release_project() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "group_scene_generator")
	hide()
	_project.clear()
	_project_id = ""
	_job_id = ""
	_result_metadata.clear()


func handle_job_completed(job_id: String, data: Variant, metadata: Dictionary) -> bool:
	if job_id != _job_id:
		return false
	_job_id = ""
	_generate_button.disabled = false
	if str(metadata.get("project_id", "")) != _project_id:
		_status.text = "Result discarded because a different project is now active."
		return true
	if not data is Dictionary:
		_status.text = "The group-scene response was not a JSON object."
		return true
	_result_metadata = metadata.duplicate(true)
	_render_results(data)
	return true


func handle_job_failed(job_id: String, message: String) -> bool:
	if job_id != _job_id:
		return false
	_job_id = ""
	_generate_button.disabled = false
	_status.text = message
	return true


func handle_job_cancelled(job_id: String) -> bool:
	if job_id != _job_id:
		return false
	_job_id = ""
	_generate_button.disabled = false
	_status.text = "Group scene generation cancelled."
	return true


func save_window_state() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "group_scene_generator")


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	_project_summary = Label.new()
	_project_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_project_summary)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)

	var setup_panel := PanelContainer.new()
	setup_panel.custom_minimum_size.x = 390
	split.add_child(setup_panel)
	var setup_margin := MarginContainer.new()
	setup_margin.add_theme_constant_override("margin_left", 14)
	setup_margin.add_theme_constant_override("margin_right", 14)
	setup_margin.add_theme_constant_override("margin_top", 14)
	setup_margin.add_theme_constant_override("margin_bottom", 14)
	setup_panel.add_child(setup_margin)
	var setup := VBoxContainer.new()
	setup.add_theme_constant_override("separation", 10)
	setup_margin.add_child(setup)

	var character_title := Label.new()
	character_title.text = "Characters in this generation"
	character_title.add_theme_font_size_override("font_size", 18)
	setup.add_child(character_title)

	var select_actions := HBoxContainer.new()
	select_actions.add_theme_constant_override("separation", 8)
	setup.add_child(select_actions)
	var select_all := Button.new()
	select_all.text = "Select All"
	select_all.pressed.connect(_set_all_characters_selected.bind(true))
	select_actions.add_child(select_all)
	var select_none := Button.new()
	select_none.text = "Clear"
	select_none.pressed.connect(_set_all_characters_selected.bind(false))
	select_actions.add_child(select_none)

	var character_scroll := ScrollContainer.new()
	character_scroll.custom_minimum_size.y = 190
	character_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup.add_child(character_scroll)
	_character_box = VBoxContainer.new()
	_character_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_box.add_theme_constant_override("separation", 5)
	character_scroll.add_child(_character_box)

	var instructions_label := Label.new()
	instructions_label.text = "Optional generation instructions"
	setup.add_child(instructions_label)
	_instructions = TextEdit.new()
	_instructions.placeholder_text = "Example: tense first meeting in a stranded orbital station; keep the tone serious but allow dry humour."
	_instructions.custom_minimum_size.y = 140
	_instructions.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	setup.add_child(_instructions)

	_generate_button = Button.new()
	_generate_button.text = "Generate Shared Group Scene"
	_generate_button.pressed.connect(_generate_scene)
	setup.add_child(_generate_button)

	var result_panel := PanelContainer.new()
	result_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(result_panel)
	var result_margin := MarginContainer.new()
	result_margin.add_theme_constant_override("margin_left", 14)
	result_margin.add_theme_constant_override("margin_right", 14)
	result_margin.add_theme_constant_override("margin_top", 14)
	result_margin.add_theme_constant_override("margin_bottom", 14)
	result_panel.add_child(result_margin)
	var result_column := VBoxContainer.new()
	result_column.add_theme_constant_override("separation", 10)
	result_margin.add_child(result_column)

	var result_title := Label.new()
	result_title.text = "Generated Proposal"
	result_title.add_theme_font_size_override("font_size", 18)
	result_column.add_child(result_title)

	var result_hint := Label.new()
	result_hint.text = "Nothing is applied automatically. Review and edit the proposed shared context and per-character scenarios first."
	result_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_hint.modulate = Color(0.67, 0.7, 0.8)
	result_column.add_child(result_hint)

	var result_scroll := ScrollContainer.new()
	result_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_column.add_child(result_scroll)
	_result_root = VBoxContainer.new()
	_result_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_root.add_theme_constant_override("separation", 10)
	result_scroll.add_child(_result_root)

	var apply_button := Button.new()
	apply_button.text = "Apply Selected Proposal"
	apply_button.pressed.connect(_apply_results)
	result_column.add_child(apply_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.66, 0.7, 0.82)
	root.add_child(_status)


func _rebuild_character_selection() -> void:
	var previous_selection: Dictionary = {}
	for character_id in _character_checks:
		var previous_check: CheckBox = _character_checks[character_id]
		previous_selection[character_id] = previous_check.button_pressed
	_clear_children(_character_box)
	_character_checks.clear()
	for summary in CCFStorageService.project_character_summaries(_project):
		var character_id := str(summary.get("character_id", ""))
		var checkbox := CheckBox.new()
		var role := str(summary.get("role", "")).strip_edges()
		checkbox.text = str(summary.get("name", "Untitled Character"))
		if not role.is_empty():
			checkbox.text += " — %s" % role
		checkbox.button_pressed = bool(previous_selection.get(character_id, true))
		_character_box.add_child(checkbox)
		_character_checks[character_id] = checkbox


func _set_all_characters_selected(selected: bool) -> void:
	for character_id in _character_checks:
		var checkbox: CheckBox = _character_checks[character_id]
		checkbox.button_pressed = selected


func _selected_character_ids() -> Array[String]:
	var selected_ids: Array[String] = []
	for character_id in _character_checks:
		var checkbox: CheckBox = _character_checks[character_id]
		if checkbox.button_pressed:
			selected_ids.append(str(character_id))
	return selected_ids


func _generate_scene() -> void:
	project_refresh_requested.emit()
	if _generation_service == null:
		_status.text = "The AI generation service is unavailable."
		return
	var selected_ids := _selected_character_ids()
	if selected_ids.size() < 2:
		_status.text = "Select at least two characters for a group-scene generation."
		return
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var generation_settings = _settings.get("generation", {})
	var retry_count := 1
	if generation_settings is Dictionary:
		retry_count = int(generation_settings.get("retry_count", 1))
	var result := _generation_service.queue_group_scene_generation(
		_project, selected_ids, _instructions.text, profile, retry_count
	)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not queue group scene generation."))
		return
	_job_id = str(result.get("job_id", ""))
	_generate_button.disabled = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = (
		"Group scene generation queued%s."
		% (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
	)


func _render_results(data: Dictionary) -> void:
	_clear_results()
	var shared_context = data.get("shared_context", {})
	if shared_context is Dictionary:
		var heading := Label.new()
		heading.text = "Shared project context"
		heading.add_theme_font_size_override("font_size", 17)
		_result_root.add_child(heading)
		for field_id in ["title", "premise", "setting", "situation", "shared_rules", "notes"]:
			if not shared_context.has(field_id):
				continue
			_add_shared_result_row(field_id, str(shared_context.get(field_id, "")))

	var character_results = data.get("characters", [])
	if character_results is Array and not character_results.is_empty():
		var character_heading := Label.new()
		character_heading.text = "Per-character scenario suggestions"
		character_heading.add_theme_font_size_override("font_size", 17)
		_result_root.add_child(character_heading)
		for item in character_results:
			if not item is Dictionary:
				continue
			var character_id := str(item.get("character_id", ""))
			if CCFStorageService.character_index(_project, character_id) < 0:
				continue
			var scenario := str(item.get("scenario", "")).strip_edges()
			if scenario.is_empty():
				continue
			_add_character_result_row(character_id, scenario)

	if _shared_result_rows.is_empty() and _character_result_rows.is_empty():
		_status.text = "The AI response contained no usable shared context or character scenarios."
		return
	_status.text = "Generation finished. Review, edit, and choose what to apply."


func _add_shared_result_row(field_id: String, value: String) -> void:
	var labels := {
		"title": "Scene / Context Title",
		"premise": "Premise",
		"setting": "Setting",
		"situation": "Current Situation",
		"shared_rules": "Shared Rules / Constraints",
		"notes": "Project Notes"
	}
	var panel := PanelContainer.new()
	_result_root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	var checkbox := CheckBox.new()
	checkbox.text = str(labels.get(field_id, field_id.capitalize()))
	checkbox.button_pressed = true
	content.add_child(checkbox)
	var editor: Control
	if field_id == "title":
		var line_edit := LineEdit.new()
		line_edit.text = value
		content.add_child(line_edit)
		editor = line_edit
	else:
		var text_edit := TextEdit.new()
		text_edit.text = value
		text_edit.custom_minimum_size.y = 110
		text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		content.add_child(text_edit)
		editor = text_edit
	_shared_result_rows[field_id] = {"checkbox": checkbox, "editor": editor}


func _add_character_result_row(character_id: String, scenario: String) -> void:
	var character := CCFStorageService.get_character(_project, character_id)
	var panel := PanelContainer.new()
	_result_root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	var checkbox := CheckBox.new()
	checkbox.text = "%s — Scenario" % CCFStorageService.character_display_name(character)
	checkbox.button_pressed = true
	content.add_child(checkbox)
	var editor := TextEdit.new()
	editor.text = scenario
	editor.custom_minimum_size.y = 120
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	content.add_child(editor)
	_character_result_rows[character_id] = {"checkbox": checkbox, "editor": editor}


func _apply_results() -> void:
	if _project_id.is_empty():
		return
	var shared_context: Dictionary = {}
	for field_id in _shared_result_rows:
		var row: Dictionary = _shared_result_rows[field_id]
		var checkbox: CheckBox = row.get("checkbox")
		if not checkbox.button_pressed:
			continue
		var editor: Control = row.get("editor")
		if editor is LineEdit:
			shared_context[field_id] = editor.text
		elif editor is TextEdit:
			shared_context[field_id] = editor.text
	var scenarios: Dictionary = {}
	for character_id in _character_result_rows:
		var row: Dictionary = _character_result_rows[character_id]
		var checkbox: CheckBox = row.get("checkbox")
		if not checkbox.button_pressed:
			continue
		var editor: TextEdit = row.get("editor")
		scenarios[character_id] = editor.text
	if shared_context.is_empty() and scenarios.is_empty():
		_status.text = "No generated proposal items are selected."
		return
	result_apply_requested.emit(shared_context, scenarios, _result_metadata.duplicate(true))
	_status.text = "Selected group-scene proposal applied. Save the project when ready."


func _clear_results() -> void:
	_clear_children(_result_root)
	_shared_result_rows.clear()
	_character_result_rows.clear()


func _project_summary_text() -> String:
	var metadata = _project.get("metadata", {})
	var project_name := "Untitled Project"
	if metadata is Dictionary:
		project_name = str(metadata.get("name", project_name))
	return "%s • %d character%s" % [
		project_name,
		_project.get("characters", []).size(),
		"" if _project.get("characters", []).size() == 1 else "s"
	]


func _hide_window() -> void:
	CCFToolWindowStateService.save_window(self, "group_scene_generator")
	hide()


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
