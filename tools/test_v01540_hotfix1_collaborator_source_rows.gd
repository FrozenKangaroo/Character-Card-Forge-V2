extends SceneTree

const SOURCE_SERVICE = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V01540_HOTFIX1_SOURCE_ROW_REGRESSION_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _button_texts(actions: HFlowContainer) -> Array[String]:
	var result: Array[String] = []
	for child in actions.get_children():
		if child is Button:
			result.append((child as Button).text)
	return result


func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.15.40-hotfix1 real main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	if not _require(
		app.has_method("_update_build_version_label_v01540_hotfix1"),
		"The active application shell must identify v0.15.40-hotfix1."
	):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV01540Hotfix1View,
		"The real app must install the v0.15.40-hotfix1 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV01540Hotfix1View
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(
		collaborator_value is CCFCharacterCollaboratorWindowV01540Hotfix1,
		"The hotfix Workspace must install the compact-source-row Collaborator."
	):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV01540Hotfix1
	var caps := collaborator.source_row_layout_capabilities_v01540_hotfix1()
	if not _require(bool(caps.get("actions_below_label", false)), "Source actions must be below the descriptive label."):
		return
	if not _require(bool(caps.get("buttons_do_not_expand_vertically", false)), "Source action buttons must opt out of vertical expansion."):
		return

	var list_value: Variant = collaborator.get("_multi_source_list_v01537")
	if not _require(list_value is VBoxContainer, "Collaborator must expose its multi-source list."):
		return
	var source_list := list_value as VBoxContainer
	for child in source_list.get_children():
		child.queue_free()
	await process_frame

	# This is deliberately longer than a normal card title. In the old HBox row,
	# Analyse/Remove consumed most of the narrow sidebar width, reducing the label
	# to a few characters per line and stretching both buttons to the resulting
	# enormous row height.
	var long_label := (
		"A deliberately long Character Card PNG source label used to reproduce the "
		+ "narrow Collaborator sidebar wrapping failure without relying on a real provider"
	)
	var source := {
		"source_context_id": "source-row-layout-card",
		"source_type": SOURCE_SERVICE.TYPE_EXTERNAL_CARD,
		"source_role": SOURCE_SERVICE.ROLE_REFERENCE,
		"label": long_label,
		"snapshot": {"data": {"name": "Layout Regression Card"}},
		"ai_snapshot": {"data": {"name": "Layout Regression Card"}},
		"excluded_user_persona_count": 0,
		"provenance": {"source_path": "/tmp/layout-regression-character-card.png"},
		"author_intent": "reference_context"
	}
	var linked_context := [{
		"context_id": "source-row-layout-vision",
		"type": "vision_reference",
		"linked_source_context_id": "source-row-layout-card",
		"source_path": "/tmp/layout-regression-character-card.png"
	}]
	var row := collaborator.call(
		"_build_source_row_v01540_hotfix1",
		source,
		linked_context
	) as PanelContainer
	if not _require(row != null, "The hotfix must build a source card for the regression fixture."):
		return
	await process_frame
	await process_frame

	var stack := row.find_child("SourceRowStackV01540Hotfix1", true, false) as VBoxContainer
	var label := row.find_child("SourceLabelV01540Hotfix1", true, false) as Label
	var actions := row.find_child("SourceActionsV01540Hotfix1", true, false) as HFlowContainer
	if not _require(stack != null and label != null and actions != null, "Each source row must contain a stacked label and action flow."):
		return
	if not _require(label.get_parent() == stack and actions.get_parent() == stack, "Label and actions must share the vertical stack rather than the old horizontal row."):
		return
	if not _require(label.get_index() < actions.get_index(), "The descriptive label must be laid out before the source actions."):
		return
	if not _require(label.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "The source label must receive the row's available horizontal width."):
		return
	if not _require(actions is HFlowContainer, "Narrow source actions must use a wrapping flow container."):
		return

	var texts := _button_texts(actions)
	if not _require(texts.has("Re-analyse Image"), "Linked Character Card sources must retain the Re-analyse Image action."):
		return
	if not _require(texts.has("×"), "Source rows must retain the remove action."):
		return
	for child in actions.get_children():
		if not child is Button:
			continue
		var button := child as Button
		if not _require(
			button.size_flags_vertical == Control.SIZE_SHRINK_CENTER,
			"Source action buttons must shrink vertically instead of inheriting wrapped-label height."
		):
			return

	var snapshot := collaborator.source_row_layout_snapshot_v01540_hotfix1()
	if not _require(snapshot.size() == 1, "The layout diagnostics snapshot must expose the test source row."):
		return
	var row_snapshot: Dictionary = snapshot[0]
	var label_height := float(row_snapshot.get("label_height", 0.0))
	var actions_y := float(row_snapshot.get("actions_y", 0.0))
	if label_height > 0.0 and actions_y > 0.0:
		if not _require(actions_y >= label_height, "Rendered source actions must begin below the wrapped label."):
			return
	var row_height := float(row_snapshot.get("row_height", 0.0))
	var button_rows_value: Variant = row_snapshot.get("buttons", [])
	if row_height > 0.0 and button_rows_value is Array:
		for button_row in button_rows_value as Array:
			if not button_row is Dictionary:
				continue
			var button_height := float((button_row as Dictionary).get("height", 0.0))
			if button_height > 0.0:
				if not _require(button_height < row_height, "No source action button may stretch to the full source-row height."):
					return

	app.queue_free()
	await process_frame
	print("v0.15.40-hotfix1 Collaborator source row layout regression passed")
	quit(0)
