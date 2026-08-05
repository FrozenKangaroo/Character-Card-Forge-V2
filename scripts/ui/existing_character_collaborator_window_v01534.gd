class_name CCFExistingCharacterCollaboratorWindowV01534
extends Window

signal develop_requested(options: Dictionary)

const INTENT_SERVICE_V01534 = preload(
	"res://scripts/services/collaborator_character_intent_service_v01534.gd"
)

var _source_name_v01534 := ""
var _intent_v01534: OptionButton
var _description_v01534: Label
var _instruction_v01534: TextEdit
var _status_v01534: Label


func _ready() -> void:
	visible = false
	title = "Develop Existing Character in Collaborator"
	size = Vector2i(820, 690)
	min_size = Vector2i(660, 540)
	force_native = true
	transient = false
	exclusive = false
	close_requested.connect(hide)
	_build_ui_v01534()


func open_for_character_v01534(source_name: String) -> void:
	_source_name_v01534 = source_name.strip_edges()
	if _source_name_v01534.is_empty():
		_source_name_v01534 = "the active character"
	_instruction_v01534.text = ""
	_status_v01534.text = ""
	if _intent_v01534 != null and _intent_v01534.item_count > 0:
		_intent_v01534.select(0)
	_refresh_intent_v01534()
	popup_centered()


func intent_ids_v01534() -> Array[String]:
	var result: Array[String] = []
	if _intent_v01534 == null:
		return result
	for index in range(_intent_v01534.item_count):
		result.append(str(_intent_v01534.get_item_metadata(index)))
	return result


func _build_ui_v01534() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 11)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "Develop the current character as structured source"
	heading.add_theme_font_size_override("font_size", 22)
	root.add_child(heading)

	var intro := Label.new()
	intro.text = (
		"Choose the direction you want Character Collaborator to start from. The current character is captured as a read-only source snapshot: established facts stay authoritative unless you explicitly branch or change them."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.76, 0.80, 0.90)
	root.add_child(intro)

	var source_label := Label.new()
	source_label.name = "ExistingCharacterSourceLabelV01534"
	source_label.text = "Source: the active character"
	source_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source_label.add_theme_font_size_override("font_size", 16)
	root.add_child(source_label)

	var intent_label := Label.new()
	intent_label.text = "Starting direction"
	root.add_child(intent_label)
	_intent_v01534 = OptionButton.new()
	_intent_v01534.name = "ExistingCharacterIntentV01534"
	_intent_v01534.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option in INTENT_SERVICE_V01534.intent_options():
		_intent_v01534.add_item(str(option.get("label", "Development")))
		_intent_v01534.set_item_metadata(
			_intent_v01534.item_count - 1,
			str(option.get("id", "open_ended"))
		)
	_intent_v01534.item_selected.connect(func(_index: int) -> void: _refresh_intent_v01534())
	root.add_child(_intent_v01534)

	_description_v01534 = Label.new()
	_description_v01534.name = "ExistingCharacterIntentDescriptionV01534"
	_description_v01534.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_v01534.modulate = Color(0.70, 0.75, 0.86)
	root.add_child(_description_v01534)

	var instruction_label := Label.new()
	instruction_label.text = "Starting direction / details (optional)"
	root.add_child(instruction_label)
	_instruction_v01534 = TextEdit.new()
	_instruction_v01534.name = "ExistingCharacterIntentInstructionV01534"
	_instruction_v01534.custom_minimum_size.y = 190
	_instruction_v01534.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_instruction_v01534.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	root.add_child(_instruction_v01534)

	var note := Label.new()
	note.text = (
		"Opening Collaborator does not call a provider by itself and does not modify the source character. v0.15.34 establishes the source and authoring direction; later completion/apply workflows remain explicit."
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate = Color(0.66, 0.72, 0.82)
	root.add_child(note)

	_status_v01534 = Label.new()
	_status_v01534.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_v01534.modulate = Color(0.82, 0.72, 0.48)
	root.add_child(_status_v01534)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(hide)
	actions.add_child(cancel_button)
	var open_button := Button.new()
	open_button.name = "OpenExistingCharacterCollaboratorV01534"
	open_button.text = "Open in Collaborator"
	open_button.pressed.connect(_submit_v01534)
	actions.add_child(open_button)

	_refresh_intent_v01534()


func _refresh_intent_v01534() -> void:
	if _intent_v01534 == null:
		return
	var intent_id := str(_intent_v01534.get_selected_metadata())
	var option := INTENT_SERVICE_V01534.intent_by_id(intent_id)
	if _description_v01534 != null:
		_description_v01534.text = str(option.get("description", ""))
	if _instruction_v01534 != null:
		_instruction_v01534.placeholder_text = str(option.get("placeholder", ""))
	var source_label := find_child("ExistingCharacterSourceLabelV01534", true, false) as Label
	if source_label != null:
		source_label.text = "Source: %s" % _source_name_v01534


func _submit_v01534() -> void:
	if _intent_v01534 == null:
		return
	var intent_id := str(_intent_v01534.get_selected_metadata())
	var option := INTENT_SERVICE_V01534.intent_by_id(intent_id)
	if option.is_empty():
		_status_v01534.text = "Choose a valid starting direction."
		return
	develop_requested.emit({
		"intent_id": str(option.get("id", intent_id)),
		"intent_label": str(option.get("label", "Development")),
		"instruction": _instruction_v01534.text.strip_edges()
	})
	hide()
