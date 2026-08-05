class_name CCFCollaboratorCompletionDestinationWindowV01535
extends Window

signal destination_selected(destination_id: String)
signal routing_cancelled

const COMPLETION_SERVICE_V01535 = preload(
	"res://scripts/services/collaborator_completion_service_v01535.gd"
)

var _destination_v01535: OptionButton
var _description_v01535: Label
var _context_v01535: Label
var _safety_note_v01535: Label
var _status_v01535: Label
var _options_v01535: Array[Dictionary] = []


func _ready() -> void:
	visible = false
	title = "Choose Collaborator Workspace Destination"
	size = Vector2i(800, 570)
	min_size = Vector2i(650, 470)
	force_native = true
	transient = false
	exclusive = false
	close_requested.connect(_cancel_v01535)
	_build_ui_v01535()


func open_for_completion_v01535(
	current_character: Dictionary,
	template: Dictionary,
	project_name: String,
	current_character_name: String
) -> void:
	_options_v01535 = COMPLETION_SERVICE_V01535.destination_options(
		current_character,
		template
	)
	_destination_v01535.clear()
	var recommended := COMPLETION_SERVICE_V01535.recommended_destination(
		current_character,
		template
	)
	var selected_index := 0
	for option in _options_v01535:
		_destination_v01535.add_item(str(option.get("label", "Workspace destination")))
		var index := _destination_v01535.item_count - 1
		var destination_id := str(option.get("id", ""))
		_destination_v01535.set_item_metadata(index, destination_id)
		if destination_id == recommended:
			selected_index = index
	if _destination_v01535.item_count > 0:
		_destination_v01535.select(selected_index)
	_context_v01535.text = "Current project: %s\nCurrent character: %s" % [
		project_name if not project_name.strip_edges().is_empty() else "Untitled Project",
		current_character_name if not current_character_name.strip_edges().is_empty() else "Untitled Character"
	]
	_status_v01535.text = ""
	_refresh_description_v01535()
	popup_centered()


func destination_ids_v01535() -> Array[String]:
	var result: Array[String] = []
	if _destination_v01535 == null:
		return result
	for index in range(_destination_v01535.item_count):
		result.append(str(_destination_v01535.get_item_metadata(index)))
	return result


func selected_destination_v01535() -> String:
	if _destination_v01535 == null or _destination_v01535.item_count == 0:
		return ""
	return str(_destination_v01535.get_selected_metadata())


func _build_ui_v01535() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 11)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "Where should this completed Collaborator character go?"
	heading.add_theme_font_size_override("font_size", 22)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(heading)

	var intro := Label.new()
	intro.text = (
		"The generated Blueprint or detailed draft is ready. Choose its destination before Character Card Forge changes Workspace data. Occupied characters are never replaced automatically."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.76, 0.80, 0.90)
	root.add_child(intro)

	_context_v01535 = Label.new()
	_context_v01535.name = "CollaboratorCompletionContextV01535"
	_context_v01535.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_context_v01535.add_theme_font_size_override("font_size", 16)
	root.add_child(_context_v01535)

	var destination_label := Label.new()
	destination_label.text = "Workspace destination"
	root.add_child(destination_label)

	_destination_v01535 = OptionButton.new()
	_destination_v01535.name = "CollaboratorCompletionDestinationV01535"
	_destination_v01535.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_destination_v01535.item_selected.connect(
		func(_index: int) -> void: _refresh_description_v01535()
	)
	root.add_child(_destination_v01535)

	_description_v01535 = Label.new()
	_description_v01535.name = "CollaboratorCompletionDestinationDescriptionV01535"
	_description_v01535.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_v01535.modulate = Color(0.70, 0.75, 0.86)
	_description_v01535.custom_minimum_size.y = 70
	root.add_child(_description_v01535)

	_safety_note_v01535 = Label.new()
	_safety_note_v01535.text = (
		"Safety rule: an occupied current character is never overwritten by this release. Refining/replacing an existing character remains the v0.15.36 Compare & Apply workflow."
	)
	_safety_note_v01535.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_safety_note_v01535.modulate = Color(0.82, 0.70, 0.48)
	root.add_child(_safety_note_v01535)

	_status_v01535 = Label.new()
	_status_v01535.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_v01535.modulate = Color(0.84, 0.72, 0.50)
	root.add_child(_status_v01535)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_cancel_v01535)
	actions.add_child(cancel_button)

	var apply_button := Button.new()
	apply_button.name = "ApplyCollaboratorCompletionDestinationV01535"
	apply_button.text = "Place Character"
	apply_button.pressed.connect(_submit_v01535)
	actions.add_child(apply_button)


func _refresh_description_v01535() -> void:
	if _destination_v01535 == null or _destination_v01535.item_count == 0:
		if _description_v01535 != null:
			_description_v01535.text = "No safe destination is available."
		return
	var selected_id := str(_destination_v01535.get_selected_metadata())
	for option in _options_v01535:
		if str(option.get("id", "")) == selected_id:
			_description_v01535.text = str(option.get("description", ""))
			return
	_description_v01535.text = "Choose a valid Workspace destination."


func _submit_v01535() -> void:
	var destination_id := selected_destination_v01535()
	if destination_id.is_empty():
		_status_v01535.text = "Choose a valid Workspace destination."
		return
	destination_selected.emit(destination_id)
	hide()


func _cancel_v01535() -> void:
	hide()
	routing_cancelled.emit()
