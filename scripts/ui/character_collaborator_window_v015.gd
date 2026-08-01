class_name CCFCharacterCollaboratorWindowV015
extends Window

signal sessions_changed(sessions: Array)
signal character_draft_ready(payload: Dictionary, session_title: String)

const DEFAULT_CONTEXT_WINDOW_TOKENS := 32768
const RECENT_MESSAGES_AFTER_SUMMARY := 8

var _generation_service: CCFGenerationService
var _project: Dictionary = {}
var _settings: Dictionary = {}
var _template: Dictionary = {}
var _active_character_id := ""
var _sessions: Array = []
var _active_session_index := -1
var _pending_regenerate_index := -1

var _session_selector: OptionButton
var _context_list: VBoxContainer
var _chat_list: VBoxContainer
var _chat_scroll: ScrollContainer
var _input: TextEdit
var _status: Label
var _context_usage: Label
var _send_button: Button
var _regenerate_button: Button
var _previous_variant_button: Button
var _next_variant_button: Button
var _generate_button: Button
var _summarise_button: Button
var _card_dialog: FileDialog
var _image_dialog: FileDialog
var _summary_confirm: ConfirmationDialog


func _ready() -> void:
	visible = false
	title = "Character Collaborator"
	size = Vector2i(1460, 900)
	min_size = Vector2i(1040, 680)
	unresizable = false
	exclusive = false
	transient = false
	close_requested.connect(hide)
	_build_ui()
	_build_dialogs()
	hide()


func set_generation_service(service: CCFGenerationService) -> void:
	if _generation_service == service:
		return
	if _generation_service != null:
		if _generation_service.job_completed.is_connected(_on_generation_completed):
			_generation_service.job_completed.disconnect(_on_generation_completed)
		if _generation_service.job_failed.is_connected(_on_generation_failed):
			_generation_service.job_failed.disconnect(_on_generation_failed)
		if _generation_service.job_started.is_connected(_on_generation_started):
			_generation_service.job_started.disconnect(_on_generation_started)
	_generation_service = service
	if _generation_service != null:
		_generation_service.job_completed.connect(_on_generation_completed)
		_generation_service.job_failed.connect(_on_generation_failed)
		_generation_service.job_started.connect(_on_generation_started)


func open_for_project(project: Dictionary, settings: Dictionary, character_id: String, template: Dictionary) -> void:
	_project = project.duplicate(true)
	_settings = settings.duplicate(true)
	_active_character_id = character_id
	_template = template.duplicate(true)
	var raw_sessions: Variant = _project.get("collaborator_sessions", [])
	_sessions = raw_sessions.duplicate(true) if raw_sessions is Array else []
	_normalise_sessions()
	if _sessions.is_empty():
		_create_new_session(false)
	else:
		_active_session_index = clampi(_active_session_index, 0, _sessions.size() - 1) if _active_session_index >= 0 else _sessions.size() - 1
	_refresh_all()
	popup_centered()


func update_project_context(project: Dictionary, settings: Dictionary, character_id: String, template: Dictionary) -> void:
	_project = project.duplicate(true)
	_settings = settings.duplicate(true)
	_active_character_id = character_id
	_template = template.duplicate(true)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	root.add_child(toolbar)
	_session_selector = OptionButton.new()
	_session_selector.custom_minimum_size.x = 260
	_session_selector.item_selected.connect(_on_session_selected)
	toolbar.add_child(_session_selector)
	var new_session := Button.new()
	new_session.text = "New Conversation"
	new_session.pressed.connect(func(): _create_new_session(true))
	toolbar.add_child(new_session)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)
	_context_usage = Label.new()
	toolbar.add_child(_context_usage)
	_summarise_button = Button.new()
	_summarise_button.text = "Summarise Older Messages…"
	_summarise_button.pressed.connect(_request_summary)
	toolbar.add_child(_summarise_button)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 340
	root.add_child(split)

	var context_panel := VBoxContainer.new()
	context_panel.custom_minimum_size.x = 300
	context_panel.add_theme_constant_override("separation", 8)
	split.add_child(context_panel)
	var context_title := Label.new()
	context_title.text = "Reference Context"
	context_title.add_theme_font_size_override("font_size", 18)
	context_panel.add_child(context_title)
	var context_help := Label.new()
	context_help.text = "References inform the conversation but never modify project data by themselves. Images are summarised by the Vision provider before the Text provider sees them."
	context_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_panel.add_child(context_help)
	var context_actions := HFlowContainer.new()
	context_actions.add_theme_constant_override("separation", 6)
	context_panel.add_child(context_actions)
	var current_button := Button.new()
	current_button.text = "Add Current Character"
	current_button.pressed.connect(_add_current_character_context)
	context_actions.add_child(current_button)
	var card_button := Button.new()
	card_button.text = "Import JSON / V2 PNG…"
	card_button.pressed.connect(func(): _card_dialog.popup_centered_ratio(0.7))
	context_actions.add_child(card_button)
	var image_button := Button.new()
	image_button.text = "Add Reference Image…"
	image_button.pressed.connect(func(): _image_dialog.popup_centered_ratio(0.7))
	context_actions.add_child(image_button)
	var context_scroll := ScrollContainer.new()
	context_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	context_panel.add_child(context_scroll)
	_context_list = VBoxContainer.new()
	_context_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_context_list.add_theme_constant_override("separation", 6)
	context_scroll.add_child(_context_list)

	var chat_panel := VBoxContainer.new()
	chat_panel.add_theme_constant_override("separation", 8)
	split.add_child(chat_panel)
	var intro := Label.new()
	intro.text = "Bounce ideas off the AI naturally. Nothing becomes canonical until you explicitly generate a character into Workspace."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat_panel.add_child(intro)
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_panel.add_child(_chat_scroll)
	_chat_list = VBoxContainer.new()
	_chat_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_list.add_theme_constant_override("separation", 10)
	_chat_scroll.add_child(_chat_list)
	_input = TextEdit.new()
	_input.custom_minimum_size.y = 100
	_input.placeholder_text = "Talk through the character idea…  Ctrl+Enter sends."
	_input.gui_input.connect(_on_input_gui)
	chat_panel.add_child(_input)
	var chat_actions := HFlowContainer.new()
	chat_actions.add_theme_constant_override("separation", 8)
	chat_panel.add_child(chat_actions)
	_send_button = Button.new()
	_send_button.text = "Send"
	_send_button.pressed.connect(_send_message)
	chat_actions.add_child(_send_button)
	_regenerate_button = Button.new()
	_regenerate_button.text = "Regenerate Response"
	_regenerate_button.pressed.connect(_regenerate_last_response)
	chat_actions.add_child(_regenerate_button)
	_previous_variant_button = Button.new()
	_previous_variant_button.text = "◀ Previous Variant"
	_previous_variant_button.pressed.connect(func(): _move_response_variant(-1))
	chat_actions.add_child(_previous_variant_button)
	_next_variant_button = Button.new()
	_next_variant_button.text = "Next Variant ▶"
	_next_variant_button.pressed.connect(func(): _move_response_variant(1))
	chat_actions.add_child(_next_variant_button)
	var action_spacer := Control.new()
	action_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_actions.add_child(action_spacer)
	_generate_button = Button.new()
	_generate_button.text = "Generate Character → Workspace"
	_generate_button.pressed.connect(_generate_character)
	chat_actions.add_child(_generate_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.72, 0.76, 0.86)
	root.add_child(_status)


func _build_dialogs() -> void:
	_card_dialog = FileDialog.new()
	_card_dialog.visible = false
	_card_dialog.force_native = true
	_card_dialog.transient = false
	_card_dialog.exclusive = false
	_card_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_card_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_card_dialog.filters = PackedStringArray(["*.json, *.png, *.apng ; Character Card JSON / V2 PNG"])
	_card_dialog.file_selected.connect(_on_card_context_selected)
	add_child(_card_dialog)
	_card_dialog.hide()

	_image_dialog = FileDialog.new()
	_image_dialog.visible = false
	_image_dialog.force_native = true
	_image_dialog.transient = false
	_image_dialog.exclusive = false
	_image_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_image_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_image_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Reference images"])
	_image_dialog.file_selected.connect(_on_image_selected)
	add_child(_image_dialog)
	_image_dialog.hide()

	_summary_confirm = ConfirmationDialog.new()
	_summary_confirm.visible = false
	_summary_confirm.title = "Summarise Older Conversation"
	_summary_confirm.dialog_text = "Older messages will be split away from the active model context and replaced by an AI summary. The full original transcript remains stored locally, but summarisation can lose nuance, exact wording, chronology, or minor details. Continue?"
	_summary_confirm.ok_button_text = "Summarise"
	_summary_confirm.confirmed.connect(_summarise_older_messages)
	add_child(_summary_confirm)
	_summary_confirm.hide()


func _normalise_sessions() -> void:
	var cleaned: Array = []
	for raw in _sessions:
		if not raw is Dictionary:
			continue
		var session: Dictionary = raw.duplicate(true)
		if str(session.get("session_id", "")).is_empty():
			session["session_id"] = _new_session_id()
		if str(session.get("title", "")).strip_edges().is_empty():
			session["title"] = "Character Collaboration"
		if not session.get("messages", []) is Array:
			session["messages"] = []
		if not session.get("context_items", []) is Array:
			session["context_items"] = []
		session["memory_summary"] = str(session.get("memory_summary", ""))
		session["summarized_through"] = int(session.get("summarized_through", -1))
		cleaned.append(session)
	_sessions = cleaned


func _create_new_session(emit_change: bool) -> void:
	var session := {
		"session_id": _new_session_id(),
		"title": "Character Collaboration %d" % (_sessions.size() + 1),
		"messages": [],
		"context_items": [],
		"memory_summary": "",
		"summarized_through": -1,
		"created_at": Time.get_datetime_string_from_system(true),
		"updated_at": Time.get_datetime_string_from_system(true)
	}
	_sessions.append(session)
	_active_session_index = _sessions.size() - 1
	if emit_change:
		_emit_sessions_changed()
		_refresh_all()


func _active_session() -> Dictionary:
	if _active_session_index < 0 or _active_session_index >= _sessions.size():
		return {}
	return _sessions[_active_session_index]


func _store_active_session(session: Dictionary) -> void:
	if _active_session_index < 0 or _active_session_index >= _sessions.size():
		return
	session["updated_at"] = Time.get_datetime_string_from_system(true)
	_sessions[_active_session_index] = session
	_emit_sessions_changed()


func _emit_sessions_changed() -> void:
	sessions_changed.emit(_sessions.duplicate(true))


func _refresh_all() -> void:
	_refresh_session_selector()
	_refresh_context_list()
	_refresh_chat()
	_refresh_context_usage()
	_refresh_action_state()


func _refresh_session_selector() -> void:
	_session_selector.clear()
	for raw in _sessions:
		var session: Dictionary = raw
		_session_selector.add_item(str(session.get("title", "Character Collaboration")))
	if _active_session_index >= 0 and _active_session_index < _session_selector.item_count:
		_session_selector.select(_active_session_index)


func _on_session_selected(index: int) -> void:
	_active_session_index = index
	_pending_regenerate_index = -1
	_refresh_all()


func _refresh_context_list() -> void:
	for child in _context_list.get_children():
		child.queue_free()
	var session := _active_session()
	var items: Array = session.get("context_items", [])
	if items.is_empty():
		var empty := Label.new()
		empty.text = "No reference context attached."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_context_list.add_child(empty)
		return
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var row := VBoxContainer.new()
		var header := HBoxContainer.new()
		row.add_child(header)
		var label := Label.new()
		label.text = "%s • %s" % [str(item.get("type", "context")).replace("_", " ").capitalize(), str(item.get("label", "Untitled"))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(label)
		var remove := Button.new()
		remove.text = "×"
		remove.tooltip_text = "Remove this reference from the Collaborator session."
		remove.pressed.connect(func(): _remove_context_item(index))
		header.add_child(remove)
		var preview := Label.new()
		preview.text = _truncate(str(item.get("content", "")), 360)
		preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview.modulate = Color(0.70, 0.74, 0.82)
		row.add_child(preview)
		_context_list.add_child(row)


func _refresh_chat() -> void:
	for child in _chat_list.get_children():
		child.queue_free()
	var session := _active_session()
	var messages: Array = session.get("messages", [])
	if messages.is_empty():
		var empty := Label.new()
		empty.text = "Start by describing the character, asking for ideas, or attaching an existing card/image as reference."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chat_list.add_child(empty)
		return
	for index in range(messages.size()):
		var message: Dictionary = messages[index]
		var panel := VBoxContainer.new()
		var who := Label.new()
		who.text = "You" if str(message.get("role", "")) == "user" else "Character Collaborator"
		who.add_theme_font_size_override("font_size", 15)
		panel.add_child(who)
		var body := RichTextLabel.new()
		body.bbcode_enabled = false
		body.fit_content = true
		body.custom_minimum_size.y = 28
		body.text = str(message.get("content", ""))
		panel.add_child(body)
		if str(message.get("role", "")) == "assistant":
			var variants: Array = message.get("variants", [])
			if variants.size() > 1:
				var variant_index := int(message.get("variant_index", variants.size() - 1))
				var info := Label.new()
				info.text = "Response variant %d of %d" % [variant_index + 1, variants.size()]
				info.modulate = Color(0.62, 0.68, 0.82)
				panel.add_child(info)
		_chat_list.add_child(panel)
	call_deferred("_scroll_chat_to_bottom")


func _scroll_chat_to_bottom() -> void:
	if _chat_scroll != null:
		_chat_scroll.scroll_vertical = int(_chat_scroll.get_v_scroll_bar().max_value)


func _refresh_context_usage() -> void:
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var context_window := maxi(4096, int(profile.get("context_window_tokens", DEFAULT_CONTEXT_WINDOW_TOKENS)))
	var reserve := maxi(512, int(profile.get("max_output_tokens", 6000)))
	var used := _estimated_input_tokens()
	var available := maxi(1, context_window - reserve)
	var percentage := int(round(float(used) * 100.0 / float(available)))
	_context_usage.text = "Context ~%d / %d tokens (%d%%) • output reserve %d" % [used, available, percentage, reserve]
	if used > available:
		_context_usage.modulate = Color(1.0, 0.52, 0.52)
		_status.text = "Context exceeds the selected model budget. Choose a larger-context model, remove context, or summarise older messages before sending."
	elif percentage >= 85:
		_context_usage.modulate = Color(1.0, 0.78, 0.42)
	else:
		_context_usage.modulate = Color(0.72, 0.78, 0.88)


func _estimated_input_tokens() -> int:
	var text_parts: Array[String] = []
	text_parts.append(CCFGenerationServiceV015.COLLABORATOR_SYSTEM_PROMPT)
	for block in _context_blocks():
		text_parts.append(block)
	var session := _active_session()
	text_parts.append(str(session.get("memory_summary", "")))
	for raw in _active_messages_for_model():
		if raw is Dictionary:
			text_parts.append(str(raw.get("content", "")))
	return CCFGenerationService.estimate_tokens("\n\n".join(text_parts))


func _refresh_action_state() -> void:
	var session := _active_session()
	var messages: Array = session.get("messages", [])
	var has_assistant := not messages.is_empty() and str((messages[-1] as Dictionary).get("role", "")) == "assistant"
	_regenerate_button.disabled = not has_assistant or _generation_service == null or _generation_service.has_active_job()
	var variants: Array = (messages[-1] as Dictionary).get("variants", []) if has_assistant else []
	var variant_index := int((messages[-1] as Dictionary).get("variant_index", 0)) if has_assistant else 0
	_previous_variant_button.disabled = variants.size() <= 1 or variant_index <= 0
	_next_variant_button.disabled = variants.size() <= 1 or variant_index >= variants.size() - 1
	_send_button.disabled = _generation_service == null or _generation_service.has_active_job()
	_generate_button.disabled = messages.is_empty() or _generation_service == null or _generation_service.has_active_job()
	_summarise_button.disabled = messages.size() <= RECENT_MESSAGES_AFTER_SUMMARY + 2 or _generation_service == null or _generation_service.has_active_job()


func _on_input_gui(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.keycode == KEY_ENTER and key.ctrl_pressed:
			_send_message()
			_input.accept_event()


func _send_message() -> void:
	var text := _input.text.strip_edges()
	if text.is_empty():
		return
	if not _can_send_with_context_budget():
		return
	var session := _active_session()
	var messages: Array = session.get("messages", []).duplicate(true)
	messages.append({"role": "user", "content": text})
	session["messages"] = messages
	_store_active_session(session)
	_input.clear()
	_pending_regenerate_index = -1
	_refresh_all()
	_queue_reply(false)


func _queue_reply(regenerate: bool) -> void:
	if _generation_service == null or not _generation_service.has_method("queue_collaborator_reply"):
		_status.text = "The active generation service does not support Character Collaborator yet."
		return
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var retry_count := int((_settings.get("generation", {}) as Dictionary).get("retry_count", 1))
	var session := _active_session()
	var result: Dictionary = _generation_service.call(
		"queue_collaborator_reply",
		_active_messages_for_model(),
		_context_blocks(),
		str(session.get("memory_summary", "")),
		profile,
		retry_count,
		str(session.get("session_id", "")),
		regenerate
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue collaborator response."))
	_refresh_action_state()


func _regenerate_last_response() -> void:
	var session := _active_session()
	var messages: Array = session.get("messages", []).duplicate(true)
	if messages.is_empty() or not messages[-1] is Dictionary or str((messages[-1] as Dictionary).get("role", "")) != "assistant":
		return
	_pending_regenerate_index = messages.size() - 1
	if not _can_send_with_context_budget():
		_pending_regenerate_index = -1
		return
	_queue_reply(true)


func _move_response_variant(delta: int) -> void:
	var session := _active_session()
	var messages: Array = session.get("messages", []).duplicate(true)
	if messages.is_empty() or not messages[-1] is Dictionary:
		return
	var message: Dictionary = messages[-1].duplicate(true)
	var variants: Array = message.get("variants", []).duplicate(true)
	if variants.is_empty():
		return
	var variant_index := clampi(int(message.get("variant_index", variants.size() - 1)) + delta, 0, variants.size() - 1)
	message["variant_index"] = variant_index
	message["content"] = str(variants[variant_index])
	messages[-1] = message
	session["messages"] = messages
	_store_active_session(session)
	_refresh_all()


func _can_send_with_context_budget() -> bool:
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var context_window := maxi(4096, int(profile.get("context_window_tokens", DEFAULT_CONTEXT_WINDOW_TOKENS)))
	var reserve := maxi(512, int(profile.get("max_output_tokens", 6000)))
	var available := maxi(1, context_window - reserve)
	if _estimated_input_tokens() <= available:
		return true
	_status.text = "This conversation is too large for the selected model's current context budget. Summarise older messages, remove context, or choose a larger-context model."
	return false


func _request_summary() -> void:
	_summary_confirm.popup_centered(Vector2i(620, 260))


func _summarise_older_messages() -> void:
	var session := _active_session()
	var messages: Array = session.get("messages", [])
	var current_through := int(session.get("summarized_through", -1))
	var target_through := messages.size() - RECENT_MESSAGES_AFTER_SUMMARY - 1
	if target_through <= current_through:
		_status.text = "There are not enough new older messages to summarise yet."
		return
	var chunk: Array = []
	for index in range(current_through + 1, target_through + 1):
		chunk.append(messages[index])
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var retry_count := int((_settings.get("generation", {}) as Dictionary).get("retry_count", 1))
	var result: Dictionary = _generation_service.call(
		"queue_collaborator_summary",
		chunk,
		_context_blocks(),
		str(session.get("memory_summary", "")),
		profile,
		retry_count,
		str(session.get("session_id", "")),
		target_through
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue conversation summary."))


func _active_messages_for_model() -> Array:
	var session := _active_session()
	var messages: Array = session.get("messages", [])
	var start := int(session.get("summarized_through", -1)) + 1
	var end := messages.size()
	if _pending_regenerate_index >= 0:
		end = mini(end, _pending_regenerate_index)
	var result: Array = []
	for index in range(start, end):
		result.append((messages[index] as Dictionary).duplicate(true))
	return result


func _context_blocks() -> Array[String]:
	var result: Array[String] = []
	var session := _active_session()
	for raw in session.get("context_items", []):
		if not raw is Dictionary:
			continue
		var item: Dictionary = raw
		var content := str(item.get("content", "")).strip_edges()
		if content.is_empty():
			continue
		result.append("%s — %s:\n%s" % [str(item.get("type", "Reference")).replace("_", " ").capitalize(), str(item.get("label", "Untitled")), content])
	return result


func _add_current_character_context() -> void:
	var character := CCFStorageService.get_character(_project, _active_character_id)
	if character.is_empty():
		_status.text = "There is no active character to attach."
		return
	_add_context_item({
		"type": "project_character",
		"label": CCFStorageService.character_display_name(character),
		"content": JSON.stringify(character, "  "),
		"character_id": _active_character_id
	})
	_status.text = "Current project character added as Collaborator reference context."


func _on_card_context_selected(path: String) -> void:
	var result := CCFCardFormatService.load_card_file(path)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not read the selected character card."))
		return
	var normalised := CCFCardFormatService.normalise_to_v2(result.get("data", {}))
	var data: Dictionary = normalised.get("data", {})
	if data.is_empty():
		_status.text = "The selected card did not contain usable Character Card data."
		return
	_add_context_item({
		"type": "imported_character_card",
		"label": str(data.get("name", path.get_file())),
		"content": JSON.stringify(data, "  "),
		"source_path": path,
		"source_format": str(result.get("source_format", path.get_extension().to_lower()))
	})
	_status.text = "Imported %s as read-only Collaborator context. No project fields were changed." % path.get_file()


func _on_image_selected(path: String) -> void:
	if _generation_service == null or not _generation_service.has_method("queue_collaborator_vision_summary"):
		_status.text = "The active generation service does not support Collaborator vision analysis."
		return
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_VISION)
	var retry_count := int((_settings.get("generation", {}) as Dictionary).get("retry_count", 1))
	var session := _active_session()
	var result: Dictionary = _generation_service.call(
		"queue_collaborator_vision_summary",
		path,
		profile,
		retry_count,
		str(session.get("session_id", ""))
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not analyse reference image."))
	else:
		_status.text = "Reference image queued for Vision analysis. The resulting summary will be fed to the text Collaborator."


func _add_context_item(item: Dictionary) -> void:
	var session := _active_session()
	var items: Array = session.get("context_items", []).duplicate(true)
	item["context_id"] = "%s_%d" % [str(item.get("type", "context")), Time.get_ticks_usec()]
	items.append(item)
	session["context_items"] = items
	_store_active_session(session)
	_refresh_all()


func _remove_context_item(index: int) -> void:
	var session := _active_session()
	var items: Array = session.get("context_items", []).duplicate(true)
	if index < 0 or index >= items.size():
		return
	items.remove_at(index)
	session["context_items"] = items
	_store_active_session(session)
	_refresh_all()


func _generate_character() -> void:
	if not _can_send_with_context_budget():
		return
	var session := _active_session()
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var retry_count := int((_settings.get("generation", {}) as Dictionary).get("retry_count", 1))
	var result: Dictionary = _generation_service.call(
		"queue_collaborator_character",
		_active_messages_for_model(),
		_context_blocks(),
		str(session.get("memory_summary", "")),
		_template,
		profile,
		retry_count,
		str(session.get("session_id", ""))
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue character generation."))
	else:
		_status.text = "Generating a complete character draft from the collaboration. It will be added to Workspace after the model returns."


func _on_generation_started(_job_id: String, job_type: String, _label: String) -> void:
	if job_type.begins_with("collaborator_"):
		_refresh_action_state()


func _on_generation_completed(_job_id: String, job_type: String, data: Variant, metadata: Dictionary) -> void:
	if job_type == "collaborator_reply":
		_apply_reply(str(data), bool(metadata.get("regenerate", false)))
	elif job_type == "collaborator_summary":
		_apply_summary(str(data), int(metadata.get("through_index", -1)))
	elif job_type == "collaborator_vision":
		_apply_vision_summary(str(data), str(metadata.get("image_name", "Reference image")), str(metadata.get("image_path", "")))
	elif job_type == "collaborator_character" and data is Dictionary:
		var session := _active_session()
		character_draft_ready.emit((data as Dictionary).duplicate(true), str(session.get("title", "Character Collaboration")))
		_status.text = "Character draft generated and sent to Workspace."
	_refresh_all()


func _on_generation_failed(_job_id: String, job_type: String, message: String) -> void:
	if not job_type.begins_with("collaborator_"):
		return
	_pending_regenerate_index = -1
	_status.text = message
	_refresh_action_state()


func _apply_reply(text: String, regenerate: bool) -> void:
	var session := _active_session()
	var messages: Array = session.get("messages", []).duplicate(true)
	if regenerate and _pending_regenerate_index >= 0 and _pending_regenerate_index < messages.size():
		var target: Dictionary = messages[_pending_regenerate_index].duplicate(true)
		var variants: Array = target.get("variants", []).duplicate(true)
		if variants.is_empty():
			variants.append(str(target.get("content", "")))
		variants.append(text)
		target["variants"] = variants
		target["variant_index"] = variants.size() - 1
		target["content"] = text
		messages[_pending_regenerate_index] = target
	else:
		messages.append({"role": "assistant", "content": text, "variants": [text], "variant_index": 0})
	session["messages"] = messages
	_store_active_session(session)
	_pending_regenerate_index = -1
	_status.text = "Character Collaborator replied."


func _apply_summary(summary: String, through_index: int) -> void:
	var session := _active_session()
	session["memory_summary"] = summary
	session["summarized_through"] = maxi(int(session.get("summarized_through", -1)), through_index)
	_store_active_session(session)
	_status.text = "Older messages were compressed for model context. The complete original transcript is still stored locally; detail may be lost in the summary."


func _apply_vision_summary(summary: String, image_name: String, image_path: String) -> void:
	_add_context_item({
		"type": "vision_reference",
		"label": image_name,
		"content": summary,
		"source_path": image_path
	})
	_status.text = "Vision analysis added as reference context for the text Collaborator."


func _new_session_id() -> String:
	return "collab_%d_%d" % [int(Time.get_unix_time_from_system()), randi_range(1000, 9999)]


func _truncate(text: String, limit: int) -> String:
	var clean := text.strip_edges()
	return clean if clean.length() <= limit else clean.left(limit - 1) + "…"
