class_name CCFWorkspaceV0172View
extends "res://scripts/ui/workspace_v0171.gd"

const FRONT_PORCH_SERVICE_V0172 = preload(
	"res://scripts/services/front_porch_extension_service_v0172.gd"
)
const GENERATION_SERVICE_V0172 = preload(
	"res://scripts/services/generation_service_v0172.gd"
)

var _front_porch_service_v0172 := FRONT_PORCH_SERVICE_V0172.new()
var _front_porch_controls_v0172: Dictionary = {}
var _front_porch_adult_rows_v0172: Array[Control] = []
var _front_porch_adult_unlocked_v0172 := false
var _front_porch_adult_toggle_v0172: CheckBox
var _front_porch_summary_v0172: Label
var _front_porch_group_tabs_v0172: TabContainer
var _front_porch_seed_tabs_v0172: TabContainer
var _front_porch_greeting_seed_controls_v0172: Array[Dictionary] = []


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V0172.new() as CCFGenerationServiceV01526
	add_child(service)
	service.configure_scheduler_v01526(
		_ai_scheduler_v01526, worker_id, worker_label, job_number_base
	)
	service.job_started.connect(_on_job_started)
	service.job_completed.connect(_on_job_completed)
	service.job_failed.connect(_on_job_failed)
	service.job_cancelled.connect(_on_job_cancelled)
	service.queue_changed.connect(_on_worker_queue_changed_v01526)
	service.diagnostics_available.connect(_on_generation_diagnostics_available_v01522)
	return service


func _rebuild_form() -> void:
	var restore_front_porch := false
	var previous_group := 0
	if _tabs != null and _tabs.get_tab_count() > 0:
		restore_front_porch = _tabs.get_tab_title(_tabs.current_tab) == "Front Porch — Optional"
		if _front_porch_group_tabs_v0172 != null:
			previous_group = _front_porch_group_tabs_v0172.current_tab
	super._rebuild_form()
	_build_front_porch_tab_v0172()
	if _front_porch_group_tabs_v0172 != null:
		_front_porch_group_tabs_v0172.current_tab = clampi(
			previous_group, 0, _front_porch_group_tabs_v0172.get_tab_count() - 1
		)
	if restore_front_porch and _tabs.get_tab_count() > 0:
		_tabs.current_tab = _tabs.get_tab_count() - 1


func _capture_all_fields() -> void:
	super._capture_all_fields()
	_capture_front_porch_fields_v0172()
	_capture_front_porch_greeting_seeds_v0172()


func _build_alternative_greetings_tab() -> void:
	_front_porch_seed_tabs_v0172 = null
	_front_porch_greeting_seed_controls_v0172.clear()
	super._build_alternative_greetings_tab()
	if _alternate_editors == null:
		return
	var root := _alternate_editors.get_parent() as VBoxContainer
	if root == null:
		return
	var divider := HSeparator.new()
	root.add_child(divider)
	var title := Label.new()
	title.text = "Front Porch Opening Seeds — Optional"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)
	var explanation := Label.new()
	explanation.text = (
		"Each alternate greeting can optionally override the card-level Front Porch opening state. "
		+ "Unset values inherit the character defaults. A disabled seed lets Front Porch read the room."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color(0.68, 0.72, 0.82)
	root.add_child(explanation)
	_front_porch_seed_tabs_v0172 = TabContainer.new()
	_front_porch_seed_tabs_v0172.custom_minimum_size.y = 520
	_front_porch_seed_tabs_v0172.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_front_porch_seed_tabs_v0172)
	var greeting_count := 0
	for child in _alternate_editors.get_children():
		if child is TextEdit:
			greeting_count += 1
	for greeting_index in range(maxi(1, greeting_count)):
		_add_front_porch_greeting_seed_tab_v0172(greeting_index)


func _add_alternative_editor(value: String) -> void:
	super._add_alternative_editor(value)
	if _front_porch_seed_tabs_v0172 != null:
		_add_front_porch_greeting_seed_tab_v0172(
			_front_porch_greeting_seed_controls_v0172.size()
		)


func _add_front_porch_greeting_seed_tab_v0172(greeting_index: int) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "front_porch_greeting_seed_%d_v0172" % greeting_index
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_front_porch_seed_tabs_v0172.add_child(scroll)
	_front_porch_seed_tabs_v0172.set_tab_title(
		_front_porch_seed_tabs_v0172.get_tab_count() - 1,
		"Alternate %d" % (greeting_index + 1)
	)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var raw_seeds := _front_porch_service_v0172.greeting_seeds(_project)
	var seed_exists := (
		greeting_index < raw_seeds.size()
		and raw_seeds[greeting_index] is Dictionary
	)
	var seed_enabled := CheckBox.new()
	seed_enabled.text = "Use a Front Porch opening-state override for this greeting"
	seed_enabled.button_pressed = seed_exists
	content.add_child(seed_enabled)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var generate := Button.new()
	generate.text = "Generate Seed"
	generate.pressed.connect(
		_generate_front_porch_greeting_seed_v0172.bind(greeting_index, false)
	)
	actions.add_child(generate)
	var regenerate := Button.new()
	regenerate.text = "Regenerate Selected"
	regenerate.pressed.connect(
		_generate_front_porch_greeting_seed_v0172.bind(greeting_index, true)
	)
	actions.add_child(regenerate)
	var clear := Button.new()
	clear.text = "Clear Seed"
	clear.pressed.connect(_clear_front_porch_greeting_seed_v0172.bind(greeting_index))
	actions.add_child(clear)

	var seed_control := {
		"index": greeting_index,
		"enabled": seed_enabled,
		"fields": {}
	}
	var field_controls: Dictionary = {}
	for field in _front_porch_service_v0172.greeting_seed_fields():
		var field_id := str(field.get("id", ""))
		var field_row := HBoxContainer.new()
		field_row.add_theme_constant_override("separation", 8)
		content.add_child(field_row)
		var include := CheckBox.new()
		include.text = "Include"
		include.button_pressed = (
			_front_porch_service_v0172.greeting_seed_field_included(
				_project, greeting_index, field
			)
		)
		field_row.add_child(include)
		var label := Label.new()
		label.text = str(field.get("label", field_id))
		label.custom_minimum_size.x = 190
		field_row.add_child(label)
		var value: Variant = _front_porch_service_v0172.greeting_seed_value(
			_project, greeting_index, field
		)
		var input := _create_front_porch_input_v0172(field, value)
		field_row.add_child(input)
		_set_front_porch_input_enabled_v0172(
			input, seed_exists and include.button_pressed
		)
		include.toggled.connect(
			_on_front_porch_seed_field_toggled_v0172.bind(
				greeting_index, field_id
			)
		)
		field_controls[field_id] = {
			"field": field.duplicate(true),
			"include": include,
			"input": input
		}
	seed_control["fields"] = field_controls
	_front_porch_greeting_seed_controls_v0172.append(seed_control)
	seed_enabled.toggled.connect(
		_on_front_porch_seed_enabled_v0172.bind(greeting_index)
	)


func _build_front_porch_tab_v0172() -> void:
	if _tabs == null:
		return
	_front_porch_controls_v0172.clear()
	_front_porch_adult_rows_v0172.clear()
	_front_porch_adult_unlocked_v0172 = false

	var page := VBoxContainer.new()
	page.name = "front_porch_optional_v0172"
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 10)
	_tabs.add_child(page)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Front Porch — Optional")

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 12)
	header_margin.add_theme_constant_override("margin_right", 18)
	header_margin.add_theme_constant_override("margin_top", 12)
	page.add_child(header_margin)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header_margin.add_child(header)

	var intro := Label.new()
	intro.text = (
		"Optional Front Porch 2.5 character-life and new-conversation defaults. "
		+ "Unset fields are not added to the card. Imported future fields are preserved. "
		+ "Nothing here changes an existing Front Porch conversation."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(intro)

	var boundary := Label.new()
	boundary.text = (
		"Direct database writing is intentionally unsupported. A later version will install "
		+ "through Front Porch's supported local API."
	)
	boundary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boundary.modulate = Color(0.72, 0.66, 0.48)
	header.add_child(boundary)

	var action_row := HFlowContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	header.add_child(action_row)
	var generate_enabled := Button.new()
	generate_enabled.text = "Generate Enabled Front Porch Fields"
	generate_enabled.tooltip_text = (
		"Queue one AI proposal containing only included AI-capable fields. Review is required before application."
	)
	generate_enabled.pressed.connect(_generate_enabled_front_porch_fields_v0172)
	action_row.add_child(generate_enabled)
	var validate_button := Button.new()
	validate_button.text = "Validate Front Porch Data"
	validate_button.pressed.connect(_validate_front_porch_fields_v0172)
	action_row.add_child(validate_button)
	var clear_all_button := Button.new()
	clear_all_button.text = "Clear All Known Front Porch Fields"
	clear_all_button.tooltip_text = (
		"Turns off every known field in memory. Unknown imported fields remain preserved until explicitly mapped."
	)
	clear_all_button.pressed.connect(_clear_front_porch_group_v0172.bind(""))
	action_row.add_child(clear_all_button)

	_front_porch_adult_toggle_v0172 = CheckBox.new()
	_front_porch_adult_toggle_v0172.text = "Show and enable optional 18+ intimate-preference fields"
	_front_porch_adult_toggle_v0172.tooltip_text = (
		"This explicit session-only opt-in reveals adult fields. Existing hidden imported data remains preserved."
	)
	_front_porch_adult_toggle_v0172.toggled.connect(_on_front_porch_adult_toggled_v0172)
	header.add_child(_front_porch_adult_toggle_v0172)

	_front_porch_summary_v0172 = Label.new()
	_front_porch_summary_v0172.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_porch_summary_v0172.modulate = Color(0.64, 0.70, 0.84)
	header.add_child(_front_porch_summary_v0172)

	_front_porch_group_tabs_v0172 = TabContainer.new()
	_front_porch_group_tabs_v0172.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_front_porch_group_tabs_v0172)
	for group in _front_porch_service_v0172.groups():
		_build_front_porch_group_v0172(group)
	_update_front_porch_adult_visibility_v0172()
	_update_front_porch_summary_v0172()


func _build_front_porch_group_v0172(group: Dictionary) -> void:
	var group_id := str(group.get("id", "group"))
	var scroll := ScrollContainer.new()
	scroll.name = "front_porch_%s_v0172" % group_id
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_front_porch_group_tabs_v0172.add_child(scroll)
	_front_porch_group_tabs_v0172.set_tab_title(
		_front_porch_group_tabs_v0172.get_tab_count() - 1,
		str(group.get("label", "Front Porch"))
	)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var description := Label.new()
	description.text = str(group.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.modulate = Color(0.70, 0.73, 0.82)
	content.add_child(description)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var generate_section := Button.new()
	generate_section.text = "Generate Section"
	generate_section.tooltip_text = (
		"Propose every AI-capable field in this section, then show one review window."
	)
	generate_section.pressed.connect(
		_generate_front_porch_group_v0172.bind(group_id, false)
	)
	actions.add_child(generate_section)
	var regenerate_selected := Button.new()
	regenerate_selected.text = "Regenerate Selected"
	regenerate_selected.tooltip_text = (
		"Propose only fields whose Include box is selected."
	)
	regenerate_selected.pressed.connect(
		_generate_front_porch_group_v0172.bind(group_id, true)
	)
	actions.add_child(regenerate_selected)
	var clear_section := Button.new()
	clear_section.text = "Clear Section"
	clear_section.pressed.connect(_clear_front_porch_group_v0172.bind(group_id))
	actions.add_child(clear_section)

	for field in _front_porch_service_v0172.fields_for_group(group_id):
		_add_front_porch_field_v0172(content, field)


func _add_front_porch_field_v0172(parent: VBoxContainer, field: Dictionary) -> void:
	var field_id := str(field.get("id", ""))
	var included := _front_porch_service_v0172.is_included(_project, field)
	var value: Variant = _front_porch_service_v0172.value_for(_project, field)
	var panel := PanelContainer.new()
	panel.name = "%s_row_v0172" % field_id
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	content.add_child(heading)
	var include := CheckBox.new()
	include.text = "Include"
	include.button_pressed = included
	heading.add_child(include)
	var label := Label.new()
	label.text = str(field.get("label", field_id))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 15)
	heading.add_child(label)
	if bool(field.get("generate", false)):
		var suggest := Button.new()
		suggest.text = "AI Suggest"
		suggest.tooltip_text = "Queue this field only and review the proposal before applying it."
		suggest.pressed.connect(
			_suggest_front_porch_field_v0172.bind(field.duplicate(true))
		)
		heading.add_child(suggest)

	var input := _create_front_porch_input_v0172(field, value)
	content.add_child(input)
	_set_front_porch_input_enabled_v0172(input, included)
	include.toggled.connect(
		_on_front_porch_include_toggled_v0172.bind(field_id)
	)
	_front_porch_controls_v0172[field_id] = {
		"field": field.duplicate(true),
		"include": include,
		"input": input,
		"row": panel
	}
	if bool(field.get("adult", false)):
		_front_porch_adult_rows_v0172.append(panel)


func _create_front_porch_input_v0172(field: Dictionary, value: Variant) -> Control:
	var field_type := str(field.get("type", "line"))
	match field_type:
		"number":
			var spin := SpinBox.new()
			spin.min_value = float(field.get("minimum", -1000000))
			spin.max_value = float(field.get("maximum", 1000000))
			spin.step = float(field.get("step", 1))
			spin.value = float(value)
			spin.value_changed.connect(func(_new_value: float): _mark_dirty())
			spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			return spin
		"checkbox":
			var checkbox := CheckBox.new()
			checkbox.text = "Enabled"
			checkbox.button_pressed = bool(value)
			checkbox.toggled.connect(func(_pressed: bool): _mark_dirty())
			return checkbox
		"select":
			var options := OptionButton.new()
			var selected_index := 0
			var found := false
			for option_value in field.get("options", []):
				var index := options.item_count
				var option_text := str(option_value)
				options.add_item(option_text)
				options.set_item_metadata(index, option_text)
				if option_text == str(value):
					selected_index = index
					found = true
			if not found and not str(value).is_empty():
				selected_index = options.item_count
				options.add_item(str(value) + " • imported")
				options.set_item_metadata(selected_index, str(value))
			if options.item_count > 0:
				options.select(selected_index)
			options.item_selected.connect(func(_selected: int): _mark_dirty())
			options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			return options
		"multiline":
			var editor := TextEdit.new()
			editor.text = str(value)
			editor.placeholder_text = str(field.get("placeholder", ""))
			editor.custom_minimum_size.y = float(field.get("height", 110))
			editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			editor.text_changed.connect(_mark_dirty)
			editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			return editor
		_:
			var line := LineEdit.new()
			line.text = _front_porch_value_text_v0172(value)
			line.placeholder_text = str(field.get("placeholder", ""))
			line.text_changed.connect(func(_new_text: String): _mark_dirty())
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			return line


func _on_front_porch_include_toggled_v0172(
	enabled: bool, field_id: String
) -> void:
	var row_value: Variant = _front_porch_controls_v0172.get(field_id, {})
	if not row_value is Dictionary:
		return
	var input_value: Variant = (row_value as Dictionary).get("input")
	if input_value is Control:
		_set_front_porch_input_enabled_v0172(input_value as Control, enabled)
	_mark_dirty()
	_update_front_porch_summary_v0172()


func _set_front_porch_input_enabled_v0172(input: Control, enabled: bool) -> void:
	if input is LineEdit:
		(input as LineEdit).editable = enabled
	elif input is TextEdit:
		(input as TextEdit).editable = enabled
	elif input is SpinBox:
		(input as SpinBox).editable = enabled
	else:
		input.disabled = not enabled


func _capture_front_porch_fields_v0172() -> Dictionary:
	if _project.is_empty() or _front_porch_controls_v0172.is_empty():
		return {"ok": true, "included_count": 0}
	var result := _front_porch_service_v0172.apply_control_values(
		_project,
		_front_porch_enabled_map_v0172(),
		_front_porch_value_map_v0172(),
		_front_porch_adult_unlocked_v0172
	)
	_update_front_porch_summary_v0172()
	if not bool(result.get("ok", false)):
		_status.text = "Front Porch data needs attention: %s" % "; ".join(
			result.get("errors", [])
		)
	return result


func _front_porch_enabled_map_v0172() -> Dictionary:
	var result: Dictionary = {}
	for field_id in _front_porch_controls_v0172:
		var row: Dictionary = _front_porch_controls_v0172[field_id]
		var include_value: Variant = row.get("include")
		result[field_id] = (
			(include_value as CheckBox).button_pressed
			if include_value is CheckBox
			else false
		)
	return result


func _front_porch_value_map_v0172() -> Dictionary:
	var result: Dictionary = {}
	for field_id in _front_porch_controls_v0172:
		var row: Dictionary = _front_porch_controls_v0172[field_id]
		result[field_id] = _front_porch_input_value_v0172(
			row.get("input"), row.get("field", {})
		)
	return result


func _front_porch_input_value_v0172(
	input_value: Variant, field: Dictionary
) -> Variant:
	if input_value is LineEdit:
		var text := (input_value as LineEdit).text
		if str(field.get("type", "")) in ["tags", "integer_tags"]:
			return text.split(",", false)
		return text
	if input_value is TextEdit:
		return (input_value as TextEdit).text
	if input_value is SpinBox:
		return (input_value as SpinBox).value
	if input_value is CheckBox:
		return (input_value as CheckBox).button_pressed
	if input_value is OptionButton:
		var option := input_value as OptionButton
		return str(option.get_selected_metadata()) if option.selected >= 0 else ""
	return ""


func _front_porch_value_text_v0172(value: Variant) -> String:
	if value is Array:
		var parts: Array[String] = []
		for item in value:
			parts.append(str(item))
		return ", ".join(parts)
	return str(value)


func _on_front_porch_seed_enabled_v0172(
	enabled: bool, greeting_index: int
) -> void:
	if greeting_index < 0 or greeting_index >= _front_porch_greeting_seed_controls_v0172.size():
		return
	var seed_control := _front_porch_greeting_seed_controls_v0172[greeting_index]
	var fields_value: Variant = seed_control.get("fields", {})
	if fields_value is Dictionary:
		for field_id in fields_value:
			var field_row: Dictionary = fields_value[field_id]
			var include_value: Variant = field_row.get("include")
			var input_value: Variant = field_row.get("input")
			if input_value is Control:
				_set_front_porch_input_enabled_v0172(
					input_value as Control,
					enabled
					and include_value is CheckBox
					and (include_value as CheckBox).button_pressed
				)
	_mark_dirty()


func _on_front_porch_seed_field_toggled_v0172(
	enabled: bool, greeting_index: int, field_id: String
) -> void:
	if greeting_index < 0 or greeting_index >= _front_porch_greeting_seed_controls_v0172.size():
		return
	var seed_control := _front_porch_greeting_seed_controls_v0172[greeting_index]
	var seed_enabled_value: Variant = seed_control.get("enabled")
	var fields_value: Variant = seed_control.get("fields", {})
	if not fields_value is Dictionary:
		return
	var field_row_value: Variant = (fields_value as Dictionary).get(field_id, {})
	if not field_row_value is Dictionary:
		return
	var input_value: Variant = (field_row_value as Dictionary).get("input")
	if input_value is Control:
		_set_front_porch_input_enabled_v0172(
			input_value as Control,
			enabled
			and seed_enabled_value is CheckBox
			and (seed_enabled_value as CheckBox).button_pressed
		)
	_mark_dirty()


func _capture_front_porch_greeting_seeds_v0172() -> Dictionary:
	var all_errors: Array[String] = []
	var greetings_value: Variant = CCFStorageService.get_value_at_path(
		_project, "character.alternate_greetings", []
	)
	var greeting_count: int = greetings_value.size() if greetings_value is Array else 0
	for seed_control in _front_porch_greeting_seed_controls_v0172:
		var greeting_index := int(seed_control.get("index", -1))
		if greeting_index < 0:
			continue
		var seed_enabled_value: Variant = seed_control.get("enabled")
		var seed_enabled := (
			(seed_enabled_value as CheckBox).button_pressed
			if seed_enabled_value is CheckBox
			else false
		)
		if greeting_index >= greeting_count:
			seed_enabled = false
		var field_enabled: Dictionary = {}
		var field_values: Dictionary = {}
		var fields_value: Variant = seed_control.get("fields", {})
		if fields_value is Dictionary:
			for field_id in fields_value:
				var field_row: Dictionary = fields_value[field_id]
				var include_value: Variant = field_row.get("include")
				field_enabled[field_id] = (
					(include_value as CheckBox).button_pressed
					if include_value is CheckBox
					else false
				)
				field_values[field_id] = _front_porch_input_value_v0172(
					field_row.get("input"), field_row.get("field", {})
				)
		var result := _front_porch_service_v0172.apply_greeting_seed_values(
			_project,
			greeting_index,
			seed_enabled,
			field_enabled,
			field_values
		)
		for error_text in result.get("errors", []):
			all_errors.append(
				"Alternate %d — %s" % [greeting_index + 1, str(error_text)]
			)
	if not all_errors.is_empty():
		_status.text = "Front Porch greeting seed needs attention: %s" % "; ".join(
			all_errors
		)
	return {"ok": all_errors.is_empty(), "errors": all_errors}


func _generate_front_porch_greeting_seed_v0172(
	greeting_index: int, enabled_only: bool
) -> void:
	_capture_all_fields()
	if greeting_index < 0 or greeting_index >= _front_porch_greeting_seed_controls_v0172.size():
		return
	var seed_control := _front_porch_greeting_seed_controls_v0172[greeting_index]
	var fields_value: Variant = seed_control.get("fields", {})
	var generation_fields: Array[Dictionary] = []
	if fields_value is Dictionary:
		for raw_field in _front_porch_service_v0172.greeting_seed_fields():
			var field := raw_field.duplicate(true)
			var field_id := str(field.get("id", ""))
			var row_value: Variant = (fields_value as Dictionary).get(field_id, {})
			if enabled_only:
				if not row_value is Dictionary:
					continue
				var include_value: Variant = (row_value as Dictionary).get("include")
				if (
					not include_value is CheckBox
					or not (include_value as CheckBox).button_pressed
				):
					continue
			field["path"] = (
				"generation.front_porch_greeting_seed_review.seed_%d.%s"
				% [greeting_index, str(field.get("key_path", field_id))]
			)
			generation_fields.append(field)
	if generation_fields.is_empty():
		_status.text = "Select at least one opening-seed field before regenerating it."
		return
	if _generation_service == null or not _generation_service.has_method(
		"queue_front_porch_fields_v0172"
	):
		_status.text = "The v0.17.2 Front Porch generation service is unavailable."
		return
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var result := _generation_service.call(
		"queue_front_porch_fields_v0172",
		_project,
		generation_fields,
		profile,
		int(_generation_settings().get("retry_count", 1)),
		"Alternate %d Opening Seed" % (greeting_index + 1),
		{"front_porch_greeting_seed_index": greeting_index}
	) as Dictionary
	if not bool(result.get("ok", false)):
		_status.text = str(
			result.get("error", "Could not queue opening-seed generation.")
		)
		return
	_status.text = (
		"Front Porch opening-seed proposal queued for Alternate %d."
		% (greeting_index + 1)
	)


func _clear_front_porch_greeting_seed_v0172(greeting_index: int) -> void:
	if greeting_index < 0 or greeting_index >= _front_porch_greeting_seed_controls_v0172.size():
		return
	var seed_control := _front_porch_greeting_seed_controls_v0172[greeting_index]
	var enabled_value: Variant = seed_control.get("enabled")
	if enabled_value is CheckBox:
		(enabled_value as CheckBox).button_pressed = false
	_capture_front_porch_greeting_seeds_v0172()
	_mark_dirty()
	_status.text = (
		"Front Porch opening seed cleared for Alternate %d. Save to keep this change."
		% (greeting_index + 1)
	)


func _generate_front_porch_group_v0172(
	group_id: String, enabled_only: bool
) -> void:
	_capture_all_fields()
	var fields := _front_porch_service_v0172.generation_fields(
		group_id,
		enabled_only,
		_front_porch_enabled_map_v0172(),
		_front_porch_adult_unlocked_v0172
	)
	var group_label := group_id.replace("_", " ").capitalize()
	for group in _front_porch_service_v0172.groups():
		if str(group.get("id", "")) == group_id:
			group_label = str(group.get("label", group_label))
			break
	_queue_front_porch_fields_v0172(fields, group_label)


func _generate_enabled_front_porch_fields_v0172() -> void:
	_capture_all_fields()
	var fields := _front_porch_service_v0172.generation_fields(
		"",
		true,
		_front_porch_enabled_map_v0172(),
		_front_porch_adult_unlocked_v0172
	)
	_queue_front_porch_fields_v0172(fields, "Enabled Fields")


func _suggest_front_porch_field_v0172(field: Dictionary) -> void:
	if bool(field.get("adult", false)) and not _front_porch_adult_unlocked_v0172:
		_status.text = "Unlock optional 18+ fields before requesting that suggestion."
		return
	_capture_all_fields()
	var fields: Array[Dictionary] = [field.duplicate(true)]
	_queue_front_porch_fields_v0172(
		fields, str(field.get("label", "Front Porch Field"))
	)


func _queue_front_porch_fields_v0172(
	fields: Array[Dictionary], scope_label: String
) -> void:
	if _generation_service == null or not _generation_service.has_method(
		"queue_front_porch_fields_v0172"
	):
		_status.text = "The v0.17.2 Front Porch generation service is unavailable."
		return
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var result := _generation_service.call(
		"queue_front_porch_fields_v0172",
		_project,
		fields,
		profile,
		int(_generation_settings().get("retry_count", 1)),
		scope_label
	) as Dictionary
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue Front Porch generation."))
		return
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "Front Porch %s proposal queued%s." % [
		scope_label,
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else ""
	]


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	if job_type == "front_porch_fields":
		var origin_project_id := str(metadata.get("project_id", ""))
		if not origin_project_id.is_empty() and origin_project_id != str(
			_project.get("project_id", "")
		):
			_status.text = "Front Porch proposal discarded because its originating character is no longer active."
			return
		if data is Dictionary:
			_show_generation_preview(
				data as Dictionary,
				metadata,
				"Front Porch — %s" % str(metadata.get("front_porch_scope", "Proposal"))
			)
			_status.text = "Front Porch generation finished. Review the proposed fields before applying them."
		else:
			_status.text = "Front Porch generation returned no usable field object."
		return
	super._on_job_completed(job_id, job_type, data, metadata)


func _apply_preview() -> void:
	if _preview_metadata.has("front_porch_greeting_seed_index"):
		_apply_front_porch_greeting_seed_preview_v0172()
		return
	var front_porch_preview := int(
		_preview_metadata.get("front_porch_generation_contract", 0)
	) == 1
	if front_porch_preview:
		_apply_front_porch_fields_preview_v0172()
		return
	super._apply_preview()


func _apply_front_porch_fields_preview_v0172() -> void:
	if (
		not _preview_project_id.is_empty()
		and _preview_project_id != str(_project.get("project_id", ""))
	):
		_status.text = "This Front Porch preview belongs to a different character and was not applied."
		_hide_preview()
		return
	var enabled := _front_porch_enabled_map_v0172()
	var values := _front_porch_value_map_v0172()
	var applied_ids: Array[String] = []
	for preview_row in _preview_rows:
		var selected_value: Variant = preview_row.get("checkbox")
		if (
			not selected_value is CheckBox
			or not (selected_value as CheckBox).button_pressed
		):
			continue
		var field: Dictionary = preview_row.get("field", {})
		var field_id := str(field.get("id", ""))
		if not _front_porch_controls_v0172.has(field_id):
			continue
		enabled[field_id] = true
		values[field_id] = _front_porch_input_value_v0172(
			preview_row.get("editor"), field
		)
		applied_ids.append(field_id)
	if applied_ids.is_empty():
		_status.text = "No Front Porch fields were applied."
		_hide_preview()
		return
	var result := _front_porch_service_v0172.apply_control_values(
		_project,
		enabled,
		values,
		_front_porch_adult_unlocked_v0172
	)
	_record_generation_history(
		applied_ids, _preview_job_type, _preview_metadata
	)
	_dirty = true
	_rebuild_form()
	_update_header()
	if bool(result.get("ok", false)):
		_status.text = (
			"Applied %d Front Porch field(s). Review them, then Save when ready."
			% applied_ids.size()
		)
	else:
		_status.text = (
			"Applied valid Front Porch proposals; rejected invalid values: %s"
			% "; ".join(result.get("errors", []))
		)
	_hide_preview()


func _apply_front_porch_greeting_seed_preview_v0172() -> void:
	if (
		not _preview_project_id.is_empty()
		and _preview_project_id != str(_project.get("project_id", ""))
	):
		_status.text = (
			"This opening-seed preview belongs to a different character and was not applied."
		)
		_hide_preview()
		return
	var greeting_index := int(
		_preview_metadata.get("front_porch_greeting_seed_index", -1)
	)
	if greeting_index < 0 or greeting_index >= _front_porch_greeting_seed_controls_v0172.size():
		_status.text = "The alternate greeting for this seed preview is no longer available."
		_hide_preview()
		return
	var seed_control := _front_porch_greeting_seed_controls_v0172[greeting_index]
	var fields_value: Variant = seed_control.get("fields", {})
	if not fields_value is Dictionary:
		_hide_preview()
		return
	var applied_ids: Array[String] = []
	for preview_row in _preview_rows:
		var selected_value: Variant = preview_row.get("checkbox")
		if (
			not selected_value is CheckBox
			or not (selected_value as CheckBox).button_pressed
		):
			continue
		var field: Dictionary = preview_row.get("field", {})
		var field_id := str(field.get("id", ""))
		var seed_field_row_value: Variant = (fields_value as Dictionary).get(
			field_id, {}
		)
		if not seed_field_row_value is Dictionary:
			continue
		var seed_field_row := seed_field_row_value as Dictionary
		var include_value: Variant = seed_field_row.get("include")
		if include_value is CheckBox:
			(include_value as CheckBox).button_pressed = true
		_set_front_porch_control_value_v0172(
			seed_field_row.get("input"),
			_front_porch_input_value_v0172(preview_row.get("editor"), field),
			field
		)
		applied_ids.append(field_id)
	var seed_enabled_value: Variant = seed_control.get("enabled")
	if seed_enabled_value is CheckBox and not applied_ids.is_empty():
		(seed_enabled_value as CheckBox).button_pressed = true
	if applied_ids.is_empty():
		_status.text = "No Front Porch opening-seed fields were applied."
		_hide_preview()
		return
	_capture_front_porch_greeting_seeds_v0172()
	_record_generation_history(
		applied_ids,
		"Front Porch Alternate %d Opening Seed" % (greeting_index + 1),
		_preview_metadata
	)
	_dirty = true
	_rebuild_form()
	_update_header()
	_status.text = (
		"Applied %d Front Porch opening-seed field(s) to Alternate %d. "
		+ "Review and Save when ready."
	) % [applied_ids.size(), greeting_index + 1]
	_hide_preview()


func _set_front_porch_control_value_v0172(
	input_value: Variant, value: Variant, _field: Dictionary
) -> void:
	if input_value is LineEdit:
		(input_value as LineEdit).text = _front_porch_value_text_v0172(value)
	elif input_value is TextEdit:
		(input_value as TextEdit).text = str(value)
	elif input_value is SpinBox:
		(input_value as SpinBox).value = float(value)
	elif input_value is CheckBox:
		(input_value as CheckBox).button_pressed = bool(value)
	elif input_value is OptionButton:
		var option := input_value as OptionButton
		for index in range(option.item_count):
			if str(option.get_item_metadata(index)) == str(value):
				option.select(index)
				return
		var next_index := option.item_count
		option.add_item(str(value) + " • generated")
		option.set_item_metadata(next_index, str(value))
		option.select(next_index)


func _clear_front_porch_group_v0172(group_id: String) -> void:
	for field_id in _front_porch_controls_v0172:
		var row: Dictionary = _front_porch_controls_v0172[field_id]
		var field: Dictionary = row.get("field", {})
		if not group_id.is_empty() and str(field.get("group_id", "")) != group_id:
			continue
		if bool(field.get("adult", false)) and not _front_porch_adult_unlocked_v0172:
			continue
		var include_value: Variant = row.get("include")
		if include_value is CheckBox:
			(include_value as CheckBox).button_pressed = false
		var input_value: Variant = row.get("input")
		if input_value is Control:
			_set_front_porch_input_enabled_v0172(input_value as Control, false)
	_mark_dirty()
	_capture_front_porch_fields_v0172()
	_status.text = (
		"Known Front Porch fields cleared in memory. Save to keep this change."
		if group_id.is_empty()
		else "Front Porch section cleared in memory. Save to keep this change."
	)


func _validate_front_porch_fields_v0172() -> void:
	var capture := _capture_front_porch_fields_v0172()
	var errors: Array = capture.get("errors", [])
	var warnings: Array = capture.get("warnings", [])
	if not errors.is_empty():
		_status.text = "Front Porch validation found %d error(s): %s" % [
			errors.size(), "; ".join(errors)
		]
	elif not warnings.is_empty():
		_status.text = "Front Porch validation passed with %d warning(s): %s" % [
			warnings.size(), "; ".join(warnings)
		]
	else:
		_status.text = "Front Porch data is valid. Unset fields will not be exported."


func _on_front_porch_adult_toggled_v0172(unlocked: bool) -> void:
	_front_porch_adult_unlocked_v0172 = unlocked
	_update_front_porch_adult_visibility_v0172()
	if unlocked:
		_status.text = "Optional 18+ Front Porch fields are visible for this editing session."
	else:
		_status.text = "Optional 18+ fields are hidden. Existing imported values remain preserved."


func _update_front_porch_adult_visibility_v0172() -> void:
	for row in _front_porch_adult_rows_v0172:
		if is_instance_valid(row):
			row.visible = _front_porch_adult_unlocked_v0172


func _update_front_porch_summary_v0172() -> void:
	if _front_porch_summary_v0172 == null:
		return
	var included_count := 0
	for enabled in _front_porch_enabled_map_v0172().values():
		if bool(enabled):
			included_count += 1
	var extension_value: Variant = CCFStorageService.get_value_at_path(
		_project, "character.card_extensions.front_porch", {}
	)
	var imported_version := ""
	if extension_value is Dictionary:
		imported_version = str((extension_value as Dictionary).get("version", ""))
	var hidden_adult := false
	for field_id in ["fp_intimate_into", "fp_intimate_not_into"]:
		var field := _front_porch_service_v0172.field_by_id(field_id)
		if _front_porch_service_v0172.is_included(_project, field):
			hidden_adult = not _front_porch_adult_unlocked_v0172
			break
	_front_porch_summary_v0172.text = (
		"%d known field(s) selected%s%s. Manual changes remain local until Save."
		% [
			included_count,
			" • imported extension version %s" % imported_version if not imported_version.is_empty() else "",
			" • adult values present but hidden" if hidden_adult else ""
		]
	)


func front_porch_capabilities_v0172() -> Dictionary:
	var capabilities := _front_porch_service_v0172.capabilities()
	capabilities["workspace_tab"] = _tabs != null and _front_porch_group_tabs_v0172 != null
	capabilities["group_tabs"] = (
		_front_porch_group_tabs_v0172.get_tab_count()
		if _front_porch_group_tabs_v0172 != null
		else 0
	)
	capabilities["generation_service"] = (
		_generation_service != null
		and _generation_service.has_method("queue_front_porch_fields_v0172")
	)
	capabilities["direct_sqlite_writes"] = false
	return capabilities
