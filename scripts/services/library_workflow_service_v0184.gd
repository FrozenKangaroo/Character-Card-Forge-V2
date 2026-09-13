class_name CCFLibraryWorkflowServiceV0184
extends RefCounted

const VERSION := "0.18.4"
const SETTINGS_FORMAT_VERSION := 1
const SETTINGS_FILE := CCFStorageService.SETTINGS_DIR + "/library_workflow_v0184.json"
const ACTIVITY_LIMIT := 60
const WORKFLOW_STATES := [
	"draft", "needs_review", "testing", "stable", "published", "archived"
]
const PRIVACY_MARKERS := ["adult", "private"]


static func capabilities() -> Dictionary:
	return {
		"private_notes": true,
		"workflow_states": WORKFLOW_STATES.duplicate(),
		"archive_recovery": true,
		"privacy_presentation_policy": ["show", "blur", "hide"],
		"saved_searches": true,
		"smart_collections": true,
		"recent_activity": true,
		"exact_duplicate_evidence": true,
		"probable_duplicate_evidence": true,
		"explicit_duplicate_decisions": true,
		"batch_validation": true,
		"batch_export": true,
		"multi_project_group_assembly": true,
		"direct_database_writes": false,
		"automatic_merge_or_delete": false
	}


static func workflow_metadata(project: Dictionary) -> Dictionary:
	var metadata_value: Variant = project.get("metadata", {})
	var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
	return _normalise_workflow_metadata(metadata.get("library", {}))


static func set_workflow_metadata(
	project_ids: Array[String], changes: Dictionary
) -> Dictionary:
	if project_ids.is_empty():
		return {"ok": false, "error": "Select at least one project."}
	var updated_count := 0
	var failures: Array[String] = []
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not bool(loaded.get("ok", false)):
			failures.append(project_id)
			continue
		var project: Dictionary = loaded.get("data", {})
		var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
		var library_data := _normalise_workflow_metadata(metadata.get("library", {}))
		if changes.has("workflow_state"):
			var workflow_state := str(changes.get("workflow_state", "draft")).to_lower()
			if workflow_state not in WORKFLOW_STATES:
				failures.append(project_id)
				continue
			library_data["workflow_state"] = workflow_state
			if workflow_state == "archived":
				library_data["archived"] = true
		if changes.has("notes"):
			library_data["notes"] = str(changes.get("notes", ""))
		if changes.has("archived"):
			library_data["archived"] = bool(changes.get("archived", false))
			if bool(library_data.get("archived", false)):
				library_data["workflow_state"] = "archived"
			elif str(library_data.get("workflow_state", "")) == "archived":
				library_data["workflow_state"] = "draft"
		if changes.has("privacy_markers"):
			library_data["privacy_markers"] = _privacy_markers(
				changes.get("privacy_markers", [])
			)
		metadata["library"] = library_data
		project["metadata"] = metadata
		var saved := CCFStorageService.save_project(project)
		if bool(saved.get("ok", false)):
			updated_count += 1
		else:
			failures.append(project_id)
	CCFLibraryService.invalidate_index()
	return {
		"ok": failures.is_empty(),
		"updated": updated_count,
		"failures": failures,
		"error": "Some projects could not be updated." if not failures.is_empty() else ""
	}


static func archive_projects(project_ids: Array[String], archived: bool) -> Dictionary:
	return set_workflow_metadata(project_ids, {"archived": archived})


static func load_local_state() -> Dictionary:
	var defaults := {
		"format_version": SETTINGS_FORMAT_VERSION,
		"saved_views": [],
		"activity": {},
		"ignored_duplicate_keys": [],
		"duplicate_decisions": []
	}
	if not FileAccess.file_exists(SETTINGS_FILE):
		return defaults
	var file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file == null:
		return defaults
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return defaults
	for key_value in defaults.keys():
		if parsed.has(key_value):
			defaults[key_value] = parsed.get(key_value)
	defaults["format_version"] = SETTINGS_FORMAT_VERSION
	return defaults


static func save_view(view_name: String, rules: Dictionary, smart: bool = true) -> Dictionary:
	var clean_name := view_name.strip_edges()
	if clean_name.is_empty():
		return {"ok": false, "error": "Enter a name for the saved view."}
	var state := load_local_state()
	var saved_views: Array = state.get("saved_views", []).duplicate(true)
	var view_id := "view_%s" % Crypto.new().generate_random_bytes(8).hex_encode()
	for index in range(saved_views.size()):
		if not saved_views[index] is Dictionary:
			continue
		if str(saved_views[index].get("name", "")).nocasecmp_to(clean_name) == 0:
			view_id = str(saved_views[index].get("view_id", view_id))
			saved_views.remove_at(index)
			break
	var saved_view := {
		"view_id": view_id,
		"name": clean_name,
		"kind": "smart_collection" if smart else "saved_search",
		"rules": _clean_rules(rules),
		"updated_at": Time.get_datetime_string_from_system(true)
	}
	saved_views.append(saved_view)
	saved_views.sort_custom(
		func(first: Variant, second: Variant) -> bool:
			return str(first.get("name", "")).naturalnocasecmp_to(
				str(second.get("name", ""))
			) < 0
	)
	state["saved_views"] = saved_views
	var written := _write_local_state(state)
	written["view"] = saved_view
	return written


static func delete_saved_view(view_id: String) -> Dictionary:
	var state := load_local_state()
	var kept: Array = []
	for saved_value in state.get("saved_views", []):
		if saved_value is Dictionary and str(saved_value.get("view_id", "")) == view_id:
			continue
		kept.append(saved_value)
	state["saved_views"] = kept
	return _write_local_state(state)


static func record_activity(
	project_id: String, activity_type: String, detail: String = ""
) -> Dictionary:
	var clean_project_id := project_id.strip_edges()
	if clean_project_id.is_empty():
		return {"ok": false, "error": "A project ID is required."}
	var state := load_local_state()
	var activity_value: Variant = state.get("activity", {})
	var activity: Dictionary = (
		activity_value.duplicate(true) if activity_value is Dictionary else {}
	)
	var entries: Array = []
	var existing_value: Variant = activity.get(clean_project_id, [])
	if existing_value is Array:
		entries = existing_value.duplicate(true)
	entries.push_front({
		"type": activity_type.strip_edges().to_lower(),
		"detail": detail.strip_edges(),
		"at": Time.get_datetime_string_from_system(true)
	})
	if entries.size() > ACTIVITY_LIMIT:
		entries.resize(ACTIVITY_LIMIT)
	activity[clean_project_id] = entries
	state["activity"] = activity
	return _write_local_state(state)


static func recent_project_ids(limit: int = 20) -> Array[String]:
	var state := load_local_state()
	var activity_value: Variant = state.get("activity", {})
	if not activity_value is Dictionary:
		return []
	var rows: Array[Dictionary] = []
	for project_id_value in activity_value.keys():
		var entries_value: Variant = activity_value.get(project_id_value, [])
		if not entries_value is Array or entries_value.is_empty():
			continue
		var first_value: Variant = entries_value[0]
		if first_value is Dictionary:
			rows.append({
				"project_id": str(project_id_value),
				"at": str(first_value.get("at", ""))
			})
	rows.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return str(first.get("at", "")) > str(second.get("at", ""))
	)
	var result: Array[String] = []
	for row in rows:
		if result.size() >= limit:
			break
		result.append(str(row.get("project_id", "")))
	return result


static func enhance_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var local_state := load_local_state()
	var activity_value: Variant = local_state.get("activity", {})
	var activity: Dictionary = activity_value if activity_value is Dictionary else {}
	for source_row in rows:
		var row := source_row.duplicate(true)
		var project_id := str(row.get("project_id", ""))
		var loaded := CCFStorageService.load_project(project_id)
		if not bool(loaded.get("ok", false)):
			result.append(row)
			continue
		var project: Dictionary = loaded.get("data", {})
		var workflow := workflow_metadata(project)
		row.merge(workflow, true)
		row["sensitive"] = not _privacy_markers(
			workflow.get("privacy_markers", [])
		).is_empty()
		var review_state := _project_review_state(project)
		row.merge(review_state, true)
		var token_total := 0
		var missing_assets := 0
		var has_front_porch_data := false
		for character_value in project.get("characters", []):
			if not character_value is Dictionary:
				continue
			var character_id := str(character_value.get("character_id", ""))
			token_total += int(
				CCFCardInspectionServiceV0182.token_report(project, character_id).get(
					"total_tokens", 0
				)
			)
			var asset_result := CCFCardInspectionServiceV0182.missing_asset_report(
				project, character_id
			)
			missing_assets += int(asset_result.get("findings", []).size())
			if _character_has_front_porch_data(character_value):
				has_front_porch_data = true
		row["token_total"] = token_total
		row["missing_asset_count"] = missing_assets
		row["front_porch_state"] = "has_data" if has_front_porch_data else "none"
		var project_activity_value: Variant = activity.get(project_id, [])
		var project_activity: Array = (
			project_activity_value if project_activity_value is Array else []
		)
		row["last_used_at"] = (
			str(project_activity[0].get("at", ""))
			if not project_activity.is_empty() and project_activity[0] is Dictionary
			else ""
		)
		var notices: Array[String] = []
		if bool(row.get("review_stale", false)):
			notices.append("AI Review is stale")
		if missing_assets > 0:
			notices.append("%d missing asset notice(s)" % missing_assets)
		if str(row.get("portrait_source_path", "")).is_empty():
			notices.append("No library artwork")
		row["notices"] = notices
		row["search_text"] = "%s\n%s\n%s\n%s" % [
			str(row.get("search_text", "")),
			str(workflow.get("notes", "")).to_lower(),
			str(workflow.get("workflow_state", "draft")),
			" ".join(_privacy_markers(workflow.get("privacy_markers", [])))
		]
		result.append(row)
	return result


static func row_matches_rules(row: Dictionary, rules: Dictionary) -> bool:
	var query := str(rules.get("query", "")).strip_edges().to_lower()
	if not query.is_empty() and not str(row.get("search_text", "")).contains(query):
		return false
	var workflow_state := str(rules.get("workflow_state", "")).strip_edges()
	if not workflow_state.is_empty() and str(row.get("workflow_state", "")) != workflow_state:
		return false
	var review_state := str(rules.get("review_state", "")).strip_edges()
	if not review_state.is_empty() and str(row.get("review_state", "")) != review_state:
		return false
	var tag_text := str(rules.get("tag", "")).strip_edges()
	if not tag_text.is_empty() and not _contains_case_insensitive(row.get("all_tags", []), tag_text):
		return false
	var token_range := str(rules.get("token_range", "")).strip_edges()
	var token_total := int(row.get("token_total", 0))
	if token_range == "under_4k" and token_total >= 4000:
		return false
	if token_range == "4k_12k" and (token_total < 4000 or token_total > 12000):
		return false
	if token_range == "over_12k" and token_total <= 12000:
		return false
	var front_porch_state := str(rules.get("front_porch_state", "")).strip_edges()
	if not front_porch_state.is_empty() and str(row.get("front_porch_state", "")) != front_porch_state:
		return false
	if bool(rules.get("favorites_only", false)):
		if not bool(row.get("favorite", false)) and int(row.get("favorite_character_count", 0)) <= 0:
			return false
	if bool(rules.get("recent_only", false)):
		if str(row.get("last_used_at", "")).is_empty():
			return false
	return true


static func scan_duplicates(project_ids: Array[String] = []) -> Dictionary:
	var target_ids := project_ids.duplicate()
	if target_ids.is_empty():
		for folder_project_id in DirAccess.get_directories_at(CCFStorageService.characters_dir()):
			target_ids.append(folder_project_id)
	var fingerprints: Array[Dictionary] = []
	for project_id in target_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not bool(loaded.get("ok", false)):
			continue
		var project: Dictionary = loaded.get("data", {})
		for character_value in project.get("characters", []):
			if not character_value is Dictionary:
				continue
			var character: Dictionary = character_value
			var character_id := str(character.get("character_id", ""))
			fingerprints.append({
				"project_id": project_id,
				"project_name": str(project.get("metadata", {}).get("name", "Untitled Project")),
				"character_id": character_id,
				"character_name": CCFStorageService.character_display_name(character),
				"stable_id": character_id,
				"content_digest": JSON.stringify(
					_exact_content_payload(character)
				).sha256_text(),
				"image_digest": _character_image_digest(project_id, character),
				"tokens": _comparison_tokens(character)
			})
	var ignored: Array[String] = _string_array(
		load_local_state().get("ignored_duplicate_keys", [])
	)
	var matches: Array[Dictionary] = []
	for first_index in range(fingerprints.size()):
		for second_index in range(first_index + 1, fingerprints.size()):
			var first := fingerprints[first_index]
			var second := fingerprints[second_index]
			var evidence: Array[String] = []
			var match_type := ""
			if str(first.get("stable_id", "")) == str(second.get("stable_id", "")):
				match_type = "exact"
				evidence.append("Same stable character ID")
			if str(first.get("content_digest", "")) == str(second.get("content_digest", "")):
				match_type = "exact"
				evidence.append("Same normalized Character Card content hash")
			var first_image := str(first.get("image_digest", ""))
			if not first_image.is_empty() and first_image == str(second.get("image_digest", "")):
				match_type = "exact"
				evidence.append("Same artwork hash")
			var similarity := _jaccard_similarity(
				first.get("tokens", []), second.get("tokens", [])
			)
			var same_name := str(first.get("character_name", "")).strip_edges().nocasecmp_to(
				str(second.get("character_name", "")).strip_edges()
			) == 0
			if match_type.is_empty() and same_name and similarity >= 0.55:
				match_type = "probable"
				evidence.append("Same normalized name")
				evidence.append("Text similarity %.0f%%" % (similarity * 100.0))
			elif match_type.is_empty() and similarity >= 0.82:
				match_type = "probable"
				evidence.append("Text similarity %.0f%%" % (similarity * 100.0))
			if match_type.is_empty():
				continue
			var duplicate_key := _duplicate_key(first, second)
			if ignored.has(duplicate_key):
				continue
			matches.append({
				"duplicate_key": duplicate_key,
				"type": match_type,
				"confidence": 1.0 if match_type == "exact" else similarity,
				"evidence": evidence,
				"first": first,
				"second": second,
				"allowed_decisions": ["merge", "replace", "ignore", "keep_both"],
				"automatic_action": false
			})
	return {"ok": true, "matches": matches, "scanned_characters": fingerprints.size()}


static func ignore_duplicate(duplicate_key: String) -> Dictionary:
	var state := load_local_state()
	var ignored := _string_array(state.get("ignored_duplicate_keys", []))
	if not ignored.has(duplicate_key):
		ignored.append(duplicate_key)
	state["ignored_duplicate_keys"] = ignored
	return _write_local_state(state)


static func resolve_duplicate(
	duplicate_match: Dictionary, decision: String, preferred_side: String = "first"
) -> Dictionary:
	var clean_decision := decision.strip_edges().to_lower()
	if clean_decision not in ["merge", "replace", "ignore", "keep_both"]:
		return {"ok": false, "error": "Choose Merge, Replace, Ignore or Keep Both."}
	var duplicate_key := str(duplicate_match.get("duplicate_key", ""))
	if duplicate_key.is_empty():
		return {"ok": false, "error": "The duplicate match has no stable evidence key."}
	var preferred_key := "second" if preferred_side == "second" else "first"
	var other_key := "first" if preferred_key == "second" else "second"
	var preferred_value: Variant = duplicate_match.get(preferred_key, {})
	var other_value: Variant = duplicate_match.get(other_key, {})
	if not preferred_value is Dictionary or not other_value is Dictionary:
		return {"ok": false, "error": "The duplicate match is incomplete."}
	var preferred: Dictionary = preferred_value
	var other: Dictionary = other_value
	var preferred_project_id := str(preferred.get("project_id", ""))
	var other_project_id := str(other.get("project_id", ""))
	var result := {"ok": true, "decision": clean_decision, "recoverable": true}
	if clean_decision in ["merge", "replace"]:
		if preferred_project_id == other_project_id:
			return {
				"ok": false,
				"error": "Characters inside the same project must be resolved in the project workspace. No data was changed."
			}
		if clean_decision == "merge":
			var merge_result := _merge_project_organisation(
				preferred_project_id, other_project_id
			)
			if not bool(merge_result.get("ok", false)):
				return merge_result
		var archive_result := archive_projects([other_project_id], true)
		if not bool(archive_result.get("ok", false)):
			return archive_result
		result["archived_project_id"] = other_project_id
		result["message"] = (
			"Organisation merged and the duplicate project archived."
			if clean_decision == "merge"
			else "The non-preferred duplicate project was archived."
		)
	var state := load_local_state()
	var ignored := _string_array(state.get("ignored_duplicate_keys", []))
	if not ignored.has(duplicate_key):
		ignored.append(duplicate_key)
	state["ignored_duplicate_keys"] = ignored
	var decisions: Array = state.get("duplicate_decisions", []).duplicate(true)
	decisions.push_front({
		"duplicate_key": duplicate_key,
		"decision": clean_decision,
		"preferred_project_id": preferred_project_id,
		"other_project_id": other_project_id,
		"at": Time.get_datetime_string_from_system(true)
	})
	if decisions.size() > ACTIVITY_LIMIT:
		decisions.resize(ACTIVITY_LIMIT)
	state["duplicate_decisions"] = decisions
	var written := _write_local_state(state)
	if not bool(written.get("ok", false)):
		return written
	CCFLibraryService.invalidate_index()
	return result


static func batch_validate(project_ids: Array[String]) -> Dictionary:
	if project_ids.is_empty():
		return {"ok": false, "error": "Select at least one project."}
	var outcomes: Array[Dictionary] = []
	var total_characters := 0
	var total_warnings := 0
	var total_errors := 0
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not bool(loaded.get("ok", false)):
			outcomes.append({"project_id": project_id, "ok": false, "error": loaded.get("error", "Load failed.")})
			continue
		var project: Dictionary = loaded.get("data", {})
		var character_outcomes: Array[Dictionary] = []
		for character_value in project.get("characters", []):
			if not character_value is Dictionary:
				continue
			var character_id := str(character_value.get("character_id", ""))
			var health := CCFCardInspectionServiceV0182.health_report(project, character_id)
			var counts: Dictionary = health.get("counts", {})
			total_characters += 1
			total_warnings += int(counts.get("warning", 0))
			total_errors += int(counts.get("error", 0))
			character_outcomes.append({
				"character_id": character_id,
				"name": CCFStorageService.character_display_name(character_value),
				"ok": bool(health.get("ok", false)),
				"counts": counts,
				"findings": health.get("findings", [])
			})
		outcomes.append({
			"project_id": project_id,
			"name": str(project.get("metadata", {}).get("name", "Untitled Project")),
			"ok": true,
			"characters": character_outcomes
		})
		record_activity(project_id, "validate", "Library batch validation")
	return {
		"ok": true,
		"project_count": project_ids.size(),
		"character_count": total_characters,
		"warning_count": total_warnings,
		"error_count": total_errors,
		"outcomes": outcomes
	}


static func export_project_packages(
	project_ids: Array[String], destination_directory: String
) -> Dictionary:
	if project_ids.is_empty():
		return {"ok": false, "error": "Select at least one project."}
	DirAccess.make_dir_recursive_absolute(destination_directory)
	var outcomes: Array[Dictionary] = []
	var succeeded := 0
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not bool(loaded.get("ok", false)):
			outcomes.append({"project_id": project_id, "ok": false, "error": loaded.get("error", "Load failed.")})
			continue
		var project: Dictionary = loaded.get("data", {})
		var project_name := str(project.get("metadata", {}).get("name", "Untitled Project"))
		var output_path := destination_directory.path_join(
			"%s-%s.ccfproject" % [_safe_filename(project_name), project_id.left(8)]
		)
		var exported := CCFProjectPackageService.export_project(project, output_path)
		outcomes.append({
			"project_id": project_id,
			"name": project_name,
			"ok": bool(exported.get("ok", false)),
			"path": str(exported.get("path", output_path)),
			"error": str(exported.get("error", ""))
		})
		if bool(exported.get("ok", false)):
			succeeded += 1
			record_activity(project_id, "export", "Library project-package export")
	return {
		"ok": succeeded > 0,
		"succeeded": succeeded,
		"failed": project_ids.size() - succeeded,
		"outcomes": outcomes,
		"error": "No selected project could be exported." if succeeded == 0 else ""
	}


static func export_character_cards(
	project_ids: Array[String], destination_directory: String
) -> Dictionary:
	if project_ids.is_empty():
		return {"ok": false, "error": "Select at least one project."}
	DirAccess.make_dir_recursive_absolute(destination_directory)
	var outcomes: Array[Dictionary] = []
	var succeeded := 0
	var failed := 0
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not bool(loaded.get("ok", false)):
			outcomes.append({"project_id": project_id, "ok": false, "error": loaded.get("error", "Load failed.")})
			failed += 1
			continue
		var project: Dictionary = loaded.get("data", {})
		var project_name := str(project.get("metadata", {}).get("name", "Untitled Project"))
		var character_ids: Array[String] = []
		for character_value in project.get("characters", []):
			if character_value is Dictionary:
				character_ids.append(str(character_value.get("character_id", "")))
		var project_directory := destination_directory.path_join(
			"%s-%s" % [_safe_filename(project_name), project_id.left(8)]
		)
		var exported := CCFCardFormatService.export_characters_json(
			project, character_ids, project_directory
		)
		var exported_count := int(exported.get("count", 0))
		succeeded += exported_count
		failed += exported.get("failures", []).size()
		outcomes.append({
			"project_id": project_id,
			"name": project_name,
			"ok": bool(exported.get("ok", false)),
			"path": project_directory,
			"exported": exported.get("exported", []),
			"failures": exported.get("failures", []),
			"error": str(exported.get("error", ""))
		})
		if bool(exported.get("ok", false)):
			record_activity(project_id, "export", "Library Character Card V2 batch export")
	return {
		"ok": succeeded > 0,
		"succeeded": succeeded,
		"failed": failed,
		"outcomes": outcomes,
		"error": "No selected character passed the existing export-safety checks." if succeeded == 0 else ""
	}


static func create_group_project(
	project_ids: Array[String], group_name: String = ""
) -> Dictionary:
	if project_ids.size() < 2:
		return {"ok": false, "error": "Select at least two projects to create a group."}
	var source_records: Array[Dictionary] = []
	var source_names: Array[String] = []
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not bool(loaded.get("ok", false)):
			return {"ok": false, "error": "Could not load selected project %s." % project_id}
		var source_project: Dictionary = loaded.get("data", {})
		source_names.append(str(source_project.get("metadata", {}).get("name", "Untitled Project")))
		for character_value in source_project.get("characters", []):
			if character_value is Dictionary:
				source_records.append({
					"project_id": project_id,
					"character": character_value
				})
	if source_records.size() < 2:
		return {"ok": false, "error": "The selected projects do not contain at least two characters."}
	var output := CCFStorageService.new_project()
	var output_id := str(output.get("project_id", ""))
	var metadata: Dictionary = output.get("metadata", {}).duplicate(true)
	var clean_group_name := group_name.strip_edges()
	if clean_group_name.is_empty():
		clean_group_name = "Group — %s" % ", ".join(source_names).left(100)
	metadata["name"] = clean_group_name
	metadata["summary"] = "Multi-character project assembled from %d selected library projects." % project_ids.size()
	var library_data := _normalise_workflow_metadata(metadata.get("library", {}))
	library_data["workflow_state"] = "draft"
	library_data["notes"] = "Created from: %s" % ", ".join(source_names)
	metadata["library"] = library_data
	output["metadata"] = metadata
	var copied_characters: Array = []
	var new_ids: Array[String] = []
	var copy_plans: Array[Dictionary] = []
	for source_record in source_records:
		var source_project_id := str(source_record.get("project_id", ""))
		var source_character: Dictionary = source_record.get("character", {})
		var old_character_id := str(source_character.get("character_id", ""))
		var new_character_id := Crypto.new().generate_random_bytes(16).hex_encode()
		var copied_character := source_character.duplicate(true)
		copied_character["character_id"] = new_character_id
		copied_character["created_at"] = Time.get_datetime_string_from_system(true)
		copied_character["updated_at"] = copied_character.get("created_at", "")
		copied_character[CCFRevisionServiceV0181.LINEAGE_KEY] = {
			"kind": "library_group_copy",
			"source_project_id": source_project_id,
			"source_character_id": old_character_id,
			"copied_at": copied_character.get("created_at", "")
		}
		_rewrite_paths_in_value(
			copied_character,
			"characters/%s/" % old_character_id,
			"characters/%s/" % new_character_id
		)
		copied_characters.append(copied_character)
		new_ids.append(new_character_id)
		copy_plans.append({
			"source_project_id": source_project_id,
			"old_character_id": old_character_id,
			"new_character_id": new_character_id
		})
	output["characters"] = copied_characters
	output["workspace"] = {
		"active_character_id": new_ids[0],
		"selected_project_tab": "characters"
	}
	output["card_workflows"] = [{
		"workflow_id": "workflow_%s" % Crypto.new().generate_random_bytes(8).hex_encode(),
		"title": clean_group_name,
		"summary": "Assembled from selected Library projects.",
		"selected_character_ids": new_ids,
		"members": [],
		"shared_scenario": "",
		"opening_message": "",
		"notes": "",
		"front_porch_group": CCFFrontPorchGroupCardServiceV0174.default_group_options(
			output, {"selected_character_ids": new_ids}
		)
	}]
	var saved := CCFStorageService.save_project(output)
	if not bool(saved.get("ok", false)):
		return saved
	var warnings: Array[String] = []
	for copy_plan in copy_plans:
		var source_root := ProjectSettings.globalize_path(
			CCFStorageService.project_folder(str(copy_plan.get("source_project_id", ""))).path_join(
				"characters/%s" % str(copy_plan.get("old_character_id", ""))
			)
		)
		var target_root := ProjectSettings.globalize_path(
			CCFStorageService.project_folder(output_id).path_join(
				"characters/%s" % str(copy_plan.get("new_character_id", ""))
			)
		)
		var copy_error := _copy_directory_contents(source_root, target_root)
		if copy_error != OK and copy_error != ERR_DOES_NOT_EXIST:
			warnings.append("Some assets could not be copied from %s." % source_root)
	CCFLibraryService.invalidate_index()
	record_activity(output_id, "create_group", "%d source projects" % project_ids.size())
	return {
		"ok": true,
		"project_id": output_id,
		"character_count": copied_characters.size(),
		"warnings": warnings
	}


static func batch_report_text(batch_result: Dictionary, heading: String) -> String:
	var lines: Array[String] = [heading, "Generated: %s" % Time.get_datetime_string_from_system(true), ""]
	if batch_result.has("character_count"):
		lines.append("Characters: %d" % int(batch_result.get("character_count", 0)))
		lines.append("Warnings: %d" % int(batch_result.get("warning_count", 0)))
		lines.append("Errors: %d" % int(batch_result.get("error_count", 0)))
	if batch_result.has("succeeded"):
		lines.append("Succeeded: %d" % int(batch_result.get("succeeded", 0)))
		lines.append("Failed: %d" % int(batch_result.get("failed", 0)))
	lines.append("")
	for outcome_value in batch_result.get("outcomes", []):
		if not outcome_value is Dictionary:
			continue
		var outcome: Dictionary = outcome_value
		lines.append("%s — %s" % [
			str(outcome.get("name", outcome.get("project_id", "Project"))),
			"OK" if bool(outcome.get("ok", false)) else "FAILED"
		])
		if not str(outcome.get("path", "")).is_empty():
			lines.append("  %s" % str(outcome.get("path", "")))
		if not str(outcome.get("error", "")).is_empty():
			lines.append("  %s" % str(outcome.get("error", "")))
		for exported_path_value in outcome.get("exported", []):
			lines.append("  Exported: %s" % str(exported_path_value))
		for failure_value in outcome.get("failures", []):
			lines.append("  Failed: %s" % str(failure_value))
		for character_value in outcome.get("characters", []):
			if character_value is Dictionary:
				var counts: Dictionary = character_value.get("counts", {})
				lines.append("  %s: %d warning(s), %d error(s)" % [
					str(character_value.get("name", "Character")),
					int(counts.get("warning", 0)),
					int(counts.get("error", 0))
				])
	return "\n".join(lines)


static func _normalise_workflow_metadata(raw_value: Variant) -> Dictionary:
	var result := {
		"folder": "",
		"collections": [],
		"workflow_state": "draft",
		"notes": "",
		"archived": false,
		"privacy_markers": []
	}
	if raw_value is Dictionary:
		result["folder"] = str(raw_value.get("folder", "")).strip_edges()
		result["collections"] = _string_array(raw_value.get("collections", []))
		var workflow_state := str(raw_value.get("workflow_state", "draft")).to_lower()
		result["workflow_state"] = workflow_state if workflow_state in WORKFLOW_STATES else "draft"
		result["notes"] = str(raw_value.get("notes", ""))
		result["archived"] = bool(raw_value.get("archived", false)) or workflow_state == "archived"
		result["privacy_markers"] = _privacy_markers(raw_value.get("privacy_markers", []))
	return result


static func _merge_project_organisation(
	preferred_project_id: String, other_project_id: String
) -> Dictionary:
	var preferred_loaded := CCFStorageService.load_project(preferred_project_id)
	var other_loaded := CCFStorageService.load_project(other_project_id)
	if not bool(preferred_loaded.get("ok", false)) or not bool(other_loaded.get("ok", false)):
		return {"ok": false, "error": "One of the duplicate projects could not be loaded."}
	var preferred_project: Dictionary = preferred_loaded.get("data", {})
	var other_project: Dictionary = other_loaded.get("data", {})
	var preferred_metadata: Dictionary = preferred_project.get("metadata", {}).duplicate(true)
	var other_metadata: Dictionary = other_project.get("metadata", {})
	var merged_tags := _string_array(preferred_metadata.get("tags", []))
	for tag_text in _string_array(other_metadata.get("tags", [])):
		if not _contains_case_insensitive(merged_tags, tag_text):
			merged_tags.append(tag_text)
	preferred_metadata["tags"] = merged_tags
	var preferred_library := _normalise_workflow_metadata(preferred_metadata.get("library", {}))
	var other_library := _normalise_workflow_metadata(other_metadata.get("library", {}))
	var collections := _string_array(preferred_library.get("collections", []))
	for collection_text in _string_array(other_library.get("collections", [])):
		if not _contains_case_insensitive(collections, collection_text):
			collections.append(collection_text)
	preferred_library["collections"] = collections
	if str(preferred_library.get("notes", "")).strip_edges().is_empty():
		preferred_library["notes"] = str(other_library.get("notes", ""))
	preferred_metadata["library"] = preferred_library
	preferred_project["metadata"] = preferred_metadata
	return CCFStorageService.save_project(preferred_project)


static func _project_review_state(project: Dictionary) -> Dictionary:
	var has_review := false
	var has_stale := false
	for character_value in project.get("characters", []):
		if not character_value is Dictionary:
			continue
		var character_id := str(character_value.get("character_id", ""))
		var latest := CCFAIReviewServiceV0183.latest_review(project, character_id)
		if latest.is_empty():
			continue
		has_review = true
		if CCFAIReviewServiceV0183.review_is_stale(project, character_id, latest):
			has_stale = true
	return {
		"review_state": "stale" if has_stale else ("reviewed" if has_review else "not_reviewed"),
		"review_stale": has_stale,
		"has_review": has_review
	}


static func _character_has_front_porch_data(character: Dictionary) -> bool:
	var card_value: Variant = character.get("character", {})
	if card_value is Dictionary:
		var extensions_value: Variant = card_value.get("card_extensions", {})
		if extensions_value is Dictionary and extensions_value.has("front_porch"):
			return true
	var interoperability_value: Variant = character.get("interoperability", {})
	return (
		interoperability_value is Dictionary
		and JSON.stringify(interoperability_value).to_lower().contains("front_porch")
	)


static func _clean_rules(rules: Dictionary) -> Dictionary:
	return {
		"query": str(rules.get("query", "")).strip_edges(),
		"workflow_state": str(rules.get("workflow_state", "")).strip_edges(),
		"review_state": str(rules.get("review_state", "")).strip_edges(),
		"tag": str(rules.get("tag", "")).strip_edges(),
		"token_range": str(rules.get("token_range", "")).strip_edges(),
		"front_porch_state": str(rules.get("front_porch_state", "")).strip_edges(),
		"favorites_only": bool(rules.get("favorites_only", false)),
		"recent_only": bool(rules.get("recent_only", false))
	}


static func _write_local_state(state: Dictionary) -> Dictionary:
	CCFStorageService.ensure_directories()
	var file := FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not save Library workflow settings."}
	file.store_string(JSON.stringify(state, "  "))
	file.close()
	return {"ok": true, "path": SETTINGS_FILE}


static func _privacy_markers(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	for marker in _string_array(raw_value):
		var clean_marker := marker.to_lower()
		if clean_marker in PRIVACY_MARKERS and not result.has(clean_marker):
			result.append(clean_marker)
	return result


static func _string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_value is Array:
		for item in raw_value:
			var text := str(item).strip_edges()
			if not text.is_empty() and not result.has(text):
				result.append(text)
	return result


static func _contains_case_insensitive(raw_value: Variant, candidate: String) -> bool:
	for text in _string_array(raw_value):
		if text.nocasecmp_to(candidate) == 0:
			return true
	return false


static func _character_image_digest(project_id: String, character: Dictionary) -> String:
	var assets_value: Variant = character.get("assets", {})
	if not assets_value is Dictionary:
		return ""
	var relative_path := str(assets_value.get("portrait", "")).strip_edges()
	if relative_path.is_empty():
		return ""
	var absolute_path := relative_path
	if not relative_path.is_absolute_path():
		absolute_path = ProjectSettings.globalize_path(
			CCFStorageService.project_folder(project_id).path_join(relative_path)
		)
	if not FileAccess.file_exists(absolute_path):
		return ""
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return ""
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hashing.update(bytes) != OK:
		return ""
	return hashing.finish().hex_encode()


static func _comparison_tokens(character: Dictionary) -> Array[String]:
	var card_value: Variant = character.get("character", {})
	var card: Dictionary = card_value if card_value is Dictionary else {}
	var combined := "%s %s %s %s" % [
		str(card.get("name", "")),
		str(card.get("description", "")),
		str(card.get("personality", "")),
		str(card.get("scenario", ""))
	]
	var cleaned := ""
	for character_code in combined.to_lower():
		cleaned += character_code if character_code.is_valid_identifier() or character_code == " " else " "
	var result: Array[String] = []
	for token_value in cleaned.split(" ", false):
		var token_text := str(token_value).strip_edges()
		if token_text.length() >= 3 and not result.has(token_text):
			result.append(token_text)
	return result


static func _exact_content_payload(character: Dictionary) -> Dictionary:
	var card_value: Variant = character.get("character", {})
	var card: Dictionary = (
		card_value.duplicate(true) if card_value is Dictionary else {}
	)
	var metadata_value: Variant = character.get("metadata", {})
	var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
	return {
		"card": card,
		"name": str(metadata.get("name", "")),
		"summary": str(metadata.get("summary", "")),
		"role": str(metadata.get("role", "")),
		"creator": str(metadata.get("creator", "")),
		"character_version": str(metadata.get("character_version", "")),
		"tags": _string_array(metadata.get("tags", []))
	}


static func _jaccard_similarity(first_value: Variant, second_value: Variant) -> float:
	var first := _string_array(first_value)
	var second := _string_array(second_value)
	if first.is_empty() or second.is_empty():
		return 0.0
	var intersection := 0
	var union_values := first.duplicate()
	for token_text in second:
		if first.has(token_text):
			intersection += 1
		if not union_values.has(token_text):
			union_values.append(token_text)
	return float(intersection) / float(maxi(1, union_values.size()))


static func _duplicate_key(first: Dictionary, second: Dictionary) -> String:
	var identities: Array[String] = [
		"%s:%s" % [str(first.get("project_id", "")), str(first.get("character_id", ""))],
		"%s:%s" % [str(second.get("project_id", "")), str(second.get("character_id", ""))]
	]
	identities.sort()
	return "|".join(identities).sha256_text()


static func _safe_filename(value: String) -> String:
	var clean_value := value.strip_edges()
	for invalid_character in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		clean_value = clean_value.replace(invalid_character, "_")
	return clean_value if not clean_value.is_empty() else "Untitled Project"


static func _rewrite_paths_in_value(value: Variant, old_prefix: String, new_prefix: String) -> void:
	if value is Dictionary:
		for key_value in value.keys():
			var child_value: Variant = value.get(key_value)
			if child_value is String and str(child_value).begins_with(old_prefix):
				value[key_value] = new_prefix + str(child_value).trim_prefix(old_prefix)
			elif child_value is Dictionary or child_value is Array:
				_rewrite_paths_in_value(child_value, old_prefix, new_prefix)
	elif value is Array:
		for index in range(value.size()):
			var child_value: Variant = value[index]
			if child_value is String and str(child_value).begins_with(old_prefix):
				value[index] = new_prefix + str(child_value).trim_prefix(old_prefix)
			elif child_value is Dictionary or child_value is Array:
				_rewrite_paths_in_value(child_value, old_prefix, new_prefix)


static func _copy_directory_contents(source_path: String, target_path: String) -> Error:
	if not DirAccess.dir_exists_absolute(source_path):
		return ERR_DOES_NOT_EXIST
	DirAccess.make_dir_recursive_absolute(target_path)
	var source_directory := DirAccess.open(source_path)
	if source_directory == null:
		return ERR_CANT_OPEN
	source_directory.list_dir_begin()
	var entry_name := source_directory.get_next()
	while not entry_name.is_empty():
		if entry_name != "." and entry_name != "..":
			var source_entry := source_path.path_join(entry_name)
			var target_entry := target_path.path_join(entry_name)
			if source_directory.current_is_dir():
				var nested_error := _copy_directory_contents(source_entry, target_entry)
				if nested_error != OK:
					source_directory.list_dir_end()
					return nested_error
			else:
				var copy_error := DirAccess.copy_absolute(source_entry, target_entry)
				if copy_error != OK:
					source_directory.list_dir_end()
					return copy_error
		entry_name = source_directory.get_next()
	source_directory.list_dir_end()
	return OK
