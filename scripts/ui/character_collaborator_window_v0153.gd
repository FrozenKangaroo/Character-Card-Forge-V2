class_name CCFCharacterCollaboratorWindowV0153
extends "res://scripts/ui/character_collaborator_window_v0151.gd"

var _active_collaborator_job_type_v0153 := ""


func _ready() -> void:
	super._ready()
	if _input != null:
		_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		_input.tooltip_text = "Ctrl+Enter sends. Long pasted text wraps automatically."


func _refresh_chat() -> void:
	for child in _chat_list.get_children():
		child.queue_free()
	var session := _active_session()
	var messages: Array = session.get("messages", [])
	if messages.is_empty() and _active_collaborator_job_type_v0153.is_empty():
		var empty := Label.new()
		empty.text = "Start by describing the character, asking for ideas, or attaching an existing card/image as reference."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chat_list.add_child(empty)
	else:
		for index in range(messages.size()):
			var message: Dictionary = messages[index]
			_chat_list.add_child(_build_message_card_v0153(message))
	if not _active_collaborator_job_type_v0153.is_empty():
		_chat_list.add_child(_build_working_card_v0153())
	call_deferred("_scroll_chat_to_bottom")


func _build_message_card_v0153(message: Dictionary) -> Control:
	var role := str(message.get("role", ""))
	var is_user := role == "user"
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.115, 0.145, 0.215, 1.0) if is_user else Color(0.105, 0.105, 0.13, 1.0)
	style.border_color = Color(0.31, 0.43, 0.72, 0.85) if is_user else Color(0.39, 0.31, 0.52, 0.85)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	var who := Label.new()
	who.text = "You" if is_user else "Character Collaborator"
	who.add_theme_font_size_override("font_size", 15)
	who.modulate = Color(0.72, 0.82, 1.0) if is_user else Color(0.91, 0.76, 1.0)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(who)
	var copy_button := Button.new()
	copy_button.text = "Copy"
	copy_button.tooltip_text = "Copy this message text to the clipboard."
	var message_text := str(message.get("content", ""))
	copy_button.pressed.connect(func(): DisplayServer.clipboard_set(message_text))
	header.add_child(copy_button)

	var body := RichTextLabel.new()
	body.bbcode_enabled = false
	body.fit_content = true
	body.selection_enabled = true
	body.context_menu_enabled = true
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.y = 30
	body.text = message_text
	content.add_child(body)

	if not is_user:
		var variants: Array = message.get("variants", [])
		if variants.size() > 1:
			var variant_index := int(message.get("variant_index", variants.size() - 1))
			var info := Label.new()
			info.text = "Response variant %d of %d" % [variant_index + 1, variants.size()]
			info.modulate = Color(0.66, 0.69, 0.82)
			content.add_child(info)
	return panel


func _build_working_card_v0153() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.09, 0.14, 1.0)
	style.border_color = Color(0.56, 0.37, 0.72, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = _working_text_v0153()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color(0.91, 0.78, 1.0)
	panel.add_child(label)
	return panel


func _working_text_v0153() -> String:
	match _active_collaborator_job_type_v0153:
		"collaborator_reply": return "Character Collaborator is thinking…"
		"collaborator_summary": return "Character Collaborator is summarising older messages…"
		"collaborator_vision": return "Character Collaborator is analysing the reference image…"
		"collaborator_character": return "Character Collaborator is generating the Workspace character draft…"
		_: return "Character Collaborator is working…"


func _scroll_chat_to_bottom() -> void:
	if (
		_chat_scroll == null
		or not is_instance_valid(_chat_scroll)
		or not is_inside_tree()
	):
		return
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	await scene_tree.process_frame
	if (
		_chat_scroll == null
		or not is_instance_valid(_chat_scroll)
		or not is_inside_tree()
		or get_tree() != scene_tree
	):
		return
	await scene_tree.process_frame
	if (
		_chat_scroll == null
		or not is_instance_valid(_chat_scroll)
		or not is_inside_tree()
		or get_tree() != scene_tree
	):
		return
	var scroll_bar := _chat_scroll.get_v_scroll_bar()
	if scroll_bar == null or not is_instance_valid(scroll_bar):
		return
	_chat_scroll.scroll_vertical = int(scroll_bar.max_value)


func _send_message() -> void:
	super._send_message()
	call_deferred("_scroll_chat_to_bottom")


func _on_generation_started(job_id: String, job_type: String, label: String) -> void:
	if job_type.begins_with("collaborator_"):
		_active_collaborator_job_type_v0153 = job_type
		_status.text = _working_text_v0153()
		_refresh_chat()
		call_deferred("_scroll_chat_to_bottom")
	super._on_generation_started(job_id, job_type, label)


func _on_generation_completed(job_id: String, job_type: String, data: Variant, metadata: Dictionary) -> void:
	if job_type.begins_with("collaborator_"):
		_active_collaborator_job_type_v0153 = ""
	super._on_generation_completed(job_id, job_type, data, metadata)
	call_deferred("_scroll_chat_to_bottom")


func _on_generation_failed(job_id: String, job_type: String, message: String) -> void:
	if job_type.begins_with("collaborator_"):
		_active_collaborator_job_type_v0153 = ""
	super._on_generation_failed(job_id, job_type, message)
	_refresh_chat()
