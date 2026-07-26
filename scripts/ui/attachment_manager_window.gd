class_name CCFAttachmentManagerWindow
extends Window

signal attachments_changed(
	project_attachments: Array, character_id: String, character_attachments: Array
)
signal vision_preview_requested(
	generated: Dictionary, metadata: Dictionary, preview_title: String
)
signal project_refresh_requested

var _generation_service: CCFGenerationService
var _project: Dictionary = {}
var _settings: Dictionary = {}
var _template: Dictionary = {}
var _project_id := ""
var _active_character_id := ""
var _scope := "character"
var _job_id := ""
var _attachment_list: ItemList
var _scope_selector: OptionButton
var _display_name: LineEdit
var _kind_selector: OptionButton
var _include_context: CheckBox
var _notes: TextEdit
var _note_content_label: Label
var _note_content: TextEdit
var _preprocess_summary: Label
var _path_summary: Label
var _context_summary: Label
var _status: Label
var _analyse_button: Button
var _analysis_mode: OptionButton
var _file_dialog: FileDialog
var _note_dialog: Window
var _note_title: LineEdit
var _note_text: TextEdit
var _selected_attachment_id := ""
var _loading_details := false


func _ready() -> void:
	visible = false
	title = "Vision and Attachments"
	size = Vector2i(1180, 820)
	min_size = Vector2i(860, 620)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(_hide_window)
	_build_ui()
	_build_file_dialog()
	_build_note_dialog()
	hide()


func set_generation_service(service: CCFGenerationService) -> void:
	_generation_service = service


func open_for_project(
	project: Dictionary,
	active_character_id: String,
	template: Dictionary,
	settings: Dictionary
) -> void:
	_project = project.duplicate(true)
	_project_id = str(project.get("project_id", ""))
	_active_character_id = active_character_id
	_template = template.duplicate(true)
	_settings = settings.duplicate(true)
	_selected_attachment_id = ""
	_rebuild_list()
	_update_context_summary()
	_status.text = "Attachments are copied into the project as ordinary files. Nothing from vision analysis is applied without review."
	CCFToolWindowStateService.show_window(self, "attachments", Vector2i(1180, 820))


func update_project_context(
	project: Dictionary,
	active_character_id: String,
	template: Dictionary,
	settings: Dictionary
) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	_project = project.duplicate(true)
	_active_character_id = active_character_id
	_template = template.duplicate(true)
	_settings = settings.duplicate(true)
	_rebuild_list()
	_update_context_summary()


func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and _project_id == project_id


func release_project() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "attachments")
	hide()
	_project.clear()
	_project_id = ""
	_active_character_id = ""
	_selected_attachment_id = ""
	_job_id = ""


func save_window_state() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "attachments")


func handle_job_completed(job_id: String, data: Variant, metadata: Dictionary) -> bool:
	if job_id != _job_id:
		return false
	_job_id = ""
	_analyse_button.disabled = false
	if str(metadata.get("project_id", "")) != _workspace_owner_id():
		_status.text = "Vision result discarded because a different character is now active."
		return true
	if not data is Dictionary:
		_status.text = "The vision provider did not return a JSON object."
		return true
	vision_preview_requested.emit(
		data,
		metadata,
		"Vision Analysis — %s" % str(metadata.get("attachment_name", "Image"))
	)
	_status.text = "Vision analysis finished. Review the detachable proposal before applying anything."
	return true


func handle_job_failed(job_id: String, message: String) -> bool:
	if job_id != _job_id:
		return false
	_job_id = ""
	_analyse_button.disabled = false
	_status.text = message
	return true


func handle_job_cancelled(job_id: String) -> bool:
	if job_id != _job_id:
		return false
	_job_id = ""
	_analyse_button.disabled = false
	_status.text = "Vision analysis cancelled."
	return true


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var intro := Label.new()
	intro.text = "Attach reference images, GIFs, text, PDFs, subtitles, transcripts, and planning notes. File metadata stays in character.json while source files remain normal project assets."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	root.add_child(toolbar)

	var scope_label := Label.new()
	scope_label.text = "Scope"
	toolbar.add_child(scope_label)
	_scope_selector = OptionButton.new()
	_scope_selector.add_item("Active Character")
	_scope_selector.set_item_metadata(0, "character")
	_scope_selector.add_item("Shared Project")
	_scope_selector.set_item_metadata(1, "project")
	_scope_selector.item_selected.connect(_on_scope_selected)
	toolbar.add_child(_scope_selector)

	var add_files_button := Button.new()
	add_files_button.text = "Add Files"
	add_files_button.pressed.connect(_open_file_dialog)
	toolbar.add_child(add_files_button)

	var add_note_button := Button.new()
	add_note_button.text = "Add Note"
	add_note_button.pressed.connect(_open_note_dialog)
	toolbar.add_child(add_note_button)

	var remove_button := Button.new()
	remove_button.text = "Remove Entry"
	remove_button.pressed.connect(_remove_selected)
	toolbar.add_child(remove_button)

	var open_button := Button.new()
	open_button.text = "Open File"
	open_button.pressed.connect(_open_selected_file)
	toolbar.add_child(open_button)

	var refresh_button := Button.new()
	refresh_button.text = "Refresh Metadata"
	refresh_button.pressed.connect(_refresh_selected_preprocess)
	toolbar.add_child(refresh_button)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)

	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size.x = 390
	split.add_child(list_panel)
	var list_margin := MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 10)
	list_margin.add_theme_constant_override("margin_right", 10)
	list_margin.add_theme_constant_override("margin_top", 10)
	list_margin.add_theme_constant_override("margin_bottom", 10)
	list_panel.add_child(list_margin)
	var list_column := VBoxContainer.new()
	list_column.add_theme_constant_override("separation", 8)
	list_margin.add_child(list_column)

	_attachment_list = ItemList.new()
	_attachment_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_attachment_list.allow_reselect = true
	_attachment_list.item_selected.connect(_on_attachment_selected)
	list_column.add_child(_attachment_list)

	_context_summary = Label.new()
	_context_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_context_summary.modulate = Color(0.66, 0.7, 0.82)
	list_column.add_child(_context_summary)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_panel)
	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 14)
	detail_margin.add_theme_constant_override("margin_right", 14)
	detail_margin.add_theme_constant_override("margin_top", 14)
	detail_margin.add_theme_constant_override("margin_bottom", 14)
	detail_panel.add_child(detail_margin)
	var detail_root := VBoxContainer.new()
	detail_root.add_theme_constant_override("separation", 9)
	detail_margin.add_child(detail_root)

	var detail_title := Label.new()
	detail_title.text = "Selected Attachment"
	detail_title.add_theme_font_size_override("font_size", 19)
	detail_root.add_child(detail_title)

	var form := GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 12)
	form.add_theme_constant_override("v_separation", 8)
	detail_root.add_child(form)

	form.add_child(_field_label("Display name"))
	_display_name = LineEdit.new()
	_display_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_display_name)

	form.add_child(_field_label("Type"))
	_kind_selector = OptionButton.new()
	for kind in ["image", "gif", "text", "pdf", "subtitle", "transcript", "note", "file"]:
		_kind_selector.add_item(kind.capitalize())
		_kind_selector.set_item_metadata(_kind_selector.item_count - 1, kind)
	_kind_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kind_selector.item_selected.connect(_on_kind_changed)
	form.add_child(_kind_selector)

	form.add_child(_field_label("Generation context"))
	_include_context = CheckBox.new()
	_include_context.text = "Include this attachment when building prompts"
	form.add_child(_include_context)

	var notes_label := Label.new()
	notes_label.text = "Attachment notes"
	detail_root.add_child(notes_label)
	_notes = TextEdit.new()
	_notes.placeholder_text = "Optional instructions, provenance, scene context, or what the AI should pay attention to."
	_notes.custom_minimum_size.y = 105
	_notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	detail_root.add_child(_notes)

	_note_content_label = Label.new()
	_note_content_label.text = "Note content"
	detail_root.add_child(_note_content_label)
	_note_content = TextEdit.new()
	_note_content.placeholder_text = "Text stored directly in the project as this note attachment."
	_note_content.custom_minimum_size.y = 135
	_note_content.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	detail_root.add_child(_note_content)

	_preprocess_summary = Label.new()
	_preprocess_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preprocess_summary.modulate = Color(0.7, 0.74, 0.84)
	detail_root.add_child(_preprocess_summary)

	_path_summary = Label.new()
	_path_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_path_summary.modulate = Color(0.58, 0.62, 0.72)
	detail_root.add_child(_path_summary)

	var detail_actions := HFlowContainer.new()
	detail_actions.add_theme_constant_override("separation", 8)
	detail_root.add_child(detail_actions)
	var apply_metadata_button := Button.new()
	apply_metadata_button.text = "Apply Metadata"
	apply_metadata_button.pressed.connect(_apply_metadata)
	detail_actions.add_child(apply_metadata_button)

	var vision_heading := Label.new()
	vision_heading.text = "Review-first vision analysis"
	vision_heading.add_theme_font_size_override("font_size", 18)
	detail_root.add_child(vision_heading)

	var vision_hint := Label.new()
	vision_hint.text = "Uses the profile assigned to the Vision role. The model returns controlled field suggestions into the normal Generation Preview; it cannot overwrite the card directly."
	vision_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vision_hint.modulate = Color(0.65, 0.69, 0.8)
	detail_root.add_child(vision_hint)

	var vision_row := HBoxContainer.new()
	vision_row.add_theme_constant_override("separation", 8)
	detail_root.add_child(vision_row)
	_analysis_mode = OptionButton.new()
	_analysis_mode.add_item("Concept Extraction")
	_analysis_mode.set_item_metadata(0, "concept")
	_analysis_mode.add_item("Full-card Suggestions")
	_analysis_mode.set_item_metadata(1, "full_card")
	_analysis_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vision_row.add_child(_analysis_mode)
	_analyse_button = Button.new()
	_analyse_button.text = "Analyse Selected Image"
	_analyse_button.pressed.connect(_analyse_selected)
	vision_row.add_child(_analyse_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.72, 0.82, 0.72)
	root.add_child(_status)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_hide_window)
	root.add_child(close_button)

	_set_detail_enabled(false)


func _build_file_dialog() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.visible = false
	_file_dialog.title = "Add Attachments"
	_file_dialog.mode_overrides_title = false
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM as FileDialog.Access
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES as FileDialog.FileMode
	_file_dialog.filters = PackedStringArray(
		[
			"*.png,*.jpg,*.jpeg,*.webp,*.gif,*.bmp,*.tga,*.svg;Images;image/png,image/jpeg,image/webp,image/gif,image/bmp,image/svg+xml",
			"*.txt,*.md,*.markdown,*.json,*.yaml,*.yml,*.csv,*.log;Text files;text/plain,application/json,application/yaml,text/csv",
			"*.pdf;PDF documents;application/pdf",
			"*.srt,*.vtt,*.ass,*.ssa,*.sub;Subtitles;text/plain",
			"*.transcript,*.trs;Transcripts;text/plain",
			"*.*;All files"
		]
	)
	_file_dialog.files_selected.connect(_on_files_selected)
	add_child(_file_dialog)
	_file_dialog.hide()


func _build_note_dialog() -> void:
	_note_dialog = Window.new()
	_note_dialog.visible = false
	_note_dialog.title = "Add Note Attachment"
	_note_dialog.size = Vector2i(620, 470)
	_note_dialog.min_size = Vector2i(520, 380)
	_note_dialog.force_native = true
	_note_dialog.transient = true
	_note_dialog.exclusive = true
	_note_dialog.close_requested.connect(_note_dialog.hide)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_note_dialog.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var title_label := Label.new()
	title_label.text = "Note title"
	root.add_child(title_label)
	_note_title = LineEdit.new()
	_note_title.placeholder_text = "Project note"
	root.add_child(_note_title)
	var text_label := Label.new()
	text_label.text = "Note text"
	root.add_child(text_label)
	_note_text = TextEdit.new()
	_note_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_note_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	root.add_child(_note_text)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_note_dialog.hide)
	actions.add_child(cancel_button)
	var add_button := Button.new()
	add_button.text = "Add Note"
	add_button.pressed.connect(_create_note)
	actions.add_child(add_button)
	add_child(_note_dialog)
	_note_dialog.hide()


func _open_file_dialog() -> void:
	if _project_id.is_empty():
		return
	_file_dialog.popup_centered_ratio(0.72)


func _open_note_dialog() -> void:
	_note_title.text = ""
	_note_text.text = ""
	_note_dialog.popup_centered(Vector2i(620, 470))


func _on_files_selected(paths: PackedStringArray) -> void:
	if paths.is_empty():
		return
	var attachments := _current_attachments()
	var imported_count := 0
	var errors: Array[String] = []
	for path in paths:
		var result := CCFAttachmentService.import_file(
			_project_id, _active_character_id, _scope, str(path)
		)
		if bool(result.get("ok", false)):
			attachments.append(result.get("attachment", {}))
			imported_count += 1
		else:
			errors.append(str(result.get("error", "Could not import %s" % path)))
	_set_current_attachments(attachments)
	_emit_changed()
	_rebuild_list()
	_update_context_summary()
	_status.text = "Imported %d attachment(s). Save the project when ready." % imported_count
	if not errors.is_empty():
		_status.text += " %d file(s) failed: %s" % [errors.size(), "; ".join(errors)]


func _create_note() -> void:
	var attachments := _current_attachments()
	var note := CCFAttachmentService.create_note(_note_title.text, _note_text.text)
	attachments.append(note)
	_set_current_attachments(attachments)
	_selected_attachment_id = str(note.get("attachment_id", ""))
	_emit_changed()
	_rebuild_list()
	_update_context_summary()
	_note_dialog.hide()
	_status.text = "Note attachment added. Save the project when ready."


func _on_scope_selected(index: int) -> void:
	_scope = str(_scope_selector.get_item_metadata(index))
	_selected_attachment_id = ""
	_rebuild_list()


func _rebuild_list() -> void:
	if _attachment_list == null:
		return
	_attachment_list.clear()
	var selected_index := -1
	var attachments := _current_attachments()
	for index in range(attachments.size()):
		var attachment = attachments[index]
		if not attachment is Dictionary:
			continue
		var normalised := CCFAttachmentService.normalise_attachment(attachment)
		var context_mark := "✓" if bool(normalised.get("include_in_context", true)) else "—"
		var label := "%s  %s  ·  %s  ·  %s" % [
			context_mark,
			str(normalised.get("display_name", "Attachment")),
			str(normalised.get("kind", "file")).capitalize(),
			CCFAttachmentService.format_bytes(int(normalised.get("size_bytes", 0)))
		]
		_attachment_list.add_item(label)
		_attachment_list.set_item_metadata(
			_attachment_list.item_count - 1,
			str(normalised.get("attachment_id", ""))
		)
		if str(normalised.get("attachment_id", "")) == _selected_attachment_id:
			selected_index = _attachment_list.item_count - 1
	if selected_index >= 0:
		_attachment_list.select(selected_index)
		_load_selected_details()
	elif _attachment_list.item_count > 0:
		_attachment_list.select(0)
		_selected_attachment_id = str(_attachment_list.get_item_metadata(0))
		_load_selected_details()
	else:
		_selected_attachment_id = ""
		_clear_details()


func _on_attachment_selected(index: int) -> void:
	_selected_attachment_id = str(_attachment_list.get_item_metadata(index))
	_load_selected_details()


func _load_selected_details() -> void:
	var attachment := _selected_attachment()
	if attachment.is_empty():
		_clear_details()
		return
	_loading_details = true
	_set_detail_enabled(true)
	_display_name.text = str(attachment.get("display_name", "Attachment"))
	_select_kind(str(attachment.get("kind", "file")))
	_include_context.button_pressed = bool(attachment.get("include_in_context", true))
	_notes.text = str(attachment.get("notes", ""))
	_note_content.text = str(attachment.get("note_text", ""))
	_update_note_content_visibility(str(attachment.get("kind", "file")))
	var preprocess = attachment.get("preprocess", {})
	_preprocess_summary.text = (
		"Preprocessing: %s" % str(preprocess.get("summary", "Attachment stored."))
		if preprocess is Dictionary
		else "Preprocessing metadata is unavailable."
	)
	var relative_path := str(attachment.get("relative_path", ""))
	_path_summary.text = (
		"Managed path: %s" % relative_path
		if not relative_path.is_empty()
		else "This note is stored directly in project metadata."
	)
	_analyse_button.disabled = not CCFAttachmentService.is_vision_compatible(attachment) or not _job_id.is_empty()
	_loading_details = false


func _clear_details() -> void:
	_loading_details = true
	_display_name.text = ""
	_notes.text = ""
	_note_content.text = ""
	_update_note_content_visibility("file")
	_include_context.button_pressed = false
	_preprocess_summary.text = "Select an attachment to see its preprocessing and context estimate."
	_path_summary.text = ""
	_set_detail_enabled(false)
	_loading_details = false


func _set_detail_enabled(enabled: bool) -> void:
	_display_name.editable = enabled
	_kind_selector.disabled = not enabled
	_include_context.disabled = not enabled
	_notes.editable = enabled
	_note_content.editable = enabled
	_analyse_button.disabled = not enabled


func _apply_metadata() -> void:
	if _loading_details or _selected_attachment_id.is_empty():
		return
	var attachments := _current_attachments()
	for index in range(attachments.size()):
		if not attachments[index] is Dictionary:
			continue
		if str(attachments[index].get("attachment_id", "")) != _selected_attachment_id:
			continue
		var attachment := CCFAttachmentService.normalise_attachment(attachments[index])
		var clean_name := _display_name.text.strip_edges()
		attachment["display_name"] = clean_name if not clean_name.is_empty() else "Attachment"
		attachment["kind"] = (
			str(_kind_selector.get_selected_metadata())
			if _kind_selector.selected >= 0
			else "file"
		)
		attachment["include_in_context"] = _include_context.button_pressed
		attachment["notes"] = _notes.text
		if str(attachment.get("kind", "")) == "note":
			attachment["note_text"] = _note_content.text
			attachment = CCFAttachmentService.refresh_preprocess(_project_id, attachment)
		attachments[index] = attachment
		break
	_set_current_attachments(attachments)
	_emit_changed()
	_rebuild_list()
	_update_context_summary()
	_status.text = "Attachment metadata applied. Save the project when ready."


func _refresh_selected_preprocess() -> void:
	var attachments := _current_attachments()
	for index in range(attachments.size()):
		if not attachments[index] is Dictionary:
			continue
		if str(attachments[index].get("attachment_id", "")) != _selected_attachment_id:
			continue
		attachments[index] = CCFAttachmentService.refresh_preprocess(
			_project_id, attachments[index]
		)
		break
	_set_current_attachments(attachments)
	_emit_changed()
	_rebuild_list()
	_update_context_summary()
	_status.text = "Attachment preprocessing metadata refreshed."


func _remove_selected() -> void:
	if _selected_attachment_id.is_empty():
		return
	var attachments: Array = []
	for attachment in _current_attachments():
		if attachment is Dictionary and str(attachment.get("attachment_id", "")) == _selected_attachment_id:
			continue
		attachments.append(attachment)
	_set_current_attachments(attachments)
	_selected_attachment_id = ""
	_emit_changed()
	_rebuild_list()
	_update_context_summary()
	_status.text = "Attachment entry removed. Its managed file was retained safely as an orphan asset; save the project when ready."


func _open_selected_file() -> void:
	var attachment := _selected_attachment()
	if attachment.is_empty():
		return
	var absolute_path := CCFAttachmentService.resolve_absolute_path(_project_id, attachment)
	if absolute_path.is_empty() or not FileAccess.file_exists(absolute_path):
		_status.text = "This attachment does not have an available managed file."
		return
	OS.shell_open(absolute_path)


func _analyse_selected() -> void:
	var attachment := _selected_attachment()
	if attachment.is_empty():
		return
	if _generation_service == null:
		_status.text = "Vision generation service is unavailable."
		return
	_apply_metadata()
	attachment = _selected_attachment()
	var workspace_document := CCFStorageService.character_workspace_document(
		_project, _active_character_id
	)
	workspace_document["attachment_context_character_limit"] = _context_limit()
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_VISION
	)
	var selected_analysis_mode := (
		str(_analysis_mode.get_selected_metadata())
		if _analysis_mode.selected >= 0
		else "concept"
	)
	var generation_settings = _settings.get("generation", {})
	var retries := (
		int(generation_settings.get("retry_count", 1))
		if generation_settings is Dictionary
		else 1
	)
	var result := _generation_service.queue_vision_analysis(
		workspace_document,
		_template,
		attachment,
		profile,
		selected_analysis_mode,
		retries
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue vision analysis."))
		return
	_job_id = str(result.get("job_id", ""))
	_analyse_button.disabled = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "Vision analysis queued%s." % (
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else ""
	)


func _update_context_summary() -> void:
	if _project.is_empty():
		return
	var report := CCFAttachmentService.context_report(
		_project, _active_character_id, _context_limit()
	)
	_context_summary.text = (
		"Enabled context: %d attachment(s), %d characters, approximately %d tokens (limit %d characters)."
		% [
			int(report.get("included_count", 0)),
			int(report.get("characters", 0)),
			int(report.get("estimated_tokens", 0)),
			int(report.get("limit", _context_limit()))
		]
	)
	if int(report.get("omitted_count", 0)) > 0:
		_context_summary.text += " %d attachment(s) had no usable text/metadata or exceeded the context limit." % int(report.get("omitted_count", 0))


func _context_limit() -> int:
	var generation_settings = _settings.get("generation", {})
	if generation_settings is Dictionary:
		return int(generation_settings.get("attachment_context_character_limit", 24000))
	return 24000


func _current_attachments() -> Array:
	if _scope == "project":
		return CCFAttachmentService.normalise_list(_project.get("attachments", []))
	var character := CCFStorageService.get_character(_project, _active_character_id)
	return CCFAttachmentService.normalise_list(character.get("attachments", []))


func _set_current_attachments(attachments: Array) -> void:
	var normalised := CCFAttachmentService.normalise_list(attachments)
	if _scope == "project":
		_project["attachments"] = normalised
		return
	var character_index := CCFStorageService.character_index(_project, _active_character_id)
	if character_index < 0:
		return
	var characters: Array = _project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[character_index].duplicate(true)
	character["attachments"] = normalised
	characters[character_index] = character
	_project["characters"] = characters


func _selected_attachment() -> Dictionary:
	for attachment in _current_attachments():
		if attachment is Dictionary and str(attachment.get("attachment_id", "")) == _selected_attachment_id:
			return CCFAttachmentService.normalise_attachment(attachment)
	return {}


func _emit_changed() -> void:
	var project_attachments := CCFAttachmentService.normalise_list(
		_project.get("attachments", [])
	)
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var character_attachments := CCFAttachmentService.normalise_list(
		character.get("attachments", [])
	)
	attachments_changed.emit(
		project_attachments, _active_character_id, character_attachments
	)
	project_refresh_requested.emit()


func _on_kind_changed(_index: int) -> void:
	if _loading_details:
		return
	var kind := (
		str(_kind_selector.get_selected_metadata())
		if _kind_selector.selected >= 0
		else "file"
	)
	_update_note_content_visibility(kind)


func _update_note_content_visibility(kind: String) -> void:
	var is_note := kind == "note"
	_note_content_label.visible = is_note
	_note_content.visible = is_note


func _select_kind(kind: String) -> void:
	for index in range(_kind_selector.item_count):
		if str(_kind_selector.get_item_metadata(index)) == kind:
			_kind_selector.select(index)
			return
	_kind_selector.select(_kind_selector.item_count - 1)


func _workspace_owner_id() -> String:
	return CCFStorageService.workspace_owner_id(_project_id, _active_character_id)


func _field_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 150
	return label


func _hide_window() -> void:
	CCFToolWindowStateService.save_window(self, "attachments")
	hide()
