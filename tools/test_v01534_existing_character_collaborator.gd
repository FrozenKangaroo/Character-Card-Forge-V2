extends SceneTree

const INTENT_SERVICE = preload(
	"res://scripts/services/collaborator_character_intent_service_v01534.gd"
)
const INTENT_WINDOW = preload(
	"res://scripts/ui/existing_character_collaborator_window_v01534.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options := INTENT_SERVICE.intent_options()
	assert(options.size() == 10, "v0.15.34 must expose the ten planned existing-character authoring directions.")
	var intent_ids := {}
	for option in options:
		intent_ids[str(option.get("id", ""))] = true
	for expected_id in [
		"refine",
		"alternative_version",
		"future_version",
		"past_version",
		"continue_after_event",
		"side_character_promotion",
		"relative_descendant",
		"connected_character",
		"same_setting",
		"open_ended"
	]:
		assert(intent_ids.has(expected_id), "Missing v0.15.34 author intent: %s" % expected_id)

	var character := {
		"character_id": "character-v01534-regression",
		"name": "Akari",
		"description": "Akari has long dark hair and works at the campus library.",
		"personality": "Patient but stubborn.",
		"scenario": "Akari already knows {{user}}."
	}
	var source := INTENT_SERVICE.build_source(
		character,
		"project-v01534-regression",
		"Regression Project",
		"Akari",
		{
			"intent_id": "future_version",
			"intent_label": "Future version",
			"instruction": "Explore her five years later after moving interstate."
		}
	)
	assert(not source.is_empty(), "Existing characters must build a structured Collaborator source.")
	assert(str(source.get("source_type", "")) == "character", "Existing-character handoff must use the established character source type.")
	assert(str(source.get("label", "")) == "Akari", "Existing-character source must keep the Workspace display name.")
	var snapshot: Dictionary = source.get("snapshot", {})
	assert(str(snapshot.get("description", "")) == str(character.get("description", "")), "Existing-character source must preserve the complete source snapshot.")
	var author_intent := str(source.get("author_intent", ""))
	assert(author_intent.contains("future version"), "Selected author intent must be model-facing Collaborator context.")
	assert(author_intent.contains("five years later"), "Optional starting direction must be preserved in author intent.")
	var provenance: Dictionary = source.get("provenance", {})
	var derivation: Dictionary = provenance.get("derivation", {})
	assert(str(derivation.get("source_project_id", "")) == "project-v01534-regression", "v0.15.34 must reuse source-project derivation provenance.")
	assert(str(derivation.get("source_character_id", "")) == "character-v01534-regression", "v0.15.34 must reuse source-character derivation provenance.")
	assert(str(derivation.get("source_character_name", "")) == "Akari", "Derivation provenance must preserve the source character name.")
	assert(str(derivation.get("derivation_type", "")) == "future_version", "Derivation provenance must store the selected stable author-intent ID.")
	assert(str(derivation.get("derivation_prompt", "")).contains("five years later"), "Derivation provenance must retain the author's starting direction.")
	assert(str(derivation.get("origin_workflow", "")) == "existing_character_collaborator_v01534", "Existing-character Collaborator provenance must identify the v0.15.34 workflow.")

	var chooser := INTENT_WINDOW.new() as CCFExistingCharacterCollaboratorWindowV01534
	root.add_child(chooser)
	await process_frame
	var chooser_ids := chooser.intent_ids_v01534()
	assert(chooser_ids.size() == options.size(), "The v0.15.34 chooser must render every service-defined author intent.")
	assert(chooser_ids.has("refine") and chooser_ids.has("open_ended"), "The chooser must include both focused and open-ended development.")

	var project_text := FileAccess.get_file_as_string("res://project.godot")
	assert(project_text.contains('config/features=PackedStringArray("4.7", "GL Compatibility")'), "Character Card Forge must advertise the Godot 4.7 project feature baseline.")

	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null, "The real main scene must load for v0.15.34 regression coverage.")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	assert(workspace_value is CCFWorkspaceV01534View, "The real main scene must install v0.15.34 or a later compatible Workspace.")
	var workspace := workspace_value as CCFWorkspaceV01534View
	var capabilities := workspace.collaborator_source_capabilities_v01533()
	assert(bool(capabilities.get("existing_character_workspace_action", false)), "v0.15.34 must expose Existing Character → Collaborator from Workspace.")
	assert(bool(capabilities.get("existing_character_author_intents", false)), "v0.15.34 must expose author-intent starting choices.")
	assert(bool(capabilities.get("derivation_provenance_compatible_v01410", false)), "v0.15.34 must remain compatible with v0.14.10 derivation provenance concepts.")
	var live_collaborator_value: Variant = workspace.get("_character_collaborator_window")
	assert(live_collaborator_value is CCFCharacterCollaboratorWindowV01534, "Live Workspace must retain the v0.15.34 source-aware Collaborator capability.")
	var live_chooser_value: Variant = workspace.get("_existing_character_collaborator_window_v01534")
	assert(live_chooser_value is CCFExistingCharacterCollaboratorWindowV01534, "Live Workspace must install the existing-character author-intent chooser.")

	var found_menu_action := false
	for node in workspace.find_children("*", "MenuButton", true, false):
		if not node is MenuButton or (node as MenuButton).text != "Author":
			continue
		var popup := (node as MenuButton).get_popup()
		for index in range(popup.item_count):
			if popup.get_item_text(index) == "Develop Current Character in Collaborator…":
				found_menu_action = true
				break
	assert(found_menu_action, "Author menu must expose Develop Current Character in Collaborator…")

	var main_script := app.get_script() as Script
	assert(main_script != null, "The active app shell must have a script.")
	assert(
		app.has_method("_update_build_version_label_v01534"),
		"The active app shell must retain the v0.15.34 shell capability through inheritance."
	)

	app.queue_free()
	chooser.queue_free()
	await process_frame
	print("v0.15.34 Existing Character Collaborator regression passed")
	quit(0)
