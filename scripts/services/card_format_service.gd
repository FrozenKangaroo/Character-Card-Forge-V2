class_name CCFCardFormatService
extends RefCounted

const FORMAT_V1 := "chara_card_v1"
const FORMAT_V2 := "chara_card_v2"
const SPEC_VERSION_V2 := "2.0"
const CCF_EXTENSION_KEY := "character_card_forge/v1"
static var PNG_SIGNATURE: PackedByteArray = PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10])
const PNG_CARD_KEY := "chara"

const REQUIRED_V1_FIELDS: Array[String] = [
	"name",
	"description",
	"personality",
	"scenario",
	"first_mes",
	"mes_example"
]

const CANONICAL_FIELD_MAP := {
	"data.name": "character.name",
	"data.description": "character.description",
	"data.personality": "character.personality",
	"data.scenario": "character.scenario",
	"data.first_mes": "character.first_message",
	"data.mes_example": "character.example_dialogue",
	"data.creator_notes": "character.creator_notes",
	"data.system_prompt": "character.system_prompt",
	"data.post_history_instructions": "character.post_history_instructions",
	"data.alternate_greetings": "character.alternate_greetings",
	"data.character_book": "character.character_book",
	"data.tags": "metadata.tags",
	"data.creator": "metadata.creator",
	"data.character_version": "metadata.character_version",
	"data.extensions": "character.card_extensions"
}


static func export_character_v2(project: Dictionary, character_id: String) -> Dictionary:
	var character_record := CCFStorageService.get_character(project, character_id)
	if character_record.is_empty():
		return {}
	var card_data: Dictionary = character_record.get("character", {})
	var metadata: Dictionary = character_record.get("metadata", {})
	var generation: Dictionary = character_record.get("generation", {})
	var project_metadata: Dictionary = project.get("metadata", {})
	var series_id := str(project_metadata.get("series_id", "")).strip_edges()
	var series_name := ""
	if not series_id.is_empty():
		var assigned_series := CCFSeriesService.series_by_id(series_id)
		series_name = str(assigned_series.get("name", ""))
	var extensions := _dictionary_copy(card_data.get("card_extensions", {}))
	var ccf_extension := {
		"format_version": 1,
		"project_id": str(project.get("project_id", "")),
		"character_id": str(character_record.get("character_id", "")),
		"template_id": str(generation.get("template_id", "default")),
		"library_summary": str(metadata.get("summary", "")),
		"group_role": str(metadata.get("role", "")),
		"favorite": bool(metadata.get("favorite", false)),
		"series_id": series_id,
		"series_name": series_name,
		"concept": _dictionary_copy(character_record.get("concept", {})),
		"template_fields": _collect_template_fields(character_record),
		"custom": _collect_ccf_custom_data(character_record)
	}
	extensions[CCF_EXTENSION_KEY] = ccf_extension

	var data := {
		"name": str(card_data.get("name", "")),
		"description": str(card_data.get("description", "")),
		"personality": str(card_data.get("personality", "")),
		"scenario": str(card_data.get("scenario", "")),
		"first_mes": str(card_data.get("first_message", "")),
		"mes_example": str(card_data.get("example_dialogue", "")),
		"creator_notes": str(card_data.get("creator_notes", "")),
		"system_prompt": str(card_data.get("system_prompt", "")),
		"post_history_instructions": str(card_data.get("post_history_instructions", "")),
		"alternate_greetings": _string_array(card_data.get("alternate_greetings", [])),
		"tags": _string_array(metadata.get("tags", [])),
		"creator": str(metadata.get("creator", "")),
		"character_version": str(metadata.get("character_version", "")),
		"extensions": extensions
	}
	var character_book := _dictionary_copy(card_data.get("character_book", {}))
	if not character_book.is_empty():
		data["character_book"] = character_book
	return {
		"spec": FORMAT_V2,
		"spec_version": SPEC_VERSION_V2,
		"data": data
	}


static func export_json(project: Dictionary, character_id: String, destination_path: String) -> Dictionary:
	var card := export_character_v2(project, character_id)
	if card.is_empty():
		return {"ok": false, "error": "The selected character could not be found."}
	var validation := validate_card(card)
	if not validation.get("errors", []).is_empty():
		return {
			"ok": false,
			"error": "The character could not be exported because the mapped card is invalid.",
			"report": validation
		}
	return _write_text_file(destination_path, JSON.stringify(card, "  "))


static func export_characters_json(
	project: Dictionary, character_ids: Array[String], destination_directory: String
) -> Dictionary:
	if character_ids.is_empty():
		return {"ok": false, "error": "No characters were selected for batch export."}
	DirAccess.make_dir_recursive_absolute(destination_directory)
	var exported: Array[String] = []
	var failures: Array[String] = []
	var used_names: Dictionary = {}
	for character_id in character_ids:
		var character := CCFStorageService.get_character(project, character_id)
		if character.is_empty():
			failures.append("Unknown character ID: %s" % character_id)
			continue
		var base_name := _safe_filename(CCFStorageService.character_display_name(character))
		var unique_name := base_name
		var suffix := 2
		while used_names.has(unique_name.to_lower()):
			unique_name = "%s %d" % [base_name, suffix]
			suffix += 1
		used_names[unique_name.to_lower()] = true
		var output_path := destination_directory.path_join(unique_name + ".json")
		var result := export_json(project, character_id, output_path)
		if result.get("ok", false):
			exported.append(output_path)
		else:
			failures.append("%s: %s" % [base_name, str(result.get("error", "Export failed."))])
	return {
		"ok": not exported.is_empty(),
		"exported": exported,
		"failures": failures,
		"count": exported.size()
	}


static func load_card_file(source_path: String) -> Dictionary:
	var extension := source_path.get_extension().to_lower()
	if extension == "json":
		var loaded := _read_json_file(source_path)
		if not loaded.get("ok", false):
			return loaded
		return _prepare_loaded_card(loaded.get("data", {}), "json", source_path)
	if extension == "png" or extension == "apng":
		var png_result := read_png_card(source_path)
		if not png_result.get("ok", false):
			return png_result
		return _prepare_loaded_card(
			png_result.get("data", {}),
			"png",
			source_path,
			str(png_result.get("metadata_key", PNG_CARD_KEY))
		)
	return {"ok": false, "error": "Unsupported card file type. Choose a .json, .png, or .apng file."}


static func import_card_to_project(card: Dictionary, source_format: String = "json") -> Dictionary:
	var detected := detect_card_format(card)
	if detected == "unknown":
		return {"ok": false, "error": "The selected file is not a recognised Character Card V1 or V2 object."}
	var normalised := normalise_to_v2(card)
	if normalised.is_empty():
		return {"ok": false, "error": "The character card could not be normalised."}
	var validation := validate_card(normalised)
	if not validation.get("errors", []).is_empty():
		return {
			"ok": false,
			"error": "The character card contains invalid required fields.",
			"report": validation
		}

	var data: Dictionary = normalised.get("data", {})
	var project := CCFStorageService.new_project()
	var characters: Array = project.get("characters", [])
	var character_record: Dictionary = characters[0]
	var card_data: Dictionary = character_record.get("character", {}).duplicate(true)
	var metadata: Dictionary = character_record.get("metadata", {}).duplicate(true)
	card_data["name"] = str(data.get("name", "Untitled Character"))
	card_data["description"] = str(data.get("description", ""))
	card_data["personality"] = str(data.get("personality", ""))
	card_data["scenario"] = str(data.get("scenario", ""))
	card_data["first_message"] = str(data.get("first_mes", ""))
	card_data["example_dialogue"] = str(data.get("mes_example", ""))
	card_data["creator_notes"] = str(data.get("creator_notes", ""))
	card_data["system_prompt"] = str(data.get("system_prompt", ""))
	card_data["post_history_instructions"] = str(data.get("post_history_instructions", ""))
	card_data["alternate_greetings"] = _string_array(data.get("alternate_greetings", []))
	card_data["character_book"] = _dictionary_copy(data.get("character_book", {}))
	card_data["card_extensions"] = _dictionary_copy(data.get("extensions", {}))
	metadata["name"] = str(data.get("name", "Untitled Character"))
	metadata["tags"] = _string_array(data.get("tags", []))
	metadata["creator"] = str(data.get("creator", ""))
	metadata["character_version"] = str(data.get("character_version", ""))
	character_record["character"] = card_data
	character_record["metadata"] = metadata
	character_record["interoperability"] = {
		"source_format": source_format,
		"source_spec": str(normalised.get("spec", FORMAT_V2)),
		"source_spec_version": str(normalised.get("spec_version", SPEC_VERSION_V2)),
		"imported_at": Time.get_datetime_string_from_system(true)
	}
	_restore_ccf_extension(character_record, data.get("extensions", {}))
	characters[0] = character_record
	project["characters"] = characters
	var project_metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	project_metadata["name"] = str(card_data.get("name", "Untitled Character"))
	project_metadata["summary"] = str(metadata.get("summary", ""))
	project_metadata["tags"] = _string_array(metadata.get("tags", []))
	var extensions_value: Variant = data.get("extensions", {})
	if extensions_value is Dictionary:
		var ccf_value: Variant = extensions_value.get(CCF_EXTENSION_KEY, {})
		if ccf_value is Dictionary:
			project_metadata["series_id"] = str(ccf_value.get("series_id", "")).strip_edges()
	project["metadata"] = project_metadata
	return {"ok": true, "project": project, "report": validation, "detected_format": detected}


static func normalise_to_v2(card: Dictionary) -> Dictionary:
	var detected := detect_card_format(card)
	if detected == FORMAT_V2:
		var source_data = card.get("data", {})
		if not source_data is Dictionary:
			return {}
		var data: Dictionary = source_data.duplicate(true)
		for field_name in REQUIRED_V1_FIELDS:
			data[field_name] = str(data.get(field_name, ""))
		for field_name in ["creator_notes", "system_prompt", "post_history_instructions", "creator", "character_version"]:
			data[field_name] = str(data.get(field_name, ""))
		data["alternate_greetings"] = _string_array(data.get("alternate_greetings", []))
		data["tags"] = _string_array(data.get("tags", []))
		data["extensions"] = _dictionary_copy(data.get("extensions", {}))
		if data.has("character_book") and not data.get("character_book") is Dictionary:
			data.erase("character_book")
		return {"spec": FORMAT_V2, "spec_version": SPEC_VERSION_V2, "data": data}
	if detected == FORMAT_V1:
		var data := {}
		for field_name in REQUIRED_V1_FIELDS:
			data[field_name] = str(card.get(field_name, ""))
		data["creator_notes"] = ""
		data["system_prompt"] = ""
		data["post_history_instructions"] = ""
		data["alternate_greetings"] = []
		data["tags"] = []
		data["creator"] = ""
		data["character_version"] = ""
		data["extensions"] = {}
		return {"spec": FORMAT_V2, "spec_version": SPEC_VERSION_V2, "data": data}
	return {}


static func detect_card_format(card: Variant) -> String:
	if not card is Dictionary:
		return "unknown"
	var card_dict: Dictionary = card
	if str(card_dict.get("spec", "")) == FORMAT_V2 and card_dict.get("data", null) is Dictionary:
		return FORMAT_V2
	var has_v1_fields := true
	for field_name in REQUIRED_V1_FIELDS:
		if not card_dict.has(field_name):
			has_v1_fields = false
			break
	if has_v1_fields:
		return FORMAT_V1
	return "unknown"


static func validate_card(card: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var notes: Array[String] = []
	var detected := detect_card_format(card)
	if detected == "unknown":
		errors.append("The JSON object is not a recognised Character Card V1 or V2 card.")
		return {"errors": errors, "warnings": warnings, "notes": notes, "format": detected}
	if detected == FORMAT_V1:
		warnings.append("This is a legacy V1 card. Import will upgrade it to the V2-compatible internal mapping.")
		for field_name in REQUIRED_V1_FIELDS:
			if not card.get(field_name, null) is String:
				warnings.append("V1 field '%s' is not a string and will be converted to text." % field_name)
		return {"errors": errors, "warnings": warnings, "notes": notes, "format": detected}

	if str(card.get("spec_version", "")) != SPEC_VERSION_V2:
		warnings.append("The card declares spec_version '%s'; CCF exports Character Card V2 as 2.0." % str(card.get("spec_version", "")))
	var data = card.get("data", {})
	if not data is Dictionary:
		errors.append("V2 field 'data' must be an object.")
		return {"errors": errors, "warnings": warnings, "notes": notes, "format": detected}
	var data_dict: Dictionary = data
	for field_name in REQUIRED_V1_FIELDS:
		if not data_dict.has(field_name):
			errors.append("Required V2 field data.%s is missing." % field_name)
		elif not data_dict.get(field_name) is String:
			warnings.append("data.%s is not a string and will be converted to text on import." % field_name)
	for field_name in ["creator_notes", "system_prompt", "post_history_instructions", "creator", "character_version"]:
		if not data_dict.has(field_name):
			warnings.append("Required V2 field data.%s is missing; import will supply an empty string." % field_name)
		elif not data_dict.get(field_name) is String:
			warnings.append("data.%s is not a string and will be converted to text on import." % field_name)
	if not data_dict.has("alternate_greetings"):
		warnings.append("Required V2 field data.alternate_greetings is missing; import will supply an empty list.")
	elif not data_dict.get("alternate_greetings") is Array:
		warnings.append("data.alternate_greetings is not an array and will be normalised to an empty list.")
	if not data_dict.has("tags"):
		warnings.append("Required V2 field data.tags is missing; import will supply an empty list.")
	elif not data_dict.get("tags") is Array:
		warnings.append("data.tags is not an array and will be normalised to an empty list.")
	if not data_dict.has("extensions"):
		warnings.append("Required V2 field data.extensions is missing; import will supply an empty object.")
	elif not data_dict.get("extensions") is Dictionary:
		warnings.append("data.extensions is not an object and will be normalised to an empty object.")
	if data_dict.has("character_book") and not data_dict.get("character_book") is Dictionary:
		warnings.append("data.character_book is not an object and cannot be preserved as a lorebook.")
	if data_dict.get("extensions", {}) is Dictionary and not data_dict.get("extensions", {}).is_empty():
		notes.append("Unknown Character Card extension data will be preserved for round-trip export.")
	if data_dict.get("character_book", {}) is Dictionary and not data_dict.get("character_book", {}).is_empty():
		notes.append("The embedded character lorebook will be preserved even though dedicated lorebook editing is not implemented yet.")
	return {"errors": errors, "warnings": warnings, "notes": notes, "format": detected}


static func compatibility_report(project: Dictionary, character_id: String) -> Dictionary:
	var card := export_character_v2(project, character_id)
	var validation := validate_card(card)
	var rows: Array[Dictionary] = []
	for target_path in CANONICAL_FIELD_MAP:
		var internal_path := str(CANONICAL_FIELD_MAP[target_path])
		var value = _mapped_internal_value(project, character_id, internal_path)
		var status := "Mapped"
		var note := "Direct Character Card V2 mapping."
		if target_path in ["data.alternate_greetings", "data.character_book", "data.extensions"]:
			status = "Preserved"
			note = "Stored in the clean project model and round-tripped without requiring a dedicated editor yet."
		rows.append(
			{
				"target": target_path,
				"source": internal_path,
				"status": status,
				"value_summary": _value_summary(value),
				"note": note
			}
		)
	var character_record := CCFStorageService.get_character(project, character_id)
	var generation: Dictionary = character_record.get("generation", {})
	var template_fields := _collect_template_fields(character_record)
	for field_path in template_fields:
		rows.append(
			{
				"target": "data.extensions[%s].template_fields" % CCF_EXTENSION_KEY,
				"source": str(field_path),
				"status": "Namespaced",
				"value_summary": _value_summary(template_fields.get(field_path)),
				"note": "This template-specific field has no direct Character Card V2 equivalent, so CCF preserves it in its namespaced extension data."
			}
		)
	rows.append(
		{
			"target": "data.extensions[%s]" % CCF_EXTENSION_KEY,
			"source": "CCF project metadata/custom data",
			"status": "Namespaced",
			"value_summary": "Template %s" % str(generation.get("template_id", "default")),
			"note": "CCF-specific round-trip information is exported in a namespaced extensions entry."
		}
	)
	return {
		"card": card,
		"validation": validation,
		"rows": rows,
		"target": "Character Card V2 / SillyTavern-compatible JSON"
	}


static func read_png_card(source_path: String) -> Dictionary:
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open the PNG file."}
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if not _has_png_signature(bytes):
		return {"ok": false, "error": "The selected file is not a valid PNG/APNG file."}
	var offset := 8
	while offset + 12 <= bytes.size():
		var length := _read_u32_be(bytes, offset)
		if length < 0 or offset + 12 + length > bytes.size():
			return {"ok": false, "error": "The PNG chunk table is malformed."}
		var chunk_type := bytes.slice(offset + 4, offset + 8).get_string_from_ascii()
		var chunk_data := bytes.slice(offset + 8, offset + 8 + length)
		if chunk_type == "tEXt":
			var parsed_text := _parse_text_chunk(chunk_data)
			var keyword := str(parsed_text.get("keyword", ""))
			if keyword.to_lower() == PNG_CARD_KEY:
				var encoded := str(parsed_text.get("text", ""))
				var json_text := Marshalls.base64_to_utf8(encoded)
				var parsed = JSON.parse_string(json_text)
				if parsed is Dictionary:
					return {"ok": true, "data": parsed, "metadata_key": keyword}
				return {"ok": false, "error": "The PNG contains a 'chara' metadata chunk, but its decoded JSON is invalid."}
		if chunk_type == "IEND":
			break
		offset += 12 + length
	return {"ok": false, "error": "No Character Card 'chara' metadata chunk was found in this PNG."}


static func write_png_card(
	source_png_path: String,
	destination_path: String,
	project: Dictionary,
	character_id: String
) -> Dictionary:
	var card := export_character_v2(project, character_id)
	if card.is_empty():
		return {"ok": false, "error": "The selected character could not be found."}
	var source := FileAccess.open(source_png_path, FileAccess.READ)
	if source == null:
		return {"ok": false, "error": "Could not open the source PNG image."}
	var bytes := source.get_buffer(source.get_length())
	source.close()
	if not _has_png_signature(bytes):
		return {"ok": false, "error": "The source image is not a valid PNG/APNG file."}
	var output := PackedByteArray()
	output.append_array(PNG_SIGNATURE)
	var offset := 8
	var inserted := false
	while offset + 12 <= bytes.size():
		var length := _read_u32_be(bytes, offset)
		if length < 0 or offset + 12 + length > bytes.size():
			return {"ok": false, "error": "The source PNG chunk table is malformed."}
		var chunk_type_bytes := bytes.slice(offset + 4, offset + 8)
		var chunk_type := chunk_type_bytes.get_string_from_ascii()
		var chunk_data := bytes.slice(offset + 8, offset + 8 + length)
		var skip_chunk := false
		if chunk_type == "tEXt":
			var parsed_text := _parse_text_chunk(chunk_data)
			skip_chunk = str(parsed_text.get("keyword", "")).to_lower() == PNG_CARD_KEY
		if chunk_type == "IEND" and not inserted:
			output.append_array(_make_png_text_chunk(PNG_CARD_KEY, Marshalls.utf8_to_base64(JSON.stringify(card))))
			inserted = true
		if not skip_chunk:
			output.append_array(bytes.slice(offset, offset + 12 + length))
		if chunk_type == "IEND":
			break
		offset += 12 + length
	if not inserted:
		return {"ok": false, "error": "The source PNG does not contain a valid IEND chunk."}
	var destination := FileAccess.open(destination_path, FileAccess.WRITE)
	if destination == null:
		return {"ok": false, "error": "Could not open the destination PNG for writing."}
	destination.store_buffer(output)
	destination.close()
	return {"ok": true, "path": destination_path}


static func suggested_filename(project: Dictionary, character_id: String, extension: String = "json") -> String:
	var character := CCFStorageService.get_character(project, character_id)
	var clean_name := _safe_filename(CCFStorageService.character_display_name(character))
	return "%s.%s" % [clean_name, extension.trim_prefix(".")]


static func _prepare_loaded_card(
	raw_card: Variant,
	source_format: String,
	source_path: String,
	metadata_key: String = ""
) -> Dictionary:
	if not raw_card is Dictionary:
		return {"ok": false, "error": "The card data is not a JSON object."}
	var card: Dictionary = raw_card
	var validation := validate_card(card)
	if not validation.get("errors", []).is_empty():
		return {
			"ok": false,
			"error": "The selected file is not a valid supported character card.",
			"report": validation
		}
	return {
		"ok": true,
		"data": card,
		"source_format": source_format,
		"source_path": source_path,
		"metadata_key": metadata_key,
		"report": validation,
		"detected_format": detect_card_format(card)
	}


static func _restore_ccf_extension(character_record: Dictionary, raw_extensions: Variant) -> void:
	if not raw_extensions is Dictionary:
		return
	var extensions: Dictionary = raw_extensions
	var raw_ccf = extensions.get(CCF_EXTENSION_KEY, {})
	if not raw_ccf is Dictionary:
		return
	var ccf: Dictionary = raw_ccf
	var metadata: Dictionary = character_record.get("metadata", {}).duplicate(true)
	metadata["summary"] = str(ccf.get("library_summary", metadata.get("summary", "")))
	metadata["role"] = str(ccf.get("group_role", metadata.get("role", "")))
	metadata["favorite"] = bool(ccf.get("favorite", metadata.get("favorite", false)))
	character_record["metadata"] = metadata
	var concept = ccf.get("concept", {})
	if concept is Dictionary:
		var merged_concept: Dictionary = character_record.get("concept", {}).duplicate(true)
		merged_concept.merge(concept, true)
		character_record["concept"] = merged_concept
	var generation: Dictionary = character_record.get("generation", {}).duplicate(true)
	generation["template_id"] = str(ccf.get("template_id", generation.get("template_id", "default")))
	character_record["generation"] = generation
	var template_fields = ccf.get("template_fields", {})
	if template_fields is Dictionary:
		for field_path in template_fields:
			CCFStorageService.set_value_at_path(
				character_record, str(field_path), _duplicate_variant(template_fields.get(field_path))
			)
	var custom = ccf.get("custom", {})
	if custom is Dictionary:
		var top_level = custom.get("top_level", {})
		if top_level is Dictionary:
			for key in top_level:
				if not character_record.has(key):
					character_record[key] = _duplicate_variant(top_level.get(key))
		var character_custom = custom.get("character_custom", {})
		if character_custom is Dictionary:
			var character_data: Dictionary = character_record.get("character", {}).duplicate(true)
			var existing_custom := _dictionary_copy(character_data.get("custom", {}))
			existing_custom.merge(character_custom, true)
			character_data["custom"] = existing_custom
			character_record["character"] = character_data
		# Compatibility with early v0.7 development cards that stored extra top-level keys flat.
		if not custom.has("top_level"):
			for key in custom:
				if str(key) == "character_custom":
					continue
				if not character_record.has(key):
					character_record[key] = _duplicate_variant(custom.get(key))


static func _collect_template_fields(character_record: Dictionary) -> Dictionary:
	var result := {}
	var generation = character_record.get("generation", {})
	var template_id := "default"
	if generation is Dictionary:
		template_id = str(generation.get("template_id", "default"))
	var template := CCFTemplateService.load_template(template_id)
	var canonical_paths: Dictionary = {}
	for internal_path in CANONICAL_FIELD_MAP.values():
		canonical_paths[str(internal_path)] = true
	for section in template.get("sections", []):
		if not section is Dictionary:
			continue
		for field in section.get("fields", []):
			if not field is Dictionary:
				continue
			var field_path := str(field.get("path", "")).strip_edges()
			if field_path.is_empty() or canonical_paths.has(field_path):
				continue
			var value = CCFStorageService.get_value_at_path(character_record, field_path, null)
			if value != null:
				result[field_path] = _duplicate_variant(value)
	return result


static func _collect_ccf_custom_data(character_record: Dictionary) -> Dictionary:
	var top_level := {}
	for key in character_record:
		if key in [
			"character_id",
			"created_at",
			"updated_at",
			"metadata",
			"concept",
			"character",
			"generation",
			"assets",
			"workspace",
			"interoperability"
		]:
			continue
		top_level[str(key)] = _duplicate_variant(character_record.get(key))
	var result := {"top_level": top_level}
	var character_data = character_record.get("character", {})
	if character_data is Dictionary and character_data.get("custom", null) is Dictionary:
		result["character_custom"] = _duplicate_variant(character_data.get("custom"))
	return result


static func _mapped_internal_value(project: Dictionary, character_id: String, internal_path: String) -> Variant:
	var character := CCFStorageService.get_character(project, character_id)
	return CCFStorageService.get_value_at_path(character, internal_path, "")


static func _value_summary(value: Variant) -> String:
	if value is Array:
		var item_suffix := ""
		if value.size() != 1:
			item_suffix = "s"
		return "%d item%s" % [value.size(), item_suffix]
	if value is Dictionary:
		var key_suffix := ""
		if value.size() != 1:
			key_suffix = "s"
		return "%d key%s" % [value.size(), key_suffix]
	var text := str(value).strip_edges()
	if text.is_empty():
		return "Empty"
	if text.length() > 80:
		return text.substr(0, 77) + "…"
	return text


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


static func _dictionary_copy(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


static func _duplicate_variant(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


static func _safe_filename(value: String) -> String:
	var clean := value.strip_edges()
	if clean.is_empty():
		clean = "Untitled Character"
	for forbidden in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		clean = clean.replace(forbidden, "_")
	return clean


static func _read_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open %s." % path}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		return {"ok": false, "error": "The selected JSON file could not be parsed."}
	return {"ok": true, "data": parsed}


static func _write_text_file(path: String, text: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open %s for writing." % path}
	file.store_string(text)
	file.close()
	return {"ok": true, "path": path}


static func _has_png_signature(bytes: PackedByteArray) -> bool:
	if bytes.size() < PNG_SIGNATURE.size():
		return false
	for index in range(PNG_SIGNATURE.size()):
		if bytes[index] != PNG_SIGNATURE[index]:
			return false
	return true


static func _read_u32_be(bytes: PackedByteArray, offset: int) -> int:
	if offset < 0 or offset + 4 > bytes.size():
		return -1
	return (
		(int(bytes[offset]) << 24)
		| (int(bytes[offset + 1]) << 16)
		| (int(bytes[offset + 2]) << 8)
		| int(bytes[offset + 3])
	)


static func _append_u32_be(target: PackedByteArray, value: int) -> void:
	target.append((value >> 24) & 0xff)
	target.append((value >> 16) & 0xff)
	target.append((value >> 8) & 0xff)
	target.append(value & 0xff)


static func _parse_text_chunk(data: PackedByteArray) -> Dictionary:
	var separator := -1
	for index in range(data.size()):
		if data[index] == 0:
			separator = index
			break
	if separator < 0:
		return {"keyword": "", "text": ""}
	return {
		"keyword": data.slice(0, separator).get_string_from_ascii(),
		"text": data.slice(separator + 1, data.size()).get_string_from_ascii()
	}


static func _make_png_text_chunk(keyword: String, text: String) -> PackedByteArray:
	var chunk_type := "tEXt".to_ascii_buffer()
	var chunk_data := PackedByteArray()
	chunk_data.append_array(keyword.to_ascii_buffer())
	chunk_data.append(0)
	chunk_data.append_array(text.to_ascii_buffer())
	var crc_input := PackedByteArray()
	crc_input.append_array(chunk_type)
	crc_input.append_array(chunk_data)
	var output := PackedByteArray()
	_append_u32_be(output, chunk_data.size())
	output.append_array(chunk_type)
	output.append_array(chunk_data)
	_append_u32_be(output, _crc32(crc_input))
	return output


static func _crc32(bytes: PackedByteArray) -> int:
	var crc: int = 0xffffffff
	for byte_value in bytes:
		crc ^= int(byte_value)
		for _bit_index in range(8):
			if (crc & 1) != 0:
				crc = (crc >> 1) ^ 0xedb88320
			else:
				crc >>= 1
	return (crc ^ 0xffffffff) & 0xffffffff
