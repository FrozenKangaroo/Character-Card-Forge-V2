class_name CCFFrontPorchWorkHoursControlV0209
extends VBoxContainer

signal value_changed

var _start_edit: LineEdit
var _end_edit: LineEdit
var _validation_label: Label
var _legacy_value := ""
var _loading := false


func _init() -> void:
	name = "FrontPorchWorkHoursV0209"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 5)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	_start_edit = _time_column(row, "Start", "09:00", "WorkHoursStartV0209")
	var separator := Label.new()
	separator.text = "–"
	separator.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	separator.custom_minimum_size.y = 50
	row.add_child(separator)
	_end_edit = _time_column(row, "End", "17:00", "WorkHoursEndV0209")
	_start_edit.text_changed.connect(_on_time_changed.unbind(1))
	_end_edit.text_changed.connect(_on_time_changed.unbind(1))
	_validation_label = Label.new()
	_validation_label.name = "WorkHoursValidationV0209"
	_validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_validation_label.modulate = Color(0.78, 0.67, 0.48)
	add_child(_validation_label)


func set_work_hours_value_v0209(raw_value: Variant) -> void:
	_loading = true
	var parsed := CCFFrontPorchWorkScheduleV0209.display_parts(raw_value)
	_start_edit.text = str(parsed.get("start", ""))
	_end_edit.text = str(parsed.get("end", ""))
	_legacy_value = str(parsed.get("legacy", ""))
	_loading = false
	_refresh_validation()


func work_hours_value_v0209() -> Variant:
	if (
		not _legacy_value.is_empty()
		and _start_edit.text.strip_edges().is_empty()
		and _end_edit.text.strip_edges().is_empty()
	):
		return _legacy_value
	return {
		"start": _start_edit.text.strip_edges(),
		"end": _end_edit.text.strip_edges()
	}


func set_editable_v0209(editable: bool) -> void:
	_start_edit.editable = editable
	_end_edit.editable = editable


func _time_column(
	parent: HBoxContainer, label_text: String, placeholder: String, node_name: String
) -> LineEdit:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var label := Label.new()
	label.text = label_text + " (HH:MM)"
	column.add_child(label)
	var edit := LineEdit.new()
	edit.name = node_name
	edit.placeholder_text = placeholder
	edit.max_length = 5
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(edit)
	return edit


func _on_time_changed() -> void:
	if _loading:
		return
	_legacy_value = ""
	_refresh_validation()
	value_changed.emit()


func _refresh_validation() -> void:
	var parsed := CCFFrontPorchWorkScheduleV0209.normalise(
		work_hours_value_v0209()
	)
	if bool(parsed.get("ok", false)):
		var canonical := str(parsed.get("value", ""))
		_validation_label.text = (
			"Saved for Front Porch as %s" % canonical
			if not canonical.is_empty()
			else "Set both times, or turn Include off when this character has no fixed shift."
		)
		return
	_validation_label.text = str(parsed.get("error", "Set valid Start and End times."))
	if not _legacy_value.is_empty():
		_validation_label.text += " Imported value kept until you replace it: %s" % _legacy_value
