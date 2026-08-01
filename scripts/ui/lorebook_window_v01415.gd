class_name CCFLorebookWindowV01415
extends "res://scripts/ui/lorebook_window_v0145.gd"

var _activation_input: TextEdit
var _activation_results: RichTextLabel


func _ready() -> void:
	super._ready()
	title = "Lorebook Manager — Generation + Trigger Preview"
	_install_scope_transfer_actions()
	_install_activation_tester()


func _install_scope_transfer_actions() -> void:
	if get_child_count() == 0:
		return
	var root := get_child(0)
	if not root is VBoxContainer or root.get_child_count() == 0:
		return
	var header := root.get_child(0)
	if not header is HFlowContainer:
		return
	var copy_button := Button.new()
	copy_button.text = "Copy to Other Scope"
	copy_button.tooltip_text = "Copy the selected lore entry between Project Lorebook and Character Lorebook."
	copy_button.pressed.connect(_copy_selected_to_other_scope)
	header.add_child(copy_button)
	var move_button := Button.new()
	move_button.text = "Move to Other Scope"
	move_button.tooltip_text = "Move the selected lore entry between Project Lorebook and Character Lorebook."
	move_button.pressed.connect(_move_selected_to_other_scope)
	header.add_child(move_button)


func _install_activation_tester() -> void:
	if get_child_count() == 0:
		return
	var root := get_child(0)
	if not root is VBoxContainer:
		return
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 170
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title_label := Label.new()
	title_label.text = "Trigger Preview"
	title_label.add_theme_font_size_override("font_size", 16)
	box.add_child(title_label)
	var hint := Label.new()
	hint.text = "Enter sample scene/conversation text to see which entries in the current scope would activate. Constant entries always activate; selective entries require both primary and secondary key matches."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.66, 0.69, 0.80)
	box.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	_activation_input = TextEdit.new()
	_activation_input.custom_minimum_size = Vector2(480, 76)
	_activation_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_activation_input.placeholder_text = "Example: {{user}} arrives at the Railway Museum and asks Mika about the old signal box…"
	row.add_child(_activation_input)
	var test_button := Button.new()
	test_button.text = "Test Triggers"
	test_button.pressed.connect(_test_current_scope_triggers)
	row.add_child(test_button)
	_activation_results = RichTextLabel.new()
	_activation_results.fit_content = true
	_activation_results.bbcode_enabled = true
	_activation_results.custom_minimum_size.y = 44
	box.add_child(_activation_results)
	var status_index := maxi(0, root.get_child_count() - 1)
	root.add_child(panel)
	root.move_child(panel, status_index)


func _test_current_scope_triggers() -> void:
	_commit_editor()
	var corpus := _activation_input.text.strip_edges()
	var lines := CCFLorebookContextServiceV01415.describe_activation(_current_book(), corpus)
	if lines.is_empty():
		_activation_results.text = "[i]No entries activate for this sample text.[/i]"
	else:
		_activation_results.text = "[b]Active entries (%d):[/b] %s" % [lines.size(), " • ".join(lines)]
	_status.text = "Trigger preview evaluated against the current lorebook scope."


func _copy_selected_to_other_scope() -> void:
	_transfer_selected_entry(false)


func _move_selected_to_other_scope() -> void:
	_transfer_selected_entry(true)


func _transfer_selected_entry(remove_source: bool) -> void:
	_commit_editor()
	var source_entries := _entries()
	if _selected_index < 0 or _selected_index >= source_entries.size():
		_status.text = "Select a lore entry first."
		return
	var raw_entry: Variant = source_entries[_selected_index]
	if not raw_entry is Dictionary:
		_status.text = "The selected lore entry is invalid."
		return
	var copied_entry: Dictionary = (raw_entry as Dictionary).duplicate(true)
	copied_entry["id"] = "%s_%s" % [str(copied_entry.get("id", "lore")), Time.get_unix_time_from_system()]
	var target_book: Dictionary = (_character_book if _scope == SCOPE_PROJECT else _project_book).duplicate(true)
	var target_entries_value: Variant = target_book.get("entries", [])
	var target_entries: Array = target_entries_value.duplicate(true) if target_entries_value is Array else []
	copied_entry["insertion_order"] = target_entries.size()
	target_entries.append(copied_entry)
	target_book["entries"] = target_entries
	if _scope == SCOPE_PROJECT:
		_character_book = target_book
	else:
		_project_book = target_book
	if remove_source:
		var source_book := _current_book().duplicate(true)
		var mutable_entries_value: Variant = source_book.get("entries", [])
		var mutable_entries: Array = mutable_entries_value.duplicate(true) if mutable_entries_value is Array else []
		mutable_entries.remove_at(_selected_index)
		source_book["entries"] = mutable_entries
		_set_current_book(source_book)
		_selected_index = min(_selected_index, mutable_entries.size() - 1)
		_refresh_entries()
		if _selected_index >= 0:
			_entry_list.select(_selected_index)
			_load_editor()
		else:
			_show_empty_editor()
	_status.text = "%s selected lore entry to the %s Lorebook. Save Lorebooks to apply." % [
		"Moved" if remove_source else "Copied",
		"Character" if _scope == SCOPE_PROJECT else "Project"
	]
