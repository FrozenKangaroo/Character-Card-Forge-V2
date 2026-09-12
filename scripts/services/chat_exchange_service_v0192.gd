class_name CCFChatExchangeServiceV0192
extends RefCounted

const EXCHANGE_DIR := CCFStorageService.ROOT_DIR + "/chat_exchanges_v0192"
const INDEX_FILE := EXCHANGE_DIR + "/index.json"
const FORMAT_VERSION := 1
const FPCHAT_FORMAT := "fpai_chat"
const FPCHAT_VERSION := 1
const MAX_SOURCE_BYTES := 256 * 1024 * 1024
const MAX_CHAT_JSON_BYTES := 32 * 1024 * 1024
const MAX_MESSAGES := 200000


static func capabilities() -> Dictionary:
	return {
		"fpchat_zip": true,
		"fpchat_raw_json": true,
		"sillytavern_jsonl": true,
		"preview_before_transfer": true,
		"managed_source_copy": true,
		"source_hash_provenance": true,
		"opaque_fpai_state_preserved": true,
		"card_data_separation": true,
		"path_traversal_rejected": true,
		"raw_database_writes": false
	}


static func inspect_path(source_path: String) -> Dictionary:
	if not FileAccess.file_exists(source_path):
		return {"ok": false, "error": "The selected chat file does not exist."}
	var source_size := FileAccess.get_file_as_bytes(source_path).size()
	if source_size <= 0:
		return {"ok": false, "error": "The selected chat file is empty."}
	if source_size > MAX_SOURCE_BYTES:
		return {"ok": false, "error": "The selected chat file exceeds Front Porch's 256 MB import limit."}
	var extension := source_path.get_extension().to_lower()
	if extension == "fpchat":
		return _inspect_fpchat(source_path)
	if extension in ["jsonl", "json"]:
		return _inspect_text_chat(source_path)
	return {"ok": false, "error": "Choose a .fpchat, .jsonl or compatible .json chat file."}


static func store_managed_copy(
	source_path: String, project_id: String, character_id: String
) -> Dictionary:
	var inspection := inspect_path(source_path)
	if not bool(inspection.get("ok", false)):
		return inspection
	var source_bytes := FileAccess.get_file_as_bytes(source_path)
	var source_hash := _sha256_bytes(source_bytes)
	var exchange_id := "%d-%s" % [Time.get_ticks_usec(), source_hash.substr(0, 12)]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXCHANGE_DIR))
	var extension := source_path.get_extension().to_lower()
	var destination := EXCHANGE_DIR.path_join("%s.%s" % [exchange_id, extension])
	var output := FileAccess.open(destination, FileAccess.WRITE)
	if output == null:
		return {"ok": false, "error": "Could not preserve the chat file in managed storage."}
	output.store_buffer(source_bytes)
	output.close()
	var record := {
		"exchange_id": exchange_id,
		"project_id": project_id,
		"character_id": character_id,
		"source_filename": source_path.get_file(),
		"managed_path": destination,
		"sha256": source_hash,
		"format": inspection.get("format", "unknown"),
		"message_count": inspection.get("message_count", 0),
		"imported_at": Time.get_datetime_string_from_system(true)
	}
	var index := load_index()
	var exchanges: Array = index.get("exchanges", []).duplicate(true)
	exchanges.push_front(record)
	if exchanges.size() > 100:
		exchanges.resize(100)
	index["exchanges"] = exchanges
	var saved := _write_index(index)
	if not bool(saved.get("ok", false)):
		return saved
	return {"ok": true, "record": record, "inspection": inspection}


static func store_download(
	file_bytes: PackedByteArray,
	format_id: String,
	project_id: String,
	character_id: String,
	source_label := "Front Porch export"
) -> Dictionary:
	if file_bytes.is_empty():
		return {"ok": false, "error": "Front Porch returned an empty chat export."}
	var extension := "fpchat" if format_id == "fpchat" else "jsonl"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXCHANGE_DIR))
	var file_hash := _sha256_bytes(file_bytes)
	var exchange_id := "%d-%s" % [Time.get_ticks_usec(), file_hash.substr(0, 12)]
	var destination := EXCHANGE_DIR.path_join("%s.%s" % [exchange_id, extension])
	var output := FileAccess.open(destination, FileAccess.WRITE)
	if output == null:
		return {"ok": false, "error": "Could not preserve the exported chat."}
	output.store_buffer(file_bytes)
	output.close()
	var inspection := inspect_path(destination)
	if not bool(inspection.get("ok", false)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(destination))
		return inspection
	var record := {
		"exchange_id": exchange_id,
		"project_id": project_id,
		"character_id": character_id,
		"source_filename": source_label,
		"managed_path": destination,
		"sha256": file_hash,
		"format": inspection.get("format", format_id),
		"message_count": inspection.get("message_count", 0),
		"imported_at": Time.get_datetime_string_from_system(true)
	}
	var index := load_index()
	var exchanges: Array = index.get("exchanges", []).duplicate(true)
	exchanges.push_front(record)
	if exchanges.size() > 100:
		exchanges.resize(100)
	index["exchanges"] = exchanges
	var saved := _write_index(index)
	if not bool(saved.get("ok", false)):
		return saved
	return {"ok": true, "record": record, "inspection": inspection}


static func export_managed_copy(record: Dictionary, destination_path: String) -> Dictionary:
	var managed_path := str(record.get("managed_path", ""))
	if not FileAccess.file_exists(managed_path):
		return {"ok": false, "error": "The managed chat source is missing."}
	var output := FileAccess.open(destination_path, FileAccess.WRITE)
	if output == null:
		return {"ok": false, "error": "Could not create the selected export file."}
	output.store_buffer(FileAccess.get_file_as_bytes(managed_path))
	output.close()
	return {"ok": true, "path": destination_path}


static func load_index() -> Dictionary:
	if not FileAccess.file_exists(INDEX_FILE):
		return {"format_version": FORMAT_VERSION, "exchanges": []}
	var file := FileAccess.open(INDEX_FILE, FileAccess.READ)
	if file == null:
		return {"format_version": FORMAT_VERSION, "exchanges": []}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {"format_version": FORMAT_VERSION, "exchanges": []}
	return (parsed as Dictionary).duplicate(true)


static func preview_text(inspection: Dictionary, limit := 40) -> String:
	if not bool(inspection.get("ok", false)):
		return str(inspection.get("error", "The chat could not be inspected."))
	var lines := PackedStringArray([
		"Format: %s" % str(inspection.get("label", inspection.get("format", "Unknown"))),
		"Messages: %d" % int(inspection.get("message_count", 0)),
		"Character: %s" % str(inspection.get("character_name", "Unknown")),
		"User: %s" % str(inspection.get("user_name", "Unknown")),
		""
	])
	var messages: Array = inspection.get("messages", [])
	var shown := mini(messages.size(), limit)
	for message_index in range(shown):
		var message_value: Variant = messages[message_index]
		if not message_value is Dictionary:
			continue
		var message := message_value as Dictionary
		lines.append("%s: %s" % [
			str(message.get("sender", "Unknown")),
			str(message.get("text", "")).replace("\n", " ").left(320)
		])
	if messages.size() > shown:
		lines.append("… %d more message(s)" % (messages.size() - shown))
	return "\n".join(lines)


static func sillytavern_jsonl(messages: Array, user_name: String, character_name: String) -> String:
	var lines := PackedStringArray([JSON.stringify({
		"user_name": user_name,
		"character_name": character_name,
		"create_date": Time.get_datetime_string_from_system(true)
	})])
	for message_value in messages:
		if not message_value is Dictionary:
			continue
		var message := message_value as Dictionary
		lines.append(JSON.stringify({
			"name": str(message.get("sender", user_name)),
			"is_user": bool(message.get("is_user", false)),
			"mes": str(message.get("text", "")),
			"send_date": str(message.get("send_date", "")),
			"extra": {}
		}))
	return "\n".join(lines) + "\n"


static func _inspect_fpchat(source_path: String) -> Dictionary:
	var reader := ZIPReader.new()
	var open_error := reader.open(source_path)
	if open_error != OK:
		return {"ok": false, "error": "The .fpchat package is not a readable ZIP archive."}
	for entry_value in reader.get_files():
		if not _safe_archive_path(str(entry_value)):
			reader.close()
			return {"ok": false, "error": "The .fpchat package contains an unsafe file path."}
	if not reader.file_exists("chat.json"):
		reader.close()
		return {"ok": false, "error": "The .fpchat package is missing chat.json."}
	var chat_bytes := reader.read_file("chat.json")
	reader.close()
	if chat_bytes.size() > MAX_CHAT_JSON_BYTES:
		return {"ok": false, "error": "The .fpchat timeline is too large to preview safely."}
	var parsed: Variant = JSON.parse_string(chat_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return {"ok": false, "error": "The .fpchat chat.json is invalid."}
	return _inspect_fpchat_document(parsed, "fpchat")


static func _inspect_text_chat(source_path: String) -> Dictionary:
	var source_text := FileAccess.get_file_as_string(source_path)
	var parser := JSON.new()
	var parsed: Variant = null
	if parser.parse(source_text) == OK:
		parsed = parser.data
	if parsed is Dictionary and str((parsed as Dictionary).get("format", "")) == FPCHAT_FORMAT:
		return _inspect_fpchat_document(parsed, "fpchat_json")
	if parsed is Array or (parsed is Dictionary and (parsed as Dictionary).get("messages", null) is Array):
		return _inspect_sillytavern_json(parsed)
	return _inspect_jsonl(source_text)


static func _inspect_sillytavern_json(parsed: Variant) -> Dictionary:
	var raw_messages: Variant = parsed
	var user_name := "User"
	var character_name := "Character"
	if parsed is Dictionary:
		var document := parsed as Dictionary
		raw_messages = document.get("messages", [])
		user_name = str(document.get("user_name", user_name))
		character_name = str(document.get("character_name", character_name))
	if not raw_messages is Array or (raw_messages as Array).size() > MAX_MESSAGES:
		return {"ok": false, "error": "The SillyTavern JSON message list is invalid or too large."}
	var messages := _normalise_messages(raw_messages)
	if messages.is_empty():
		return {"ok": false, "error": "No compatible chat messages were found."}
	return {
		"ok": true,
		"format": "sillytavern_json",
		"label": "SillyTavern JSON",
		"character_name": character_name,
		"user_name": user_name,
		"message_count": messages.size(),
		"messages": messages,
		"opaque_full_state": false
	}


static func _inspect_fpchat_document(parsed: Variant, format_id: String) -> Dictionary:
	if not parsed is Dictionary:
		return {"ok": false, "error": "The Front Porch chat document is invalid."}
	var document := parsed as Dictionary
	if str(document.get("format", "")) != FPCHAT_FORMAT:
		return {"ok": false, "error": "The chat package does not identify itself as fpai_chat."}
	if int(document.get("version", 0)) > FPCHAT_VERSION:
		return {"ok": false, "error": "This .fpchat version is newer than Character Card Forge supports."}
	var raw_messages: Variant = document.get("messages", [])
	if not raw_messages is Array or (raw_messages as Array).size() > MAX_MESSAGES:
		return {"ok": false, "error": "The Front Porch message timeline is invalid or too large."}
	var metadata: Dictionary = document.get("chat_metadata", {}) if document.get("chat_metadata", {}) is Dictionary else {}
	var result := _normalise_messages(raw_messages)
	return {
		"ok": true,
		"format": format_id,
		"label": "Front Porch .fpchat" if format_id == "fpchat" else "Front Porch chat JSON",
		"character_name": str(metadata.get("character_name", metadata.get("characterName", "Unknown"))),
		"user_name": str(metadata.get("user_name", metadata.get("userName", "Unknown"))),
		"message_count": result.size(),
		"messages": result,
		"opaque_full_state": document.has("fpai")
	}


static func _inspect_jsonl(source_text: String) -> Dictionary:
	var raw_lines := source_text.split("\n", false)
	var messages: Array[Dictionary] = []
	var user_name := "User"
	var character_name := "Character"
	for line_value in raw_lines:
		var line_text := str(line_value).strip_edges()
		if line_text.is_empty():
			continue
		var parsed_line: Variant = JSON.parse_string(line_text)
		if not parsed_line is Dictionary:
			return {"ok": false, "error": "The SillyTavern JSONL contains an invalid JSON line."}
		var row := parsed_line as Dictionary
		if row.has("user_name") or row.has("character_name"):
			user_name = str(row.get("user_name", user_name))
			character_name = str(row.get("character_name", character_name))
			continue
		if not row.has("mes") and not row.has("message"):
			continue
		var is_user := bool(row.get("is_user", row.get("isUser", false)))
		messages.append({
			"sender": str(row.get("name", row.get("send_name", user_name if is_user else character_name))),
			"is_user": is_user,
			"text": str(row.get("mes", row.get("message", ""))),
			"send_date": str(row.get("send_date", ""))
		})
		if messages.size() > MAX_MESSAGES:
			return {"ok": false, "error": "The SillyTavern chat contains too many messages."}
	if messages.is_empty():
		return {"ok": false, "error": "No compatible chat messages were found."}
	return {
		"ok": true,
		"format": "sillytavern_jsonl",
		"label": "SillyTavern JSONL",
		"character_name": character_name,
		"user_name": user_name,
		"message_count": messages.size(),
		"messages": messages,
		"opaque_full_state": false
	}


static func _normalise_messages(raw_messages: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not raw_messages is Array:
		return result
	for message_value in raw_messages:
		if not message_value is Dictionary:
			continue
		var message := message_value as Dictionary
		var is_user := bool(message.get("is_user", message.get("isUser", false)))
		result.append({
			"sender": str(message.get("name", message.get("sender", "User" if is_user else "Character"))),
			"is_user": is_user,
			"text": str(message.get("mes", message.get("text", ""))),
			"send_date": str(message.get("send_date", ""))
		})
	return result


static func _safe_archive_path(entry_path: String) -> bool:
	var normalised := entry_path.replace("\\", "/")
	if normalised.begins_with("/") or normalised.contains(":"):
		return false
	for segment in normalised.split("/"):
		if segment == "..":
			return false
	return true


static func _sha256_bytes(file_bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK:
		return ""
	hashing.update(file_bytes)
	return hashing.finish().hex_encode()


static func _write_index(index: Dictionary) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXCHANGE_DIR))
	var file := FileAccess.open(INDEX_FILE, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not update the managed chat exchange index."}
	file.store_string(JSON.stringify(index, "  "))
	file.close()
	return {"ok": true}
