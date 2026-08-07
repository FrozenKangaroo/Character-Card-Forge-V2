extends SceneTree

const SOURCE_SERVICE = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)
const CARD_VISION_SERVICE = preload(
	"res://scripts/services/collaborator_card_vision_service_v01539.gd"
)


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V01539_REGRESSION_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	CCFStorageService.ensure_directories()

	var capabilities := CARD_VISION_SERVICE.capabilities()
	if not _require(bool(capabilities.get("character_card_png_dual_ingestion", false)), "Dual-ingestion capability must be enabled."):
		return
	if not _require(bool(capabilities.get("analyse_attached_card_later", false)), "Attached card images must support later Vision analysis."):
		return

	var combined_plan := CARD_VISION_SERVICE.ingestion_plan(CARD_VISION_SERVICE.MODE_CARD_AND_VISION)
	if not _require(bool(combined_plan.get("use_card_metadata", false)) and bool(combined_plan.get("use_vision", false)), "Card + Vision mode must enable both evidence paths."):
		return
	var card_only_plan := CARD_VISION_SERVICE.ingestion_plan(CARD_VISION_SERVICE.MODE_CARD_ONLY)
	if not _require(bool(card_only_plan.get("use_card_metadata", false)) and not bool(card_only_plan.get("use_vision", true)), "Card-only mode must not queue Vision."):
		return
	var vision_only_plan := CARD_VISION_SERVICE.ingestion_plan(CARD_VISION_SERVICE.MODE_VISION_ONLY)
	if not _require(not bool(vision_only_plan.get("use_card_metadata", true)) and bool(vision_only_plan.get("use_vision", false)), "Vision-only mode must not add structured metadata."):
		return

	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var character := CCFStorageService.get_character(project, character_id)
	CCFStorageService.set_value_at_path(character, "character.name", "Miya")
	CCFStorageService.set_value_at_path(
		character,
		"character.description",
		"Miya is {{user}}'s girlfriend of two years. This relationship fact belongs to the actual character card."
	)
	CCFStorageService.set_value_at_path(
		character,
		"character.creator_notes",
		"Keep Miya playful. <UserPersona>Damo, 20, Australian, glasses, Gundam fan.</UserPersona> End notes."
	)
	CCFStorageService.update_character(project, character)

	var source_png := CCFStorageService.ROOT_DIR.path_join("v01539_source.png")
	var card_png := CCFStorageService.ROOT_DIR.path_join("v01539_dual_card.png")
	var image := Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 0.5, 0.8, 1.0))
	if not _require(image.save_png(source_png) == OK, "Dual-ingestion fixture PNG must be writable."):
		return
	var png_result := CCFCardFormatService.write_png_card(
		source_png,
		card_png,
		project,
		character_id
	)
	if not _require(bool(png_result.get("ok", false)), "Character Card PNG fixture must export successfully."):
		return

	var loaded := SOURCE_SERVICE.from_card_file(card_png)
	if not _require(bool(loaded.get("ok", false)), "Character Card PNG must still load as structured Collaborator metadata."):
		return
	var source_value: Variant = loaded.get("source", {})
	if not _require(source_value is Dictionary, "Loaded Character Card must provide a source dictionary."):
		return
	var source: Dictionary = source_value
	if not _require(CARD_VISION_SERVICE.is_visual_card_source(source), "Character Card PNG must also be recognised as visual evidence."):
		return
	if not _require(CARD_VISION_SERVICE.source_image_path(source) == card_png, "Structured card source must retain the original PNG path for later Vision analysis."):
		return

	var raw_source := JSON.stringify(source.get("snapshot", {}))
	var ai_source := JSON.stringify(source.get("ai_snapshot", {}))
	if not _require(raw_source.contains("Damo"), "Raw PNG metadata must preserve embedded UserPersona residue for provenance."):
		return
	if not _require(not ai_source.contains("Damo"), "AI-facing PNG metadata must exclude embedded UserPersona residue."):
		return
	if not _require(ai_source.contains("Miya is {{user}}'s girlfriend"), "Real character-to-{{user}} relationship canon must survive UserPersona exclusion."):
		return
	if not _require(int(source.get("excluded_user_persona_count", 0)) >= 1, "PNG source must expose the UserPersona exclusion count."):
		return

	var fake_vision_context := {
		"context_id": "vision-context-v01539",
		"type": "vision_reference",
		"label": "v01539_dual_card.png",
		"content": "VISION DESCRIPTION OF USER-ATTACHED IMAGE\nThe visible artwork shows short dark hair and a blue jacket.",
		"vision_description": "The visible artwork shows short dark hair and a blue jacket.",
		"source_path": card_png,
		"vision_profile_id": "vision-profile-test",
		"vision_profile_name": "Vision Test",
		"vision_model": "vision-model-test"
	}
	var source_id := str(source.get("source_context_id", ""))
	var linked_context := CARD_VISION_SERVICE.annotate_vision_context(fake_vision_context, source_id)
	if not _require(str(linked_context.get("linked_source_context_id", "")) == source_id, "Vision context must link back to the structured card source ID."):
		return
	if not _require(str(linked_context.get("context_provenance", "")) == "vision_description_linked_to_character_card_source", "Linked Vision context needs explicit dual-ingestion provenance."):
		return

	var marked_source := CARD_VISION_SERVICE.mark_source_vision_analysis(
		source,
		linked_context,
		{
			"vision_profile_id": "vision-profile-test",
			"vision_profile_name": "Vision Test",
			"vision_model": "vision-model-test"
		}
	)
	var marked_provenance: Dictionary = marked_source.get("provenance", {})
	var visual_analysis_value: Variant = marked_provenance.get("visual_analysis", {})
	if not _require(visual_analysis_value is Dictionary and str((visual_analysis_value as Dictionary).get("status", "")) == "available", "Structured source provenance must record linked Vision availability without merging its content into card metadata."):
		return
	if not _require(JSON.stringify(marked_source.get("snapshot", {})).contains("Damo"), "Linking Vision must not destructively rewrite the raw card snapshot."):
		return
	if not _require(not JSON.stringify(marked_source.get("ai_snapshot", {})).contains("Damo"), "Linking Vision must not reintroduce excluded UserPersona text."):
		return
	if not _require(CARD_VISION_SERVICE.source_has_linked_vision(marked_source, [linked_context]), "Linked Vision context must be discoverable for the source-row UI."):
		return

	var context_block := SOURCE_SERVICE.model_context_block([marked_source])
	if not _require(not context_block.contains("Damo"), "UserPersona residue must remain absent from model-facing structured context after Vision linkage."):
		return
	if not _require(context_block.contains("Miya is {{user}}'s girlfriend"), "Structured model context must retain actual {{user}} relationship facts after Vision linkage."):
		return

	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.15.39 real main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v01539"), "The active application shell must be v0.15.39."):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(workspace_value is CCFWorkspaceV01539View, "The real app must install the v0.15.39 Workspace while retaining earlier generation/Image Studio layers."):
		return
	var workspace := workspace_value as CCFWorkspaceV01539View
	var workspace_caps := workspace.multi_source_collaborator_capabilities_v01537()
	if not _require(bool(workspace_caps.get("card_metadata_and_vision_together", false)), "Workspace must advertise Character Card metadata + Vision support."):
		return
	if not _require(bool(workspace_caps.get("embedded_user_persona_excluded", false)), "Workspace must retain embedded UserPersona exclusion."):
		return

	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(collaborator_value is CCFCharacterCollaboratorWindowV01539, "The real Workspace must install the v0.15.39 Collaborator window."):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV01539
	var collaborator_caps := collaborator.card_png_dual_ingestion_capabilities_v01539()
	if not _require(bool(collaborator_caps.get("vision_does_not_overwrite_card_metadata", false)), "Live Collaborator must expose non-destructive dual-ingestion semantics."):
		return
	var mode_value: Variant = collaborator.get("_card_ingestion_mode_v01539")
	if not _require(mode_value is OptionButton and (mode_value as OptionButton).item_count == 3, "Character Card PNG chooser must expose exactly three ingestion modes."):
		return
	var attachment_dialog_value: Variant = collaborator.get("_attachment_dialog_v01521")
	if not _require(attachment_dialog_value is FileDialog and " ".join(Array((attachment_dialog_value as FileDialog).filters)).contains("*.apng"), "Collaborator attachment picker must expose APNG alongside PNG."):
		return

	app.queue_free()
	await process_frame
	print("v0.15.39 Character Card PNG dual-ingestion regression passed")
	quit(0)
