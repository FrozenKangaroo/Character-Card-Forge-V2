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
