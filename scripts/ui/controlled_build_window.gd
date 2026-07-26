class_name CCFControlledBuildWindow
extends Window

signal preview_requested(generated: Dictionary, metadata: Dictionary, preview_title: String)
signal project_refresh_requested

const MODE_SAFE_SECTION := "safe_section"
const MODE_CUSTOM_FIELDS := "custom_fields"
const MODE_REVISION := "revision"

var _generation_service: CCFGenerationService
var _settings: Dictionary = {}
var _project: Dictionary = {}
var _template: Dictionary = {}
var _project_id := ""
var _tracked_jobs: Dictionary = {}
var _field_checkboxes: Dictionary = {}

var _mode_selector: OptionButton
var _mode_description: Label
var _section_row: HBoxContainer
var _section_selector: OptionButton
var _field_actions: HBoxContainer
var _field_scroll: ScrollContainer
var _field_list: VBoxContainer
var _revision_group: VBoxContainer
var _revision_instructions: TextEdit
var _status: Label
var _queue_button: Button


func _ready() -> void:
	close_requested.connect(_hide_window)
	_build_interface()


func set_generation_service(generation_service: CCFGenerationService) -> void:
	_generation_service = generation_service


func open_for_project(project: Dictionary, template: Dictionary, settings: Dictionary) -> void:
	_project = project.duplicate(true)
	_template = template.duplicate(true)
	_settings = settings.duplicate(true)
	_project_id = str(project.get("project_id", ""))
	_populate_sections()
	_render_target_fields()
	_status.text = "Choose a controlled build mode and queue only the content you want to change."


func update_project_context(
	project: Dictionary, template: Dictionary, settings: Dictionary
) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	var previous_template_id := str(_template.get("template_id", ""))
	_project = project.duplicate(true)
	_template = template.duplicate(true)
	_settings = settings.duplicate(true)
	if previous_template_id != str(_template.get("template_id", "")):
		_populate_sections()
		_render_target_fields()


func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and _project_id == project_id


func release_project() -> void:
	_tracked_jobs.clear()
	_project_id = ""
	_project = {}
	_template = {}
	_settings = {}


func handle_job_completed(job_id: String, data: Variant, metadata: Dictionary) -> bool:
	if not _tracked_jobs.has(job_id):
		return false
	var job_info: Dictionary = _tracked_jobs.get(job_id, {})
	_tracked_jobs.erase(job_id)
	if not data is Dictionary:
		_status.text = "The controlled build returned an unexpected response."
		return true

	var build_mode := str(job_info.get("mode", metadata.get("controlled_mode", MODE_CUSTOM_FIELDS)))
	var preview_title := "Controlled Build Preview"
	match build_mode:
		MODE_SAFE_SECTION:
			preview_title = "Safe Section Build Preview"
		MODE_REVISION:
			preview_title = "Revision Preview"
		_:
			preview_title = "Custom Section Build Preview"
	_status.text = "Generation finished. Review the proposed changes in Generation Preview."
	preview_requested.emit(data, metadata, preview_title)
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
	_status.text = "Controlled build cancelled."
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

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	root.add_child(mode_row)

	var mode_label := Label.new()
	mode_label.text = "Build mode"
	mode_row.add_child(mode_label)

	_mode_selector = OptionButton.new()
	_mode_selector.custom_minimum_size.x = 250
	_mode_selector.add_item("Safe Section Build")
	_mode_selector.set_item_metadata(0, MODE_SAFE_SECTION)
	_mode_selector.add_item("Custom Section Build")
	_mode_selector.set_item_metadata(1, MODE_CUSTOM_FIELDS)
	_mode_selector.add_item("Revise Existing Content")
	_mode_selector.set_item_metadata(2, MODE_REVISION)
	_mode_selector.item_selected.connect(_on_mode_selected)
	mode_row.add_child(_mode_selector)

	var mode_spacer := Control.new()
	mode_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_child(mode_spacer)

	_queue_button = Button.new()
	_queue_button.text = "Queue Controlled Build"
	_queue_button.pressed.connect(_queue_controlled_build)
	mode_row.add_child(_queue_button)

	_mode_description = Label.new()
	_mode_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_description.modulate = Color(0.67, 0.7, 0.8)
	root.add_child(_mode_description)

	_section_row = HBoxContainer.new()
	_section_row.add_theme_constant_override("separation", 8)
	root.add_child(_section_row)

	var section_label := Label.new()
	section_label.text = "Template section"
	_section_row.add_child(section_label)

	_section_selector = OptionButton.new()
	_section_selector.custom_minimum_size.x = 300
	_section_selector.item_selected.connect(func(_index: int): _render_target_fields())
	_section_row.add_child(_section_selector)

	var section_hint := Label.new()
	section_hint.text = "Every AI-generatable field in this section is targeted; all other fields are protected context."
	section_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section_hint.modulate = Color(0.6, 0.64, 0.74)
	section_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_section_row.add_child(section_hint)

	_field_actions = HBoxContainer.new()
	_field_actions.add_theme_constant_override("separation", 8)
	root.add_child(_field_actions)

	var targets_label := Label.new()
	targets_label.text = "Target fields"
	targets_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_actions.add_child(targets_label)

	var select_all_button := Button.new()
	select_all_button.text = "Select All"
	select_all_button.pressed.connect(_set_all_field_checks.bind(true))
	_field_actions.add_child(select_all_button)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(_set_all_field_checks.bind(false))
	_field_actions.add_child(clear_button)

	_field_scroll = ScrollContainer.new()
	_field_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_field_scroll)

	var field_margin := MarginContainer.new()
	field_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_margin.add_theme_constant_override("margin_right", 12)
	field_margin.add_theme_constant_override("margin_bottom", 10)
	_field_scroll.add_child(field_margin)

	_field_list = VBoxContainer.new()
	_field_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_list.add_theme_constant_override("separation", 8)
	field_margin.add_child(_field_list)

	_revision_group = VBoxContainer.new()
	_revision_group.add_theme_constant_override("separation", 6)
	root.add_child(_revision_group)

	var revision_label := Label.new()
	revision_label.text = "Revision instructions"
	_revision_group.add_child(revision_label)

	_revision_instructions = TextEdit.new()
	_revision_instructions.placeholder_text = "Example: Make the voice sharper and funnier, preserve all established facts, and reduce repetition."
	_revision_instructions.custom_minimum_size.y = 130
	_revision_instructions.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_revision_group.add_child(_revision_instructions)

	var revision_hint := Label.new()
	revision_hint.text = "Only the selected fields may be returned. Existing values are supplied as the text to revise; unrelated fields remain protected context."
	revision_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	revision_hint.modulate = Color(0.6, 0.64, 0.74)
	_revision_group.add_child(revision_hint)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.7, 0.74, 0.84)
	root.add_child(_status)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_hide_window)
	root.add_child(close_button)

	_on_mode_selected(0)


func _on_mode_selected(_index: int) -> void:
	var build_mode := _current_mode()
	_section_row.visible = build_mode == MODE_SAFE_SECTION
	_field_actions.visible = build_mode != MODE_SAFE_SECTION
	_revision_group.visible = build_mode == MODE_REVISION
	match build_mode:
		MODE_SAFE_SECTION:
			_mode_description.text = "Generate one complete template section while explicitly treating every field outside that section as protected context."
		MODE_REVISION:
			_mode_description.text = "Improve selected existing fields using your revision instructions without rebuilding the rest of the character."
		_:
			_mode_description.text = "Choose any combination of AI-generatable template fields and build only that exact subset."
	_render_target_fields()


func _populate_sections() -> void:
	if _section_selector == null:
		return
	var previous_id := ""
	if _section_selector.selected >= 0:
		previous_id = str(_section_selector.get_selected_metadata())
	_section_selector.clear()
	var selected_index := 0
	var section_index := 0
	for section in _template.get("sections", []):
		if not section is Dictionary:
			continue
		var generation_count := 0
		for field in section.get("fields", []):
			if field is Dictionary and bool(field.get("generate", false)):
				generation_count += 1
		if generation_count == 0:
			continue
		var section_id := str(section.get("id", "section_%d" % section_index))
		_section_selector.add_item(
			"%s (%d fields)" % [str(section.get("title", "Section")), generation_count]
		)
		_section_selector.set_item_metadata(_section_selector.item_count - 1, section_id)
		if section_id == previous_id:
			selected_index = _section_selector.item_count - 1
		section_index += 1
	if _section_selector.item_count > 0:
		_section_selector.select(clampi(selected_index, 0, _section_selector.item_count - 1))


func _render_target_fields() -> void:
	if _field_list == null:
		return
	_clear_children(_field_list)
	_field_checkboxes.clear()
	var build_mode := _current_mode()
	if build_mode == MODE_SAFE_SECTION:
		var section := _selected_section()
		if section.is_empty():
			var empty_label := Label.new()
			empty_label.text = "The current template has no AI-generatable sections."
			_field_list.add_child(empty_label)
			return
		var heading := Label.new()
		heading.text = str(section.get("title", "Section"))
		heading.add_theme_font_size_override("font_size", 18)
		_field_list.add_child(heading)
		for field in section.get("fields", []):
			if field is Dictionary and bool(field.get("generate", false)):
				_add_field_check(field, true, true)
		return

	for section in _template.get("sections", []):
		if not section is Dictionary:
			continue
		var generation_fields: Array = []
		for field in section.get("fields", []):
			if field is Dictionary and bool(field.get("generate", false)):
				generation_fields.append(field)
		if generation_fields.is_empty():
			continue
		var heading := Label.new()
		heading.text = str(section.get("title", "Section"))
		heading.add_theme_font_size_override("font_size", 18)
		_field_list.add_child(heading)
		for field in generation_fields:
			_add_field_check(field, false, false)


func _add_field_check(field: Dictionary, checked: bool, locked: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_field_list.add_child(row)

	var check := CheckBox.new()
	check.text = str(field.get("label", field.get("id", "Field")))
	check.button_pressed = checked
	check.disabled = locked
	check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(check)

	var path_label := Label.new()
	path_label.text = str(field.get("path", ""))
	path_label.modulate = Color(0.55, 0.59, 0.69)
	row.add_child(path_label)

	_field_checkboxes[str(field.get("id", ""))] = {"check": check, "field": field.duplicate(true)}


func _set_all_field_checks(pressed: bool) -> void:
	for field_id in _field_checkboxes:
		var row: Dictionary = _field_checkboxes[field_id]
		var check: CheckBox = row.get("check")
		if check != null and not check.disabled:
			check.button_pressed = pressed


func _selected_fields() -> Array:
	var selected: Array = []
	if _current_mode() == MODE_SAFE_SECTION:
		var section := _selected_section()
		for field in section.get("fields", []):
			if field is Dictionary and bool(field.get("generate", false)):
				selected.append(field.duplicate(true))
		return selected

	for field_id in _field_checkboxes:
		var row: Dictionary = _field_checkboxes[field_id]
		var check: CheckBox = row.get("check")
		if check != null and check.button_pressed:
			var field = row.get("field", {})
			if field is Dictionary:
				selected.append(field.duplicate(true))
	return selected


func _selected_section() -> Dictionary:
	if _section_selector == null or _section_selector.selected < 0:
		return {}
	var selected_id := str(_section_selector.get_selected_metadata())
	for section in _template.get("sections", []):
		if section is Dictionary and str(section.get("id", "")) == selected_id:
			return section.duplicate(true)
	return {}


func _queue_controlled_build() -> void:
	project_refresh_requested.emit()
	if _generation_service == null:
		_status.text = "Generation service is not available."
		return
	var fields := _selected_fields()
	if fields.is_empty():
		_status.text = "Select at least one field to build."
		return

	var build_mode := _current_mode()
	var revision_instruction := ""
	if build_mode == MODE_REVISION:
		revision_instruction = _revision_instructions.text.strip_edges()
	if build_mode == MODE_REVISION and revision_instruction.is_empty():
		_status.text = "Enter revision instructions before queuing a revision."
		return

	var scope_label := "custom field selection"
	if build_mode == MODE_SAFE_SECTION:
		scope_label = str(_selected_section().get("title", "template section"))
	elif build_mode == MODE_REVISION:
		scope_label = "selected field revision"

	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var result := _generation_service.queue_controlled_build(
		_project,
		_template,
		fields,
		profile,
		build_mode,
		scope_label,
		revision_instruction,
		int(_generation_settings().get("retry_count", 1))
	)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not queue controlled build."))
		return

	var job_id := str(result.get("job_id", ""))
	_tracked_jobs[job_id] = {"mode": build_mode}
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = (
		"Controlled build queued%s."
		% (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
	)


func _current_mode() -> String:
	if _mode_selector == null or _mode_selector.selected < 0:
		return MODE_SAFE_SECTION
	return str(_mode_selector.get_selected_metadata())


func _generation_settings() -> Dictionary:
	var generation = _settings.get("generation", {})
	return generation if generation is Dictionary else {}


func _hide_window() -> void:
	hide()


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
