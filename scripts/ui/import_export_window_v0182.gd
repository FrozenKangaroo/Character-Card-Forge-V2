class_name CCFImportExportWindowV0182
extends CCFImportExportWindowV0180

signal inspection_project_changed_v0182(
	project: Dictionary, active_character_id: String, message: String
)

const INSPECTION_SERVICE = preload(
	"res://scripts/services/card_inspection_service_v0182.gd"
)

var _import_inspection_v0182: Dictionary = {}
var _import_portrait_v0182: TextureRect
var _copy_button_v0182: Button
var _merge_button_v0182: Button
var _replace_button_v0182: Button
var _cancel_import_button_v0182: Button
var _import_action_confirm_v0182: ConfirmationDialog
var _pending_import_action_v0182 := ""


func _build_import_tab(tabs: TabContainer) -> void:
	super._build_import_tab(tabs)
	var page := tabs.get_child(tabs.get_tab_count() - 1) as VBoxContainer
	if page == null:
		return
	_import_portrait_v0182 = TextureRect.new()
	_import_portrait_v0182.custom_minimum_size = Vector2(180, 180)
	_import_portrait_v0182.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_import_portrait_v0182.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_import_portrait_v0182.visible = false
	page.add_child(_import_portrait_v0182)
	page.move_child(_import_portrait_v0182, 2)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	page.add_child(actions)
	_copy_button_v0182 = _import_action_button_v0182(
		"Import as Copy in Current Project", "copy"
	)
	actions.add_child(_copy_button_v0182)
	_merge_button_v0182 = _import_action_button_v0182(
		"Merge into Active Character…", "merge"
	)
	actions.add_child(_merge_button_v0182)
	_replace_button_v0182 = _import_action_button_v0182(
		"Replace Active Character…", "replace"
	)
	actions.add_child(_replace_button_v0182)
	_cancel_import_button_v0182 = Button.new()
	_cancel_import_button_v0182.text = "Cancel Preview"
	_cancel_import_button_v0182.disabled = true
	_cancel_import_button_v0182.pressed.connect(_cancel_import_preview_v0182)
	actions.add_child(_cancel_import_button_v0182)
	_set_current_import_actions_enabled_v0182(false)


func _build_dialogs() -> void:
	super._build_dialogs()
	_import_action_confirm_v0182 = ConfirmationDialog.new()
	_import_action_confirm_v0182.confirmed.connect(
		_apply_current_import_action_v0182
	)
	add_child(_import_action_confirm_v0182)


func _on_card_import_selected(path: String) -> void:
	super._on_card_import_selected(path)
	if _pending_import_card.is_empty():
		_import_inspection_v0182.clear()
		_set_current_import_actions_enabled_v0182(false)
		return
	_import_inspection_v0182 = INSPECTION_SERVICE.import_inspection(path)
	if not bool(_import_inspection_v0182.get("ok", false)):
		_set_current_import_actions_enabled_v0182(false)
		_import_summary.text += "\n[color=#ff9b9b]Inspector: %s[/color]" % str(
			_import_inspection_v0182.get("error", "Could not inspect import.")
		)
		return
	_set_current_import_actions_enabled_v0182(true)
	_refresh_import_inspection_v0182()


func _refresh_import_inspection_v0182() -> void:
	var imported_project: Dictionary = _import_inspection_v0182.get(
		"imported_project", {}
	)
	var imported_id := str(_import_inspection_v0182.get(
		"imported_character_id", ""
	))
	var imported_character := CCFStorageService.get_character(
		imported_project, imported_id
	)
	var lines: Array[String] = []
	lines.append("[font_size=20]%s[/font_size]" % CCFStorageService.character_display_name(imported_character))
	lines.append("Detected: %s %s from %s" % [
		str(_import_inspection_v0182.get("detected_format", "unknown")),
		str(_import_inspection_v0182.get("detected_version", "")),
		str(_import_inspection_v0182.get("source_format", "file")).to_upper()
	])
	var token_report: Dictionary = _import_inspection_v0182.get("token_report", {})
	lines.append("Estimated authored size: %d tokens across %d characters" % [
		int(token_report.get("total_tokens", 0)),
		int(token_report.get("total_characters", 0))
	])
	var validation: Dictionary = _import_inspection_v0182.get("validation", {})
	for error_text in validation.get("errors", []):
		lines.append("[color=#ff9b9b]Validation: %s[/color]" % str(error_text))
	for warning_text in validation.get("warnings", []):
		lines.append("[color=#e6c57a]Validation: %s[/color]" % str(warning_text))
	for note_text in validation.get("notes", []):
		lines.append("[color=#9ec8ff]Preservation: %s[/color]" % str(note_text))
	lines.append("[font_size=17]Migration / loss map[/font_size]")
	for row in _import_inspection_v0182.get("loss_mapping", []):
		lines.append("• %s — [b]%s[/b]: %s" % [
			str(row.get("field", "Field")),
			str(row.get("disposition", "review")).capitalize(),
			str(row.get("detail", ""))
		])
	var duplicate_evidence: Array = _import_inspection_v0182.get(
		"duplicate_evidence", []
	)
	if duplicate_evidence.is_empty():
		lines.append("[color=#8ed6a1]Duplicate evidence: no exact-content or same-name match found.[/color]")
	else:
		lines.append("[color=#e6c57a]Possible duplicates:[/color]")
		for evidence in duplicate_evidence:
			lines.append("• %s — %s" % [
				str(evidence.get("name", "Character")),
				str(evidence.get("summary", "Possible match"))
			])
	lines.append("Choose New Project, Copy, Merge, Replace, or Cancel only after reviewing this preview.")
	_import_summary.text = "\n".join(lines)
	var portrait_path := str(_import_inspection_v0182.get("portrait_path", ""))
	_import_portrait_v0182.visible = false
	_import_portrait_v0182.texture = null
	if not portrait_path.is_empty():
		var image := Image.load_from_file(portrait_path)
		if image != null and not image.is_empty():
			_import_portrait_v0182.texture = ImageTexture.create_from_image(image)
			_import_portrait_v0182.visible = true
	_status.text = "Import inspection complete. Review format, size, validation, duplicates and migration mapping."


func _import_action_button_v0182(
	button_text: String, action: String
) -> Button:
	var button := Button.new()
	button.text = button_text
	button.pressed.connect(func() -> void: _request_import_action_v0182(action))
	return button


func _request_import_action_v0182(action: String) -> void:
	if _import_inspection_v0182.is_empty():
		return
	_pending_import_action_v0182 = action
	if action == "copy":
		_apply_current_import_action_v0182()
		return
	_import_action_confirm_v0182.title = "%s inspected card" % action.capitalize()
	_import_action_confirm_v0182.dialog_text = (
		"%s the inspected card %s the active character? A revision recovery "
		+ "checkpoint will be created first."
	) % [action.capitalize(), "into" if action == "merge" else "over"]
	_import_action_confirm_v0182.popup_centered()


func _apply_current_import_action_v0182() -> void:
	var action := _pending_import_action_v0182
	_pending_import_action_v0182 = ""
	var result := INSPECTION_SERVICE.apply_import_to_current_project(
		_project,
		_active_character_id,
		_import_inspection_v0182,
		action
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not apply inspected import."))
		return
	_project = result.get("project", {}).duplicate(true)
	_active_character_id = str(result.get("active_character_id", _active_character_id))
	var message_text := (
		"Inspected card imported as a copy in the current project."
		if action == "copy"
		else "Inspected card %s the active character with a recovery checkpoint."
		% ("merged into" if action == "merge" else "replaced")
	)
	inspection_project_changed_v0182.emit(
		_project.duplicate(true), _active_character_id, message_text
	)
	_cancel_import_preview_v0182()


func _cancel_import_preview_v0182() -> void:
	_import_inspection_v0182.clear()
	_pending_import_card.clear()
	_pending_import_source_path = ""
	_pending_import_source_format = ""
	_import_button.disabled = true
	_import_portrait_v0182.texture = null
	_import_portrait_v0182.visible = false
	_import_summary.text = "[color=#a8acbd]No card selected.[/color]"
	_set_current_import_actions_enabled_v0182(false)
	_status.text = "Import preview cancelled. No project data changed."


func _set_current_import_actions_enabled_v0182(enabled: bool) -> void:
	for button in [
		_copy_button_v0182,
		_merge_button_v0182,
		_replace_button_v0182,
		_cancel_import_button_v0182
	]:
		if button != null:
			button.disabled = not enabled
