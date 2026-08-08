class_name CCFCharacterCollaboratorWindowV01540Hotfix5
extends "res://scripts/ui/character_collaborator_window_v01540_hotfix4.gd"

const COMPOSER_INPUT_MIN_HEIGHT_V01540_HOTFIX5 := 100.0
const COMPOSER_BOTTOM_TOLERANCE_V01540_HOTFIX5 := 2.0

var _composer_reflow_pending_v01540_hotfix5 := false


func _ready() -> void:
	super._ready()
	if not size_changed.is_connected(_schedule_composer_reflow_v01540_hotfix5):
		size_changed.connect(_schedule_composer_reflow_v01540_hotfix5)
	if not visibility_changed.is_connected(_schedule_composer_reflow_v01540_hotfix5):
		visibility_changed.connect(_schedule_composer_reflow_v01540_hotfix5)
	_schedule_composer_reflow_v01540_hotfix5()


func _refresh_all() -> void:
	super._refresh_all()
	_schedule_composer_reflow_v01540_hotfix5()


func _process(delta: float) -> void:
	super._process(delta)
	if not visible:
		return
	if _composer_layout_needs_reflow_v01540_hotfix5():
		_schedule_composer_reflow_v01540_hotfix5()


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["composer_resize_guard_v01540_hotfix5"] = true
	result["composer_bottom_pinned_v01540_hotfix5"] = true
	return result


func composer_layout_capabilities_v01540_hotfix5() -> Dictionary:
	return {
		"version": "0.15.40-hotfix5",
		"composer_resize_guard": true,
		"chat_scroll_absorbs_vertical_resize": true,
		"composer_controls_vertical_shrink": true,
		"deferred_resize_reflow": true
	}


func _schedule_composer_reflow_v01540_hotfix5() -> void:
	if _composer_reflow_pending_v01540_hotfix5:
		return
	_composer_reflow_pending_v01540_hotfix5 = true
	call_deferred("_apply_composer_reflow_v01540_hotfix5")


func _apply_composer_reflow_v01540_hotfix5() -> void:
	_composer_reflow_pending_v01540_hotfix5 = false
	if not is_inside_tree() or _input == null or _chat_scroll == null:
		return
	var chat_panel := _composer_panel_v01540_hotfix5()
	if chat_panel == null:
		return

	chat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_panel.custom_minimum_size.y = 0.0
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_scroll.size_flags_stretch_ratio = 1.0
	_chat_scroll.custom_minimum_size.y = 0.0
	if _chat_list != null:
		_chat_list.custom_minimum_size.y = 0.0

	_input.visible = true
	_input.size_flags_vertical = Control.SIZE_SHRINK_END
	_input.size_flags_stretch_ratio = 0.0
	_input.custom_minimum_size.y = maxf(_input.custom_minimum_size.y, COMPOSER_INPUT_MIN_HEIGHT_V01540_HOTFIX5)
	_input.update_minimum_size()

	var input_index := _input.get_index()
	for child in chat_panel.get_children():
		if not child is Control:
			continue
		var control := child as Control
		if control == _chat_scroll:
			continue
		if control.get_index() >= input_index:
			control.size_flags_vertical = Control.SIZE_SHRINK_END
			control.size_flags_stretch_ratio = 0.0

	chat_panel.update_minimum_size()
	chat_panel.queue_sort()
	var parent := chat_panel.get_parent()
	for _depth in range(4):
		if parent == null:
			break
		if parent is Container:
			(parent as Container).queue_sort()
		parent = parent.get_parent()


func _composer_panel_v01540_hotfix5() -> VBoxContainer:
	if _input == null:
		return null
	var parent := _input.get_parent()
	if parent is VBoxContainer:
		return parent as VBoxContainer
	return null


func _composer_layout_needs_reflow_v01540_hotfix5() -> bool:
	if _input == null or _chat_scroll == null:
		return false
	var chat_panel := _composer_panel_v01540_hotfix5()
	if chat_panel == null:
		return false
	if not _input.visible:
		return true
	if _chat_scroll.size_flags_vertical != Control.SIZE_EXPAND_FILL:
		return true
	if _chat_scroll.custom_minimum_size.y > 0.0:
		return true
	if _input.size_flags_vertical != Control.SIZE_SHRINK_END:
		return true
	if _input.custom_minimum_size.y < COMPOSER_INPUT_MIN_HEIGHT_V01540_HOTFIX5:
		return true
	if not chat_panel.is_visible_in_tree():
		return false
	var panel_rect := chat_panel.get_global_rect()
	var input_rect := _input.get_global_rect()
	if input_rect.end.y > panel_rect.end.y + COMPOSER_BOTTOM_TOLERANCE_V01540_HOTFIX5:
		return true
	var input_index := _input.get_index()
	for child in chat_panel.get_children():
		if not child is Control:
			continue
		var control := child as Control
		if control.get_index() < input_index or not control.visible:
			continue
		if control.get_global_rect().end.y > panel_rect.end.y + COMPOSER_BOTTOM_TOLERANCE_V01540_HOTFIX5:
			return true
	return false


func composer_layout_snapshot_v01540_hotfix5() -> Dictionary:
	var chat_panel := _composer_panel_v01540_hotfix5()
	var panel_bottom := 0.0
	var input_bottom := 0.0
	var input_top := 0.0
	if chat_panel != null:
		panel_bottom = chat_panel.get_global_rect().end.y
	if _input != null:
		input_top = _input.get_global_rect().position.y
		input_bottom = _input.get_global_rect().end.y
	return {
		"panel_found": chat_panel != null,
		"panel_height": chat_panel.size.y if chat_panel != null else 0.0,
		"chat_scroll_height": _chat_scroll.size.y if _chat_scroll != null else 0.0,
		"chat_scroll_min_height": _chat_scroll.custom_minimum_size.y if _chat_scroll != null else 0.0,
		"input_visible": _input.visible if _input != null else false,
		"input_top": input_top,
		"input_bottom": input_bottom,
		"panel_bottom": panel_bottom,
		"input_vertical_flags": _input.size_flags_vertical if _input != null else -1,
		"needs_reflow": _composer_layout_needs_reflow_v01540_hotfix5()
	}
