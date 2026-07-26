class_name CCFAttachmentService
extends RefCounted

const ATTACHMENT_FORMAT_VERSION := 1
const DEFAULT_CONTEXT_CHARACTER_LIMIT := 24000
const MAX_TEXT_FILE_BYTES := 4 * 1024 * 1024
const MAX_VISION_IMAGE_BYTES := 25 * 1024 * 1024

const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "bmp", "tga", "svg"]
const GIF_EXTENSIONS := ["gif"]
const TEXT_EXTENSIONS := ["txt", "md", "markdown", "json", "yaml", "yml", "csv", "log"]
const SUBTITLE_EXTENSIONS := ["srt", "vtt", "ass", "ssa", "sub"]
const TRANSCRIPT_EXTENSIONS := ["transcript", "trs"]


static func normalise_list(raw_value: Variant) -> Array:
	var result: Array = []
	if not raw_value is Array:
		return result
	for raw_attachment in raw_value:
		if raw_attachment is Dictionary:
			result.append(normalise_attachment(raw_attachment))
	return result


static func normalise_attachment(raw_attachment: Dictionary) -> Dictionary:
	var attachment_id := str(raw_attachment.get("attachment_id", "")).strip_edges()
	if attachment_id.is_empty():
		attachment_id = _new_id()
	var kind := str(raw_attachment.get("kind", "file")).strip_edges().to_lower()
	if not kind in ["image", "gif", "text", "pdf", "subtitle", "transcript", "note", "file"]:
		kind = "file"
	var result := {
		"format_version": ATTACHMENT_FORMAT_VERSION,
		"attachment_id": attachment_id,
		"display_name": str(raw_attachment.get("display_name", "Attachment")).strip_edges(),
		"kind": kind,
		"relative_path": str(raw_attachment.get("relative_path", "")).replace("\\", "/"),
		"source_filename": str(raw_attachment.get("source_filename", "")),
		"mime_type": str(raw_attachment.get("mime_type", "application/octet-stream")),
		"size_bytes": maxi(0, int(raw_attachment.get("size_bytes", 0))),
		"added_at": str(raw_attachment.get("added_at", Time.get_datetime_string_from_system(true))),
		"include_in_context": bool(raw_attachment.get("include_in_context", true)),
		"notes": str(raw_attachment.get("notes", "")),
		"note_text": str(raw_attachment.get("note_text", "")),
		"preprocess": _normalise_preprocess(raw_attachment.get("preprocess", {}))
	}
	if str(result.get("display_name", "")).is_empty():
		result["display_name"] = str(result.get("source_filename", "Attachment"))
	for key in raw_attachment:
		if not result.has(key):
			var custom_value = raw_attachment.get(key)
			result[key] = (
				custom_value.duplicate(true)
				if custom_value is Dictionary or custom_value is Array
				else custom_value
			)
	return result


static func import_file(
	project_id: String, character_id: String, scope: String, source_path: String
) -> Dictionary:
	var clean_source := source_path.strip_edges()
	if clean_source.is_empty() or not FileAccess.file_exists(clean_source):
		return {"ok": false, "error": "The selected attachment file does not exist."}
	var attachment_id := _new_id()
	var source_filename := clean_source.get_file()
	var destination_relative := _destination_relative_path(
		character_id, scope, attachment_id, source_filename
	)
	var destination_absolute := ProjectSettings.globalize_path(
		_project_folder(project_id).path_join(destination_relative)
	)
	DirAccess.make_dir_recursive_absolute(destination_absolute.get_base_dir())
	var copy_result := _copy_file(clean_source, destination_absolute)
	if not bool(copy_result.get("ok", false)):
		return copy_result
	var attachment := _attachment_from_file(
		attachment_id,
		source_filename,
		destination_relative,
		destination_absolute
	)
	return {"ok": true, "attachment": attachment}


static func create_note(title: String, note_text: String) -> Dictionary:
	var clean_title := title.strip_edges()
	if clean_title.is_empty():
		clean_title = "Project Note"
	var attachment := normalise_attachment(
		{
			"attachment_id": _new_id(),
			"display_name": clean_title,
			"kind": "note",
			"mime_type": "text/plain",
			"size_bytes": note_text.to_utf8_buffer().size(),
			"added_at": Time.get_datetime_string_from_system(true),
			"include_in_context": true,
			"note_text": note_text,
			"preprocess": _preprocess_note(note_text)
		}
	)
	return attachment


static func refresh_preprocess(project_id: String, attachment: Dictionary) -> Dictionary:
	var result := normalise_attachment(attachment)
	var kind := str(result.get("kind", "file"))
	if kind == "note":
		result["size_bytes"] = str(result.get("note_text", "")).to_utf8_buffer().size()
		result["preprocess"] = _preprocess_note(str(result.get("note_text", "")))
		return result
	var absolute_path := resolve_absolute_path(project_id, result)
	if absolute_path.is_empty() or not FileAccess.file_exists(absolute_path):
		var missing := _normalise_preprocess(result.get("preprocess", {}))
		missing["status"] = "missing"
		missing["summary"] = "The stored attachment file is missing."
		result["preprocess"] = missing
		return result
	result["size_bytes"] = _file_size(absolute_path)
	result["preprocess"] = _preprocess_file(absolute_path, kind)
	return result


static func copy_managed_attachment(
	source_project_id: String,
	target_project_id: String,
	source_relative_path: String,
	target_relative_path: String
) -> Dictionary:
	if not _is_safe_relative_path(source_relative_path):
		return {"ok": false, "error": "The source attachment path is unsafe."}
	if not _is_safe_relative_path(target_relative_path):
		return {"ok": false, "error": "The destination attachment path is unsafe."}
	var source_absolute := ProjectSettings.globalize_path(
		_project_folder(source_project_id).path_join(source_relative_path)
	)
	if not FileAccess.file_exists(source_absolute):
		return {"ok": false, "error": "The source attachment file is missing."}
	var target_absolute := ProjectSettings.globalize_path(
		_project_folder(target_project_id).path_join(target_relative_path)
	)
	DirAccess.make_dir_recursive_absolute(target_absolute.get_base_dir())
	return _copy_file(source_absolute, target_absolute)


static func delete_file(project_id: String, attachment: Dictionary) -> Dictionary:
	var relative_path := str(attachment.get("relative_path", ""))
	if relative_path.is_empty():
		return {"ok": true}
	if not _is_safe_relative_path(relative_path):
		return {"ok": false, "error": "The attachment path is unsafe and was not removed."}
	if not (
		relative_path.begins_with("attachments/")
		or relative_path.contains("/attachments/")
	):
		return {"ok": false, "error": "The attachment is outside a managed attachment folder."}
	var absolute_path := ProjectSettings.globalize_path(
		_project_folder(project_id).path_join(relative_path)
	)
	if FileAccess.file_exists(absolute_path):
		var remove_error := DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			return {"ok": false, "error": "Could not remove the attachment file (error %s)." % remove_error}
	return {"ok": true}


static func resolve_absolute_path(project_id: String, attachment: Dictionary) -> String:
	var relative_path := str(attachment.get("relative_path", "")).replace("\\", "/")
	if relative_path.is_empty() or not _is_safe_relative_path(relative_path):
		return ""
	return ProjectSettings.globalize_path(
		_project_folder(project_id).path_join(relative_path)
	)


static func context_report(
	project: Dictionary,
	character_id: String,
	character_limit: int = DEFAULT_CONTEXT_CHARACTER_LIMIT
) -> Dictionary:
	return _render_context_entries(
		str(project.get("project_id", "")),
		_context_attachments(project, character_id),
		character_limit
	)


static func context_report_for_workspace(
	workspace_document: Dictionary,
	character_limit: int = DEFAULT_CONTEXT_CHARACTER_LIMIT
) -> Dictionary:
	var project_id := str(
		workspace_document.get(
			"container_project_id", workspace_document.get("project_id", "")
		)
	)
	var entries: Array = []
	for raw_attachment in workspace_document.get("project_attachments", []):
		if raw_attachment is Dictionary:
			entries.append(
				{
					"scope_label": "Shared project attachment",
					"attachment": normalise_attachment(raw_attachment)
				}
			)
	for raw_attachment in workspace_document.get("attachments", []):
		if raw_attachment is Dictionary:
			entries.append(
				{
					"scope_label": "Active character attachment",
					"attachment": normalise_attachment(raw_attachment)
				}
			)
	return _render_context_entries(project_id, entries, character_limit)


static func context_report_for_characters(
	project: Dictionary,
	character_ids: Array[String],
	character_limit: int = DEFAULT_CONTEXT_CHARACTER_LIMIT
) -> Dictionary:
	var entries: Array = []
	for raw_attachment in project.get("attachments", []):
		if raw_attachment is Dictionary:
			entries.append(
				{
					"scope_label": "Shared project attachment",
					"attachment": normalise_attachment(raw_attachment)
				}
			)
	for character_id in character_ids:
		var character := _get_character(project, character_id)
		var character_name := _character_display_name(character)
		for raw_attachment in character.get("attachments", []):
			if raw_attachment is Dictionary:
				entries.append(
					{
						"scope_label": "%s attachment" % character_name,
						"attachment": normalise_attachment(raw_attachment)
					}
				)
	return _render_context_entries(
		str(project.get("project_id", "")), entries, character_limit
	)


static func _render_context_entries(
	project_id: String, entries: Array, character_limit: int
) -> Dictionary:
	var sections: Array[String] = []
	var summaries: Array[Dictionary] = []
	var used_characters := 0
	var included_count := 0
	var omitted_count := 0
	var safe_limit := clampi(character_limit, 2000, 120000)
	for entry in entries:
		if not entry is Dictionary:
			continue
		var attachment: Dictionary = entry.get("attachment", {})
		if not bool(attachment.get("include_in_context", true)):
			continue
		var separator_cost := 2 if not sections.is_empty() else 0
		var remaining := safe_limit - used_characters - separator_cost
		if remaining <= 0:
			omitted_count += 1
			continue
		var rendered := _attachment_context_text(
			project_id,
			attachment,
			str(entry.get("scope_label", "Attachment")),
			remaining
		)
		var text := str(rendered.get("text", ""))
		if text.is_empty():
			omitted_count += 1
			continue
		sections.append(text)
		var consumed := text.length()
		used_characters += separator_cost + consumed
		included_count += 1
		summaries.append(
			{
				"attachment_id": str(attachment.get("attachment_id", "")),
				"display_name": str(attachment.get("display_name", "Attachment")),
				"scope": str(entry.get("scope_label", "Attachment")),
				"characters": consumed,
				"estimated_tokens": _estimate_tokens(text),
				"truncated": bool(rendered.get("truncated", false))
			}
		)
	var joined := "\n\n".join(sections)
	return {
		"text": joined,
		"included_count": included_count,
		"omitted_count": omitted_count,
		"characters": joined.length(),
		"estimated_tokens": _estimate_tokens(joined),
		"limit": safe_limit,
		"attachments": summaries
	}


static func image_data_url(project_id: String, attachment: Dictionary) -> Dictionary:
	var kind := str(attachment.get("kind", ""))
	if not kind in ["image", "gif"]:
		return {"ok": false, "error": "Only image and GIF attachments can be sent to a vision model."}
	var absolute_path := resolve_absolute_path(project_id, attachment)
	if absolute_path.is_empty() or not FileAccess.file_exists(absolute_path):
		return {"ok": false, "error": "The selected image attachment file is missing."}
	var bytes := FileAccess.get_file_as_bytes(absolute_path)
	if bytes.is_empty():
		return {"ok": false, "error": "The selected image attachment is empty."}
	if bytes.size() > MAX_VISION_IMAGE_BYTES:
		return {
			"ok": false,
			"error": "The image is larger than the current 25 MB vision safety limit."
		}
	var mime_type := str(
		attachment.get("mime_type", _mime_for_extension(absolute_path.get_extension()))
	)
	if not mime_type in ["image/png", "image/jpeg", "image/webp", "image/gif"]:
		var converted_image := Image.new()
		var load_error := converted_image.load(absolute_path)
		if load_error != OK or converted_image.is_empty():
			return {
				"ok": false,
				"error": "This image format is stored successfully, but it could not be converted to PNG for the selected vision provider."
			}
		bytes = converted_image.save_png_to_buffer()
		mime_type = "image/png"
		if bytes.is_empty() or bytes.size() > MAX_VISION_IMAGE_BYTES:
			return {
				"ok": false,
				"error": "The converted PNG exceeds the current 25 MB vision safety limit."
			}
	return {
		"ok": true,
		"data_url": "data:%s;base64,%s" % [mime_type, Marshalls.raw_to_base64(bytes)],
		"size_bytes": bytes.size()
	}


static func is_vision_compatible(attachment: Dictionary) -> bool:
	return str(attachment.get("kind", "")) in ["image", "gif"]


static func format_bytes(byte_count: int) -> String:
	var amount := float(maxi(0, byte_count))
	if amount < 1024.0:
		return "%d B" % int(amount)
	if amount < 1024.0 * 1024.0:
		return "%.1f KB" % (amount / 1024.0)
	if amount < 1024.0 * 1024.0 * 1024.0:
		return "%.1f MB" % (amount / (1024.0 * 1024.0))
	return "%.1f GB" % (amount / (1024.0 * 1024.0 * 1024.0))


static func _attachment_from_file(
	attachment_id: String,
	source_filename: String,
	relative_path: String,
	absolute_path: String
) -> Dictionary:
	var extension := source_filename.get_extension().to_lower()
	var kind := _kind_for_extension(extension)
	return normalise_attachment(
		{
			"attachment_id": attachment_id,
			"display_name": source_filename,
			"kind": kind,
			"relative_path": relative_path,
			"source_filename": source_filename,
			"mime_type": _mime_for_extension(extension),
			"size_bytes": _file_size(absolute_path),
			"added_at": Time.get_datetime_string_from_system(true),
			"include_in_context": true,
			"preprocess": _preprocess_file(absolute_path, kind)
		}
	)


static func _preprocess_file(absolute_path: String, kind: String) -> Dictionary:
	var size_bytes := _file_size(absolute_path)
	if kind in ["image", "gif"]:
		var image := Image.new()
		var load_error := image.load(absolute_path)
		var kind_label := "GIF" if kind == "gif" else "Image"
		if load_error == OK and not image.is_empty():
			return {
				"status": "ready",
				"summary": "%s, %d × %d pixels, %s." % [
					kind_label, image.get_width(), image.get_height(), format_bytes(size_bytes)
				],
				"character_count": 0,
				"estimated_tokens": 0,
				"image_width": image.get_width(),
				"image_height": image.get_height(),
				"truncated": false
			}
		return {
			"status": "stored",
			"summary": "%s stored (%s). Frame/dimension inspection was not available." % [
				kind_label, format_bytes(size_bytes)
			],
			"character_count": 0,
			"estimated_tokens": 0,
			"image_width": 0,
			"image_height": 0,
			"truncated": false
		}
	if kind in ["text", "subtitle", "transcript"]:
		if size_bytes > MAX_TEXT_FILE_BYTES:
			return {
				"status": "too_large",
				"summary": "Text attachment stored, but it is larger than the 4 MB preprocessing limit.",
				"character_count": 0,
				"estimated_tokens": 0,
				"image_width": 0,
				"image_height": 0,
				"truncated": true
			}
		var text := FileAccess.get_file_as_string(absolute_path)
		return {
			"status": "ready",
			"summary": "%s text: %s, approximately %d tokens before context trimming." % [
				kind.capitalize(), format_bytes(size_bytes), _estimate_tokens(text)
			],
			"character_count": text.length(),
			"estimated_tokens": _estimate_tokens(text),
			"image_width": 0,
			"image_height": 0,
			"truncated": false
		}
	if kind == "pdf":
		return {
			"status": "stored",
			"summary": "PDF stored (%s). Native PDF text extraction is not included in this foundation release." % format_bytes(size_bytes),
			"character_count": 0,
			"estimated_tokens": 0,
			"image_width": 0,
			"image_height": 0,
			"truncated": false
		}
	return {
		"status": "stored",
		"summary": "File stored as an ordinary project asset (%s)." % format_bytes(size_bytes),
		"character_count": 0,
		"estimated_tokens": 0,
		"image_width": 0,
		"image_height": 0,
		"truncated": false
	}


static func _preprocess_note(note_text: String) -> Dictionary:
	return {
		"status": "ready",
		"summary": "Note text: %d characters, approximately %d tokens." % [
			note_text.length(), _estimate_tokens(note_text)
		],
		"character_count": note_text.length(),
		"estimated_tokens": _estimate_tokens(note_text),
		"image_width": 0,
		"image_height": 0,
		"truncated": false
	}


static func _normalise_preprocess(raw_value: Variant) -> Dictionary:
	var result := {
		"status": "stored",
		"summary": "Attachment stored.",
		"character_count": 0,
		"estimated_tokens": 0,
		"image_width": 0,
		"image_height": 0,
		"truncated": false
	}
	if raw_value is Dictionary:
		result.merge(raw_value, true)
	return result


static func _context_attachments(project: Dictionary, character_id: String) -> Array:
	var result: Array = []
	for raw_attachment in project.get("attachments", []):
		if raw_attachment is Dictionary:
			result.append(
				{
					"scope_label": "Shared project attachment",
					"attachment": normalise_attachment(raw_attachment)
				}
			)
	var character := _get_character(project, character_id)
	for raw_attachment in character.get("attachments", []):
		if raw_attachment is Dictionary:
			result.append(
				{
					"scope_label": "Active character attachment",
					"attachment": normalise_attachment(raw_attachment)
				}
			)
	return result


static func _attachment_context_text(
	project_id: String,
	attachment: Dictionary,
	scope_label: String,
	character_limit: int
) -> Dictionary:
	var title := str(attachment.get("display_name", "Attachment"))
	var kind := str(attachment.get("kind", "file"))
	var notes := str(attachment.get("notes", "")).strip_edges()
	var body := ""
	if kind == "note":
		body = str(attachment.get("note_text", ""))
	elif kind in ["text", "subtitle", "transcript"]:
		var absolute_path := resolve_absolute_path(project_id, attachment)
		if not absolute_path.is_empty() and FileAccess.file_exists(absolute_path):
			var size_bytes := _file_size(absolute_path)
			if size_bytes <= MAX_TEXT_FILE_BYTES:
				body = FileAccess.get_file_as_string(absolute_path)
	else:
		var preprocess = attachment.get("preprocess", {})
		if preprocess is Dictionary:
			body = str(preprocess.get("summary", ""))
	if body.strip_edges().is_empty() and notes.is_empty():
		return {"text": "", "truncated": false}
	var header := "[%s: %s | %s]" % [scope_label, title, kind]
	var rendered := header
	if not notes.is_empty():
		rendered += "\nAttachment notes: %s" % notes
	if not body.strip_edges().is_empty():
		rendered += "\n%s" % body.strip_edges()
	var truncated := false
	if rendered.length() > character_limit:
		var truncation_marker := "\n[Attachment context truncated to fit the configured generation budget.]"
		if character_limit > truncation_marker.length():
			rendered = rendered.left(character_limit - truncation_marker.length())
			rendered += truncation_marker
		else:
			rendered = rendered.left(character_limit)
		truncated = true
	return {"text": rendered, "truncated": truncated}


static func _destination_relative_path(
	character_id: String, scope: String, attachment_id: String, source_filename: String
) -> String:
	var safe_filename := _safe_filename(source_filename)
	var stored_name := "%s_%s" % [attachment_id, safe_filename]
	if scope == "project":
		return "attachments/%s" % stored_name
	return "characters/%s/attachments/%s" % [character_id, stored_name]


static func _project_folder(project_id: String) -> String:
	return "user://character_card_forge/characters/%s" % project_id


static func _get_character(project: Dictionary, character_id: String) -> Dictionary:
	for raw_character in project.get("characters", []):
		if not raw_character is Dictionary:
			continue
		if str(raw_character.get("character_id", "")) == character_id:
			return raw_character.duplicate(true)
	return {}


static func _character_display_name(character: Dictionary) -> String:
	var character_data = character.get("character", {})
	if character_data is Dictionary:
		var card_name := str(character_data.get("name", "")).strip_edges()
		if not card_name.is_empty():
			return card_name
	var metadata = character.get("metadata", {})
	if metadata is Dictionary:
		var metadata_name := str(metadata.get("name", "")).strip_edges()
		if not metadata_name.is_empty():
			return metadata_name
	return "Character"


static func _estimate_tokens(text: String) -> int:
	if text.is_empty():
		return 0
	return maxi(1, int(ceil(float(text.length()) / 4.0)))


static func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var length := file.get_length()
	file.close()
	return length


static func _copy_file(source_path: String, destination_path: String) -> Dictionary:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return {"ok": false, "error": "Could not open the selected attachment."}
	var destination := FileAccess.open(destination_path, FileAccess.WRITE)
	if destination == null:
		source.close()
		return {"ok": false, "error": "Could not create the managed attachment copy."}
	while source.get_position() < source.get_length():
		var remaining := source.get_length() - source.get_position()
		destination.store_buffer(source.get_buffer(mini(1024 * 1024, remaining)))
	source.close()
	destination.close()
	return {"ok": true}


static func _kind_for_extension(extension: String) -> String:
	var lower := extension.to_lower()
	if lower in IMAGE_EXTENSIONS:
		return "image"
	if lower in GIF_EXTENSIONS:
		return "gif"
	if lower in SUBTITLE_EXTENSIONS:
		return "subtitle"
	if lower in TRANSCRIPT_EXTENSIONS:
		return "transcript"
	if lower in TEXT_EXTENSIONS:
		return "text"
	if lower == "pdf":
		return "pdf"
	return "file"


static func _mime_for_extension(extension: String) -> String:
	match extension.to_lower():
		"png":
			return "image/png"
		"jpg", "jpeg":
			return "image/jpeg"
		"webp":
			return "image/webp"
		"gif":
			return "image/gif"
		"bmp":
			return "image/bmp"
		"svg":
			return "image/svg+xml"
		"pdf":
			return "application/pdf"
		"json":
			return "application/json"
		"srt", "vtt", "ass", "ssa", "sub", "txt", "md", "markdown", "log", "transcript", "trs":
			return "text/plain"
		"csv":
			return "text/csv"
		"yaml", "yml":
			return "application/yaml"
		_:
			return "application/octet-stream"


static func _safe_filename(value: String) -> String:
	var clean := value.get_file().strip_edges()
	if clean.is_empty():
		clean = "attachment"
	for forbidden in ["/", "\\", ":", "*", "?", '"', "<", ">", "|"]:
		clean = clean.replace(forbidden, "_")
	return clean


static func _is_safe_relative_path(path: String) -> bool:
	if path.is_absolute_path():
		return false
	var normalised := path.replace("\\", "/")
	for part in normalised.split("/", false):
		if part == "..":
			return false
	return not normalised.is_empty()


static func _new_id() -> String:
	var unix := int(Time.get_unix_time_from_system())
	var random_part := randi_range(100000, 999999)
	return "attachment_%d_%d" % [unix, random_part]
