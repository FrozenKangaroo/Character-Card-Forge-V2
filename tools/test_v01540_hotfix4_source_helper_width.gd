extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V01540_HOTFIX4_SOURCE_HELPER_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	CCFStorageService.ensure_directories()
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.15.40-hotfix4 main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	if not _require(app.has_method("_update_build_version_label_v01540_hotfix4"), "The active application shell must identify hotfix4."):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(workspace_value is CCFWorkspaceV01540Hotfix4View, "The real app must install the hotfix4 Workspace."):
		return
	var workspace := workspace_value as CCFWorkspaceV01540Hotfix4View
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(collaborator_value is CCFCharacterCollaboratorWindowV01540Hotfix4, "The real Workspace must install the hotfix4 Collaborator."):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV01540Hotfix4

	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	collaborator.open_for_project(project, {}, character_id, {})
	collaborator.size = Vector2i(1230, 1080)
	collaborator.popup_centered()
	await process_frame
	await process_frame

	var actions := collaborator.find_child("CollaboratorMultiSourceActionsV01537", true, false) as HFlowContainer
	if not _require(actions != null, "The inherited multi-source action flow must exist."):
		return
	var hint := collaborator.find_child("CollaboratorMultiSourceHintV01540Hotfix4", true, false) as Label
	if not _require(hint != null, "The source helper label must be found and renamed by hotfix4."):
		return
	if not _require(hint.get_parent() != actions, "The explanatory Character Card helper must never remain inside the HFlow action container."):
		return
	if not _require(hint.get_parent() == collaborator.get("_source_panel_v01533"), "The helper must be a direct full-width child of the source panel."):
		return
	if not _require(hint.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "The helper must expand across the source panel width."):
		return
	if not _require(hint.custom_minimum_size.x >= 260.0, "The helper must declare a readable minimum width instead of relying only on size flags."):
		return
	for child in actions.get_children():
		if not _require(not child is Label, "The source action HFlow must contain actions only, never wrapped explanatory labels."):
			return

	# The Reference Context pane itself has a 300px minimum. A helper narrower than
	# 220px recreates the reported near-single-glyph wrapping even if the exact
	# headless split geometry differs from a desktop window manager.
	if hint.size.x > 0.0:
		if not _require(hint.size.x >= 220.0, "At desktop geometry the helper must remain readable and may not collapse toward one-glyph width."):
			return

	# Reproduce the exact inherited structure from the user's screenshot by putting
	# the helper back in the HFlow, then require the normal final reflow to repair it.
	var hint_parent := hint.get_parent()
	hint_parent.remove_child(hint)
	actions.add_child(hint)
	hint.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hint.custom_minimum_size.x = 0.0
	if not _require(collaborator.call("_sidebar_layout_needs_reflow_v01540_hotfix3"), "A helper label inside the source action flow must be detected as invalid."):
		return
	collaborator.call("_schedule_sidebar_final_reflow_v01540_hotfix3")
	await process_frame
	await process_frame
	if not _require(hint.get_parent() != actions, "Final reflow must move the helper back out of the source action flow."):
		return
	if not _require(hint.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "Final reflow must restore full-width helper sizing."):
		return
	if not _require(hint.custom_minimum_size.x >= 260.0, "Final reflow must restore the readable helper minimum width."):
		return
	if hint.size.x > 0.0:
		if not _require(hint.size.x >= 220.0, "Recovered helper geometry must remain readable after the final reflow."):
			return

	app.queue_free()
	await process_frame
	print("v0.15.40-hotfix4 source helper width regression passed")
	quit(0)
