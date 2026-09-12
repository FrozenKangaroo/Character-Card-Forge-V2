class_name CCFTestChatWindowV0192
extends Window

const CHAT_SERVICE = preload(
	"res://scripts/services/front_porch_chat_service_v0192.gd"
)
const PROFILE_SERVICE = preload(
	"res://scripts/services/test_chat_profile_service_v0192.gd"
)
const EXCHANGE_SERVICE = preload(
	"res://scripts/services/chat_exchange_service_v0192.gd"
)

var _project: Dictionary = {}
var _project_id := ""
var _active_character_id := ""
var _remote_character_id := ""
var _service: CCFFrontPorchChatServiceV0192
var _busy := false
var _verified := false

var _connection_address: LineEdit
var _connection_username: LineEdit
var _connection_password: LineEdit
var _connection_totp: LineEdit
var _connection_status: Label
var _runtime_status: Label
var _character_status: Label

var _profile_selector: OptionButton
var _profile_name: LineEdit
var _profile_persona: OptionButton
var _profile_runtime: LineEdit
var _profile_notes: TextEdit
var _profiles: Array[Dictionary] = []
var _personas: Array[Dictionary] = []

var _session_selector: OptionButton
var _sessions: Array[Dictionary] = []
var _transcript: TextEdit
var _composer: TextEdit
var _chat_status: Label
var _streaming_text := ""

var _exchange_preview: TextEdit
var _exchange_status: Label
var _mismatch_selector: OptionButton
var _selected_import_path := ""
var _selected_inspection: Dictionary = {}
var _managed_records: Array[Dictionary] = []
var _managed_selector: OptionButton

var _import_dialog: FileDialog
var _export_fpchat_dialog: FileDialog
var _export_jsonl_dialog: FileDialog
var _fresh_confirm: ConfirmationDialog
var _delete_confirm: ConfirmationDialog
var _pending_export_bytes := PackedByteArray()
var _pending_export_format := ""


func _ready() -> void:
	visible = false
	title = "Test Chat and Chat Exchange"
	size = Vector2i(1280, 860)
	min_size = Vector2i(940, 660)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(_hide_window)
	_build_ui()
	_build_dialogs()
	_service = CHAT_SERVICE.new()
	add_child(_service)
	_service.stream_token_v0192.connect(_on_stream_token)
	_service.stream_done_v0192.connect(_on_stream_done)
	_service.stream_error_v0192.connect(_on_stream_error)
	_service.stream_chat_updated_v0192.connect(_on_stream_chat_updated)
	set_process(false)
	_load_connection()
	_refresh_personas()
	_refresh_profiles()
	_refresh_managed_records()
	hide()


func _process(_delta: float) -> void:
	if _service != null:
		_service.poll_stream()


func open_for_project(project: Dictionary, active_character_id: String) -> void:
	_project = project.duplicate(true)
	_project_id = str(project.get("project_id", ""))
	_active_character_id = active_character_id
	_refresh_character_context()
	_refresh_profiles()
	_refresh_managed_records()
	set_process(true)
	CCFToolWindowStateService.show_window(self, "test_chat_v0192", Vector2i(1280, 860))


func update_project_context(project: Dictionary, active_character_id: String) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	_project = project.duplicate(true)
	_active_character_id = active_character_id
	_refresh_character_context()


func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and project_id == _project_id


func save_window_state() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "test_chat_v0192")


func close_for_project_change() -> void:
	_hide_window()


func capabilities_v0192() -> Dictionary:
	return {
		"runtime": CCFFrontPorchChatServiceV0192.capabilities_v0192(),
		"profiles": CCFTestChatProfileServiceV0192.capabilities(),
		"exchange": CCFChatExchangeServiceV0192.capabilities()
	}


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var intro := Label.new()
	intro.text = "Run an explicit single-character test through Front Porch, or inspect and transfer portable chat files. Character Card Forge never writes to Front Porch's database."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)
	_character_status = Label.new()
	_character_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_character_status)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	_build_test_chat_tab(tabs)
	_build_exchange_tab(tabs)


func _build_test_chat_tab(tabs: TabContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Front Porch Test"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	scroll.add_child(root)

	root.add_child(_section_label("Connection (password and two-factor code are never saved)"))
	var connection_row := HBoxContainer.new()
	connection_row.add_theme_constant_override("separation", 7)
	root.add_child(connection_row)
	_connection_address = _line_edit("http://127.0.0.1:8085", 280)
	connection_row.add_child(_labelled_control("Front Porch address", _connection_address))
	_connection_username = _line_edit("Username", 150)
	connection_row.add_child(_labelled_control("Username", _connection_username))
	_connection_password = _line_edit("Password", 170)
	_connection_password.secret = true
	connection_row.add_child(_labelled_control("Password", _connection_password))
	_connection_totp = _line_edit("Optional", 90)
	_connection_totp.secret = true
	connection_row.add_child(_labelled_control("2FA code", _connection_totp))
	connection_row.add_child(_button("Connect & Verify", _connect_and_verify))
	_connection_status = _status_label()
	root.add_child(_connection_status)
	_runtime_status = _status_label()
	root.add_child(_runtime_status)

	root.add_child(_section_label("Local Test Profile"))
	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 7)
	root.add_child(profile_row)
	_profile_selector = OptionButton.new()
	_profile_selector.custom_minimum_size.x = 190
	_profile_selector.item_selected.connect(_load_selected_profile)
	profile_row.add_child(_profile_selector)
	_profile_name = _line_edit("Profile name", 180)
	profile_row.add_child(_profile_name)
	_profile_persona = OptionButton.new()
	_profile_persona.custom_minimum_size.x = 180
	profile_row.add_child(_profile_persona)
	_profile_runtime = _line_edit("Expected provider / model / preset", 270)
	_profile_runtime.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_row.add_child(_profile_runtime)
	profile_row.add_child(_button("Save Profile", _save_profile))
	profile_row.add_child(_button("Delete", _delete_profile))
	_profile_notes = TextEdit.new()
	_profile_notes.placeholder_text = "Optional test purpose, comparison notes or expected behavior. Stored locally; never added to the character."
	_profile_notes.custom_minimum_size.y = 62
	_profile_notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	root.add_child(_profile_notes)
	var profile_note := Label.new()
	profile_note.text = "Profiles select a Front Porch persona and record the runtime you intend to compare. Front Porch does not currently expose a safe per-chat model/preset switch, so CCF will not change global runtime settings."
	profile_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_note.modulate = Color(0.69, 0.73, 0.86)
	root.add_child(profile_note)

	root.add_child(_section_label("Explicit Chat Session"))
	var session_row := HBoxContainer.new()
	session_row.add_theme_constant_override("separation", 7)
	root.add_child(session_row)
	session_row.add_child(_button("Open Latest / Resume", _open_latest))
	session_row.add_child(_button("Start Fresh…", _request_start_fresh))
	_session_selector = OptionButton.new()
	_session_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	session_row.add_child(_session_selector)
	session_row.add_child(_button("Select Session", _select_session))
	session_row.add_child(_button("Delete with Backup…", _request_delete_session))
	session_row.add_child(_button("Export .fpchat", _export_fpchat))
	session_row.add_child(_button("Export JSONL", _export_jsonl))
	_transcript = TextEdit.new()
	_transcript.editable = false
	_transcript.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_transcript.custom_minimum_size.y = 260
	_transcript.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_transcript)
	_composer = TextEdit.new()
	_composer.placeholder_text = "Write a test message. Enter creates a new line; use Send when ready."
	_composer.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_composer.custom_minimum_size.y = 82
	root.add_child(_composer)
	var send_row := HBoxContainer.new()
	send_row.add_theme_constant_override("separation", 7)
	root.add_child(send_row)
	send_row.add_child(_button("Send", _send_message))
	send_row.add_child(_button("Stop", _stop_generation))
	_chat_status = _status_label()
	_chat_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	send_row.add_child(_chat_status)


func _build_exchange_tab(tabs: TabContainer) -> void:
	var root := VBoxContainer.new()
	root.name = "Chat Exchange"
	root.add_theme_constant_override("separation", 8)
	tabs.add_child(root)
	var note := Label.new()
	note.text = "Inspect .fpchat or SillyTavern JSON/JSONL before preserving or transferring it. Full Front Porch state remains opaque and byte-for-byte intact in managed copies."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(note)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 7)
	root.add_child(actions)
	actions.add_child(_button("Choose & Preview Chat…", _choose_import))
	actions.add_child(_button("Preserve Local Copy", _preserve_selected_import))
	actions.add_child(_button("Import into Front Porch…", _send_import_to_front_porch))
	_mismatch_selector = OptionButton.new()
	_mismatch_selector.add_item("Mismatch: Ask", 0)
	_mismatch_selector.add_item("Mismatch: Full restore", 1)
	_mismatch_selector.add_item("Mismatch: Dialogue only", 2)
	actions.add_child(_mismatch_selector)
	_exchange_preview = TextEdit.new()
	_exchange_preview.editable = false
	_exchange_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_exchange_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_exchange_preview)
	_exchange_status = _status_label()
	root.add_child(_exchange_status)
	var managed_row := HBoxContainer.new()
	managed_row.add_theme_constant_override("separation", 7)
	root.add_child(managed_row)
	_managed_selector = OptionButton.new()
	_managed_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	managed_row.add_child(_managed_selector)
	managed_row.add_child(_button("Refresh Managed Copies", _refresh_managed_records))
	managed_row.add_child(_button("Export Selected Copy…", _export_managed_copy))


func _build_dialogs() -> void:
	_import_dialog = _file_dialog(FileDialog.FILE_MODE_OPEN_FILE)
	_import_dialog.filters = PackedStringArray([
		"*.fpchat ; Front Porch chat",
		"*.jsonl ; SillyTavern JSONL",
		"*.json ; Compatible chat JSON"
	])
	_import_dialog.file_selected.connect(_inspect_selected_path)
	add_child(_import_dialog)
	_export_fpchat_dialog = _file_dialog(FileDialog.FILE_MODE_SAVE_FILE)
	_export_fpchat_dialog.filters = PackedStringArray(["*.fpchat ; Front Porch chat"])
	_export_fpchat_dialog.file_selected.connect(_write_pending_export)
	add_child(_export_fpchat_dialog)
	_export_jsonl_dialog = _file_dialog(FileDialog.FILE_MODE_SAVE_FILE)
	_export_jsonl_dialog.filters = PackedStringArray(["*.jsonl ; SillyTavern JSONL"])
	_export_jsonl_dialog.file_selected.connect(_write_pending_export)
	add_child(_export_jsonl_dialog)

	_fresh_confirm = ConfirmationDialog.new()
	_fresh_confirm.visible = false
	_fresh_confirm.title = "Start a Fresh Front Porch Chat"
	_fresh_confirm.dialog_text = "Create a new Front Porch chat for the linked character? This does not replace or delete existing sessions."
	_fresh_confirm.confirmed.connect(_start_fresh)
	add_child(_fresh_confirm)
	_delete_confirm = ConfirmationDialog.new()
	_delete_confirm.visible = false
	_delete_confirm.title = "Back Up and Delete Session"
	_delete_confirm.confirmed.connect(_delete_session_with_backup)
	add_child(_delete_confirm)


func _connect_and_verify() -> void:
	if _busy:
		return
	_busy = true
	_connection_status.text = "Connecting and verifying supported chat endpoints…"
	var configured := _service.configure(_connection_address.text)
	if not bool(configured.get("ok", false)):
		_finish_connection_failure(str(configured.get("error", "The address is invalid.")))
		return
	CCFFrontPorchInstallServiceV0173.save_connection({
		"base_url": _connection_address.text,
		"username": _connection_username.text
	})
	var health := await _service.detect()
	if not bool(health.get("ok", false)):
		_finish_connection_failure(str(health.get("error", "Front Porch could not be reached.")))
		return
	var login_result := await _service.login(
		_connection_username.text,
		_connection_password.text,
		_connection_totp.text
	)
	_connection_password.text = ""
	_connection_totp.text = ""
	if not bool(login_result.get("ok", false)):
		_finish_connection_failure(str(login_result.get("error", "Front Porch login failed.")))
		return
	var verified := await _service.verify_chat_contract()
	if not bool(verified.get("ok", false)):
		_finish_connection_failure(str(verified.get("error", "The chat API could not be verified.")))
		return
	_verified = true
	_busy = false
	_personas.clear()
	for persona_value in verified.get("personas", []):
		if persona_value is Dictionary:
			_personas.append((persona_value as Dictionary).duplicate(true))
	_refresh_personas()
	var runtime: Dictionary = verified.get("runtime", {})
	_runtime_status.text = _runtime_summary(runtime)
	_connection_status.text = "Connected. Supported single-character chat and transfer endpoints verified."
	var stream_result := _service.connect_stream()
	if not bool(stream_result.get("ok", false)):
		_chat_status.text = str(stream_result.get("error", "Live stream unavailable."))


func _finish_connection_failure(message_text: String) -> void:
	_busy = false
	_verified = false
	_connection_status.text = message_text


func _open_latest() -> void:
	if not _require_ready():
		return
	_ensure_stream()
	_set_chat_busy("Opening the linked Front Porch character…")
	var selected := await _service.select_character(_remote_character_id)
	if not bool(selected.get("ok", false)):
		_finish_chat_request(selected)
		return
	await _reload_sessions_and_state()
	_finish_chat_request({"ok": true}, "Latest session opened. No message was sent.")


func _request_start_fresh() -> void:
	if _require_ready():
		_fresh_confirm.popup_centered()


func _start_fresh() -> void:
	_ensure_stream()
	_set_chat_busy("Creating a fresh Front Porch chat…")
	var result := await _service.start_fresh(_remote_character_id, _selected_persona_id())
	if not bool(result.get("ok", false)):
		_finish_chat_request(result)
		return
	await _reload_sessions_and_state()
	_finish_chat_request({"ok": true}, "Fresh chat created explicitly. Existing sessions were retained.")


func _select_session() -> void:
	if not _require_ready() or _session_selector.selected < 0 or _session_selector.selected >= _sessions.size():
		return
	var selected_session: Dictionary = _sessions[_session_selector.selected]
	_ensure_stream()
	_set_chat_busy("Selecting Front Porch session…")
	var result := await _service.select_session(str(selected_session.get("id", selected_session.get("sessionId", ""))))
	if not bool(result.get("ok", false)):
		_finish_chat_request(result)
		return
	await _load_chat_state()
	_finish_chat_request({"ok": true}, "Session selected.")


func _send_message() -> void:
	if not _require_ready() or _composer.text.strip_edges().is_empty():
		return
	var outgoing := _composer.text
	_ensure_stream()
	_set_chat_busy("Sending test message through Front Porch…")
	_streaming_text = ""
	var result := await _service.send_message(outgoing)
	if bool(result.get("ok", false)):
		_composer.text = ""
		_busy = false
		_chat_status.text = "Generating in Front Porch… Stop remains available."
	else:
		_finish_chat_request(result)


func _stop_generation() -> void:
	if not _verified:
		return
	_chat_status.text = "Requesting cancellation…"
	var result := await _service.stop_generation()
	_finish_chat_request(result, "Stop requested. Front Porch will settle the current turn safely.")


func _request_delete_session() -> void:
	if not _require_ready() or _session_selector.selected < 0 or _session_selector.selected >= _sessions.size():
		return
	var selected_session: Dictionary = _sessions[_session_selector.selected]
	_delete_confirm.dialog_text = "CCF will first preserve a recoverable .fpchat backup, then delete the Front Porch session '%s'. Continue?" % str(selected_session.get("name", selected_session.get("title", "selected session")))
	_delete_confirm.popup_centered()


func _delete_session_with_backup() -> void:
	if _session_selector.selected < 0 or _session_selector.selected >= _sessions.size():
		return
	var selected_session: Dictionary = _sessions[_session_selector.selected]
	var session_id := str(selected_session.get("id", selected_session.get("sessionId", "")))
	_set_chat_busy("Selecting the exact session before backup…")
	var selected := await _service.select_session(session_id)
	if not bool(selected.get("ok", false)):
		_finish_chat_request(selected)
		return
	_chat_status.text = "Creating a recoverable .fpchat backup…"
	var backup := await _service.export_current("fpchat")
	if not bool(backup.get("ok", false)):
		_finish_chat_request(backup)
		return
	var stored := CCFChatExchangeServiceV0192.store_download(
		backup.get("bytes", PackedByteArray()),
		"fpchat",
		_project_id,
		_active_character_id,
		"Backup before deleting Front Porch session"
	)
	if not bool(stored.get("ok", false)):
		_finish_chat_request(stored)
		return
	var deleted := await _service.delete_session(session_id)
	if not bool(deleted.get("ok", false)):
		_finish_chat_request(deleted)
		return
	_refresh_managed_records()
	await _reload_sessions_and_state()
	_finish_chat_request({"ok": true}, "Session deleted after a recoverable managed .fpchat backup was saved.")


func _reload_sessions_and_state() -> void:
	var listed := await _service.list_sessions(_remote_character_id)
	_sessions.clear()
	_session_selector.clear()
	if bool(listed.get("ok", false)):
		for session_value in listed.get("sessions", []):
			if not session_value is Dictionary:
				continue
			var session_record := (session_value as Dictionary).duplicate(true)
			_sessions.append(session_record)
			_session_selector.add_item(str(session_record.get("name", session_record.get("title", session_record.get("id", "Session")))))
	await _load_chat_state()


func _load_chat_state() -> void:
	var result := await _service.chat_state()
	if not bool(result.get("ok", false)):
		_chat_status.text = str(result.get("error", "Could not load chat history."))
		return
	var payload: Dictionary = result.get("payload", {})
	_render_state(payload)


func _render_state(payload: Dictionary) -> void:
	var lines := PackedStringArray()
	for message_value in payload.get("messages", []):
		if not message_value is Dictionary:
			continue
		var message := message_value as Dictionary
		lines.append("%s:\n%s\n" % [
			str(message.get("sender", "Unknown")),
			str(message.get("text", ""))
		])
	_transcript.text = "\n".join(lines)
	_transcript.scroll_vertical = maxi(0, _transcript.get_line_count() - 1)


func _on_stream_token(token_text: String) -> void:
	if _streaming_text.is_empty():
		_transcript.text += "\nFront Porch:\n"
	_streaming_text += token_text
	_transcript.text += token_text
	_transcript.scroll_vertical = maxi(0, _transcript.get_line_count() - 1)


func _on_stream_done() -> void:
	_streaming_text = ""
	_chat_status.text = "Generation complete; refreshing canonical Front Porch history…"
	await _load_chat_state()
	_chat_status.text = "Generation complete."


func _on_stream_error(message_text: String) -> void:
	_streaming_text = ""
	_chat_status.text = message_text


func _on_stream_chat_updated() -> void:
	if not _busy:
		await _load_chat_state()


func _export_fpchat() -> void:
	await _prepare_current_export("fpchat")


func _export_jsonl() -> void:
	await _prepare_current_export("jsonl")


func _prepare_current_export(format_id: String) -> void:
	if not _require_ready():
		return
	_set_chat_busy("Requesting the Front Porch chat export…")
	var result := await _service.export_current(format_id)
	if not bool(result.get("ok", false)):
		_finish_chat_request(result)
		return
	_pending_export_bytes = result.get("bytes", PackedByteArray())
	_pending_export_format = format_id
	var stored := CCFChatExchangeServiceV0192.store_download(
		_pending_export_bytes,
		format_id,
		_project_id,
		_active_character_id
	)
	if not bool(stored.get("ok", false)):
		_finish_chat_request(stored)
		return
	_refresh_managed_records()
	_busy = false
	var character_record := CCFStorageService.get_character(_project, _active_character_id)
	var base_filename := _safe_filename(CCFStorageService.character_display_name(character_record))
	if format_id == "fpchat":
		_export_fpchat_dialog.current_file = "%s-test-chat.fpchat" % base_filename
		_export_fpchat_dialog.popup_centered_ratio(0.72)
	else:
		_export_jsonl_dialog.current_file = "%s-test-chat.jsonl" % base_filename
		_export_jsonl_dialog.popup_centered_ratio(0.72)


func _write_pending_export(destination_path: String) -> void:
	if _pending_export_bytes.is_empty():
		return
	var expected_extension := "fpchat" if _pending_export_format == "fpchat" else "jsonl"
	var final_path := destination_path
	if final_path.get_extension().to_lower() != expected_extension:
		final_path += "." + expected_extension
	var output := FileAccess.open(final_path, FileAccess.WRITE)
	if output == null:
		_chat_status.text = "Could not write the selected chat export."
		return
	output.store_buffer(_pending_export_bytes)
	output.close()
	_pending_export_bytes = PackedByteArray()
	_chat_status.text = "Chat exported and a managed recovery copy was retained."


func _choose_import() -> void:
	_import_dialog.popup_centered_ratio(0.72)


func _inspect_selected_path(source_path: String) -> void:
	var result := CCFChatExchangeServiceV0192.inspect_path(source_path)
	_selected_import_path = source_path if bool(result.get("ok", false)) else ""
	_selected_inspection = result.duplicate(true)
	_exchange_preview.text = CCFChatExchangeServiceV0192.preview_text(result)
	_exchange_status.text = "Preview ready. Nothing has been transferred." if bool(result.get("ok", false)) else str(result.get("error", "Could not inspect chat."))


func _preserve_selected_import() -> void:
	if _selected_import_path.is_empty():
		_exchange_status.text = "Choose and preview a compatible chat first."
		return
	var result := CCFChatExchangeServiceV0192.store_managed_copy(
		_selected_import_path, _project_id, _active_character_id
	)
	_exchange_status.text = "Managed source copy preserved with its SHA-256 provenance." if bool(result.get("ok", false)) else str(result.get("error", "Could not preserve chat."))
	_refresh_managed_records()


func _send_import_to_front_porch() -> void:
	if not _require_ready():
		return
	if _selected_import_path.is_empty() or not bool(_selected_inspection.get("ok", false)):
		_exchange_status.text = "Choose and preview a compatible chat first."
		return
	var preserved := CCFChatExchangeServiceV0192.store_managed_copy(
		_selected_import_path, _project_id, _active_character_id
	)
	if not bool(preserved.get("ok", false)):
		_exchange_status.text = str(preserved.get("error", "Could not preserve the source before transfer."))
		return
	var mismatch_mode := ""
	if _mismatch_selector.selected == 1:
		mismatch_mode = "full"
	elif _mismatch_selector.selected == 2:
		mismatch_mode = "dialogue"
	_exchange_status.text = "Importing the previewed chat through Front Porch's supported API…"
	var result := await _service.import_chat(
		FileAccess.get_file_as_bytes(_selected_import_path), mismatch_mode
	)
	if bool(result.get("ok", false)):
		_exchange_status.text = "Front Porch imported the chat. A managed source copy was preserved first."
		await _reload_sessions_and_state()
	elif bool(result.get("character_mismatch", false)):
		_exchange_status.text = "Character mismatch: package '%s', active Front Porch character '%s'. Choose Full restore or Dialogue only, review the preview, then retry." % [str(result.get("package_name", "Unknown")), str(result.get("active_name", "Unknown"))]
	else:
		_exchange_status.text = str(result.get("error", "Front Porch could not import the chat."))
	_refresh_managed_records()


func _refresh_managed_records() -> void:
	_managed_records.clear()
	if _managed_selector == null:
		return
	_managed_selector.clear()
	var index := CCFChatExchangeServiceV0192.load_index()
	for record_value in index.get("exchanges", []):
		if not record_value is Dictionary:
			continue
		var record := (record_value as Dictionary).duplicate(true)
		if str(record.get("project_id", "")) != _project_id:
			continue
		_managed_records.append(record)
		_managed_selector.add_item("%s • %s • %d messages" % [
			str(record.get("imported_at", "")),
			str(record.get("format", "chat")),
			int(record.get("message_count", 0))
		])
	if _managed_records.is_empty():
		_managed_selector.add_item("No managed chat copies for this project")


func _export_managed_copy() -> void:
	if _managed_selector.selected < 0 or _managed_selector.selected >= _managed_records.size():
		_exchange_status.text = "There is no managed chat copy to export."
		return
	var record: Dictionary = _managed_records[_managed_selector.selected]
	var managed_path := str(record.get("managed_path", ""))
	_pending_export_bytes = FileAccess.get_file_as_bytes(managed_path)
	_pending_export_format = "fpchat" if managed_path.get_extension().to_lower() == "fpchat" else "jsonl"
	if _pending_export_format == "fpchat":
		_export_fpchat_dialog.current_file = str(record.get("source_filename", "managed-chat.fpchat"))
		_export_fpchat_dialog.popup_centered_ratio(0.72)
	else:
		_export_jsonl_dialog.current_file = str(record.get("source_filename", "managed-chat.jsonl"))
		_export_jsonl_dialog.popup_centered_ratio(0.72)


func _save_profile() -> void:
	var profile_id := ""
	if _profile_selector.selected > 0 and _profile_selector.selected - 1 < _profiles.size():
		profile_id = str(_profiles[_profile_selector.selected - 1].get("profile_id", ""))
	var result := CCFTestChatProfileServiceV0192.save_profile({
		"profile_id": profile_id,
		"name": _profile_name.text,
		"persona_id": _selected_persona_id(),
		"expected_runtime": _profile_runtime.text,
		"notes": _profile_notes.text
	})
	_connection_status.text = "Local Test Profile saved; character and Front Porch settings were unchanged." if bool(result.get("ok", false)) else str(result.get("error", "Could not save profile."))
	_refresh_profiles(str(result.get("profile", {}).get("profile_id", "")))


func _delete_profile() -> void:
	if _profile_selector.selected <= 0 or _profile_selector.selected - 1 >= _profiles.size():
		return
	var profile_id := str(_profiles[_profile_selector.selected - 1].get("profile_id", ""))
	var result := CCFTestChatProfileServiceV0192.delete_profile(profile_id)
	_connection_status.text = "Local Test Profile deleted. No card or Front Porch data changed." if bool(result.get("ok", false)) else str(result.get("error", "Could not delete profile."))
	_refresh_profiles()


func _refresh_profiles(select_id := "") -> void:
	_profiles = CCFTestChatProfileServiceV0192.load_profiles()
	if _profile_selector == null:
		return
	_profile_selector.clear()
	_profile_selector.add_item("New / unsaved profile")
	var selected_index := 0
	for profile_index in range(_profiles.size()):
		var profile: Dictionary = _profiles[profile_index]
		_profile_selector.add_item(str(profile.get("name", "Test Profile")))
		if str(profile.get("profile_id", "")) == select_id:
			selected_index = profile_index + 1
	_profile_selector.select(selected_index)
	_load_selected_profile(selected_index)


func _load_selected_profile(selected_index: int) -> void:
	if _profile_name == null:
		return
	if selected_index <= 0 or selected_index - 1 >= _profiles.size():
		_profile_name.text = ""
		_profile_runtime.text = ""
		_profile_notes.text = ""
		_select_persona("")
		return
	var profile: Dictionary = _profiles[selected_index - 1]
	_profile_name.text = str(profile.get("name", ""))
	_profile_runtime.text = str(profile.get("expected_runtime", ""))
	_profile_notes.text = str(profile.get("notes", ""))
	_select_persona(str(profile.get("persona_id", "")))


func _refresh_personas() -> void:
	var desired_id := _selected_persona_id()
	_profile_persona.clear()
	_profile_persona.add_item("Front Porch default persona")
	_profile_persona.set_item_metadata(0, "")
	for persona in _personas:
		_profile_persona.add_item(str(persona.get("name", persona.get("displayName", "Persona"))))
		_profile_persona.set_item_metadata(_profile_persona.item_count - 1, str(persona.get("id", "")))
	_select_persona(desired_id)


func _select_persona(persona_id: String) -> void:
	if _profile_persona == null or _profile_persona.item_count == 0:
		return
	for item_index in range(_profile_persona.item_count):
		if str(_profile_persona.get_item_metadata(item_index)) == persona_id:
			_profile_persona.select(item_index)
			return
	_profile_persona.select(0)


func _selected_persona_id() -> String:
	if _profile_persona == null or _profile_persona.selected < 0:
		return ""
	return str(_profile_persona.get_item_metadata(_profile_persona.selected))


func _refresh_character_context() -> void:
	var character_record := CCFStorageService.get_character(_project, _active_character_id)
	var binding := CCFFrontPorchSyncServiceV0185.binding_for_character(
		_project, _active_character_id
	)
	_remote_character_id = str(binding.get("remote_id", ""))
	var display_name := CCFStorageService.character_display_name(character_record)
	if _remote_character_id.is_empty():
		_character_status.text = "Active character: %s • Not linked to Front Porch. Install or link it in Import / Export before starting a test chat." % display_name
	else:
		_character_status.text = "Active character: %s • Linked Front Porch ID: %s" % [display_name, _remote_character_id]


func _load_connection() -> void:
	var connection := CCFFrontPorchInstallServiceV0173.load_connection()
	_connection_address.text = str(connection.get("base_url", CCFFrontPorchInstallServiceV0173.DEFAULT_BASE_URL))
	_connection_username.text = str(connection.get("username", ""))
	_connection_status.text = "Connect when you are ready. Opening this window performs no network request."
	_runtime_status.text = "Runtime: not verified."


func _require_ready() -> bool:
	if _busy:
		return false
	if not _verified or not _service.is_authenticated():
		_chat_status.text = "Connect and verify Front Porch first."
		return false
	if _remote_character_id.is_empty():
		_chat_status.text = "Install or link this character to Front Porch first."
		return false
	return true


func _ensure_stream() -> void:
	if _service.stream_is_active():
		return
	var stream_result := _service.connect_stream()
	if not bool(stream_result.get("ok", false)):
		_chat_status.text = str(stream_result.get("error", "Live stream unavailable."))


func _set_chat_busy(message_text: String) -> void:
	_busy = true
	_chat_status.text = message_text


func _finish_chat_request(result: Dictionary, success_message := "") -> void:
	_busy = false
	if bool(result.get("ok", false)):
		_chat_status.text = success_message
	else:
		_chat_status.text = str(result.get("error", "Front Porch chat request failed."))


func _runtime_summary(runtime: Dictionary) -> String:
	if runtime.is_empty():
		return "Runtime endpoint was optional/unavailable; chat endpoints are still verified."
	var provider := str(runtime.get("provider", runtime.get("backend", "Front Porch runtime")))
	var model := str(runtime.get("model", runtime.get("modelName", "current model")))
	return "Observed Front Porch runtime: %s • %s. CCF did not change it." % [provider, model]


func _hide_window() -> void:
	save_window_state()
	set_process(false)
	if _service != null:
		_service.disconnect_stream()
	hide()


func _file_dialog(dialog_mode: FileDialog.FileMode) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.visible = false
	dialog.force_native = true
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = dialog_mode
	return dialog


func _button(button_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = button_text
	button.pressed.connect(callback)
	return button


func _line_edit(placeholder: String, minimum_width: float) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.custom_minimum_size.x = minimum_width
	return field


func _labelled_control(label_text: String, control: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	var field_label := Label.new()
	field_label.text = label_text
	box.add_child(field_label)
	box.add_child(control)
	return box


func _section_label(label_text: String) -> Label:
	var section := Label.new()
	section.text = label_text
	section.add_theme_font_size_override("font_size", 16)
	section.modulate = Color(0.95, 0.66, 0.31)
	return section


func _status_label() -> Label:
	var status := Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.modulate = Color(0.69, 0.73, 0.86)
	return status


func _safe_filename(raw_value: String) -> String:
	var clean := raw_value.strip_edges()
	for forbidden in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		clean = clean.replace(forbidden, "_")
	return clean if not clean.is_empty() else "character"
