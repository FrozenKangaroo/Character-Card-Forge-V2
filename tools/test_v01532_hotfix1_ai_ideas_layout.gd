extends SceneTree

const HOTFIX_WINDOW = preload("res://scripts/ui/idea_generator_window_v01532_hotfix1.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var window := HOTFIX_WINDOW.new()
	window.visible = false
	window.size = Vector2i(1280, 800)
	root.add_child(window)
	await process_frame
	await process_frame

	var header := window.find_child("IdeaNotebookActionsV01532Hotfix1", true, false) as VBoxContainer
	assert(header != null, "The AI Ideas Notebook controls must use the hotfix VBox header.")
	assert(header.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "The hotfix header must fill the AI Ideas tab horizontally.")
	assert(header.size_flags_vertical == Control.SIZE_SHRINK_BEGIN, "The hotfix header must not consume the expandable AI Ideas result area.")

	var action_row := header.get_node_or_null("IdeaNotebookActionButtonsV01532Hotfix1") as HBoxContainer
	assert(action_row != null, "Save/Open Notebook actions must live in a compact horizontal row.")
	assert(action_row.size_flags_vertical == Control.SIZE_SHRINK_BEGIN, "The AI Ideas action row must remain vertically compact.")

	var status := header.get_node_or_null("IdeaNotebookBatchStatusV01532Hotfix1") as Label
	assert(status != null, "The latest-batch status must be a separate full-width row below the buttons.")
	assert(status.get_parent() == header, "The latest-batch status must not share the wrapping button flow container.")
	assert(status.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "The batch-status label must receive the available tab width.")
	assert(status.size_flags_vertical == Control.SIZE_SHRINK_BEGIN, "The batch-status label must not stretch the AI Ideas tab vertically.")
	assert(status.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "The batch-status label should wrap by words when the window is genuinely narrow.")

	assert(window.find_child("IdeaNotebookActionsV01532", true, false) == null, "The old HFlowContainer toolbar must be removed after the hotfix applies.")

	var save_button: Button = null
	var open_button: Button = null
	for child in action_row.get_children():
		if child is Button and child.text == "Save Generated Ideas…":
			save_button = child
		elif child is Button and child.text == "Open Idea Notebook":
			open_button = child
	assert(save_button != null, "Save Generated Ideas must remain available after the layout repair.")
	assert(open_button != null, "Open Idea Notebook must remain available after the layout repair.")

	window.queue_free()
	await process_frame
	print("v0.15.32-hotfix1 AI Ideas layout regression passed")
	quit(0)
