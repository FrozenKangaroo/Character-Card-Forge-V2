class_name CCFGettingStartedWindowV0201
extends Window

signal action_requested(action_id: String)
signal dismissed()


func _ready() -> void:
	title = "Getting Started with Character Card Forge"
	size = Vector2i(800, 660)
	min_size = Vector2i(650, 520)
	force_native = true
	transient = false
	exclusive = false
	close_requested.connect(_dismiss)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "Create your first character your way"
	heading.add_theme_font_size_override("font_size", 26)
	root.add_child(heading)
	var intro := Label.new()
	intro.text = "Start manually, generate ideas, collaborate with AI, or import a card. Every route leads to the same editable workspace and nothing is sent to a provider until you explicitly request an AI action."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.76, 0.78, 0.86)
	root.add_child(intro)
	root.add_child(_guide_step("1", "Choose a starting path", "New Project explains each creation method and lets you select the starting template.", "new_project", "Choose New Project…"))
	root.add_child(_guide_step("2", "Set up AI only if wanted", "Settings keeps Text, Vision and Image profiles separate. Manual authoring works without an API.", "settings", "Open Settings"))
	root.add_child(_guide_step("3", "Find any command quickly", "Press Ctrl+K to search actions. The palette also lists the shortcuts for saving, reviewing, exporting and lorebooks.", "quick_actions", "Open Quick Actions"))
	root.add_child(_guide_step("4", "Return to your library", "Projects, revisions and managed assets stay in the selected library location.", "library", "Open Character Library"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var finish := Button.new()
	finish.text = "Got it — close guide"
	finish.pressed.connect(_dismiss)
	root.add_child(finish)


func open_guide() -> void:
	popup_centered()


func _guide_step(
	number: String,
	step_title: String,
	description: String,
	action_id: String,
	button_text: String
) -> Control:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var number_label := Label.new()
	number_label.text = number
	number_label.add_theme_font_size_override("font_size", 22)
	number_label.custom_minimum_size.x = 28
	row.add_child(number_label)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var title_label := Label.new()
	title_label.text = step_title
	title_label.add_theme_font_size_override("font_size", 18)
	copy.add_child(title_label)
	var detail := Label.new()
	detail.text = description
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.modulate = Color(0.70, 0.72, 0.80)
	copy.add_child(detail)
	var action := Button.new()
	action.text = button_text
	action.pressed.connect(_request_action.bind(action_id))
	row.add_child(action)
	return panel


func _request_action(action_id: String) -> void:
	hide()
	action_requested.emit(action_id)


func _dismiss() -> void:
	hide()
	dismissed.emit()
