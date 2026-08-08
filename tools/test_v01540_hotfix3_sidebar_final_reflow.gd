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
	print("V01540_HOTFIX3_SIDEBAR_REFLOW_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _clear_container_now(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _inject_reported_source_failure(source_list: VBoxContainer) -> void:
	_clear_container_now(source_list)
	var row := HBoxContainer.new()
	row.name = "InjectedReportedFullHeightSourceRow"
	var analyse := Button.new()
	analyse.text = "Analyse Image"
	analyse.custom_minimum_size = Vector2(130, 700)
	row.add_child(analyse)
	var label := Label.new()
	label.text = "Character Card source label squeezed into a near single-character column."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var remove := Button.new()
	remove.text = "×"
	remove.custom_minimum_size = Vector2(145, 700)
	row.add_child(remove)
	source_list.add_child(row)


func _inject_reported_context_failure(context_list: VBoxContainer) -> void:
	_clear_container_now(context_list)
	var row := VBoxContainer.new()
	row.name = "InjectedReportedReferenceContextRow"
	var header := HBoxContainer.new()
	row.add_child(header)
	var label := Label.new()
	label.text = "Vision reference • deliberately long fixture label that must retain usable width"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	var remove := Button.new()
	remove.text = "×"
	remove.custom_minimum_size = Vector2(145, 650)
	header.add_child(remove)
	context_list.add_child(row)


func _assert_final_sidebar(
	collaborator: CCFCharacterCollaboratorWindowV01540Hotfix3,
	expect_context_items: int
) -> bool:
	var source_list_value: Variant = collaborator.get("_multi_source_list_v01537")
	var context_list_value: Variant = collaborator.get("_context_list")
	if not _require(source_list_value is VBoxContainer, "The active Collaborator must expose the structured source list."):
		return false
	if not _require(context_list_value is VBoxContainer, "The active Collaborator must expose the ordinary reference-context list."):
		return false
	var source_list := source_list_value as VBoxContainer
	var context_list := context_list_value as VBoxContainer

	var live_sources := 0
	for child in source_list.get_children():
		if child.is_queued_for_deletion():
			continue
		live_sources += 1
		if not _require(child is PanelContainer, "Every final structured source row must be a stacked PanelContainer."):
			return false
		if not _require(str(child.get_meta("source_row_renderer", "")).begins_with("v0.15.40-hotfix"), "Every final structured source row must identify the safe hotfix renderer."):
			return false
	if not _require(live_sources == 1, "The single Character Card fixture must leave one final structured source row."):
		return false

	var live_context := 0
	for child in context_list.get_children():
		if child.is_queued_for_deletion():
			continue
		if expect_context_items == 0 and child is Label:
			continue
		live_context += 1
		if not _require(child is PanelContainer, "Every final reference/attachment row must be a stacked PanelContainer."):
			return false
		if not _require(str(child.get_meta("context_row_renderer", "")) == "v0.15.40-hotfix3", "Reference/attachment rows must identify the hotfix3 renderer."):
			return false
	if not _require(live_context == expect_context_items, "The final reference-context list must match the active context item count."):
		return false

	var snapshot := collaborator.sidebar_layout_snapshot_v01540_hotfix3()
	if not _require(not bool(snapshot.get("needs_reflow", true)), "The settled whole-sidebar snapshot must not request another reflow."):
		return false
	var buttons_value: Variant = snapshot.get("buttons", [])
	if not _require(buttons_value is Array, "The whole-sidebar snapshot must expose action buttons."):
		return false
	for raw_button in buttons_value as Array:
		if not raw_button is Dictionary:
			continue
		var button: Dictionary = raw_button
		if not _require(int(button.get("vertical_flags", 0)) == Control.SIZE_SHRINK_CENTER, "Every final sidebar action must explicitly shrink vertically."):
			return false
		var height := float(button.get("height", 0.0))
		if height > 0.0 and not _require(height <= 72.0, "No visible sidebar action may become a full-height column."):
			return false
	return true


func _run() -> void:
	CCFStorageService.ensure_directories()
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The hotfix3 real main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	if not _require(app.has_method("_update_build_version_label_v01540_hotfix3"), "The active application shell must identify v0.15.40-hotfix3."):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(workspace_value is CCFWorkspaceV01540Hotfix3View, "The real application must install the hotfix3 Workspace."):
		return
	var workspace := workspace_value as CCFWorkspaceV01540Hotfix3View
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(collaborator_value is CCFCharacterCollaboratorWindowV01540Hotfix3, "The real Workspace must install the hotfix3 Collaborator."):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV01540Hotfix3
	var caps := collaborator.sidebar_layout_capabilities_v01540_hotfix3()
	if not _require(bool(caps.get("whole_sidebar_regression_scope", false)), "The active hotfix must cover the whole Reference Context sidebar."):
		return

	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var character := CCFStorageService.get_character(project, character_id)
	CCFStorageService.set_value_at_path(character, "character.name", "Whole Sidebar Regression Character With A Long Name")
	CCFStorageService.set_value_at_path(character, "character.description", "A regression fixture for the exact Card data plus Vision sidebar failure reported in the desktop runtime.")
	CCFStorageService.update_character(project, character)
	var source_png := CCFStorageService.ROOT_DIR.path_join("v01540_hotfix3_source.png")
	var card_png := CCFStorageService.ROOT_DIR.path_join("v01540_hotfix3_card.png")
	var image := Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.35, 0.50, 0.75, 1.0))
	if not _require(image.save_png(source_png) == OK, "The hotfix3 source PNG fixture must be writable."):
		return
	var png_result := CCFCardFormatService.write_png_card(source_png, card_png, project, character_id)
	if not _require(bool(png_result.get("ok", false)), "The hotfix3 Character Card PNG fixture must export successfully."):
		return
	var loaded := SOURCE_SERVICE.from_card_file(card_png)
	if not _require(bool(loaded.get("ok", false)), "The exported Character Card PNG must load as structured metadata."):
		return
	var source_value: Variant = loaded.get("source", {})
	if not _require(source_value is Dictionary, "The exported card must produce a structured Collaborator source."):
		return
	var source: Dictionary = source_value

	collaborator.open_for_project(project, {}, character_id, {})
	await process_frame
	await process_frame
	var added := collaborator.add_source_v01537(source, false)
	if not _require(bool(added.get("ok", false)), "The structured Character Card source must add through the public Collaborator API."):
		return
	await process_frame
	await process_frame

	var sources := collaborator.active_source_contexts_v01537()
	var source_id := str(sources[0].get("source_context_id", ""))
	var linked_context := CARD_VISION_SERVICE.annotate_vision_context({
		"context_id": "v01540-hotfix3-linked-vision",
		"type": "vision_reference",
		"label": "v01540_hotfix3_card.png",
		"content": "VISION DESCRIPTION OF USER-ATTACHED IMAGE\nVisible artwork regression fixture.",
		"vision_description": "Visible artwork regression fixture.",
		"source_path": card_png
	}, source_id)
	var marked_source := CARD_VISION_SERVICE.mark_source_vision_analysis(
		sources[0],
		linked_context,
		{"vision_profile_name": "Regression Vision", "vision_model": "fixture-model"}
	)
	var session_value: Variant = collaborator.call("_active_session")
	if not _require(session_value is Dictionary, "The active Collaborator session must be available."):
		return
	var session: Dictionary = (session_value as Dictionary).duplicate(true)
	session["context_items"] = [linked_context]
	collaborator.call("_store_sources_in_session_v01537", session, [marked_source])
	# This emits sessions_changed and schedules the authoritative final deferred reflow.
	collaborator.call("_store_active_session", session)

	var source_list := collaborator.get("_multi_source_list_v01537") as VBoxContainer
	var context_list := collaborator.get("_context_list") as VBoxContainer
	# Inject the exact visual failure shape after the session signal but before its
	# deferred reflow. The final pass must still win.
	_inject_reported_source_failure(source_list)
	_inject_reported_context_failure(context_list)
	await process_frame
	await process_frame
	if not _assert_final_sidebar(collaborator, 1):
		return

	# Also prove a later stale renderer with no session mutation is repaired by the
	# lightweight visible-window runtime guard on the following frame.
	_inject_reported_source_failure(source_list)
	_inject_reported_context_failure(context_list)
	collaborator.call("_process", 0.016)
	await process_frame
	await process_frame
	if not _assert_final_sidebar(collaborator, 1):
		return

	app.queue_free()
	await process_frame
	print("v0.15.40-hotfix3 whole Collaborator sidebar final-reflow regression passed")
	quit(0)
