extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V01540_HOTFIX5_COMPOSER_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	CCFStorageService.ensure_directories()
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.15.40-hotfix5 main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	if not _require(app.has_method("_update_build_version_label_v01540_hotfix5"), "The active application shell must identify hotfix5."):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(workspace_value is CCFWorkspaceV01540Hotfix5View, "The real app must install the hotfix5 Workspace."):
		return
	var workspace := workspace_value as CCFWorkspaceV01540Hotfix5View
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(collaborator_value is CCFCharacterCollaboratorWindowV01540Hotfix5, "The real Workspace must install the hotfix5 Collaborator."):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV01540Hotfix5

	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	collaborator.open_for_project(project, {}, character_id, {})
	collaborator.popup_centered()
	await process_frame
	await process_frame

	# Recreate the vertical pressure from the reported long Vision Analysis without
	# relying on a provider call. The real Collaborator chat surface and composer
	# remain in use; only the already-generated message body is synthetic.
	var chat_list := collaborator.get("_chat_list") as VBoxContainer
	if not _require(chat_list != null, "The real Collaborator chat list must exist."):
		return
	var vision_card := PanelContainer.new()
	vision_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vision_text := Label.new()
	vision_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vision_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vision_text.text = "Vision Analysis — regression reference image\n\n" + ("Subject and Appearance: long visual analysis content. Pose and Body Language: detailed description. Setting and Environment: detailed scene context. Lighting and Atmosphere: detailed observations. Art Style: detailed rendering notes. Action/Context: detailed inferred scene.\n\n").repeat(18)
	vision_card.add_child(vision_text)
	chat_list.add_child(vision_card)
	await process_frame
	await process_frame

	var resize_sequence := [
		Vector2i(1460, 900),
		Vector2i(1180, 720),
		Vector2i(1040, 680),
		Vector2i(1680, 980),
		Vector2i(1100, 700),
	]
	for target_size in resize_sequence:
		collaborator.size = target_size
		await process_frame
		await process_frame
		await process_frame
		var snapshot: Dictionary = collaborator.composer_layout_snapshot_v01540_hotfix5()
		if not _require(bool(snapshot.get("panel_found", false)), "Composer panel must exist after resize."):
			return
		if not _require(bool(snapshot.get("input_visible", false)), "Composer input must remain visible after resize without project switching."):
			return
		if not _require(float(snapshot.get("input_bottom", 0.0)) <= float(snapshot.get("panel_bottom", 0.0)) + 2.0, "Composer input must stay inside the visible chat panel after resize."):
			return
		if not _require(not bool(snapshot.get("needs_reflow", true)), "Composer layout must settle after the deferred resize reflow."):
			return

	# Recreate the likely stale-layout state directly: the scrolling transcript
	# wrongly claims a large minimum height and the input is allowed to expand.
	var chat_scroll := collaborator.get("_chat_scroll") as ScrollContainer
	var input := collaborator.get("_input") as TextEdit
	if not _require(chat_scroll != null and input != null, "Chat scroll and input controls must exist."):
		return
	chat_scroll.custom_minimum_size.y = 900.0
	input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	collaborator.size = Vector2i(1040, 680)
	await process_frame
	if not _require(collaborator.call("_composer_layout_needs_reflow_v01540_hotfix5"), "The stale composer state must be detected without switching projects."):
		return
	collaborator.call("_schedule_composer_reflow_v01540_hotfix5")
	await process_frame
	await process_frame
	await process_frame
	var recovered: Dictionary = collaborator.composer_layout_snapshot_v01540_hotfix5()
	if not _require(float(recovered.get("chat_scroll_min_height", -1.0)) == 0.0, "Recovery must release the transcript's stale minimum height."):
		return
	if not _require(bool(recovered.get("input_visible", false)), "Recovery must keep the composer visible."):
		return
	if not _require(float(recovered.get("input_bottom", 0.0)) <= float(recovered.get("panel_bottom", 0.0)) + 2.0, "Recovered composer must be inside the visible panel."):
		return
	if not _require(not bool(recovered.get("needs_reflow", true)), "Recovered composer must settle without a project/session switch."):
		return

	# Exact warning regressions reported from normal Godot 4.7.1 runtime.
	var hotfix3_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v01540_hotfix3.gd")
	var hotfix4_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v01540_hotfix4.gd")
	if not _require(not hotfix3_source.contains("func _on_sidebar_sessions_changed_v01540_hotfix3(_sessions:"), "Hotfix3 callback parameter must not shadow the base _sessions member."):
		return
	if not _require(not hotfix4_source.contains("label.name = SOURCE_HELPER_LABEL_NAME_V01540_HOTFIX4 if"), "Hotfix4 helper naming must not use the incompatible String/StringName ternary."):
		return
	if not _require(not hotfix4_source.contains("\"hint_parent_name\": hint.get_parent().name if"), "Hotfix4 snapshot must not use the incompatible StringName/String ternary."):
		return

	app.queue_free()
	await process_frame
	print("v0.15.40-hotfix5 composer resize and warning regression passed")
	quit(0)
