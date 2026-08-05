extends SceneTree

const SOURCE_SERVICE = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	CCFStorageService.ensure_directories()

	var pasted_text := "<Miya's Persona>\nMiya is {{user}}'s girlfriend of two years and knows how to tease him.\n</Miya's Persona>\n\n<UserPersona>\nMale, 20 years old, Australian, called Damo, wears glasses and likes Gundam.\n</UserPersona>"
	var pasted := SOURCE_SERVICE.from_pasted_text(pasted_text, "Miya extracted card")
	assert(not pasted.is_empty(), "Pasted card-like text must become a Collaborator source.")
	var raw_text := str((pasted.get("snapshot", {}) as Dictionary).get("text", ""))
	var ai_text := str((pasted.get("ai_snapshot", {}) as Dictionary).get("text", ""))
	assert(raw_text.contains("Damo"), "The raw source snapshot must preserve excluded UserPersona text for provenance.")
	assert(not ai_text.contains("Damo"), "The AI-facing source must exclude the embedded UserPersona block.")
	assert(ai_text.contains("Miya is {{user}}'s girlfriend"), "Character-established relationship facts involving {{user}} must remain in AI context.")
	assert(int(pasted.get("excluded_user_persona_count", 0)) >= 1, "UserPersona exclusion must be visible in source metadata.")

	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var character := CCFStorageService.get_character(project, character_id)
	CCFStorageService.set_value_at_path(character, "character.name", "Miya")
	CCFStorageService.set_value_at_path(character, "character.description", "Miya is {{user}}'s long-term girlfriend.")
	CCFStorageService.update_character(project, character)
	character = CCFStorageService.get_character(project, character_id)
	var target := SOURCE_SERVICE.from_character(
		character,
		str(project.get("project_id", "")),
		"Miya Project",
		SOURCE_SERVICE.ROLE_TARGET
	)
	assert(SOURCE_SERVICE.can_be_target(target), "A Workspace character with a stable ID must be eligible as the explicit target.")
	assert(str(target.get("source_role", "")) == SOURCE_SERVICE.ROLE_TARGET, "The refinement target role must be retained.")

	var saved_idea := {
		"id": "idea_test_1",
		"format": "character_card_forge_saved_idea",
		"format_version": 1,
		"title": "Birthday complication",
		"character_name": "Miya",
		"character_role": "Partner",
		"source_anchor": "Existing relationship",
		"roleplay_hook": "A surprise changes the evening.",
		"concept": "Develop a new scenario around Miya and {{user}} without defining {{user}}'s personal identity.",
		"tags": ["scenario"]
	}
	var idea_source := SOURCE_SERVICE.from_saved_idea(saved_idea)
	var sources := SOURCE_SERVICE.normalise_collection([target, pasted, idea_source])
	assert(sources.size() == 3, "Three individually identified sources must survive collection normalisation.")
	var target_count := 0
	for source in sources:
		if str(source.get("source_role", "")) == SOURCE_SERVICE.ROLE_TARGET:
			target_count += 1
	assert(target_count == 1, "A multi-source session must have at most one explicit Compare & Apply target.")

	var block := SOURCE_SERVICE.model_context_block(sources)
	assert(block.contains("Source count: 3"), "The model context must identify the multi-source collection.")
	assert(block.contains("Miya is {{user}}'s girlfriend"), "Character-established {{user}} relationship facts must remain available to the model.")
	assert(not block.contains("called Damo"), "Excluded UserPersona text must never leak into the model-facing multi-source block.")
	assert(block.contains("TARGET"), "The model must be told which source is the target.")
	assert(block.contains("REFERENCE"), "The model must be told which sources are references.")

	var source_png := CCFStorageService.ROOT_DIR.path_join("v01537_source.png")
	var card_png := CCFStorageService.ROOT_DIR.path_join("v01537_card.png")
	var image := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	assert(image.save_png(source_png) == OK, "Regression fixture PNG must be writable.")
	var export_character := CCFStorageService.get_character(project, character_id)
	CCFStorageService.set_value_at_path(
		export_character,
		"character.creator_notes",
		"Character notes remain. <UserPersona>Damo, Australian, glasses.</UserPersona> End notes."
	)
	CCFStorageService.update_character(project, export_character)
	var png_result := CCFCardFormatService.write_png_card(
		source_png,
		card_png,
		project,
		character_id
	)
	assert(bool(png_result.get("ok", false)), "A Character Card PNG fixture must export successfully.")
	var attached := SOURCE_SERVICE.from_card_file(card_png)
	assert(bool(attached.get("ok", false)), "A Character Card PNG must be loadable directly as a Collaborator source.")
	var attached_source: Dictionary = attached.get("source", {})
	var attached_raw := JSON.stringify(attached_source.get("snapshot", {}))
	var attached_ai := JSON.stringify(attached_source.get("ai_snapshot", {}))
	assert(attached_raw.contains("Damo"), "Attached card raw provenance must preserve the original embedded UserPersona.")
	assert(not attached_ai.contains("Damo"), "Attached card AI context must exclude embedded UserPersona residue.")
	assert(attached_ai.contains("Miya is {{user}}'s long-term girlfriend"), "Attached card sanitisation must keep actual character relationship canon.")

	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null, "The v0.15.37 real main scene must load.")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	assert(app.has_method("_update_build_version_label_v01537"), "The active shell must be v0.15.37.")
	var workspace_value: Variant = app.get("_workspace")
	assert(workspace_value is CCFWorkspaceV01537View, "The real app must install the v0.15.37 Workspace.")
	var workspace := workspace_value as CCFWorkspaceV01537View
	var caps := workspace.multi_source_collaborator_capabilities_v01537()
	assert(bool(caps.get("multi_source", false)), "Workspace must expose multi-source Collaborator capability.")
	assert(bool(caps.get("embedded_user_persona_excluded", false)), "Workspace capability must expose UserPersona exclusion.")

	app.queue_free()
	await process_frame
	print("v0.15.37 multi-source Collaborator regression passed")
	quit(0)
