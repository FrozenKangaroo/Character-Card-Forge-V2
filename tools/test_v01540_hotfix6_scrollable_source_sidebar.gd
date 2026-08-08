extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V01540_HOTFIX6_SIDEBAR_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _long_assistant_text() -> String:
	return ("Character Collaborator analysis paragraph with enough detail to create a substantial scrolling transcript while preserving the real RichTextLabel and ScrollContainer layout path.\n\n").repeat(28)


func _context_item(index: int) -> Dictionary:
	return {
		"type": "image",
		"label": "Card Vision reference %d.png" % index,
		"content": ("Subject and Appearance: detailed Vision description. Pose and Body Language: detailed posture. Setting and Environment: detailed background. Lighting and Atmosphere: detailed scene notes. Art Style: detailed rendering notes. ").repeat(8),
		"vision_description": ("Vision-derived reference context %d. " % index).repeat(40)
	}


func _set_live_session_content(collaborator: CCFCharacterCollaboratorWindowV01540Hotfix6, context_items: Array, message_count: int) -> void:
	var session_value: Variant = collaborator.call("_active_session")
	var session: Dictionary = session_value.duplicate(true) if session_value is Dictionary else {}
	var messages: Array = []
	for index in range(message_count):
		messages.append({
			"role": "assistant" if index % 2 == 0 else "user",
			"content": _long_assistant_text() if index % 2 == 0 else "Author follow-up %d with enough text to keep the actual conversation populated." % index
		})
	session["messages"] = messages
	session["context_items"] = context_items.duplicate(true)
	collaborator.call("_store_active_session", session)
	collaborator.call("_refresh_all")


func _assert_window_contract(collaborator: CCFCharacterCollaboratorWindowV01540Hotfix6, label: String) -> bool:
	var composer: Dictionary = collaborator.composer_window_snapshot_v01540_hotfix6()
	if not _require(bool(composer.get("input_visible", false)), "%s: composer input must remain visible." % label):
		return false
	if not _require(bool(composer.get("input_inside_viewport", false)), "%s: composer input must remain inside the actual Collaborator viewport." % label):
		return false
	if not _require(bool(composer.get("chat_panel_inside_viewport", false)), "%s: chat panel must not extend below the actual Collaborator viewport." % label):
		return false
	if not _require(not bool(composer.get("window_guard_needs_reflow", true)), "%s: composer/window layout must settle after resize." % label):
		return false
	return true


func _exercise_large_small_cycle(collaborator: CCFCharacterCollaboratorWindowV01540Hotfix6, label: String) -> bool:
	var sizes := [
		Vector2i(1900, 1080),
		Vector2i(1180, 720),
		Vector2i(1040, 680),
		Vector2i(1760, 1000),
		Vector2i(1100, 700),
		Vector2i(1900, 1080),
		Vector2i(1040, 680),
	]
	for target_size in sizes:
		collaborator.size = target_size
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		if not _assert_window_contract(collaborator, "%s at %s" % [label, target_size]):
			return false
	return true


func _run() -> void:
	CCFStorageService.ensure_directories()
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.15.40-hotfix6 main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	if not _require(app.has_method("_update_build_version_label_v01540_hotfix6"), "The active application shell must identify hotfix6."):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(workspace_value is CCFWorkspaceV01540Hotfix6View, "The real app must install the hotfix6 Workspace."):
		return
	var workspace := workspace_value as CCFWorkspaceV01540Hotfix6View
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(collaborator_value is CCFCharacterCollaboratorWindowV01540Hotfix6, "The real Workspace must install the hotfix6 Collaborator."):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV01540Hotfix6

	# A/B case A from desktop testing: ordinary attachment/Vision context only.
	var attachment_project := CCFStorageService.new_project()
	var attachment_character_id := CCFStorageService.active_character_id(attachment_project)
	collaborator.open_for_project(attachment_project, {}, attachment_character_id, {})
	collaborator.popup_centered()
	await process_frame
	await process_frame
	_set_live_session_content(collaborator, [_context_item(1)], 6)
	await process_frame
	await process_frame
	var attachment_sidebar: Dictionary = collaborator.sidebar_scroll_snapshot_v01540_hotfix6()
	if not _require(bool(attachment_sidebar.get("scroll_found", false)), "Attachment-only project must retain the Reference Context scroll container."):
		return
	if not _require(bool(attachment_sidebar.get("context_inside_scroll_content", false)), "Attachment-only context must live inside the shared scroll content column."):
		return
	if not await _exercise_large_small_cycle(collaborator, "attachment-only project"):
		return

	# A/B case B from desktop testing: a structured Collaborator source plus the
	# Vision/attachment surface. Before hotfix6 the Sources block sat outside the
	# sidebar ScrollContainer and could force the whole HSplitContainer taller than
	# the native window after a large -> small resize.
	var structured_project := CCFStorageService.new_project()
	var structured_character_id := CCFStorageService.active_character_id(structured_project)
	collaborator.open_for_project(structured_project, {}, structured_character_id, {})
	collaborator.popup_centered()
	await process_frame
	await process_frame
	var structured_card_json := JSON.stringify({
		"name": "Attached Character Card",
		"description": "Established character facts remain read-only source context.",
		"personality": "Structured-source regression character."
	})
	var add_result := collaborator.add_pasted_source_v01537(
		structured_card_json,
		"Attached Character Card"
	)
	if not _require(bool(add_result.get("ok", false)), "Structured source must be addable through the public Collaborator source API."):
		return
	var context_items: Array = []
	for index in range(1, 6):
		context_items.append(_context_item(index))
	_set_live_session_content(collaborator, context_items, 8)
	await process_frame
	await process_frame
	await process_frame

	var structured_sidebar: Dictionary = collaborator.sidebar_scroll_snapshot_v01540_hotfix6()
	if not _require(bool(structured_sidebar.get("source_inside_scroll_content", false)), "Structured Sources block must be inside the shared Reference Context scroll content."):
		return
	if not _require(bool(structured_sidebar.get("context_inside_scroll_content", false)), "Ordinary Vision/attachment rows must share that same scroll content."):
		return
	if not _require(float(structured_sidebar.get("scroll_min_height", -1.0)) == 0.0, "Reference Context scroll must not claim a fixed vertical minimum from dynamic source content."):
		return
	if not await _exercise_large_small_cycle(collaborator, "structured source + Vision project"):
		return

	# Recreate the exact old architecture after the correct layout has settled:
	# move the structured source panel back outside the ScrollContainer. The normal
	# visible runtime guard must detect and repair this without switching projects.
	var source_panel := collaborator.get("_source_panel_v01533") as VBoxContainer
	var context_list := collaborator.get("_context_list") as VBoxContainer
	var scroll_content := collaborator.get("_reference_scroll_content_v01540_hotfix6") as VBoxContainer
	if not _require(source_panel != null and context_list != null and scroll_content != null, "Hotfix6 shared sidebar controls must exist."):
		return
	var context_scroll := scroll_content.get_parent() as ScrollContainer
	if not _require(context_scroll != null and context_scroll.get_parent() != null, "Shared content must be inside the original Reference Context ScrollContainer."):
		return
	var outer_panel := context_scroll.get_parent()
	scroll_content.remove_child(source_panel)
	outer_panel.add_child(source_panel)
	outer_panel.move_child(source_panel, context_scroll.get_index())
	if not _require(collaborator.call("_sidebar_layout_needs_reflow_v01540_hotfix3"), "Old source-outside-scroll architecture must be detected as invalid immediately."):
		return
	collaborator.size = Vector2i(1040, 680)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var repaired_sidebar: Dictionary = collaborator.sidebar_scroll_snapshot_v01540_hotfix6()
	if not _require(bool(repaired_sidebar.get("source_inside_scroll_content", false)), "Runtime reconciliation must move a stale Sources block back inside the scroll content without project switching."):
		return
	if not _require(not bool(repaired_sidebar.get("needs_reflow", true)), "Repaired sidebar must settle after restoring the shared-scroll contract."):
		return
	if not _assert_window_contract(collaborator, "repaired old sidebar architecture"):
		return

	app.queue_free()
	await process_frame
	print("v0.15.40-hotfix6 scrollable source sidebar regression passed")
	quit(0)
