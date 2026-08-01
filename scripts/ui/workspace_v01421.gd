class_name CCFWorkspaceV01421View
extends "res://scripts/ui/workspace_v01420.gd"

const CCFCHAR_SERVICE = preload("res://scripts/services/ccfchar_source_service_v01421.gd")
const IMPORT_CCFCHAR_MENU_ID := 14210

var _ccfchar_dialog: FileDialog
var _ccfchar_preview: Window
var _ccfchar_rows: VBoxContainer
var _ccfchar_source: Dictionary = {}
var _ccfchar_checks: Dictionary = {}
var _ccfchar_apply_button: Button


func _ready() -> void:
	super._ready()
	_build_ccfchar_import_ui()
	_add_ccfchar_menu_route()


func _build_ccfchar_import_ui() -> void:
	_ccfchar_dialog = FileDialog.new()
	_ccfchar_dialog.visible = false
	_ccfchar_dialog.force_native = true
	_ccfchar_dialog.transient = false
	_ccfchar_dialog.exclusive = false
	_ccfchar_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_ccfchar_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_ccfchar_dialog.filters = PackedStringArray(["*.ccfchar ; Character Card Forge character source"])
	_ccfchar_dialog.min_size = Vector2i(780, 540)
	_ccfchar_dialog.file_selected.connect(_on_ccfchar_file_selected)
	add_child(_ccfchar_dialog)
	_ccfchar_dialog.hide()

	_ccfchar_preview = Window.new()
	_ccfchar_preview.visible = false
	_ccfchar_preview.force_native = true
	_ccfchar_preview.transient = false
	_ccfchar_preview.exclusive = false
	_ccfchar_preview.title = "Import .ccfchar Source"
	_ccfchar_preview.size = Vector2i(820, 680)
	_ccfchar_preview.min_size = Vector2i(720, 520)
	_ccfchar_preview.close_requested.connect(_close_ccfchar_preview)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12
	root.offset_top = 12
	root.offset_right = -12
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 8)
	_ccfchar_preview.add_child(root)
	var intro := Label.new()
	intro.text = "Only supplied fields are shown. Uncheck anything you do not want to apply; omitted fields are never cleared."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	var top_actions := HBoxContainer.new()
	top_actions.add_theme_constant_override("separation", 8)
	root.add_child(top_actions)
	var import_another := Button.new()
	import_another.text = "Import Another .ccfchar…"
	import_another.tooltip_text = "Choose a different Character Card Forge source file without closing the workspace."
	import_another.pressed.connect(_on_ccfchar_import_another)
	top_actions.add_child(import_another)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_ccfchar_rows = VBoxContainer.new()
	_ccfchar_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ccfchar_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_ccfchar_rows)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_close_ccfchar_preview)
	actions.add_child(cancel_button)
	_ccfchar_apply_button = Button.new()
	_ccfchar_apply_button.text = "Apply Selected"
	_ccfchar_apply_button.pressed.connect(_apply_ccfchar_selected)
	actions.add_child(_ccfchar_apply_button)

	add_child(_ccfchar_preview)
	_ccfchar_preview.hide()


func _add_ccfchar_menu_route() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton:
			continue
		var menu := node as MenuButton
		if menu.text != "Character":
			continue
		var menu_popup := menu.get_popup()
		menu_popup.add_separator()
		menu_popup.add_item("Import .ccfchar Source…", IMPORT_CCFCHAR_MENU_ID)
		menu_popup.id_pressed.connect(_on_ccfchar_character_menu)
		return


func _on_ccfchar_character_menu(id: int) -> void:
	if id != IMPORT_CCFCHAR_MENU_ID:
		return
	if _project.is_empty():
		return
	_open_ccfchar_file_dialog()


func _open_ccfchar_file_dialog() -> void:
	if _ccfchar_dialog == null:
		return
	_ccfchar_dialog.popup_centered_ratio(0.72)


func _on_ccfchar_import_another() -> void:
	if _ccfchar_preview != null:
		_ccfchar_preview.hide()
	_open_ccfchar_file_dialog()


func _on_ccfchar_file_selected(path: String) -> void:
	var result := CCFCHAR_SERVICE.load_file(path)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not import .ccfchar source."))
		return
	_ccfchar_source = result.duplicate(true)
	_rebuild_ccfchar_preview()
	_ccfchar_preview.popup_centered(Vector2i(820, 680))


func _rebuild_ccfchar_preview() -> void:
	for child in _ccfchar_rows.get_children():
		child.queue_free()
	_ccfchar_checks.clear()
	for row in CCFCHAR_SERVICE.preview_rows(_ccfchar_source):
		var path := str(row.get("path", ""))
		var check := CheckBox.new()
		check.button_pressed = true
		check.text = "%s  —  %s" % [str(row.get("label", path)), str(row.get("summary", ""))]
		check.tooltip_text = path
		_ccfchar_rows.add_child(check)
		_ccfchar_checks[path] = check
	var unknown: Array = _ccfchar_source.get("unknown_top_level", [])
	if not unknown.is_empty():
		var note := Label.new()
		note.text = "Ignored unknown top-level keys: %s" % ", ".join(unknown)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ccfchar_rows.add_child(note)
	if _ccfchar_apply_button != null:
		_ccfchar_apply_button.disabled = _ccfchar_checks.is_empty()


func _close_ccfchar_preview() -> void:
	if _ccfchar_preview != null:
		_ccfchar_preview.hide()


func _apply_ccfchar_selected() -> void:
	if _project.is_empty() or _ccfchar_source.is_empty():
		return
	_capture_all_fields()
	var selected: Array[String] = []
	for raw_path in _ccfchar_checks.keys():
		var path := str(raw_path)
		var check: CheckBox = _ccfchar_checks[raw_path]
		if check.button_pressed:
			selected.append(path)
	if selected.is_empty():
		_status.text = "No .ccfchar fields were selected to import."
		return
	var result := CCFCHAR_SERVICE.apply_values(_project, _ccfchar_source, selected)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not apply .ccfchar source."))
		return
	var generation_value: Variant = _project.get("generation", {})
	var generation: Dictionary = generation_value if generation_value is Dictionary else {}
	var template_id := str(generation.get("template_id", "default")).strip_edges()
	if template_id.is_empty():
		template_id = "default"
	_template = CCFTemplateService.load_template(template_id)
	_dirty = true
	_rebuild_form()
	_populate_template_selector()
	_update_header()
	_commit_active_character_to_container()
	_populate_project_controls()
	_update_project_level_window_contexts()
	_close_ccfchar_preview()
	_status.text = "Imported %d field%s from .ccfchar. Review the workspace, then generate or save when ready. Use Character → Import .ccfchar Source… to import another file." % [
		int(result.get("count", 0)),
		"" if int(result.get("count", 0)) == 1 else "s"
	]
