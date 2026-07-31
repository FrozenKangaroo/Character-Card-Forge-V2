class_name CCFWorkspaceV0142View
extends "res://scripts/ui/workspace_v0141.gd"

const CHARACTER_TRANSFER_SERVICE = preload("res://scripts/services/character_transfer_service.gd")

var _transfer_window: Window
var _transfer_operation: OptionButton
var _transfer_destination: OptionButton
var _transfer_new_name_label: Label
var _transfer_new_name: LineEdit
var _transfer_open_destination: CheckBox
var _transfer_warning: Label
var _transfer_status: Label
var _transfer_execute_button: Button


func _ready() -> void:
	super._ready()
	_add_character_transfer_button()
	_build_character_transfer_window()


func _add_character_transfer_button() -> void:
	for node in find_children("*", "Button", true, false):
		if not node is Button:
			continue
		var button := node as Button
		if button.text != "Duplicate Character":
			continue
		var parent := button.get_parent()
		if parent == null:
			return
		var transfer_button := Button.new()
		transfer_button.text = "Move / Copy…"
		transfer_button.tooltip_text = "Move or copy the active character into another Character Project or a new project."
		transfer_button.pressed.connect(_open_character_transfer)
		parent.add_child(transfer_button)
		parent.move_child(transfer_button, button.get_index() + 1)
		return


func _build_character_transfer_window() -> void:
	_transfer_window = Window.new()
	_transfer_window.visible = false
	_transfer_window.title = "Move / Copy Character"
	_transfer_window.size = Vector2i(680, 500)
	_transfer_window.min_size = Vector2i(560, 420)
	_transfer_window.force_native = true
	_transfer_window.transient = true
	_transfer_window.exclusive = false
	_transfer_window.close_requested.connect(_hide_character_transfer)
	add_child(_transfer_window)
	_transfer_window.hide()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_transfer_window.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Transfer active character"
	title.add_theme_font_size_override("font_size", 21)
	root.add_child(title)

	var intro := Label.new()
	intro.text = "Transfer the complete character-local workspace: card fields, concept, Builder state, Interview review, Mode & Style, assigned template, attachments, portrait and generated/emotion image records. Shared project context and relationships stay with their project."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.70, 0.74, 0.84)
	root.add_child(intro)

	var operation_row := HBoxContainer.new()
	operation_row.add_theme_constant_override("separation", 8)
	root.add_child(operation_row)
	var operation_label := Label.new()
	operation_label.text = "Operation"
	operation_row.add_child(operation_label)
	_transfer_operation = OptionButton.new()
	_transfer_operation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_transfer_operation.add_item("Copy character")
	_transfer_operation.set_item_metadata(0, CHARACTER_TRANSFER_SERVICE.OPERATION_COPY)
	_transfer_operation.add_item("Move character")
	_transfer_operation.set_item_metadata(1, CHARACTER_TRANSFER_SERVICE.OPERATION_MOVE)
	_transfer_operation.item_selected.connect(_on_transfer_operation_changed)
	operation_row.add_child(_transfer_operation)

	var destination_row := HBoxContainer.new()
	destination_row.add_theme_constant_override("separation", 8)
	root.add_child(destination_row)
	var destination_label := Label.new()
	destination_label.text = "Destination"
	destination_row.add_child(destination_label)
	_transfer_destination = OptionButton.new()
	_transfer_destination.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_transfer_destination.item_selected.connect(_on_transfer_destination_changed)
	destination_row.add_child(_transfer_destination)

	_transfer_new_name_label = Label.new()
	_transfer_new_name_label.text = "New project name"
	root.add_child(_transfer_new_name_label)
	_transfer_new_name = LineEdit.new()
	_transfer_new_name.placeholder_text = "Leave blank to use the character's first name"
	root.add_child(_transfer_new_name)

	_transfer_open_destination = CheckBox.new()
	_transfer_open_destination.text = "Open destination project after transfer"
	_transfer_open_destination.button_pressed = true
	root.add_child(_transfer_open_destination)

	_transfer_warning = Label.new()
	_transfer_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_transfer_warning.modulate = Color(0.84, 0.73, 0.48)
	root.add_child(_transfer_warning)

	_transfer_status = Label.new()
	_transfer_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_transfer_status.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_transfer_status.modulate = Color(0.70, 0.78, 0.86)
	root.add_child(_transfer_status)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_hide_character_transfer)
	actions.add_child(cancel_button)
	_transfer_execute_button = Button.new()
	_transfer_execute_button.text = "Copy Character"
	_transfer_execute_button.pressed.connect(_execute_character_transfer)
	actions.add_child(_transfer_execute_button)


func _open_character_transfer() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	_refresh_transfer_destinations()
	_transfer_operation.select(0)
	var active_character := CCFStorageService.get_character(
		_project_container, _active_character_id
	)
	_transfer_new_name.text = CCFProjectLifecycleService.first_name(
		CCFStorageService.character_display_name(active_character)
	)
	_transfer_status.text = ""
	_on_transfer_operation_changed(0)
	_on_transfer_destination_changed(_transfer_destination.selected)
	_transfer_window.popup_centered()


func _refresh_transfer_destinations() -> void:
	_transfer_destination.clear()
	_transfer_destination.add_item("New Character Project")
	_transfer_destination.set_item_metadata(0, "")
	var source_project_id := str(_project_container.get("project_id", ""))
	for raw_row in CCFStorageService.list_projects():
		if not raw_row is Dictionary:
			continue
		var row: Dictionary = raw_row
		var project_id := str(row.get("project_id", ""))
		if project_id.is_empty() or project_id == source_project_id:
			continue
		var project_name := str(row.get("name", "Character Project"))
		var character_count := int(row.get("character_count", 0))
		_transfer_destination.add_item(
			"%s — %d character%s" % [
				project_name,
				character_count,
				"" if character_count == 1 else "s"
			]
		)
		_transfer_destination.set_item_metadata(
			_transfer_destination.item_count - 1, project_id
		)
	_transfer_destination.select(0)


func _on_transfer_operation_changed(_index: int) -> void:
	if _transfer_operation == null or _transfer_operation.selected < 0:
		return
	var operation := str(_transfer_operation.get_selected_metadata())
	if operation == CHARACTER_TRANSFER_SERVICE.OPERATION_MOVE:
		_transfer_execute_button.text = "Move Character"
		_transfer_warning.text = "Move saves the destination first and removes the source only after that succeeds. If this is the source project's only character, CCF leaves a fresh empty draft there so project-level context and attachments are not destroyed."
	else:
		_transfer_execute_button.text = "Copy Character"
		_transfer_warning.text = "Copy creates an independent character identity. Character-local files are copied so later edits or image changes do not depend on the source project."


func _on_transfer_destination_changed(_index: int) -> void:
	if _transfer_destination == null or _transfer_destination.selected < 0:
		return
	var is_new := str(_transfer_destination.get_selected_metadata()).is_empty()
	_transfer_new_name_label.visible = is_new
	_transfer_new_name.visible = is_new


func _execute_character_transfer() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	var prepared := CCFProjectLifecycleService.prepare_for_save(
		_project_container, _active_character_id
	)
	if not bool(prepared.get("ok", false)):
		_transfer_status.text = str(prepared.get("error", "Save the character before transferring it."))
		return
	_active_character_id = str(prepared.get("active_character_id", _active_character_id))
	if _transfer_destination.selected < 0 or _transfer_operation.selected < 0:
		_transfer_status.text = "Choose an operation and destination."
		return
	var operation := str(_transfer_operation.get_selected_metadata())
	var destination_project_id := str(_transfer_destination.get_selected_metadata())
	_transfer_execute_button.disabled = true
	_transfer_status.text = "Transferring character and managed files…"
	var result := CHARACTER_TRANSFER_SERVICE.transfer_character(
		_project_container,
		_active_character_id,
		destination_project_id,
		operation,
		_transfer_new_name.text if destination_project_id.is_empty() else ""
	)
	_transfer_execute_button.disabled = false
	if not bool(result.get("ok", false)):
		_transfer_status.text = str(result.get("error", "Character transfer failed."))
		return

	var source_after: Dictionary = result.get("source_project", {})
	var target_project: Dictionary = result.get("target_project", {})
	var opened_target := _transfer_open_destination.button_pressed
	_hide_character_transfer()
	if opened_target and not target_project.is_empty():
		var target_template_id := CCFStorageService.active_character_template_id(target_project)
		load_project(
			target_project,
			CCFTemplateService.load_template(target_template_id),
			_settings
		)
		_status.text = (
			"Character moved and destination opened."
			if operation == CHARACTER_TRANSFER_SERVICE.OPERATION_MOVE
			else "Character copied and destination opened."
		)
	else:
		var source_template_id := CCFStorageService.active_character_template_id(source_after)
		load_project(
			source_after,
			CCFTemplateService.load_template(source_template_id),
			_settings
		)
		_status.text = (
			"Character moved to the selected destination."
			if operation == CHARACTER_TRANSFER_SERVICE.OPERATION_MOVE
			else "Character copied to the selected destination."
		)
	if bool(result.get("source_replaced_with_empty_draft", false)):
		_status.text += " The source project kept a fresh empty draft to preserve its project-level context."
	project_saved.emit(target_project.duplicate(true))


func _hide_character_transfer() -> void:
	if _transfer_window != null:
		_transfer_window.hide()
