class_name CCFFrontPorchStringListControlV02116
extends VBoxContainer

signal value_changed

var _items_box := VBoxContainer.new()
var _add_button := Button.new()
var _editable := true
var _loading := false


func _init() -> void:
	name = "FrontPorchStringListV02116"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	_items_box.name = "ItemsV02116"
	_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_box.add_theme_constant_override("separation", 6)
	add_child(_items_box)
	_add_button.name = "AddItemV02116"
	_add_button.text = "+ Add item"
	_add_button.tooltip_text = (
		"Add one independent Front Porch list item. Commas and line breaks inside an item are preserved."
	)
	_add_button.pressed.connect(_add_item.bind("", true))
	add_child(_add_button)


func set_items(value: Variant) -> void:
	_loading = true
	for child in _items_box.get_children():
		_items_box.remove_child(child)
		child.queue_free()
	if value is Array:
		for item in value as Array:
			_add_item(str(item), false)
	elif value is PackedStringArray:
		for item in value as PackedStringArray:
			_add_item(str(item), false)
	elif value != null and not str(value).is_empty():
		# A malformed generated string is kept as one reviewable item. The
		# caller decides whether it may be selected/applied.
		_add_item(str(value), false)
	_loading = false
	_refresh_editable()


func items_value() -> Array[String]:
	var result: Array[String] = []
	for row_value in _items_box.get_children():
		if not row_value is HBoxContainer:
			continue
		var editor := (row_value as HBoxContainer).get_node_or_null("ItemTextV02116")
		if not editor is TextEdit:
			continue
		var text := (editor as TextEdit).text.strip_edges()
		if not text.is_empty():
			result.append(text)
	return result


func set_editable(enabled: bool) -> void:
	_editable = enabled
	_refresh_editable()


func item_count() -> int:
	return _items_box.get_child_count()


func item_editor(index: int) -> TextEdit:
	if index < 0 or index >= _items_box.get_child_count():
		return null
	return _items_box.get_child(index).get_node_or_null("ItemTextV02116") as TextEdit


func _add_item(initial_text: String = "", notify: bool = true) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	_items_box.add_child(row)
	var editor := TextEdit.new()
	editor.name = "ItemTextV02116"
	editor.text = initial_text
	editor.placeholder_text = "One complete item; commas remain part of this item"
	editor.custom_minimum_size.y = 58
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.text_changed.connect(_on_item_changed)
	row.add_child(editor)
	var remove_button := Button.new()
	remove_button.name = "RemoveItemV02116"
	remove_button.text = "Remove"
	remove_button.tooltip_text = "Remove this complete list item."
	remove_button.pressed.connect(_remove_item.bind(row))
	row.add_child(remove_button)
	_refresh_row_editable(row)
	if notify and not _loading:
		value_changed.emit()


func _remove_item(row: HBoxContainer) -> void:
	if not _editable:
		return
	_items_box.remove_child(row)
	row.queue_free()
	if not _loading:
		value_changed.emit()


func _on_item_changed() -> void:
	if not _loading:
		value_changed.emit()


func _refresh_editable() -> void:
	_add_button.disabled = not _editable
	for row_value in _items_box.get_children():
		if row_value is HBoxContainer:
			_refresh_row_editable(row_value as HBoxContainer)


func _refresh_row_editable(row: HBoxContainer) -> void:
	var editor := row.get_node_or_null("ItemTextV02116")
	if editor is TextEdit:
		(editor as TextEdit).editable = _editable
	var remove_button := row.get_node_or_null("RemoveItemV02116")
	if remove_button is Button:
		(remove_button as Button).disabled = not _editable
