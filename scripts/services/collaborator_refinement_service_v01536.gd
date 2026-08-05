class_name CCFCollaboratorRefinementServiceV01536
extends RefCounted

const COMPLETION_SERVICE_V01535 = preload(
	"res://scripts/services/collaborator_completion_service_v01535.gd"
)

const DEST_COMPARE_APPLY := "compare_apply_source_character"
const APPLY_UPDATE_ORIGINAL := "update_original"
const APPLY_CREATE_COPY := "create_improved_copy"


static func can_compare_source(source_context: Dictionary) -> bool:
	if str(source_context.get("source_type", "")) != "character":
		return false
	var snapshot_value: Variant = source_context.get("snapshot", {})
	return snapshot_value is Dictionary and not (snapshot_value as Dictionary).is_empty()


static func source_snapshot(source_context: Dictionary) -> Dictionary:
	if not can_compare_source(source_context):
		return {}
	return (source_context.get("snapshot", {}) as Dictionary).duplicate(true)


static func source_character_id(source_context: Dictionary) -> String:
	var snapshot := source_snapshot(source_context)
	var snapshot_id := str(
		snapshot.get("character_id", snapshot.get("id", ""))
	).strip_edges()
	if not snapshot_id.is_empty():
		return snapshot_id
	var provenance_value: Variant = source_context.get("provenance", {})
	if provenance_value is Dictionary:
		var provenance: Dictionary = provenance_value
		var direct_id := str(provenance.get("character_id", "")).strip_edges()
		if not direct_id.is_empty():
			return direct_id
		var derivation_value: Variant = provenance.get("derivation", {})
		if derivation_value is Dictionary:
			return str(
				(derivation_value as Dictionary).get("source_character_id", "")
			).strip_edges()
	return ""


static func source_project_id(source_context: Dictionary) -> String:
	var provenance_value: Variant = source_context.get("provenance", {})
	if not provenance_value is Dictionary:
		return ""
	var provenance: Dictionary = provenance_value
	var direct_id := str(provenance.get("project_id", "")).strip_edges()
	if not direct_id.is_empty():
		return direct_id
	var derivation_value: Variant = provenance.get("derivation", {})
	if derivation_value is Dictionary:
		return str(
			(derivation_value as Dictionary).get("source_project_id", "")
		).strip_edges()
	return ""


static func source_exists_in_project(
	source_context: Dictionary,
	project: Dictionary
) -> bool:
	if not can_compare_source(source_context):
		return false
	var target_id := source_character_id(source_context)
	if target_id.is_empty():
		return false
	var expected_project_id := source_project_id(source_context)
	var current_project_id := str(project.get("project_id", "")).strip_edges()
	if (
		not expected_project_id.is_empty()
		and not current_project_id.is_empty()
		and expected_project_id != current_project_id
	):
		return false
	return CCFStorageService.character_index(project, target_id) >= 0


static func allows_update_original(source_context: Dictionary) -> bool:
	if not can_compare_source(source_context):
		return false
	var provenance_value: Variant = source_context.get("provenance", {})
	if not provenance_value is Dictionary:
		return true
	var derivation_value: Variant = (
		(provenance_value as Dictionary).get("derivation", {})
	)
	if not derivation_value is Dictionary:
		return true
	var intent_id := str(
		(derivation_value as Dictionary).get("derivation_type", "")
	).strip_edges()
	return intent_id.is_empty() or intent_id in ["refine", "open_ended"]


static func build_proposal(
	payload: Dictionary,
	session_title: String,
	template: Dictionary,
	source_context: Dictionary
) -> Dictionary:
	if not can_compare_source(source_context):
		return {"ok": false, "error": "Compare & Apply requires an existing-character Collaborator source."}
	var materialised := COMPLETION_SERVICE_V01535.materialise_character(
		payload,
		session_title,
		template,
		COMPLETION_SERVICE_V01535.DEST_SAME_PROJECT_NEW,
		source_context
	)
	if not bool(materialised.get("ok", false)):
		return materialised
	var character_value: Variant = materialised.get("character", {})
	if not character_value is Dictionary:
		return {"ok": false, "error": "Collaborator completion did not produce a comparable character record."}
	return {
		"ok": true,
		"character": (character_value as Dictionary).duplicate(true),
		"display_name": str(materialised.get("display_name", "Collaborator proposal"))
	}


static func comparison_rows(
	payload: Dictionary,
	source_character: Dictionary,
	proposal: Dictionary,
	template: Dictionary
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var seen: Dictionary = {}
	var paths := _explicit_proposal_paths(payload, template)
	for item in paths:
		var path := str(item.get("path", "")).strip_edges()
		if path.is_empty() or seen.has(path):
			continue
		seen[path] = true
		var original_value: Variant = _semantic_value(source_character, path)
		var proposed_value: Variant = _semantic_value(proposal, path)
		if _values_equal(original_value, proposed_value):
			continue
		rows.append({
			"id": path.replace(".", "_"),
			"path": path,
			"label": str(item.get("label", path)),
			"original": _clone_variant(original_value),
			"proposed": _clone_variant(proposed_value),
			"selected": true
		})
	return rows


static func apply_selected_changes(
	current_source: Dictionary,
	captured_source: Dictionary,
	proposal: Dictionary,
	selected_paths: Array[String],
	mode: String,
	source_context: Dictionary,
	session_title: String
) -> Dictionary:
	if mode not in [APPLY_UPDATE_ORIGINAL, APPLY_CREATE_COPY]:
		return {"ok": false, "error": "Unknown Compare & Apply destination."}
	if selected_paths.is_empty():
		return {"ok": false, "error": "Select at least one changed field or section to apply."}
	if mode == APPLY_UPDATE_ORIGINAL and not allows_update_original(source_context):
		return {
			"ok": false,
			"error": "This Collaborator direction creates a branch/related character, so Update Original is disabled. Use Create Improved Copy instead."
		}

	var conflicts: Array[String] = []
	if mode == APPLY_UPDATE_ORIGINAL:
		for path in selected_paths:
			var captured_value: Variant = _semantic_value(captured_source, path)
			var current_value: Variant = _semantic_value(current_source, path)
			var proposal_value: Variant = _semantic_value(proposal, path)
			if (
				not _values_equal(current_value, captured_value)
				and not _values_equal(current_value, proposal_value)
			):
				conflicts.append(path)
	if not conflicts.is_empty():
		return {
			"ok": false,
			"error": "The source character changed after it was sent to Collaborator. Reopen Compare & Apply after reviewing the current card so newer edits are not overwritten.",
			"conflicts": conflicts
		}

	var result := current_source.duplicate(true)
	for path in selected_paths:
		_set_semantic_value(result, path, _semantic_value(proposal, path))

	var now := Time.get_datetime_string_from_system(true)
	var source_id := str(
		current_source.get("character_id", current_source.get("id", ""))
	).strip_edges()
	if mode == APPLY_CREATE_COPY:
		var identity_seed := CCFStorageService.new_character_record(
			CCFStorageService.character_display_name(result)
		)
		result["character_id"] = str(identity_seed.get("character_id", ""))
		result["created_at"] = str(identity_seed.get("created_at", now))

	var provenance_value: Variant = result.get("provenance", {})
	var provenance: Dictionary = (
		(provenance_value as Dictionary).duplicate(true)
		if provenance_value is Dictionary
		else {}
	)
	var refinement_record := {
		"source": "character_collaborator_v01536",
		"mode": mode,
		"source_character_id": source_id,
		"source_context_id": str(source_context.get("source_context_id", "")),
		"session_title": session_title,
		"applied_paths": selected_paths.duplicate(),
		"applied_at": now
	}
	provenance["character_collaborator_refinement"] = refinement_record.duplicate(true)
	var history_value: Variant = provenance.get("character_collaborator_refinements", [])
	var history: Array = history_value.duplicate(true) if history_value is Array else []
	history.append(refinement_record.duplicate(true))
	provenance["character_collaborator_refinements"] = history

	if mode == APPLY_CREATE_COPY:
		var source_provenance_value: Variant = source_context.get("provenance", {})
		if source_provenance_value is Dictionary:
			var derivation_value: Variant = (
				(source_provenance_value as Dictionary).get("derivation", {})
			)
			if derivation_value is Dictionary and not (derivation_value as Dictionary).is_empty():
				provenance["derivation"] = (derivation_value as Dictionary).duplicate(true)
	result["provenance"] = provenance
	result["updated_at"] = now

	return {
		"ok": true,
		"character": result,
		"mode": mode,
		"source_character_id": source_id,
		"character_id": str(result.get("character_id", "")),
		"applied_paths": selected_paths.duplicate()
	}


static func capabilities() -> Dictionary:
	return {
		"version": "0.15.36",
		"existing_character_compare": true,
		"selective_field_apply": true,
		"update_original": true,
		"create_improved_copy": true,
		"branch_intent_update_guard": true,
		"source_snapshot_conflict_guard": true,
		"v01410_derivation_provenance": true
	}


static func _explicit_proposal_paths(
	payload: Dictionary,
	template: Dictionary
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var concept_prompt := str(payload.get("concept_prompt", ""))
	if not concept_prompt.strip_edges().is_empty():
		result.append({"path": "concept.prompt", "label": "Generation Concept"})

	var suggested_name := str(payload.get("suggested_name", "")).strip_edges()
	if not suggested_name.is_empty():
		result.append({"path": "character.name", "label": "Name"})

	if str(payload.get("handoff_mode", "")) == "detailed_workspace_draft":
		var fields_value: Variant = payload.get("fields", {})
		if fields_value is Dictionary:
			var fields: Dictionary = fields_value
			for raw_field in CCFTemplateService.generation_fields(template):
				if not raw_field is Dictionary:
					continue
				var field: Dictionary = raw_field
				var field_id := str(field.get("id", "")).strip_edges()
				if field_id.is_empty() or not fields.has(field_id):
					continue
				var field_path := _canonical_path(str(field.get("path", "")))
				if field_path.is_empty():
					continue
				result.append({
					"path": field_path,
					"label": str(field.get("label", field.get("name", field_id)))
				})
		if payload.has("alternate_greetings"):
			result.append({
				"path": "character.alternate_greetings",
				"label": "Alternative Greetings"
			})
		if payload.has("lorebook"):
			result.append({
				"path": "character.character_book",
				"label": "Character Lorebook"
			})
	return result


static func _canonical_path(path: String) -> String:
	var clean := path.strip_edges()
	if clean in ["metadata.name", "character.name"]:
		return "character.name"
	return clean


static func _semantic_value(character: Dictionary, path: String) -> Variant:
	var canonical := _canonical_path(path)
	if canonical == "character.name":
		var character_name := str(
			CCFStorageService.get_value_at_path(character, "character.name", "")
		).strip_edges()
		if not character_name.is_empty():
			return character_name
		return str(
			CCFStorageService.get_value_at_path(character, "metadata.name", "")
		)
	return CCFStorageService.get_value_at_path(character, canonical, null)


static func _set_semantic_value(
	character: Dictionary,
	path: String,
	value: Variant
) -> void:
	var canonical := _canonical_path(path)
	if canonical == "character.name":
		var name_value := str(value)
		CCFStorageService.set_value_at_path(character, "character.name", name_value)
		CCFStorageService.set_value_at_path(character, "metadata.name", name_value)
		return
	CCFStorageService.set_value_at_path(character, canonical, _clone_variant(value))


static func _values_equal(left: Variant, right: Variant) -> bool:
	return JSON.stringify(left) == JSON.stringify(right)


static func _clone_variant(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value
