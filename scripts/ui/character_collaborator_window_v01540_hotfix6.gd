class_name CCFCharacterCollaboratorWindowV01540Hotfix6
extends "res://scripts/ui/character_collaborator_window_v01540_hotfix5.gd"

const SCROLL_CONTENT_NAME_V01540_HOTFIX6 := "CollaboratorReferenceScrollContentV01540Hotfix6"
const WINDOW_BOTTOM_TOLERANCE_V01540_HOTFIX6 := 2.0

var _reference_scroll_content_v01540_hotfix6: VBoxContainer


func _ready() -> void:
	super._ready()
	_install_scrollable_reference_sidebar_v01540_hotfix6()
	_schedule_sidebar_final_reflow_v01540_hotfix3()
	_schedule_composer_reflow_v01540_hotfix5()


func _refresh_all() -> void:
	super._refresh_all()
	_install_scrollable_reference_sidebar_v01540_hotfix6()
	_schedule_composer_reflow_v01540_hotfix5()


func _process(delta: float) -> void:
	super._process(delta)
	if not visible:
		return
	if _composer_window_layout_needs_reflow_v01540_hotfix6():
		_schedule_composer_reflow_v01540_hotfix5()


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["scrollable_source_sidebar_v01540_hotfix6"] = true
	result["composer_window_bounds_guard_v01540_hotfix6"] = true
	return result


func sidebar_layout_capabilities_v01540_hotfix6() -> Dictionary:
	return {
		"version": "0.15.40-hotfix6",
		"structured_sources_inside_reference_scroll": true,
		"ordinary_context_inside_reference_scroll": true,
		"shared_scroll_content_column": true,
		"sidebar_dynamic_content_cannot_set_split_minimum_height": true,
		"inherits_whole_sidebar_final_reflow": true
	}


func composer_layout_capabilities_v01540_hotfix6() -> Dictionary:
	var result := super.composer_layout_capabilities_v01540_hotfix5()
	result["version"] = "0.15.40-hotfix6"
	result["composer_checked_against_window_viewport"] = true
	result["sidebar_minimum_height_decoupled"] = true
	return result


func _apply_sidebar_final_reflow_v01540_hotfix3() -> void:
	super._apply_sidebar_final_reflow_v01540_hotfix3()
	_install_scrollable_reference_sidebar_v01540_hotfix6()
	_schedule_composer_reflow_v01540_hotfix5()


func _apply_composer_reflow_v01540_hotfix5() -> void:
	_install_scrollable_reference_sidebar_v01540_hotfix6()
	super._apply_composer_reflow_v01540_hotfix5()
	_queue_window_layout_chain_v01540_hotfix6()


func _install_scrollable_reference_sidebar_v01540_hotfix6() -> void:
	if _context_list == null or _source_panel_v01533 == null:
		return
	var context_scroll := _reference_context_scroll_v01540_hotfix6()
	if context_scroll == null:
		return

	var content := _reference_scroll_content_v01540_hotfix6
	if content == null or not is_instance_valid(content):
		var existing := context_scroll.find_child(SCROLL_CONTENT_NAME_V01540_HOTFIX6, false, false)
		if existing is VBoxContainer:
			content = existing as VBoxContainer
		else:
			content = VBoxContainer.new()
			content.name = SCROLL_CONTENT_NAME_V01540_HOTFIX6
			content.add_theme_constant_override("separation", 8)
		_reference_scroll_content_v01540_hotfix6 = content

	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.custom_minimum_size.y = 0.0
	context_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	context_scroll.custom_minimum_size.y = 0.0
	context_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	context_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	# Both dynamic sidebar surfaces must live beneath the same ScrollContainer.
	# Otherwise the structured Sources block contributes a fixed vertical minimum
	# to the HSplitContainer while ordinary attachments do not.
	if content.get_parent() != context_scroll:
		var old_content_parent := content.get_parent()
		if old_content_parent != null:
			old_content_parent.remove_child(content)
		context_scroll.add_child(content)

	if _source_panel_v01533.get_parent() != content:
		var source_parent := _source_panel_v01533.get_parent()
		if source_parent != null:
			source_parent.remove_child(_source_panel_v01533)
		content.add_child(_source_panel_v01533)
	_source_panel_v01533.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_source_panel_v01533.custom_minimum_size.y = 0.0

	if _context_list.get_parent() != content:
		var list_parent := _context_list.get_parent()
		if list_parent != null:
			list_parent.remove_child(_context_list)
		content.add_child(_context_list)
	_context_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_context_list.custom_minimum_size.y = 0.0

	if _source_panel_v01533.get_index() > _context_list.get_index():
		content.move_child(_source_panel_v01533, 0)

	content.update_minimum_size()
	context_scroll.update_minimum_size()
	context_scroll.queue_sort()
	_queue_window_layout_chain_v01540_hotfix6()


func _reference_context_scroll_v01540_hotfix6() -> ScrollContainer:
	if _context_list == null:
		return null
	var node := _context_list.get_parent()
	while node != null and node != self:
		if node is ScrollContainer:
			return node as ScrollContainer
		node = node.get_parent()
	# During the first reparent operation the list may not yet be under the scroll.
	if _source_panel_v01533 != null:
		node = _source_panel_v01533.get_parent()
		while node != null and node != self:
			if node is ScrollContainer:
				return node as ScrollContainer
			node = node.get_parent()
	# Fall back to the original v0.15 construction: the source panel and scroll
	# are siblings under the Reference Context VBox.
	if _source_panel_v01533 != null and _source_panel_v01533.get_parent() != null:
		for sibling in _source_panel_v01533.get_parent().get_children():
			if sibling is ScrollContainer:
				return sibling as ScrollContainer
	return null


func _composer_window_layout_needs_reflow_v01540_hotfix6() -> bool:
	if not visible or _input == null:
		return false
	var viewport_rect := get_viewport().get_visible_rect()
	var chat_panel := _composer_panel_v01540_hotfix5()
	var input_index := _input.get_index()
	if _input.get_global_rect().end.y > viewport_rect.end.y + WINDOW_BOTTOM_TOLERANCE_V01540_HOTFIX6:
		return true
	if chat_panel != null:
		for child in chat_panel.get_children():
			if not child is Control:
				continue
			var control := child as Control
			if control.get_index() < input_index or not control.visible:
				continue
			if control.get_global_rect().end.y > viewport_rect.end.y + WINDOW_BOTTOM_TOLERANCE_V01540_HOTFIX6:
				return true
	return false


func _sidebar_layout_needs_reflow_v01540_hotfix3() -> bool:
	if super._sidebar_layout_needs_reflow_v01540_hotfix3():
		return true
	if _source_panel_v01533 == null or _context_list == null:
		return false
	var context_scroll := _reference_context_scroll_v01540_hotfix6()
	if context_scroll == null:
		return true
	if _reference_scroll_content_v01540_hotfix6 == null or not is_instance_valid(_reference_scroll_content_v01540_hotfix6):
		return true
	if _reference_scroll_content_v01540_hotfix6.get_parent() != context_scroll:
		return true
	if _source_panel_v01533.get_parent() != _reference_scroll_content_v01540_hotfix6:
		return true
	if _context_list.get_parent() != _reference_scroll_content_v01540_hotfix6:
		return true
	if context_scroll.custom_minimum_size.y > 0.0:
		return true
	return false


func _queue_window_layout_chain_v01540_hotfix6() -> void:
	var chat_panel := _composer_panel_v01540_hotfix5()
	if chat_panel == null:
		return
	var node := chat_panel.get_parent()
	var depth := 0
	while node != null and node != self and depth < 6:
		if node is Container:
			(node as Container).queue_sort()
		node = node.get_parent()
		depth += 1


func sidebar_scroll_snapshot_v01540_hotfix6() -> Dictionary:
	var context_scroll := _reference_context_scroll_v01540_hotfix6()
	var content := _reference_scroll_content_v01540_hotfix6
	return {
		"scroll_found": context_scroll != null,
		"content_found": content != null and is_instance_valid(content),
		"source_inside_scroll_content": _source_panel_v01533 != null and content != null and _source_panel_v01533.get_parent() == content,
		"context_inside_scroll_content": _context_list != null and content != null and _context_list.get_parent() == content,
		"scroll_min_height": context_scroll.custom_minimum_size.y if context_scroll != null else -1.0,
		"scroll_height": context_scroll.size.y if context_scroll != null else 0.0,
		"content_height": content.size.y if content != null and is_instance_valid(content) else 0.0,
		"vertical_scroll_visible": context_scroll.get_v_scroll_bar().visible if context_scroll != null else false,
		"needs_reflow": _sidebar_layout_needs_reflow_v01540_hotfix3()
	}


func composer_window_snapshot_v01540_hotfix6() -> Dictionary:
	var result := composer_layout_snapshot_v01540_hotfix5()
	var viewport_rect := get_viewport().get_visible_rect()
	var input_bottom := _input.get_global_rect().end.y if _input != null else 0.0
	var chat_panel := _composer_panel_v01540_hotfix5()
	var panel_bottom := chat_panel.get_global_rect().end.y if chat_panel != null else 0.0
	result["viewport_bottom"] = viewport_rect.end.y
	result["input_inside_viewport"] = input_bottom <= viewport_rect.end.y + WINDOW_BOTTOM_TOLERANCE_V01540_HOTFIX6
	result["chat_panel_inside_viewport"] = panel_bottom <= viewport_rect.end.y + WINDOW_BOTTOM_TOLERANCE_V01540_HOTFIX6
	result["window_guard_needs_reflow"] = _composer_window_layout_needs_reflow_v01540_hotfix6()
	return result
