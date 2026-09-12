class_name CCFIntegrationAdapterServiceV0191
extends RefCounted

const PROFILE_CATALOG_PATH := "res://data/export_profiles_v0191.json"
const PROFILE_FORMAT_VERSION := 1
const DEFAULT_PROFILE_ID := "character_card_v2_full"
const FRONT_PORCH_PROFILE_ID := "front_porch"
const SILLYTAVERN_PROFILE_ID := "sillytavern_clean"
const CCF_EXTENSION_PATH := "data.extensions.character_card_forge/v1"

const STANDARD_DATA_PATHS: Array[String] = [
	"data.name",
	"data.description",
	"data.personality",
	"data.scenario",
	"data.first_mes",
	"data.mes_example",
	"data.creator_notes",
	"data.system_prompt",
	"data.post_history_instructions",
	"data.alternate_greetings",
	"data.tags",
	"data.creator",
	"data.character_version",
	"data.tts_voice",
	"data.character_book",
	"data.extensions"
]


static func capabilities() -> Dictionary:
	return {
		"contract_version": 1,
		"versioned_profiles": true,
		"detection": true,
		"import": true,
		"export": true,
		"validation": true,
		"capability_reporting": true,
		"install_payloads": true,
		"update_payloads": true,
		"before_export_preview": true,
		"include_rules": true,
		"omit_rules": true,
		"rename_rules": true,
		"transform_rules": true,
		"unknown_extension_preservation": true,
		"visible_loss_reports": true,
		"third_party_executable_plugins": false,
		"raw_database_writes": false,
		"automatic_network_calls": false
	}


static func adapter_descriptors() -> Array[Dictionary]:
	return [
		{
			"id": "character_card_v2",
			"name": "Character Card V2",
			"detect": true,
			"import": true,
			"export": true,
			"validate": true,
			"formats": ["json", "png"],
			"install": false,
			"update": false
		},
		{
			"id": "front_porch",
			"name": "Front Porch",
			"detect": true,
			"import": true,
			"export": true,
			"validate": true,
			"formats": ["json", "png"],
			"install": true,
			"update": true
		},
		{
			"id": "sillytavern",
			"name": "SillyTavern",
			"detect": true,
			"import": true,
			"export": true,
			"validate": true,
			"formats": ["json", "png"],
			"install": false,
			"update": false
		}
	]


static func profiles() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var file := FileAccess.open(PROFILE_CATALOG_PATH, FileAccess.READ)
	if file == null:
		return result
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return result
	var catalog := parsed as Dictionary
	if int(catalog.get("format_version", 0)) != PROFILE_FORMAT_VERSION:
		return result
	var profile_values: Variant = catalog.get("profiles", [])
	if not profile_values is Array:
		return result
	for profile_value in profile_values:
		if not profile_value is Dictionary:
			continue
		var profile := (profile_value as Dictionary).duplicate(true)
		var validation := validate_profile(profile)
		if bool(validation.get("ok", false)):
			result.append(profile)
	return result


static func profile_by_id(profile_id: String) -> Dictionary:
	for profile in profiles():
		if str(profile.get("id", "")) == profile_id:
			return profile
	return {}


static func validate_profile(profile: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	for required_key in ["id", "name", "adapter_id", "output_extensions", "rules"]:
		if not profile.has(required_key):
			errors.append("Profile is missing '%s'." % required_key)
	if str(profile.get("id", "")).strip_edges().is_empty():
		errors.append("Profile ID cannot be empty.")
	var adapter_id := str(profile.get("adapter_id", ""))
	var known_adapter := false
	for descriptor in adapter_descriptors():
		if str(descriptor.get("id", "")) == adapter_id:
			known_adapter = true
			break
	if not known_adapter:
		errors.append("Profile references an unknown adapter: %s" % adapter_id)
	var outputs: Variant = profile.get("output_extensions", [])
	if not outputs is Array or (outputs as Array).is_empty():
		errors.append("Profile must support at least one output extension.")
	else:
		for output_value in outputs:
			if str(output_value) not in ["json", "png"]:
				errors.append("Unsupported output extension: %s" % str(output_value))
	var rules_value: Variant = profile.get("rules", {})
	if not rules_value is Dictionary:
		errors.append("Profile rules must be an object.")
	else:
		var rules := rules_value as Dictionary
		if not rules.get("include_paths", []) is Array:
			errors.append("include_paths must be an array.")
		if not rules.get("omit_paths", []) is Array:
			errors.append("omit_paths must be an array.")
		if not rules.get("rename_paths", {}) is Dictionary:
			errors.append("rename_paths must be an object.")
		if not rules.get("transformations", []) is Array:
			errors.append("transformations must be an array.")
		else:
			for transform_value in rules.get("transformations", []):
				if str(transform_value) not in ["remove_empty_optional_fields"]:
					errors.append("Unknown transformation: %s" % str(transform_value))
	return {"ok": errors.is_empty(), "errors": errors}


static func detect_document(document: Variant, source_hint := "") -> Dictionary:
	if not document is Dictionary:
		return {"ok": false, "adapter_id": "", "format": "unknown"}
	var detected_format := CCFCardFormatService.detect_card_format(document)
	if detected_format == "unknown":
		return {"ok": false, "adapter_id": "", "format": detected_format}
	var adapter_id := "character_card_v2"
	var normalised := CCFCardFormatService.normalise_to_v2(document)
	var extensions_value: Variant = normalised.get("data", {}).get("extensions", {})
	if extensions_value is Dictionary and (extensions_value as Dictionary).has("front_porch"):
		adapter_id = "front_porch"
	elif source_hint.to_lower().contains("sillytavern"):
		adapter_id = "sillytavern"
	return {"ok": true, "adapter_id": adapter_id, "format": detected_format}


static func import_document(
	document: Dictionary, source_hint := "json"
) -> Dictionary:
	var detected := detect_document(document, source_hint)
	if not bool(detected.get("ok", false)):
		return {"ok": false, "error": "The document is not a supported character card."}
	var imported := CCFCardFormatService.import_card_to_project(document, source_hint)
	imported["adapter_id"] = str(detected.get("adapter_id", ""))
	return imported


static func preview_export(
	project: Dictionary, character_id: String, profile_id: String
) -> Dictionary:
	var profile := profile_by_id(profile_id)
	if profile.is_empty():
		return {"ok": false, "error": "The selected export profile is unavailable."}
	return preview_with_profile(project, character_id, profile)


static func preview_with_profile(
	project: Dictionary, character_id: String, profile: Dictionary
) -> Dictionary:
	var profile_validation := validate_profile(profile)
	if not bool(profile_validation.get("ok", false)):
		return {
			"ok": false,
			"error": "; ".join(profile_validation.get("errors", [])),
			"profile": profile
		}
	var source_document := CCFCardFormatService.export_character_v2(
		project, character_id
	)
	if source_document.is_empty():
		return {"ok": false, "error": "The selected character could not be found."}
	var document := source_document.duplicate(true)
	var rule_rows: Array[Dictionary] = []
	_apply_profile_rules(document, profile, rule_rows)
	var report := _preservation_report(
		project, character_id, source_document, document, profile, rule_rows
	)
	var validation := CCFCardFormatService.validate_card(document)
	var safety := CCFCardFormatService.export_safety_report(project, character_id)
	var errors: Array = validation.get("errors", []).duplicate()
	for safety_error in safety.get("errors", []):
		errors.append(str(safety_error))
	validation["errors"] = errors
	var warnings: Array = validation.get("warnings", []).duplicate()
	for safety_warning in safety.get("warnings", []):
		warnings.append(str(safety_warning))
	validation["warnings"] = warnings
	return {
		"ok": errors.is_empty(),
		"profile": profile.duplicate(true),
		"adapter_id": str(profile.get("adapter_id", "")),
		"document": document,
		"json": JSON.stringify(document, "  "),
		"validation": validation,
		"safety": safety,
		"report": report
	}


static func export_json(
	project: Dictionary,
	character_id: String,
	profile_id: String,
	destination_path: String
) -> Dictionary:
	var preview := preview_export(project, character_id, profile_id)
	if not bool(preview.get("ok", false)):
		return {
			"ok": false,
			"error": _preview_error(preview),
			"preview": preview
		}
	var file := FileAccess.open(destination_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open the destination file for writing."}
	file.store_string(str(preview.get("json", "")))
	file.close()
	return {
		"ok": true,
		"path": destination_path,
		"profile_id": profile_id,
		"report": preview.get("report", {})
	}


static func export_characters_json(
	project: Dictionary,
	character_ids: Array[String],
	profile_id: String,
	destination_directory: String
) -> Dictionary:
	if character_ids.is_empty():
		return {"ok": false, "error": "No characters were selected for batch export."}
	DirAccess.make_dir_recursive_absolute(destination_directory)
	var exported: Array[String] = []
	var failures: Array[String] = []
	var used_filenames: Dictionary = {}
	for character_id in character_ids:
		var character := CCFStorageService.get_character(project, character_id)
		if character.is_empty():
			failures.append("Unknown character ID: %s" % character_id)
			continue
		var suggested := CCFCardFormatService.suggested_filename(
			project, character_id, "json"
		)
		var base_filename := suggested.get_basename()
		var unique_filename := base_filename
		var suffix := 2
		while used_filenames.has(unique_filename.to_lower()):
			unique_filename = "%s %d" % [base_filename, suffix]
			suffix += 1
		used_filenames[unique_filename.to_lower()] = true
		var output_path := destination_directory.path_join(unique_filename + ".json")
		var export_result := export_json(
			project, character_id, profile_id, output_path
		)
		if bool(export_result.get("ok", false)):
			exported.append(output_path)
		else:
			failures.append("%s: %s" % [
				CCFStorageService.character_display_name(character),
				str(export_result.get("error", "Export failed."))
			])
	return {
		"ok": not exported.is_empty(),
		"exported": exported,
		"failures": failures,
		"count": exported.size(),
		"profile_id": profile_id
	}


static func write_png(
	source_image_path: String,
	destination_path: String,
	project: Dictionary,
	character_id: String,
	profile_id: String
) -> Dictionary:
	var preview := preview_export(project, character_id, profile_id)
	if not bool(preview.get("ok", false)):
		return {
			"ok": false,
			"error": _preview_error(preview),
			"preview": preview
		}
	var profile: Dictionary = preview.get("profile", {})
	if "png" not in profile.get("output_extensions", []):
		return {"ok": false, "error": "The selected export profile does not support PNG."}
	var result := CCFCardFormatService.write_png_card_from_document(
		source_image_path,
		destination_path,
		preview.get("document", {})
	)
	result["profile_id"] = profile_id
	result["report"] = preview.get("report", {})
	return result


static func prepare_install_payload(
	project: Dictionary,
	character_id: String,
	profile_id: String,
	artwork_path := ""
) -> Dictionary:
	var preview := preview_export(project, character_id, profile_id)
	if not bool(preview.get("ok", false)):
		return {"ok": false, "error": _preview_error(preview), "preview": preview}
	var profile: Dictionary = preview.get("profile", {})
	if not bool(profile.get("supports_install", false)):
		return {"ok": false, "error": "The selected profile does not support direct installation."}
	var filename := CCFCardFormatService.suggested_filename(
		project, character_id, "png" if not artwork_path.is_empty() else "json"
	)
	if artwork_path.is_empty():
		return {
			"ok": true,
			"bytes": str(preview.get("json", "")).to_utf8_buffer(),
			"filename": filename,
			"content_type": "application/json; charset=utf-8",
			"label": "Front Porch Character Card JSON",
			"preview": preview
		}
	var built := CCFCardFormatService.build_png_card_bytes_from_document(
		artwork_path, preview.get("document", {})
	)
	if not bool(built.get("ok", false)):
		return built
	return {
		"ok": true,
		"bytes": built.get("bytes", PackedByteArray()),
		"filename": filename,
		"content_type": "image/png",
		"label": "Front Porch Character Card PNG with portrait",
		"preview": preview
	}


static func report_text(report: Dictionary) -> String:
	var summary_value: Variant = report.get("summary", {})
	var summary: Dictionary = summary_value if summary_value is Dictionary else {}
	var lines := PackedStringArray([
		"Export Preservation Report",
		"Profile: %s" % str(report.get("profile_name", "Unknown")),
		"Adapter: %s" % str(report.get("adapter_id", "unknown")),
		"Mapped: %d • Preserved: %d • Transformed: %d • Omitted: %d" % [
			int(summary.get("mapped", 0)),
			int(summary.get("preserved", 0)),
			int(summary.get("transformed", 0)),
			int(summary.get("omitted", 0))
		],
		""
	])
	for row_value in report.get("rows", []):
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		lines.append("[%s] %s — %s" % [
			str(row.get("disposition", "mapped")).to_upper(),
			str(row.get("path", "field")),
			str(row.get("detail", ""))
		])
	return "\n".join(lines)


static func profile_rules_text(profile: Dictionary) -> String:
	var rules_value: Variant = profile.get("rules", {})
	var rules: Dictionary = rules_value if rules_value is Dictionary else {}
	var includes := _string_values(rules.get("include_paths", []))
	var omits := _string_values(rules.get("omit_paths", []))
	var transforms := _string_values(rules.get("transformations", []))
	var renames_value: Variant = rules.get("rename_paths", {})
	var rename_count := (renames_value as Dictionary).size() if renames_value is Dictionary else 0
	return "Include: %s\nOmit: %s\nRename rules: %d\nTransforms: %s" % [
		", ".join(includes) if not includes.is_empty() else "none",
		", ".join(omits) if not omits.is_empty() else "none",
		rename_count,
		", ".join(transforms) if not transforms.is_empty() else "none"
	]


static func _apply_profile_rules(
	document: Dictionary,
	profile: Dictionary,
	rows: Array[Dictionary]
) -> void:
	var rules_value: Variant = profile.get("rules", {})
	var rules: Dictionary = rules_value if rules_value is Dictionary else {}
	var include_paths := _string_values(rules.get("include_paths", []))
	if not include_paths.is_empty() and "*" not in include_paths:
		var included: Dictionary = {}
		for path in include_paths:
			var found := _path_value(document, path)
			if bool(found.get("exists", false)):
				_set_path(included, path, found.get("value"))
		document.clear()
		document.merge(included, true)
	var rename_value: Variant = rules.get("rename_paths", {})
	if rename_value is Dictionary:
		for source_value in (rename_value as Dictionary).keys():
			var source_path := str(source_value)
			var target_path := str((rename_value as Dictionary).get(source_value, ""))
			var found := _path_value(document, source_path)
			if bool(found.get("exists", false)) and not target_path.is_empty():
				_set_path(document, target_path, found.get("value"))
				_erase_path(document, source_path)
				rows.append({
					"path": source_path,
					"disposition": "transformed",
					"detail": "Renamed to %s by the selected profile." % target_path
				})
	for omit_path in _string_values(rules.get("omit_paths", [])):
		if _erase_path(document, omit_path):
			rows.append({
				"path": omit_path,
				"disposition": "omitted",
				"detail": "Explicitly omitted by the selected profile. The CCF project remains unchanged."
			})
	for transformation in _string_values(rules.get("transformations", [])):
		if transformation == "remove_empty_optional_fields":
			for optional_path in ["data.tts_voice", "data.character_book"]:
				var found := _path_value(document, optional_path)
				if bool(found.get("exists", false)) and _value_is_empty(found.get("value")):
					_erase_path(document, optional_path)
					rows.append({
						"path": optional_path,
						"disposition": "transformed",
						"detail": "Empty optional field removed for a cleaner target document."
					})


static func _preservation_report(
	project: Dictionary,
	character_id: String,
	source_document: Dictionary,
	document: Dictionary,
	profile: Dictionary,
	rule_rows: Array[Dictionary]
) -> Dictionary:
	var rows := rule_rows.duplicate(true)
	var covered: Dictionary = {}
	for row in rows:
		covered[str(row.get("path", ""))] = true
	for path in STANDARD_DATA_PATHS:
		if covered.has(path):
			continue
		var source_found := _path_value(source_document, path)
		if not bool(source_found.get("exists", false)):
			continue
		var target_found := _path_value(document, path)
		rows.append({
			"path": path,
			"disposition": "mapped" if bool(target_found.get("exists", false)) else "omitted",
			"detail": (
				"Mapped into the target Character Card document."
				if bool(target_found.get("exists", false))
				else "The target document does not contain this source field."
			)
		})
	var source_extensions_value: Variant = source_document.get("data", {}).get("extensions", {})
	var target_extensions_value: Variant = document.get("data", {}).get("extensions", {})
	var source_extensions: Dictionary = source_extensions_value if source_extensions_value is Dictionary else {}
	var target_extensions: Dictionary = target_extensions_value if target_extensions_value is Dictionary else {}
	for extension_key_value in source_extensions.keys():
		var extension_key := str(extension_key_value)
		var extension_path := "data.extensions.%s" % extension_key
		if covered.has(extension_path) or extension_path == CCF_EXTENSION_PATH:
			continue
		var preserved := target_extensions.has(extension_key_value)
		rows.append({
			"path": extension_path,
			"disposition": "preserved" if preserved else "omitted",
			"detail": (
				"Unknown or target-specific extension data is retained losslessly."
				if preserved
				else "Extension data is excluded by this profile but remains in the CCF project."
			)
		})
	var character := CCFStorageService.get_character(project, character_id)
	for private_key in ["workspace", "revision_history", "generation", "assets", "attachments"]:
		if character.has(private_key) and not _value_is_empty(character.get(private_key)):
			rows.append({
				"path": "character.%s" % private_key,
				"disposition": "preserved",
				"detail": "Kept privately in the CCF project; ordinary card export does not disclose it."
			})
	var summary := {"mapped": 0, "preserved": 0, "transformed": 0, "omitted": 0}
	for row in rows:
		var disposition := str(row.get("disposition", "mapped"))
		if summary.has(disposition):
			summary[disposition] = int(summary.get(disposition, 0)) + 1
	return {
		"format_version": 1,
		"profile_id": str(profile.get("id", "")),
		"profile_name": str(profile.get("name", "")),
		"adapter_id": str(profile.get("adapter_id", "")),
		"summary": summary,
		"rows": rows
	}


static func _preview_error(preview: Dictionary) -> String:
	var explicit_error := str(preview.get("error", "")).strip_edges()
	if not explicit_error.is_empty():
		return explicit_error
	var validation_value: Variant = preview.get("validation", {})
	if validation_value is Dictionary:
		var errors: Array = (validation_value as Dictionary).get("errors", [])
		if not errors.is_empty():
			return "; ".join(errors)
	return "The selected profile could not produce an exportable document."


static func _path_value(document: Dictionary, path: String) -> Dictionary:
	var current: Variant = document
	for part in path.split(".", false):
		if not current is Dictionary or not (current as Dictionary).has(part):
			return {"exists": false}
		current = (current as Dictionary).get(part)
	return {"exists": true, "value": current}


static func _set_path(document: Dictionary, path: String, value: Variant) -> void:
	var parts := path.split(".", false)
	if parts.is_empty():
		return
	var current := document
	for index in range(parts.size() - 1):
		var key := str(parts[index])
		var next_value: Variant = current.get(key, {})
		if not next_value is Dictionary:
			next_value = {}
		current[key] = next_value
		current = current[key]
	current[str(parts[-1])] = (
		value.duplicate(true) if value is Dictionary or value is Array else value
	)


static func _erase_path(document: Dictionary, path: String) -> bool:
	var parts := path.split(".", false)
	if parts.is_empty():
		return false
	var current := document
	for index in range(parts.size() - 1):
		var key := str(parts[index])
		if not current.has(key) or not current.get(key) is Dictionary:
			return false
		current = current[key]
	var leaf := str(parts[-1])
	if not current.has(leaf):
		return false
	current.erase(leaf)
	return true


static func _string_values(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


static func _value_is_empty(value: Variant) -> bool:
	if value == null:
		return true
	if value is String:
		return (value as String).strip_edges().is_empty()
	if value is Array or value is Dictionary:
		return value.is_empty()
	return false
