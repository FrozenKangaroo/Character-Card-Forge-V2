class_name CCFFrontPorchNeedsOffControlV02116
extends VBoxContainer

signal value_changed

const RAW_HIDE = preload("res://scripts/services/front_porch_rawhide_character_v02116.gd")
const LABELS := {
	"hunger": "Disable Hunger",
	"bladder": "Disable Bladder",
	"energy": "Disable Energy",
	"social": "Disable Social",
	"fun": "Disable Fun",
	"hygiene": "Disable Hygiene",
	"comfort": "Disable Comfort"
}

var _checks: Dictionary = {}
var _preserved_unknown: Array[String] = []
var _unknown_label := Label.new()


func _init() -> void:
	for need_key in RAW_HIDE.NEED_KEYS:
		var check := CheckBox.new()
		check.text = str(LABELS.get(need_key, need_key.capitalize()))
		check.toggled.connect(func(_pressed: bool): value_changed.emit())
		add_child(check)
		_checks[need_key] = check
	_unknown_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unknown_label.modulate = Color(0.75, 0.68, 0.45)
	_unknown_label.visible = false
	add_child(_unknown_label)


func set_needs_off(value: Variant) -> void:
	var selected: Array = value if value is Array else []
	_preserved_unknown.clear()
	for raw_value in selected:
		var clean_value := str(raw_value).strip_edges()
		if not clean_value.is_empty() and clean_value not in RAW_HIDE.NEED_KEYS:
			_preserved_unknown.append(clean_value)
	_unknown_label.text = "Preserved imported values: %s" % ", ".join(_preserved_unknown)
	_unknown_label.visible = not _preserved_unknown.is_empty()
	for need_key in _checks:
		(_checks[need_key] as CheckBox).set_pressed_no_signal(need_key in selected)


func needs_off_value() -> Array[String]:
	var result: Array[String] = _preserved_unknown.duplicate()
	for need_key in RAW_HIDE.NEED_KEYS:
		if (_checks[need_key] as CheckBox).button_pressed:
			result.append(need_key)
	return result


func set_editable(enabled: bool) -> void:
	for check in _checks.values():
		(check as CheckBox).disabled = not enabled
