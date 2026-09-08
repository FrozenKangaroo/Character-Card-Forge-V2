class_name CCFImageGenerationWindowV0175
extends CCFImageGenerationWindowV0170

const FRONT_PORCH_GALLERY_SERVICE_V0175 = preload(
	"res://scripts/services/front_porch_avatar_gallery_service_v0175.gd"
)

var _add_front_porch_look_button_v0175: Button
var _add_front_porch_expression_button_v0175: Button
var _expression_dialog_v0175: ConfirmationDialog
var _expression_selector_v0175: OptionButton


func _ready() -> void:
	super._ready()
	ensure_front_porch_gallery_surface_v0175()


func _build_ui() -> void:
	super._build_ui()
	_install_front_porch_gallery_surface_v0175()


func ensure_front_porch_gallery_surface_v0175() -> void:
	_install_front_porch_gallery_surface_v0175()
	_refresh_front_porch_gallery_actions_v0175()


func front_porch_gallery_capabilities_v0175() -> Dictionary:
	return FRONT_PORCH_GALLERY_SERVICE_V0175.capabilities()


func _install_front_porch_gallery_surface_v0175() -> void:
	if (
		_add_front_porch_look_button_v0175 != null
		and is_instance_valid(_add_front_porch_look_button_v0175)
	):
		return
	if _set_portrait_button == null or not is_instance_valid(_set_portrait_button):
		return
	var gallery_actions := _set_portrait_button.get_parent()
	if gallery_actions == null:
		return
	_add_front_porch_look_button_v0175 = Button.new()
	_add_front_porch_look_button_v0175.text = "Add as Front Porch Look"
	_add_front_porch_look_button_v0175.tooltip_text = (
		"Link this generated result as an alternate Front Porch look. The image "
		+ "keeps its Image Studio provenance and is not made the portrait."
	)
	_add_front_porch_look_button_v0175.pressed.connect(
		_add_selected_as_front_porch_look_v0175
	)
	gallery_actions.add_child(_add_front_porch_look_button_v0175)
	_add_front_porch_expression_button_v0175 = Button.new()
	_add_front_porch_expression_button_v0175.text = "Add as Expression…"
	_add_front_porch_expression_button_v0175.tooltip_text = (
		"Assign one of Front Porch's supported emotion labels to this generated result."
	)
	_add_front_porch_expression_button_v0175.pressed.connect(
		_open_expression_dialog_v0175
	)
	gallery_actions.add_child(_add_front_porch_expression_button_v0175)
	_expression_dialog_v0175 = ConfirmationDialog.new()
	_expression_dialog_v0175.title = "Add Front Porch Expression"
	_expression_dialog_v0175.ok_button_text = "Add Expression"
	_expression_dialog_v0175.min_size = Vector2i(520, 240)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_expression_dialog_v0175.add_child(content)
	var explanation := Label.new()
	explanation.text = (
		"Choose the emotion this image represents. This creates a gallery association; "
		+ "it does not change the character portrait or contact Front Porch."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(explanation)
	_expression_selector_v0175 = OptionButton.new()
	for label_value in FRONT_PORCH_GALLERY_SERVICE_V0175.EMOTION_LABELS:
		_expression_selector_v0175.add_item(str(label_value).capitalize())
		_expression_selector_v0175.set_item_metadata(
			_expression_selector_v0175.item_count - 1, label_value
		)
	content.add_child(_expression_selector_v0175)
	_expression_dialog_v0175.confirmed.connect(
		_add_selected_as_front_porch_expression_v0175
	)
	add_child(_expression_dialog_v0175)
	_expression_dialog_v0175.hide()


func _refresh_gallery_action_state() -> void:
	super._refresh_gallery_action_state()
	_refresh_front_porch_gallery_actions_v0175()


func _refresh_front_porch_gallery_actions_v0175() -> void:
	var available := (
		_selected_image_index >= 0
		and _selected_image_index < _gallery.item_count
		and not _selected_gallery_entry().is_empty()
	)
	if _add_front_porch_look_button_v0175 != null:
		_add_front_porch_look_button_v0175.disabled = not available
	if _add_front_porch_expression_button_v0175 != null:
		_add_front_porch_expression_button_v0175.disabled = not available


func _add_selected_as_front_porch_look_v0175() -> void:
	_add_selected_to_front_porch_gallery_v0175("look", "")


func _open_expression_dialog_v0175() -> void:
	if _selected_gallery_entry().is_empty():
		return
	_expression_dialog_v0175.popup_centered(Vector2i(560, 250))


func _add_selected_as_front_porch_expression_v0175() -> void:
	if _expression_selector_v0175.selected < 0:
		return
	_add_selected_to_front_porch_gallery_v0175(
		"expression", str(_expression_selector_v0175.get_selected_metadata())
	)


func _add_selected_to_front_porch_gallery_v0175(
	entry_kind: String, expression_label: String
) -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	var result := FRONT_PORCH_GALLERY_SERVICE_V0175.add_source(
		_project,
		_active_character_id,
		{
			"kind": "image_studio",
			"path": str(entry.get("path", "")),
			"source_record": entry
		},
		entry_kind,
		expression_label
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not add the gallery role."))
		return
	_project = (result.get("project", {}) as Dictionary).duplicate(true)
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not save the avatar gallery."))
		return
	project_changed.emit(_project.duplicate(true))
	if entry_kind == "look":
		_status.text = "Added this generated image as a Front Porch look. The portrait is unchanged."
	else:
		_status.text = "Added this generated image as the %s expression. The portrait is unchanged." % expression_label
