class_name CCFLorebookWindowV0145
extends Window

signal lorebooks_saved(project_book: Dictionary, character_book: Dictionary)

const SCOPE_PROJECT := 0
const SCOPE_CHARACTER := 1

var _project_book: Dictionary = {}
var _character_book: Dictionary = {}
var _scope := SCOPE_CHARACTER
var _selected_index := -1
var _loading := false

var _scope_select: OptionButton
var _entry_list: ItemList
var _status: Label
var _name_edit: LineEdit
var _keys_edit: LineEdit
var _secondary_keys_edit: LineEdit
var _content_edit: TextEdit
var _comment_edit: LineEdit
var _enabled_check: CheckBox
var _constant_check: CheckBox
var _selective_check: CheckBox
var _case_sensitive_check: CheckBox
var _priority_spin: SpinBox
var _order_spin: SpinBox
var _position_select: OptionButton


func _ready() -> void:
	title = "Lorebook Manager"
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	size = Vector2i(1100, 720)
	min_size = Vector2i(860, 560)
	close_requested.connect(hide)
	_build_ui()


func open_for_project(project: Dictionary, active_character: Dictionary) -> void:
	_project_book = _normalise_book(project.get("lorebook", {}), "Project Lorebook")
	var character_data: Dictionary = active_character.get("character", {}) if active_character.get("character", {}) is Dictionary else {}
	_character_book = _normalise_book(character_data.get("character_book", {}), "Character Lorebook")
	_scope = SCOPE_CHARACTER
	_selected_index = -1
	if _scope_select != null:
		_scope_select.select(SCOPE_CHARACTER)
	_refresh_entries()
	_show_empty_editor()
	popup_centered_clamped(Vector2i(1100, 720), 0.92)


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12
	root.offset_top = 12
	root.offset_right = -12
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HFlowContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)
	var title_label := Label.new()
	title_label.text = "Lorebook"
	title_label.add_theme_font_size_override("font_size", 22)
	header.add_child(title_label)
	_scope_select = OptionButton.new()
	_scope_select.add_item("Project Lorebook", SCOPE_PROJECT)
	_scope_select.add_item("Character Lorebook", SCOPE_CHARACTER)
	_scope_select.select(SCOPE_CHARACTER)
	_scope_select.item_selected.connect(_on_scope_changed)
	header.add_child(_scope_select)
	var add_button := Button.new()
	add_button.text = "+ Entry"
	add_button.pressed.connect(_add_entry)
	header.add_child(add_button)
	var duplicate_button := Button.new()
	duplicate_button.text = "Duplicate"
	duplicate_button.pressed.connect(_duplicate_entry)
	header.add_child(duplicate_button)
	var delete_button := Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(_delete_entry)
	header.add_child(delete_button)
	var save_button := Button.new()
	save_button.text = "Save Lorebooks"
	save_button.pressed.connect(_save_lorebooks)
	header.add_child(save_button)

	var hint := Label.new()
	hint.text = "Project lore is shared by every character in this project. Character lore maps directly to the character's Character Card character_book data for interoperability."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.66, 0.69, 0.80)
	root.add_child(hint)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 310
	root.add_child(split)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 280
	left.add_theme_constant_override("separation", 6)
	split.add_child(left)
	var list_label := Label.new()
	list_label.text = "Entries"
	left.add_child(list_label)
	_entry_list = ItemList.new()
	_entry_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_entry_list.item_selected.connect(_on_entry_selected)
	left.add_child(_entry_list)

	var editor_scroll := ScrollContainer.new()
	editor_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(editor_scroll)
	var editor := VBoxContainer.new()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.add_theme_constant_override("separation", 8)
	editor_scroll.add_child(editor)

	_name_edit = _line_field(editor, "Entry name", "Example: Railway Museum, Magic System, Mika's Older Sister")
	_keys_edit = _line_field(editor, "Primary keys", "Comma-separated activation keys")
	_secondary_keys_edit = _line_field(editor, "Secondary keys", "Optional comma-separated selective keys")
	_comment_edit = _line_field(editor, "Author note / comment", "Private note describing what this entry is for")

	var flags := HFlowContainer.new()
	flags.add_theme_constant_override("separation", 10)
	editor.add_child(flags)
	_enabled_check = CheckBox.new(); _enabled_check.text = "Enabled"; flags.add_child(_enabled_check)
	_constant_check = CheckBox.new(); _constant_check.text = "Constant"; flags.add_child(_constant_check)
	_selective_check = CheckBox.new(); _selective_check.text = "Selective"; flags.add_child(_selective_check)
	_case_sensitive_check = CheckBox.new(); _case_sensitive_check.text = "Case sensitive"; flags.add_child(_case_sensitive_check)

	var numbers := HFlowContainer.new()
	numbers.add_theme_constant_override("separation", 10)
	editor.add_child(numbers)
	var priority_label := Label.new(); priority_label.text = "Priority"; numbers.add_child(priority_label)
	_priority_spin = SpinBox.new(); _priority_spin.min_value = -10000; _priority_spin.max_value = 10000; _priority_spin.value = 100; numbers.add_child(_priority_spin)
	var order_label := Label.new(); order_label.text = "Insertion order"; numbers.add_child(order_label)
	_order_spin = SpinBox.new(); _order_spin.min_value = 0; _order_spin.max_value = 100000; numbers.add_child(_order_spin)
	var position_label := Label.new(); position_label.text = "Position"; numbers.add_child(position_label)
	_position_select = OptionButton.new()
	_position_select.add_item("Before character", 0)
	_position_select.add_item("After character", 1)
	_position_select.add_item("Before examples", 2)
	_position_select.add_item("After examples", 3)
	numbers.add_child(_position_select)

	var content_label := Label.new()
	content_label.text = "Lore content"
	editor.add_child(content_label)
	_content_edit = TextEdit.new()
	_content_edit.custom_minimum_size.y = 300
	_content_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_edit.placeholder_text = "Write the world, location, person, rule, background, or supporting information that should become available when this lore entry is active."
	editor.add_child(_content_edit)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.70, 0.74, 0.84)
	root.add_child(_status)


func _line_field(parent: VBoxContainer, label_text: String, placeholder: String) -> LineEdit:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	var label := Label.new()
	label.text = label_text
	box.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(edit)
	return edit


func _on_scope_changed(index: int) -> void:
	_commit_editor()
	_scope = index
	_selected_index = -1
	_refresh_entries()
	_show_empty_editor()


func _current_book() -> Dictionary:
	return _project_book if _scope == SCOPE_PROJECT else _character_book


func _set_current_book(book: Dictionary) -> void:
	if _scope == SCOPE_PROJECT:
		_project_book = book
	else:
		_character_book = book


func _entries() -> Array:
	var book := _current_book()
	var value: Variant = book.get("entries", [])
	return value if value is Array else []


func _refresh_entries() -> void:
	if _entry_list == null:
		return
	_entry_list.clear()
	var entries := _entries()
	for index in range(entries.size()):
		var raw: Variant = entries[index]
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		var name := str(entry.get("name", "")).strip_edges()
		if name.is_empty():
			name = str(entry.get("comment", "")).strip_edges()
		if name.is_empty():
			name = "Lore Entry %d" % (index + 1)
		var prefix := "" if bool(entry.get("enabled", true)) else "[Off] "
		_entry_list.add_item(prefix + name)
	if _selected_index >= 0 and _selected_index < _entry_list.item_count:
		_entry_list.select(_selected_index)


func _on_entry_selected(index: int) -> void:
	_commit_editor()
	_selected_index = index
	_load_editor()


func _add_entry() -> void:
	_commit_editor()
	var book := _current_book().duplicate(true)
	var entries: Array = book.get("entries", []).duplicate(true)
	entries.append(_new_entry(entries.size()))
	book["entries"] = entries
	_set_current_book(book)
	_selected_index = entries.size() - 1
	_refresh_entries()
	_entry_list.select(_selected_index)
	_load_editor()
	_name_edit.grab_focus()
	_status.text = "Added a new lore entry."


func _duplicate_entry() -> void:
	_commit_editor()
	var entries := _entries()
	if _selected_index < 0 or _selected_index >= entries.size() or not entries[_selected_index] is Dictionary:
		_status.text = "Select an entry to duplicate."
		return
	var book := _current_book().duplicate(true)
	var copy_entries: Array = book.get("entries", []).duplicate(true)
	var copied: Dictionary = (copy_entries[_selected_index] as Dictionary).duplicate(true)
	copied["id"] = _new_entry_id()
	copied["name"] = "%s Copy" % str(copied.get("name", "Lore Entry"))
	copy_entries.insert(_selected_index + 1, copied)
	book["entries"] = copy_entries
	_set_current_book(book)
	_selected_index += 1
	_refresh_entries()
	_entry_list.select(_selected_index)
	_load_editor()
	_status.text = "Duplicated lore entry."


func _delete_entry() -> void:
	_commit_editor()
	var entries := _entries()
	if _selected_index < 0 or _selected_index >= entries.size():
		_status.text = "Select an entry to delete."
		return
	var book := _current_book().duplicate(true)
	var copy_entries: Array = book.get("entries", []).duplicate(true)
	copy_entries.remove_at(_selected_index)
	book["entries"] = copy_entries
	_set_current_book(book)
	_selected_index = min(_selected_index, copy_entries.size() - 1)
	_refresh_entries()
	if _selected_index >= 0:
		_entry_list.select(_selected_index)
		_load_editor()
	else:
		_show_empty_editor()
	_status.text = "Deleted lore entry from the draft. Save Lorebooks to apply the change."


func _load_editor() -> void:
	var entries := _entries()
	if _selected_index < 0 or _selected_index >= entries.size() or not entries[_selected_index] is Dictionary:
		_show_empty_editor()
		return
	_loading = true
	var entry: Dictionary = entries[_selected_index]
	_name_edit.text = str(entry.get("name", ""))
	_keys_edit.text = _join_strings(entry.get("keys", []))
	_secondary_keys_edit.text = _join_strings(entry.get("secondary_keys", []))
	_content_edit.text = str(entry.get("content", ""))
	_comment_edit.text = str(entry.get("comment", ""))
	_enabled_check.button_pressed = bool(entry.get("enabled", true))
	_constant_check.button_pressed = bool(entry.get("constant", false))
	_selective_check.button_pressed = bool(entry.get("selective", false))
	_case_sensitive_check.button_pressed = bool(entry.get("case_sensitive", false))
	_priority_spin.value = float(entry.get("priority", 100))
	_order_spin.value = float(entry.get("insertion_order", _selected_index))
	_position_select.select(_position_index(str(entry.get("position", "before_char"))))
	_set_editor_disabled(false)
	_loading = false


func _show_empty_editor() -> void:
	_loading = true
	_name_edit.text = ""
	_keys_edit.text = ""
	_secondary_keys_edit.text = ""
	_content_edit.text = ""
	_comment_edit.text = ""
	_enabled_check.button_pressed = true
	_constant_check.button_pressed = false
	_selective_check.button_pressed = false
	_case_sensitive_check.button_pressed = false
	_priority_spin.value = 100
	_order_spin.value = 0
	_position_select.select(0)
	_set_editor_disabled(true)
	_loading = false


func _set_editor_disabled(disabled: bool) -> void:
	for control in [_name_edit, _keys_edit, _secondary_keys_edit, _content_edit, _comment_edit, _enabled_check, _constant_check, _selective_check, _case_sensitive_check, _priority_spin, _order_spin, _position_select]:
		if control != null:
			control.set("disabled", disabled)


func _commit_editor() -> void:
	if _loading:
		return
	var entries := _entries()
	if _selected_index < 0 or _selected_index >= entries.size() or not entries[_selected_index] is Dictionary:
		return
	var book := _current_book().duplicate(true)
	var copy_entries: Array = book.get("entries", []).duplicate(true)
	var entry: Dictionary = (copy_entries[_selected_index] as Dictionary).duplicate(true)
	entry["name"] = _name_edit.text.strip_edges()
	entry["keys"] = _split_strings(_keys_edit.text)
	entry["secondary_keys"] = _split_strings(_secondary_keys_edit.text)
	entry["content"] = _content_edit.text
	entry["comment"] = _comment_edit.text.strip_edges()
	entry["enabled"] = _enabled_check.button_pressed
	entry["constant"] = _constant_check.button_pressed
	entry["selective"] = _selective_check.button_pressed
	entry["case_sensitive"] = _case_sensitive_check.button_pressed
	entry["priority"] = int(_priority_spin.value)
	entry["insertion_order"] = int(_order_spin.value)
	entry["position"] = _position_value(_position_select.selected)
	copy_entries[_selected_index] = _normalise_entry(entry, _selected_index)
	book["entries"] = copy_entries
	_set_current_book(book)
	_refresh_entries()


func _save_lorebooks() -> void:
	_commit_editor()
	lorebooks_saved.emit(_project_book.duplicate(true), _character_book.duplicate(true))
	_status.text = "Lorebooks applied to the project draft. Save the Character Project to persist them."


func _normalise_book(raw: Variant, fallback_name: String) -> Dictionary:
	var source: Dictionary = raw.duplicate(true) if raw is Dictionary else {}
	var entries: Array = []
	var raw_entries: Variant = source.get("entries", [])
	if raw_entries is Array:
		for index in range(raw_entries.size()):
			if raw_entries[index] is Dictionary:
				entries.append(_normalise_entry(raw_entries[index], index))
	return {
		"name": str(source.get("name", fallback_name)),
		"description": str(source.get("description", "")),
		"scan_depth": int(source.get("scan_depth", 4)),
		"token_budget": int(source.get("token_budget", 2048)),
		"recursive_scanning": bool(source.get("recursive_scanning", false)),
		"extensions": source.get("extensions", {}).duplicate(true) if source.get("extensions", {}) is Dictionary else {},
		"entries": entries
	}


func _normalise_entry(raw: Dictionary, index: int) -> Dictionary:
	return {
		"id": str(raw.get("id", _new_entry_id())),
		"name": str(raw.get("name", raw.get("comment", ""))),
		"keys": _normalise_string_array(raw.get("keys", [])),
		"secondary_keys": _normalise_string_array(raw.get("secondary_keys", [])),
		"content": str(raw.get("content", "")),
		"comment": str(raw.get("comment", "")),
		"enabled": bool(raw.get("enabled", true)),
		"constant": bool(raw.get("constant", false)),
		"selective": bool(raw.get("selective", false)),
		"case_sensitive": bool(raw.get("case_sensitive", false)),
		"priority": int(raw.get("priority", 100)),
		"insertion_order": int(raw.get("insertion_order", index)),
		"position": str(raw.get("position", "before_char")),
		"extensions": raw.get("extensions", {}).duplicate(true) if raw.get("extensions", {}) is Dictionary else {}
	}


func _new_entry(index: int) -> Dictionary:
	return _normalise_entry({"id": _new_entry_id(), "name": "New Lore Entry", "insertion_order": index}, index)


func _new_entry_id() -> String:
	return "lore_%s_%s" % [str(Time.get_ticks_usec()), str(randi_range(1000, 9999))]


func _normalise_string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			var text := str(item).strip_edges()
			if not text.is_empty() and not out.has(text):
				out.append(text)
	elif value is String:
		return _split_strings(value)
	return out


func _split_strings(text: String) -> Array[String]:
	var out: Array[String] = []
	for part in text.split(",", false):
		var clean := part.strip_edges()
		if not clean.is_empty() and not out.has(clean):
			out.append(clean)
	return out


func _join_strings(value: Variant) -> String:
	return ", ".join(_normalise_string_array(value))


func _position_index(value: String) -> int:
	match value:
		"after_char": return 1
		"before_example": return 2
		"after_example": return 3
		_: return 0


func _position_value(index: int) -> String:
	match index:
		1: return "after_char"
		2: return "before_example"
		3: return "after_example"
		_: return "before_char"
