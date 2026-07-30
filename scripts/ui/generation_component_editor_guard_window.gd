class_name CCFGenerationComponentEditorGuardWindow
extends CCFGenerationComponentEditorWindow

var _applied_groups: Array = []
var _close_confirmation: ConfirmationDialog


func _ready() -> void:
	super._ready()
	_rewire_close_actions()
	_build_close_confirmation()


func open_for_template(template: Dictionary, read_only: bool) -> void:
	super.open_for_template(template, read_only)
	_applied_groups = _groups.duplicate(true)
	_status.text += " Multiple enabled groups may target the same Character Card field; they are combined in group order, using their titles as section headings."


func _apply() -> void:
	super._apply()
	if not _read_only:
		_applied_groups = _groups.duplicate(true)


func _rewire_close_actions() -> void:
	if close_requested.is_connected(hide):
		close_requested.disconnect(hide)
	if not close_requested.is_connected(_request_close):
		close_requested.connect(_request_close)

	for node in find_children("*", "Button", true, false):
		if not node is Button:
			continue
		var button: Button = node
		if button.text != "Close":
			continue
		if button.pressed.is_connected(hide):
			button.pressed.disconnect(hide)
		if not button.pressed.is_connected(_request_close):
			button.pressed.connect(_request_close)
		break


func _build_close_confirmation() -> void:
	_close_confirmation = ConfirmationDialog.new()
	_close_confirmation.title = "Unapplied Generation Component Changes"
	_close_confirmation.dialog_text = (
		"You have generation component changes that have not been applied to the template editor.\n\n"
		+ "Apply them before closing, discard them, or keep editing."
	)
	_close_confirmation.ok_button_text = "Apply to Template"
	_close_confirmation.cancel_button_text = "Keep Editing"
	_close_confirmation.confirmed.connect(_apply_and_close)
	_close_confirmation.custom_action.connect(_on_close_confirmation_action)
	_close_confirmation.add_button("Discard Changes", false, "discard")
	add_child(_close_confirmation)


func _request_close() -> void:
	if _read_only or not _has_unapplied_changes():
		hide()
		return
	_close_confirmation.popup_centered(Vector2i(620, 220))


func _apply_and_close() -> void:
	_apply()
	hide()


func _on_close_confirmation_action(action: StringName) -> void:
	if action != &"discard":
		return
	_groups = _applied_groups.duplicate(true)
	_close_confirmation.hide()
	hide()


func _has_unapplied_changes() -> bool:
	return JSON.stringify(_groups) != JSON.stringify(_applied_groups)
