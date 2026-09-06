extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0171_SOURCE_PRECEDENCE_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var target := CCFCollaboratorSourceContextServiceV01537.from_character(
		{
			"character_id": "target_v0171",
			"character": {
				"name": "Mira",
				"description": "Mira has green eyes and a scar over her left eyebrow."
			}
		},
		"project_v0171",
		"Precedence Regression",
		CCFCollaboratorSourceContextServiceV01537.ROLE_TARGET
	)
	var card := CCFCollaboratorSourceContextServiceV01537.upgrade_source({
		"source_context_id": "card_source_v0171",
		"source_type": CCFCollaboratorSourceContextServiceV01537.TYPE_EXTERNAL_CARD,
		"label": "Mira reference card",
		"snapshot": {
			"normalised_card": {
				"data": {
					"name": "Mira",
					"description": "Mira has green eyes and a scar over her left eyebrow."
				}
			}
		},
		"provenance": {
			"origin": "external_character_card",
			"source_path": "user://mira_card.png"
		},
		"source_role": "reference"
	})
	var image := CCFImageCollaboratorHandoffServiceV0170.from_result(
		{
			"project_id": "project_v0171",
			"metadata": {"name": "Precedence Regression"}
		},
		{
			"character_id": "target_v0171",
			"character": {"name": "Mira"}
		},
		{
			"image_id": "image_v0171",
			"path": "characters/target_v0171/generated_images/mira.png",
			"execution_snapshot_v01610": {
				"model": "image-model-v0171",
				"profile_name": "Image Profile",
				"composed_prompt": "Mira with amber eyes and no visible scar",
				"seed": 171
			}
		},
		"user://character_card_forge/projects/project_v0171/mira.png"
	)
	var card_vision := CCFCollaboratorCardVisionServiceV01539.annotate_vision_context(
		{
			"context_id": "card_vision_v0171",
			"type": "vision_reference",
			"label": "Mira card artwork",
			"content": "The visible portrait appears to have blue eyes; the eyebrow area is partly obscured."
		},
		str(card.get("source_context_id", "")),
		str(card.get("source_type", ""))
	)
	var image_vision := CCFCollaboratorCardVisionServiceV01539.annotate_vision_context(
		{
			"context_id": "image_vision_v0171",
			"type": "vision_reference",
			"label": "Generated portrait",
			"content": "The image appears to show green eyes and a faint left-eyebrow scar."
		},
		str(image.get("source_context_id", "")),
		str(image.get("source_type", ""))
	)
	var sources: Array[Dictionary] = [target, card, image]
	var contexts: Array[Dictionary] = [card_vision, image_vision]
	var sources_before := sources.duplicate(true)
	var contexts_before := contexts.duplicate(true)
	var view := CCFCollaboratorSourcePrecedenceServiceV0171.presentation(
		sources, contexts
	)
	if not _require(
		int(view.get("source_count", 0)) == 3
		and bool(view.get("has_target", false))
		and bool(view.get("needs_conflict_review", false)),
		"The evidence view must identify three sources, one target and review-worthy cross-evidence pairs."
	):
		return
	var rows: Array = view.get("rows", [])
	var roles := {}
	for raw_row in rows:
		if raw_row is Dictionary:
			roles[str((raw_row as Dictionary).get("source_type", ""))] = str(
				(raw_row as Dictionary).get("evidence_role_id", "")
			)
	if not _require(
		roles.get("character")
		== CCFCollaboratorSourcePrecedenceServiceV0171.ROLE_TARGET_CANON
		and roles.get("external_character_card")
		== CCFCollaboratorSourcePrecedenceServiceV0171.ROLE_STRUCTURED_FACTS
		and roles.get("image_studio_result")
		== CCFCollaboratorSourcePrecedenceServiceV0171.ROLE_CREATIVE_INTENT,
		"Target, card metadata and Image Studio prompt must receive distinct evidence roles."
	):
		return
	var notices_text := "\n".join(view.get("notices", []))
	if not _require(
		notices_text.contains("only current character eligible for Compare & Apply")
		and notices_text.contains("embedded Character Card data and linked Vision evidence")
		and notices_text.contains("Image Studio prompt and linked Vision evidence"),
		"The presentation must explain target precedence and both structured/Vision review boundaries."
	):
		return
	var model_block := CCFCollaboratorSourcePrecedenceServiceV0171.model_precedence_block(
		sources, contexts
	)
	if not _require(
		model_block.contains("TARGET CANON is the sole current character")
		and model_block.contains("Vision is SUPPLEMENTARY OBSERVATION")
		and model_block.contains("CREATIVE INTENT — Image Studio Result"),
		"The model-facing contract must carry the same evidence roles and conflict policy."
	):
		return
	var card_review := CCFCollaboratorSourcePrecedenceServiceV0171.evidence_review_text(
		card, contexts
	)
	if not _require(
		card_review.contains("STRUCTURED / RAW SOURCE SNAPSHOT")
		and card_review.contains("LINKED VISION — SEPARATE SUPPLEMENTARY OBSERVATION")
		and card_review.contains("green eyes")
		and card_review.contains("blue eyes"),
		"Evidence review must display structured card facts and linked Vision observation without merging them."
	):
		return
	if not _require(
		sources == sources_before and contexts == contexts_before,
		"Precedence presentation must never mutate stored sources or Vision evidence."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.17.1 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(
		app.has_method("_update_build_version_label_v0171"),
		"The active application shell must identify v0.17.1."
	):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0171View,
		"The application must install the v0.17.1 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0171View
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(
		collaborator_value is CCFCharacterCollaboratorWindowV0171,
		"The Workspace must install the v0.17.1 evidence-aware Collaborator."
	):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV0171
	if not _require(
		collaborator.precedence_surface_ready_v0171(),
		"The live Collaborator must expose the Evidence roles & conflict review surface."
	):
		return
	var started := collaborator.start_source_session_v01533(target)
	if not _require(bool(started.get("ok", false)), "The test target source must start a Collaborator session."):
		return
	if not _require(
		bool(collaborator.add_source_v01537(card, false).get("ok", false))
		and bool(collaborator.add_source_v01537(image, false).get("ok", false)),
		"The live Collaborator must accept card and Image Studio references."
	):
		return
	collaborator.call("_add_context_item", card_vision)
	collaborator.call("_add_context_item", image_vision)
	collaborator.call("_refresh_all")
	await process_frame
	var live_view := collaborator.precedence_surface_snapshot_v0171()
	if not _require(
		bool(live_view.get("needs_conflict_review", false)),
		"The live source panel must surface structured/Vision review notices."
	):
		return
	var review_buttons: Array[Button] = []
	for button_node in collaborator.find_children("*", "Button", true, false):
		if button_node is Button and (button_node as Button).text == "Review Evidence…":
			review_buttons.append(button_node as Button)
	if not _require(
		review_buttons.size() == 2,
		"Each linked visual source must expose a Review Evidence action (found %d)."
		% review_buttons.size()
	):
		return
	collaborator.call(
		"_open_evidence_review_v0171", str(card.get("source_context_id", ""))
	)
	var review_text_value: Variant = collaborator.get("_evidence_review_text_v0171")
	if not _require(
		review_text_value is TextEdit
		and (review_text_value as TextEdit).text.contains("blue eyes"),
		"The live review dialog must show linked Vision evidence beside the source snapshot."
	):
		return
	var context_blocks_value: Variant = collaborator.call("_context_blocks")
	var context_blocks: Array = (
		context_blocks_value as Array if context_blocks_value is Array else []
	)
	if not _require(
		"\n".join(context_blocks).contains(
			"COLLABORATOR EVIDENCE ROLES AND CONFLICT CONTRACT"
		),
		"Live Collaborator requests must receive the v0.17.1 precedence contract."
	):
		return
	if not _require(
		app.has_method("_update_build_version_label_v0170")
		and app.get("_image_generation_window") is CCFImageGenerationWindowV0170,
		"v0.17.1 must preserve the complete v0.17.0 Image Studio handoff."
	):
		return
	app.queue_free()
	await process_frame
	print("v0.17.1 Collaborator source precedence and conflict review regression passed")
	quit(0)
