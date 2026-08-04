extends SceneTree

const SOURCE_SERVICE = preload(
	"res://scripts/services/collaborator_source_context_service_v01533.gd"
)
const GENERATION_SERVICE = preload(
	"res://scripts/services/generation_service_v01533.gd"
)
const COLLABORATOR_WINDOW = preload(
	"res://scripts/ui/character_collaborator_window_v01533.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var idea := {
		"title": "Assigned the Wrong Dorm Room",
		"character_name": "Mina",
		"character_role": "{{user}}'s unexpectedly assigned dorm mate",
		"source_anchor": "a university housing error",
		"roleplay_hook": "They must decide how to live together.",
		"concept": "Mina and {{user}} are accidentally assigned the same university dorm room.",
		"tags": ["university", "roommates", "romance"]
	}
	var generated_source := SOURCE_SERVICE.from_generated_idea(
		idea,
		{"seed": "dorm mix-up", "idea_contract_version": "user_centric_roleplay_v3"}
	)
	assert(SOURCE_SERVICE.is_valid(generated_source), "Generated ideas must create valid v0.15.33 Collaborator sources.")
	assert(str(generated_source.get("source_type", "")) == "generated_idea", "Generated source type must be explicit.")
	assert(not bool((generated_source.get("provenance", {}) as Dictionary).get("saved_to_notebook", true)), "Sending an unsaved generated idea to Collaborator must not mark/save it as Notebook material.")
	var generated_block := SOURCE_SERVICE.model_context_block(generated_source)
	assert(generated_block.contains("ESTABLISHED SOURCE FACTS"), "Source prompt must distinguish established facts.")
	assert(generated_block.contains("AUTHOR-REQUESTED CHANGES"), "Source prompt must distinguish requested changes.")
	assert(generated_block.contains("NEW/PROPOSED DETAILS"), "Source prompt must distinguish new details.")
	assert(generated_block.contains("Assigned the Wrong Dorm Room"), "Model source block must preserve generated idea content.")

	var saved_idea := idea.duplicate(true)
	saved_idea["id"] = "idea-regression"
	saved_idea["notebook_id"] = "notebook-regression"
	saved_idea["format"] = "character_card_forge_saved_idea"
	saved_idea["format_version"] = 1
	var saved_source := SOURCE_SERVICE.from_saved_idea(saved_idea)
	assert(str(saved_source.get("source_type", "")) == "saved_idea", "Saved Notebook ideas must have their own source type.")
	var saved_provenance: Dictionary = saved_source.get("provenance", {})
	assert(str(saved_provenance.get("idea_id", "")) == "idea-regression", "Saved idea source must preserve Idea Notebook provenance.")
	assert(str(saved_provenance.get("notebook_id", "")) == "notebook-regression", "Saved idea source must preserve notebook provenance.")

	var character_source := SOURCE_SERVICE.from_character(
		{
			"character_id": "character-regression",
			"name": "Akari",
			"description": "Akari has long dark hair.",
			"personality": "Patient but stubborn.",
			"scenario": "Akari already knows {{user}}."
		},
		"project-regression",
		"Regression Family"
	)
	assert(str(character_source.get("source_type", "")) == "character", "v0.15.33 must establish the existing-character source schema for v0.15.34.")
	assert(str((character_source.get("snapshot", {}) as Dictionary).get("scenario", "")) == "Akari already knows {{user}}.", "Character source snapshot must preserve structured card facts.")

	var collaborator := COLLABORATOR_WINDOW.new() as CCFCharacterCollaboratorWindowV01533
	root.add_child(collaborator)
	await process_frame
	await process_frame
	var started := collaborator.start_source_session_v01533(generated_source)
	assert(bool(started.get("ok", false)), "Collaborator must publicly start a source-aware session.")
	var active_source := collaborator.active_source_context_v01533()
	assert(str(active_source.get("source_context_id", "")) == str(generated_source.get("source_context_id", "")), "Active Collaborator session must retain its source snapshot identity.")
	var active_session_value: Variant = collaborator.call("_active_session")
	assert(active_session_value is Dictionary, "Collaborator must have an active persisted session.")
	var active_session: Dictionary = active_session_value
	assert(active_session.has("source_context"), "Source context must persist as first-class Collaborator session data.")
	var blocks_value: Variant = collaborator.call("_context_blocks")
	assert(blocks_value is Array, "Source-aware Collaborator must still produce normal context blocks.")
	var blocks: Array = blocks_value
	assert(not blocks.is_empty() and str(blocks[0]).contains("COLLABORATOR SOURCE CONTEXT"), "Source context must be prepended to every model-facing Collaborator request.")
	var source_panel_value: Variant = collaborator.get("_source_panel_v01533")
	assert(source_panel_value is VBoxContainer and (source_panel_value as VBoxContainer).visible, "Source-aware conversations must show a visible source panel.")

	var generation := GENERATION_SERVICE.new() as CCFGenerationServiceV01533
	root.add_child(generation)
	await process_frame
	var empty_parse: Dictionary = generation.call("_safe_provider_envelope_v01533", "", 200)
	assert(not bool(empty_parse.get("ok", true)), "Empty provider bodies must be rejected without JSON.parse_string engine errors.")
	assert(str(empty_parse.get("reason", "")) == "empty_body", "Empty provider body must have a clear failure reason.")
	var malformed_parse: Dictionary = generation.call("_safe_provider_envelope_v01533", "<html>gateway timeout", 502)
	assert(not bool(malformed_parse.get("ok", true)), "Non-JSON provider bodies must be rejected silently.")
	assert(str(malformed_parse.get("detail", "")).contains("HTTP 502"), "Malformed-response diagnostics must retain HTTP status.")
	var valid_parse: Dictionary = generation.call("_safe_provider_envelope_v01533", "{\"choices\":[]}", 200)
	assert(bool(valid_parse.get("ok", false)), "Valid provider JSON envelopes must continue through the established generation pipeline.")
	var hardening: Dictionary = generation.provider_response_hardening_capabilities_v01533()
	assert(bool(hardening.get("raw_body_diagnostics", false)), "Provider hardening must preserve raw response diagnostics.")

	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null, "The real main scene must load for v0.15.33 regression coverage.")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	assert(workspace_value is CCFWorkspaceV01533View, "The real main scene must install the v0.15.33 Workspace or a compatible hotfix subclass.")
	var workspace := workspace_value as CCFWorkspaceV01533View
	var live_collaborator_value: Variant = workspace.get("_character_collaborator_window")
	assert(live_collaborator_value is CCFCharacterCollaboratorWindowV01533, "Live Workspace must install the v0.15.33 source-aware Collaborator.")
	var generator_value: Variant = workspace.get("_idea_generator_v01532")
	assert(generator_value is CCFIdeaGeneratorWindowV01533, "Live Workspace must retain hotfix1 AI Ideas layout while installing v0.15.33 handoffs.")
	var generator := generator_value as CCFIdeaGeneratorWindowV01533
	var generated_button := generator.find_child("DevelopGeneratedIdeaV01533", true, false)
	var saved_button := generator.find_child("DevelopSavedIdeaV01533", true, false)
	assert(generated_button is Button, "AI Ideas must expose Develop Generated Idea in v0.15.33.")
	assert(saved_button is Button, "Idea Notebook must expose Develop in Collaborator in v0.15.33.")
	var callback := Callable(workspace, "_on_collaborator_source_requested_v01533")
	assert(generator.is_connected("collaborator_source_requested", callback), "Idea Generator handoffs must be wired to the live Workspace Collaborator source API.")
	var services: Dictionary = workspace.concurrent_services_v01526()
	for role in ["primary", "collaborator", "ideas", "tools", "vision"]:
		var worker: Variant = services.get(role)
		assert(worker is CCFGenerationServiceV01533, "Every live concurrent worker must use the v0.15.33 hardened provider service.")
	assert(
		app.has_method("_update_build_version_label_v01533"),
		"The active scene must retain the v0.15.33 app-shell capability even when a later hotfix subclasses it."
	)

	app.queue_free()
	collaborator.queue_free()
	generation.queue_free()
	await process_frame
	print("v0.15.33 Collaborator source context regression passed")
	quit(0)
