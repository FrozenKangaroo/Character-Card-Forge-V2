class_name CCFCharacterCollaboratorWindowV01540Hotfix1
extends "res://scripts/ui/character_collaborator_window_v01539.gd"

const SOURCE_ROW_MAX_BUTTON_HEIGHT_V01540_HOTFIX1 := 44.0


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["source_row_stacked_layout_v01540_hotfix1"] = true
	result["source_actions_below_label_v01540_hotfix1"] = true
	result["source_action_vertical_shrink_v01540_hotfix1"] = true
	return result


func source_row_layout_capabilities_v01540_hotfix1() -> Dictionary:
	return {
		"version": "0.15.40-hotfix1",
		"stacked_source_rows": true,
		"label_owns_full_row_width": true,
		"actions_below_label": true,
		"wrapping_action_container": true,
		"buttons_do_not_expand_vertically": true,
		"character_card_vision_action_preserved": true,
		"make_target_action_preserved": true,
		"remove_action_preserved": true
	}


func _refresh_multi_source_list_v01537() -> void:
	if _multi_source_list_v01537 == null:
		return
	for child in _multi_source_list_v01537.get_children():
		child.queue_free()

	var sources := active_source_contexts_v01537()
	var session := _active_session()
	var context_items: Variant = session.get("context_items", [])
	for source in sources:
		_build_source_row_v01540_hotfix1(source, context_items)


func _build_source_row_v01540_hotfix1(source: Dictionary, context_items: Variant) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "CollaboratorSourceRowV01540Hotfix1"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.set_meta("source_context_id", str(source.get("source_context_id", "")))
	_multi_source_list_v01537.add_child(card)

	var stack := VBoxContainer.new()
	stack.name = "SourceRowStackV01540Hotfix1"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stack.add_theme_constant_override("separation", 4)
	card.add_child(stack)

	var linked_vision := (
		CARD_VISION_SERVICE_V01539.is_visual_card_source(source)
		and CARD_VISION_SERVICE_V01539.source_has_linked_vision(source, context_items)
	)
	var label := Label.new()
	label.name = "SourceLabelV01540Hotfix1"
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
	actions.name = "SourceActionsV01540Hotfix1"
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
		_prepare_source_action_button_v01540_hotfix1(target_button)
		target_button.pressed.connect(_on_make_target_v01537.bind(source_id))
		actions.add_child(target_button)

	if CARD_VISION_SERVICE_V01539.is_visual_card_source(source):
		var analyse := Button.new()
		analyse.text = "Re-analyse Image" if linked_vision else "Analyse Image"
		analyse.tooltip_text = "Analyse the visible Character Card image with the configured Vision model. The result stays separate from embedded card metadata."
		_prepare_source_action_button_v01540_hotfix1(analyse)
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
	_prepare_source_action_button_v01540_hotfix1(remove_button)
	remove_button.pressed.connect(_on_remove_source_v01537.bind(source_id))
	actions.add_child(remove_button)
	return card


func _prepare_source_action_button_v01540_hotfix1(button: Button) -> void:
	# The old HBox source row allowed every action button to inherit the height of
	# a heavily wrapped label. In a narrow sidebar that could turn Analyse/Remove
	# into full-window vertical columns. Buttons now live in their own flow row and
	# explicitly shrink to their normal control height.
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size.y = 0.0


func source_row_layout_snapshot_v01540_hotfix1() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _multi_source_list_v01537 == null:
		return result
	for child in _multi_source_list_v01537.get_children():
		if not child is PanelContainer or child.is_queued_for_deletion():
			continue
		var row := child as PanelContainer
		var label := row.find_child("SourceLabelV01540Hotfix1", true, false) as Label
		var actions := row.find_child("SourceActionsV01540Hotfix1", true, false) as HFlowContainer
		var button_rows: Array[Dictionary] = []
		if actions != null:
			for action in actions.get_children():
				if action is Button:
					button_rows.append({
						"text": (action as Button).text,
						"height": (action as Button).size.y,
						"vertical_flags": (action as Button).size_flags_vertical
					})
		result.append({
			"source_context_id": str(row.get_meta("source_context_id", "")),
			"row_height": row.size.y,
			"label_width": label.size.x if label != null else 0.0,
			"label_height": label.size.y if label != null else 0.0,
			"actions_y": actions.position.y if actions != null else 0.0,
			"actions_height": actions.size.y if actions != null else 0.0,
			"buttons": button_rows
		})
	return result
