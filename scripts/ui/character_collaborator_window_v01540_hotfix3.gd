class_name CCFCharacterCollaboratorWindowV01540Hotfix3
extends "res://scripts/ui/character_collaborator_window_v01540_hotfix2.gd"

const ATTACHMENT_SERVICE_V01540_HOTFIX3 = preload(
	"res://scripts/services/collaborator_attachment_service_v01521.gd"
)

const SIDEBAR_BUTTON_MAX_SAFE_HEIGHT_V01540_HOTFIX3 := 72.0

var _sidebar_reflow_pending_v01540_hotfix3 := false


func _ready() -> void:
	super._ready()
	if not sessions_changed.is_connected(_on_sidebar_sessions_changed_v01540_hotfix3):
		sessions_changed.connect(_on_sidebar_sessions_changed_v01540_hotfix3)
	if not visibility_changed.is_connected(_schedule_sidebar_final_reflow_v01540_hotfix3):
		visibility_changed.connect(_schedule_sidebar_final_reflow_v01540_hotfix3)
	if not size_changed.is_connected(_schedule_sidebar_final_reflow_v01540_hotfix3):
		size_changed.connect(_schedule_sidebar_final_reflow_v01540_hotfix3)
	if _session_selector != null and not _session_selector.item_selected.is_connected(_on_sidebar_session_selected_v01540_hotfix3):
		_session_selector.item_selected.connect(_on_sidebar_session_selected_v01540_hotfix3)
	_schedule_sidebar_final_reflow_v01540_hotfix3()


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["sidebar_final_reflow_v01540_hotfix3"] = true
	result["reference_context_rows_stacked_v01540_hotfix3"] = true
	result["visible_sidebar_runtime_guard_v01540_hotfix3"] = true
	return result


func sidebar_layout_capabilities_v01540_hotfix3() -> Dictionary:
	return {
		"version": "0.15.40-hotfix3",
		"final_deferred_reflow": true,
		"runtime_visible_guard": true,
		"structured_source_rows_stacked": true,
		"reference_context_rows_stacked": true,
		"all_sidebar_actions_vertically_compact": true,
		"whole_sidebar_regression_scope": true
	}


func _refresh_all() -> void:
	super._refresh_all()
	_schedule_sidebar_final_reflow_v01540_hotfix3()


func _process(_delta: float) -> void:
	if not visible:
		return
	if _sidebar_layout_needs_reflow_v01540_hotfix3():
		_schedule_sidebar_final_reflow_v01540_hotfix3()


func _on_sidebar_sessions_changed_v01540_hotfix3(_sessions: Array) -> void:
	_schedule_sidebar_final_reflow_v01540_hotfix3()


func _on_sidebar_session_selected_v01540_hotfix3(_index: int) -> void:
	_schedule_sidebar_final_reflow_v01540_hotfix3()


func _schedule_sidebar_final_reflow_v01540_hotfix3() -> void:
	if _sidebar_reflow_pending_v01540_hotfix3:
		return
	_sidebar_reflow_pending_v01540_hotfix3 = true
	call_deferred("_apply_sidebar_final_reflow_v01540_hotfix3")


func _apply_sidebar_final_reflow_v01540_hotfix3() -> void:
	_sidebar_reflow_pending_v01540_hotfix3 = false
	if not is_inside_tree():
		return
	# Rebuild both independent left-sidebar surfaces after the current inherited
	# refresh stack has finished. Card data + Vision touches both surfaces, so a
	# source-only postcondition is insufficient.
	_rebuild_live_source_rows_v01540_hotfix2()
	_rebuild_reference_context_rows_v01540_hotfix3()
	_compact_sidebar_buttons_v01540_hotfix3()


func _rebuild_reference_context_rows_v01540_hotfix3() -> void:
	if _context_list == null:
		return
	for child in _context_list.get_children():
		_context_list.remove_child(child)
		child.queue_free()

	var session := _active_session()
	var items_value: Variant = session.get("context_items", [])
	var items: Array = items_value if items_value is Array else []
	if items.is_empty():
		var empty := Label.new()
		empty.text = "No reference context or attachments added."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.set_meta("context_row_renderer", "v0.15.40-hotfix3-empty")
		_context_list.add_child(empty)
		return

	for index in range(items.size()):
		if not items[index] is Dictionary:
			continue
		var item: Dictionary = items[index]
		var card := PanelContainer.new()
		card.name = "CollaboratorContextRowV01540Hotfix3"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		card.set_meta("context_row_renderer", "v0.15.40-hotfix3")
		card.set_meta("context_index", index)
		_context_list.add_child(card)

		var stack := VBoxContainer.new()
		stack.name = "ContextRowStackV01540Hotfix3"
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		stack.add_theme_constant_override("separation", 4)
		card.add_child(stack)

		var label := Label.new()
		label.name = "ContextLabelV01540Hotfix3"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if ATTACHMENT_SERVICE_V01540_HOTFIX3.is_attachment_context_item(item):
			var token_count := CCFGenerationService.estimate_tokens(str(item.get("content", "")))
			label.text = "Attachment • %s • %s • ~%s tokens" % [
				str(item.get("label", "Untitled")),
				ATTACHMENT_SERVICE_V01540_HOTFIX3.display_format(item),
				_format_tokens_v0151(token_count)
			]
		else:
			label.text = "%s • %s" % [
				str(item.get("type", "context")).replace("_", " ").capitalize(),
				str(item.get("label", "Untitled"))
			]
		stack.add_child(label)

		var preview := Label.new()
		preview.name = "ContextPreviewV01540Hotfix3"
		preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var preview_source := str(item.get("raw_text", item.get("vision_description", item.get("content", ""))))
		preview.text = _truncate(preview_source, 360)
		preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview.modulate = Color(0.70, 0.74, 0.82)
		stack.add_child(preview)

		var actions := HFlowContainer.new()
		actions.name = "ContextActionsV01540Hotfix3"
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		actions.add_theme_constant_override("h_separation", 4)
		actions.add_theme_constant_override("v_separation", 4)
		stack.add_child(actions)

		var remove := Button.new()
		remove.text = "Remove"
		remove.tooltip_text = "Remove this reference or attachment from future Collaborator context. The historical conversation remains unchanged."
		_prepare_sidebar_action_button_v01540_hotfix3(remove)
		remove.pressed.connect(_on_remove_context_item_v01540_hotfix3.bind(index))
		actions.add_child(remove)


func _on_remove_context_item_v01540_hotfix3(index: int) -> void:
	_remove_context_item(index)


func _prepare_sidebar_action_button_v01540_hotfix3(button: Button) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2.ZERO


func _compact_sidebar_buttons_v01540_hotfix3() -> void:
	for root_control in [_source_panel_v01533, _context_list]:
		if root_control == null:
			continue
		for node in root_control.find_children("*", "Button", true, false):
			if node is Button:
				_prepare_sidebar_action_button_v01540_hotfix3(node as Button)


func _sidebar_layout_needs_reflow_v01540_hotfix3() -> bool:
	var source_count := active_source_contexts_v01537().size()
	if source_count > 0:
		if _multi_source_list_v01537 == null:
			return true
		var live_source_rows := 0
		for child in _multi_source_list_v01537.get_children():
			if child.is_queued_for_deletion():
				continue
			live_source_rows += 1
			if not child is PanelContainer:
				return true
			if not str(child.get_meta("source_row_renderer", "")).begins_with("v0.15.40-hotfix"):
				return true
		if live_source_rows != source_count:
			return true

	var session := _active_session()
	var items_value: Variant = session.get("context_items", [])
	var items: Array = items_value if items_value is Array else []
	if not items.is_empty():
		if _context_list == null:
			return true
		var live_context_rows := 0
		for child in _context_list.get_children():
			if child.is_queued_for_deletion():
				continue
			live_context_rows += 1
			if not child is PanelContainer:
				return true
			if str(child.get_meta("context_row_renderer", "")) != "v0.15.40-hotfix3":
				return true
		if live_context_rows != items.size():
			return true

	for root_control in [_source_panel_v01533, _context_list]:
		if root_control == null:
			continue
		for node in root_control.find_children("*", "Button", true, false):
			if node is Button and (node as Button).size.y > SIDEBAR_BUTTON_MAX_SAFE_HEIGHT_V01540_HOTFIX3:
				return true
	return false


func sidebar_layout_snapshot_v01540_hotfix3() -> Dictionary:
	var buttons: Array[Dictionary] = []
	for root_control in [_source_panel_v01533, _context_list]:
		if root_control == null:
			continue
		for node in root_control.find_children("*", "Button", true, false):
			if node is Button:
				var button := node as Button
				buttons.append({
					"text": button.text,
					"height": button.size.y,
					"vertical_flags": button.size_flags_vertical,
					"parent_type": button.get_parent().get_class() if button.get_parent() != null else ""
				})
	return {
		"source_rows": source_row_layout_snapshot_v01540_hotfix2(),
		"context_row_count": _context_list.get_child_count() if _context_list != null else 0,
		"buttons": buttons,
		"needs_reflow": _sidebar_layout_needs_reflow_v01540_hotfix3()
	}
