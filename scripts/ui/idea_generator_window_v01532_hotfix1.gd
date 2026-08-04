class_name CCFIdeaGeneratorWindowV01532Hotfix1
extends "res://scripts/ui/idea_generator_window_v01532.gd"


func _ready() -> void:
	super._ready()
	_repair_ai_ideas_notebook_header_hotfix1()


func _repair_ai_ideas_notebook_header_hotfix1() -> void:
	var tab := _tabs.get_node_or_null("AI Ideas") as VBoxContainer
	if tab == null:
		return
	var old_toolbar := tab.get_node_or_null("IdeaNotebookActionsV01532") as Control
	if old_toolbar == null:
		return

	var insert_at := old_toolbar.get_index()
	var header := VBoxContainer.new()
	header.name = "IdeaNotebookActionsV01532Hotfix1"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_theme_constant_override("separation", 4)
	tab.add_child(header)
	tab.move_child(header, insert_at)

	var action_row := HBoxContainer.new()
	action_row.name = "IdeaNotebookActionButtonsV01532Hotfix1"
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	action_row.add_theme_constant_override("separation", 8)
	header.add_child(action_row)

	for child in old_toolbar.get_children():
		if child == _last_batch_label_v01532:
			continue
		child.reparent(action_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(spacer)

	if _last_batch_label_v01532 != null:
		_last_batch_label_v01532.reparent(header)
		_last_batch_label_v01532.name = "IdeaNotebookBatchStatusV01532Hotfix1"
		_last_batch_label_v01532.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_last_batch_label_v01532.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_last_batch_label_v01532.custom_minimum_size.x = 0
		_last_batch_label_v01532.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_last_batch_label_v01532.modulate = Color(0.72, 0.76, 0.86)

	old_toolbar.queue_free()
