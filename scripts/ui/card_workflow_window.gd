class_name CCFCardWorkflowWindow
extends Window

signal project_refresh_requested
signal workflow_saved(workflow: Dictionary)
signal workflow_deleted(workflow_id: String)

var _generation_service: CCFGenerationService
var _project: Dictionary = {}
var _settings: Dictionary = {}
var _project_id := ""
var _job_id := ""
var _current_workflow_id := ""
var _character_checks: Dictionary = {}
var _member_rows: Dictionary = {}
var _saved_selector: OptionButton
var _mode_selector: OptionButton
var _character_box: VBoxContainer
var _instructions: TextEdit
var _generate_button: Button
var _status: Label
var _project_summary: Label
var _title_edit: LineEdit
var _summary_edit: TextEdit
var _shared_scenario_edit: TextEdit
var _opening_message_edit: TextEdit
var _notes_edit: TextEdit
var _member_root: VBoxContainer


func _ready() -> void:
	visible = false
	title = "Card Workflow Studio"
	size = Vector2i(1260, 860)
	min_size = Vector2i(920, 640)
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
	_project_summary.text = _project_summary_text()
	_rebuild_saved_selector()
	_rebuild_character_selection()
	if _current_workflow_id.is_empty():
		_new_draft()
	_status.text = "Plan a multi-character single card, a coordinated split-card batch, or a group-card output. Saved workflow drafts live inside this project."
	CCFToolWindowStateService.show_window(self, "card_workflow_studio", Vector2i(1260, 860))


func update_project_context(project: Dictionary, settings: Dictionary) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	_project = project.duplicate(true)
	_settings = settings.duplicate(true)
	_project_summary.text = _project_summary_text()
	_rebuild_saved_selector(_current_workflow_id)
	_rebuild_character_selection()


func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and _project_id == project_id


func release_project() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "card_workflow_studio")
	hide()
	_project.clear()
	_project_id = ""
	_job_id = ""
	_current_workflow_id = ""
	_member_rows.clear()


func save_window_state() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "card_workflow_studio")


func handle_job_completed(job_id: String, data: Variant, metadata: Dictionary) -> bool:
	if job_id != _job_id:
		return false
	_job_id = ""
	_generate_button.disabled = false
	if str(metadata.get("project_id", "")) != _project_id:
		_status.text = "Card-workflow result discarded because a different project is now active."
		return true
	if not data is Dictionary:
		_status.text = "The card-workflow response was not a JSON object."
		return true
	_load_generated_result(data, metadata)
	_status.text = "Workflow draft generated. Review and edit it, then save the draft into the project when ready."
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
	_status.text = "Card workflow generation cancelled."
	return true


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

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size.x = 410
	split.add_child(left_panel)
	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 14)
	left_margin.add_theme_constant_override("margin_right", 14)
	left_margin.add_theme_constant_override("margin_top", 14)
	left_margin.add_theme_constant_override("margin_bottom", 14)
	left_panel.add_child(left_margin)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 9)
	left_margin.add_child(left)

	var saved_label := Label.new()
	saved_label.text = "Saved workflow drafts"
	saved_label.add_theme_font_size_override("font_size", 18)
	left.add_child(saved_label)
	_saved_selector = OptionButton.new()
	_saved_selector.item_selected.connect(_on_saved_workflow_selected)
	left.add_child(_saved_selector)
	var saved_actions := HFlowContainer.new()
	saved_actions.add_theme_constant_override("separation", 8)
	left.add_child(saved_actions)
	var new_button := Button.new()
	new_button.text = "New Draft"
	new_button.pressed.connect(_new_draft)
	saved_actions.add_child(new_button)
	var save_button := Button.new()
	save_button.text = "Save Draft"
	save_button.pressed.connect(_save_workflow)
	saved_actions.add_child(save_button)
	var delete_button := Button.new()
	delete_button.text = "Delete Draft"
	delete_button.pressed.connect(_delete_workflow)
	saved_actions.add_child(delete_button)

	left.add_child(HSeparator.new())
	var mode_label := Label.new()
	mode_label.text = "Workflow mode"
	left.add_child(mode_label)
	_mode_selector = OptionButton.new()
	_mode_selector.add_item("Multi-character single card")
	_mode_selector.set_item_metadata(0, "multi_single")
	_mode_selector.add_item("Split-card batch plan")
	_mode_selector.set_item_metadata(1, "split_batch")
	_mode_selector.add_item("Group-card plan")
	_mode_selector.set_item_metadata(2, "group_card")
	left.add_child(_mode_selector)

	var character_label := Label.new()
	character_label.text = "Characters included"
	left.add_child(character_label)
	var select_actions := HBoxContainer.new()
	select_actions.add_theme_constant_override("separation", 8)
	left.add_child(select_actions)
	var select_all := Button.new()
	select_all.text = "Select All"
	select_all.pressed.connect(_set_all_characters_selected.bind(true))
	select_actions.add_child(select_all)
	var clear_selection := Button.new()
	clear_selection.text = "Clear"
	clear_selection.pressed.connect(_set_all_characters_selected.bind(false))
	select_actions.add_child(clear_selection)
	var character_scroll := ScrollContainer.new()
	character_scroll.custom_minimum_size.y = 190
	left.add_child(character_scroll)
	_character_box = VBoxContainer.new()
	_character_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_box.add_theme_constant_override("separation", 4)
	character_scroll.add_child(_character_box)

	var instructions_label := Label.new()
	instructions_label.text = "Optional workflow instructions"
	left.add_child(instructions_label)
	_instructions = TextEdit.new()
	_instructions.placeholder_text = "Desired output structure, tone, division of roles, shared opening, constraints…"
	_instructions.custom_minimum_size.y = 120
	_instructions.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	left.add_child(_instructions)
	_generate_button = Button.new()
	_generate_button.text = "Generate Workflow Draft"
	_generate_button.pressed.connect(_generate_workflow)
	left.add_child(_generate_button)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right_panel)
	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 14)
	right_margin.add_theme_constant_override("margin_right", 14)
	right_margin.add_theme_constant_override("margin_top", 14)
	right_margin.add_theme_constant_override("margin_bottom", 14)
	right_panel.add_child(right_margin)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right_margin.add_child(right)

	var draft_heading := Label.new()
	draft_heading.text = "Workflow draft"
	draft_heading.add_theme_font_size_override("font_size", 18)
	right.add_child(draft_heading)
	var draft_hint := Label.new()
	draft_hint.text = "This is project-level planning data, not an exported card yet. It gives later generation/export steps one coherent source of truth."
	draft_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	draft_hint.modulate = Color(0.67, 0.7, 0.8)
	right.add_child(draft_hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 8)
	scroll.add_child(fields)
	_title_edit = _add_line_field(fields, "Working title")
	_summary_edit = _add_multiline_field(fields, "Output summary / intent", 105)
	_shared_scenario_edit = _add_multiline_field(fields, "Shared scenario / setup", 130)
	_opening_message_edit = _add_multiline_field(fields, "Opening message or opening direction", 130)
	_notes_edit = _add_multiline_field(fields, "Workflow notes", 100)
	var member_heading := Label.new()
	member_heading.text = "Per-character output directions"
	member_heading.add_theme_font_size_override("font_size", 17)
	fields.add_child(member_heading)
	_member_root = VBoxContainer.new()
	_member_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_member_root.add_theme_constant_override("separation", 10)
	fields.add_child(_member_root)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.66, 0.7, 0.82)
	root.add_child(_status)


func _add_line_field(parent: VBoxContainer, label_text: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var editor := LineEdit.new()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(editor)
	return editor


func _add_multiline_field(parent: VBoxContainer, label_text: String, height: int) -> TextEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var editor := TextEdit.new()
	editor.custom_minimum_size.y = height
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(editor)
	return editor


func _rebuild_saved_selector(preferred_id: String = "") -> void:
	_saved_selector.clear()
	_saved_selector.add_item("New / unsaved draft")
	_saved_selector.set_item_metadata(0, "")
	var selected_index := 0
	var item_index := 1
	var raw_workflows = _project.get("card_workflows", [])
	if raw_workflows is Array:
		for raw_workflow in raw_workflows:
			if not raw_workflow is Dictionary:
				continue
			var workflow_id := str(raw_workflow.get("workflow_id", ""))
			var workflow_title := str(raw_workflow.get("title", "Untitled workflow")).strip_edges()
			if workflow_title.is_empty():
				workflow_title = "Untitled workflow"
			_saved_selector.add_item(workflow_title)
			_saved_selector.set_item_metadata(item_index, workflow_id)
			if workflow_id == preferred_id:
				selected_index = item_index
			item_index += 1
	_saved_selector.select(selected_index)


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
		checkbox.text = str(summary.get("name", "Untitled Character"))
		var role := str(summary.get("role", "")).strip_edges()
		if not role.is_empty():
			checkbox.text += " — %s" % role
		checkbox.button_pressed = bool(previous_selection.get(character_id, true))
		_character_box.add_child(checkbox)
		_character_checks[character_id] = checkbox


func _on_saved_workflow_selected(index: int) -> void:
	var workflow_id := str(_saved_selector.get_item_metadata(index))
	if workflow_id.is_empty():
		_new_draft()
		return
	var workflow := _find_workflow(workflow_id)
	if workflow.is_empty():
		return
	_load_workflow(workflow)


func _find_workflow(workflow_id: String) -> Dictionary:
	var raw_workflows = _project.get("card_workflows", [])
	if not raw_workflows is Array:
		return {}
	for raw_workflow in raw_workflows:
		if raw_workflow is Dictionary and str(raw_workflow.get("workflow_id", "")) == workflow_id:
			return raw_workflow.duplicate(true)
	return {}


func _new_draft() -> void:
	_current_workflow_id = ""
	_title_edit.text = ""
	_summary_edit.text = ""
	_shared_scenario_edit.text = ""
	_opening_message_edit.text = ""
	_notes_edit.text = ""
	_instructions.text = ""
	_mode_selector.select(0)
	_set_all_characters_selected(true)
	_clear_children(_member_root)
	_member_rows.clear()
	if _saved_selector.item_count > 0:
		_saved_selector.select(0)
	_status.text = "New unsaved workflow draft."


func _load_workflow(workflow: Dictionary) -> void:
	_current_workflow_id = str(workflow.get("workflow_id", ""))
	_select_mode(str(workflow.get("mode", "multi_single")))
	_title_edit.text = str(workflow.get("title", ""))
	_summary_edit.text = str(workflow.get("summary", ""))
	_shared_scenario_edit.text = str(workflow.get("shared_scenario", ""))
	_opening_message_edit.text = str(workflow.get("opening_message", ""))
	_notes_edit.text = str(workflow.get("notes", ""))
	_instructions.text = str(workflow.get("instructions", ""))
	var selected_lookup: Dictionary = {}
	for raw_id in workflow.get("selected_character_ids", []):
		selected_lookup[str(raw_id)] = true
	for character_id in _character_checks:
		var checkbox: CheckBox = _character_checks[character_id]
		checkbox.button_pressed = selected_lookup.has(str(character_id))
	_render_members(workflow.get("members", []))
	_status.text = "Loaded saved workflow draft."


func _load_generated_result(data: Dictionary, metadata: Dictionary) -> void:
	_current_workflow_id = ""
	_title_edit.text = str(data.get("title", ""))
	_summary_edit.text = str(data.get("summary", ""))
	_shared_scenario_edit.text = str(data.get("shared_scenario", ""))
	_opening_message_edit.text = str(data.get("opening_message", ""))
	_notes_edit.text = str(data.get("notes", ""))
	var workflow_mode := str(metadata.get("workflow_mode", _selected_mode()))
	_select_mode(workflow_mode)
	var selected_lookup: Dictionary = {}
	for raw_id in metadata.get("selected_character_ids", []):
		selected_lookup[str(raw_id)] = true
	for character_id in _character_checks:
		var checkbox: CheckBox = _character_checks[character_id]
		checkbox.button_pressed = selected_lookup.has(str(character_id))
	_render_members(data.get("members", []))
	if _saved_selector.item_count > 0:
		_saved_selector.select(0)


func _render_members(raw_members: Variant) -> void:
	_clear_children(_member_root)
	_member_rows.clear()
	if not raw_members is Array:
		return
	for raw_member in raw_members:
		if not raw_member is Dictionary:
			continue
		var character_id := str(raw_member.get("character_id", ""))
		if CCFStorageService.character_index(_project, character_id) < 0:
			continue
		_add_member_row(character_id, raw_member)


func _add_member_row(character_id: String, member: Dictionary) -> void:
	var panel := PanelContainer.new()
	_member_root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	var heading := Label.new()
	heading.text = CCFRelationshipService.character_name(_project, character_id)
	heading.add_theme_font_size_override("font_size", 16)
	content.add_child(heading)
	var role_edit := _add_line_field(content, "Role in this output")
	role_edit.text = str(member.get("role_in_output", ""))
	var direction_edit := _add_multiline_field(content, "Card / portrayal direction", 90)
	direction_edit.text = str(member.get("card_direction", ""))
	var scenario_edit := _add_multiline_field(content, "Scenario direction", 90)
	scenario_edit.text = str(member.get("scenario_direction", ""))
	var opening_edit := _add_multiline_field(content, "Opening direction", 90)
	opening_edit.text = str(member.get("opening_direction", ""))
	_member_rows[character_id] = {
		"role": role_edit,
		"card_direction": direction_edit,
		"scenario_direction": scenario_edit,
		"opening_direction": opening_edit
	}


func _generate_workflow() -> void:
	project_refresh_requested.emit()
	if _generation_service == null:
		_status.text = "The AI generation service is unavailable."
		return
	var selected_ids := _selected_character_ids()
	if selected_ids.size() < 2:
		_status.text = "Select at least two characters for a multi-character workflow."
		return
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var generation_settings = _settings.get("generation", {})
	var retry_count := 1
	if generation_settings is Dictionary:
		retry_count = int(generation_settings.get("retry_count", 1))
	var result := _generation_service.queue_card_workflow_generation(
		_project, selected_ids, _selected_mode(), _instructions.text, profile, retry_count
	)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not queue card workflow generation."))
		return
	_job_id = str(result.get("job_id", ""))
	_generate_button.disabled = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "Card workflow generation queued%s." % (
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else ""
	)


func _save_workflow() -> void:
	var selected_ids := _selected_character_ids()
	if selected_ids.size() < 2:
		_status.text = "Select at least two characters before saving this workflow."
		return
	if _current_workflow_id.is_empty():
		_current_workflow_id = "workflow_%d" % Time.get_ticks_usec()
	var now := Time.get_datetime_string_from_system(true)
	var existing := _find_workflow(_current_workflow_id)
	var created_at := str(existing.get("created_at", now))
	var workflow := {
		"workflow_id": _current_workflow_id,
		"created_at": created_at,
		"updated_at": now,
		"mode": _selected_mode(),
		"title": _title_edit.text,
		"selected_character_ids": selected_ids,
		"instructions": _instructions.text,
		"summary": _summary_edit.text,
		"shared_scenario": _shared_scenario_edit.text,
		"opening_message": _opening_message_edit.text,
		"notes": _notes_edit.text,
		"members": _capture_members()
	}
	workflow_saved.emit(workflow)
	_status.text = "Workflow draft saved into the project. Save the project file when ready."


func _delete_workflow() -> void:
	if _current_workflow_id.is_empty():
		_status.text = "This draft has not been saved yet."
		return
	var deleted_id := _current_workflow_id
	workflow_deleted.emit(deleted_id)
	_current_workflow_id = ""
	_new_draft()
	_status.text = "Workflow draft removed from the project. Save the project file when ready."


func _capture_members() -> Array[Dictionary]:
	var members: Array[Dictionary] = []
	for character_id in _member_rows:
		var row: Dictionary = _member_rows[character_id]
		var role_edit: LineEdit = row.get("role")
		var direction_edit: TextEdit = row.get("card_direction")
		var scenario_edit: TextEdit = row.get("scenario_direction")
		var opening_edit: TextEdit = row.get("opening_direction")
		members.append(
			{
				"character_id": str(character_id),
				"role_in_output": role_edit.text,
				"card_direction": direction_edit.text,
				"scenario_direction": scenario_edit.text,
				"opening_direction": opening_edit.text
			}
		)
	return members


func _selected_character_ids() -> Array[String]:
	var selected_ids: Array[String] = []
	for character_id in _character_checks:
		var checkbox: CheckBox = _character_checks[character_id]
		if checkbox.button_pressed:
			selected_ids.append(str(character_id))
	return selected_ids


func _set_all_characters_selected(selected: bool) -> void:
	for character_id in _character_checks:
		var checkbox: CheckBox = _character_checks[character_id]
		checkbox.button_pressed = selected


func _selected_mode() -> String:
	if _mode_selector.selected < 0:
		return "multi_single"
	return str(_mode_selector.get_item_metadata(_mode_selector.selected))


func _select_mode(workflow_mode: String) -> void:
	for index in range(_mode_selector.item_count):
		if str(_mode_selector.get_item_metadata(index)) == workflow_mode:
			_mode_selector.select(index)
			return
	_mode_selector.select(0)


func _project_summary_text() -> String:
	var metadata = _project.get("metadata", {})
	var project_name := "Untitled Project"
	if metadata is Dictionary:
		project_name = str(metadata.get("name", project_name))
	var workflow_count := 0
	var raw_workflows = _project.get("card_workflows", [])
	if raw_workflows is Array:
		workflow_count = raw_workflows.size()
	return "%s • %d character%s • %d saved workflow draft%s" % [
		project_name,
		_project.get("characters", []).size(),
		"" if _project.get("characters", []).size() == 1 else "s",
		workflow_count,
		"" if workflow_count == 1 else "s"
	]


func _hide_window() -> void:
	CCFToolWindowStateService.save_window(self, "card_workflow_studio")
	hide()


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
