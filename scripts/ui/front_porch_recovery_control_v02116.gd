class_name CCFFrontPorchRecoveryControlV02116
extends VBoxContainer

signal value_changed

const RAW_HIDE = preload("res://scripts/services/front_porch_rawhide_character_v02116.gd")

var _mode := OptionButton.new()
var _duration_mode := OptionButton.new()
var _minutes := SpinBox.new()
var _pcd := OptionButton.new()
var _preserved: Dictionary = {}
var _editable := true


func _init() -> void:
	_mode.name = "RecoveryMode"
	add_child(_row("Recovery mode", _mode))
	for value in RAW_HIDE.RECOVERY_MODES:
		_mode.add_item(str(value).capitalize())
		_mode.set_item_metadata(_mode.item_count - 1, value)
	_duration_mode.name = "DurationMode"
	_duration_mode.add_item("Personality decides")
	_duration_mode.set_item_metadata(0, "personality")
	_duration_mode.add_item("Fixed duration")
	_duration_mode.set_item_metadata(1, "fixed")
	add_child(_row("Hard recovery duration", _duration_mode))
	_minutes.name = "FixedMinutes"
	_minutes.min_value = 0
	_minutes.max_value = 180
	_minutes.step = 1
	add_child(_row("Fixed minutes", _minutes))
	_pcd.name = "PcdMode"
	add_child(_row("Post-climax dip", _pcd))
	for value in RAW_HIDE.PCD_MODES:
		_pcd.add_item(str(value).capitalize())
		_pcd.set_item_metadata(_pcd.item_count - 1, value)
	_mode.item_selected.connect(_mode_changed)
	_duration_mode.item_selected.connect(_duration_mode_changed)
	_minutes.value_changed.connect(func(_value: float): value_changed.emit())
	_pcd.item_selected.connect(func(_index: int): value_changed.emit())
	_refresh_duration_controls()


func _row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 190
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _mode_changed(_index: int) -> void:
	_refresh_duration_controls()
	value_changed.emit()


func _duration_mode_changed(_index: int) -> void:
	_refresh_duration_controls()
	value_changed.emit()


func _refresh_duration_controls() -> void:
	var is_hard := str(_mode.get_selected_metadata()) == "hard"
	var is_fixed := str(_duration_mode.get_selected_metadata()) == "fixed"
	_duration_mode.disabled = not _editable or not is_hard
	_minutes.editable = _editable and is_hard and is_fixed


func set_recovery_value(value: Variant) -> void:
	var recovery: Dictionary = value if value is Dictionary else {}
	_preserved = recovery.duplicate(true)
	_select(_mode, str(recovery.get("mode", "auto")))
	var duration := RAW_HIDE.explicit_recovery_minutes(recovery)
	_duration_mode.select(1 if bool(duration.get("present", false)) else 0)
	if bool(duration.get("present", false)):
		_minutes.value = float(duration.get("value", 0))
	_select(_pcd, str(recovery.get("pcd", "off")))
	_refresh_duration_controls()


func recovery_value() -> Dictionary:
	var result := _preserved.duplicate(true)
	result.merge({
		"mode": str(_mode.get_selected_metadata()),
		"pcd": str(_pcd.get_selected_metadata())
	}, true)
	if (
		str(result.mode) == "hard"
		and str(_duration_mode.get_selected_metadata()) == "fixed"
	):
		result["minutes"] = int(_minutes.value)
	else:
		result.erase("minutes")
	return result


func set_editable(enabled: bool) -> void:
	_editable = enabled
	_mode.disabled = not enabled
	_pcd.disabled = not enabled
	_refresh_duration_controls()


func _select(control: OptionButton, value: String) -> void:
	for index in range(control.item_count):
		if str(control.get_item_metadata(index)) == value:
			control.select(index)
			return
	if not value.is_empty():
		control.add_item(value + " • imported")
		control.set_item_metadata(control.item_count - 1, value)
		control.select(control.item_count - 1)
