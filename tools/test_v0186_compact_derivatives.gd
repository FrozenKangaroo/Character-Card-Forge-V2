extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0186_COMPACT_DERIVATIVE_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _make_project() -> Dictionary:
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var record := CCFStorageService.get_character(project, character_id)
	var metadata: Dictionary = record.get("metadata", {}).duplicate(true)
	metadata["name"] = "Ilyra Voss"
	metadata["tags"] = ["archivist", "fantasy", "slow burn"]
	record["metadata"] = metadata
	var card: Dictionary = record.get("character", {}).duplicate(true)
	card["name"] = "Ilyra Voss"
	card["description"] = "Ilyra is the meticulous keeper of a wandering archive. " .repeat(40)
	card["personality"] = "Patient, observant, gently sardonic, and fiercely protective of fragile stories. ".repeat(30)
	card["scenario"] = "A storm strands {{user}} inside Ilyra's impossible archive. ".repeat(20)
	card["first_message"] = "Mind the blue shelves. They remember everyone who lies to them."
	card["example_dialogue"] = "{{char}}: Every missing page leaves a shape behind.\n{{user}}: Can we follow it?"
	card["creator_notes"] = "Preserve her careful cadence and never prescribe {{user}}'s feelings."
	card["system_prompt"] = "Keep the archive internally consistent."
	card["post_history_instructions"] = "Track recovered volumes without narrating for {{user}}."
	card["alternate_greetings"] = ["The east wing has started whispering again."]
	card["character_book"] = {"entries": [{"keys": ["Blue shelves"], "content": "They record deliberate lies."}]}
	card["card_extensions"] = {
		"front_porch": {
			"version": "2.5",
			"realism_engine": {
				"ambitions": ["Restore the index"],
				"intimate_preferences": {"into": ["patient trust"], "not_into": ["humiliation"]}
			}
		}
	}
	record["character"] = card
	var generation: Dictionary = record.get("generation", {}).duplicate(true)
	generation["image_style_default_v0169"] = {"id": "ink", "name": "Ink"}
	record["generation"] = generation
	var workspace: Dictionary = record.get("workspace", {}).duplicate(true)
	workspace[CCFFrontPorchSyncServiceV0185.BINDING_KEY] = {"remote_id": "remote-ilyra", "last_exchanged_fingerprint": "old"}
	record["workspace"] = workspace
	CCFRevisionServiceV0181.create_checkpoint(record, "Finished source", "Fixture baseline", "manual", {}, true)
	var characters: Array = project.get("characters", []).duplicate(true)
	characters[0] = record
	project["characters"] = characters
	return project


func _mock_result(requested_paths: Array) -> Dictionary:
	var fields := {}
	for path_value in requested_paths:
		var path := str(path_value)
		fields[path] = {
			"character.description": "Keeper of a wandering archive whose blue shelves remember deliberate lies.",
			"character.personality": "Patient, observant, gently sardonic, and protective of fragile stories.",
			"character.scenario": "A storm strands {{user}} inside Ilyra's impossible archive.",
			"character.first_message": "Mind the blue shelves. They remember everyone who lies to them.",
			"character.creator_notes": "Preserve her careful cadence and {{user}}'s agency.",
			"character.system_prompt": "Keep the archive internally consistent.",
			"character.post_history_instructions": "Track recovered volumes without narrating for {{user}}.",
			"character.example_dialogue": "{{char}}: Every missing page leaves a shape behind."
		}.get(path, "Compact replacement")
	return {"summary": "Removed repetition while preserving the archive hook.", "fields": fields}


func _find_button(root: Node, text_value: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if node is Button and node.text == text_value:
			return node
	return null


func _run() -> void:
	var capabilities := CCFCompactDerivativeServiceV0186.capabilities()
	if not _require(
		bool(capabilities.get("independent_character_only", false))
		and bool(capabilities.get("source_content_hash_guard", false))
		and bool(capabilities.get("complete_field_comparison", false))
		and bool(capabilities.get("editable_before_save", false))
		and not bool(capabilities.get("source_overwrite", true))
		and not bool(capabilities.get("automatic_save", true)),
		"v0.18.6 must advertise its independent, review-first safety boundary."
	):
		return
	var project := _make_project()
	var source_id := CCFStorageService.active_character_id(project)
	var source_before := CCFStorageService.get_character(project, source_id).duplicate(true)
	var source_hash := CCFCompactDerivativeServiceV0186.source_content_hash(project, source_id)
	var before_tokens := CCFCompactDerivativeServiceV0186.estimated_tokens(project, source_id)
	if not _require(
		not source_hash.is_empty()
		and before_tokens > 500
		and CCFCompactDerivativeServiceV0186.suggested_target(before_tokens, "gentle")
		> CCFCompactDerivativeServiceV0186.suggested_target(before_tokens, "extreme"),
		"Source hashing and the four progressively smaller target levels must be deterministic."
	):
		return

	var options := CCFCompactDerivativeServiceV0186.default_options(project, source_id)
	options["compression_level"] = "aggressive"
	options["target_tokens"] = 650
	options["preserve_examples"] = true
	var adult_only_options := options.duplicate(true)
	adult_only_options["preserve_front_porch"] = false
	adult_only_options["preserve_adult_traits"] = true
	var adult_only := CCFCompactDerivativeServiceV0186.build_candidate(
		source_before, adult_only_options
	)
	var no_adult_options := options.duplicate(true)
	no_adult_options["preserve_front_porch"] = true
	no_adult_options["preserve_adult_traits"] = false
	var no_adult := CCFCompactDerivativeServiceV0186.build_candidate(
		source_before, no_adult_options
	)
	if not _require(
		CCFStorageService.get_value_at_path(
			adult_only,
			"character.card_extensions.front_porch.realism_engine.intimate_preferences",
			null
		) is Dictionary
		and CCFStorageService.get_value_at_path(
			adult_only,
			"character.card_extensions.front_porch.realism_engine.ambitions",
			null
		) == null
		and CCFStorageService.get_value_at_path(
			no_adult,
			"character.card_extensions.front_porch.realism_engine.ambitions",
			null
		) is Array
		and CCFStorageService.get_value_at_path(
			no_adult,
			"character.card_extensions.front_porch.realism_engine.intimate_preferences",
			null
		) == null,
		"Front Porch/state and adult-trait preservation controls must remain independent."
	):
		return
	var request := CCFCompactDerivativeServiceV0186.build_request(project, source_id, options)
	var requested_paths: Array = request.get("requested_paths", [])
	if not _require(
		bool(request.get("ok", false))
		and not requested_paths.has("character.example_dialogue")
		and str(request.get("source_hash", "")) == source_hash
		and JSON.stringify(request.get("messages", [])).contains("target_tokens"),
		"The request must honour preserved examples and carry the target budget and source hash."
	):
		return

	var validated := CCFCompactDerivativeServiceV0186.validate_result(
		project, source_id, _mock_result(requested_paths), options
	)
	var candidate: Dictionary = validated.get("candidate", {})
	if not _require(
		bool(validated.get("ok", false))
		and int(validated.get("after_tokens", before_tokens)) < before_tokens
		and CCFStorageService.get_value_at_path(candidate, "character.example_dialogue", "")
		== CCFStorageService.get_value_at_path(source_before, "character.example_dialogue", "")
		and CCFCompactDerivativeServiceV0186.comparison_rows(source_before, candidate).size() == 8,
		"Validated previews must compress requested fields, preserve locked material and expose the complete comparison set."
	):
		return

	var created := CCFCompactDerivativeServiceV0186.create_derivative(
		project,
		source_id,
		candidate,
		"Ilyra Voss — Lite",
		options,
		{"model": "fixture-model", "profile_name": "Fixture Text", "profile_id": "fixture"},
		source_hash
	)
	var updated: Dictionary = created.get("project", {})
	var derivative_id := str(created.get("character_id", ""))
	var derivative := CCFStorageService.get_character(updated, derivative_id)
	var source_after := CCFStorageService.get_character(updated, source_id)
	var lineage_value: Variant = derivative.get(CCFRevisionServiceV0181.LINEAGE_KEY, {})
	var provenance_value: Variant = derivative.get(CCFCompactDerivativeServiceV0186.PROVENANCE_KEY, {})
	var portable := CCFCardFormatService.export_character_v2(updated, derivative_id)
	if not _require(
		bool(created.get("ok", false))
		and updated.get("characters", []).size() == 2
		and source_after == source_before
		and derivative_id != source_id
		and lineage_value is Dictionary
		and str((lineage_value as Dictionary).get("source_character_id", "")) == source_id
		and provenance_value is Dictionary
		and str((provenance_value as Dictionary).get("model", "")) == "fixture-model"
		and CCFRevisionServiceV0181.list_revisions(derivative).size() == 1
		and not JSON.stringify(portable).contains(CCFCompactDerivativeServiceV0186.PROVENANCE_KEY)
		and not JSON.stringify(portable).contains("fixture-model")
		and CCFFrontPorchSyncServiceV0185.binding_for_character(updated, derivative_id).is_empty(),
		"Creation must append an independent revisioned character while source, private provenance and remote identity remain safe."
	):
		return

	var changed_project := project.duplicate(true)
	var changed_source := CCFStorageService.get_character(changed_project, source_id)
	CCFStorageService.set_value_at_path(changed_source, "character.personality", "Changed after preview")
	var changed_characters: Array = changed_project.get("characters", []).duplicate(true)
	changed_characters[0] = changed_source
	changed_project["characters"] = changed_characters
	var stale := CCFCompactDerivativeServiceV0186.create_derivative(
		changed_project, source_id, candidate, "Stale", options, {}, source_hash
	)
	if not _require(
		not bool(stale.get("ok", true)) and bool(stale.get("stale", false)),
		"A changed source must invalidate an older derivative preview."
	):
		return

	var window := CCFCompactDerivativeWindowV0186.new()
	window.visible = false
	get_root().add_child(window)
	await process_frame
	window.open_for_character(project, source_id)
	var window_caps := window.compact_derivative_window_capabilities_v0186()
	if not _require(
		bool(window_caps.get("target_budget", false))
		and bool(window_caps.get("four_levels", false))
		and bool(window_caps.get("seven_preservation_controls", false))
		and bool(window_caps.get("editable_comparison", false))
		and bool(window_caps.get("create_disabled_before_preview", false)),
		"The live derivative window must expose target, levels, preservation and disabled-before-preview creation."
	):
		return
	window.begin_generation("fixture-job")
	if not _require(
		window.handle_job_completed(
			"fixture-job",
			_mock_result(requested_paths),
			{
				"source_hash": source_hash,
				"compact_options": options,
				"model": "fixture-model",
				"profile_name": "Fixture Text"
			}
		),
		"The live window must accept a matching reviewed preview."
	):
		return
	window.queue_free()
	await process_frame

	var packed := load("res://scenes/main.tscn") as PackedScene
	var app := packed.instantiate()
	get_root().add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.18.6", "Godot rewrite • v0.19.0",
			"Godot rewrite • v0.19.1", "Godot rewrite • v0.19.2",
			"Godot rewrite • v0.19.3", "Godot rewrite • v0.19.3-hotfix1",
			"Godot rewrite • v0.19.4"
		]:
			version_found = true
			break
	if not _require(
		workspace_value is CCFWorkspaceV0186View
		and workspace_value.get("_generation_service") is CCFGenerationServiceV0186
		and _find_button(workspace_value, "Create Compact/Lite Derivative…") != null
		and version_found,
		"The live v0.18.6 app must install the derivative tool and current generation service."
	):
		return
	app.queue_free()
	await process_frame
	print("V0186_COMPACT_DERIVATIVE_OK")
	quit(0)
