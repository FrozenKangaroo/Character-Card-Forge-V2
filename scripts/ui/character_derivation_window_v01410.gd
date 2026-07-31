class_name CCFCharacterDerivationWindowV01410
extends Window

signal create_requested(options: Dictionary)

var _source_name := ""
var _mode: OptionButton
var _name_edit: LineEdit
var _instruction: TextEdit
var _include_card: CheckBox
var _include_shared: CheckBox
var _include_relationships: CheckBox
var _auto_generate: CheckBox
var _status: Label


func _ready() -> void:
	visible = false
	title = "Create Related Character / AI Variation"
	size = Vector2i(760, 650)
	min_size = Vector2i(620, 520)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(hide)
	_build_ui()


func open_for_character(source_name: String) -> void:
	_source_name = source_name.strip_edges()
	if _source_name.is_empty():
		_source_name = "the active character"
	_name_edit.text = ""
	_instruction.text = ""
	_mode.select(0)
	_status.text = ""
	_update_mode_hint()
	popup_centered()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "Create from the active character"
	heading.add_theme_font_size_override("font_size", 21)
	root.add_child(heading)

	var intro := Label.new()
	intro.text = "Create a new standalone character using the active character as grounded source material. The original character is never overwritten."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.70, 0.74, 0.84)
	root.add_child(intro)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	root.add_child(mode_row)
	var mode_label := Label.new()
	mode_label.text = "Type"
	mode_row.add_child(mode_label)
	_mode = OptionButton.new()
	_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mode.add_item("Related character")
	_mode.set_item_metadata(0, "related")
	_mode.add_item("Variation of this character")
	_mode.set_item_metadata(1, "variation")
	_mode.item_selected.connect(func(_index: int) -> void: _update_mode_hint())
	mode_row.add_child(_mode)

	var name_label := Label.new()
	name_label.text = "New character name (optional)"
	root.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "For example: Mika"
	root.add_child(_name_edit)

	var instruction_label := Label.new()
	instruction_label.text = "What should be created?"
	root.add_child(instruction_label)
	_instruction = TextEdit.new()
	_instruction.placeholder_text = "Example: Create her older sister who is mentioned in her backstory, preserving every established fact about the sister and filling in missing details."
	_instruction.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_instruction.custom_minimum_size.y = 190
	_instruction.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_instruction)

	_include_card = CheckBox.new()
	_include_card.text = "Use the active character card as grounding context"
	_include_card.button_pressed = true
	root.add_child(_include_card)
	_include_shared = CheckBox.new()
	_include_shared.text = "Include shared project context"
	_include_shared.button_pressed = true
	root.add_child(_include_shared)
	_include_relationships = CheckBox.new()
	_include_relationships.text = "Include established project relationships involving the source character"
	_include_relationships.button_pressed = true
	root.add_child(_include_relationships)
	_auto_generate = CheckBox.new()
	_auto_generate.text = "Start normal Generate Character flow immediately"
	_auto_generate.button_pressed = true
	root.add_child(_auto_generate)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.80, 0.72, 0.48)
	root.add_child(_status)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(hide)
	actions.add_child(cancel)
	var create := Button.new()
	create.text = "Create New Character"
	create.pressed.connect(_submit)
	actions.add_child(create)


func _update_mode_hint() -> void:
	if _instruction == null or _mode == null:
		return
	var mode_id := str(_mode.get_selected_metadata())
	if mode_id == "variation":
		_instruction.placeholder_text = "Example: Create a 35-year-old version of this character ten years later. Preserve core identity, personality, speech style and established history where they still make sense."
	else:
		_instruction.placeholder_text = "Example: Create her older sister who is mentioned in her backstory. Preserve established facts, but make the new character distinct and standalone."


func _submit() -> void:
	var instruction_text := _instruction.text.strip_edges()
	if instruction_text.is_empty():
		_status.text = "Describe the related character or variation you want to create."
		return
	create_requested.emit({
		"mode": str(_mode.get_selected_metadata()),
		"name": _name_edit.text.strip_edges(),
		"instruction": instruction_text,
		"include_source_card": _include_card.button_pressed,
		"include_shared_context": _include_shared.button_pressed,
		"include_relationships": _include_relationships.button_pressed,
		"auto_generate": _auto_generate.button_pressed
	})
	hide()
