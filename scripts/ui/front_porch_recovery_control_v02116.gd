class_name CCFFrontPorchRecoveryControlV02116
extends VBoxContainer

signal value_changed

const RAW_HIDE = preload("res://scripts/services/front_porch_rawhide_character_v02116.gd")

var _mode := OptionButton.new()
var _minutes := SpinBox.new()
var _pcd := OptionButton.new()
var _preserved: Dictionary = {}


func _init() -> void:
	add_child(_row("Recovery mode", _mode))
	for value in RAW_HIDE.RECOVERY_MODES:
		_mode.add_item(str(value).capitalize())
		_mode.set_item_metadata(_mode.item_count - 1, value)
	_minutes.min_value = 0
	_minutes.max_value = 180
	_minutes.step = 1
	add_child(_row("Hard recovery minutes", _minutes))
	add_child(_row("Post-climax dip", _pcd))
	for value in RAW_HIDE.PCD_MODES:
		_pcd.add_item(str(value).capitalize())
		_pcd.set_item_metadata(_pcd.item_count - 1, value)
	_mode.item_selected.connect(_mode_changed)
	_minutes.value_changed.connect(func(_value: float): value_changed.emit())
	_pcd.item_selected.connect(func(_index: int): value_changed.emit())
	_mode_changed(0)


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
	_minutes.editable = str(_mode.get_selected_metadata()) == "hard"
	value_changed.emit()


func set_recovery_value(value: Variant) -> void:
	var recovery: Dictionary = value if value is Dictionary else {}
	_preserved = recovery.duplicate(true)
	_select(_mode, str(recovery.get("mode", "auto")))
	_minutes.value = float(recovery.get("minutes", 0))
	_select(_pcd, str(recovery.get("pcd", "off")))
	_mode_changed(_mode.selected)


func recovery_value() -> Dictionary:
	var result := _preserved.duplicate(true)
	result.merge({
		"mode": str(_mode.get_selected_metadata()),
		"pcd": str(_pcd.get_selected_metadata())
	}, true)
	if str(result.mode) == "hard":
		result["minutes"] = int(_minutes.value)
	elif str(result.mode) in RAW_HIDE.RECOVERY_MODES:
		result.erase("minutes")
	return result


func set_editable(enabled: bool) -> void:
	_mode.disabled = not enabled
	_pcd.disabled = not enabled
	_minutes.editable = enabled and str(_mode.get_selected_metadata()) == "hard"


func _select(control: OptionButton, value: String) -> void:
	for index in range(control.item_count):
		if str(control.get_item_metadata(index)) == value:
			control.select(index)
			return
	if not value.is_empty():
		control.add_item(value + " • imported")
		control.set_item_metadata(control.item_count - 1, value)
		control.select(control.item_count - 1)
