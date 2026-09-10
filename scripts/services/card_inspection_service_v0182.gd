class_name CCFCardInspectionServiceV0182
extends RefCounted

const VERSION := "0.18.2"
const CHARS_PER_TOKEN := 4.0
const SECTION_WARNING_TOKENS := 2000
const TOTAL_WARNING_TOKENS := 12000
const INSPECTION_KEY := "card_inspection_v0182"
const PRIVATE_KEYS := [
	"revision_history", "revision_lineage", INSPECTION_KEY
]
const CORE_FIELDS := [
	{"path": "character.description", "label": "Description"},
	{"path": "character.personality", "label": "Personality"},
	{"path": "character.scenario", "label": "Scenario"},
	{"path": "character.first_message", "label": "First Message"}
]
const TEXT_SECTIONS := [
	{"path": "character.description", "label": "Description"},
	{"path": "character.personality", "label": "Personality"},
	{"path": "character.scenario", "label": "Scenario"},
	{"path": "character.first_message", "label": "First Message"},
	{"path": "character.example_dialogue", "label": "Example Dialogue"},
	{"path": "character.creator_notes", "label": "Creator Notes"},
	{"path": "character.system_prompt", "label": "System Prompt"},
	{
		"path": "character.post_history_instructions",
		"label": "Post-History Instructions"
	},
	{"path": "concept.prompt", "label": "Generation Concept"},
	{"path": "concept.notes", "label": "Concept Notes"}
]


static func health_report(
	project: Dictionary, character_id: String, options: Dictionary = {}
) -> Dictionary:
	var character_record := CCFStorageService.get_character(project, character_id)
	if character_record.is_empty():
		return {
			"ok": false,
			"findings": [_finding(
				"error", "missing_character", "", "The selected character could not be found."
			)]
		}
	var findings: Array[Dictionary] = []
	var card_value: Variant = character_record.get("character", {})
	var card: Dictionary = card_value if card_value is Dictionary else {}
	var metadata_value: Variant = character_record.get("metadata", {})
	var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
	if not card_value is Dictionary:
		findings.append(_finding(
			"error", "malformed_character", "character", "Character content must be an object."
		))
	if not metadata_value is Dictionary:
		findings.append(_finding(
			"error", "malformed_metadata", "metadata", "Character metadata must be an object."
		))
	var display_name := CCFStorageService.character_display_name(character_record).strip_edges()
	if display_name.is_empty() or display_name.begins_with("Untitled Character"):
		findings.append(_finding(
			"warning", "placeholder_name", "character.name", "The character still has a placeholder name."
		))
	for field in CORE_FIELDS:
		var field_path := str(field.get("path", ""))
		if str(CCFStorageService.get_value_at_path(character_record, field_path, "")).strip_edges().is_empty():
			findings.append(_finding(
				"warning",
				"missing_core_field",
				field_path,
				"%s is empty." % str(field.get("label", "Required field"))
			))
	_check_known_types(character_record, findings)
	_check_duplicates(character_record, findings)
	_check_unknown_metadata(character_record, findings)
	var asset_report := missing_asset_report(project, character_id)
	for asset_finding in asset_report.get("findings", []):
		findings.append(asset_finding)
	var tokens := token_report(project, character_id)
	for section in tokens.get("sections", []):
		if int(section.get("tokens", 0)) > int(
			options.get("section_warning_tokens", SECTION_WARNING_TOKENS)
		):
			findings.append(_finding(
				"warning",
				"oversized_section",
				str(section.get("path", "")),
				"%s is approximately %d tokens; review whether it is intentionally this large."
				% [str(section.get("label", "Section")), int(section.get("tokens", 0))]
			))
	if int(tokens.get("total_tokens", 0)) > int(
		options.get("total_warning_tokens", TOTAL_WARNING_TOKENS)
	):
		findings.append(_finding(
			"warning",
			"oversized_card",
			"",
			"The authored card is approximately %d tokens before runtime formatting or activated lore."
			% int(tokens.get("total_tokens", 0))
		))
	var counts := {"error": 0, "warning": 0, "info": 0}
	for finding in findings:
		var severity := str(finding.get("severity", "info"))
		counts[severity] = int(counts.get(severity, 0)) + 1
	return {
		"ok": true,
		"findings": findings,
		"counts": counts,
		"blocking": false,
		"summary": "%d warning(s), %d error(s), %d informational note(s). Findings are advisory."
		% [int(counts.get("warning", 0)), int(counts.get("error", 0)), int(counts.get("info", 0))]
	}


static func token_report(project: Dictionary, character_id: String) -> Dictionary:
	var character_record := CCFStorageService.get_character(project, character_id)
	var sections: Array[Dictionary] = []
	for definition in TEXT_SECTIONS:
		_append_token_section(
			sections,
			str(definition.get("path", "")),
			str(definition.get("label", "Section")),
			CCFStorageService.get_value_at_path(
				character_record, str(definition.get("path", "")), ""
			)
		)
	_append_token_section(
		sections,
		"character.alternate_greetings",
		"Alternate Greetings",
		CCFStorageService.get_value_at_path(
			character_record, "character.alternate_greetings", []
		)
	)
	_append_token_section(
		sections,
		"character.character_book",
		"Character Lorebook",
		_lorebook_text(CCFStorageService.get_value_at_path(
			character_record, "character.character_book", {}
		))
	)
	_append_token_section(
		sections,
		"project.shared_context",
		"Project Shared Context",
		_text_from_variant(project.get("shared_context", {}))
	)
	_append_token_section(
		sections,
		"project.lorebook",
		"Project Lorebook",
		_lorebook_text(project.get("lorebook", {}))
	)
	var total_tokens := 0
	var total_characters := 0
	for section in sections:
		total_tokens += int(section.get("tokens", 0))
		total_characters += int(section.get("characters", 0))
	return {
		"ok": not character_record.is_empty(),
		"estimator": "characters_divided_by_4",
		"approximate": true,
		"sections": sections,
		"total_tokens": total_tokens,
		"total_characters": total_characters,
		"notice": (
			"Token counts are deterministic estimates. Exact counts and the final compiled "
			+ "prompt depend on the selected model, tokenizer, frontend and runtime lore activation."
		)
	}


static func compiled_prompt_preview(
	project: Dictionary, character_id: String
) -> Dictionary:
	var character_record := CCFStorageService.get_character(project, character_id)
	if character_record.is_empty():
		return {"ok": false, "error": "The selected character could not be found."}
	var card: Dictionary = character_record.get("character", {})
	var blocks: Array[String] = []
	blocks.append(
		"[CCF APPROXIMATION — NOT THE EXACT TARGET FRONTEND PROMPT]\n"
		+ "This preview shows authored material in a plausible order. The target frontend "
		+ "may use different templates, separators, lore activation, chat history and model instructions."
	)
	_append_prompt_block(blocks, "SYSTEM PROMPT", card.get("system_prompt", ""))
	_append_prompt_block(blocks, "CHARACTER NAME", card.get("name", ""))
	_append_prompt_block(blocks, "DESCRIPTION", card.get("description", ""))
	_append_prompt_block(blocks, "PERSONALITY", card.get("personality", ""))
	_append_prompt_block(blocks, "SCENARIO", card.get("scenario", ""))
	_append_prompt_block(
		blocks, "PROJECT SHARED CONTEXT", _text_from_variant(project.get("shared_context", {}))
	)
	_append_prompt_block(
		blocks, "CHARACTER LOREBOOK (ALL ENTRIES; RUNTIME ACTIVATION UNKNOWN)",
		_lorebook_text(card.get("character_book", {}))
	)
	_append_prompt_block(
		blocks, "PROJECT LOREBOOK (ALL ENTRIES; RUNTIME ACTIVATION UNKNOWN)",
		_lorebook_text(project.get("lorebook", {}))
	)
	_append_prompt_block(blocks, "EXAMPLE DIALOGUE", card.get("example_dialogue", ""))
	_append_prompt_block(blocks, "FIRST MESSAGE", card.get("first_message", ""))
	_append_prompt_block(
		blocks, "POST-HISTORY INSTRUCTIONS", card.get("post_history_instructions", "")
	)
	var preview_text := "\n\n".join(blocks)
	return {
		"ok": true,
		"text": preview_text,
		"estimated_tokens": estimate_tokens(preview_text),
		"approximate": true,
		"runtime_dependencies": [
			"target frontend prompt template",
			"model tokenizer",
			"active chat history",
			"lorebook activation and ordering",
			"frontend-specific extensions"
		]
	}


static func technical_metadata(
	project: Dictionary, character_id: String
) -> Dictionary:
	var character_record := CCFStorageService.get_character(project, character_id)
	var exported := CCFCardFormatService.export_character_v2(project, character_id)
	var card: Dictionary = character_record.get("character", {})
	var extension_value: Variant = card.get("card_extensions", {})
	var extension_keys: Array[String] = []
	if extension_value is Dictionary:
		for key_value in (extension_value as Dictionary).keys():
			extension_keys.append(str(key_value))
	var interoperability_value: Variant = character_record.get("interoperability", {})
	var interoperability: Dictionary = (
		(interoperability_value as Dictionary).duplicate(true)
		if interoperability_value is Dictionary
		else {}
	)
	return {
		"application_candidate": VERSION,
		"project_format_version": int(project.get("format_version", 0)),
		"project_id": str(project.get("project_id", "")),
		"character_id": character_id,
		"character_created_at": str(character_record.get("created_at", "")),
		"character_updated_at": str(character_record.get("updated_at", "")),
		"source_interoperability": interoperability,
		"card_spec": str(exported.get("spec", "")),
		"card_spec_version": str(exported.get("spec_version", "")),
		"extension_keys": extension_keys,
		"revision_count": CCFRevisionServiceV0181.list_revisions(character_record).size(),
		"private_internal_keys": PRIVATE_KEYS.duplicate(),
		"export_target": "Character Card V2 / SillyTavern-compatible JSON"
	}


static func raw_character_json(
	project: Dictionary, character_id: String
) -> String:
	var character_record := CCFStorageService.get_character(project, character_id)
	var editable := character_record.duplicate(true)
	for key_value in PRIVATE_KEYS:
		editable.erase(str(key_value))
	return JSON.stringify(editable, "  ")


static func validate_raw_character_json(
	raw_text: String, expected_character_id: String
) -> Dictionary:
	var json := JSON.new()
	var parse_error := json.parse(raw_text)
	if parse_error != OK:
		return {
			"ok": false,
			"errors": ["Invalid JSON at line %d: %s" % [json.get_error_line(), json.get_error_message()]],
			"warnings": []
		}
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		return {"ok": false, "errors": ["The character JSON root must be an object."], "warnings": []}
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var candidate: Dictionary = parsed
	if not candidate.get("character", null) is Dictionary:
		errors.append("character must be an object.")
	if not candidate.get("metadata", null) is Dictionary:
		errors.append("metadata must be an object.")
	if not candidate.get("assets", null) is Dictionary:
		errors.append("assets must be an object.")
	var candidate_id := str(candidate.get("character_id", ""))
	if candidate_id.is_empty():
		errors.append("character_id is required.")
	elif candidate_id != expected_character_id:
		errors.append("character_id cannot be changed in Raw JSON mode.")
	var candidate_card_value: Variant = candidate.get("character", {})
	if candidate_card_value is Dictionary:
		var candidate_card: Dictionary = candidate_card_value
		for field_name in [
			"name", "description", "personality", "scenario", "first_message",
			"example_dialogue", "creator_notes", "system_prompt",
			"post_history_instructions", "tts_voice"
		]:
			if candidate_card.has(field_name) and not candidate_card.get(field_name) is String:
				errors.append("character.%s must be text." % field_name)
		if candidate_card.has("alternate_greetings") and not candidate_card.get("alternate_greetings") is Array:
			errors.append("character.alternate_greetings must be an array.")
		if candidate_card.has("character_book") and not candidate_card.get("character_book") is Dictionary:
			errors.append("character.character_book must be an object.")
		if candidate_card.has("card_extensions") and not candidate_card.get("card_extensions") is Dictionary:
			errors.append("character.card_extensions must be an object.")
	for private_key in PRIVATE_KEYS:
		if candidate.has(private_key):
			warnings.append("Private key '%s' is managed by CCF and will not be replaced from Raw JSON." % private_key)
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"data": candidate.duplicate(true)
	}


static func apply_raw_character_json(
	project: Dictionary, character_id: String, raw_text: String
) -> Dictionary:
	var validation := validate_raw_character_json(raw_text, character_id)
	if not bool(validation.get("ok", false)):
		return validation
	var index := CCFStorageService.character_index(project, character_id)
	var characters: Array = project.get("characters", []).duplicate(true)
	var existing: Dictionary = (characters[index] as Dictionary).duplicate(true)
	CCFRevisionServiceV0181.create_checkpoint(
		existing,
		"Before Raw JSON apply",
		"Automatic recovery point created before expert Raw JSON changes.",
		"pre_raw_json",
		{},
		true
	)
	var history := CCFRevisionServiceV0181.ensure_history(existing).duplicate(true)
	var candidate: Dictionary = validation.get("data", {}).duplicate(true)
	for private_key in PRIVATE_KEYS:
		candidate.erase(str(private_key))
	for private_key in PRIVATE_KEYS:
		var private_key_text := str(private_key)
		if (
			private_key_text != CCFRevisionServiceV0181.HISTORY_KEY
			and existing.has(private_key_text)
		):
			var private_value: Variant = existing.get(private_key_text)
			candidate[private_key_text] = (
				private_value.duplicate(true)
				if private_value is Dictionary or private_value is Array
				else private_value
			)
	candidate["character_id"] = character_id
	candidate["created_at"] = str(existing.get("created_at", ""))
	candidate["updated_at"] = Time.get_datetime_string_from_system(true)
	candidate[CCFRevisionServiceV0181.HISTORY_KEY] = history
	CCFRevisionServiceV0181.create_checkpoint(
		candidate,
		"Applied Raw JSON",
		"Validated expert Raw JSON changes were explicitly applied.",
		"raw_json",
		{},
		true
	)
	characters[index] = candidate
	project["characters"] = characters
	return {"ok": true, "project": project.duplicate(true), "validation": validation}


static func import_inspection(source_path: String) -> Dictionary:
	var loaded := CCFCardFormatService.load_card_file(source_path)
	if not bool(loaded.get("ok", false)):
		return loaded
	var raw_card: Dictionary = loaded.get("data", {})
	var import_result := CCFCardFormatService.import_card_to_project(
		raw_card, str(loaded.get("source_format", "json"))
	)
	if not bool(import_result.get("ok", false)):
		return import_result
	var imported_project: Dictionary = import_result.get("project", {})
	var imported_id := CCFStorageService.active_character_id(imported_project)
	var token_data := token_report(imported_project, imported_id)
	var validation: Dictionary = loaded.get("report", {})
	var migration := migration_report(raw_card)
	var duplicate_evidence := _duplicate_evidence(
		CCFStorageService.get_character(imported_project, imported_id)
	)
	return {
		"ok": true,
		"source_path": source_path,
		"source_format": str(loaded.get("source_format", "json")),
		"detected_format": str(loaded.get("detected_format", "unknown")),
		"detected_version": str(raw_card.get("spec_version", "1")),
		"portrait_path": source_path if str(loaded.get("source_format", "")) == "png" else "",
		"raw_card": raw_card.duplicate(true),
		"imported_project": imported_project,
		"imported_character_id": imported_id,
		"token_report": token_data,
		"validation": validation,
		"duplicate_evidence": duplicate_evidence,
		"migration": migration,
		"loss_mapping": migration.get("rows", []).duplicate(true)
	}


static func migration_report(raw_card: Dictionary) -> Dictionary:
	var detected := CCFCardFormatService.detect_card_format(raw_card)
	var rows: Array[Dictionary] = []
	if detected == CCFCardFormatService.FORMAT_V1:
		rows.append(_migration_row("Core V1 text fields", "transformed", "Renamed into Character Card V2 data fields and CCF's internal character model."))
		rows.append(_migration_row("Missing V2 optional fields", "defaulted", "Supplied as empty text, lists or extension objects."))
		rows.append(_migration_row("V1-only unknown keys", "potentially lossy", "V1 has no standardized extension container for unknown keys."))
	else:
		rows.append(_migration_row("Character Card V2 canonical fields", "preserved", "Mapped directly into the internal character model."))
		rows.append(_migration_row("data.extensions", "namespaced", "Unknown vendor extensions remain under card_extensions for round-trip export."))
		rows.append(_migration_row("data.character_book", "preserved", "The complete lorebook object is retained."))
		if str(raw_card.get("spec_version", "")) != CCFCardFormatService.SPEC_VERSION_V2:
			rows.append(_migration_row("Future/different spec version", "review", "Known fields are mapped; validation warnings identify compatibility uncertainty."))
	return {
		"source_format": detected,
		"target": "CCF project format %d + Character Card V2 export" % CCFStorageService.CURRENT_FORMAT_VERSION,
		"rows": rows,
		"requires_review": true
	}


static func apply_import_to_current_project(
	project: Dictionary,
	active_character_id: String,
	inspection: Dictionary,
	action: String
) -> Dictionary:
	var imported_project: Dictionary = inspection.get("imported_project", {})
	var imported_id := str(inspection.get("imported_character_id", ""))
	var imported := CCFStorageService.get_character(imported_project, imported_id)
	if imported.is_empty():
		return {"ok": false, "error": "The inspected import no longer contains a character."}
	var updated := project.duplicate(true)
	if action == "copy":
		var copy_record := imported.duplicate(true)
		var new_character_id := _new_id()
		copy_record["character_id"] = new_character_id
		copy_record["created_at"] = Time.get_datetime_string_from_system(true)
		copy_record["updated_at"] = copy_record["created_at"]
		copy_record.erase(CCFRevisionServiceV0181.HISTORY_KEY)
		CCFRevisionServiceV0181.create_checkpoint(
			copy_record, "Imported as copy", "Import baseline.", "import", {}, true
		)
		var characters: Array = updated.get("characters", []).duplicate(true)
		characters.append(copy_record)
		updated["characters"] = characters
		return {"ok": true, "project": updated, "active_character_id": new_character_id}
	var index := CCFStorageService.character_index(updated, active_character_id)
	if index < 0:
		return {"ok": false, "error": "The active character could not be found."}
	var characters: Array = updated.get("characters", []).duplicate(true)
	var current_record: Dictionary = (characters[index] as Dictionary).duplicate(true)
	CCFRevisionServiceV0181.create_checkpoint(
		current_record,
		"Before import %s" % action,
		"Automatic recovery point created before applying an inspected import.",
		"pre_import",
		{"source_path": str(inspection.get("source_path", ""))},
		true
	)
	if action == "replace":
		var history := CCFRevisionServiceV0181.ensure_history(current_record).duplicate(true)
		var replacement := imported.duplicate(true)
		replacement["character_id"] = active_character_id
		replacement["created_at"] = str(current_record.get("created_at", ""))
		replacement["updated_at"] = Time.get_datetime_string_from_system(true)
		replacement[CCFRevisionServiceV0181.HISTORY_KEY] = history
		CCFRevisionServiceV0181.create_checkpoint(
			replacement, "Import replacement", "Inspected card replaced the authored fields.", "import_replace", {}, true
		)
		characters[index] = replacement
	elif action == "merge":
		_merge_imported_non_empty(current_record, imported)
		CCFRevisionServiceV0181.create_checkpoint(
			current_record, "Import merge", "Non-empty imported fields were merged after review.", "import_merge", {}, true
		)
		characters[index] = current_record
	else:
		return {"ok": false, "error": "Unknown import action."}
	updated["characters"] = characters
	return {"ok": true, "project": updated, "active_character_id": active_character_id}


static func missing_asset_report(
	project: Dictionary, character_id: String
) -> Dictionary:
	var character_record := CCFStorageService.get_character(project, character_id)
	var findings: Array[Dictionary] = []
	var missing: Array[Dictionary] = []
	var assets_value: Variant = character_record.get("assets", {})
	var assets: Dictionary = assets_value if assets_value is Dictionary else {}
	_check_asset_reference(project, character_id, "portrait", -1, assets.get("portrait", ""), missing, findings)
	for collection_key in ["generated_images", "emotion_images"]:
		var collection_value: Variant = assets.get(collection_key, [])
		if not collection_value is Array:
			findings.append(_finding("warning", "malformed_asset_collection", "assets.%s" % collection_key, "%s must be a list." % collection_key.capitalize()))
			continue
		for index in range((collection_value as Array).size()):
			var path_text := _asset_path_from_value((collection_value as Array)[index])
			_check_asset_reference(project, character_id, collection_key, index, path_text, missing, findings)
	var attachments_value: Variant = character_record.get("attachments", [])
	if attachments_value is Array:
		for index in range((attachments_value as Array).size()):
			var attachment_value: Variant = (attachments_value as Array)[index]
			if not attachment_value is Dictionary:
				continue
			var stored_path := str((attachment_value as Dictionary).get("stored_path", (attachment_value as Dictionary).get("path", "")))
			_check_asset_reference(project, character_id, "attachments", index, stored_path, missing, findings)
	var valid_ids: Dictionary = {}
	for character_value in project.get("characters", []):
		if character_value is Dictionary:
			valid_ids[str((character_value as Dictionary).get("character_id", ""))] = true
	var workflows: Array = project.get("card_workflows", [])
	for workflow_index in range(workflows.size()):
		var workflow_value: Variant = workflows[workflow_index]
		if not workflow_value is Dictionary:
			continue
		var workflow: Dictionary = workflow_value
		var member_ids: Array = workflow.get("selected_character_ids", [])
		for member_index in range(member_ids.size()):
			var member_id_value: Variant = member_ids[member_index]
			var member_id := str(member_id_value)
			if not valid_ids.has(member_id):
				findings.append(_finding("warning", "missing_group_member", "card_workflows", "A saved card workflow references missing character %s." % member_id))
				missing.append({
					"kind": "group_member",
					"index": member_index,
					"workflow_index": workflow_index,
					"workflow_id": str(workflow.get("workflow_id", "")),
					"stored_path": member_id,
					"resolved_path": "Missing from this project",
					"character_id": character_id
				})
	return {"ok": true, "missing": missing, "findings": findings}


static func repair_group_member(
	project: Dictionary,
	missing_item: Dictionary,
	replacement_character_id: String
) -> Dictionary:
	if CCFStorageService.character_index(project, replacement_character_id) < 0:
		return {"ok": false, "error": "Choose an existing replacement character."}
	var workflows: Array = project.get("card_workflows", []).duplicate(true)
	var workflow_index := int(missing_item.get("workflow_index", -1))
	if workflow_index < 0 or workflow_index >= workflows.size():
		return {"ok": false, "error": "The affected card workflow no longer exists."}
	if not workflows[workflow_index] is Dictionary:
		return {"ok": false, "error": "The affected card workflow is malformed."}
	var workflow: Dictionary = (workflows[workflow_index] as Dictionary).duplicate(true)
	if (
		str(missing_item.get("workflow_id", "")) != ""
		and str(workflow.get("workflow_id", ""))
		!= str(missing_item.get("workflow_id", ""))
	):
		return {"ok": false, "error": "The affected card workflow changed; refresh the report."}
	var members: Array = workflow.get("selected_character_ids", []).duplicate(true)
	var member_index := int(missing_item.get("index", -1))
	if member_index < 0 or member_index >= members.size():
		return {"ok": false, "error": "The missing member entry no longer exists."}
	if str(members[member_index]) != str(missing_item.get("stored_path", "")):
		return {"ok": false, "error": "The missing member entry changed; refresh the report."}
	members[member_index] = replacement_character_id
	var unique_members: Array[String] = []
	for member_value in members:
		var member_id := str(member_value)
		if not unique_members.has(member_id):
			unique_members.append(member_id)
	workflow["selected_character_ids"] = unique_members
	for member_record_value in workflow.get("members", []):
		if not member_record_value is Dictionary:
			continue
		var member_record: Dictionary = member_record_value
		if str(member_record.get("character_id", "")) == str(missing_item.get("stored_path", "")):
			member_record["character_id"] = replacement_character_id
	workflows[workflow_index] = workflow
	var updated := project.duplicate(true)
	updated["card_workflows"] = workflows
	return {"ok": true, "project": updated}


static func relink_asset(
	project: Dictionary,
	character_id: String,
	missing_item: Dictionary,
	replacement_path: String
) -> Dictionary:
	if replacement_path.strip_edges().is_empty() or not FileAccess.file_exists(replacement_path):
		return {"ok": false, "error": "Choose an existing replacement file."}
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0:
		return {"ok": false, "error": "The selected character could not be found."}
	var characters: Array = project.get("characters", []).duplicate(true)
	var character_record: Dictionary = (characters[index] as Dictionary).duplicate(true)
	var managed := _copy_relinked_asset(project, character_id, replacement_path)
	if not bool(managed.get("ok", false)):
		return managed
	var stored_replacement := str(managed.get("relative_path", ""))
	CCFRevisionServiceV0181.create_checkpoint(
		character_record, "Before asset relink", "Recovery point before repairing a missing asset.", "pre_asset_relink", {}, true
	)
	var kind := str(missing_item.get("kind", ""))
	var item_index := int(missing_item.get("index", -1))
	if kind == "attachments":
		var attachments: Array = character_record.get("attachments", []).duplicate(true)
		if item_index < 0 or item_index >= attachments.size() or not attachments[item_index] is Dictionary:
			return {"ok": false, "error": "The missing attachment entry no longer exists."}
		var attachment: Dictionary = (attachments[item_index] as Dictionary).duplicate(true)
		attachment["stored_path"] = stored_replacement
		attachments[item_index] = attachment
		character_record["attachments"] = attachments
	else:
		var assets: Dictionary = character_record.get("assets", {}).duplicate(true)
		if kind == "portrait":
			assets["portrait"] = stored_replacement
		else:
			var collection: Array = assets.get(kind, []).duplicate(true)
			if item_index < 0 or item_index >= collection.size():
				return {"ok": false, "error": "The missing asset entry no longer exists."}
			if collection[item_index] is Dictionary:
				var entry: Dictionary = (collection[item_index] as Dictionary).duplicate(true)
				var path_key := _asset_path_key(entry)
				entry[path_key] = stored_replacement
				collection[item_index] = entry
			else:
				collection[item_index] = stored_replacement
			assets[kind] = collection
		character_record["assets"] = assets
	CCFRevisionServiceV0181.create_checkpoint(
		character_record, "Asset relinked", "Missing asset reference repaired.", "asset_relink", {}, true
	)
	characters[index] = character_record
	project["characters"] = characters
	return {"ok": true, "project": project.duplicate(true)}


static func _copy_relinked_asset(
	project: Dictionary, character_id: String, source_path: String
) -> Dictionary:
	var source_file := FileAccess.open(source_path, FileAccess.READ)
	if source_file == null:
		return {"ok": false, "error": "The replacement file could not be opened."}
	var bytes := source_file.get_buffer(source_file.get_length())
	source_file.close()
	var original_filename := source_path.get_file()
	var safe_filename := ""
	for character in original_filename:
		if character.is_valid_filename():
			safe_filename += character
		else:
			safe_filename += "_"
	if safe_filename.is_empty():
		safe_filename = "relinked_asset"
	var relative_path := "characters/%s/assets/relinked_%d_%s" % [
		character_id, int(Time.get_unix_time_from_system()), safe_filename
	]
	var absolute_path := ProjectSettings.globalize_path(
		CCFStorageService.project_folder(str(project.get("project_id", ""))).path_join(
			relative_path
		)
	)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var output := FileAccess.open(absolute_path, FileAccess.WRITE)
	if output == null:
		return {"ok": false, "error": "The replacement could not be copied into managed project assets."}
	output.store_buffer(bytes)
	output.close()
	return {"ok": true, "relative_path": relative_path, "absolute_path": absolute_path}


static func checklist_report(
	project: Dictionary, character_id: String
) -> Dictionary:
	var character_record := CCFStorageService.get_character(project, character_id)
	var settings := checklist_settings(character_record)
	var tokens := token_report(project, character_id)
	var card: Dictionary = character_record.get("character", {})
	var assets: Dictionary = character_record.get("assets", {})
	var items: Array[Dictionary] = []
	_append_check(items, settings, "authored_fields", "Core authored fields", _core_fields_present(character_record), "Description, Personality, Scenario and First Message contain text.")
	_append_check(items, settings, "portrait", "Portrait or generated image", _has_any_asset_reference(assets), "At least one artwork reference is assigned.")
	_append_check(items, settings, "lore", "Lore reviewed", not _lorebook_text(card.get("character_book", {})).strip_edges().is_empty(), "The character has lorebook content.")
	_append_check(items, settings, "token_budget", "Token budget", int(tokens.get("total_tokens", 0)) <= int(settings.get("token_limit", TOTAL_WARNING_TOKENS)), "Estimated authored content remains within the chosen checklist limit.")
	_append_check(items, settings, "manual_review", "Manual review", bool(settings.get("manual_review_complete", false)), "Author explicitly marked review complete.")
	_append_check(items, settings, "test_status", "Optional test completed", bool(settings.get("test_complete", false)), "Author explicitly marked a roleplay test complete.")
	var enabled_count := 0
	var passed_count := 0
	for item in items:
		if bool(item.get("enabled", true)):
			enabled_count += 1
			if bool(item.get("passed", false)):
				passed_count += 1
	return {
		"ok": true,
		"settings": settings,
		"items": items,
		"enabled_count": enabled_count,
		"passed_count": passed_count,
		"complete": enabled_count > 0 and enabled_count == passed_count
	}


static func checklist_settings(character_record: Dictionary) -> Dictionary:
	var inspection_value: Variant = character_record.get(INSPECTION_KEY, {})
	var inspection: Dictionary = inspection_value.duplicate(true) if inspection_value is Dictionary else {}
	var settings_value: Variant = inspection.get("quality_checklist", {})
	var settings: Dictionary = settings_value.duplicate(true) if settings_value is Dictionary else {}
	var enabled_value: Variant = settings.get("enabled", {})
	var enabled: Dictionary = enabled_value.duplicate(true) if enabled_value is Dictionary else {}
	for item_id in ["authored_fields", "portrait", "lore", "token_budget", "manual_review", "test_status"]:
		if not enabled.has(item_id):
			enabled[item_id] = item_id not in ["lore", "test_status"]
	settings["enabled"] = enabled
	settings["token_limit"] = maxi(256, int(settings.get("token_limit", TOTAL_WARNING_TOKENS)))
	settings["manual_review_complete"] = bool(settings.get("manual_review_complete", false))
	settings["test_complete"] = bool(settings.get("test_complete", false))
	return settings


static func save_checklist_settings(
	project: Dictionary, character_id: String, settings: Dictionary
) -> Dictionary:
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0:
		return {"ok": false, "error": "The selected character could not be found."}
	var characters: Array = project.get("characters", []).duplicate(true)
	var character_record: Dictionary = (characters[index] as Dictionary).duplicate(true)
	var inspection_value: Variant = character_record.get(INSPECTION_KEY, {})
	var inspection: Dictionary = inspection_value.duplicate(true) if inspection_value is Dictionary else {}
	inspection["quality_checklist"] = settings.duplicate(true)
	character_record[INSPECTION_KEY] = inspection
	characters[index] = character_record
	project["characters"] = characters
	return {"ok": true, "project": project.duplicate(true)}


static func capabilities() -> Dictionary:
	return {
		"version": VERSION,
		"deterministic_health": true,
		"advisory_findings": true,
		"section_token_estimates": true,
		"compiled_prompt_approximation": true,
		"technical_metadata": true,
		"validated_raw_json_apply": true,
		"import_preview": true,
		"duplicate_evidence": true,
		"loss_mapping": true,
		"migration_assistant": true,
		"missing_asset_relink": true,
		"missing_group_member_repair": true,
		"custom_quality_checklist": true,
		"revision_guarded_changes": true
	}


static func estimate_tokens(text: String) -> int:
	if text.is_empty():
		return 0
	return maxi(1, int(ceil(float(text.length()) / CHARS_PER_TOKEN)))


static func _finding(
	severity: String, code: String, field_path: String, message: String
) -> Dictionary:
	return {
		"severity": severity,
		"code": code,
		"path": field_path,
		"message": message,
		"blocking": false
	}


static func _check_known_types(
	character_record: Dictionary, findings: Array[Dictionary]
) -> void:
	var metadata_value: Variant = character_record.get("metadata", {})
	if metadata_value is Dictionary and not (metadata_value as Dictionary).get("tags", []) is Array:
		findings.append(_finding("warning", "malformed_tags", "metadata.tags", "Tags should be a list."))
	var card_value: Variant = character_record.get("character", {})
	if not card_value is Dictionary:
		return
	var card: Dictionary = card_value
	if not card.get("alternate_greetings", []) is Array:
		findings.append(_finding("warning", "malformed_greetings", "character.alternate_greetings", "Alternate Greetings should be a list."))
	if not card.get("character_book", {}) is Dictionary:
		findings.append(_finding("warning", "malformed_lorebook", "character.character_book", "The character lorebook should be an object."))
	if not card.get("card_extensions", {}) is Dictionary:
		findings.append(_finding("warning", "malformed_extensions", "character.card_extensions", "Card extensions should be an object."))


static func _check_duplicates(
	character_record: Dictionary, findings: Array[Dictionary]
) -> void:
	var seen: Dictionary = {}
	for definition in TEXT_SECTIONS:
		var field_path := str(definition.get("path", ""))
		var text := str(CCFStorageService.get_value_at_path(character_record, field_path, "")).strip_edges()
		var normalized := _normalized_text(text)
		if normalized.length() < 24:
			continue
		if seen.has(normalized):
			findings.append(_finding("warning", "duplicate_text", field_path, "%s duplicates %s." % [str(definition.get("label", "Section")), str(seen.get(normalized))]))
		else:
			seen[normalized] = str(definition.get("label", "Section"))
	var greetings_value: Variant = CCFStorageService.get_value_at_path(character_record, "character.alternate_greetings", [])
	if greetings_value is Array:
		var greeting_seen: Dictionary = {}
		for index in range((greetings_value as Array).size()):
			var normalized := _normalized_text(str((greetings_value as Array)[index]))
			if normalized.is_empty():
				continue
			if greeting_seen.has(normalized):
				findings.append(_finding("warning", "duplicate_greeting", "character.alternate_greetings", "Alternate Greeting %d duplicates Alternate Greeting %d." % [index + 1, int(greeting_seen.get(normalized)) + 1]))
			else:
				greeting_seen[normalized] = index


static func _check_unknown_metadata(
	character_record: Dictionary, findings: Array[Dictionary]
) -> void:
	var known := {
		"character_id": true, "created_at": true, "updated_at": true,
		"metadata": true, "concept": true, "character": true, "generation": true,
		"assets": true, "attachments": true, "workspace": true,
		"interoperability": true, "variant": true
	}
	for private_key in PRIVATE_KEYS:
		known[private_key] = true
	for key_value in character_record.keys():
		var key_text := str(key_value)
		if not known.has(key_text):
			findings.append(_finding("info", "namespaced_custom_metadata", key_text, "Custom field '%s' is not a canonical Character Card V2 field and will require namespaced preservation." % key_text))


static func _append_token_section(
	sections: Array[Dictionary], field_path: String, label_text: String, value: Variant
) -> void:
	var text := _text_from_variant(value)
	sections.append({
		"path": field_path,
		"label": label_text,
		"characters": text.length(),
		"tokens": estimate_tokens(text),
		"empty": text.strip_edges().is_empty()
	})


static func _text_from_variant(value: Variant) -> String:
	if value is String:
		return value
	if value is Array:
		var parts: Array[String] = []
		for item in value:
			parts.append(_text_from_variant(item))
		return "\n".join(parts)
	if value is Dictionary:
		var parts: Array[String] = []
		for key_value in (value as Dictionary).keys():
			var nested := _text_from_variant((value as Dictionary).get(key_value))
			if not nested.strip_edges().is_empty():
				parts.append("%s: %s" % [str(key_value), nested])
		return "\n".join(parts)
	return str(value) if value != null else ""


static func _lorebook_text(value: Variant) -> String:
	if not value is Dictionary:
		return _text_from_variant(value)
	var book: Dictionary = value
	var entries_value: Variant = book.get("entries", [])
	if not entries_value is Array:
		return _text_from_variant(book)
	var parts: Array[String] = []
	for entry_value in entries_value:
		if entry_value is Dictionary:
			var entry: Dictionary = entry_value
			parts.append("%s\nKeys: %s\n%s" % [str(entry.get("name", entry.get("comment", "Lore"))), _text_from_variant(entry.get("keys", [])), str(entry.get("content", ""))])
	return "\n\n".join(parts)


static func _append_prompt_block(
	blocks: Array[String], heading: String, value: Variant
) -> void:
	var text := _text_from_variant(value).strip_edges()
	if not text.is_empty():
		blocks.append("[%s]\n%s" % [heading, text])


static func _migration_row(
	field_name: String, disposition: String, detail: String
) -> Dictionary:
	return {"field": field_name, "disposition": disposition, "detail": detail}


static func _duplicate_evidence(imported_character: Dictionary) -> Array[Dictionary]:
	var evidence: Array[Dictionary] = []
	var imported_name := CCFStorageService.character_display_name(imported_character)
	var imported_digest := _character_content_digest(imported_character)
	for row_value in CCFStorageService.list_projects():
		if not row_value is Dictionary:
			continue
		var project_id := str((row_value as Dictionary).get("project_id", ""))
		var loaded := CCFStorageService.load_project(project_id)
		if not bool(loaded.get("ok", false)):
			continue
		for existing_value in loaded.get("data", {}).get("characters", []):
			if not existing_value is Dictionary:
				continue
			var existing: Dictionary = existing_value
			var same_name := CCFStorageService.character_display_name(existing).nocasecmp_to(imported_name) == 0
			var same_content := _character_content_digest(existing) == imported_digest
			if same_name or same_content:
				evidence.append({
					"project_id": project_id,
					"character_id": str(existing.get("character_id", "")),
					"name": CCFStorageService.character_display_name(existing),
					"exact_content": same_content,
					"same_name": same_name,
					"summary": "Exact authored content" if same_content else "Same character name"
				})
	return evidence


static func _character_content_digest(character_record: Dictionary) -> String:
	return JSON.stringify({
		"metadata": character_record.get("metadata", {}),
		"concept": character_record.get("concept", {}),
		"character": character_record.get("character", {})
	}).sha256_text()


static func _merge_imported_non_empty(
	target: Dictionary, source: Dictionary
) -> void:
	for section_key in ["metadata", "concept", "character"]:
		var target_section: Dictionary = target.get(section_key, {}).duplicate(true)
		var source_value: Variant = source.get(section_key, {})
		if not source_value is Dictionary:
			continue
		for key_value in (source_value as Dictionary).keys():
			var incoming: Variant = (source_value as Dictionary).get(key_value)
			if _variant_has_content(incoming):
				target_section[str(key_value)] = incoming.duplicate(true) if incoming is Dictionary or incoming is Array else incoming
		target[section_key] = target_section


static func _variant_has_content(value: Variant) -> bool:
	if value == null:
		return false
	if value is String:
		return not (value as String).strip_edges().is_empty()
	if value is Array or value is Dictionary:
		return not value.is_empty()
	return true


static func _check_asset_reference(
	project: Dictionary,
	character_id: String,
	kind: String,
	item_index: int,
	path_value: Variant,
	missing: Array[Dictionary],
	findings: Array[Dictionary]
) -> void:
	var path_text := str(path_value).strip_edges()
	if path_text.is_empty():
		return
	var resolved := _resolve_asset_path(project, path_text)
	if FileAccess.file_exists(resolved):
		return
	var item := {
		"kind": kind,
		"index": item_index,
		"stored_path": path_text,
		"resolved_path": resolved,
		"character_id": character_id
	}
	missing.append(item)
	findings.append(_finding("warning", "missing_asset", "assets.%s" % kind, "Missing %s file: %s" % [kind.replace("_", " "), path_text]))


static func _resolve_asset_path(project: Dictionary, path_text: String) -> String:
	if path_text.begins_with("user://") or path_text.is_absolute_path():
		return path_text
	return CCFStorageService.project_folder(str(project.get("project_id", ""))).path_join(path_text)


static func _asset_path_from_value(value: Variant) -> String:
	if value is String:
		return value
	if value is Dictionary:
		for key_value in ["managed_path", "path", "image_path", "stored_path"]:
			var candidate := str((value as Dictionary).get(key_value, "")).strip_edges()
			if not candidate.is_empty():
				return candidate
	return ""


static func _asset_path_key(entry: Dictionary) -> String:
	for key_value in ["managed_path", "path", "image_path", "stored_path"]:
		if entry.has(key_value):
			return key_value
	return "path"


static func _append_check(
	items: Array[Dictionary],
	settings: Dictionary,
	item_id: String,
	label_text: String,
	passed: bool,
	detail: String
) -> void:
	var enabled: Dictionary = settings.get("enabled", {})
	items.append({
		"id": item_id,
		"label": label_text,
		"enabled": bool(enabled.get(item_id, true)),
		"passed": passed,
		"detail": detail
	})


static func _core_fields_present(character_record: Dictionary) -> bool:
	for field in CORE_FIELDS:
		if str(CCFStorageService.get_value_at_path(character_record, str(field.get("path", "")), "")).strip_edges().is_empty():
			return false
	return true


static func _has_any_asset_reference(assets: Dictionary) -> bool:
	if not str(assets.get("portrait", "")).strip_edges().is_empty():
		return true
	for key_value in ["generated_images", "emotion_images"]:
		var value: Variant = assets.get(key_value, [])
		if value is Array and not (value as Array).is_empty():
			return true
	return false


static func _normalized_text(value: String) -> String:
	return " ".join(value.to_lower().split()).strip_edges()


static func _new_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()
