class_name CCFRelationshipMatrixWindow
extends Window

signal project_refresh_requested
signal relationships_applied(relationships: Array)

var _generation_service: CCFGenerationService
var _project: Dictionary = {}
var _settings: Dictionary = {}
var _project_id := ""
var _job_id := ""
var _relationships: Dictionary = {}
var _character_checks: Dictionary = {}
var _pair_list: ItemList
var _character_box: VBoxContainer
var _project_summary: Label
var _instructions: TextEdit
var _generate_button: Button
var _status: Label
var _current_pair_key := ""
var _loading_editor := false
var _local_dirty := false
var _label_edit: LineEdit
var _status_edit: LineEdit
var _intensity: SpinBox
var _tags_edit: LineEdit
var _summary_edit: TextEdit
var _a_to_b_label: Label
var _a_to_b_edit: TextEdit
var _b_to_a_label: Label
var _b_to_a_edit: TextEdit
var _dynamic_edit: TextEdit
var _notes_edit: TextEdit


func _ready() -> void:
	visible = false
	title = "Relationship Matrix"
	size = Vector2i(1240, 860)
	min_size = Vector2i(900, 640)
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
	_load_relationships_from_project()
	_rebuild_character_selection()
	_rebuild_pair_list()
	_project_summary.text = _project_summary_text()
	_status.text = "Edit any pair manually, or select characters and let AI draft their relationship matrix. Changes remain local until you apply them to the project."
	CCFToolWindowStateService.show_window(self, "relationship_matrix", Vector2i(1240, 860))


func update_project_context(project: Dictionary, settings: Dictionary) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	_project = project.duplicate(true)
	_settings = settings.duplicate(true)
	_project_summary.text = _project_summary_text()
	_rebuild_character_selection()
	if not _local_dirty and _job_id.is_empty():
		_load_relationships_from_project()
	_rebuild_pair_list()


func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and _project_id == project_id


func release_project() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "relationship_matrix")
	hide()
	_project.clear()
	_project_id = ""
	_job_id = ""
	_relationships.clear()
	_current_pair_key = ""
	_local_dirty = false


func save_window_state() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "relationship_matrix")


func handle_job_completed(job_id: String, data: Variant, metadata: Dictionary) -> bool:
	if job_id != _job_id:
		return false
	_job_id = ""
	_generate_button.disabled = false
	if str(metadata.get("project_id", "")) != _project_id:
		_status.text = "Relationship result discarded because a different project is now active."
		return true
	if not data is Dictionary:
		_status.text = "The relationship response was not a JSON object."
		return true
	var raw_relationships = data.get("relationships", [])
	if not raw_relationships is Array:
		_status.text = "The AI response did not contain a relationships array."
		return true
	var selected_ids: Array[String] = []
	for raw_id in metadata.get("selected_character_ids", []):
		selected_ids.append(str(raw_id))
	var selected_lookup: Dictionary = {}
	for character_id in selected_ids:
		selected_lookup[character_id] = true
	var applied_count := 0
	for raw_relationship in raw_relationships:
		if not raw_relationship is Dictionary:
			continue
		var relationship := CCFRelationshipService.normalise_relationship(raw_relationship)
		if relationship.is_empty():
			continue
		var first_id := str(relationship.get("character_a_id", ""))
		var second_id := str(relationship.get("character_b_id", ""))
		if not selected_lookup.has(first_id) or not selected_lookup.has(second_id):
			continue
		if CCFStorageService.character_index(_project, first_id) < 0:
			continue
		if CCFStorageService.character_index(_project, second_id) < 0:
			continue
		_relationships[CCFRelationshipService.pair_key(first_id, second_id)] = relationship
		applied_count += 1
	if applied_count == 0:
		_status.text = "The AI response contained no usable relationships for the selected characters."
		return true
	_local_dirty = true
	_rebuild_pair_list(_current_pair_key)
	_status.text = "AI drafted %d relationship%s into the local matrix. Review and edit them before applying the matrix to the project." % [
		applied_count, "" if applied_count == 1 else "s"
	]
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
	_status.text = "Relationship generation cancelled."
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
	left_panel.custom_minimum_size.x = 390
	split.add_child(left_panel)
	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 14)
	left_margin.add_theme_constant_override("margin_right", 14)
	left_margin.add_theme_constant_override("margin_top", 14)
	left_margin.add_theme_constant_override("margin_bottom", 14)
	left_panel.add_child(left_margin)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left_margin.add_child(left)

	var ai_heading := Label.new()
	ai_heading.text = "AI relationship generation"
	ai_heading.add_theme_font_size_override("font_size", 18)
	left.add_child(ai_heading)
	var ai_hint := Label.new()
	ai_hint.text = "Select two or more characters. AI will draft every pair within that selected set into the local matrix."
	ai_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ai_hint.modulate = Color(0.67, 0.7, 0.8)
	left.add_child(ai_hint)

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
	character_scroll.custom_minimum_size.y = 155
	left.add_child(character_scroll)
	_character_box = VBoxContainer.new()
	_character_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_box.add_theme_constant_override("separation", 4)
	character_scroll.add_child(_character_box)

	_instructions = TextEdit.new()
	_instructions.placeholder_text = "Optional relationship-generation instructions, tone, history, conflicts, constraints…"
	_instructions.custom_minimum_size.y = 100
	_instructions.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	left.add_child(_instructions)
	_generate_button = Button.new()
	_generate_button.text = "Generate Selected Relationships"
	_generate_button.pressed.connect(_generate_relationships)
	left.add_child(_generate_button)

	left.add_child(HSeparator.new())
	var matrix_heading := Label.new()
	matrix_heading.text = "Pair matrix"
	matrix_heading.add_theme_font_size_override("font_size", 18)
	left.add_child(matrix_heading)
	_pair_list = ItemList.new()
	_pair_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pair_list.select_mode = ItemList.SELECT_SINGLE
	_pair_list.item_selected.connect(_on_pair_selected)
	left.add_child(_pair_list)

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

	var editor_heading := Label.new()
	editor_heading.text = "Relationship details"
	editor_heading.add_theme_font_size_override("font_size", 18)
	right.add_child(editor_heading)
	var editor_scroll := ScrollContainer.new()
	editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(editor_scroll)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 8)
	editor_scroll.add_child(fields)

	_label_edit = _add_line_field(fields, "Relationship label", "Friends, rivals, siblings, handler and asset…")
	_status_edit = _add_line_field(fields, "Current status", "Stable, strained, secret, newly formed…")
	var intensity_row := HBoxContainer.new()
	fields.add_child(intensity_row)
	var intensity_label := Label.new()
	intensity_label.text = "Intensity"
	intensity_label.custom_minimum_size.x = 160
	intensity_row.add_child(intensity_label)
	_intensity = SpinBox.new()
	_intensity.min_value = 0
	_intensity.max_value = 100
	_intensity.step = 1
	_intensity.value = 50
	_intensity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intensity_row.add_child(_intensity)
	_tags_edit = _add_line_field(fields, "Tags", "slow burn, rivalry, protective, unresolved")
	_summary_edit = _add_multiline_field(fields, "Shared relationship summary", 105)
	_a_to_b_label = Label.new()
	fields.add_child(_a_to_b_label)
	_a_to_b_edit = _add_multiline_editor(fields, 105)
	_b_to_a_label = Label.new()
	fields.add_child(_b_to_a_label)
	_b_to_a_edit = _add_multiline_editor(fields, 105)
	_dynamic_edit = _add_multiline_field(fields, "Ongoing dynamic and development", 105)
	_notes_edit = _add_multiline_field(fields, "Private planning notes", 90)

	var pair_actions := HFlowContainer.new()
	pair_actions.add_theme_constant_override("separation", 8)
	right.add_child(pair_actions)
	var save_pair := Button.new()
	save_pair.text = "Keep Pair Edits"
	save_pair.pressed.connect(_keep_pair_edits)
	pair_actions.add_child(save_pair)
	var clear_pair := Button.new()
	clear_pair.text = "Clear Pair Data"
	clear_pair.pressed.connect(_clear_pair_data)
	pair_actions.add_child(clear_pair)
	var apply_matrix := Button.new()
	apply_matrix.text = "Apply Matrix to Project"
	apply_matrix.pressed.connect(_apply_matrix)
	pair_actions.add_child(apply_matrix)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.66, 0.7, 0.82)
	root.add_child(_status)


func _add_line_field(parent: VBoxContainer, label_text: String, placeholder: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var editor := LineEdit.new()
	editor.placeholder_text = placeholder
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(editor)
	return editor


func _add_multiline_field(parent: VBoxContainer, label_text: String, height: int) -> TextEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	return _add_multiline_editor(parent, height)


func _add_multiline_editor(parent: VBoxContainer, height: int) -> TextEdit:
	var editor := TextEdit.new()
	editor.custom_minimum_size.y = height
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(editor)
	return editor


func _load_relationships_from_project() -> void:
	_relationships.clear()
	for relationship in CCFRelationshipService.normalise_relationships(_project):
		_relationships[str(relationship.get("relationship_id", ""))] = relationship.duplicate(true)
	_local_dirty = false


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


func _rebuild_pair_list(preferred_key: String = "") -> void:
	if _pair_list == null:
		return
	var target_key := preferred_key if not preferred_key.is_empty() else _current_pair_key
	_pair_list.clear()
	var summaries := CCFStorageService.project_character_summaries(_project)
	var selected_index := -1
	var pair_index := 0
	for first_index in range(summaries.size()):
		var first: Dictionary = summaries[first_index]
		for second_index in range(first_index + 1, summaries.size()):
			var second: Dictionary = summaries[second_index]
			var first_id := str(first.get("character_id", ""))
			var second_id := str(second.get("character_id", ""))
			var relationship_key := CCFRelationshipService.pair_key(first_id, second_id)
			var label := "%s ↔ %s" % [first.get("name", "Character"), second.get("name", "Character")]
			var relationship = _relationships.get(relationship_key, {})
			if relationship is Dictionary and CCFRelationshipService.has_meaningful_content(relationship):
				var relationship_label := str(relationship.get("label", "")).strip_edges()
				var relationship_status := str(relationship.get("status", "")).strip_edges()
				if not relationship_label.is_empty():
					label += " — %s" % relationship_label
				elif not relationship_status.is_empty():
					label += " — %s" % relationship_status
			_pair_list.add_item(label)
			_pair_list.set_item_metadata(pair_index, relationship_key)
			if relationship_key == target_key:
				selected_index = pair_index
			pair_index += 1
	if _pair_list.item_count == 0:
		_current_pair_key = ""
		_clear_editor()
		return
	if selected_index < 0:
		selected_index = 0
	_pair_list.select(selected_index)
	_load_pair_by_key(str(_pair_list.get_item_metadata(selected_index)))


func _on_pair_selected(index: int) -> void:
	_save_editor_to_local()
	_load_pair_by_key(str(_pair_list.get_item_metadata(index)))


func _load_pair_by_key(relationship_key: String) -> void:
	_current_pair_key = relationship_key
	var ids := relationship_key.split("::", false)
	if ids.size() != 2:
		_clear_editor()
		return
	var first_id := str(ids[0])
	var second_id := str(ids[1])
	var relationship = _relationships.get(
		relationship_key, CCFRelationshipService.new_relationship(first_id, second_id)
	)
	if not relationship is Dictionary:
		relationship = CCFRelationshipService.new_relationship(first_id, second_id)
	_loading_editor = true
	_label_edit.text = str(relationship.get("label", ""))
	_status_edit.text = str(relationship.get("status", ""))
	_intensity.value = int(relationship.get("intensity", 50))
	_tags_edit.text = _join_values(relationship.get("tags", []), ", ")
	_summary_edit.text = str(relationship.get("summary", ""))
	_a_to_b_edit.text = str(relationship.get("a_to_b", ""))
	_b_to_a_edit.text = str(relationship.get("b_to_a", ""))
	_dynamic_edit.text = str(relationship.get("dynamic", ""))
	_notes_edit.text = str(relationship.get("notes", ""))
	_a_to_b_label.text = "%s → %s" % [
		CCFRelationshipService.character_name(_project, first_id),
		CCFRelationshipService.character_name(_project, second_id)
	]
	_b_to_a_label.text = "%s → %s" % [
		CCFRelationshipService.character_name(_project, second_id),
		CCFRelationshipService.character_name(_project, first_id)
	]
	_loading_editor = false


func _save_editor_to_local() -> void:
	if _loading_editor or _current_pair_key.is_empty():
		return
	var ids := _current_pair_key.split("::", false)
	if ids.size() != 2:
		return
	var relationship := CCFRelationshipService.new_relationship(str(ids[0]), str(ids[1]))
	relationship["label"] = _label_edit.text
	relationship["status"] = _status_edit.text
	relationship["intensity"] = int(_intensity.value)
	relationship["tags"] = _parse_tags(_tags_edit.text)
	relationship["summary"] = _summary_edit.text
	relationship["a_to_b"] = _a_to_b_edit.text
	relationship["b_to_a"] = _b_to_a_edit.text
	relationship["dynamic"] = _dynamic_edit.text
	relationship["notes"] = _notes_edit.text
	relationship["updated_at"] = Time.get_datetime_string_from_system(true)
	if CCFRelationshipService.has_meaningful_content(relationship):
		_relationships[_current_pair_key] = relationship
	else:
		_relationships.erase(_current_pair_key)
	_local_dirty = true


func _keep_pair_edits() -> void:
	_save_editor_to_local()
	_rebuild_pair_list(_current_pair_key)
	_status.text = "Pair edits kept in the local matrix. Apply the matrix to the project when ready."


func _clear_pair_data() -> void:
	if _current_pair_key.is_empty():
		return
	_relationships.erase(_current_pair_key)
	_local_dirty = true
	_load_pair_by_key(_current_pair_key)
	_rebuild_pair_list(_current_pair_key)
	_status.text = "This pair's relationship data was cleared from the local matrix."


func _apply_matrix() -> void:
	_save_editor_to_local()
	var relationships: Array = []
	for relationship in _relationships.values():
		if relationship is Dictionary and CCFRelationshipService.has_meaningful_content(relationship):
			relationships.append(relationship.duplicate(true))
	relationships.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return str(first.get("relationship_id", "")) < str(second.get("relationship_id", ""))
	)
	relationships_applied.emit(relationships)
	_local_dirty = false
	_status.text = "Relationship matrix applied to the project. Save the project when ready."


func _generate_relationships() -> void:
	_save_editor_to_local()
	project_refresh_requested.emit()
	if _generation_service == null:
		_status.text = "The AI generation service is unavailable."
		return
	var selected_ids := _selected_character_ids()
	if selected_ids.size() < 2:
		_status.text = "Select at least two characters for relationship generation."
		return
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var generation_settings = _settings.get("generation", {})
	var retry_count := 1
	if generation_settings is Dictionary:
		retry_count = int(generation_settings.get("retry_count", 1))
	var result := _generation_service.queue_relationship_generation(
		_project, selected_ids, _instructions.text, profile, retry_count
	)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not queue relationship generation."))
		return
	_job_id = str(result.get("job_id", ""))
	_generate_button.disabled = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "Relationship generation queued%s." % (
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else ""
	)


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


func _clear_editor() -> void:
	_loading_editor = true
	_label_edit.text = ""
	_status_edit.text = ""
	_intensity.value = 50
	_tags_edit.text = ""
	_summary_edit.text = ""
	_a_to_b_edit.text = ""
	_b_to_a_edit.text = ""
	_dynamic_edit.text = ""
	_notes_edit.text = ""
	_a_to_b_label.text = "Character A → Character B"
	_b_to_a_label.text = "Character B → Character A"
	_loading_editor = false


func _project_summary_text() -> String:
	var metadata = _project.get("metadata", {})
	var project_name := "Untitled Project"
	if metadata is Dictionary:
		project_name = str(metadata.get("name", project_name))
	var relationship_count := 0
	for relationship in _relationships.values():
		if relationship is Dictionary and CCFRelationshipService.has_meaningful_content(relationship):
			relationship_count += 1
	return "%s • %d character%s • %d defined relationship%s" % [
		project_name,
		_project.get("characters", []).size(),
		"" if _project.get("characters", []).size() == 1 else "s",
		relationship_count,
		"" if relationship_count == 1 else "s"
	]


func _parse_tags(text: String) -> Array[String]:
	var tags: Array[String] = []
	for raw_tag in text.split(",", false):
		var clean_tag := raw_tag.strip_edges()
		if not clean_tag.is_empty() and not tags.has(clean_tag):
			tags.append(clean_tag)
	return tags


func _hide_window() -> void:
	_save_editor_to_local()
	CCFToolWindowStateService.save_window(self, "relationship_matrix")
	hide()


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _join_values(values: Array, separator: String) -> String:
	var result := ""
	for index in range(values.size()):
		if index > 0:
			result += separator
		result += str(values[index])
	return result
