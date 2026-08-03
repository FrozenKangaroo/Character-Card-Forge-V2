class_name CCFCollaboratorAttachmentServiceV01521
extends RefCounted

const TEXT_EXTENSIONS := ["txt", "md", "markdown", "srt", "ass", "ssa", "json"]
const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
const MAX_TEXT_ATTACHMENT_BYTES := 4 * 1024 * 1024


static func classify_path(path: String) -> Dictionary:
	var extension := path.get_extension().to_lower()
	if extension in TEXT_EXTENSIONS:
		return {
			"ok": true,
			"kind": "text",
			"extension": extension,
			"format_label": _format_label(extension)
		}
	if extension in IMAGE_EXTENSIONS:
		return {
			"ok": true,
			"kind": "image",
			"extension": extension,
			"format_label": "Image"
		}
	return {
		"ok": false,
		"error": "Unsupported Collaborator attachment type: .%s" % extension,
		"extension": extension
	}


static func load_text_attachment(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"ok": false, "error": "The selected attachment file no longer exists."}
	var classification := classify_path(path)
	if not bool(classification.get("ok", false)) or str(classification.get("kind", "")) != "text":
		return {"ok": false, "error": str(classification.get("error", "This file is not a supported text attachment."))}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read %s." % path.get_file()}
	var byte_size := int(file.get_length())
	if byte_size > MAX_TEXT_ATTACHMENT_BYTES:
		file.close()
		return {
			"ok": false,
			"error": "%s is too large to attach directly (%s). The current per-file limit is %s." % [
				path.get_file(),
				_format_bytes(byte_size),
				_format_bytes(MAX_TEXT_ATTACHMENT_BYTES)
			]
		}
	var bytes := file.get_buffer(byte_size)
	file.close()
	if bytes.find(0) >= 0:
		return {"ok": false, "error": "%s appears to contain binary data rather than readable text." % path.get_file()}
	var text := bytes.get_string_from_utf8()
	if text.strip_edges().is_empty():
		return {"ok": false, "error": "%s is empty." % path.get_file()}

	var extension := str(classification.get("extension", ""))
	var line_count := text.count("\n") + 1
	var json_valid := true
	if extension == "json":
		json_valid = JSON.parse_string(text) != null

	return {
		"ok": true,
		"kind": "text",
		"attachment": {
			"type": "text_attachment",
			"attachment_kind": "text",
			"label": path.get_file(),
			"content": _context_content(path.get_file(), extension, text),
			"raw_text": text,
			"source_path": path,
			"source_extension": extension,
			"format_label": str(classification.get("format_label", _format_label(extension))),
			"byte_size": byte_size,
			"character_count": text.length(),
			"line_count": line_count,
			"json_valid": json_valid,
			"embedded_text_copy": true,
			"context_provenance": "user_attached_text_file"
		}
	}


static func is_attachment_context_item(item: Dictionary) -> bool:
	var item_type := str(item.get("type", ""))
	return item_type in ["text_attachment", "vision_reference"] or not str(item.get("attachment_kind", "")).is_empty()


static func display_format(item: Dictionary) -> String:
	var explicit := str(item.get("format_label", "")).strip_edges()
	if not explicit.is_empty():
		return explicit
	if str(item.get("type", "")) == "vision_reference" or str(item.get("attachment_kind", "")) == "image":
		return "Image"
	var extension := str(item.get("source_extension", "")).to_lower()
	return _format_label(extension) if not extension.is_empty() else "Attachment"


static func _context_content(filename: String, extension: String, raw_text: String) -> String:
	var format_label := _format_label(extension)
	return "USER-ATTACHED %s FILE — %s\nThe contents below are preserved verbatim as reference material. Treat timestamps, dialogue order, speaker/style cues, keys and structure as source evidence where relevant; do not assume the file itself changed project data.\n\n%s" % [format_label.to_upper(), filename, raw_text]


static func _format_label(extension: String) -> String:
	match extension:
		"txt": return "Text"
		"md", "markdown": return "Markdown"
		"srt": return "SRT subtitle"
		"ass": return "ASS subtitle"
		"ssa": return "SSA subtitle"
		"json": return "JSON"
		_: return extension.to_upper() if not extension.is_empty() else "Attachment"


static func _format_bytes(value: int) -> String:
	if value >= 1024 * 1024:
		return "%.1f MiB" % (float(value) / float(1024 * 1024))
	if value >= 1024:
		return "%.1f KiB" % (float(value) / 1024.0)
	return "%d bytes" % value
