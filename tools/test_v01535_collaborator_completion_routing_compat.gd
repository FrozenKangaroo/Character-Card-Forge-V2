extends SceneTree

const COMPLETION_SERVICE = preload(
	"res://scripts/services/collaborator_completion_service_v01535.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var template := CCFTemplateService.load_default_template()
	assert(not template.is_empty(), "v0.15.35 compatibility regression requires the default template.")

	var blank := CCFStorageService.new_character_record()
	var blank_id := str(blank.get("character_id", ""))
	assert(
		COMPLETION_SERVICE.is_effectively_empty_character(blank, template),
		"Later releases must retain v0.15.35 empty-slot detection."
	)
	assert(
		COMPLETION_SERVICE.recommended_destination(blank, template)
		== COMPLETION_SERVICE.DEST_CURRENT_EMPTY,
		"Later releases must retain v0.15.35 empty-slot routing."
	)

	var occupied := blank.duplicate(true)
	CCFStorageService.set_value_at_path(
		occupied,
		"concept.prompt",
		"Authored content that protects the current slot."
	)
	assert(
		COMPLETION_SERVICE.recommended_destination(occupied, template)
		== COMPLETION_SERVICE.DEST_SAME_PROJECT_NEW,
		"Later releases must retain the safe occupied-character default."
	)
	assert(
		not _option_ids(COMPLETION_SERVICE.destination_options(occupied, template)).has(
			COMPLETION_SERVICE.DEST_CURRENT_EMPTY
		),
		"Later releases must never re-expose the empty-slot overwrite route for occupied characters."
	)

	var source := {
		"format": "character_card_forge_collaborator_source",
		"format_version": 1,
		"source_context_id": "source-v01535-compat",
		"source_type": "character",
		"label": "Source Character",
		"snapshot": {"character_id": "source-character"},
		"provenance": {
			"derivation": {
				"source_project_id": "source-project",
				"source_character_id": "source-character",
				"derivation_type": "future_version"
			}
		}
	}
	var blueprint_payload := {
		"handoff_mode": "blueprint",
		"suggested_name": "Future Character",
		"concept_prompt": "A complete future-version Generation Concept."
	}
	var materialised := COMPLETION_SERVICE.materialise_character(
		blueprint_payload,
		"Future Character Session",
		template,
		COMPLETION_SERVICE.DEST_CURRENT_EMPTY,
		source,
		blank
	)
	assert(bool(materialised.get("ok", false)), "Later releases must retain v0.15.35 Blueprint materialisation.")
	var blank_record: Dictionary = materialised.get("character", {})
	assert(
		str(blank_record.get("character_id", "")) == blank_id,
		"Later releases must preserve the empty placeholder character ID."
	)
	assert(
		str(CCFStorageService.get_value_at_path(blank_record, "concept.prompt", ""))
		== "A complete future-version Generation Concept.",
		"Later releases must retain the generated Blueprint concept."
	)

	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null, "The real main scene must load for v0.15.35 compatibility coverage.")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var workspace_value: Variant = app.get("_workspace")
	assert(
		workspace_value is CCFWorkspaceV01535View,
		"The live Workspace must retain v0.15.35 completion-routing capability through inheritance."
	)
	var workspace := workspace_value as CCFWorkspaceV01535View
	var capabilities := workspace.collaborator_completion_capabilities_v01535()
	assert(bool(capabilities.get("empty_workspace_reuse", false)), "v0.15.35 empty-slot reuse must remain supported.")
	assert(bool(capabilities.get("same_project_new_character", false)), "v0.15.35 same-project creation must remain supported.")
	assert(bool(capabilities.get("new_project_destination", false)), "v0.15.35 new-project destination must remain supported.")

	var live_collaborator_value: Variant = workspace.get("_character_collaborator_window")
	assert(
		live_collaborator_value is CCFCharacterCollaboratorWindowV01535,
		"The live Collaborator must retain the v0.15.35 completion-routing UI capability."
	)
	var live_destination_value: Variant = workspace.get("_completion_destination_window_v01535")
	assert(
		live_destination_value is CCFCollaboratorCompletionDestinationWindowV01535,
		"The live destination chooser must retain the v0.15.35 destination contract."
	)

	var found_pending_menu := false
	for node in workspace.find_children("*", "MenuButton", true, false):
		if not node is MenuButton or (node as MenuButton).text != "Author":
			continue
		var popup := (node as MenuButton).get_popup()
		for index in range(popup.item_count):
			if popup.get_item_text(index) == "Place Pending Collaborator Completion…":
				found_pending_menu = true
				break
	assert(found_pending_menu, "Later releases must retain pending completion recovery.")

	assert(
		app.has_method("_update_build_version_label_v01535"),
		"The active app shell must retain the v0.15.35 shell capability through inheritance."
	)

	app.queue_free()
	await process_frame
	print("v0.15.35 Collaborator completion routing regression passed")
	quit(0)


func _option_ids(options: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for option in options:
		result.append(str(option.get("id", "")))
	return result
