class_name CCFCollaboratorCompletionServiceV01535
extends RefCounted

const DEST_CURRENT_EMPTY := "current_empty_character"
const DEST_SAME_PROJECT_NEW := "same_project_new_character"
const DEST_NEW_PROJECT := "new_project"


static func destination_options(
	current_character: Dictionary,
	template: Dictionary
) -> Array[Dictionary]:
	var empty := is_effectively_empty_character(current_character, template)
	var result: Array[Dictionary] = []
	if empty:
		result.append({
			"id": DEST_CURRENT_EMPTY,
			"label": "Populate Current Empty Character (Recommended)",
			"description": "Use the current untouched character slot and preserve its character ID. No existing authored character content is replaced.",
			"recommended": true
		})
	result.append({
		"id": DEST_SAME_PROJECT_NEW,
		"label": "Create New Character in This Project%s" % ("" if empty else " (Recommended)"),
		"description": "Create a new standalone character beside the current one. Project shared context, relationships and group membership stay in the current project.",
		"recommended": not empty
	})
	result.append({
		"id": DEST_NEW_PROJECT,
		"label": "Create as New Project",
		"description": "Create a separate Character Project containing the completed character. The current project and character remain unchanged.",
		"recommended": false
	})
	return result


static func recommended_destination(
	current_character: Dictionary,
	template: Dictionary
) -> String:
	return DEST_CURRENT_EMPTY if is_effectively_empty_character(current_character, template) else DEST_SAME_PROJECT_NEW


static func is_effectively_empty_character(
	character: Dictionary,
	template: Dictionary
) -> bool:
	if character.is_empty():
		return true

	var concept_value: Variant = character.get("concept", {})
	if concept_value is Dictionary:
		var concept: Dictionary = concept_value
		if not str(concept.get("prompt", "")).strip_edges().is_empty():
			return false
		if not str(concept.get("notes", "")).strip_edges().is_empty():
			return false

	var metadata_value: Variant = character.get("metadata", {})
	if metadata_value is Dictionary:
		var metadata: Dictionary = metadata_value
		for key in ["summary", "role", "creator", "character_version"]:
			if not str(metadata.get(key, "")).strip_edges().is_empty():
				return false
		var tags_value: Variant = metadata.get("tags", [])
		if tags_value is Array and not (tags_value as Array).is_empty():
			return false

	var card_value: Variant = character.get("character", {})
	if card_value is Dictionary:
		var card: Dictionary = card_value
		for key in [
			"description",
			"personality",
			"scenario",
			"first_message",
			"example_dialogue",
			"creator_notes",
			"system_prompt",
			"post_history_instructions"
		]:
			if not str(card.get(key, "")).strip_edges().is_empty():
				return false
		var alternatives_value: Variant = card.get("alternate_greetings", [])
		if alternatives_value is Array and not (alternatives_value as Array).is_empty():
			return false
		var book_value: Variant = card.get("character_book", {})
		if book_value is Dictionary and not (book_value as Dictionary).is_empty():
			return false
		var extensions_value: Variant = card.get("card_extensions", {})
		if extensions_value is Dictionary and not (extensions_value as Dictionary).is_empty():
			return false

	# Custom templates may expose generation fields outside the built-in card
	# paths above. Treat any populated generation field as authored content.
	for raw_field in CCFTemplateService.generation_fields(template):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_path := str(field.get("path", "")).strip_edges()
		if field_path.is_empty() or field_path in ["character.name", "metadata.name"]:
			continue
		var value: Variant = CCFStorageService.get_value_at_path(character, field_path, null)
		if _variant_has_content(value):
			return false

	var assets_value: Variant = character.get("assets", {})
	if assets_value is Dictionary:
		var assets: Dictionary = assets_value
		if not str(assets.get("portrait", "")).strip_edges().is_empty():
			return false
		for key in ["generated_images", "emotion_images"]:
			var rows_value: Variant = assets.get(key, [])
			if rows_value is Array and not (rows_value as Array).is_empty():
				return false

	var attachments_value: Variant = character.get("attachments", [])
	if attachments_value is Array and not (attachments_value as Array).is_empty():
		return false

	return true


static func materialise_character(
	payload: Dictionary,
	session_title: String,
	template: Dictionary,
	destination_id: String,
	source_context: Dictionary = {},
	existing_empty_character: Dictionary = {}
) -> Dictionary:
	var handoff_mode := str(payload.get("handoff_mode", "")).strip_edges()
	if handoff_mode not in ["blueprint", "detailed_workspace_draft"]:
		return {"ok": false, "error": "Unsupported Collaborator handoff mode."}

	var fallback_name := session_title.strip_edges()
	if fallback_name.is_empty():
		fallback_name = "Collaborator Character"
	var suggested_name := str(payload.get("suggested_name", "")).strip_edges()
	var display_name := suggested_name if not suggested_name.is_empty() else fallback_name
	var record := CCFStorageService.new_character_record(display_name)

	if handoff_mode == "blueprint":
		var concept_prompt := str(payload.get("concept_prompt", "")).strip_edges()
		if concept_prompt.is_empty():
			return {"ok": false, "error": "Character Collaborator returned a Blueprint without a usable Generation Concept."}
		CCFStorageService.set_value_at_path(record, "concept.prompt", concept_prompt)
	else:
		var fields_value: Variant = payload.get("fields", {})
		if not fields_value is Dictionary:
			return {"ok": false, "error": "Character Collaborator returned a detailed draft without usable template fields."}
		var fields: Dictionary = fields_value
		for raw_field in CCFTemplateService.generation_fields(template):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			var field_id := str(field.get("id", "")).strip_edges()
			var field_path := str(field.get("path", "")).strip_edges()
			if field_id.is_empty() or field_path.is_empty() or not fields.has(field_id):
				continue
			var value: Variant = fields.get(field_id)
			CCFStorageService.set_value_at_path(record, field_path, value)
			if field_path in ["character.name", "metadata.name"]:
				var candidate_name := str(value).strip_edges()
				if not candidate_name.is_empty():
					display_name = candidate_name

		var concept_prompt := str(payload.get("concept_prompt", "")).strip_edges()
		if not concept_prompt.is_empty():
			CCFStorageService.set_value_at_path(record, "concept.prompt", concept_prompt)

		var alternatives: Array[String] = []
		var alternatives_value: Variant = payload.get("alternate_greetings", [])
		if alternatives_value is Array:
			for raw_greeting in alternatives_value:
				var greeting := str(raw_greeting).strip_edges()
				if not greeting.is_empty():
					alternatives.append(greeting)
		CCFStorageService.set_value_at_path(record, "character.alternate_greetings", alternatives)

		var lorebook_value: Variant = payload.get("lorebook", {})
		if lorebook_value is Dictionary:
			var lorebook: Dictionary = (lorebook_value as Dictionary).duplicate(true)
			if not lorebook.get("entries", []) is Array:
				lorebook["entries"] = []
			CCFStorageService.set_value_at_path(record, "character.character_book", lorebook)

	if display_name.is_empty():
		display_name = fallback_name
	CCFStorageService.set_value_at_path(record, "metadata.name", display_name)
	CCFStorageService.set_value_at_path(record, "character.name", display_name)

	if destination_id == DEST_CURRENT_EMPTY and not existing_empty_character.is_empty():
		var preserved_id := str(existing_empty_character.get("character_id", "")).strip_edges()
		if not preserved_id.is_empty():
			record["character_id"] = preserved_id
		var preserved_created_at := str(existing_empty_character.get("created_at", "")).strip_edges()
		if not preserved_created_at.is_empty():
			record["created_at"] = preserved_created_at

	var provenance: Dictionary = record.get("provenance", {}).duplicate(true)
	var source_id := str(source_context.get("source_context_id", "")).strip_edges()
	var source_type := str(source_context.get("source_type", "")).strip_edges()
	provenance["character_collaborator"] = {
		"source": "character_collaborator_v01535",
		"handoff_mode": handoff_mode,
		"destination": destination_id,
		"session_title": session_title,
		"source_context_id": source_id,
		"source_type": source_type,
		"generated_at": Time.get_datetime_string_from_system(true)
	}
	var source_provenance_value: Variant = source_context.get("provenance", {})
	if source_provenance_value is Dictionary:
		var source_provenance: Dictionary = source_provenance_value
		var derivation_value: Variant = source_provenance.get("derivation", {})
		if derivation_value is Dictionary and not (derivation_value as Dictionary).is_empty():
			provenance["derivation"] = (derivation_value as Dictionary).duplicate(true)
	record["provenance"] = provenance
	record["updated_at"] = Time.get_datetime_string_from_system(true)

	return {
		"ok": true,
		"character": record,
		"display_name": display_name,
		"handoff_mode": handoff_mode,
		"destination": destination_id
	}


static func new_project_for_character(character: Dictionary) -> Dictionary:
	if character.is_empty():
		return {}
	var project := CCFStorageService.new_project()
	var character_copy := character.duplicate(true)
	project["characters"] = [character_copy]
	var character_id := str(character_copy.get("character_id", ""))
	var workspace: Dictionary = project.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = character_id
	workspace["selected_project_tab"] = "characters"
	project["workspace"] = workspace
	var display_name := CCFStorageService.character_display_name(character_copy)
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["name"] = display_name
	project["metadata"] = metadata
	return project


static func capabilities() -> Dictionary:
	return {
		"version": "0.15.35",
		"empty_workspace_reuse": true,
		"same_project_new_character": true,
		"new_project_destination": true,
		"occupied_character_overwrite": false,
		"replacement_compare_apply_reserved_v01536": true,
		"provenance_preserved": true
	}


static func _variant_has_content(value: Variant) -> bool:
	if value == null:
		return false
	if value is String:
		return not (value as String).strip_edges().is_empty()
	if value is Array:
		return not (value as Array).is_empty()
	if value is Dictionary:
		return not (value as Dictionary).is_empty()
	if value is bool:
		return bool(value)
	if value is int or value is float:
		return value != 0
	return true
