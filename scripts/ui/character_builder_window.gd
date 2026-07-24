class_name CCFCharacterBuilderWindow
extends Window

signal builder_state_changed(state: Dictionary)
signal concept_apply_requested(state: Dictionary)
signal character_apply_requested(state: Dictionary, overwrite_existing: bool)
signal concept_refresh_requested()

var _generation_service: CCFGenerationService
var _settings: Dictionary = {}
var _state: Dictionary = {}
var _project_id := ""
var _current_concept := ""
var _series_context := ""
var _current_step_index := 0
var _step_buttons: Array[Button] = []
var _field_controls: Dictionary = {}
var _tracked_jobs: Dictionary = {}

var _preset_selector: OptionButton
var _preset_description: Label
var _completion_label: Label
var _step_title: Label
var _step_description: Label
var _step_content: VBoxContainer
var _status: Label
var _previous_button: Button
var _next_button: Button
var _ai_step_button: Button
var _ai_all_button: Button
var _extract_button: Button
var _overwrite_checkbox: CheckBox

func _ready() -> void:
	close_requested.connect(_hide_builder)
	_build_interface()

func set_generation_service(generation_service: CCFGenerationService) -> void:
	_generation_service = generation_service

func open_for_project(project: Dictionary, settings: Dictionary) -> void:
	_project_id = str(project.get("project_id", ""))
	_settings = settings.duplicate(true)
	_current_concept = str(CCFStorageService.get_value_at_path(project, "concept.prompt", ""))
	_series_context = CCFSeriesService.generation_context_for_project(project)
	var workspace: Dictionary = project.get("workspace", {})
	var raw_builder = workspace.get("builder", {})
	_state = CCFBuilderService.normalise_state(raw_builder if raw_builder is Dictionary else {})
	var selected_step_id := str(_state.get("selected_step", "foundation"))
	_current_step_index = _step_index_for_id(selected_step_id)
	_populate_presets()
	_render_step()
	_update_completion()
	_status.text = "Builder state is stored with this character when you save the project."

func update_project_context(project: Dictionary, settings: Dictionary) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	_settings = settings.duplicate(true)
	_current_concept = str(CCFStorageService.get_value_at_path(project, "concept.prompt", ""))
	_series_context = CCFSeriesService.generation_context_for_project(project)

func current_state() -> Dictionary:
	_capture_visible_fields()
	return _state.duplicate(true)

func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and _project_id == project_id

func release_project() -> void:
	_tracked_jobs.clear()
	_project_id = ""
	_current_concept = ""
	_series_context = ""
	_state = {}

func handle_job_completed(job_id: String, job_type: String, data: Variant, metadata: Dictionary) -> bool:
	if not _tracked_jobs.has(job_id):
		return false
	_tracked_jobs.erase(job_id)
	if not data is Dictionary:
		_status.text = "The builder AI job returned an unexpected response."
		return true
	var allowed_paths: Array[String] = []
	var raw_allowed = metadata.get("allowed_paths", [])
	if raw_allowed is Array:
		for field_path in raw_allowed:
			allowed_paths.append(str(field_path))
	_state = CCFBuilderService.apply_ai_patch(_state, data, allowed_paths)
	_state["selected_step"] = _current_step_id()
	_select_preset_id("custom")
	_render_step()
	_update_completion()
	builder_state_changed.emit(_state.duplicate(true))
	if job_type == "builder_extract":
		_status.text = "Concept analysed. Review the extracted builder details before applying them."
	else:
		_status.text = "AI builder details added. Review and edit anything you want."
	return true

func handle_job_failed(job_id: String, message: String) -> bool:
	if not _tracked_jobs.has(job_id):
		return false
	_tracked_jobs.erase(job_id)
	_status.text = message
	return true

func handle_job_cancelled(job_id: String) -> bool:
	if not _tracked_jobs.has(job_id):
		return false
	_tracked_jobs.erase(job_id)
	_status.text = "Builder AI job cancelled."
	return true

func _build_interface() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 8)
	root.add_child(preset_row)

	var preset_label := Label.new()
	preset_label.text = "Builder preset"
	preset_row.add_child(preset_label)

	_preset_selector = OptionButton.new()
	_preset_selector.custom_minimum_size.x = 250
	_preset_selector.item_selected.connect(_on_preset_selected)
	preset_row.add_child(_preset_selector)

	var apply_preset_button := Button.new()
	apply_preset_button.text = "Apply Preset"
	apply_preset_button.pressed.connect(_apply_selected_preset)
	preset_row.add_child(apply_preset_button)

	_extract_button = Button.new()
	_extract_button.text = "Analyse Current Concept"
	_extract_button.tooltip_text = "Use AI to convert the current generation concept into structured builder fields."
	_extract_button.pressed.connect(_analyse_current_concept)
	preset_row.add_child(_extract_button)

	_completion_label = Label.new()
	_completion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_completion_label.modulate = Color(0.64, 0.68, 0.82)
	preset_row.add_child(_completion_label)

	_preset_description = Label.new()
	_preset_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preset_description.modulate = Color(0.65, 0.68, 0.77)
	root.add_child(_preset_description)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	var navigation_panel := PanelContainer.new()
	navigation_panel.custom_minimum_size.x = 190
	body.add_child(navigation_panel)

	var navigation_margin := MarginContainer.new()
	navigation_margin.add_theme_constant_override("margin_left", 10)
	navigation_margin.add_theme_constant_override("margin_right", 10)
	navigation_margin.add_theme_constant_override("margin_top", 10)
	navigation_margin.add_theme_constant_override("margin_bottom", 10)
	navigation_panel.add_child(navigation_margin)

	var navigation := VBoxContainer.new()
	navigation.add_theme_constant_override("separation", 6)
	navigation_margin.add_child(navigation)

	_step_buttons.clear()
	var step_index := 0
	for builder_step in CCFBuilderService.steps():
		if not builder_step is Dictionary:
			continue
		var step_button := Button.new()
		step_button.text = str(builder_step.get("title", "Step"))
		step_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		step_button.pressed.connect(_select_step.bind(step_index))
		navigation.add_child(step_button)
		_step_buttons.append(step_button)
		step_index += 1

	var navigation_spacer := Control.new()
	navigation_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	navigation.add_child(navigation_spacer)

	var clear_step_button := Button.new()
	clear_step_button.text = "Clear Current Step"
	clear_step_button.pressed.connect(_clear_current_step)
	navigation.add_child(clear_step_button)

	var content_area := VBoxContainer.new()
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 8)
	body.add_child(content_area)

	_step_title = Label.new()
	_step_title.add_theme_font_size_override("font_size", 22)
	content_area.add_child(_step_title)

	_step_description = Label.new()
	_step_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_step_description.modulate = Color(0.68, 0.71, 0.8)
	content_area.add_child(_step_description)

	var step_actions := HBoxContainer.new()
	step_actions.add_theme_constant_override("separation", 8)
	content_area.add_child(step_actions)

	_ai_step_button = Button.new()
	_ai_step_button.text = "AI Fill This Step"
	_ai_step_button.pressed.connect(_ai_fill_current_step)
	step_actions.add_child(_ai_step_button)

	_ai_all_button = Button.new()
	_ai_all_button.text = "AI Fill All Builder Fields"
	_ai_all_button.pressed.connect(_ai_fill_all)
	step_actions.add_child(_ai_all_button)

	var action_hint := Label.new()
	action_hint.text = "AI fills the builder scratchpad only. Nothing reaches the character card until you apply it."
	action_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_hint.modulate = Color(0.59, 0.63, 0.73)
	action_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_actions.add_child(action_hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_child(scroll)

	var step_margin := MarginContainer.new()
	step_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_margin.add_theme_constant_override("margin_right", 12)
	step_margin.add_theme_constant_override("margin_top", 6)
	step_margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(step_margin)

	_step_content = VBoxContainer.new()
	_step_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_step_content.add_theme_constant_override("separation", 12)
	step_margin.add_child(_step_content)

	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	root.add_child(footer)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.7, 0.73, 0.82)
	footer.add_child(_status)

	var footer_actions := HBoxContainer.new()
	footer_actions.add_theme_constant_override("separation", 8)
	footer.add_child(footer_actions)

	_overwrite_checkbox = CheckBox.new()
	_overwrite_checkbox.text = "Overwrite existing card fields"
	_overwrite_checkbox.tooltip_text = "When disabled, Apply to Character fills only empty destination fields."
	footer_actions.add_child(_overwrite_checkbox)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_actions.add_child(footer_spacer)

	var concept_button := Button.new()
	concept_button.text = "Send to Concept"
	concept_button.tooltip_text = "Replace the character's generation concept with the assembled builder brief."
	concept_button.pressed.connect(_request_concept_apply)
	footer_actions.add_child(concept_button)

	var apply_button := Button.new()
	apply_button.text = "Apply to Character"
	apply_button.tooltip_text = "Transfer builder details into the concept, description, personality, scenario, name, and tags."
	apply_button.pressed.connect(_request_character_apply)
	footer_actions.add_child(apply_button)

	_previous_button = Button.new()
	_previous_button.text = "Previous"
	_previous_button.pressed.connect(_previous_step)
	footer_actions.add_child(_previous_button)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.pressed.connect(_next_step)
	footer_actions.add_child(_next_button)

func _populate_presets() -> void:
	if _preset_selector == null:
		return
	_preset_selector.clear()
	var current_preset_id := str(_state.get("preset_id", "custom"))
	var selected_index := 0
	var row_index := 0
	for preset_summary in CCFBuilderService.list_presets():
		if not preset_summary is Dictionary:
			continue
		_preset_selector.add_item(str(preset_summary.get("name", "Preset")))
		_preset_selector.set_item_metadata(row_index, str(preset_summary.get("preset_id", "custom")))
		_preset_selector.set_item_tooltip(row_index, str(preset_summary.get("description", "")))
		if str(preset_summary.get("preset_id", "")) == current_preset_id:
			selected_index = row_index
		row_index += 1
	if _preset_selector.item_count > 0:
		_preset_selector.select(clampi(selected_index, 0, _preset_selector.item_count - 1))
	_update_preset_description()

func _on_preset_selected(_index: int) -> void:
	_update_preset_description()

func _update_preset_description() -> void:
	if _preset_selector == null or _preset_selector.selected < 0:
		_preset_description.text = ""
		return
	_preset_description.text = _preset_selector.get_item_tooltip(_preset_selector.selected)

func _apply_selected_preset() -> void:
	_capture_visible_fields()
	if _preset_selector.selected < 0:
		return
	var preset_id := str(_preset_selector.get_selected_metadata())
	_state = CCFBuilderService.apply_preset(_state, preset_id)
	_state["selected_step"] = _current_step_id()
	_render_step()
	_update_completion()
	builder_state_changed.emit(_state.duplicate(true))
	if preset_id == "custom":
		_status.text = "Builder cleared."
	else:
		_status.text = "Preset applied to its matching builder fields. Existing details outside the preset were kept."

func _select_preset_id(preset_id: String) -> void:
	if _preset_selector == null:
		return
	for item_index in range(_preset_selector.item_count):
		if str(_preset_selector.get_item_metadata(item_index)) == preset_id:
			_preset_selector.select(item_index)
			_update_preset_description()
			return

func _render_step() -> void:
	if _step_content == null:
		return
	_field_controls.clear()
	_clear_children(_step_content)
	var builder_steps := CCFBuilderService.steps()
	if builder_steps.is_empty():
		_step_title.text = "Builder unavailable"
		_step_description.text = "The builder schema could not be loaded."
		return
	_current_step_index = clampi(_current_step_index, 0, builder_steps.size() - 1)
	var builder_step: Dictionary = builder_steps[_current_step_index]
	_step_title.text = str(builder_step.get("title", "Builder Step"))
	_step_description.text = str(builder_step.get("description", ""))

	for button_index in range(_step_buttons.size()):
		_step_buttons[button_index].disabled = button_index == _current_step_index

	var builder_fields = builder_step.get("fields", [])
	if builder_fields is Array and not builder_fields.is_empty():
		for builder_field in builder_fields:
			if builder_field is Dictionary:
				_add_builder_field(builder_field)
		_ai_step_button.disabled = false
	else:
		_render_review()
		_ai_step_button.disabled = true

	_previous_button.disabled = _current_step_index <= 0
	_next_button.disabled = _current_step_index >= builder_steps.size() - 1
	_state["selected_step"] = _current_step_id()

func _add_builder_field(builder_field: Dictionary) -> void:
	var label := Label.new()
	label.text = str(builder_field.get("label", builder_field.get("id", "Field")))
	label.add_theme_font_size_override("font_size", 16)
	_step_content.add_child(label)

	var field_path := str(builder_field.get("path", ""))
	var field_type := str(builder_field.get("type", "line"))
	var default_value: Variant = ""
	if field_type == "tags":
		default_value = []
	var value: Variant = CCFStorageService.get_value_at_path(_state, field_path, default_value)
	var control: Control

	if field_type == "multiline":
		var text_edit := TextEdit.new()
		text_edit.text = str(value)
		text_edit.placeholder_text = str(builder_field.get("placeholder", ""))
		text_edit.custom_minimum_size.y = float(builder_field.get("height", 120))
		text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		text_edit.text_changed.connect(func(): _on_builder_control_changed(field_path, field_type, text_edit))
		control = text_edit
	else:
		var line_edit := LineEdit.new()
		line_edit.placeholder_text = str(builder_field.get("placeholder", ""))
		line_edit.text = _value_to_text(value)
		line_edit.text_changed.connect(func(_new_text: String): _on_builder_control_changed(field_path, field_type, line_edit))
		control = line_edit

	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_step_content.add_child(control)
	_field_controls[field_path] = {"control": control, "type": field_type}

func _render_review() -> void:
	var completion := CCFBuilderService.completion_percent(_state)
	var overview := Label.new()
	overview.text = "Builder completion: %d%%. The preview below is the generation concept that will be created from the current builder state." % completion
	overview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_step_content.add_child(overview)

	var concept_preview := TextEdit.new()
	concept_preview.text = CCFBuilderService.compose_concept(_state)
	concept_preview.editable = false
	concept_preview.custom_minimum_size.y = 400
	concept_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_step_content.add_child(concept_preview)

	var destination_note := Label.new()
	destination_note.text = "Apply to Character can populate: character name, generation concept, description, personality, scenario, and library tags. First message and other template fields remain available for normal AI generation or manual editing."
	destination_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	destination_note.modulate = Color(0.64, 0.68, 0.78)
	_step_content.add_child(destination_note)

func _on_builder_control_changed(field_path: String, field_type: String, control: Control) -> void:
	var value: Variant = ""
	if control is LineEdit:
		value = control.text
	elif control is TextEdit:
		value = control.text
	if field_type == "tags":
		value = _parse_tags(str(value))
	CCFStorageService.set_value_at_path(_state, field_path, value)
	_state["preset_id"] = "custom"
	_select_preset_id("custom")
	_state["updated_at"] = Time.get_datetime_string_from_system(true)
	_state["selected_step"] = _current_step_id()
	_update_completion()
	builder_state_changed.emit(_state.duplicate(true))

func _capture_visible_fields() -> void:
	var changed := false
	for field_path in _field_controls:
		var row: Dictionary = _field_controls[field_path]
		var control: Control = row.get("control")
		var field_type := str(row.get("type", "line"))
		var value: Variant = ""
		if control is LineEdit:
			value = control.text
		elif control is TextEdit:
			value = control.text
		if field_type == "tags":
			value = _parse_tags(str(value))
		var current_value = CCFStorageService.get_value_at_path(_state, field_path, "")
		if JSON.stringify(current_value) != JSON.stringify(value):
			CCFStorageService.set_value_at_path(_state, field_path, value)
			changed = true
	var step_id := _current_step_id()
	if str(_state.get("selected_step", "foundation")) != step_id:
		_state["selected_step"] = step_id
		changed = true
	if changed:
		_state["updated_at"] = Time.get_datetime_string_from_system(true)

func _select_step(step_index: int) -> void:
	_capture_visible_fields()
	var builder_steps := CCFBuilderService.steps()
	var safe_index := clampi(step_index, 0, maxi(0, builder_steps.size() - 1))
	if safe_index != _current_step_index:
		_current_step_index = safe_index
		_state["selected_step"] = _current_step_id()
		_state["updated_at"] = Time.get_datetime_string_from_system(true)
	_render_step()
	builder_state_changed.emit(_state.duplicate(true))

func _previous_step() -> void:
	_select_step(maxi(0, _current_step_index - 1))

func _next_step() -> void:
	_select_step(mini(CCFBuilderService.steps().size() - 1, _current_step_index + 1))

func _clear_current_step() -> void:
	_capture_visible_fields()
	_state = CCFBuilderService.clear_step(_state, _current_step_id())
	_select_preset_id("custom")
	_render_step()
	_update_completion()
	builder_state_changed.emit(_state.duplicate(true))
	_status.text = "Current builder step cleared."

func _ai_fill_current_step() -> void:
	_capture_visible_fields()
	var builder_fields := CCFBuilderService.fields_for_step(_current_step_id())
	_queue_builder_fill(builder_fields, str(CCFBuilderService.step_by_id(_current_step_id()).get("title", "Builder step")))

func _ai_fill_all() -> void:
	_capture_visible_fields()
	_queue_builder_fill(CCFBuilderService.all_fields(), "all builder fields")

func _queue_builder_fill(builder_fields: Array, scope_label: String) -> void:
	if _generation_service == null:
		_status.text = "Generation service is not available."
		return
	var profile := CCFSettingsService.active_profile(_settings)
	var result := _generation_service.queue_builder_fill(
		_state,
		builder_fields,
		profile,
		scope_label,
		int(_generation_settings().get("retry_count", 1)),
		_project_id,
		_series_context
	)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not queue builder generation."))
		return
	var job_id := str(result.get("job_id", ""))
	_tracked_jobs[job_id] = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "Builder AI job queued%s." % (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")

func _analyse_current_concept() -> void:
	_capture_visible_fields()
	concept_refresh_requested.emit()
	if _generation_service == null:
		_status.text = "Generation service is not available."
		return
	var profile := CCFSettingsService.active_profile(_settings)
	var result := _generation_service.queue_builder_extract(
		_current_concept,
		CCFBuilderService.all_fields(),
		profile,
		int(_generation_settings().get("retry_count", 1)),
		_project_id,
		_series_context
	)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not analyse the current concept."))
		return
	var job_id := str(result.get("job_id", ""))
	_tracked_jobs[job_id] = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "Concept analysis queued%s." % (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")

func _request_concept_apply() -> void:
	_capture_visible_fields()
	builder_state_changed.emit(_state.duplicate(true))
	concept_apply_requested.emit(_state.duplicate(true))

func _request_character_apply() -> void:
	_capture_visible_fields()
	builder_state_changed.emit(_state.duplicate(true))
	character_apply_requested.emit(_state.duplicate(true), _overwrite_checkbox.button_pressed)

func _update_completion() -> void:
	if _completion_label != null:
		_completion_label.text = "Builder %d%% complete" % CCFBuilderService.completion_percent(_state)

func _current_step_id() -> String:
	var builder_steps := CCFBuilderService.steps()
	if builder_steps.is_empty():
		return "foundation"
	var safe_index := clampi(_current_step_index, 0, builder_steps.size() - 1)
	return str(builder_steps[safe_index].get("id", "foundation"))

func _step_index_for_id(step_id: String) -> int:
	var builder_steps := CCFBuilderService.steps()
	for step_index in range(builder_steps.size()):
		var builder_step = builder_steps[step_index]
		if builder_step is Dictionary and str(builder_step.get("id", "")) == step_id:
			return step_index
	return 0

func _generation_settings() -> Dictionary:
	var generation = _settings.get("generation", {})
	return generation if generation is Dictionary else {}

func _hide_builder() -> void:
	_capture_visible_fields()
	builder_state_changed.emit(_state.duplicate(true))
	hide()

func _parse_tags(text: String) -> Array[String]:
	var tags: Array[String] = []
	for tag_part in text.split(",", false):
		var clean_tag := tag_part.strip_edges()
		if not clean_tag.is_empty() and not tags.has(clean_tag):
			tags.append(clean_tag)
	return tags

func _value_to_text(value: Variant) -> String:
	if value is Array:
		var parts: Array[String] = []
		for item in value:
			var clean_item := str(item).strip_edges()
			if not clean_item.is_empty():
				parts.append(clean_item)
		var result := ""
		for part_index in range(parts.size()):
			if part_index > 0:
				result += ", "
			result += parts[part_index]
		return result
	return str(value)

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
