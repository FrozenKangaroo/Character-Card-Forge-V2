class_name CCFConceptStudioWindowV01411
extends Window

signal concept_selected(concept_text: String)
signal open_ai_ideas_requested

const OPTION_SERVICE = preload("res://scripts/services/idea_generator_option_service_v01411.gd")

var _options: Dictionary = {}
var _tabs: TabContainer
var _structured_grid: GridContainer
var _field_controls: Dictionary = {}
var _custom_instructions: TextEdit
var _options_window: Window
var _field_picker: OptionButton
var _option_text: TextEdit
var _multi_toggle: CheckBox
var _max_random: SpinBox
var _options_status: Label


func _ready() -> void:
	visible = false
	title = "Concept Studio"
	size = Vector2i(980, 820)
	min_size = Vector2i(760, 620)
	force_native = true
	transient = true
	close_requested.connect(hide)
	_options = OPTION_SERVICE.load_options()
	_build_ui()
	_build_options_window()


func open_studio() -> void:
	_options = OPTION_SERVICE.load_options()
	_rebuild_structured_fields()
	popup_centered()


func _build_ui() -> void:
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
	var heading := Label.new()
	heading.text = "Concept Studio"
	heading.add_theme_font_size_override("font_size", 22)
	root.add_child(heading)
	var intro := Label.new()
	intro.text = "Use V2 AI Ideas for several prompt-driven possibilities, or build one concept from the configurable V1-style ingredient fields."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)
	_build_ai_tab()
	_build_structured_tab()
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide)
	root.add_child(close_button)


func _build_ai_tab() -> void:
	var tab := VBoxContainer.new()
	tab.name = "AI Ideas"
	tab.add_theme_constant_override("separation", 12)
	_tabs.add_child(tab)
	var description := Label.new()
	description.text = "Enter a freeform theme or scenario in the existing V2 Idea Generator, choose how many ideas to generate, then pick Use This Idea."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(description)
	var open_button := Button.new()
	open_button.text = "Open AI Idea Generator"
	open_button.pressed.connect(func() -> void:
		hide()
		open_ai_ideas_requested.emit()
	)
	tab.add_child(open_button)


func _build_structured_tab() -> void:
	var tab := VBoxContainer.new()
	tab.name = "Structured Builder"
	tab.add_theme_constant_override("separation", 8)
	_tabs.add_child(tab)
	var toolbar := HBoxContainer.new()
	tab.add_child(toolbar)
	var options_button := Button.new()
	options_button.text = "Idea Generator Options…"
	options_button.pressed.connect(_open_options)
	toolbar.add_child(options_button)
	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(_clear_structured)
	toolbar.add_child(clear_button)
	var random_button := Button.new()
	random_button.text = "Randomise Unlocked"
	random_button.pressed.connect(_randomise_structured)
	toolbar.add_child(random_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_structured_grid = GridContainer.new()
	_structured_grid.columns = 2
	_structured_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_structured_grid)
	_custom_instructions = TextEdit.new()
	_custom_instructions.custom_minimum_size = Vector2(0, 110)
	_custom_instructions.placeholder_text = "Optional extra direction for the Main Concept…"
	content.add_child(_custom_instructions)
	var generate := Button.new()
	generate.text = "Build Idea into Main Concept"
	generate.pressed.connect(_apply_structured_concept)
	content.add_child(generate)
	_rebuild_structured_fields()


func _rebuild_structured_fields() -> void:
	if _structured_grid == null:
		return
	for child in _structured_grid.get_children():
		child.queue_free()
	_field_controls.clear()
	for raw_field in _options.get("fields", []):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var block := VBoxContainer.new()
		block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = str(field.get("label", "Field"))
		block.add_child(label)
		var row := HBoxContainer.new()
		block.add_child(row)
		var edit := LineEdit.new()
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.placeholder_text = "Choose or type; separate multiple values with commas"
		row.add_child(edit)
		var menu := MenuButton.new()
		menu.text = "Choose"
		row.add_child(menu)
		var popup := menu.get_popup()
		for option_index in range(field.get("options", []).size()):
			popup.add_item(str(field.get("options", [])[option_index]), option_index)
		popup.id_pressed.connect(func(id: int) -> void:
			var value := popup.get_item_text(popup.get_item_index(id))
			if bool(field.get("multi_select", false)) and not edit.text.strip_edges().is_empty():
				var values := edit.text.split(",", false)
				if not values.has(value):
					edit.text += ", " + value
			else:
				edit.text = value
		)
		var lock := CheckBox.new()
		lock.text = "Lock"
		row.add_child(lock)
		_field_controls[str(field.get("id", ""))] = {"edit": edit, "lock": lock, "field": field}
		_structured_grid.add_child(block)


func _clear_structured() -> void:
	for control_value in _field_controls.values():
		var control: Dictionary = control_value
		(control.get("edit") as LineEdit).clear()
	_custom_instructions.clear()


func _randomise_structured() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for control_value in _field_controls.values():
		var control: Dictionary = control_value
		if (control.get("lock") as CheckBox).button_pressed:
			continue
		var field: Dictionary = control.get("field", {})
		var values: Array = field.get("options", [])
		if values.is_empty():
			continue
		var picks: Array[String] = []
		var count := 1
		if bool(field.get("multi_select", false)):
			count = rng.randi_range(1, mini(int(field.get("max_random_choices", 1)), values.size()))
		var shuffled := values.duplicate()
		shuffled.shuffle()
		for index in range(count):
			picks.append(str(shuffled[index]))
		(control.get("edit") as LineEdit).text = ", ".join(picks)


func _apply_structured_concept() -> void:
	var lines: Array[String] = []
	for control_value in _field_controls.values():
		var control: Dictionary = control_value
		var value := (control.get("edit") as LineEdit).text.strip_edges()
		if value.is_empty():
			continue
		var field: Dictionary = control.get("field", {})
		lines.append("%s: %s" % [str(field.get("label", "Field")), value])
	var extra := _custom_instructions.text.strip_edges()
	if not extra.is_empty():
		lines.append("Custom instructions: %s" % extra)
	if lines.is_empty():
		return
	concept_selected.emit("Create a coherent, playable character concept from these selected ingredients. Treat every listed ingredient as authoritative unless the custom instructions explicitly override it.\n\n" + "\n".join(lines))
	hide()


func _build_options_window() -> void:
	_options_window = Window.new()
	_options_window.visible = false
	_options_window.title = "Idea Generator Options"
	_options_window.size = Vector2i(800, 700)
	_options_window.force_native = true
	_options_window.transient = true
	_options_window.close_requested.connect(_options_window.hide)
	add_child(_options_window)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	_options_window.add_child(root)
	_field_picker = OptionButton.new()
	_field_picker.item_selected.connect(_load_option_field)
	root.add_child(_field_picker)
	_multi_toggle = CheckBox.new()
	_multi_toggle.text = "Allow multiple selections for this field"
	root.add_child(_multi_toggle)
	_max_random = SpinBox.new()
	_max_random.min_value = 1
	_max_random.max_value = 12
	root.add_child(_max_random)
	_option_text = TextEdit.new()
	_option_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_option_text.placeholder_text = "One option per line"
	root.add_child(_option_text)
	var actions := HBoxContainer.new()
	root.add_child(actions)
	for spec in [["Apply Field", "_apply_option_field"], ["Reset Field", "_reset_option_field"], ["Reset All Idea Options", "_reset_all_options"]]:
		var button := Button.new()
		button.text = spec[0]
		button.pressed.connect(Callable(self, spec[1]))
		actions.add_child(button)
	_options_status = Label.new()
	root.add_child(_options_status)


func _open_options() -> void:
	_field_picker.clear()
	for raw_field in _options.get("fields", []):
		var field: Dictionary = raw_field
		_field_picker.add_item(str(field.get("label", "Field")))
		_field_picker.set_item_metadata(_field_picker.item_count - 1, str(field.get("id", "")))
	if _field_picker.item_count > 0:
		_field_picker.select(0)
		_load_option_field(0)
	_options_window.popup_centered()


func _load_option_field(index: int) -> void:
	if index < 0:
		return
	var field := OPTION_SERVICE.field_by_id(_options, str(_field_picker.get_item_metadata(index)))
	_multi_toggle.button_pressed = bool(field.get("multi_select", false))
	_max_random.value = int(field.get("max_random_choices", 1))
	_option_text.text = "\n".join(field.get("options", []))


func _apply_option_field() -> void:
	if _field_picker.selected < 0:
		return
	var field_id := str(_field_picker.get_selected_metadata())
	var fields: Array = _options.get("fields", [])
	for index in range(fields.size()):
		if str(fields[index].get("id", "")) != field_id:
			continue
		var field: Dictionary = fields[index].duplicate(true)
		field["multi_select"] = _multi_toggle.button_pressed
		field["max_random_choices"] = int(_max_random.value)
		field["options"] = _option_text.text.split("\n", false)
		fields[index] = field
		break
	_options["fields"] = fields
	var result := OPTION_SERVICE.save_options(_options)
	_options_status.text = "Field options saved." if bool(result.get("ok", false)) else str(result.get("error", "Save failed."))
	_rebuild_structured_fields()


func _reset_option_field() -> void:
	if _field_picker.selected < 0:
		return
	_options = OPTION_SERVICE.reset_field(_options, str(_field_picker.get_selected_metadata()))
	OPTION_SERVICE.save_options(_options)
	_load_option_field(_field_picker.selected)
	_rebuild_structured_fields()
	_options_status.text = "Field reset to bundled defaults."


func _reset_all_options() -> void:
	var result := OPTION_SERVICE.reset_all()
	_options = result.get("data", OPTION_SERVICE.default_options())
	_open_options()
	_rebuild_structured_fields()
	_options_status.text = "All Idea Generator options reset."
