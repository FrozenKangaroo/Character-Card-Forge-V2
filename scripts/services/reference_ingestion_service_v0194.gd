class_name CCFReferenceIngestionServiceV0194
extends RefCounted

const MAX_PDF_BYTES := 32 * 1024 * 1024
const MAX_REMOTE_BYTES := 16 * 1024 * 1024
const MAX_EXTRACTED_CHARACTERS := 500000
const MAX_PREVIEW_CHARACTERS := 120000
const MAX_DECOMPRESSED_STREAM_BYTES := 8 * 1024 * 1024

const REMOTE_TEXT_MIME_TYPES := [
	"text/plain", "text/markdown", "text/csv", "text/html",
	"application/json", "application/yaml", "application/x-yaml",
	"application/xhtml+xml"
]
const REMOTE_IMAGE_MIME_TYPES := ["image/png", "image/jpeg", "image/webp"]


static func validate_https_url(source_url: String) -> Dictionary:
	var clean_url := source_url.strip_edges()
	if clean_url.is_empty():
		return {"ok": false, "error": "Enter an HTTPS address first."}
	if not clean_url.left(8).to_lower() == "https://":
		return {
			"ok": false,
			"error": "Remote references must use HTTPS. Download a local copy first if the source is HTTP-only."
		}
	var authority_end := clean_url.length()
	for delimiter in ["/", "?", "#"]:
		var delimiter_index := clean_url.find(delimiter, 8)
		if delimiter_index >= 0:
			authority_end = mini(authority_end, delimiter_index)
	var authority := clean_url.substr(8, authority_end - 8)
	if (
		authority.is_empty()
		or authority.contains("@")
		or authority.contains("?")
		or authority.contains("#")
	):
		return {
			"ok": false,
			"error": "The HTTPS address must have a host and cannot contain embedded credentials."
		}
	if clean_url.contains("\n") or clean_url.contains("\r") or clean_url.contains(" "):
		return {"ok": false, "error": "The HTTPS address contains invalid whitespace."}
	return {"ok": true, "url": clean_url}


static func resolve_redirect_url(current_url: String, location: String) -> Dictionary:
	var clean_location := location.strip_edges()
	if clean_location.is_empty():
		return {"ok": false, "error": "The remote source returned a redirect without a destination."}
	if clean_location.left(8).to_lower() == "https://":
		return validate_https_url(clean_location)
	if clean_location.left(7).to_lower() == "http://":
		return {
			"ok": false,
			"error": "The remote source redirected to insecure HTTP, so the download was stopped."
		}
	var origin_end := current_url.find("/", 8)
	var origin := current_url if origin_end < 0 else current_url.left(origin_end)
	if clean_location.begins_with("/"):
		return validate_https_url(origin + clean_location)
	var without_fragment := current_url.split("#", false, 1)[0]
	var without_query := without_fragment.split("?", false, 1)[0]
	var base_directory := without_query.get_base_dir().trim_suffix("/")
	return validate_https_url(
		"%s/%s" % [base_directory, clean_location.trim_prefix("/")]
	)


static func inspect_download(
	body: PackedByteArray, content_type: String, suggested_filename: String
) -> Dictionary:
	if body.is_empty():
		return {"ok": false, "error": "The remote reference is empty."}
	if body.size() > MAX_REMOTE_BYTES:
		return {
			"ok": false,
			"error": "The remote reference exceeds the 16 MB download limit."
		}
	var clean_type := content_type.split(";", false, 1)[0].strip_edges().to_lower()
	var filename := _safe_remote_filename(suggested_filename, clean_type)
	var extension := filename.get_extension().to_lower()
	var kind := ""
	if clean_type == "application/pdf" or extension == "pdf" or _has_pdf_magic(body):
		kind = "pdf"
		clean_type = "application/pdf"
	elif clean_type in REMOTE_IMAGE_MIME_TYPES or extension in ["png", "jpg", "jpeg", "webp"]:
		kind = "image"
		if not clean_type in REMOTE_IMAGE_MIME_TYPES:
			clean_type = (
				"image/png" if extension == "png"
				else "image/webp" if extension == "webp"
				else "image/jpeg"
			)
	elif clean_type in REMOTE_TEXT_MIME_TYPES or extension in [
		"txt", "md", "markdown", "csv", "json", "yaml", "yml", "html", "htm"
	]:
		kind = "text"
		if not clean_type in REMOTE_TEXT_MIME_TYPES:
			clean_type = "text/html" if extension in ["html", "htm"] else "text/plain"
	else:
		return {
			"ok": false,
			"error": "This address returned an unsupported content type (%s). Use PDF, readable text/HTML/JSON, PNG, JPEG or WebP." % (
				clean_type if not clean_type.is_empty() else "unknown"
			)
		}

	var preprocess: Dictionary
	var preview_text := ""
	if kind == "pdf":
		preprocess = extract_pdf_bytes(body)
		if str(preprocess.get("status", "")) == "error":
			return {"ok": false, "error": str(preprocess.get("summary", "Could not inspect the PDF."))}
		preview_text = str(preprocess.get("extracted_text", ""))
	elif kind == "text":
		var raw_text := body.get_string_from_utf8()
		if body.has(0):
			return {"ok": false, "error": "The remote reference contains binary data rather than readable text."}
		var extracted_text := _html_to_text(raw_text) if clean_type in ["text/html", "application/xhtml+xml"] or extension in ["html", "htm"] else raw_text
		extracted_text = _clean_extracted_text(extracted_text)
		if extracted_text.is_empty():
			return {"ok": false, "error": "No readable text was found in the remote reference."}
		var truncated := extracted_text.length() > MAX_EXTRACTED_CHARACTERS
		if truncated:
			extracted_text = extracted_text.left(MAX_EXTRACTED_CHARACTERS)
		preprocess = {
			"status": "ready",
			"summary": "Remote %s: %d characters, approximately %d tokens%s." % [
				"HTML text" if clean_type in ["text/html", "application/xhtml+xml"] else "text",
				extracted_text.length(),
				_estimate_tokens(extracted_text),
				" (bounded extraction)" if truncated else ""
			],
			"character_count": extracted_text.length(),
			"estimated_tokens": _estimate_tokens(extracted_text),
			"image_width": 0,
			"image_height": 0,
			"page_count": 0,
			"truncated": truncated,
			"extracted_text": extracted_text,
			"extraction_method": "local_html_text_v0194" if clean_type in ["text/html", "application/xhtml+xml"] else "local_utf8_text_v0194"
		}
		preview_text = extracted_text
	else:
		var image := Image.new()
		var image_error := _load_image_buffer(image, body, clean_type, extension)
		if image_error != OK or image.is_empty():
			return {"ok": false, "error": "The downloaded image could not be decoded safely."}
		preprocess = {
			"status": "ready",
			"summary": "Remote image, %d × %d pixels, %s." % [
				image.get_width(), image.get_height(), _format_bytes(body.size())
			],
			"character_count": 0,
			"estimated_tokens": 0,
			"image_width": image.get_width(),
			"image_height": image.get_height(),
			"page_count": 0,
			"truncated": false
		}
	return {
		"ok": true,
		"kind": kind,
		"mime_type": clean_type,
		"filename": filename,
		"size_bytes": body.size(),
		"preprocess": preprocess,
		"preview_text": _bounded_preview(preview_text),
		"preview_truncated": preview_text.length() > MAX_PREVIEW_CHARACTERS
	}


static func preprocess_pdf_path(absolute_path: String) -> Dictionary:
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return _pdf_failure("The stored PDF could not be opened.", "missing")
	var length := int(file.get_length())
	if length > MAX_PDF_BYTES:
		file.close()
		return _pdf_failure("PDF stored, but it exceeds the 32 MB local extraction limit.", "too_large")
	var bytes := file.get_buffer(length)
	file.close()
	return extract_pdf_bytes(bytes)


static func extract_pdf_bytes(pdf_bytes: PackedByteArray) -> Dictionary:
	if pdf_bytes.is_empty() or not _has_pdf_magic(pdf_bytes):
		return _pdf_failure("The selected file does not have a valid PDF header.")
	if pdf_bytes.size() > MAX_PDF_BYTES:
		return _pdf_failure("PDF exceeds the 32 MB local extraction limit.", "too_large")
	var document_text := _ascii_projection(pdf_bytes)
	var objects := _pdf_objects(pdf_bytes, document_text)
	if objects.is_empty():
		return _pdf_failure("PDF structure could not be inspected safely.")
	var decoded_streams: Dictionary = {}
	var unicode_map: Dictionary = {}
	for object_id in objects:
		var object_bytes: PackedByteArray = objects.get(object_id, PackedByteArray())
		var object_body := _ascii_projection(object_bytes)
		if not object_body.contains("stream"):
			continue
		var decoded := _decode_pdf_stream(object_bytes)
		if decoded.is_empty():
			continue
		var decoded_text := decoded.get_string_from_ascii()
		decoded_streams[object_id] = decoded_text
		unicode_map.merge(_parse_to_unicode_map(decoded_text), true)

	var page_records: Array[Dictionary] = []
	var extracted_sections: Array[String] = []
	var page_number := 0
	for object_id in objects:
		var page_body := _ascii_projection(
			objects.get(object_id, PackedByteArray())
		)
		if not _is_pdf_page_object(page_body):
			continue
		page_number += 1
		var page_parts: Array[String] = []
		for content_id in _page_content_references(page_body):
			var stream_text := str(decoded_streams.get(content_id, ""))
			var part := _extract_pdf_content_text(stream_text, unicode_map)
			if not part.is_empty():
				page_parts.append(part)
		var page_text := _clean_extracted_text("\n".join(page_parts))
		page_records.append({
			"page": page_number,
			"character_count": page_text.length(),
			"has_text": not page_text.is_empty()
		})
		if not page_text.is_empty():
			extracted_sections.append("[Page %d]\n%s" % [page_number, page_text])

	if page_records.is_empty():
		for object_id in decoded_streams:
			var fallback_stream := str(decoded_streams.get(object_id, ""))
			if not fallback_stream.contains("BT"):
				continue
			var fallback_text := _extract_pdf_content_text(fallback_stream, unicode_map)
			if not fallback_text.is_empty():
				extracted_sections.append(fallback_text)
	var extracted_text := _clean_extracted_text("\n\n".join(extracted_sections))
	var truncated := extracted_text.length() > MAX_EXTRACTED_CHARACTERS
	if truncated:
		extracted_text = extracted_text.left(MAX_EXTRACTED_CHARACTERS)
	var detected_page_count := page_records.size()
	if detected_page_count == 0:
		detected_page_count = _fallback_page_count(document_text)
	if extracted_text.is_empty():
		return {
			"status": "no_text_layer",
			"summary": "PDF stored (%s), but no readable text layer was found. Scanned-page OCR remains an explicit future option." % _format_bytes(pdf_bytes.size()),
			"character_count": 0,
			"estimated_tokens": 0,
			"image_width": 0,
			"image_height": 0,
			"page_count": detected_page_count,
			"pages": page_records,
			"truncated": false,
			"extracted_text": "",
			"extraction_method": "local_pdf_text_v0194"
		}
	return {
		"status": "ready",
		"summary": "PDF text layer: %d page(s), %d characters, approximately %d tokens%s." % [
			detected_page_count,
			extracted_text.length(),
			_estimate_tokens(extracted_text),
			" (bounded extraction)" if truncated else ""
		],
		"character_count": extracted_text.length(),
		"estimated_tokens": _estimate_tokens(extracted_text),
		"image_width": 0,
		"image_height": 0,
		"page_count": detected_page_count,
		"pages": page_records,
		"truncated": truncated,
		"extracted_text": extracted_text,
		"extraction_method": "local_pdf_text_v0194"
	}


static func _pdf_objects(
	pdf_bytes: PackedByteArray, document_text: String
) -> Dictionary:
	var result: Dictionary = {}
	var regex := RegEx.new()
	if regex.compile("(?s)(\\d+)\\s+\\d+\\s+obj(.*?)endobj") != OK:
		return result
	for match_value in regex.search_all(document_text):
		result[str(match_value.get_string(1))] = pdf_bytes.slice(
			match_value.get_start(2), match_value.get_end(2)
		)
	return result


static func _decode_pdf_stream(object_bytes: PackedByteArray) -> PackedByteArray:
	var object_body := _ascii_projection(object_bytes)
	var stream_index := object_body.find("stream")
	var end_index := object_body.rfind("endstream")
	if stream_index < 0 or end_index <= stream_index:
		return PackedByteArray()
	var data_start := stream_index + 6
	if object_body.substr(data_start, 2) == "\r\n":
		data_start += 2
	elif object_body.substr(data_start, 1) in ["\r", "\n"]:
		data_start += 1
	var stream_end := end_index
	var length_regex := RegEx.new()
	length_regex.compile("/Length\\s+(\\d+)")
	var length_match := length_regex.search(object_body.left(stream_index))
	var indirect_length_regex := RegEx.new()
	indirect_length_regex.compile("/Length\\s+\\d+\\s+\\d+\\s+R")
	var uses_indirect_length := (
		indirect_length_regex.search(object_body.left(stream_index)) != null
	)
	if length_match != null and not uses_indirect_length:
		stream_end = mini(end_index, data_start + int(length_match.get_string(1)))
	else:
		while stream_end > data_start and object_bytes[stream_end - 1] in [10, 13]:
			stream_end -= 1
	var stream_bytes := object_bytes.slice(data_start, stream_end)
	if object_body.left(stream_index).contains("/FlateDecode"):
		var decompressed := stream_bytes.decompress_dynamic(
			MAX_DECOMPRESSED_STREAM_BYTES, FileAccess.COMPRESSION_DEFLATE
		)
		return decompressed
	if object_body.left(stream_index).contains("/ASCIIHexDecode"):
		return _hex_to_bytes(
			_ascii_projection(stream_bytes).replace(">", "")
		)
	return stream_bytes


static func _ascii_projection(bytes: PackedByteArray) -> String:
	var projected := PackedByteArray()
	projected.resize(bytes.size())
	for index in range(bytes.size()):
		var value := bytes[index]
		projected[index] = value if value in [9, 10, 13] or value >= 32 and value <= 126 else 32
	return projected.get_string_from_ascii()


static func _is_pdf_page_object(object_body: String) -> bool:
	var regex := RegEx.new()
	regex.compile("/Type\\s*/Page(?:\\s|/|>>)")
	return regex.search(object_body) != null


static func _page_content_references(page_body: String) -> Array[String]:
	var result: Array[String] = []
	var contents_regex := RegEx.new()
	contents_regex.compile("(?s)/Contents\\s*(?:\\[(.*?)\\]|(\\d+)\\s+\\d+\\s+R)")
	var contents_match := contents_regex.search(page_body)
	if contents_match == null:
		return result
	var direct_ref := contents_match.get_string(2)
	if not direct_ref.is_empty():
		result.append(direct_ref)
		return result
	var reference_regex := RegEx.new()
	reference_regex.compile("(\\d+)\\s+\\d+\\s+R")
	for reference_match in reference_regex.search_all(contents_match.get_string(1)):
		result.append(reference_match.get_string(1))
	return result


static func _parse_to_unicode_map(stream_text: String) -> Dictionary:
	var result: Dictionary = {}
	if not stream_text.contains("beginbf"):
		return result
	var pair_regex := RegEx.new()
	pair_regex.compile("<([0-9A-Fa-f]+)>\\s*<([0-9A-Fa-f]+)>")
	for pair_match in pair_regex.search_all(stream_text):
		var source_hex := pair_match.get_string(1).to_upper()
		var target_hex := pair_match.get_string(2)
		var decoded := _decode_unicode_hex(target_hex)
		if not source_hex.is_empty() and not decoded.is_empty():
			result[source_hex] = decoded
	return result


static func _extract_pdf_content_text(
	stream_text: String, unicode_map: Dictionary
) -> String:
	if stream_text.is_empty() or not stream_text.contains("BT"):
		return ""
	var result: Array[String] = []
	var block_regex := RegEx.new()
	block_regex.compile("(?s)BT(.*?)ET")
	var operand_regex := RegEx.new()
	operand_regex.compile("(?s)(\\((?:\\\\.|[^\\\\)])*\\)|<[0-9A-Fa-f\\s]+>|\\[(.*?)\\])\\s*(Tj|TJ|'|\")")
	for block_match in block_regex.search_all(stream_text):
		var block := block_match.get_string(1)
		var block_parts: Array[String] = []
		for operand_match in operand_regex.search_all(block):
			var operand := operand_match.get_string(1)
			var decoded := ""
			if operand.begins_with("["):
				decoded = _decode_pdf_text_array(operand, unicode_map)
			else:
				decoded = _decode_pdf_text_operand(operand, unicode_map)
			if not decoded.is_empty():
				block_parts.append(decoded)
		var block_text := _clean_extracted_text(" ".join(block_parts))
		if not block_text.is_empty():
			result.append(block_text)
	return _clean_extracted_text("\n".join(result))


static func _decode_pdf_text_array(operand: String, unicode_map: Dictionary) -> String:
	var parts: Array[String] = []
	var token_regex := RegEx.new()
	token_regex.compile("(?s)\\((?:\\\\.|[^\\\\)])*\\)|<[0-9A-Fa-f\\s]+>")
	for token_match in token_regex.search_all(operand):
		var decoded := _decode_pdf_text_operand(token_match.get_string(0), unicode_map)
		if not decoded.is_empty():
			parts.append(decoded)
	return "".join(parts)


static func _decode_pdf_text_operand(operand: String, unicode_map: Dictionary) -> String:
	if operand.begins_with("("):
		return _decode_pdf_literal(operand.substr(1, maxi(0, operand.length() - 2)))
	if operand.begins_with("<"):
		var hex_text := operand.substr(1, maxi(0, operand.length() - 2)).replace(" ", "").replace("\n", "").replace("\r", "").replace("\t", "")
		return _decode_pdf_hex_text(hex_text, unicode_map)
	return ""


static func _decode_pdf_literal(encoded: String) -> String:
	var output := PackedByteArray()
	var index := 0
	while index < encoded.length():
		var character := encoded.substr(index, 1)
		if character != "\\":
			output.append(character.to_ascii_buffer()[0])
			index += 1
			continue
		index += 1
		if index >= encoded.length():
			break
		var escaped := encoded.substr(index, 1)
		match escaped:
			"n": output.append(10)
			"r": output.append(13)
			"t": output.append(9)
			"b": output.append(8)
			"f": output.append(12)
			"\n": pass
			"\r":
				if index + 1 < encoded.length() and encoded.substr(index + 1, 1) == "\n":
					index += 1
			_:
				if escaped >= "0" and escaped <= "7":
					var octal := escaped
					var extra := 0
					while extra < 2 and index + 1 < encoded.length():
						var next_character := encoded.substr(index + 1, 1)
						if next_character < "0" or next_character > "7":
							break
						octal += next_character
						index += 1
						extra += 1
					output.append(_octal_to_int(octal) & 0xff)
				else:
					output.append(escaped.to_ascii_buffer()[0])
		index += 1
	return output.get_string_from_utf8()


static func _decode_pdf_hex_text(hex_text: String, unicode_map: Dictionary) -> String:
	var upper := hex_text.to_upper()
	if unicode_map.has(upper):
		return str(unicode_map.get(upper, ""))
	var mapped := ""
	var widths := [4, 2]
	for width in widths:
		if upper.length() % width != 0:
			continue
		var complete := true
		var candidate := ""
		for index in range(0, upper.length(), width):
			var code := upper.substr(index, width)
			if not unicode_map.has(code):
				complete = false
				break
			candidate += str(unicode_map.get(code, ""))
		if complete and not candidate.is_empty():
			mapped = candidate
			break
	if not mapped.is_empty():
		return mapped
	var bytes := _hex_to_bytes(upper)
	if bytes.size() >= 2 and bytes[0] == 0xfe and bytes[1] == 0xff:
		return bytes.get_string_from_utf16()
	var looks_utf16_be := bytes.size() >= 2 and bytes.size() % 2 == 0
	if looks_utf16_be:
		for index in range(0, bytes.size(), 2):
			if bytes[index] != 0:
				looks_utf16_be = false
				break
	if looks_utf16_be:
		var with_bom := PackedByteArray([0xfe, 0xff])
		with_bom.append_array(bytes)
		return with_bom.get_string_from_utf16()
	return bytes.get_string_from_utf8()


static func _decode_unicode_hex(hex_text: String) -> String:
	var bytes := _hex_to_bytes(hex_text)
	if bytes.is_empty():
		return ""
	if not (bytes.size() >= 2 and bytes[0] == 0xfe and bytes[1] == 0xff):
		var with_bom := PackedByteArray([0xfe, 0xff])
		with_bom.append_array(bytes)
		bytes = with_bom
	return bytes.get_string_from_utf16()


static func _hex_to_bytes(hex_text: String) -> PackedByteArray:
	var clean := hex_text.replace(" ", "").replace("\n", "").replace("\r", "").replace("\t", "")
	if clean.length() % 2 != 0:
		clean += "0"
	var result := PackedByteArray()
	for index in range(0, clean.length(), 2):
		result.append(clean.substr(index, 2).hex_to_int() & 0xff)
	return result


static func _octal_to_int(octal: String) -> int:
	var result := 0
	for digit in octal:
		result = result * 8 + int(digit)
	return result


static func _fallback_page_count(document_text: String) -> int:
	var regex := RegEx.new()
	regex.compile("/Type\\s*/Page(?:\\s|/|>>)")
	return regex.search_all(document_text).size()


static func _html_to_text(html: String) -> String:
	var text := html
	for pattern in ["(?is)<script[^>]*>.*?</script>", "(?is)<style[^>]*>.*?</style>", "(?is)<!--.*?-->"]:
		var remover := RegEx.new()
		remover.compile(pattern)
		text = remover.sub(text, " ", true)
	var breaks := RegEx.new()
	breaks.compile("(?i)</?(?:p|div|br|li|h[1-6]|tr|section|article)[^>]*>")
	text = breaks.sub(text, "\n", true)
	var tags := RegEx.new()
	tags.compile("(?s)<[^>]+>")
	text = tags.sub(text, " ", true)
	for entity in {
		"&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
		"&quot;": "\"", "&#39;": "'"
	}:
		text = text.replace(str(entity), str({
			"&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
			"&quot;": "\"", "&#39;": "'"
		}.get(entity)))
	return text


static func _clean_extracted_text(raw_text: String) -> String:
	var text := raw_text.replace("\r\n", "\n").replace("\r", "\n")
	var horizontal := RegEx.new()
	horizontal.compile("[\\t ]+")
	text = horizontal.sub(text, " ", true)
	var blank_lines := RegEx.new()
	blank_lines.compile("\\n[ \\n]*\\n[ \\n]*")
	text = blank_lines.sub(text, "\n\n", true)
	return text.strip_edges()


static func _bounded_preview(text: String) -> String:
	if text.length() <= MAX_PREVIEW_CHARACTERS:
		return text
	return text.left(MAX_PREVIEW_CHARACTERS) + "\n\n[Preview truncated; the managed extraction retains the bounded full text.]"


static func _load_image_buffer(
	image: Image, body: PackedByteArray, mime_type: String, extension: String
) -> Error:
	if mime_type == "image/png" or extension == "png":
		return image.load_png_from_buffer(body)
	if mime_type == "image/webp" or extension == "webp":
		return image.load_webp_from_buffer(body)
	return image.load_jpg_from_buffer(body)


static func _has_pdf_magic(bytes: PackedByteArray) -> bool:
	return bytes.size() >= 5 and bytes.slice(0, 5).get_string_from_ascii() == "%PDF-"


static func _safe_remote_filename(filename: String, mime_type: String) -> String:
	var clean := filename.get_file().uri_decode().strip_edges()
	if clean.is_empty():
		clean = "remote-reference" + _extension_for_mime(mime_type)
	for forbidden in ["/", "\\", ":", "*", "?", '"', "<", ">", "|"]:
		clean = clean.replace(forbidden, "_")
	if clean.get_extension().is_empty():
		clean += _extension_for_mime(mime_type)
	return clean


static func _extension_for_mime(mime_type: String) -> String:
	match mime_type:
		"application/pdf": return ".pdf"
		"application/json": return ".json"
		"text/html", "application/xhtml+xml": return ".html"
		"text/markdown": return ".md"
		"text/csv": return ".csv"
		"image/png": return ".png"
		"image/jpeg": return ".jpg"
		"image/webp": return ".webp"
		_: return ".txt"


static func _pdf_failure(summary: String, status := "error") -> Dictionary:
	return {
		"status": status,
		"summary": summary,
		"character_count": 0,
		"estimated_tokens": 0,
		"image_width": 0,
		"image_height": 0,
		"page_count": 0,
		"pages": [],
		"truncated": false,
		"extracted_text": "",
		"extraction_method": "local_pdf_text_v0194"
	}


static func _estimate_tokens(text: String) -> int:
	return 0 if text.is_empty() else maxi(1, int(ceil(float(text.length()) / 4.0)))


static func _format_bytes(byte_count: int) -> String:
	if byte_count >= 1024 * 1024:
		return "%.1f MB" % (float(byte_count) / float(1024 * 1024))
	if byte_count >= 1024:
		return "%.1f KB" % (float(byte_count) / 1024.0)
	return "%d B" % byte_count
