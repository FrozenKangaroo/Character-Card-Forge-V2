class_name CCFCharacterCollaboratorWindowV01540Hotfix2
extends "res://scripts/ui/character_collaborator_window_v01540_hotfix1.gd"


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["source_row_live_refresh_guard_v01540_hotfix2"] = true
	result["source_row_no_horizontal_fallback_v01540_hotfix2"] = true
	return result


func source_row_layout_capabilities_v01540_hotfix2() -> Dictionary:
	return {
		"version": "0.15.40-hotfix2",
		"stacked_source_rows": true,
		"label_owns_full_row_width": true,
		"actions_below_label": true,
		"wrapping_action_container": true,
		"buttons_do_not_expand_vertically": true,
		"live_refresh_postcondition": true,
		"horizontal_fallback_forbidden": true,
		"character_card_vision_action_preserved": true,
		"make_target_action_preserved": true,
		"remove_action_preserved": true
	}


# v0.15.40-hotfix1 proved that the stacked row itself was sound, but runtime
# testing showed the normal add-card -> Vision -> _refresh_all() chain could
# still finish with the inherited v0.15.39 HBox renderer. Make the active leaf
# renderer authoritative and also enforce it as a postcondition of the source
# panel refresh, so either dynamic or ancestor-bound refresh dispatch converges
# on the same compact row structure.
func _refresh_multi_source_list_v01537() -> void:
	_rebuild_live_source_rows_v01540_hotfix2()


func _refresh_source_panel_v01533() -> void:
	super._refresh_source_panel_v01533()
	if _source_panel_v01533 == null or not _source_panel_v01533.visible:
		return
	if not _live_source_rows_are_hotfix2_v01540_hotfix2():
		_rebuild_live_source_rows_v01540_hotfix2()


func _rebuild_live_source_rows_v01540_hotfix2() -> void:
	if _multi_source_list_v01537 == null:
		return

	# Detach old rows immediately rather than only queue_free()ing them. This
	# prevents a stale inherited HBox row from remaining visible for a frame while
	# the replacement is already present.
	for child in _multi_source_list_v01537.get_children():
		_multi_source_list_v01537.remove_child(child)
		child.queue_free()

	var sources := active_source_contexts_v01537()
	var session := _active_session()
	var context_items: Variant = session.get("context_items", [])
	for source in sources:
		_build_live_source_row_v01540_hotfix2(source, context_items)


func _build_live_source_row_v01540_hotfix2(
	source: Dictionary,
	context_items: Variant
) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "CollaboratorSourceRowV01540Hotfix2"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.set_meta("source_context_id", str(source.get("source_context_id", "")))
	card.set_meta("source_row_renderer", "v0.15.40-hotfix2")
	_multi_source_list_v01537.add_child(card)

	var stack := VBoxContainer.new()
	stack.name = "SourceRowStackV01540Hotfix2"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stack.add_theme_constant_override("separation", 4)
	card.add_child(stack)

	var linked_vision := (
		CARD_VISION_SERVICE_V01539.is_visual_card_source(source)
		and CARD_VISION_SERVICE_V01539.source_has_linked_vision(source, context_items)
	)
	var label := Label.new()
	label.name = "SourceLabelV01540Hotfix2"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s • %s • %s" % [
		str(source.get("source_role", SOURCE_SERVICE_V01537.ROLE_REFERENCE)).to_upper(),
		SOURCE_SERVICE_V01537.display_type(source),
		str(source.get("label", "Source material"))
	]
	if int(source.get("excluded_user_persona_count", 0)) > 0:
		label.text += " • UserPersona excluded"
	if linked_vision:
		label.text += " • Vision linked"
	stack.add_child(label)

	var actions := HFlowContainer.new()
	actions.name = "SourceActionsV01540Hotfix2"
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	actions.add_theme_constant_override("h_separation", 4)
	actions.add_theme_constant_override("v_separation", 4)
	stack.add_child(actions)

	var source_id := str(source.get("source_context_id", ""))
	if (
		SOURCE_SERVICE_V01537.can_be_target(source)
		and str(source.get("source_role", "")) != SOURCE_SERVICE_V01537.ROLE_TARGET
	):
		var target_button := Button.new()
		target_button.text = "Make Target"
		target_button.tooltip_text = "Use this existing Workspace character as the explicit Compare & Apply target."
		_prepare_live_source_action_button_v01540_hotfix2(target_button)
		target_button.pressed.connect(_on_make_target_v01537.bind(source_id))
		actions.add_child(target_button)

	if CARD_VISION_SERVICE_V01539.is_visual_card_source(source):
		var analyse := Button.new()
		analyse.text = "Re-analyse Image" if linked_vision else "Analyse Image"
		analyse.tooltip_text = "Analyse the visible Character Card image with the configured Vision model. The result stays separate from embedded card metadata."
		_prepare_live_source_action_button_v01540_hotfix2(analyse)
		analyse.pressed.connect(
			_on_analyse_card_source_v01539.bind(
				source_id,
				CARD_VISION_SERVICE_V01539.source_image_path(source)
			)
		)
		actions.add_child(analyse)

	var remove_button := Button.new()
	remove_button.text = "×"
	remove_button.tooltip_text = "Remove this source from future Collaborator context."
	_prepare_live_source_action_button_v01540_hotfix2(remove_button)
	remove_button.pressed.connect(_on_remove_source_v01537.bind(source_id))
	actions.add_child(remove_button)
	return card


func _prepare_live_source_action_button_v01540_hotfix2(button: Button) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2.ZERO


func _live_source_rows_are_hotfix2_v01540_hotfix2() -> bool:
	if _multi_source_list_v01537 == null:
		return false
	var expected_count := active_source_contexts_v01537().size()
	var live_count := 0
	for child in _multi_source_list_v01537.get_children():
		if child.is_queued_for_deletion():
			continue
		live_count += 1
		if not child is PanelContainer:
			return false
		if str(child.get_meta("source_row_renderer", "")) != "v0.15.40-hotfix2":
			return false
	return live_count == expected_count


func source_row_layout_snapshot_v01540_hotfix2() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _multi_source_list_v01537 == null:
		return result
	for child in _multi_source_list_v01537.get_children():
		if not child is PanelContainer or child.is_queued_for_deletion():
			continue
		var row := child as PanelContainer
		var label := row.find_child("SourceLabelV01540Hotfix2", true, false) as Label
		var actions := row.find_child("SourceActionsV01540Hotfix2", true, false) as HFlowContainer
		var buttons: Array[Dictionary] = []
		if actions != null:
			for action in actions.get_children():
				if action is Button:
					buttons.append({
						"text": (action as Button).text,
						"width": (action as Button).size.x,
						"height": (action as Button).size.y,
						"vertical_flags": (action as Button).size_flags_vertical
					})
		result.append({
			"source_context_id": str(row.get_meta("source_context_id", "")),
			"renderer": str(row.get_meta("source_row_renderer", "")),
			"row_width": row.size.x,
			"row_height": row.size.y,
			"label_width": label.size.x if label != null else 0.0,
			"label_height": label.size.y if label != null else 0.0,
			"actions_y": actions.position.y if actions != null else 0.0,
			"actions_height": actions.size.y if actions != null else 0.0,
			"buttons": buttons
		})
	return result
