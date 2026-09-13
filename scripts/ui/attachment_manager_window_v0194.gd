class_name CCFAttachmentManagerV0194Window
extends CCFAttachmentManagerV01311Window

const REMOTE_FETCH_SERVICE_V0194 = preload(
	"res://scripts/services/remote_reference_fetch_service_v0194.gd"
)

var _remote_fetch_service: CCFRemoteReferenceFetchServiceV0194
var _add_url_button: Button
var _refresh_remote_button: Button
var _extracted_label: Label
var _extracted_preview: TextEdit
var _remote_dialog: Window
var _remote_url: LineEdit
var _remote_status: Label
var _remote_text_preview: TextEdit
var _remote_image_preview: TextureRect
var _remote_include_context: CheckBox
var _remote_accept_button: Button
var _remote_preview: Dictionary = {}
var _remote_mode := "add"


func _ready() -> void:
	super._ready()
	_remote_fetch_service = REMOTE_FETCH_SERVICE_V0194.new()
	add_child(_remote_fetch_service)
	_build_remote_dialog()


func release_project() -> void:
	if _remote_dialog != null and _remote_dialog.visible:
		_close_remote_dialog()
	super.release_project()


func _hide_window() -> void:
	if _remote_dialog != null and _remote_dialog.visible:
		_close_remote_dialog()
	super._hide_window()


func _build_ui() -> void:
	super._build_ui()
	var toolbar := _scope_selector.get_parent()
	if toolbar is Container:
		_add_url_button = Button.new()
		_add_url_button.text = "Add from URL…"
		_add_url_button.tooltip_text = (
			"Inspect a bounded HTTPS PDF, text document, web page or image, then "
			+ "choose whether to keep a managed project copy."
		)
		_add_url_button.pressed.connect(_open_remote_add)
		toolbar.add_child(_add_url_button)
		_refresh_remote_button = Button.new()
		_refresh_remote_button.text = "Refresh Remote…"
		_refresh_remote_button.tooltip_text = (
			"Explicitly fetch and preview a newer copy of the selected remote reference."
		)
		_refresh_remote_button.disabled = true
		_refresh_remote_button.pressed.connect(_open_remote_refresh)
		toolbar.add_child(_refresh_remote_button)

	var detail_root := _preprocess_summary.get_parent()
	_extracted_label = Label.new()
	_extracted_label.text = "Extracted reference preview"
	_extracted_label.visible = false
	detail_root.add_child(_extracted_label)
	detail_root.move_child(_extracted_label, _preprocess_summary.get_index() + 1)
	_extracted_preview = TextEdit.new()
	_extracted_preview.editable = false
	_extracted_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_extracted_preview.custom_minimum_size.y = 125
	_extracted_preview.tooltip_text = (
		"This is derived preprocessing. The original managed source remains unchanged."
	)
	_extracted_preview.visible = false
	detail_root.add_child(_extracted_preview)
	detail_root.move_child(_extracted_preview, _extracted_label.get_index() + 1)


func _load_selected_details() -> void:
	super._load_selected_details()
	if _extracted_preview == null:
		return
	var attachment := _selected_attachment()
	var preprocess = attachment.get("preprocess", {})
	var extracted_text := (
		str(preprocess.get("extracted_text", ""))
		if preprocess is Dictionary
		else ""
	)
	_extracted_label.visible = not extracted_text.is_empty()
	_extracted_preview.visible = not extracted_text.is_empty()
	_extracted_preview.text = extracted_text.left(
		CCFReferenceIngestionServiceV0194.MAX_PREVIEW_CHARACTERS
	)
	if _refresh_remote_button != null:
		_refresh_remote_button.disabled = not _is_remote_attachment(attachment)


func _clear_details() -> void:
	super._clear_details()
	if _extracted_label != null:
		_extracted_label.visible = false
	if _extracted_preview != null:
		_extracted_preview.visible = false
		_extracted_preview.text = ""
	if _refresh_remote_button != null:
		_refresh_remote_button.disabled = true


func _build_remote_dialog() -> void:
	_remote_dialog = Window.new()
	_remote_dialog.visible = false
	_remote_dialog.title = "Add Remote Reference"
	_remote_dialog.size = Vector2i(860, 700)
	_remote_dialog.min_size = Vector2i(680, 520)
	_remote_dialog.force_native = true
	_remote_dialog.transient = true
	_remote_dialog.exclusive = true
	_remote_dialog.close_requested.connect(_close_remote_dialog)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 16)
	_remote_dialog.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	margin.add_child(root)
	var explanation := Label.new()
	explanation.text = (
		"Only HTTPS is accepted. Fetching is bounded to 16 MB, 20 seconds and four "
		+ "HTTPS redirects. Nothing is added until you review the preview below."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(explanation)
	var url_row := HBoxContainer.new()
	url_row.add_theme_constant_override("separation", 8)
	root.add_child(url_row)
	_remote_url = LineEdit.new()
	_remote_url.placeholder_text = "https://example.com/reference.pdf"
	_remote_url.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	url_row.add_child(_remote_url)
	var inspect_button := Button.new()
	inspect_button.text = "Fetch Preview"
	inspect_button.pressed.connect(_fetch_remote_preview)
	url_row.add_child(inspect_button)
	_remote_status = Label.new()
	_remote_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_remote_status.modulate = Color(0.72, 0.82, 0.72)
	root.add_child(_remote_status)
	_remote_text_preview = TextEdit.new()
	_remote_text_preview.editable = false
	_remote_text_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_remote_text_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_remote_text_preview)
	_remote_image_preview = TextureRect.new()
	_remote_image_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_remote_image_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_remote_image_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_remote_image_preview.visible = false
	root.add_child(_remote_image_preview)
	_remote_include_context = CheckBox.new()
	_remote_include_context.text = "Include extracted text/reference metadata in generation context after adding"
	_remote_include_context.button_pressed = false
	root.add_child(_remote_include_context)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_close_remote_dialog)
	actions.add_child(cancel_button)
	_remote_accept_button = Button.new()
	_remote_accept_button.text = "Add Managed Copy"
	_remote_accept_button.disabled = true
	_remote_accept_button.pressed.connect(_accept_remote_preview)
	actions.add_child(_remote_accept_button)
	add_child(_remote_dialog)
	_remote_dialog.hide()


func _open_remote_add() -> void:
	if _project_id.is_empty():
		return
	_remote_mode = "add"
	_prepare_remote_dialog("")
	_remote_dialog.title = "Add Remote Reference"
	_remote_accept_button.text = "Add Managed Copy"
	_remote_dialog.popup_centered(Vector2i(860, 700))


func _open_remote_refresh() -> void:
	var attachment := _selected_attachment()
	if not _is_remote_attachment(attachment):
		_status.text = "Select a reference previously added from HTTPS first."
		return
	var source: Dictionary = attachment.get("source", {})
	_remote_mode = "refresh"
	_prepare_remote_dialog(str(source.get("source_url", "")))
	_remote_dialog.title = "Refresh Remote Reference"
	_remote_accept_button.text = "Replace with Reviewed Copy"
	_remote_include_context.button_pressed = bool(
		attachment.get("include_in_context", false)
	)
	_remote_dialog.popup_centered(Vector2i(860, 700))


func _prepare_remote_dialog(source_url: String) -> void:
	_remote_preview.clear()
	_remote_url.text = source_url
	_remote_status.text = "Fetch a preview before accepting this reference."
	_remote_text_preview.text = ""
	_remote_text_preview.visible = true
	_remote_image_preview.texture = null
	_remote_image_preview.visible = false
	_remote_include_context.button_pressed = false
	_remote_accept_button.disabled = true


func _fetch_remote_preview() -> void:
	if _remote_fetch_service == null or _remote_fetch_service.is_busy():
		return
	_remote_preview.clear()
	_remote_accept_button.disabled = true
	_remote_status.text = "Fetching a bounded preview…"
	var result := await _remote_fetch_service.fetch_preview(_remote_url.text)
	if not bool(result.get("ok", false)):
		_remote_status.text = str(result.get("error", "The remote reference could not be inspected."))
		return
	_remote_preview = result
	_remote_status.text = "%s Ready for review; no project file has been changed." % str(
		result.get("preprocess", {}).get("summary", "Reference inspected.")
	)
	_remote_accept_button.disabled = false
	if str(result.get("kind", "")) == "image":
		_show_remote_image(result)
	else:
		_remote_image_preview.visible = false
		_remote_text_preview.visible = true
		_remote_text_preview.text = str(result.get("preview_text", ""))
		if _remote_text_preview.text.is_empty():
			_remote_text_preview.text = (
				"No readable text layer was found. The original PDF can still be stored; "
				+ "scanned-page OCR is not run automatically."
			)


func _show_remote_image(result: Dictionary) -> void:
	var image := Image.new()
	var body: PackedByteArray = result.get("body", PackedByteArray())
	var mime_type := str(result.get("mime_type", ""))
	var image_error := ERR_FILE_UNRECOGNIZED
	if mime_type == "image/png":
		image_error = image.load_png_from_buffer(body)
	elif mime_type == "image/webp":
		image_error = image.load_webp_from_buffer(body)
	else:
		image_error = image.load_jpg_from_buffer(body)
	if image_error != OK or image.is_empty():
		_remote_status.text = "The image passed inspection but its preview could not be displayed."
		return
	_remote_text_preview.visible = false
	_remote_image_preview.texture = ImageTexture.create_from_image(image)
	_remote_image_preview.visible = true


func _accept_remote_preview() -> void:
	if _remote_preview.is_empty():
		return
	var source_metadata := {
		"kind": "remote_https",
		"source_url": str(_remote_preview.get("source_url", "")),
		"final_url": str(_remote_preview.get("final_url", "")),
		"fetched_at": str(_remote_preview.get("fetched_at", "")),
		"content_type": str(_remote_preview.get("mime_type", "")),
		"sha256": str(_remote_preview.get("sha256", "")),
		"redirect_count": int(_remote_preview.get("redirect_count", 0))
	}
	var imported := CCFAttachmentService.import_bytes(
		_project_id,
		_active_character_id,
		_scope,
		_remote_preview.get("body", PackedByteArray()),
		str(_remote_preview.get("filename", "remote-reference.txt")),
		source_metadata,
		_remote_include_context.button_pressed,
		_remote_preview.get("preprocess", {})
	)
	if not bool(imported.get("ok", false)):
		_remote_status.text = str(imported.get("error", "Could not store the managed reference copy."))
		return
	var fresh: Dictionary = imported.get("attachment", {})
	var attachments := _current_attachments()
	if _remote_mode == "refresh":
		fresh = _merge_refreshed_attachment(fresh, attachments)
	else:
		attachments.append(fresh)
	_selected_attachment_id = str(fresh.get("attachment_id", ""))
	_set_current_attachments(attachments)
	_emit_changed()
	_rebuild_list()
	_update_context_summary()
	_remote_dialog.hide()
	_status.text = (
		"Remote reference refreshed from a reviewed HTTPS preview; the previous managed file was retained for recovery."
		if _remote_mode == "refresh"
		else "Remote reference added as a managed project copy. Save the project when ready."
	)


func _merge_refreshed_attachment(fresh: Dictionary, attachments: Array) -> Dictionary:
	for index in range(attachments.size()):
		if not attachments[index] is Dictionary:
			continue
		var previous: Dictionary = attachments[index]
		if str(previous.get("attachment_id", "")) != _selected_attachment_id:
			continue
		var history: Array = previous.get("refresh_history", []).duplicate(true)
		var previous_source = previous.get("source", {})
		history.append({
			"relative_path": str(previous.get("relative_path", "")),
			"sha256": str(previous_source.get("sha256", "")) if previous_source is Dictionary else "",
			"fetched_at": str(previous_source.get("fetched_at", "")) if previous_source is Dictionary else "",
			"refreshed_at": Time.get_datetime_string_from_system(true)
		})
		if history.size() > 10:
			history = history.slice(history.size() - 10)
		fresh["attachment_id"] = str(previous.get("attachment_id", ""))
		fresh["added_at"] = str(previous.get("added_at", fresh.get("added_at", "")))
		fresh["display_name"] = str(previous.get("display_name", fresh.get("display_name", "")))
		fresh["notes"] = str(previous.get("notes", ""))
		fresh["refresh_history"] = history
		attachments[index] = CCFAttachmentService.normalise_attachment(fresh)
		return attachments[index]
	attachments.append(fresh)
	return fresh


func _close_remote_dialog() -> void:
	if _remote_fetch_service != null and _remote_fetch_service.is_busy():
		_remote_fetch_service.cancel()
	_remote_dialog.hide()


static func _is_remote_attachment(attachment: Dictionary) -> bool:
	var source = attachment.get("source", {})
	return source is Dictionary and str(source.get("kind", "")) == "remote_https"


func reference_ingestion_capabilities_v0194() -> Dictionary:
	return {
		"local_pdf_text_layer": true,
		"scanned_pdf_ocr": false,
		"https_preview_before_accept": true,
		"explicit_remote_refresh": true,
		"background_remote_refresh": false,
		"max_remote_bytes": CCFReferenceIngestionServiceV0194.MAX_REMOTE_BYTES,
		"max_pdf_bytes": CCFReferenceIngestionServiceV0194.MAX_PDF_BYTES
	}
