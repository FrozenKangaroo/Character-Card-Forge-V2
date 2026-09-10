class_name CCFRevisionServiceV0181
extends RefCounted

const FORMAT_VERSION := 1
const DEFAULT_RETENTION := 50
const MIN_RETENTION := 5
const MAX_RETENTION := 500
const HISTORY_KEY := "revision_history"
const LINEAGE_KEY := "revision_lineage"


static func ensure_history(character_record: Dictionary) -> Dictionary:
	var history_value: Variant = character_record.get(HISTORY_KEY, {})
	var history: Dictionary = (
		(history_value as Dictionary).duplicate(true)
		if history_value is Dictionary
		else {}
	)
	history["format_version"] = FORMAT_VERSION
	history["retention_limit"] = clampi(
		int(history.get("retention_limit", DEFAULT_RETENTION)),
		MIN_RETENTION,
		MAX_RETENTION
	)
	history["include_in_packages"] = bool(
		history.get("include_in_packages", true)
	)
	var entries_value: Variant = history.get("entries", [])
	history["entries"] = (
		(entries_value as Array).duplicate(true)
		if entries_value is Array
		else []
	)
	character_record[HISTORY_KEY] = history
	return history


static func create_checkpoint(
	character_record: Dictionary,
	checkpoint_label: String,
	checkpoint_note: String = "",
	checkpoint_reason: String = "manual",
	provenance: Dictionary = {},
	force: bool = false
) -> Dictionary:
	if character_record.is_empty():
		return {"ok": false, "error": "No character is available to checkpoint."}
	var history := ensure_history(character_record)
	var snapshot := snapshot_character(character_record)
	var content_digest := _content_digest(snapshot)
	var entries: Array = history.get("entries", []).duplicate(true)
	if not force and not entries.is_empty():
		var newest_value: Variant = entries[-1]
		if (
			newest_value is Dictionary
			and str((newest_value as Dictionary).get("content_hash", ""))
			== content_digest
		):
			return {
				"ok": true,
				"created": false,
				"duplicate": true,
				"revision": (newest_value as Dictionary).duplicate(true)
			}
	var clean_label := checkpoint_label.strip_edges()
	if clean_label.is_empty():
		clean_label = "Checkpoint"
	var revision := {
		"revision_id": _new_id(),
		"created_at": Time.get_datetime_string_from_system(true),
		"label": clean_label,
		"note": checkpoint_note.strip_edges(),
		"reason": checkpoint_reason.strip_edges(),
		"provenance": provenance.duplicate(true),
		"content_hash": content_digest,
		"snapshot": snapshot
	}
	entries.append(revision)
	var retention_limit := int(history.get("retention_limit", DEFAULT_RETENTION))
	while entries.size() > retention_limit:
		entries.pop_front()
	history["entries"] = entries
	character_record[HISTORY_KEY] = history
	return {"ok": true, "created": true, "duplicate": false, "revision": revision}


static func snapshot_character(character_record: Dictionary) -> Dictionary:
	var snapshot := character_record.duplicate(true)
	snapshot.erase(HISTORY_KEY)
	# AI Review history is private workflow evidence and may itself refer to
	# revisions. Keeping it out prevents recursive checkpoint growth.
	snapshot.erase("ai_review_v0183")
	snapshot.erase("updated_at")
	return snapshot


static func list_revisions(character_record: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var history_value: Variant = character_record.get(HISTORY_KEY, {})
	if not history_value is Dictionary:
		return result
	var entries_value: Variant = (history_value as Dictionary).get("entries", [])
	if not entries_value is Array:
		return result
	for entry_value in entries_value:
		if entry_value is Dictionary:
			result.append((entry_value as Dictionary).duplicate(true))
	return result


static func get_revision(
	character_record: Dictionary, revision_id: String
) -> Dictionary:
	for revision in list_revisions(character_record):
		if str(revision.get("revision_id", "")) == revision_id:
			return revision
	return {}


static func compare_snapshots(
	left_snapshot: Dictionary, right_snapshot: Dictionary
) -> Array[Dictionary]:
	var left_flat: Dictionary = {}
	var right_flat: Dictionary = {}
	_flatten_for_diff(left_snapshot, "", left_flat)
	_flatten_for_diff(right_snapshot, "", right_flat)
	var keys: Array[String] = []
	for key_value in left_flat.keys():
		keys.append(str(key_value))
	for key_value in right_flat.keys():
		var key_text := str(key_value)
		if not keys.has(key_text):
			keys.append(key_text)
	keys.sort()
	var changes: Array[Dictionary] = []
	for field_path in keys:
		var left_exists := left_flat.has(field_path)
		var right_exists := right_flat.has(field_path)
		var left_value: Variant = left_flat.get(field_path)
		var right_value: Variant = right_flat.get(field_path)
		if left_exists == right_exists and left_value == right_value:
			continue
		changes.append({
			"path": field_path,
			"left_exists": left_exists,
			"right_exists": right_exists,
			"left": left_value,
			"right": right_value
		})
	return changes


static func restore_revision(
	project: Dictionary, character_id: String, revision_id: String
) -> Dictionary:
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0:
		return {"ok": false, "error": "The selected character could not be found."}
	var characters: Array = project.get("characters", []).duplicate(true)
	var current_record: Dictionary = (characters[index] as Dictionary).duplicate(true)
	var revision := get_revision(current_record, revision_id)
	if revision.is_empty():
		return {"ok": false, "error": "The selected revision could not be found."}
	create_checkpoint(
		current_record,
		"Before restore",
		"Automatic recovery point created before restoring an earlier revision.",
		"pre_restore",
		{},
		true
	)
	var history := ensure_history(current_record).duplicate(true)
	var snapshot_value: Variant = revision.get("snapshot", {})
	if not snapshot_value is Dictionary:
		return {"ok": false, "error": "The selected revision has no valid snapshot."}
	var restored := (snapshot_value as Dictionary).duplicate(true)
	restored["character_id"] = character_id
	restored["created_at"] = str(current_record.get("created_at", ""))
	restored["updated_at"] = Time.get_datetime_string_from_system(true)
	restored[HISTORY_KEY] = history
	create_checkpoint(
		restored,
		"Restored: %s" % str(revision.get("label", "Revision")),
		"Restore created a new current revision; earlier history was preserved.",
		"restore",
		{"source_revision_id": revision_id},
		true
	)
	characters[index] = restored
	project["characters"] = characters
	return {"ok": true, "character": restored.duplicate(true)}


static func fork_revision(
	project: Dictionary,
	character_id: String,
	revision_id: String,
	requested_name: String = ""
) -> Dictionary:
	var source := CCFStorageService.get_character(project, character_id)
	var revision := get_revision(source, revision_id)
	if revision.is_empty():
		return {"ok": false, "error": "The selected revision could not be found."}
	var snapshot_value: Variant = revision.get("snapshot", {})
	if not snapshot_value is Dictionary:
		return {"ok": false, "error": "The selected revision has no valid snapshot."}
	var forked := (snapshot_value as Dictionary).duplicate(true)
	var forked_id := _new_id()
	var now_text := Time.get_datetime_string_from_system(true)
	forked["character_id"] = forked_id
	forked["created_at"] = now_text
	forked["updated_at"] = now_text
	var chosen_name := requested_name.strip_edges()
	if chosen_name.is_empty():
		chosen_name = "%s (Revision)" % CCFStorageService.character_display_name(source)
	var card_data: Dictionary = forked.get("character", {}).duplicate(true)
	card_data["name"] = chosen_name
	forked["character"] = card_data
	var metadata: Dictionary = forked.get("metadata", {}).duplicate(true)
	metadata["name"] = chosen_name
	forked["metadata"] = metadata
	forked[LINEAGE_KEY] = {
		"source_project_id": str(project.get("project_id", "")),
		"source_character_id": character_id,
		"source_revision_id": revision_id,
		"created_at": now_text
	}
	forked.erase(HISTORY_KEY)
	create_checkpoint(
		forked,
		"Forked from %s" % str(revision.get("label", "Revision")),
		"Initial checkpoint for this derived character.",
		"fork",
		forked[LINEAGE_KEY],
		true
	)
	var characters: Array = project.get("characters", []).duplicate(true)
	characters.append(forked)
	project["characters"] = characters
	return {"ok": true, "character_id": forked_id, "character": forked.duplicate(true)}


static func apply_selected_paths(
	project: Dictionary,
	character_id: String,
	revision_id: String,
	field_paths: Array[String]
) -> Dictionary:
	var target_record := CCFStorageService.get_character(project, character_id)
	var revision := get_revision(target_record, revision_id)
	if revision.is_empty():
		return {"ok": false, "error": "The selected revision could not be found."}
	var source_value: Variant = revision.get("snapshot", {})
	if not source_value is Dictionary:
		return {"ok": false, "error": "The selected revision has no valid snapshot."}
	return apply_selected_snapshot(
		project,
		character_id,
		source_value as Dictionary,
		field_paths,
		str(revision.get("label", "revision")),
		{
			"source_character_id": character_id,
			"source_revision_id": revision_id
		}
	)


static func apply_selected_snapshot(
	project: Dictionary,
	character_id: String,
	source_snapshot: Dictionary,
	field_paths: Array[String],
	source_label: String = "source",
	provenance: Dictionary = {}
) -> Dictionary:
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0:
		return {"ok": false, "error": "The selected character could not be found."}
	if field_paths.is_empty():
		return {"ok": false, "error": "No changed fields were selected."}
	var characters: Array = project.get("characters", []).duplicate(true)
	var target_record: Dictionary = (characters[index] as Dictionary).duplicate(true)
	create_checkpoint(
		target_record,
		"Before selective merge",
		"Automatic recovery point created before applying selected revision fields.",
		"pre_merge",
		{},
		true
	)
	for field_path in field_paths:
		if _has_path(source_snapshot, field_path):
			CCFStorageService.set_value_at_path(
				target_record,
				field_path,
				CCFStorageService.get_value_at_path(
					source_snapshot, field_path, null
				)
			)
		else:
			_erase_path(target_record, field_path)
	target_record["updated_at"] = Time.get_datetime_string_from_system(true)
	create_checkpoint(
		target_record,
		"Selective merge",
		"Applied %d field(s) from %s." % [field_paths.size(), source_label],
		"selective_merge",
		provenance.merged({"paths": field_paths.duplicate()}, true),
		true
	)
	characters[index] = target_record
	project["characters"] = characters
	return {"ok": true, "character": target_record.duplicate(true)}


static func configure_history(
	character_record: Dictionary, retention_limit: int, include_in_packages: bool
) -> Dictionary:
	var history := ensure_history(character_record)
	history["retention_limit"] = clampi(
		retention_limit, MIN_RETENTION, MAX_RETENTION
	)
	history["include_in_packages"] = include_in_packages
	character_record[HISTORY_KEY] = history
	return prune_history(character_record)


static func prune_history(character_record: Dictionary) -> Dictionary:
	var history := ensure_history(character_record)
	var entries: Array = history.get("entries", []).duplicate(true)
	var retention_limit := int(history.get("retention_limit", DEFAULT_RETENTION))
	var removed := 0
	while entries.size() > retention_limit:
		entries.pop_front()
		removed += 1
	history["entries"] = entries
	character_record[HISTORY_KEY] = history
	return {"ok": true, "removed": removed, "remaining": entries.size()}


static func project_for_package(project: Dictionary) -> Dictionary:
	var packaged := project.duplicate(true)
	var characters: Array = packaged.get("characters", []).duplicate(true)
	for index in range(characters.size()):
		if not characters[index] is Dictionary:
			continue
		var character_record: Dictionary = (characters[index] as Dictionary).duplicate(true)
		var history_value: Variant = character_record.get(HISTORY_KEY, {})
		if (
			history_value is Dictionary
			and not bool((history_value as Dictionary).get("include_in_packages", true))
		):
			character_record.erase(HISTORY_KEY)
		characters[index] = character_record
	packaged["characters"] = characters
	return packaged


static func capabilities() -> Dictionary:
	return {
		"version": "0.18.1",
		"immutable_checkpoints": true,
		"field_aware_diff": true,
		"non_destructive_restore": true,
		"selective_merge": true,
		"fork_revision": true,
		"export_revision": true,
		"retention_controls": true,
		"portable_project_controls": true,
		"content_addressed_assets": true,
		"private_lineage_default_export": false
	}


static func _flatten_for_diff(
	value: Variant, prefix: String, output: Dictionary
) -> void:
	if value is Dictionary:
		var keys: Array[String] = []
		for key_value in (value as Dictionary).keys():
			keys.append(str(key_value))
		keys.sort()
		if keys.is_empty() and not prefix.is_empty():
			output[prefix] = {}
		for key_text in keys:
			var next_prefix := key_text if prefix.is_empty() else "%s.%s" % [prefix, key_text]
			_flatten_for_diff((value as Dictionary).get(key_text), next_prefix, output)
		return
	if not prefix.is_empty():
		output[prefix] = value.duplicate(true) if value is Array else value


static func _has_path(data: Dictionary, field_path: String) -> bool:
	var parts := field_path.split(".", false)
	if parts.is_empty():
		return false
	var cursor: Variant = data
	for part in parts:
		if not cursor is Dictionary or not (cursor as Dictionary).has(part):
			return false
		cursor = (cursor as Dictionary).get(part)
	return true


static func _erase_path(data: Dictionary, field_path: String) -> void:
	var parts := field_path.split(".", false)
	if parts.is_empty():
		return
	var cursor: Dictionary = data
	for index in range(parts.size() - 1):
		var part := parts[index]
		var next_value: Variant = cursor.get(part)
		if not next_value is Dictionary:
			return
		cursor = next_value
	cursor.erase(parts[-1])


static func _content_digest(snapshot: Dictionary) -> String:
	return JSON.stringify(snapshot).sha256_text()


static func _new_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()
