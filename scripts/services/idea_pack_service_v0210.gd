class_name CCFIdeaPackServiceV0210
extends RefCounted

const FORMAT_ID := "character-card-forge-ideas"
const SCHEMA_VERSION := 1
const IDEA_FORMAT := "character_card_forge_saved_idea"
const IDEA_FORMAT_VERSION := 1
const DEFAULT_ROOT := "user://character_card_forge/idea_notebook"

const SUPPORTED_KINDS := ["series", "seed", "character_note"]
const ENTRY_FIELDS := [
	"id",
	"kind",
	"title",
	"status",
	"classification",
	"summary",
	"core_premise",
	"setup",
	"opening_beat",
	"character_engine",
	"ground_truth",
	"hidden_motive",
	"core_variables",
	"flagship_seeds",
	"generation_rules",
	"guardrails",
	"tags",
	"notes",
	"sections"
]
const STRING_FIELDS := [
	"summary",
	"core_premise",
	"setup",
	"opening_beat",
	"character_engine",
	"ground_truth",
	"hidden_motive"
]
const LIST_FIELDS := [
	"core_variables",
	"flagship_seeds",
	"generation_rules",
	"guardrails",
	"tags",
	"notes"
]

var _root_dir: String
var _ideas_dir: String


func _init(root_dir: String = "") -> void:
	_root_dir = root_dir.strip_edges()
	if _root_dir.is_empty():
		_root_dir = DEFAULT_ROOT
	_ideas_dir = _root_dir.path_join("ideas")


func parse_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fatal_result("file_unreadable", "Could not open the selected Idea Pack.")
	var text := file.get_as_text()
	file.close()
	var result := parse_text(text)
	result["source_path"] = path
	return result


func parse_text(text: String) -> Dictionary:
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return _fatal_result(
			"invalid_json",
			"Invalid JSON: %s (line %d)." % [json.get_error_message(), json.get_error_line()]
		)
	if not json.data is Dictionary:
		return _fatal_result("unsupported_structure", "The Idea Pack root must be a JSON object.")
	var raw: Dictionary = json.data
	var errors: Array[Dictionary] = []
	var warnings: Array[Dictionary] = []
	if str(raw.get("format", "")) != FORMAT_ID:
		errors.append(_issue("wrong_format", "format must equal '%s'." % FORMAT_ID))
	var schema_value: Variant = raw.get("schema_version", null)
	if schema_value == null or not (schema_value is int or schema_value is float):
		errors.append(_issue("missing_schema_version", "schema_version must be an integer."))
	var schema_version := int(schema_value) if schema_value is int or schema_value is float else 0
	if schema_version < 1:
		errors.append(_issue("unsupported_schema", "schema_version must be 1 or newer."))
	elif schema_version > SCHEMA_VERSION:
		warnings.append(_issue(
			"newer_schema",
			"This pack uses schema version %d; this CCF version supports version %d. Preview is read-only." % [schema_version, SCHEMA_VERSION]
		))
	var pack_value: Variant = raw.get("pack", null)
	if pack_value == null:
		errors.append(_issue("missing_pack", "pack is required."))
	elif not pack_value is Dictionary:
		errors.append(_issue("invalid_pack_metadata", "pack must be a JSON object."))
	var pack := _normalise_pack(pack_value as Dictionary if pack_value is Dictionary else {})
	var entries_value: Variant = raw.get("entries", null)
	if entries_value == null:
		errors.append(_issue("missing_entries", "entries is required."))
	elif not entries_value is Array:
		errors.append(_issue("invalid_entries", "entries must be an array."))
	var entries: Array[Dictionary] = []
	var seen_ids := {}
	if entries_value is Array:
		for entry_index in range((entries_value as Array).size()):
			var raw_entry_value: Variant = (entries_value as Array)[entry_index]
			if not raw_entry_value is Dictionary:
				errors.append(_entry_issue(
					"invalid_entry", "Entry %d must be a JSON object." % (entry_index + 1), entry_index
				))
				continue
			var raw_entry: Dictionary = raw_entry_value
			var required_missing: Array[String] = []
			for required_field in ["id", "kind", "title"]:
				if str(raw_entry.get(required_field, "")).strip_edges().is_empty():
					required_missing.append(required_field)
			if not required_missing.is_empty():
				errors.append(_entry_issue(
					"missing_required_field",
					"Entry %d is missing: %s." % [entry_index + 1, ", ".join(required_missing)],
					entry_index
				))
				continue
			var entry := _normalise_entry(raw_entry)
			var entry_id := str(entry.get("id", ""))
			if seen_ids.has(entry_id):
				warnings.append(_entry_issue(
					"duplicate_pack_id",
					"Entry ID '%s' appears more than once in this pack." % entry_id,
					entry_index,
					entry_id
				))
			else:
				seen_ids[entry_id] = entry_index
			var kind := str(entry.get("kind", ""))
			if kind not in SUPPORTED_KINDS:
				warnings.append(_entry_issue(
					"unknown_kind",
					"Entry '%s' uses unknown kind '%s'; its data is preserved." % [entry_id, kind],
					entry_index,
					entry_id
				))
			if kind == "series" and str(entry.get("core_premise", "")).is_empty():
				warnings.append(_entry_issue(
					"empty_premise", "Series '%s' has no core premise." % entry_id, entry_index, entry_id
				))
			if kind == "seed" and _entry_has_no_premise(entry):
				warnings.append(_entry_issue(
					"empty_setup", "Seed '%s' has no summary, premise or setup." % entry_id, entry_index, entry_id
				))
			var raw_sections_value: Variant = raw_entry.get("sections", [])
			if not raw_sections_value is Array:
				warnings.append(_entry_issue(
					"invalid_sections",
					"Entry '%s' has a non-array sections value; it was safely ignored." % entry_id,
					entry_index,
					entry_id
				))
			else:
				for section_index in range((raw_sections_value as Array).size()):
					var section_value: Variant = (raw_sections_value as Array)[section_index]
					if not section_value is Dictionary:
						warnings.append(_entry_issue(
							"invalid_section",
							"Entry '%s' section %d is not an object; it was safely ignored." % [entry_id, section_index + 1],
							entry_index,
							entry_id
						))
						continue
					var section: Dictionary = section_value
					if str(section.get("label", "")).strip_edges().is_empty():
						warnings.append(_entry_issue(
							"unnamed_section",
							"Entry '%s' section %d has no label; its content remains preserved." % [entry_id, section_index + 1],
							entry_index,
							entry_id
						))
			for key_value in raw_entry.keys():
				var key := str(key_value)
				if key not in ENTRY_FIELDS:
					warnings.append(_entry_issue(
						"unknown_field",
						"Entry '%s' contains future field '%s'; it will be preserved." % [entry_id, key],
						entry_index,
						entry_id
					))
			entries.append(entry)
	_append_cross_link_warnings(entries, warnings)
	var import_allowed := errors.is_empty() and schema_version == SCHEMA_VERSION
	var result := {
		"ok": errors.is_empty(),
		"import_allowed": import_allowed,
		"format": str(raw.get("format", "")),
		"schema_version": schema_version,
		"pack": pack,
		"entries": entries,
		"errors": errors,
		"warnings": warnings,
		"raw": raw.duplicate(true),
		"summary": _summary(entries)
	}
	return analyse_conflicts(result)


func analyse_conflicts(preview: Dictionary) -> Dictionary:
	var result := preview.duplicate(true)
	var entries_value: Variant = result.get("entries", [])
	var entries: Array = entries_value if entries_value is Array else []
	var local_ideas := list_local_ideas(true)
	var by_original_id := {}
	var by_title := {}
	for idea in local_ideas:
		var original_id := original_import_id(idea)
		if original_id.is_empty():
			original_id = str(idea.get("id", ""))
		if not original_id.is_empty() and not by_original_id.has(original_id):
			by_original_id[original_id] = idea
		var title_key := _normalised_title(str(idea.get("title", "")))
		if not title_key.is_empty():
			if not by_title.has(title_key):
				by_title[title_key] = []
			(by_title[title_key] as Array).append(idea)
	var analysed: Array[Dictionary] = []
	var seen_pack_ids := {}
	var counts := {"new": 0, "updates": 0, "conflicts": 0, "title_warnings": 0}
	for entry_index in range(entries.size()):
		var entry_value: Variant = entries[entry_index]
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var entry_id := str(entry.get("id", ""))
		var title_key := _normalised_title(str(entry.get("title", "")))
		var row := {
			"index": entry_index,
			"entry": entry.duplicate(true),
			"selected": true,
			"conflict": "new",
			"action": "import",
			"existing_local_id": "",
			"likely_title_ids": []
		}
		if seen_pack_ids.has(entry_id):
			row["conflict"] = "duplicate_pack_id"
			row["action"] = "skip"
			row["selected"] = false
			counts["conflicts"] = int(counts["conflicts"]) + 1
		elif by_original_id.has(entry_id):
			var existing: Dictionary = by_original_id[entry_id]
			row["conflict"] = "existing_id"
			row["action"] = "skip"
			row["existing_local_id"] = str(existing.get("id", ""))
			counts["updates"] = int(counts["updates"]) + 1
			counts["conflicts"] = int(counts["conflicts"]) + 1
		else:
			counts["new"] = int(counts["new"]) + 1
			if by_title.has(title_key):
				row["conflict"] = "likely_title_duplicate"
				var likely_ids: Array[String] = []
				for match_value in by_title[title_key]:
					if match_value is Dictionary:
						likely_ids.append(str((match_value as Dictionary).get("id", "")))
				row["likely_title_ids"] = likely_ids
				counts["title_warnings"] = int(counts["title_warnings"]) + 1
		seen_pack_ids[entry_id] = entry_index
		analysed.append(row)
	result["analysed_entries"] = analysed
	result["conflict_summary"] = counts
	return result


func import_preview(
	preview: Dictionary,
	selections: Array,
	notebook_id: String = ""
) -> Dictionary:
	if not bool(preview.get("ok", false)):
		return {"ok": false, "error": "The Idea Pack has fatal validation errors."}
	if not bool(preview.get("import_allowed", false)):
		return {"ok": false, "error": "This Idea Pack can be previewed but its schema cannot be imported safely."}
	var analysed_value: Variant = preview.get("analysed_entries", [])
	if not analysed_value is Array:
		return {"ok": false, "error": "The Idea Pack preview is incomplete."}
	var selected_by_index := {}
	for selection_value in selections:
		if not selection_value is Dictionary:
			continue
		var selection: Dictionary = selection_value
		if not bool(selection.get("selected", false)):
			continue
		selected_by_index[int(selection.get("index", -1))] = str(selection.get("action", "import"))
	if selected_by_index.is_empty():
		return {"ok": false, "error": "Select at least one entry to import."}
	var pack: Dictionary = preview.get("pack", {})
	var schema_version := int(preview.get("schema_version", 0))
	var plans: Array[Dictionary] = []
	var skipped := 0
	var occupied_ids := _local_id_set()
	for row_value in analysed_value:
		if not row_value is Dictionary:
			continue
		var row: Dictionary = row_value
		var entry_index := int(row.get("index", -1))
		if not selected_by_index.has(entry_index):
			continue
		var action := str(selected_by_index[entry_index])
		var conflict := str(row.get("conflict", "new"))
		if action == "skip":
			skipped += 1
			continue
		if conflict == "existing_id" and action not in ["replace", "keep_both"]:
			return {"ok": false, "error": "Choose Skip, Replace or Keep both for every existing ID conflict."}
		if conflict == "duplicate_pack_id" and action != "keep_both":
			return {"ok": false, "error": "Duplicate IDs inside a pack must be skipped or explicitly kept as a copy."}
		var local_id := ""
		var existing: Dictionary = {}
		if action == "replace":
			local_id = str(row.get("existing_local_id", ""))
			var loaded := load_local_idea(local_id)
			if not bool(loaded.get("ok", false)):
				return {"ok": false, "error": "An existing Idea Notebook record changed after preview. Refresh the import."}
			existing = loaded.get("data", {})
		else:
			local_id = _new_unique_local_id(occupied_ids)
			occupied_ids[local_id] = true
		var entry: Dictionary = row.get("entry", {})
		plans.append({
			"action": action,
			"local_id": local_id,
			"record": _idea_record(entry, pack, schema_version, local_id, notebook_id, existing)
		})
	if plans.is_empty():
		return {
			"ok": true,
			"imported": 0,
			"replaced": 0,
			"copies": 0,
			"skipped": skipped,
			"total": 0
		}
	var committed := _commit_atomic(plans)
	committed["skipped"] = skipped
	return committed


func build_export_pack(ideas: Array, pack_metadata: Dictionary = {}) -> Dictionary:
	var entries: Array[Dictionary] = []
	var seen_ids := {}
	for idea_value in ideas:
		if not idea_value is Dictionary:
			continue
		var entry := idea_to_entry(idea_value as Dictionary)
		var entry_id := str(entry.get("id", ""))
		if seen_ids.has(entry_id):
			entry["id"] = "%s-copy-%d" % [entry_id, int(seen_ids[entry_id]) + 1]
			seen_ids[entry_id] = int(seen_ids[entry_id]) + 1
		else:
			seen_ids[entry_id] = 1
		entries.append(entry)
	var pack := _normalise_pack(pack_metadata)
	if str(pack.get("id", "")).is_empty():
		pack["id"] = "ccf-ideas-%s" % Time.get_datetime_string_from_system(true).replace(":", "-")
	if str(pack.get("title", "")).is_empty():
		pack["title"] = "Character Card Forge Idea Pack"
	if pack.get("created_at", null) == null:
		pack["created_at"] = Time.get_datetime_string_from_system(true)
	return {
		"format": FORMAT_ID,
		"schema_version": SCHEMA_VERSION,
		"pack": pack,
		"entries": entries
	}


func export_to_file(path: String, ideas: Array, pack_metadata: Dictionary = {}) -> Dictionary:
	var output_path := path.strip_edges()
	if output_path.is_empty():
		return {"ok": false, "error": "Choose an Idea Pack destination."}
	if not output_path.to_lower().ends_with(".ccfideas.json"):
		output_path += ".ccfideas.json"
	var pack := build_export_pack(ideas, pack_metadata)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not create the Idea Pack file."}
	file.store_string(JSON.stringify(pack, "  "))
	file.store_string("\n")
	file.flush()
	file.close()
	var verified := parse_file(output_path)
	if not bool(verified.get("ok", false)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(output_path))
		return {"ok": false, "error": "The exported Idea Pack did not pass validation."}
	return {"ok": true, "path": output_path, "entry_count": ideas.size(), "pack": pack}


func idea_to_entry(idea: Dictionary) -> Dictionary:
	var structured_value: Variant = idea.get("structured_idea", {})
	var structured: Dictionary = structured_value if structured_value is Dictionary else {}
	var entry_value: Variant = structured.get("entry", {})
	var has_structured_entry := entry_value is Dictionary and not (entry_value as Dictionary).is_empty()
	var entry: Dictionary
	if has_structured_entry:
		entry = _normalise_entry(entry_value as Dictionary)
	else:
		entry = _normalise_entry({
			"id": str(idea.get("id", "")),
			"kind": "seed",
			"title": str(idea.get("title", "Untitled idea")),
			"summary": str(idea.get("concept", "")),
			"tags": idea.get("tags", []),
			"notes": [str(idea.get("notes", ""))] if not str(idea.get("notes", "")).is_empty() else []
		})
	var stored_rendered := render_entry_for_generation(entry)
	var original_id := original_import_id(idea)
	if not original_id.is_empty():
		entry["id"] = original_id
	entry["title"] = str(idea.get("title", entry.get("title", "Untitled idea"))).strip_edges()
	entry["tags"] = _string_list(idea.get("tags", entry.get("tags", [])))
	var edited_notes := str(idea.get("notes", "")).strip_edges()
	var stored_notes := "\n".join(_string_list(entry.get("notes", []))).strip_edges()
	if has_structured_entry and edited_notes != stored_notes:
		entry["notes"] = [edited_notes] if not edited_notes.is_empty() else []
	var edited_concept := str(idea.get("concept", "")).strip_edges()
	if has_structured_entry and not edited_concept.is_empty() and edited_concept != stored_rendered:
		var sections: Array = entry.get("sections", []).duplicate(true)
		var replaced_override := false
		for section_index in range(sections.size()):
			if not sections[section_index] is Dictionary:
				continue
			var section: Dictionary = (sections[section_index] as Dictionary).duplicate(true)
			if str(section.get("label", "")).nocasecmp_to("CCF author concept override") != 0:
				continue
			section["content"] = edited_concept
			sections[section_index] = section
			replaced_override = true
			break
		if not replaced_override:
			sections.append({
				"label": "CCF author concept override",
				"content": edited_concept
			})
		entry["sections"] = sections
	return entry


func generation_context_for_idea(idea: Dictionary) -> String:
	return render_entry_for_generation(idea_to_entry(idea))


func render_entry_for_generation(entry: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("IDEA: %s" % str(entry.get("title", "Untitled idea")))
	lines.append("KIND: %s" % str(entry.get("kind", "seed")))
	var classification: Dictionary = entry.get("classification", {})
	var classification_bits: Array[String] = []
	var bible := str(classification.get("bible", ""))
	if not bible.is_empty():
		classification_bits.append("Bible %s" % bible)
	var series_number_value: Variant = classification.get("series_number", null)
	if series_number_value != null:
		classification_bits.append("Series %s" % str(series_number_value))
	var primary_series := _string_list(classification.get("primary_series", []))
	if not primary_series.is_empty():
		classification_bits.append("Primary series: %s" % ", ".join(primary_series))
	if not classification_bits.is_empty():
		lines.append("CLASSIFICATION: %s" % " • ".join(classification_bits))
	var labels := {
		"summary": "SUMMARY",
		"core_premise": "CORE PREMISE",
		"setup": "SETUP",
		"opening_beat": "OPENING BEAT",
		"character_engine": "CHARACTER ENGINE",
		"ground_truth": "GROUND TRUTH",
		"hidden_motive": "HIDDEN MOTIVE"
	}
	for field_id in STRING_FIELDS:
		var value := str(entry.get(field_id, "")).strip_edges()
		if not value.is_empty():
			lines.append("\n%s\n%s" % [str(labels[field_id]), value])
	var list_labels := {
		"core_variables": "CORE VARIABLES",
		"flagship_seeds": "FLAGSHIP SEEDS",
		"generation_rules": "GENERATION RULES",
		"guardrails": "GUARDRAILS",
		"notes": "NOTES"
	}
	for field_id in ["core_variables", "flagship_seeds", "generation_rules", "guardrails", "notes"]:
		var values := _string_list(entry.get(field_id, []))
		if values.is_empty():
			continue
		lines.append("\n%s" % str(list_labels[field_id]))
		for value in values:
			lines.append("- %s" % value)
	var sections_value: Variant = entry.get("sections", [])
	if sections_value is Array:
		for section_value in sections_value:
			if not section_value is Dictionary:
				continue
			var section: Dictionary = section_value
			var label := str(section.get("label", "Additional section")).strip_edges()
			var content := str(section.get("content", "")).strip_edges()
			if not content.is_empty():
				lines.append("\n%s\n%s" % [label.to_upper(), content])
	var tags := _string_list(entry.get("tags", []))
	if not tags.is_empty():
		lines.append("\nTAGS: %s" % ", ".join(tags))
	return "\n".join(lines).strip_edges()


func list_local_ideas(include_archived: bool = true) -> Array[Dictionary]:
	_ensure_directories()
	var result: Array[Dictionary] = []
	for file_name in DirAccess.get_files_at(_ideas_dir):
		if not file_name.to_lower().ends_with(".json"):
			continue
		var loaded := _read_json(_ideas_dir.path_join(file_name))
		if not bool(loaded.get("ok", false)):
			continue
		var data_value: Variant = loaded.get("data", {})
		if not data_value is Dictionary:
			continue
		var idea: Dictionary = data_value
		if not include_archived and bool(idea.get("archived", false)):
			continue
		result.append(idea.duplicate(true))
	result.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return str(first.get("updated_at", "")) > str(second.get("updated_at", ""))
	)
	return result


func load_local_idea(local_id: String) -> Dictionary:
	return _read_json(_idea_path(local_id))


func original_import_id(idea: Dictionary) -> String:
	var source_value: Variant = idea.get("source", {})
	if source_value is Dictionary:
		var source: Dictionary = source_value
		var pack_value: Variant = source.get("idea_pack", {})
		if pack_value is Dictionary:
			return str((pack_value as Dictionary).get("original_id", "")).strip_edges()
	var structured_value: Variant = idea.get("structured_idea", {})
	if structured_value is Dictionary:
		var entry_value: Variant = (structured_value as Dictionary).get("entry", {})
		if entry_value is Dictionary:
			return str((entry_value as Dictionary).get("id", "")).strip_edges()
	return ""


func export_filter_values(ideas: Array) -> Dictionary:
	var bibles := {}
	var series := {}
	for idea_value in ideas:
		if not idea_value is Dictionary:
			continue
		var entry := idea_to_entry(idea_value as Dictionary)
		var classification: Dictionary = entry.get("classification", {})
		var bible := str(classification.get("bible", "")).strip_edges()
		if not bible.is_empty():
			bibles[bible] = true
		for series_name in _string_list(classification.get("primary_series", [])):
			series[series_name] = true
		for series_name in _string_list(classification.get("secondary_series", [])):
			series[series_name] = true
	var bible_list: Array[String] = []
	for value in bibles.keys():
		bible_list.append(str(value))
	bible_list.sort()
	var series_list: Array[String] = []
	for value in series.keys():
		series_list.append(str(value))
	series_list.sort()
	return {"bibles": bible_list, "series": series_list}


func idea_matches_export_scope(idea: Dictionary, scope: String, value: String = "") -> bool:
	if scope == "all":
		return true
	var entry := idea_to_entry(idea)
	var classification: Dictionary = entry.get("classification", {})
	if scope == "bible":
		return str(classification.get("bible", "")) == value
	if scope == "series":
		return value in _string_list(classification.get("primary_series", [])) or value in _string_list(classification.get("secondary_series", []))
	return false


func _normalise_pack(raw: Dictionary) -> Dictionary:
	var pack := raw.duplicate(true)
	for field_id in ["id", "title", "description", "source_version"]:
		pack[field_id] = str(pack.get(field_id, "")).strip_edges()
	if not pack.has("created_at"):
		pack["created_at"] = null
	if not pack.has("source"):
		pack["source"] = null
	return pack


func _normalise_entry(raw: Dictionary) -> Dictionary:
	var entry := raw.duplicate(true)
	entry["id"] = str(entry.get("id", "")).strip_edges()
	entry["kind"] = str(entry.get("kind", "")).strip_edges().to_lower()
	entry["title"] = str(entry.get("title", "")).strip_edges()
	var status_value: Variant = entry.get("status", {})
	var status: Dictionary = status_value.duplicate(true) if status_value is Dictionary else {}
	status["saved"] = bool(status.get("saved", false))
	status["implemented"] = bool(status.get("implemented", false))
	entry["status"] = status
	var classification_value: Variant = entry.get("classification", {})
	var classification: Dictionary = classification_value.duplicate(true) if classification_value is Dictionary else {}
	classification["bible"] = str(classification.get("bible", "")).strip_edges()
	if not classification.has("series_number"):
		classification["series_number"] = null
	for field_id in ["primary_series", "secondary_series", "cross_links"]:
		classification[field_id] = _string_list(classification.get(field_id, []))
	entry["classification"] = classification
	for field_id in STRING_FIELDS:
		entry[field_id] = str(entry.get(field_id, "")).strip_edges()
	for field_id in LIST_FIELDS:
		entry[field_id] = _string_list(entry.get(field_id, []))
	var sections: Array[Dictionary] = []
	var sections_value: Variant = entry.get("sections", [])
	if sections_value is Array:
		for section_value in sections_value:
			if not section_value is Dictionary:
				continue
			var section: Dictionary = (section_value as Dictionary).duplicate(true)
			section["label"] = str(section.get("label", "")).strip_edges()
			section["content"] = str(section.get("content", "")).strip_edges()
			sections.append(section)
	entry["sections"] = sections
	return entry


func _idea_record(
	entry: Dictionary,
	pack: Dictionary,
	schema_version: int,
	local_id: String,
	notebook_id: String,
	existing: Dictionary
) -> Dictionary:
	var now := Time.get_datetime_string_from_system(true)
	var record := existing.duplicate(true)
	record["format"] = IDEA_FORMAT
	record["format_version"] = IDEA_FORMAT_VERSION
	record["id"] = local_id
	record["title"] = str(entry.get("title", "Untitled idea"))
	record["concept"] = render_entry_for_generation(entry)
	record["notes"] = "\n".join(_string_list(entry.get("notes", [])))
	record["tags"] = _string_list(entry.get("tags", []))
	record["character_name"] = str(record.get("character_name", ""))
	record["character_role"] = _kind_label(str(entry.get("kind", "seed")))
	record["source_anchor"] = str(pack.get("title", "Idea Pack"))
	record["roleplay_hook"] = _first_nonempty(entry, ["opening_beat", "setup", "core_premise", "summary"])
	if existing.is_empty():
		record["created_at"] = now
		record["archived"] = false
		record["notebook_id"] = notebook_id
	else:
		record["created_at"] = str(existing.get("created_at", now))
		if not notebook_id.is_empty():
			record["notebook_id"] = notebook_id
	record["updated_at"] = now
	var classification: Dictionary = entry.get("classification", {})
	record["source"] = {
		"type": "idea_pack",
		"seed_prompt": "",
		"idea_pack": {
			"pack_id": str(pack.get("id", "")),
			"pack_title": str(pack.get("title", "")),
			"source_bible": str(classification.get("bible", "")),
			"source_version": str(pack.get("source_version", "")),
			"original_id": str(entry.get("id", "")),
			"imported_at": now,
			"schema_version": schema_version
		}
	}
	record["structured_idea"] = {
		"format": FORMAT_ID,
		"schema_version": schema_version,
		"pack": pack.duplicate(true),
		"entry": entry.duplicate(true)
	}
	return record


func _commit_atomic(plans: Array[Dictionary]) -> Dictionary:
	_ensure_directories()
	var transaction_id := "%d-%s" % [Time.get_ticks_usec(), _new_id().left(10)]
	var transaction_root := _root_dir.path_join("transactions").path_join(transaction_id)
	var stage_dir := transaction_root.path_join("stage")
	var backup_dir := transaction_root.path_join("backup")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stage_dir))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(backup_dir))
	var staged: Array[Dictionary] = []
	for plan in plans:
		var local_id := str(plan.get("local_id", ""))
		var record: Dictionary = plan.get("record", {})
		var file_name := _file_name(local_id)
		var stage_path := stage_dir.path_join(file_name)
		var write_result := _write_json(stage_path, record)
		if not bool(write_result.get("ok", false)):
			_remove_tree(transaction_root)
			return {"ok": false, "error": "CCF could not stage the complete Idea Pack. No ideas were changed."}
		var verification := _read_json(stage_path)
		if not bool(verification.get("ok", false)):
			_remove_tree(transaction_root)
			return {"ok": false, "error": "A staged idea failed JSON verification. No ideas were changed."}
		staged.append({
			"action": str(plan.get("action", "import")),
			"local_id": local_id,
			"stage": stage_path,
			"target": _ideas_dir.path_join(file_name),
			"backup": backup_dir.path_join(file_name),
			"had_existing": FileAccess.file_exists(_ideas_dir.path_join(file_name))
		})
	var committed: Array[Dictionary] = []
	for item in staged:
		var target_absolute := ProjectSettings.globalize_path(str(item.get("target", "")))
		var backup_absolute := ProjectSettings.globalize_path(str(item.get("backup", "")))
		var stage_absolute := ProjectSettings.globalize_path(str(item.get("stage", "")))
		if bool(item.get("had_existing", false)):
			var backup_error := DirAccess.rename_absolute(target_absolute, backup_absolute)
			if backup_error != OK:
				_rollback(committed)
				_remove_tree(transaction_root)
				return {"ok": false, "error": "CCF could not prepare an existing idea for replacement. No ideas were changed."}
		var replace_error := DirAccess.rename_absolute(stage_absolute, target_absolute)
		if replace_error != OK:
			if bool(item.get("had_existing", false)):
				DirAccess.rename_absolute(backup_absolute, target_absolute)
			_rollback(committed)
			_remove_tree(transaction_root)
			return {"ok": false, "error": "CCF could not commit the complete Idea Pack. The previous notebook was restored."}
		committed.append(item)
	var imported := 0
	var replaced := 0
	var copies := 0
	for item in committed:
		match str(item.get("action", "import")):
			"replace": replaced += 1
			"keep_both": copies += 1
			_: imported += 1
	_remove_tree(transaction_root)
	return {
		"ok": true,
		"imported": imported,
		"replaced": replaced,
		"copies": copies,
		"total": committed.size()
	}


func _rollback(committed: Array[Dictionary]) -> void:
	for index in range(committed.size() - 1, -1, -1):
		var item: Dictionary = committed[index]
		var target_absolute := ProjectSettings.globalize_path(str(item.get("target", "")))
		var backup_absolute := ProjectSettings.globalize_path(str(item.get("backup", "")))
		if FileAccess.file_exists(target_absolute):
			DirAccess.remove_absolute(target_absolute)
		if bool(item.get("had_existing", false)) and FileAccess.file_exists(backup_absolute):
			DirAccess.rename_absolute(backup_absolute, target_absolute)


func _append_cross_link_warnings(entries: Array[Dictionary], warnings: Array[Dictionary]) -> void:
	var known := {}
	for entry in entries:
		if str(entry.get("kind", "")) != "series":
			continue
		known[str(entry.get("id", "")).to_lower()] = true
		known[str(entry.get("title", "")).to_lower()] = true
	for entry_index in range(entries.size()):
		var entry := entries[entry_index]
		var classification: Dictionary = entry.get("classification", {})
		for cross_link in _string_list(classification.get("cross_links", [])):
			if not known.has(cross_link.to_lower()):
				warnings.append(_entry_issue(
					"unknown_cross_link",
					"Entry '%s' links to '%s', which is not a Series in this pack." % [str(entry.get("id", "")), cross_link],
					entry_index,
					str(entry.get("id", ""))
				))


func _summary(entries: Array[Dictionary]) -> Dictionary:
	var result := {"series": 0, "seeds": 0, "other": 0, "total": entries.size()}
	for entry in entries:
		match str(entry.get("kind", "")):
			"series": result["series"] = int(result["series"]) + 1
			"seed": result["seeds"] = int(result["seeds"]) + 1
			_: result["other"] = int(result["other"]) + 1
	return result


func _entry_has_no_premise(entry: Dictionary) -> bool:
	return (
		str(entry.get("summary", "")).is_empty()
		and str(entry.get("core_premise", "")).is_empty()
		and str(entry.get("setup", "")).is_empty()
	)


func _fatal_result(code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"import_allowed": false,
		"format": "",
		"schema_version": 0,
		"pack": {},
		"entries": [],
		"analysed_entries": [],
		"errors": [_issue(code, message)],
		"warnings": [],
		"summary": {"series": 0, "seeds": 0, "other": 0, "total": 0},
		"conflict_summary": {"new": 0, "updates": 0, "conflicts": 0, "title_warnings": 0}
	}


func _issue(code: String, message: String) -> Dictionary:
	return {"code": code, "message": message}


func _entry_issue(code: String, message: String, entry_index: int, entry_id: String = "") -> Dictionary:
	return {"code": code, "message": message, "entry_index": entry_index, "entry_id": entry_id}


func _string_list(value: Variant) -> Array[String]:
	var raw_values: Array = []
	if value is Array:
		raw_values = value
	elif value is PackedStringArray:
		raw_values = Array(value)
	elif value != null and not str(value).strip_edges().is_empty():
		raw_values = [value]
	var result: Array[String] = []
	for raw_value in raw_values:
		var clean := str(raw_value).strip_edges()
		if not clean.is_empty():
			result.append(clean)
	return result


func _first_nonempty(data: Dictionary, keys: Array) -> String:
	for key_value in keys:
		var value := str(data.get(str(key_value), "")).strip_edges()
		if not value.is_empty():
			return value
	return ""


func _kind_label(kind: String) -> String:
	match kind:
		"series": return "Idea Pack Series"
		"character_note": return "Idea Pack Character Note"
		"seed": return "Idea Pack Seed"
		_: return "Idea Pack %s" % kind.capitalize()


func _normalised_title(value: String) -> String:
	return " ".join(value.strip_edges().to_lower().split(" ", false))


func _local_id_set() -> Dictionary:
	var result := {}
	for idea in list_local_ideas(true):
		result[str(idea.get("id", ""))] = true
	return result


func _new_unique_local_id(occupied_ids: Dictionary) -> String:
	var candidate := _new_id()
	while occupied_ids.has(candidate):
		candidate = _new_id()
	return candidate


func _new_id() -> String:
	var crypto := Crypto.new()
	return crypto.generate_random_bytes(16).hex_encode()


func _ensure_directories() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_root_dir))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_ideas_dir))


func _file_name(local_id: String) -> String:
	return "%s.json" % local_id.validate_filename()


func _idea_path(local_id: String) -> String:
	return _ideas_dir.path_join(_file_name(local_id))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "File does not exist: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read %s." % path}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return {"ok": false, "error": "Invalid JSON in %s." % path}
	return {"ok": true, "data": json.data}


func _write_json(path: String, data: Dictionary) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not write %s." % path}
	file.store_string(JSON.stringify(data, "  "))
	file.store_string("\n")
	file.flush()
	file.close()
	return {"ok": true}


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(absolute)
	if directory == null:
		return
	directory.list_dir_begin()
	var item_name := directory.get_next()
	while not item_name.is_empty():
		if item_name != "." and item_name != "..":
			var child := absolute.path_join(item_name)
			if directory.current_is_dir():
				_remove_tree(child)
			else:
				DirAccess.remove_absolute(child)
		item_name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)
