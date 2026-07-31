class_name CCFTextInputConventionService
extends Node


func _ready() -> void:
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
	_scan_existing(get_tree().root)


func _exit_tree() -> void:
	if get_tree() != null and get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)


func _scan_existing(node: Node) -> void:
	_attach_if_text_edit(node)
	for child in node.get_children():
		_scan_existing(child)


func _on_node_added(node: Node) -> void:
	_attach_if_text_edit(node)


func _attach_if_text_edit(node: Node) -> void:
	if not node is TextEdit:
		return
	var editor := node as TextEdit
	var callback := _on_text_edit_gui_input.bind(editor)
	if not editor.gui_input.is_connected(callback):
		editor.gui_input.connect(callback)


func _on_text_edit_gui_input(event: InputEvent, editor: TextEdit) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if not key_event.shift_pressed or key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
		return
	if key_event.keycode not in [KEY_ENTER, KEY_KP_ENTER]:
		return
	# Godot's default multiline shortcuts do not consistently map Shift+Enter on
	# every platform. Treat it as an explicit newline throughout CCF so users can
	# rely on the same convention in authoring, prompt, Q&A and future submit-style
	# editors. Plain Enter keeps each control's existing behaviour.
	editor.insert_text_at_caret("\n")
	editor.accept_event()
