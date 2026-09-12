class_name CCFRichAuthoringServiceV0190
extends RefCounted

const VERSION := "0.19.0"
const PROJECT_KEY := "rich_authoring_v0190"
const CHARACTER_KEY := "rich_authoring_v0190"
const FORMAT_VERSION := 1
const REVISION_SERVICE = preload("res://scripts/services/revision_service_v0181.gd")


static func capabilities() -> Dictionary:
	return {
		"version": VERSION,
		"scenario_presets": true,
		"single_scenario_materialisation": true,
		"greeting_manager": true,
		"greeting_categories_tags_weights_randomisation_favourites": true,
		"front_porch_opening_seeds": true,
		"multi_character_workspace": true,
		"new_group_project_entry": true,
		"add_existing_library_character": true,
		"persistent_roster_and_active_cast": true,
		"reviewed_combined_materialisation": true,
		"split_character_set": true,
		"recoverable_parent_job": true,
		"partial_retry": true,
		"shared_world_manager": true,
		"dependency_inspection": true,
		"lorebook_world_reference_graph": true,
		"lineage_views": true,
		"private_custom_metadata": true,
		"explicit_export_mappings": true,
		"raw_group_json_expert_only": true,
		"source_characters_never_modified_by_materialisation": true,
		"automatic_network_calls": false,
		"raw_database_writes": false
	}


static func ensure_project_data(project: Dictionary) -> Dictionary:
	var raw_value: Variant = project.get(PROJECT_KEY, {})
	var data: Dictionary = (
		(raw_value as Dictionary).duplicate(true)
		if raw_value is Dictionary
		else {}
	)
	data["format_version"] = FORMAT_VERSION
	data["shared_world_links"] = _string_array(data.get("shared_world_links", []))
	data["split_batches"] = _dictionary_array(data.get("split_batches", []))
	data["ensemble_groups"] = _dictionary_array(data.get("ensemble_groups", []))
	data["updated_at"] = str(data.get("updated_at", ""))
	project[PROJECT_KEY] = data
	return data


static func character_data(character_record: Dictionary) -> Dictionary:
	var raw_value: Variant = character_record.get(CHARACTER_KEY, {})
	var data: Dictionary = (
		(raw_value as Dictionary).duplicate(true)
		if raw_value is Dictionary
		else {}
	)
	data["format_version"] = FORMAT_VERSION
	data["scenario_presets"] = _dictionary_array(data.get("scenario_presets", []))
	data["greeting_records"] = _normalise_greetings(
		data.get("greeting_records", []), character_record
	)
	var custom_value: Variant = data.get("custom_metadata", {})
	data["custom_metadata"] = (
		(custom_value as Dictionary).duplicate(true)
		if custom_value is Dictionary
		else {}
	)
	data["export_mappings"] = _dictionary_array(data.get("export_mappings", []))
	return data


static func store_character_data(character_record: Dictionary, data: Dictionary) -> void:
	var clean := data.duplicate(true)
	clean["format_version"] = FORMAT_VERSION
	clean["updated_at"] = Time.get_datetime_string_from_system(true)
	character_record[CHARACTER_KEY] = clean


static func scenario_presets(character_record: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_preset in character_data(character_record).get("scenario_presets", []):
		if raw_preset is Dictionary:
			result.append(_normalise_scenario(raw_preset))
	return result


static func upsert_scenario(
	character_record: Dictionary, scenario_record: Dictionary
) -> Dictionary:
	var data := character_data(character_record)
	var clean := _normalise_scenario(scenario_record)
	if str(clean.get("scenario_id", "")).is_empty():
		clean["scenario_id"] = _new_id("scenario")
	var records: Array = data.get("scenario_presets", []).duplicate(true)
	var replaced := false
	for index in range(records.size()):
		if (
			records[index] is Dictionary
			and str(records[index].get("scenario_id", ""))
			== str(clean.get("scenario_id", ""))
		):
			records[index] = clean
			replaced = true
			break
	if not replaced:
		records.append(clean)
	data["scenario_presets"] = records
	store_character_data(character_record, data)
	return clean


static func remove_scenario(character_record: Dictionary, scenario_id: String) -> bool:
	var data := character_data(character_record)
	var kept: Array = []
	var removed := false
	for raw_record in data.get("scenario_presets", []):
		if raw_record is Dictionary and str(raw_record.get("scenario_id", "")) == scenario_id:
			removed = true
			continue
		kept.append(raw_record)
	data["scenario_presets"] = kept
	store_character_data(character_record, data)
	return removed


static func materialise_scenario(
	project: Dictionary, character_id: String, scenario_id: String
) -> Dictionary:
	var character_record := CCFStorageService.get_character(project, character_id)
	if character_record.is_empty():
		return {"ok": false, "error": "The source character no longer exists."}
	var selected: Dictionary = {}
	for preset in scenario_presets(character_record):
		if str(preset.get("scenario_id", "")) == scenario_id:
			selected = preset
			break
	if selected.is_empty():
		return {"ok": false, "error": "The selected scenario preset no longer exists."}
	var card := CCFCardFormatService.export_character_v2(project, character_id)
	var card_value: Variant = card.get("data", {})
	if not card_value is Dictionary:
		return {"ok": false, "error": "The character could not be materialised."}
	var card_data: Dictionary = (card_value as Dictionary).duplicate(true)
	card_data["scenario"] = str(selected.get("scenario", ""))
	card_data["first_mes"] = str(selected.get("opening_message", ""))
	var extensions_value: Variant = card_data.get("extensions", {})
	var extensions: Dictionary = (
		(extensions_value as Dictionary).duplicate(true)
		if extensions_value is Dictionary
		else {}
	)
	extensions["ccf_materialised_scenario"] = {
		"name": str(selected.get("name", "")),
		"tags": _string_array(selected.get("tags", [])),
		"world_ids": _string_array(selected.get("world_ids", []))
	}
	card_data["extensions"] = extensions
	return {
		"ok": true,
		"card": {"spec": "chara_card_v2", "spec_version": "2.0", "data": card_data},
		"source_character_id": character_id,
		"scenario_id": scenario_id,
		"warnings": [
			"This target supports one scenario; the selected preset was materialised without changing the source character."
		]
	}


static func greeting_records(character_record: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_record in character_data(character_record).get("greeting_records", []):
		if raw_record is Dictionary:
			result.append(_normalise_greeting(raw_record))
	return result


static func set_greeting_records(
	character_record: Dictionary, records_value: Variant
) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if records_value is Array:
		for raw_record in records_value:
			if not raw_record is Dictionary:
				continue
			var clean := _normalise_greeting(raw_record)
			if str(clean.get("greeting_id", "")).is_empty():
				clean["greeting_id"] = _new_id("greeting")
			if not str(clean.get("text", "")).strip_edges().is_empty():
				records.append(clean)
	var data := character_data(character_record)
	data["greeting_records"] = records
	store_character_data(character_record, data)
	var character_value: Variant = character_record.get("character", {})
	var card_data: Dictionary = (
		(character_value as Dictionary).duplicate(true)
		if character_value is Dictionary
		else {}
	)
	var compatible: Array[String] = []
	for record in records:
		compatible.append(str(record.get("text", "")))
	card_data["alternate_greetings"] = compatible
	character_record["character"] = card_data
	return records


static func choose_greeting(
	character_record: Dictionary, category: String = "", random_key: String = ""
) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for record in greeting_records(character_record):
		if category.strip_edges().is_empty() or str(record.get("category", "")) == category:
			candidates.append(record)
	if candidates.is_empty():
		return {}
	var total_weight := 0
	for record in candidates:
		total_weight += maxi(1, int(record.get("weight", 1)))
	var digest := random_key
	if digest.is_empty():
		digest = Time.get_datetime_string_from_system(true) + str(Time.get_ticks_usec())
	var point := absi(digest.hash()) % total_weight
	for record in candidates:
		point -= maxi(1, int(record.get("weight", 1)))
		if point < 0:
			return record.duplicate(true)
	return candidates[-1].duplicate(true)


static func new_multi_character_project(
	project_name: String = "Untitled Ensemble", member_names: Array[String] = []
) -> Dictionary:
	var project := CCFStorageService.new_project()
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["name"] = project_name.strip_edges() if not project_name.strip_edges().is_empty() else "Untitled Ensemble"
	project["metadata"] = metadata
	var names := member_names.duplicate()
	if names.size() < 2:
		names = ["Member One", "Member Two"]
	var members: Array = []
	for member_name in names:
		members.append(CCFStorageService.new_character_record(str(member_name)))
	project["characters"] = members
	var roster_ids: Array[String] = []
	for member in members:
		roster_ids.append(str(member.get("character_id", "")))
	project["workspace"]["active_character_id"] = roster_ids[0]
	project["card_workflows"] = [_new_ensemble_workflow(metadata["name"], roster_ids)]
	var project_data := ensure_project_data(project)
	project_data["ensemble_groups"] = [{
		"group_id": _new_id("ensemble"),
		"name": metadata["name"],
		"workflow_id": str(project["card_workflows"][0].get("workflow_id", "")),
		"roster_ids": roster_ids,
		"created_at": Time.get_datetime_string_from_system(true)
	}]
	project[PROJECT_KEY] = project_data
	return project


static func add_new_member(
	project: Dictionary, member_name: String = "Untitled Member"
) -> Dictionary:
	var result := project.duplicate(true)
	var record := CCFStorageService.new_character_record(member_name)
	var characters: Array = result.get("characters", []).duplicate(true)
	characters.append(record)
	result["characters"] = characters
	return {"ok": true, "project": result, "character_id": str(record.get("character_id", ""))}


static func add_existing_library_character(
	target_project: Dictionary,
	source_project: Dictionary,
	source_character_id: String
) -> Dictionary:
	var source := CCFStorageService.get_character(source_project, source_character_id)
	if source.is_empty():
		return {"ok": false, "error": "The selected library character could not be loaded."}
	var result := target_project.duplicate(true)
	var copy := source.duplicate(true)
	var old_id := str(copy.get("character_id", ""))
	var new_record := CCFStorageService.new_character_record(
		CCFStorageService.character_display_name(copy)
	)
	var new_id := str(new_record.get("character_id", ""))
	copy["character_id"] = new_id
	copy["created_at"] = Time.get_datetime_string_from_system(true)
	copy["updated_at"] = copy["created_at"]
	copy.erase("revision_history")
	copy["revision_lineage"] = {
		"kind": "library_copy_v0190",
		"source_project_id": str(source_project.get("project_id", "")),
		"source_character_id": old_id,
		"copied_at": copy["created_at"]
	}
	# Managed files belong to the source project. Do not create broken cross-project paths.
	copy["assets"] = {"portrait": "", "generated_images": [], "emotion_images": []}
	copy["attachments"] = []
	REVISION_SERVICE.create_checkpoint(
		copy, "Added from Library", "Independent copy added to an ensemble project.",
		"library_copy", copy.get("revision_lineage", {}), true
	)
	var characters: Array = result.get("characters", []).duplicate(true)
	characters.append(copy)
	result["characters"] = characters
	return {
		"ok": true,
		"project": result,
		"character_id": new_id,
		"warning": "Artwork and attachments were not cross-linked; add or import managed copies in this project."
	}


static func apply_roster(
	workflow: Dictionary, roster_ids: Array[String], active_ids: Array[String]
) -> Dictionary:
	var result := workflow.duplicate(true)
	var roster := _unique_existing_strings(roster_ids)
	var active: Array[String] = []
	for character_id in _unique_existing_strings(active_ids):
		if character_id in roster:
			active.append(character_id)
	result["selected_character_ids"] = roster
	var rich_value: Variant = result.get(PROJECT_KEY, {})
	var rich: Dictionary = (
		(rich_value as Dictionary).duplicate(true)
		if rich_value is Dictionary
		else {}
	)
	rich["persistent_roster_ids"] = roster
	rich["active_character_ids"] = active if not active.is_empty() else roster.duplicate()
	rich["format_version"] = FORMAT_VERSION
	result[PROJECT_KEY] = rich
	return result


static func materialise_multi_character_card(
	project: Dictionary, workflow: Dictionary
) -> Dictionary:
	var source_guard := JSON.stringify(project)
	var roster := _workflow_roster(project, workflow)
	if roster.size() < 2:
		return {"ok": false, "error": "A combined card requires at least two existing roster members."}
	var active := _active_roster(project, workflow, roster)
	var names: Array[String] = []
	var description_blocks: Array[String] = []
	var personality_blocks: Array[String] = []
	var example_blocks: Array[String] = []
	for character_id in active:
		var record := CCFStorageService.get_character(project, character_id)
		var name := CCFStorageService.character_display_name(record)
		var card_value: Variant = record.get("character", {})
		var card_data: Dictionary = card_value if card_value is Dictionary else {}
		names.append(name)
		description_blocks.append("## %s\n%s" % [name, str(card_data.get("description", ""))])
		personality_blocks.append("## %s — distinct voice and behaviour\n%s" % [name, str(card_data.get("personality", ""))])
		var examples := str(card_data.get("example_dialogue", "")).strip_edges()
		if not examples.is_empty():
			example_blocks.append("## %s\n%s" % [name, examples])
	var combined_data := {
		"name": str(workflow.get("title", "")).strip_edges(),
		"description": "\n\n".join(description_blocks),
		"personality": "\n\n".join(personality_blocks),
		"scenario": str(workflow.get("shared_scenario", "")),
		"first_mes": str(workflow.get("opening_message", "")),
		"mes_example": "\n\n".join(example_blocks),
		"creator_notes": str(workflow.get("summary", "")),
		"system_prompt": _combined_system_prompt(project, workflow, active),
		"post_history_instructions": "",
		"alternate_greetings": [],
		"tags": ["ensemble", "multi-character"],
		"creator": "",
		"character_version": VERSION,
		"extensions": {
			"ccf_ensemble_v0190": {
				"workflow_id": str(workflow.get("workflow_id", "")),
				"member_ids": active,
				"member_names": names,
				"world_ids": _workflow_world_ids(workflow)
			}
		}
	}
	if str(combined_data["name"]).is_empty():
		combined_data["name"] = " & ".join(names)
	if JSON.stringify(project) != source_guard:
		return {"ok": false, "error": "Source project mutation was detected; materialisation was cancelled."}
	return {
		"ok": true,
		"card": {"spec": "chara_card_v2", "spec_version": "2.0", "data": combined_data},
		"source_character_ids": active,
		"warnings": [
			"This is a reviewed combined runtime artifact. Independent source characters were not merged or modified.",
			"Character Card V2 cannot express every ensemble runtime feature; roster, world and turn semantics are retained in the CCF ensemble extension."
		]
	}


static func create_split_batch(
	project: Dictionary, shared_concept: String, member_seeds: Array[Dictionary]
) -> Dictionary:
	if shared_concept.strip_edges().is_empty():
		return {"ok": false, "error": "A shared concept or project plan is required."}
	if member_seeds.size() < 2:
		return {"ok": false, "error": "A split character set requires at least two members."}
	var result := project.duplicate(true)
	var characters: Array = result.get("characters", []).duplicate(true)
	var batch_id := _new_id("split")
	var members: Array[Dictionary] = []
	for seed_value in member_seeds:
		if not seed_value is Dictionary:
			continue
		var member_name := str(seed_value.get("name", "Untitled Member")).strip_edges()
		var record := CCFStorageService.new_character_record(member_name)
		var concept: Dictionary = record.get("concept", {}).duplicate(true)
		concept["prompt"] = "%s\n\nMember role: %s" % [
			shared_concept.strip_edges(), str(seed_value.get("role", "")).strip_edges()
		]
		record["concept"] = concept
		record["revision_lineage"] = {
			"kind": "split_set_v0190", "batch_id": batch_id,
			"shared_concept_hash": shared_concept.sha256_text()
		}
		characters.append(record)
		members.append({
			"character_id": str(record.get("character_id", "")),
			"name": member_name,
			"role": str(seed_value.get("role", "")),
			"status": "pending",
			"error": "",
			"attempts": 0
		})
	if members.size() < 2:
		return {"ok": false, "error": "Two valid member definitions are required."}
	result["characters"] = characters
	var project_data := ensure_project_data(result)
	var batches: Array = project_data.get("split_batches", []).duplicate(true)
	var batch := {
		"batch_id": batch_id,
		"shared_concept": shared_concept.strip_edges(),
		"shared_context": result.get("shared_context", {}).duplicate(true),
		"members": members,
		"status": "pending",
		"created_at": Time.get_datetime_string_from_system(true),
		"updated_at": Time.get_datetime_string_from_system(true)
	}
	batches.append(batch)
	project_data["split_batches"] = batches
	result[PROJECT_KEY] = project_data
	return {"ok": true, "project": result, "batch": batch}


static func split_batch(project: Dictionary, batch_id: String) -> Dictionary:
	var data := ensure_project_data(project)
	for raw_batch in data.get("split_batches", []):
		if raw_batch is Dictionary and str(raw_batch.get("batch_id", "")) == batch_id:
			return raw_batch.duplicate(true)
	return {}


static func build_split_request(
	project: Dictionary, batch_id: String, retry_character_ids: Array[String] = []
) -> Dictionary:
	var batch := split_batch(project, batch_id)
	if batch.is_empty():
		return {"ok": false, "error": "The split-generation batch no longer exists."}
	var retry_lookup: Dictionary = {}
	for character_id in retry_character_ids:
		retry_lookup[character_id] = true
	var member_blocks: Array[String] = []
	var requested_ids: Array[String] = []
	for raw_member in batch.get("members", []):
		if not raw_member is Dictionary:
			continue
		var character_id := str(raw_member.get("character_id", ""))
		if not retry_lookup.is_empty() and not retry_lookup.has(character_id):
			continue
		requested_ids.append(character_id)
		member_blocks.append("- character_id: %s\n  name: %s\n  role: %s" % [
			character_id, str(raw_member.get("name", "")), str(raw_member.get("role", ""))
		])
	if requested_ids.is_empty():
		return {"ok": false, "error": "No pending split members were selected."}
	var prompt := "Create separate complete character-card fields for each requested member of one coordinated set. Preserve distinct voices and independent identities. Shared context supports continuity but must not make another cast member the playable target.\n\nSHARED CONCEPT:\n%s\n\nSHARED PROJECT CONTEXT:\n%s\n\nMEMBERS:\n%s\n\nReturn one JSON object with key members. Each member must contain exact character_id plus description, personality, scenario, first_message, example_dialogue, creator_notes, system_prompt and post_history_instructions strings. Return every requested ID exactly once and JSON only." % [
		str(batch.get("shared_concept", "")),
		JSON.stringify(batch.get("shared_context", {})),
		"\n".join(member_blocks)
	]
	return {
		"ok": true,
		"messages": [
			{"role": "system", "content": "You are Character Card Forge's split-set author. Produce independent, continuity-compatible characters with exact stable IDs."},
			{"role": "user", "content": prompt}
		],
		"requested_character_ids": requested_ids,
		"batch_id": batch_id
	}


static func apply_split_result(
	project: Dictionary, batch_id: String, response: Variant, provenance: Dictionary = {}
) -> Dictionary:
	if not response is Dictionary or not response.get("members", null) is Array:
		return {"ok": false, "error": "The split result did not contain a members array."}
	var result := project.duplicate(true)
	var batch := split_batch(result, batch_id)
	if batch.is_empty():
		return {"ok": false, "error": "The split batch no longer exists."}
	var expected: Dictionary = {}
	for raw_member in batch.get("members", []):
		if raw_member is Dictionary:
			expected[str(raw_member.get("character_id", ""))] = true
	var completed: Array[String] = []
	var failures: Dictionary = {}
	for raw_output in response.get("members", []):
		if not raw_output is Dictionary:
			continue
		var character_id := str(raw_output.get("character_id", ""))
		if not expected.has(character_id) or character_id in completed:
			continue
		var missing: Array[String] = []
		for field_name in ["description", "personality", "scenario", "first_message"]:
			if str(raw_output.get(field_name, "")).strip_edges().is_empty():
				missing.append(field_name)
		if not missing.is_empty():
			failures[character_id] = "Missing required fields: %s" % ", ".join(missing)
			continue
		var character := CCFStorageService.get_character(result, character_id)
		var card_data: Dictionary = character.get("character", {}).duplicate(true)
		for field_name in [
			"description", "personality", "scenario", "first_message", "example_dialogue",
			"creator_notes", "system_prompt", "post_history_instructions"
		]:
			card_data[field_name] = str(raw_output.get(field_name, ""))
		character["character"] = card_data
		var generation: Dictionary = character.get("generation", {}).duplicate(true)
		generation["last_model"] = str(provenance.get("model", ""))
		generation["last_generated_at"] = Time.get_datetime_string_from_system(true)
		character["generation"] = generation
		REVISION_SERVICE.create_checkpoint(
			character, "Split Set Generation", "Generated independently from shared batch %s." % batch_id,
			"split_set_generation", provenance, true
		)
		CCFStorageService.update_character(result, character)
		completed.append(character_id)
	var batches: Array = ensure_project_data(result).get("split_batches", []).duplicate(true)
	for batch_index in range(batches.size()):
		if not batches[batch_index] is Dictionary or str(batches[batch_index].get("batch_id", "")) != batch_id:
			continue
		var updated_batch: Dictionary = batches[batch_index].duplicate(true)
		var updated_members: Array = []
		for raw_member in updated_batch.get("members", []):
			var member: Dictionary = raw_member.duplicate(true)
			var character_id := str(member.get("character_id", ""))
			if character_id in completed:
				member["status"] = "completed"
				member["error"] = ""
			elif failures.has(character_id):
				member["status"] = "failed"
				member["error"] = str(failures[character_id])
			member["attempts"] = int(member.get("attempts", 0)) + 1
			updated_members.append(member)
		updated_batch["members"] = updated_members
		updated_batch["status"] = "completed" if completed.size() == expected.size() else "partial"
		updated_batch["updated_at"] = Time.get_datetime_string_from_system(true)
		batches[batch_index] = updated_batch
		break
	var project_data := ensure_project_data(result)
	project_data["split_batches"] = batches
	result[PROJECT_KEY] = project_data
	return {
		"ok": not completed.is_empty(),
		"project": result,
		"completed_character_ids": completed,
		"failures": failures,
		"partial": completed.size() != expected.size()
	}


static func dependency_report(project: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var project_data := ensure_project_data(project)
	for world_id in _string_array(project_data.get("shared_world_links", [])):
		rows.append(_dependency(
			"world", world_id, "project", str(project.get("project_id", "")),
			"Shared World Manager link"
		))
	var workflows_value: Variant = project.get("card_workflows", [])
	if workflows_value is Array:
		for raw_workflow in workflows_value:
			if not raw_workflow is Dictionary:
				continue
			var workflow_id := str(raw_workflow.get("workflow_id", ""))
			for character_id in _workflow_roster(project, raw_workflow):
				rows.append(_dependency("character", character_id, "workflow", workflow_id, "Roster member"))
			for world_id in _workflow_world_ids(raw_workflow):
				rows.append(_dependency("world", world_id, "workflow", workflow_id, "Shared world"))
	for raw_character in project.get("characters", []):
		if not raw_character is Dictionary:
			continue
		var character_id := str(raw_character.get("character_id", ""))
		for preset in scenario_presets(raw_character):
			for world_id in _string_array(preset.get("world_ids", [])):
				rows.append(_dependency("world", world_id, "scenario", str(preset.get("scenario_id", "")), "Scenario world"))
		var assets_value: Variant = raw_character.get("assets", {})
		if assets_value is Dictionary:
			var portrait := str((assets_value as Dictionary).get("portrait", "")).strip_edges()
			if not portrait.is_empty():
				rows.append(_dependency("image", portrait, "character", character_id, "Portrait"))
	var library_value: Variant = project.get("metadata", {}).get("library", {}) if project.get("metadata", {}) is Dictionary else {}
	if library_value is Dictionary:
		for collection_name in _string_array((library_value as Dictionary).get("collections", [])):
			rows.append(_dependency("project", str(project.get("project_id", "")), "collection", collection_name, "Collection membership"))
	return rows


static func deletion_warnings(project: Dictionary, target_kind: String, target_id: String) -> Array[String]:
	var warnings: Array[String] = []
	for row in dependency_report(project):
		if str(row.get("target_kind", "")) == target_kind and str(row.get("target_id", "")) == target_id:
			warnings.append("%s %s references this %s: %s." % [
				str(row.get("owner_kind", "")).capitalize(), str(row.get("owner_id", "")),
				target_kind, str(row.get("reason", ""))
			])
	return warnings


static func reference_graph(project: Dictionary) -> Dictionary:
	var nodes: Array[Dictionary] = []
	var edges: Array[Dictionary] = []
	var seen: Dictionary = {}
	for row in dependency_report(project):
		var target_key := "%s:%s" % [row.get("target_kind", ""), row.get("target_id", "")]
		var owner_key := "%s:%s" % [row.get("owner_kind", ""), row.get("owner_id", "")]
		if not seen.has(target_key):
			nodes.append({"id": target_key, "kind": row.get("target_kind", ""), "label": row.get("target_id", "")})
			seen[target_key] = true
		if not seen.has(owner_key):
			nodes.append({"id": owner_key, "kind": row.get("owner_kind", ""), "label": row.get("owner_id", "")})
			seen[owner_key] = true
		edges.append({"from": owner_key, "to": target_key, "label": row.get("reason", "references")})
	return {"nodes": nodes, "edges": edges, "canonical_store": "project references"}


static func lineage_rows(project: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for raw_character in project.get("characters", []):
		if not raw_character is Dictionary:
			continue
		var lineage_value: Variant = raw_character.get("revision_lineage", {})
		if not lineage_value is Dictionary or (lineage_value as Dictionary).is_empty():
			continue
		var lineage: Dictionary = lineage_value
		rows.append({
			"character_id": str(raw_character.get("character_id", "")),
			"name": CCFStorageService.character_display_name(raw_character),
			"kind": str(lineage.get("kind", lineage.get("derivation_type", "related"))),
			"source_character_id": str(lineage.get("source_character_id", "")),
			"source_project_id": str(lineage.get("source_project_id", "")),
			"batch_id": str(lineage.get("batch_id", "")),
			"timeline": str(lineage.get("timeline", "")),
			"family_role": str(lineage.get("family_role", ""))
		})
	return rows


static func set_private_custom_metadata(
	character_record: Dictionary, metadata: Dictionary, mappings: Array[Dictionary]
) -> void:
	var data := character_data(character_record)
	data["custom_metadata"] = metadata.duplicate(true)
	data["export_mappings"] = _dictionary_array(mappings)
	store_character_data(character_record, data)


static func mapped_export_preview(character_record: Dictionary) -> Dictionary:
	var data := character_data(character_record)
	var custom: Dictionary = data.get("custom_metadata", {})
	var mapped: Dictionary = {}
	var warnings: Array[String] = []
	for raw_mapping in data.get("export_mappings", []):
		if not raw_mapping is Dictionary:
			continue
		var source_key := str(raw_mapping.get("source_key", "")).strip_edges()
		var target_key := str(raw_mapping.get("target_key", "")).strip_edges()
		if source_key.is_empty() or target_key.is_empty() or not custom.has(source_key):
			warnings.append("Skipped incomplete mapping from '%s' to '%s'." % [source_key, target_key])
			continue
		mapped[target_key] = custom[source_key]
	return {
		"mapped_extensions": mapped,
		"private_unmapped_keys": custom.keys().filter(func(key: Variant) -> bool: return not _mapping_has_source(data.get("export_mappings", []), str(key))),
		"warnings": warnings
	}


static func _normalise_scenario(value: Dictionary) -> Dictionary:
	return {
		"scenario_id": str(value.get("scenario_id", "")),
		"name": str(value.get("name", "Untitled Setup")).strip_edges(),
		"scenario": str(value.get("scenario", "")),
		"opening_message": str(value.get("opening_message", "")),
		"active_character_ids": _string_array(value.get("active_character_ids", [])),
		"world_ids": _string_array(value.get("world_ids", [])),
		"tags": _string_array(value.get("tags", [])),
		"favourite": bool(value.get("favourite", false)),
		"created_at": str(value.get("created_at", Time.get_datetime_string_from_system(true))),
		"updated_at": Time.get_datetime_string_from_system(true)
	}


static func _normalise_greetings(value: Variant, character_record: Dictionary) -> Array:
	var records: Array = []
	if value is Array:
		for raw_record in value:
			if raw_record is Dictionary:
				records.append(_normalise_greeting(raw_record))
	var existing_text: Dictionary = {}
	for record in records:
		existing_text[str(record.get("text", ""))] = true
	var card_value: Variant = character_record.get("character", {})
	if card_value is Dictionary:
		var alternatives: Variant = (card_value as Dictionary).get("alternate_greetings", [])
		if alternatives is Array:
			for raw_text in alternatives:
				var greeting_text := str(raw_text)
				if greeting_text.strip_edges().is_empty() or existing_text.has(greeting_text):
					continue
				records.append(_normalise_greeting({"text": greeting_text}))
	return records


static func _normalise_greeting(value: Dictionary) -> Dictionary:
	return {
		"greeting_id": str(value.get("greeting_id", "")) if not str(value.get("greeting_id", "")).is_empty() else _new_id("greeting"),
		"text": str(value.get("text", "")),
		"category": str(value.get("category", "General")).strip_edges(),
		"tags": _string_array(value.get("tags", [])),
		"weight": clampi(int(value.get("weight", 1)), 1, 100),
		"favourite": bool(value.get("favourite", false)),
		"front_porch_seed": str(value.get("front_porch_seed", "")),
		"created_at": str(value.get("created_at", Time.get_datetime_string_from_system(true)))
	}


static func _new_ensemble_workflow(workflow_name: String, roster_ids: Array[String]) -> Dictionary:
	var members: Array = []
	for character_id in roster_ids:
		members.append({
			"character_id": character_id, "role_in_output": "", "card_direction": "",
			"scenario_direction": "", "opening_direction": ""
		})
	return apply_roster({
		"workflow_id": _new_id("workflow"),
		"created_at": Time.get_datetime_string_from_system(true),
		"updated_at": Time.get_datetime_string_from_system(true),
		"mode": "group_card", "title": workflow_name, "selected_character_ids": roster_ids,
		"instructions": "", "summary": "", "shared_scenario": "",
		"opening_message": "", "notes": "", "members": members
	}, roster_ids, roster_ids)


static func _workflow_roster(project: Dictionary, workflow: Dictionary) -> Array[String]:
	var rich_value: Variant = workflow.get(PROJECT_KEY, {})
	var raw_ids: Variant = workflow.get("selected_character_ids", [])
	if rich_value is Dictionary and (rich_value as Dictionary).has("persistent_roster_ids"):
		raw_ids = (rich_value as Dictionary).get("persistent_roster_ids", [])
	var valid: Array[String] = []
	for character_id in _string_array(raw_ids):
		if CCFStorageService.character_index(project, character_id) >= 0:
			valid.append(character_id)
	return valid


static func _active_roster(
	project: Dictionary, workflow: Dictionary, roster: Array[String]
) -> Array[String]:
	var rich_value: Variant = workflow.get(PROJECT_KEY, {})
	if not rich_value is Dictionary:
		return roster.duplicate()
	var active: Array[String] = []
	for character_id in _string_array((rich_value as Dictionary).get("active_character_ids", roster)):
		if character_id in roster and CCFStorageService.character_index(project, character_id) >= 0:
			active.append(character_id)
	return active if not active.is_empty() else roster.duplicate()


static func _workflow_world_ids(workflow: Dictionary) -> Array[String]:
	var group_value: Variant = workflow.get("front_porch_group", {})
	if group_value is Dictionary:
		return _string_array((group_value as Dictionary).get("world_ids", []))
	return []


static func _combined_system_prompt(
	project: Dictionary, workflow: Dictionary, active_ids: Array[String]
) -> String:
	var names: Array[String] = []
	for character_id in active_ids:
		names.append(CCFRelationshipService.character_name(project, character_id))
	var lines := PackedStringArray([
		"Portray this ensemble as distinct characters: %s." % ", ".join(names),
		"Never collapse their memories, motives, speech patterns, or agency into one voice.",
		"Use the shared scenario and established relationship directions to coordinate turns."
	])
	var group_value: Variant = workflow.get("front_porch_group", {})
	if group_value is Dictionary:
		var configured := str((group_value as Dictionary).get("system_prompt", "")).strip_edges()
		if not configured.is_empty():
			lines.append(configured)
	return "\n".join(lines)


static func _dependency(
	target_kind: String, target_id: String, owner_kind: String, owner_id: String, reason: String
) -> Dictionary:
	return {
		"target_kind": target_kind, "target_id": target_id,
		"owner_kind": owner_kind, "owner_id": owner_id, "reason": reason
	}


static func _mapping_has_source(mappings: Variant, source_key: String) -> bool:
	if not mappings is Array:
		return false
	for raw_mapping in mappings:
		if raw_mapping is Dictionary and str(raw_mapping.get("source_key", "")) == source_key:
			return true
	return false


static func _dictionary_array(value: Variant) -> Array:
	var result: Array = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				result.append(item.duplicate(true))
	return result


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var clean := str(item).strip_edges()
			if not clean.is_empty() and clean not in result:
				result.append(clean)
	elif not str(value).strip_edges().is_empty():
		for item in str(value).replace("\n", ",").split(","):
			var clean := str(item).strip_edges()
			if not clean.is_empty() and clean not in result:
				result.append(clean)
	return result


static func _unique_existing_strings(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for raw_value in values:
		var clean := str(raw_value).strip_edges()
		if not clean.is_empty() and clean not in result:
			result.append(clean)
	return result


static func _new_id(prefix: String) -> String:
	var context := Crypto.new()
	return "%s_%s" % [prefix, context.generate_random_bytes(16).hex_encode()]
