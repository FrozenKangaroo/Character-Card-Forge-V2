class_name CCFCharacterCollaboratorWindowV0154
extends "res://scripts/ui/character_collaborator_window_v0153.gd"

var _rename_session_button_v0154: Button
var _delete_session_button_v0154: Button
var _rename_session_window_v0154: Window
var _rename_session_edit_v0154: LineEdit
var _delete_session_confirm_v0154: ConfirmationDialog


func _ready() -> void:
	super._ready()
	_install_session_management_v0154()
	_build_session_management_dialogs_v0154()
	_refresh_action_state()


func _install_session_management_v0154() -> void:
	if _session_selector == null or _session_selector.get_parent() == null:
		return
	var toolbar := _session_selector.get_parent()
	_rename_session_button_v0154 = Button.new()
	_rename_session_button_v0154.text = "Rename"
	_rename_session_button_v0154.tooltip_text = "Rename the current Character Collaborator conversation."
	_rename_session_button_v0154.pressed.connect(_request_rename_session_v0154)
	toolbar.add_child(_rename_session_button_v0154)
	toolbar.move_child(_rename_session_button_v0154, mini(2, toolbar.get_child_count() - 1))

	_delete_session_button_v0154 = Button.new()
	_delete_session_button_v0154.text = "Delete"
	_delete_session_button_v0154.tooltip_text = "Delete the current Collaborator conversation. Generated characters and project data are not deleted."
	_delete_session_button_v0154.pressed.connect(_request_delete_session_v0154)
	toolbar.add_child(_delete_session_button_v0154)
	toolbar.move_child(_delete_session_button_v0154, mini(3, toolbar.get_child_count() - 1))


func _build_session_management_dialogs_v0154() -> void:
	_rename_session_window_v0154 = Window.new()
	_rename_session_window_v0154.visible = false
	_rename_session_window_v0154.title = "Rename Collaborator Conversation"
	_rename_session_window_v0154.size = Vector2i(520, 170)
	_rename_session_window_v0154.min_size = Vector2i(420, 150)
	_rename_session_window_v0154.exclusive = true
	_rename_session_window_v0154.transient = true
	_rename_session_window_v0154.close_requested.connect(_rename_session_window_v0154.hide)
	add_child(_rename_session_window_v0154)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_rename_session_window_v0154.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var label := Label.new()
	label.text = "Conversation name"
	box.add_child(label)
	_rename_session_edit_v0154 = LineEdit.new()
	_rename_session_edit_v0154.placeholder_text = "Character Collaboration"
	_rename_session_edit_v0154.text_submitted.connect(func(_text: String): _apply_rename_session_v0154())
	box.add_child(_rename_session_edit_v0154)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_rename_session_window_v0154.hide)
	actions.add_child(cancel)
	var save := Button.new()
	save.text = "Rename"
	save.pressed.connect(_apply_rename_session_v0154)
	actions.add_child(save)

	_delete_session_confirm_v0154 = ConfirmationDialog.new()
	_delete_session_confirm_v0154.visible = false
	_delete_session_confirm_v0154.title = "Delete Collaborator Conversation"
	_delete_session_confirm_v0154.ok_button_text = "Delete Conversation"
	_delete_session_confirm_v0154.confirmed.connect(_delete_active_session_v0154)
	add_child(_delete_session_confirm_v0154)
	_delete_session_confirm_v0154.hide()


func _request_rename_session_v0154() -> void:
	var session := _active_session()
	if session.is_empty():
		return
	_rename_session_edit_v0154.text = str(session.get("title", "Character Collaboration"))
	_rename_session_window_v0154.popup_centered()
	_rename_session_edit_v0154.grab_focus()
	_rename_session_edit_v0154.select_all()


func _apply_rename_session_v0154() -> void:
	var clean_name := _rename_session_edit_v0154.text.strip_edges()
	if clean_name.is_empty():
		_status.text = "Conversation name cannot be empty."
		return
	var session := _active_session()
	if session.is_empty():
		return
	session["title"] = clean_name
	_store_active_session(session)
	_rename_session_window_v0154.hide()
	_refresh_session_selector()
	_status.text = "Conversation renamed and autosaved."


func _request_delete_session_v0154() -> void:
	var session := _active_session()
	if session.is_empty():
		return
	var title_text := str(session.get("title", "Character Collaboration"))
	_delete_session_confirm_v0154.dialog_text = "Delete ‘%s’?\n\nThis removes only the saved Collaborator chat. Characters already created from it, attached source files, and other project data are not deleted." % title_text
	_delete_session_confirm_v0154.popup_centered(Vector2i(620, 250))


func _delete_active_session_v0154() -> void:
	if _active_session_index < 0 or _active_session_index >= _sessions.size():
		return
	_sessions.remove_at(_active_session_index)
	if _sessions.is_empty():
		_active_session_index = -1
		_create_new_session(false)
	else:
		_active_session_index = clampi(_active_session_index, 0, _sessions.size() - 1)
	_pending_regenerate_index = -1
	_emit_sessions_changed()
	_refresh_all()
	_status.text = "Conversation deleted. Remaining Collaborator chats were autosaved."


func _refresh_action_state() -> void:
	super._refresh_action_state()
	var busy := _generation_service != null and _generation_service.has_active_job()
	if _rename_session_button_v0154 != null:
		_rename_session_button_v0154.disabled = _sessions.is_empty() or busy
	if _delete_session_button_v0154 != null:
		_delete_session_button_v0154.disabled = _sessions.is_empty() or busy


func _build_message_card_v0153(message: Dictionary) -> Control:
	var panel := super._build_message_card_v0153(message)
	if str(message.get("role", "")) != "assistant":
		return panel
	var bodies := panel.find_children("*", "RichTextLabel", true, false)
	if bodies.is_empty():
		return panel
	var body := bodies[0] as RichTextLabel
	body.clear()
	body.bbcode_enabled = false
	_render_collaborator_rich_text_v0154(body, str(message.get("content", "")))
	return panel


func _render_collaborator_rich_text_v0154(body: RichTextLabel, source_text: String) -> void:
	var lines := source_text.split("\n", true)
	for index in range(lines.size()):
		var line := str(lines[index])
		var heading_level := _heading_level_v0154(line)
		if heading_level > 0:
			_render_heading_v0154(body, line.substr(heading_level + 1), heading_level)
		elif line.strip_edges() == "---":
			body.push_color(Color(0.48, 0.44, 0.58))
			body.add_text("────────────────────────────────")
			body.pop()
		elif _is_whole_italic_v0154(line):
			body.push_color(Color(0.68, 0.79, 0.84))
			body.push_italics()
			_render_inline_v0154(body, line.substr(1, line.length() - 2))
			body.pop()
			body.pop()
		elif line.begins_with("- **") and _render_semantic_bullet_v0154(body, line):
			pass
		elif line.begins_with("- "):
			body.push_color(Color(0.72, 0.68, 0.88))
			body.add_text("• ")
			body.pop()
			_render_inline_v0154(body, line.substr(2))
		else:
			_render_inline_v0154(body, line)
		if index < lines.size() - 1:
			body.add_text("\n")


func _heading_level_v0154(line: String) -> int:
	for level in range(4, 0, -1):
		var prefix := "#".repeat(level) + " "
		if line.begins_with(prefix):
			return level
	return 0


func _render_heading_v0154(body: RichTextLabel, text: String, level: int) -> void:
	var size_value := 24 - ((level - 1) * 2)
	var heading_color := Color(0.90, 0.69, 1.0) if level >= 3 else Color(0.69, 0.80, 1.0)
	body.push_font_size(size_value)
	body.push_color(heading_color)
	body.push_bold()
	_render_inline_v0154(body, text.strip_edges())
	body.pop()
	body.pop()
	body.pop()


func _is_whole_italic_v0154(line: String) -> bool:
	var stripped := line.strip_edges()
	return stripped.length() >= 3 and stripped.begins_with("*") and stripped.ends_with("*") and not stripped.begins_with("**")


func _render_semantic_bullet_v0154(body: RichTextLabel, line: String) -> bool:
	var payload := line.substr(2)
	if not payload.begins_with("**"):
		return false
	var close_index := payload.find("**", 2)
	if close_index <= 2:
		return false
	var label_text := payload.substr(2, close_index - 2).strip_edges()
	var rest := payload.substr(close_index + 2).strip_edges()
	var semantic_key := label_text.trim_suffix(":").to_lower()
	body.push_color(_semantic_color_v0154(semantic_key))
	body.push_bold()
	body.add_text("• %s" % label_text)
	body.pop()
	body.pop()
	if not rest.is_empty():
		body.add_text(" ")
		_render_inline_v0154(body, rest)
	return true


func _semantic_color_v0154(key: String) -> Color:
	if key.contains("behavior") or key.contains("behaviour"):
		return Color(0.49, 0.78, 1.0)
	if key.contains("dialogue") or key.contains("example") or key.contains("sample"):
		return Color(0.56, 0.90, 0.70)
	if key.contains("effect") or key.contains("result") or key.contains("impact"):
		return Color(0.80, 0.67, 1.0)
	if key.contains("drawback") or key.contains("risk") or key.contains("warning"):
		return Color(1.0, 0.69, 0.43)
	if key.contains("motive") or key.contains("reason"):
		return Color(0.53, 0.86, 0.84)
	return Color(0.82, 0.75, 1.0)


func _render_inline_v0154(body: RichTextLabel, text: String) -> void:
	var cursor := 0
	while cursor < text.length():
		if text.substr(cursor, 2) == "**":
			var bold_end := text.find("**", cursor + 2)
			if bold_end >= 0:
				body.push_bold()
				body.add_text(text.substr(cursor + 2, bold_end - cursor - 2))
				body.pop()
				cursor = bold_end + 2
				continue
		if text.substr(cursor, 1) == "*":
			var italic_end := text.find("*", cursor + 1)
			if italic_end >= 0:
				body.push_italics()
				body.add_text(text.substr(cursor + 1, italic_end - cursor - 1))
				body.pop()
				cursor = italic_end + 1
				continue
		var next_marker := text.find("*", cursor)
		if next_marker < 0:
			body.add_text(text.substr(cursor))
			break
		if next_marker > cursor:
			body.add_text(text.substr(cursor, next_marker - cursor))
			cursor = next_marker
		else:
			body.add_text("*")
			cursor += 1
