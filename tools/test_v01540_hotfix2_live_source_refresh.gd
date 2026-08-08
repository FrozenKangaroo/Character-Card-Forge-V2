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
	print("V01540_HOTFIX2_LIVE_SOURCE_REFRESH_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _live_children(container: Container) -> Array[Node]:
	var result: Array[Node] = []
	for child in container.get_children():
		if not child.is_queued_for_deletion():
			result.append(child)
	return result


func _assert_compact_live_row(
	collaborator: CCFCharacterCollaboratorWindowV01540Hotfix2,
	expect_linked_vision: bool
) -> bool:
	var list_value: Variant = collaborator.get("_multi_source_list_v01537")
	if not _require(list_value is VBoxContainer, "The live Collaborator must expose its multi-source VBox."):
		return false
	var source_list := list_value as VBoxContainer
	var rows := _live_children(source_list)
	if not _require(rows.size() == 1, "The normal refresh path must leave exactly one live row for the single source fixture."):
		return false
	if not _require(rows[0] is PanelContainer, "The live source row must be the compact stacked PanelContainer, never the inherited HBox fallback."):
		return false
	if not _require(not rows[0] is HBoxContainer, "No horizontal source-row fallback may survive the real refresh path."):
		return false
	var row := rows[0] as PanelContainer
	if not _require(str(row.get_meta("source_row_renderer", "")) == "v0.15.40-hotfix2", "The final live row must identify the hotfix2 renderer."):
		return false

	var stack := row.find_child("SourceRowStackV01540Hotfix2", true, false) as VBoxContainer
	var label := row.find_child("SourceLabelV01540Hotfix2", true, false) as Label
	var actions := row.find_child("SourceActionsV01540Hotfix2", true, false) as HFlowContainer
	if not _require(stack != null and label != null and actions != null, "The live row must contain the stacked label and wrapping action region."):
		return false
	if not _require(label.get_parent() == stack and actions.get_parent() == stack, "Label and actions must share the vertical stack."):
		return false
	if not _require(label.get_index() < actions.get_index(), "The source description must appear above the actions."):
		return false
	if not _require(label.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "The source description must own the available row width."):
		return false

	var analyse_found := false
	var remove_found := false
	for child in actions.get_children():
		if not child is Button:
			continue
		var button := child as Button
		if button.text in ["Analyse Image", "Re-analyse Image"]:
			analyse_found = true
			if expect_linked_vision and not _require(button.text == "Re-analyse Image", "Linked visual evidence must switch the action to Re-analyse Image."):
				return false
		if button.text == "×":
			remove_found = true
		if not _require(button.size_flags_vertical == Control.SIZE_SHRINK_CENTER, "Every source action must explicitly shrink vertically."):
			return false
	if not _require(analyse_found and remove_found, "The live Character Card row must retain Analyse/Re-analyse and remove actions."):
		return false
	if expect_linked_vision and not _require(label.text.contains("Vision linked"), "The live source label must report linked Vision evidence."):
		return false
	return true


func _run() -> void:
	CCFStorageService.ensure_directories()

	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.15.40-hotfix2 real main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	if not _require(app.has_method("_update_build_version_label_v01540_hotfix2"), "The active application shell must identify v0.15.40-hotfix2."):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(workspace_value is CCFWorkspaceV01540Hotfix2View, "The real application must install the hotfix2 Workspace."):
		return
	var workspace := workspace_value as CCFWorkspaceV01540Hotfix2View
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(collaborator_value is CCFCharacterCollaboratorWindowV01540Hotfix2, "The real Workspace must install the hotfix2 Collaborator."):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV01540Hotfix2
	var caps := collaborator.source_row_layout_capabilities_v01540_hotfix2()
	if not _require(bool(caps.get("live_refresh_postcondition", false)), "The active Collaborator must enforce the live-refresh layout postcondition."):
		return
	if not _require(bool(caps.get("horizontal_fallback_forbidden", false)), "The active Collaborator must forbid horizontal fallback rows."):
		return

	# Build a real Character Card PNG so the regression follows the same structured
	# source classification used by the user's Card data + Vision workflow.
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var character := CCFStorageService.get_character(project, character_id)
	CCFStorageService.set_value_at_path(character, "character.name", "Live Refresh Layout Regression Character With A Deliberately Long Name")
	CCFStorageService.set_value_at_path(
		character,
		"character.description",
		"A deliberately long source description used to ensure the narrow sidebar cannot squeeze the source label between action buttons."
	)
	CCFStorageService.update_character(project, character)
	var source_png := CCFStorageService.ROOT_DIR.path_join("v01540_hotfix2_source.png")
	var card_png := CCFStorageService.ROOT_DIR.path_join("v01540_hotfix2_card.png")
	var image := Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.25, 0.45, 0.75, 1.0))
	if not _require(image.save_png(source_png) == OK, "The hotfix2 source PNG fixture must be writable."):
		return
	var png_result := CCFCardFormatService.write_png_card(source_png, card_png, project, character_id)
	if not _require(bool(png_result.get("ok", false)), "The hotfix2 Character Card PNG fixture must export successfully."):
		return
	var loaded := SOURCE_SERVICE.from_card_file(card_png)
	if not _require(bool(loaded.get("ok", false)), "The exported Character Card PNG must load as structured source metadata."):
		return
	var source_value: Variant = loaded.get("source", {})
	if not _require(source_value is Dictionary, "The loaded Character Card must expose a source dictionary."):
		return
	var source: Dictionary = source_value
	if not _require(CARD_VISION_SERVICE.is_visual_card_source(source), "The fixture must be recognised as a visual Character Card source."):
		return

	# Open the Collaborator through its normal public project entry point first.
	# add_source_v01537() intentionally rejects writes when no active session exists.
	collaborator.open_for_project(project, {}, character_id, {})
	await process_frame
	await process_frame

	# add_source_v01537() calls the normal _refresh_all() chain. This is the first
	# part the hotfix1 regression skipped by calling its row builder directly.
	var added := collaborator.add_source_v01537(source, false)
	if not _require(bool(added.get("ok", false)), "The Character Card metadata source must add through the real Collaborator API: %s" % str(added.get("error", "unknown error"))):
		return
	await process_frame
	await process_frame
	if not _assert_compact_live_row(collaborator, false):
		return

	var sources := collaborator.active_source_contexts_v01537()
	if not _require(sources.size() == 1, "The Collaborator must retain the single structured Character Card source."):
		return
	var source_id := str(sources[0].get("source_context_id", ""))
	var linked_context := CARD_VISION_SERVICE.annotate_vision_context({
		"context_id": "v01540-hotfix2-linked-vision",
		"type": "vision_reference",
		"label": "v01540_hotfix2_card.png",
		"content": "VISION DESCRIPTION OF USER-ATTACHED IMAGE\nVisible artwork regression fixture.",
		"vision_description": "Visible artwork regression fixture.",
		"source_path": card_png
	}, source_id)
	var marked_source := CARD_VISION_SERVICE.mark_source_vision_analysis(
		sources[0],
		linked_context,
		{"vision_profile_name": "Regression Vision", "vision_model": "fixture-model"}
	)

	# Store the same source + linked Vision evidence shape that exists after the
	# provider completes, then run _refresh_all() exactly as the live Vision path does.
	var session_value: Variant = collaborator.call("_active_session")
	if not _require(session_value is Dictionary, "The live Collaborator session must be available for the Vision-link fixture."):
		return
	var session: Dictionary = (session_value as Dictionary).duplicate(true)
	session["context_items"] = [linked_context]
	collaborator.call("_store_sources_in_session_v01537", session, [marked_source])
	collaborator.call("_store_active_session", session)
	collaborator.call("_refresh_all")
	await process_frame
	await process_frame
	if not _assert_compact_live_row(collaborator, true):
		return

	# Recreate the runtime failure explicitly: put an inherited horizontal row in
	# the visible list and ask the normal source-panel refresh to reconcile it. The
	# hotfix2 postcondition must remove it immediately and restore the stacked row.
	var list_value: Variant = collaborator.get("_multi_source_list_v01537")
	var source_list := list_value as VBoxContainer
	for child in source_list.get_children():
		source_list.remove_child(child)
		child.queue_free()
	var stale_hbox := HBoxContainer.new()
	stale_hbox.name = "InjectedInheritedHorizontalSourceRow"
	var stale_button_a := Button.new()
	stale_button_a.text = "Analyse Image"
	stale_hbox.add_child(stale_button_a)
	var stale_label := Label.new()
	stale_label.text = "This label must never remain squeezed between two inherited action controls."
	stale_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stale_hbox.add_child(stale_label)
	var stale_button_b := Button.new()
	stale_button_b.text = "×"
	stale_hbox.add_child(stale_button_b)
	source_list.add_child(stale_hbox)
	collaborator.call("_refresh_source_panel_v01533")
	await process_frame
	if not _assert_compact_live_row(collaborator, true):
		return
	for child in source_list.get_children():
		if not _require(not child is HBoxContainer, "The post-refresh live tree must contain no inherited HBox source rows."):
			return

	app.queue_free()
	await process_frame
	print("v0.15.40-hotfix2 live Collaborator source refresh regression passed")
	quit(0)
