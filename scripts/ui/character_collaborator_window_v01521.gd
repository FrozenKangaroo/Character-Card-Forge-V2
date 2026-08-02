class_name CCFCharacterCollaboratorWindowV01521
extends "res://scripts/ui/character_collaborator_window_v01515.gd"

const ATTACHMENT_SERVICE_V01521 = preload("res://scripts/services/collaborator_attachment_service_v01521.gd")

var _attach_files_button_v01521: Button
var _attachment_dialog_v01521: FileDialog


func _ready() -> void:
	super._ready()
	_install_attachment_controls_v01521()
	_build_attachment_dialog_v01521()
	_refresh_all()


func _install_attachment_controls_v01521() -> void:
	if _context_list == null:
		return
	var context_scroll := _context_list.get_parent()
	var context_panel := context_scroll.get_parent() if context_scroll != null else null
	if context_panel == null:
		return

	var old_image_button: Button = null
	for node in context_panel.find_children("*", "Button", true, false):
		if node is Button and (node as Button).text == "Add Reference Image…":
			old_image_button = node as Button
			break
	if old_image_button == null or old_image_button.get_parent() == null:
		return

	var actions := old_image_button.get_parent()
	var insert_index := old_image_button.get_index()
	old_image_button.visible = false
	old_image_button.disabled = true

	_attach_files_button_v01521 = Button.new()
	_attach_files_button_v01521.text = "Attach Files…"
	_attach_files_button_v01521.tooltip_text = "Attach images or text-based reference files. Supported text formats: TXT, Markdown, SRT, ASS/SSA and JSON. Images continue through the configured Vision model."
	_attach_files_button_v01521.pressed.connect(_open_attachment_dialog_v01521)
	actions.add_child(_attach_files_button_v01521)
	actions.move_child(_attach_files_button_v01521, insert_index)

	for node in context_panel.find_children("*", "Label", true, false):
		if not node is Label:
			continue
		var label := node as Label
		if label.text.begins_with("References inform the conversation"):
			label.text = "References and attachments inform the conversation but never modify project data by themselves. Text files are embedded as read-only source context; images are analysed by the configured Vision provider before the Text provider sees them. Remove any attachment from the list when it should no longer consume context."
			break


func _build_attachment_dialog_v01521() -> void:
	_attachment_dialog_v01521 = FileDialog.new()
	_attachment_dialog_v01521.visible = false
	_attachment_dialog_v01521.force_native = true
	_attachment_dialog_v01521.transient = false
	_attachment_dialog_v01521.exclusive = false
	_attachment_dialog_v01521.access = FileDialog.ACCESS_FILESYSTEM
	_attachment_dialog_v01521.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	_attachment_dialog_v01521.filters = PackedStringArray([
		"*.txt, *.md, *.markdown, *.srt, *.ass, *.ssa, *.json ; Text, Markdown, subtitle and JSON references",
		"*.png, *.jpg, *.jpeg, *.webp ; Reference images",
		"*.txt, *.md, *.markdown, *.srt, *.ass, *.ssa, *.json, *.png, *.jpg, *.jpeg, *.webp ; All supported Collaborator attachments"
	])
	_attachment_dialog_v01521.files_selected.connect(_on_attachment_files_selected_v01521)
	add_child(_attachment_dialog_v01521)
	_attachment_dialog_v01521.hide()


func _open_attachment_dialog_v01521() -> void:
	if _attachment_dialog_v01521 != null:
		_attachment_dialog_v01521.popup_centered_ratio(0.72)


func _on_attachment_files_selected_v01521(paths: PackedStringArray) -> void:
	var text_added := 0
	var images_queued := 0
	var errors: Array[String] = []
	for path in paths:
		var classification := ATTACHMENT_SERVICE_V01521.classify_path(path)
		if not bool(classification.get("ok", false)):
			errors.append(str(classification.get("error", "Unsupported attachment: %s" % path.get_file())))
			continue
		match str(classification.get("kind", "")):
			"image":
				if _generation_service == null or not _generation_service.has_method("queue_collaborator_vision_summary"):
					errors.append("%s could not be attached because the active generation service has no Vision attachment pipeline." % path.get_file())
					continue
				_on_image_selected(path)
				images_queued += 1
			"text":
				var loaded := ATTACHMENT_SERVICE_V01521.load_text_attachment(path)
				if not bool(loaded.get("ok", false)):
					errors.append(str(loaded.get("error", "Could not read %s." % path.get_file())))
					continue
				var attachment_value: Variant = loaded.get("attachment", {})
				if not attachment_value is Dictionary:
					errors.append("%s did not produce a usable text attachment." % path.get_file())
					continue
				_add_context_item((attachment_value as Dictionary).duplicate(true))
				text_added += 1

	var status_parts: Array[String] = []
	if text_added > 0:
		status_parts.append("%d text attachment%s added as embedded reference context" % [text_added, "" if text_added == 1 else "s"])
	if images_queued > 0:
		status_parts.append("%d image%s queued for Vision analysis" % [images_queued, "" if images_queued == 1 else "s"])
	if not errors.is_empty():
		status_parts.append("%d attachment%s could not be added: %s" % [errors.size(), "" if errors.size() == 1 else "s", " | ".join(errors)])
	_status.text = ". ".join(status_parts) + ("." if not status_parts.is_empty() else "No attachments were added.")
	_refresh_all()


func _refresh_context_list() -> void:
	for child in _context_list.get_children():
		child.queue_free()
	var session := _active_session()
	var items_value: Variant = session.get("context_items", [])
	var items: Array = items_value if items_value is Array else []
	if items.is_empty():
		var empty := Label.new()
		empty.text = "No reference context or attachments added."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_context_list.add_child(empty)
		return

	for index in range(items.size()):
		if not items[index] is Dictionary:
			continue
		var item: Dictionary = items[index]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		var header := HBoxContainer.new()
		row.add_child(header)
		var label := Label.new()
		if ATTACHMENT_SERVICE_V01521.is_attachment_context_item(item):
			var token_count := CCFGenerationService.estimate_tokens(str(item.get("content", "")))
			label.text = "Attachment • %s • %s • ~%s tokens" % [
				str(item.get("label", "Untitled")),
				ATTACHMENT_SERVICE_V01521.display_format(item),
				_format_tokens_v0151(token_count)
			]
		else:
			label.text = "%s • %s" % [str(item.get("type", "context")).replace("_", " ").capitalize(), str(item.get("label", "Untitled"))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		header.add_child(label)

		var remove := Button.new()
		remove.text = "×"
		remove.tooltip_text = "Remove this reference or attachment from future Collaborator context. The historical conversation remains unchanged."
		remove.pressed.connect(func(): _remove_context_item(index))
		header.add_child(remove)

		var preview := Label.new()
		var preview_source := str(item.get("raw_text", item.get("vision_description", item.get("content", ""))))
		preview.text = _truncate(preview_source, 360)
		preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview.modulate = Color(0.70, 0.74, 0.82)
		row.add_child(preview)
		_context_list.add_child(row)


func _refresh_context_usage() -> void:
	super._refresh_context_usage()
	var attachment_tokens := _attachment_context_tokens_v01521()
	if attachment_tokens > 0:
		_context_usage.text += " • attachments ~%s" % _format_tokens_v0151(attachment_tokens)


func _attachment_context_tokens_v01521() -> int:
	var session := _active_session()
	var total := 0
	var items_value: Variant = session.get("context_items", [])
	if not items_value is Array:
		return 0
	for raw in items_value:
		if raw is Dictionary and ATTACHMENT_SERVICE_V01521.is_attachment_context_item(raw as Dictionary):
			total += CCFGenerationService.estimate_tokens(str((raw as Dictionary).get("content", "")))
	return total


func _apply_vision_summary_v01511(summary: String, metadata: Dictionary) -> void:
	var before_ids := _context_ids_v01521()
	super._apply_vision_summary_v01511(summary, metadata)
	var session := _active_session()
	var items_value: Variant = session.get("context_items", [])
	var items: Array = items_value.duplicate(true) if items_value is Array else []
	var changed := false
	for index in range(items.size()):
		if not items[index] is Dictionary:
			continue
		var item: Dictionary = (items[index] as Dictionary).duplicate(true)
		var context_id := str(item.get("context_id", ""))
		if before_ids.has(context_id) or str(item.get("type", "")) != "vision_reference":
			continue
		item["attachment_kind"] = "image"
		item["format_label"] = "Image"
		item["source_extension"] = str(item.get("source_path", "")).get_extension().to_lower()
		item["context_provenance"] = "vision_description_of_user_attached_image"
		items[index] = item
		changed = true
	if changed:
		session["context_items"] = items
		_store_active_session(session)
		_refresh_all()


func _context_ids_v01521() -> Dictionary:
	var result := {}
	var session := _active_session()
	var items_value: Variant = session.get("context_items", [])
	if not items_value is Array:
		return result
	for raw in items_value:
		if raw is Dictionary:
			result[str((raw as Dictionary).get("context_id", ""))] = true
	return result


func _build_message_card_v0153(message: Dictionary) -> Control:
	var panel := super._build_message_card_v0153(message)
	if str(message.get("role", "")) != "vision":
		return panel
	var source_path := str(message.get("source_path", ""))
	if source_path.is_empty():
		return panel
	var containers := panel.find_children("*", "HBoxContainer", true, false)
	if containers.is_empty():
		return panel
	var header := containers[0] as HBoxContainer
	var remove := Button.new()
	remove.text = "Remove Attachment"
	remove.tooltip_text = "Remove this image's Vision-derived reference from future Collaborator context while keeping this historical analysis message."
	remove.pressed.connect(func(): _remove_image_attachment_context_v01521(source_path))
	header.add_child(remove)
	return panel


func _remove_image_attachment_context_v01521(source_path: String) -> void:
	var session := _active_session()
	var items_value: Variant = session.get("context_items", [])
	var items: Array = items_value.duplicate(true) if items_value is Array else []
	var removed := false
	for index in range(items.size() - 1, -1, -1):
		if not items[index] is Dictionary:
			continue
		var item: Dictionary = items[index]
		if str(item.get("type", "")) == "vision_reference" and str(item.get("source_path", "")) == source_path:
			items.remove_at(index)
			removed = true
	if removed:
		session["context_items"] = items
		_store_active_session(session)
		_status.text = "Image attachment removed from future Collaborator context. Its historical Vision Analysis remains in the transcript."
		_refresh_all()
	else:
		_status.text = "This image attachment is already absent from active reference context."


func _refresh_action_state() -> void:
	super._refresh_action_state()
	if _attach_files_button_v01521 != null:
		_attach_files_button_v01521.disabled = _generation_service != null and _generation_service.has_active_job()
