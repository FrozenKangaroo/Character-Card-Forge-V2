class_name CCFWorkspaceCurrent
extends "res://scripts/ui/workspace_v0201.gd"

const FRONT_PORCH_SERVICE_CURRENT = preload(
	"res://scripts/services/front_porch_extension_service_current.gd"
)
const FRONT_PORCH_WORK_HOURS_CONTROL_V0209 = preload(
	"res://scripts/ui/front_porch_work_hours_control_v0209.gd"
)
const IDEA_GENERATOR_CURRENT = preload(
	"res://scripts/ui/idea_generator_window_current.gd"
)
const IDEA_CUSTOM_LENGTH_V0211 = preload(
	"res://scripts/services/idea_generator_custom_length_v0211.gd"
)

var _idea_custom_length_panel_v0211: VBoxContainer
var _idea_custom_target_v0211: SpinBox


func _init() -> void:
	_front_porch_service_v0172 = FRONT_PORCH_SERVICE_CURRENT.new()


func _build_concept_studio() -> void:
	_idea_generator_v01532 = IDEA_GENERATOR_CURRENT.new()
	_idea_generator_v01532.visible = false
	_idea_generator_v01532.concept_selected.connect(_on_structured_concept_selected)
	if _idea_generator_v01532.has_signal("collaborator_source_requested"):
		_idea_generator_v01532.connect(
			"collaborator_source_requested",
			Callable(self, "_on_collaborator_source_requested_v01533")
		)
	add_child(_idea_generator_v01532)
	_idea_generator_v01532.hide()
	_idea_generator_v01412 = _idea_generator_v01532
	_concept_studio = _idea_generator_v01532


func _install_idea_detail_selector_v0167() -> void:
	super._install_idea_detail_selector_v0167()
	if _idea_detail_selector_v0167 == null:
		return
	var custom_index := _idea_detail_selector_v0167.item_count
	_idea_detail_selector_v0167.add_item("Custom")
	_idea_detail_selector_v0167.set_item_metadata(custom_index, "custom")
	_idea_detail_selector_v0167.tooltip_text += (
		" Custom adds an approximate text-character target for each idea's concept."
	)
	var controls := _idea_detail_selector_v0167.get_parent() as HBoxContainer
	if controls == null or not controls.get_parent() is VBoxContainer:
		return
	var root := controls.get_parent() as VBoxContainer
	_idea_custom_length_panel_v0211 = VBoxContainer.new()
	_idea_custom_length_panel_v0211.name = "IdeaCustomLengthPanelV0211"
	_idea_custom_length_panel_v0211.add_theme_constant_override("separation", 4)
	root.add_child(_idea_custom_length_panel_v0211)
	root.move_child(
		_idea_custom_length_panel_v0211, controls.get_index() + 1
	)
	var target_row := HFlowContainer.new()
	target_row.name = "IdeaCustomLengthControlsV0211"
	target_row.add_theme_constant_override("separation", 8)
	_idea_custom_length_panel_v0211.add_child(target_row)
	var target_label := Label.new()
	target_label.text = "Target characters per idea"
	target_row.add_child(target_label)
	_idea_custom_target_v0211 = SpinBox.new()
	_idea_custom_target_v0211.name = "IdeaCustomTargetCharactersV0211"
	_idea_custom_target_v0211.min_value = (
		IDEA_CUSTOM_LENGTH_V0211.MIN_TARGET_CHARACTERS
	)
	_idea_custom_target_v0211.max_value = (
		IDEA_CUSTOM_LENGTH_V0211.MAX_TARGET_CHARACTERS
	)
	_idea_custom_target_v0211.step = 250
	_idea_custom_target_v0211.value = (
		IDEA_CUSTOM_LENGTH_V0211.DEFAULT_TARGET_CHARACTERS
	)
	_idea_custom_target_v0211.allow_greater = false
	_idea_custom_target_v0211.allow_lesser = false
	_idea_custom_target_v0211.suffix = " chars/idea"
	_idea_custom_target_v0211.custom_minimum_size.x = 210
	_idea_custom_target_v0211.tooltip_text = (
		"Approximate Unicode text-character target for each generated idea's concept field. Model compliance varies."
	)
	_idea_custom_target_v0211.value_changed.connect(
		_on_idea_custom_target_changed_v0211
	)
	target_row.add_child(_idea_custom_target_v0211)
	var guidance := Label.new()
	guidance.name = "IdeaCustomLengthGuidanceV0211"
	guidance.text = (
		"This is a soft target. CCF requests enough output capacity when possible, but the selected model controls the final length."
	)
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guidance.modulate = Color(0.64, 0.68, 0.82)
	_idea_custom_length_panel_v0211.add_child(guidance)
	_idea_custom_length_panel_v0211.hide()


func _on_idea_detail_selected_v0167(index: int) -> void:
	var selected_id := ""
	if (
		_idea_detail_selector_v0167 != null
		and index >= 0
		and index < _idea_detail_selector_v0167.item_count
	):
		selected_id = str(
			_idea_detail_selector_v0167.get_item_metadata(index)
		)
	if selected_id == "custom":
		_selected_idea_detail_level_v0167 = "custom"
		if _idea_custom_length_panel_v0211 != null:
			_idea_custom_length_panel_v0211.show()
		_refresh_idea_detail_hint_v0167()
		return
	super._on_idea_detail_selected_v0167(index)
	if _idea_custom_length_panel_v0211 != null:
		_idea_custom_length_panel_v0211.hide()


func _on_idea_custom_target_changed_v0211(_value: float) -> void:
	if _selected_idea_detail_level_v0167 == "custom":
		_refresh_idea_detail_hint_v0167()


func _refresh_idea_detail_hint_v0167() -> void:
	if _selected_idea_detail_level_v0167 != "custom":
		super._refresh_idea_detail_hint_v0167()
		return
	if _idea_detail_hint_v0167 == null:
		return
	var target := _idea_custom_target_characters_v0211()
	_idea_detail_hint_v0167.text = (
		"Custom — aim for approximately %s text characters in each idea's concept. This is model-guided, not guaranteed."
		% _format_integer_v0211(target)
	)


func _generate_ideas() -> void:
	if _selected_idea_detail_level_v0167 != "custom":
		super._generate_ideas()
		return
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	if (
		_generation_service == null
		or not _generation_service.has_method(
			"queue_idea_generation_with_custom_length_v0211"
		)
	):
		_idea_status.text = "The Custom Idea length service is unavailable."
		return
	var target := _idea_custom_target_characters_v0211()
	var result := _generation_service.call(
		"queue_idea_generation_with_custom_length_v0211",
		_idea_seed.text,
		profile,
		int(_idea_count.value),
		int(_generation_settings().get("retry_count", 1)),
		str(_project.get("project_id", "")),
		CCFSeriesService.generation_context_for_project(_project),
		target
	) as Dictionary
	if not bool(result.get("ok", false)):
		_idea_status.text = str(
			result.get("error", "Could not queue custom-length ideas.")
		)
		return
	_idea_job_id = str(result.get("job_id", ""))
	_idea_generate_button.disabled = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	var capped_note := (
		" • capped by model/profile output maximum"
		if bool(result.get("budget_limited", false))
		else ""
	)
	_idea_status.text = (
		"Queued • Custom ~%s characters/idea • request %s output tokens%s%s"
		% [
			_format_integer_v0211(target),
			_format_integer_v0211(int(result.get("request_max_tokens", 0))),
			capped_note,
			(" • behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
		]
	)


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	super._on_job_completed(job_id, job_type, data, metadata)
	if (
		job_type != "ideas"
		or str(metadata.get("idea_detail_level", "")) != "custom"
	):
		return
	var counts_value: Variant = metadata.get(
		"idea_actual_character_counts", []
	)
	if not counts_value is Array or (counts_value as Array).is_empty():
		return
	var minimum_actual := 2147483647
	var maximum_actual := 0
	var total_actual := 0
	for count_value in counts_value:
		var actual := maxi(0, int(count_value))
		minimum_actual = mini(minimum_actual, actual)
		maximum_actual = maxi(maximum_actual, actual)
		total_actual += actual
	var average_actual := int(round(
		float(total_actual) / float((counts_value as Array).size())
	))
	var target := int(metadata.get("idea_custom_target_characters", 0))
	var target_met := int(metadata.get("idea_custom_target_met_count", 0))
	_idea_status.text = (
		"Generated %d idea(s) • target ~%s characters each • actual %s–%s (average %s) • %d within the guide range."
		% [
			(counts_value as Array).size(),
			_format_integer_v0211(target),
			_format_integer_v0211(minimum_actual),
			_format_integer_v0211(maximum_actual),
			_format_integer_v0211(average_actual),
			target_met
		]
	)


func idea_custom_length_capabilities_v0211() -> Dictionary:
	var service_capabilities := {}
	if (
		_generation_service != null
		and _generation_service.has_method(
			"idea_custom_length_capabilities_v0211"
		)
	):
		service_capabilities = _generation_service.call(
			"idea_custom_length_capabilities_v0211"
		) as Dictionary
	return {
		"custom_selector": true,
		"presets_preserved": true,
		"selected_level": _selected_idea_detail_level_v0167,
		"target_characters": _idea_custom_target_characters_v0211(),
		"custom_controls_visible": (
			_idea_custom_length_panel_v0211 != null
			and _idea_custom_length_panel_v0211.visible
		),
		"service": service_capabilities
	}


func _idea_custom_target_characters_v0211() -> int:
	if _idea_custom_target_v0211 == null:
		return IDEA_CUSTOM_LENGTH_V0211.DEFAULT_TARGET_CHARACTERS
	return IDEA_CUSTOM_LENGTH_V0211.normalise_target_characters(
		int(_idea_custom_target_v0211.value)
	)


func _format_integer_v0211(value: int) -> String:
	var digits := str(maxi(0, value))
	var formatted := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			formatted += ","
		formatted += digits[index]
	return formatted


func _build_front_porch_group_v0172(group: Dictionary) -> void:
	super._build_front_porch_group_v0172(group)
	if _front_porch_group_tabs_v0172 == null:
		return
	var tab_count := _front_porch_group_tabs_v0172.get_tab_count()
	if tab_count <= 0:
		return
	var page := _front_porch_group_tabs_v0172.get_child(tab_count - 1)
	var action_rows := page.find_children("*", "HFlowContainer", true, false)
	if action_rows.is_empty() or not action_rows[0] is HFlowContainer:
		return
	var actions := action_rows[0] as HFlowContainer
	var group_id := str(group.get("id", ""))
	var select_all := Button.new()
	select_all.name = "FrontPorchSelectAll_%s_V0209" % group_id
	select_all.text = "Select All Fields"
	select_all.tooltip_text = (
		"Select every visible field in this Front Porch tab for editing or generation."
	)
	select_all.pressed.connect(
		_set_front_porch_group_selection_v0209.bind(group_id, true)
	)
	actions.add_child(select_all)
	actions.move_child(select_all, 2)
	var select_none := Button.new()
	select_none.name = "FrontPorchSelectNone_%s_V0209" % group_id
	select_none.text = "Select None"
	select_none.tooltip_text = "Clear the field selection in this Front Porch tab."
	select_none.pressed.connect(
		_set_front_porch_group_selection_v0209.bind(group_id, false)
	)
	actions.add_child(select_none)
	actions.move_child(select_none, 3)


func _create_front_porch_input_v0172(
	field: Dictionary, value: Variant
) -> Control:
	if str(field.get("id", "")) == "fp_work_hours":
		var hours := FRONT_PORCH_WORK_HOURS_CONTROL_V0209.new()
		hours.set_work_hours_value_v0209(value)
		hours.value_changed.connect(_mark_dirty)
		return hours
	return super._create_front_porch_input_v0172(field, value)


func _front_porch_input_value_v0172(
	input_value: Variant, field: Dictionary
) -> Variant:
	var raw_value: Variant
	if input_value is CCFFrontPorchWorkHoursControlV0209:
		raw_value = (
			input_value as CCFFrontPorchWorkHoursControlV0209
		).work_hours_value_v0209()
	else:
		raw_value = super._front_porch_input_value_v0172(input_value, field)
	var field_id := str(field.get("id", ""))
	if field_id not in ["fp_work_days", "fp_work_hours"]:
		return raw_value
	var normalised := (
		_front_porch_service_v0172 as CCFFrontPorchExtensionServiceCurrent
	).normalise_preview_value_v0209(field, raw_value)
	return normalised.get("value", raw_value) if bool(normalised.get("ok", false)) else raw_value


func _set_front_porch_input_enabled_v0172(
	input: Control, enabled: bool
) -> void:
	if input is CCFFrontPorchWorkHoursControlV0209:
		(input as CCFFrontPorchWorkHoursControlV0209).set_editable_v0209(enabled)
		return
	super._set_front_porch_input_enabled_v0172(input, enabled)


func _set_front_porch_control_value_v0172(
	input_value: Variant, value: Variant, field: Dictionary
) -> void:
	if input_value is CCFFrontPorchWorkHoursControlV0209:
		(
			input_value as CCFFrontPorchWorkHoursControlV0209
		).set_work_hours_value_v0209(value)
		return
	super._set_front_porch_control_value_v0172(input_value, value, field)


func _normalise_front_porch_preview_metadata_v0175(
	metadata: Dictionary
) -> Dictionary:
	var result := super._normalise_front_porch_preview_metadata_v0175(metadata)
	if int(result.get("front_porch_generation_contract", 0)) != 1:
		return result
	var preview_fields_value: Variant = result.get("preview_fields", [])
	if not preview_fields_value is Array:
		return result
	var preview_fields: Array = preview_fields_value
	for index in range(preview_fields.size()):
		var field_value: Variant = preview_fields[index]
		if not field_value is Dictionary:
			continue
		var field := (field_value as Dictionary).duplicate(true)
		if str(field.get("id", "")) == "fp_work_hours":
			field["type"] = "line"
			field["front_porch_source_type"] = "work_hours"
			preview_fields[index] = field
	result["preview_fields"] = preview_fields
	return result


func _set_front_porch_group_selection_v0209(
	group_id: String, selected: bool
) -> void:
	var changed := 0
	for field_id in _front_porch_controls_v0172:
		var row: Dictionary = _front_porch_controls_v0172[field_id]
		var field: Dictionary = row.get("field", {})
		if str(field.get("group_id", "")) != group_id:
			continue
		if bool(field.get("adult", false)) and not _front_porch_adult_unlocked_v0172:
			continue
		var include_value: Variant = row.get("include")
		var input_value: Variant = row.get("input")
		if not include_value is CheckBox:
			continue
		var include := include_value as CheckBox
		if include.button_pressed != selected:
			include.set_pressed_no_signal(selected)
			changed += 1
		if input_value is Control:
			_set_front_porch_input_enabled_v0172(input_value as Control, selected)
	_mark_dirty()
	_update_front_porch_summary_v0172()
	_status.text = "%s %d field(s) in this Front Porch tab." % [
		"Selected" if selected else "Cleared",
		changed
	]


func front_porch_current_capabilities_v0209() -> Dictionary:
	return {
		"version": "0.20.9",
		"select_all_per_tab": true,
		"typed_work_hours": true,
		"work_days_apply_normalisation": true
	}
