class_name CCFCharacterCollaboratorWindowV01540Hotfix4
extends "res://scripts/ui/character_collaborator_window_v01540_hotfix3.gd"

const SOURCE_HELPER_ACTIONS_NAME_V01540_HOTFIX4 := "CollaboratorMultiSourceActionsV01537"
const SOURCE_HELPER_LABEL_NAME_V01540_HOTFIX4 := "CollaboratorMultiSourceHintV01540Hotfix4"
const SOURCE_HELPER_PREFIX_V01540_HOTFIX4 := "Character Card JSON/PNG added through Attach Files"
const SOURCE_HELPER_MIN_WIDTH_V01540_HOTFIX4 := 260.0
const SOURCE_HELPER_UNSAFE_WIDTH_V01540_HOTFIX4 := 220.0


func _ready() -> void:
	super._ready()
	_repair_source_helper_layout_v01540_hotfix4()
	_schedule_sidebar_final_reflow_v01540_hotfix3()


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["source_helper_full_width_v01540_hotfix4"] = true
	result["source_helper_outside_action_flow_v01540_hotfix4"] = true
	result["source_helper_readable_minimum_v01540_hotfix4"] = true
	return result


func sidebar_layout_capabilities_v01540_hotfix4() -> Dictionary:
	return {
		"version": "0.15.40-hotfix4",
		"source_helper_full_width": true,
		"source_helper_outside_action_flow": true,
		"source_helper_minimum_width": SOURCE_HELPER_MIN_WIDTH_V01540_HOTFIX4,
		"source_action_flow_buttons_only": true,
		"source_list_full_width": true,
		"inherits_whole_sidebar_final_reflow": true,
		"inherits_runtime_visible_guard": true
	}


# hotfix3 made the dynamic source/context rows authoritative, but the user's
# next runtime screenshot exposed a separate inherited static label from
# v0.15.37. That helper lived inside the same HFlowContainer as source actions.
# At real desktop widths Godot could allocate it essentially one glyph of width,
# producing one-character-per-line text. Keep explanatory prose and actions in
# different layout regions permanently, and give prose a real readable minimum
# rather than relying only on size flags.
func _apply_sidebar_final_reflow_v01540_hotfix3() -> void:
	super._apply_sidebar_final_reflow_v01540_hotfix3()
	_repair_source_helper_layout_v01540_hotfix4()


func _repair_source_helper_layout_v01540_hotfix4() -> void:
	if _source_panel_v01533 == null:
		return
	_source_panel_v01533.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_source_panel_v01533.custom_minimum_size.x = maxf(
		_source_panel_v01533.custom_minimum_size.x,
		SOURCE_HELPER_MIN_WIDTH_V01540_HOTFIX4
	)

	if _multi_source_list_v01537 != null:
		_multi_source_list_v01537.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_multi_source_list_v01537.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_multi_source_list_v01537.custom_minimum_size.x = SOURCE_HELPER_MIN_WIDTH_V01540_HOTFIX4

	var actions := _source_actions_container_v01540_hotfix4()
	if actions == null:
		return
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	actions.custom_minimum_size.x = 0.0

	var hint := _source_helper_label_v01540_hotfix4()
	if hint == null:
		return

	if hint.get_parent() == actions:
		var actions_index := actions.get_index()
		actions.remove_child(hint)
		_source_panel_v01533.add_child(hint)
		_source_panel_v01533.move_child(
			hint,
			mini(actions_index + 1, _source_panel_v01533.get_child_count() - 1)
		)

	_prepare_source_helper_label_v01540_hotfix4(hint)

	# Source action flows are action-only. If a future inherited layer adds more
	# descriptive labels here, move them out as well so the same collapse cannot
	# reappear under a different helper string.
	var extra_labels: Array[Label] = []
	for child in actions.get_children():
		if child is Label:
			extra_labels.append(child as Label)
	for extra in extra_labels:
		actions.remove_child(extra)
		_source_panel_v01533.add_child(extra)
		_source_panel_v01533.move_child(
			extra,
			mini(actions.get_index() + 1, _source_panel_v01533.get_child_count() - 1)
		)
		_prepare_source_helper_label_v01540_hotfix4(extra)

	for child in actions.get_children():
		if child is Button:
			_prepare_sidebar_action_button_v01540_hotfix3(child as Button)

	_source_panel_v01533.minimum_size_changed()


func _prepare_source_helper_label_v01540_hotfix4(label: Label) -> void:
	label.name = SOURCE_HELPER_LABEL_NAME_V01540_HOTFIX4 if label.text.begins_with(SOURCE_HELPER_PREFIX_V01540_HOTFIX4) else label.name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.custom_minimum_size.x = SOURCE_HELPER_MIN_WIDTH_V01540_HOTFIX4
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.minimum_size_changed()


func _source_actions_container_v01540_hotfix4() -> HFlowContainer:
	if _source_panel_v01533 == null:
		return null
	var found := _source_panel_v01533.find_child(
		SOURCE_HELPER_ACTIONS_NAME_V01540_HOTFIX4,
		true,
		false
	)
	return found as HFlowContainer if found is HFlowContainer else null


func _source_helper_label_v01540_hotfix4() -> Label:
	if _source_panel_v01533 == null:
		return null
	var named := _source_panel_v01533.find_child(
		SOURCE_HELPER_LABEL_NAME_V01540_HOTFIX4,
		true,
		false
	)
	if named is Label:
		return named as Label
	for node in _source_panel_v01533.find_children("*", "Label", true, false):
		if node is Label and (node as Label).text.begins_with(SOURCE_HELPER_PREFIX_V01540_HOTFIX4):
			return node as Label
	return null


func _sidebar_layout_needs_reflow_v01540_hotfix3() -> bool:
	if super._sidebar_layout_needs_reflow_v01540_hotfix3():
		return true
	var actions := _source_actions_container_v01540_hotfix4()
	if actions != null:
		for child in actions.get_children():
			if child is Label:
				return true
	var hint := _source_helper_label_v01540_hotfix4()
	if hint != null:
		if hint.get_parent() is HFlowContainer:
			return true
		if hint.size_flags_horizontal != Control.SIZE_EXPAND_FILL:
			return true
		if hint.custom_minimum_size.x < SOURCE_HELPER_MIN_WIDTH_V01540_HOTFIX4:
			return true
		if hint.size.x > 0.0 and hint.size.x < SOURCE_HELPER_UNSAFE_WIDTH_V01540_HOTFIX4:
			return true
	return false


func source_helper_layout_snapshot_v01540_hotfix4() -> Dictionary:
	var actions := _source_actions_container_v01540_hotfix4()
	var hint := _source_helper_label_v01540_hotfix4()
	var labels_in_actions := 0
	if actions != null:
		for child in actions.get_children():
			if child is Label:
				labels_in_actions += 1
	return {
		"hint_found": hint != null,
		"hint_parent_type": hint.get_parent().get_class() if hint != null and hint.get_parent() != null else "",
		"hint_parent_name": hint.get_parent().name if hint != null and hint.get_parent() != null else "",
		"hint_width": hint.size.x if hint != null else 0.0,
		"hint_custom_min_width": hint.custom_minimum_size.x if hint != null else 0.0,
		"hint_horizontal_flags": hint.size_flags_horizontal if hint != null else -1,
		"source_panel_width": _source_panel_v01533.size.x if _source_panel_v01533 != null else 0.0,
		"source_list_width": _multi_source_list_v01537.size.x if _multi_source_list_v01537 != null else 0.0,
		"labels_in_action_flow": labels_in_actions,
		"needs_reflow": _sidebar_layout_needs_reflow_v01540_hotfix3()
	}
