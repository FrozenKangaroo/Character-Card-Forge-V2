class_name CCFImageGenerationWindowV0170
extends "res://scripts/ui/image_generation_window_v01610.gd"

signal collaborator_handoff_requested(source: Dictionary, options: Dictionary)

const HANDOFF_SERVICE_V0170 = preload(
	"res://scripts/services/image_collaborator_handoff_service_v0170.gd"
)

var _send_to_collaborator_button_v0170: Button
var _handoff_dialog_v0170: ConfirmationDialog
var _handoff_mode_v0170: OptionButton
var _handoff_vision_v0170: CheckButton
var _handoff_summary_v0170: Label
var _pending_handoff_entry_v0170: Dictionary = {}


func _ready() -> void:
	super._ready()
	ensure_collaborator_handoff_surface_v0170()


func _build_ui() -> void:
	super._build_ui()
	_install_collaborator_handoff_surface_v0170()


func collaborator_handoff_capabilities_v0170() -> Dictionary:
	return HANDOFF_SERVICE_V0170.capabilities()


func ensure_collaborator_handoff_surface_v0170() -> void:
	_install_collaborator_handoff_surface_v0170()
	_refresh_collaborator_handoff_v0170()


func collaborator_handoff_surface_ready_v0170() -> bool:
	return (
		_send_to_collaborator_button_v0170 != null
		and is_instance_valid(_send_to_collaborator_button_v0170)
		and _send_to_collaborator_button_v0170.is_inside_tree()
		and _handoff_dialog_v0170 != null
		and _handoff_mode_v0170 != null
		and _handoff_vision_v0170 != null
	)


func report_collaborator_handoff_v0170(result: Dictionary) -> void:
	if bool(result.get("ok", false)):
		_status.text = str(result.get(
			"message",
			"Character Collaborator opened with the selected image as structured Reference Context."
		))
		hide()
	else:
		_status.text = str(result.get(
			"error", "Could not send the selected image to Character Collaborator."
		))


func _install_collaborator_handoff_surface_v0170() -> void:
	if (
		_send_to_collaborator_button_v0170 != null
		and is_instance_valid(_send_to_collaborator_button_v0170)
	):
		return
	if _result_workflow_panel_v01610 == null:
		return
	var action_rows := _result_workflow_panel_v01610.find_children(
		"*", "HFlowContainer", false, false
	)
	if action_rows.is_empty():
		return
	var actions := action_rows[0] as HFlowContainer
	if actions == null:
		return

	_send_to_collaborator_button_v0170 = Button.new()
	_send_to_collaborator_button_v0170.name = "ImageStudioSendToCollaboratorV0170"
	_send_to_collaborator_button_v0170.text = "Send to Character Collaborator…"
	_send_to_collaborator_button_v0170.tooltip_text = (
		"Send the selected result as a structured, read-only image source with its generation provenance."
	)
	_send_to_collaborator_button_v0170.pressed.connect(
		_open_collaborator_handoff_v0170
	)
	actions.add_child(_send_to_collaborator_button_v0170)

	_handoff_dialog_v0170 = ConfirmationDialog.new()
	_handoff_dialog_v0170.name = "ImageStudioCollaboratorHandoffDialogV0170"
	_handoff_dialog_v0170.title = "Send Image to Character Collaborator"
	_handoff_dialog_v0170.ok_button_text = "Open Collaborator"
	_handoff_dialog_v0170.min_size = Vector2i(720, 340)
	_handoff_dialog_v0170.confirmed.connect(_confirm_collaborator_handoff_v0170)
	_handoff_dialog_v0170.canceled.connect(_cancel_collaborator_handoff_v0170)
	add_child(_handoff_dialog_v0170)

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(680, 0)
	root.add_theme_constant_override("separation", 10)
	_handoff_dialog_v0170.add_child(root)
	_handoff_summary_v0170 = Label.new()
	_handoff_summary_v0170.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_handoff_summary_v0170)

	var mode_label := Label.new()
	mode_label.text = "Collaborator workflow"
	root.add_child(mode_label)
	_handoff_mode_v0170 = OptionButton.new()
	_handoff_mode_v0170.add_item("Reference for the current character (recommended)")
	_handoff_mode_v0170.set_item_metadata(
		0, HANDOFF_SERVICE_V0170.MODE_EXISTING_TARGET
	)
	_handoff_mode_v0170.add_item("Start a new image-led Collaborator conversation")
	_handoff_mode_v0170.set_item_metadata(
		1, HANDOFF_SERVICE_V0170.MODE_NEW_COLLABORATOR
	)
	_handoff_mode_v0170.select(0)
	root.add_child(_handoff_mode_v0170)

	_handoff_vision_v0170 = CheckButton.new()
	_handoff_vision_v0170.text = "Analyse the image with the configured Vision profile"
	_handoff_vision_v0170.tooltip_text = (
		"Optional. Vision runs as a separate job and its description remains supplementary evidence; it never overwrites the image or generation record."
	)
	root.add_child(_handoff_vision_v0170)

	var note := Label.new()
	note.text = (
		"The raw image path, exact prompt, model, profile, seed and settings are preserved as read-only provenance. "
		+ "No character fields change until you explicitly use Collaborator's review/apply actions."
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate = Color(0.68, 0.74, 0.84)
	root.add_child(note)
	_handoff_dialog_v0170.hide()


func _refresh_result_workflow_v01610() -> void:
	super._refresh_result_workflow_v01610()
	_refresh_collaborator_handoff_v0170()


func _refresh_collaborator_handoff_v0170() -> void:
	if _send_to_collaborator_button_v0170 == null:
		return
	var entry := _selected_gallery_entry()
	_send_to_collaborator_button_v0170.disabled = (
		entry.is_empty()
		or not _selected_file_exists_v01610(entry)
		or (_image_service != null and _image_service.is_active())
	)


func _open_collaborator_handoff_v0170() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	if not _selected_file_exists_v01610(entry):
		_status.text = "Recover the missing image file before sending it to Character Collaborator."
		return
	_pending_handoff_entry_v0170 = entry.duplicate(true)
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var character_name := str(
		(character.get("character", {}) as Dictionary).get("name", "")
		if character.get("character", {}) is Dictionary
		else ""
	).strip_edges()
	if character_name.is_empty():
		var metadata_value: Variant = character.get("metadata", {})
		if metadata_value is Dictionary:
			character_name = str(
				(metadata_value as Dictionary).get("name", "")
			).strip_edges()
	if character_name.is_empty():
		character_name = "the selected character"
	_handoff_summary_v0170.text = (
		"Send %s's selected Image Studio result as structured Reference Context."
		% character_name
	)
	_handoff_mode_v0170.select(0)
	_handoff_vision_v0170.button_pressed = false
	_handoff_dialog_v0170.popup_centered(Vector2i(740, 380))


func _confirm_collaborator_handoff_v0170() -> void:
	var entry := _pending_handoff_entry_v0170.duplicate(true)
	_pending_handoff_entry_v0170.clear()
	if entry.is_empty():
		return
	var project_id := str(_project.get("project_id", ""))
	var image_path := CCFImageGenerationService.resolve_generated_image_path(
		project_id, str(entry.get("path", ""))
	)
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var source := HANDOFF_SERVICE_V0170.from_result(
		_project, character, entry, image_path
	)
	if source.is_empty():
		_status.text = "The selected result could not be prepared as Collaborator context."
		return
	var selected_mode := HANDOFF_SERVICE_V0170.MODE_EXISTING_TARGET
	if _handoff_mode_v0170.selected >= 0:
		selected_mode = str(_handoff_mode_v0170.get_selected_metadata())
	collaborator_handoff_requested.emit(source, {
		"mode": selected_mode,
		"analyse_with_vision": _handoff_vision_v0170.button_pressed
	})
	_status.text = "Opening Character Collaborator with structured image provenance…"


func _cancel_collaborator_handoff_v0170() -> void:
	_pending_handoff_entry_v0170.clear()
