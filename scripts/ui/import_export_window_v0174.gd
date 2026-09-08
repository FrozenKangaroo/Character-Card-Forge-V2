class_name CCFImportExportWindowV0174
extends CCFImportExportWindowV0173

const GROUP_SERVICE_V0174 = preload(
	"res://scripts/services/front_porch_group_card_service_v0174.gd"
)

var _group_workflow_selector_v0174: OptionButton
var _group_export_summary_v0174: RichTextLabel
var _group_import_summary_v0174: RichTextLabel
var _group_import_button_v0174: Button
var _group_save_dialog_v0174: FileDialog
var _group_import_dialog_v0174: FileDialog
var _pending_group_payload_v0174: Dictionary = {}
var _pending_group_source_v0174 := ""


func _build_ui() -> void:
	super._build_ui()
	var tabs := _primary_tabs_v0173()
	if tabs != null:
		_build_group_card_tab_v0174(tabs)


func _build_dialogs() -> void:
	super._build_dialogs()
	_group_save_dialog_v0174 = _new_file_dialog(
		FileDialog.FILE_MODE_SAVE_FILE, ["*.png ; Front Porch group-card PNG"]
	)
	_group_save_dialog_v0174.file_selected.connect(_export_group_to_path_v0174)
	_group_import_dialog_v0174 = _new_file_dialog(
		FileDialog.FILE_MODE_OPEN_FILE, ["*.png ; Front Porch group-card PNG"]
	)
	_group_import_dialog_v0174.file_selected.connect(_preview_group_import_v0174)


func _build_group_card_tab_v0174(tabs: TabContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "FrontPorchGroups"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Front Porch Groups")
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	scroll.add_child(page)
	var heading := Label.new()
	heading.text = "Front Porch Multi-Character Group Cards"
	heading.add_theme_font_size_override("font_size", 22)
	page.add_child(heading)
	var intro := Label.new()
	intro.text = (
		"Export a saved Group-card plan as a portable Front Porch PNG, or import one "
		+ "as a new multi-character CCF project. Each member's complete card and artwork "
		+ "travel inside the PNG. No Front Porch database is opened or modified."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)
	var export_panel := PanelContainer.new()
	page.add_child(export_panel)
	var export_box := VBoxContainer.new()
	export_box.add_theme_constant_override("separation", 8)
	export_panel.add_child(export_box)
	var export_heading := Label.new()
	export_heading.text = "Export"
	export_heading.add_theme_font_size_override("font_size", 18)
	export_box.add_child(export_heading)
	_group_workflow_selector_v0174 = OptionButton.new()
	_group_workflow_selector_v0174.item_selected.connect(
		func(_index: int): _refresh_group_export_preview_v0174()
	)
	export_box.add_child(_group_workflow_selector_v0174)
	_group_export_summary_v0174 = RichTextLabel.new()
	_group_export_summary_v0174.bbcode_enabled = true
	_group_export_summary_v0174.fit_content = true
	_group_export_summary_v0174.custom_minimum_size.y = 105
	export_box.add_child(_group_export_summary_v0174)
	var export_button := Button.new()
	export_button.text = "Export Front Porch Group PNG…"
	export_button.pressed.connect(_request_group_export_v0174)
	export_box.add_child(export_button)
	var import_panel := PanelContainer.new()
	page.add_child(import_panel)
	var import_box := VBoxContainer.new()
	import_box.add_theme_constant_override("separation", 8)
	import_panel.add_child(import_box)
	var import_heading := Label.new()
	import_heading.text = "Import"
	import_heading.add_theme_font_size_override("font_size", 18)
	import_box.add_child(import_heading)
	var choose_button := Button.new()
	choose_button.text = "Choose Front Porch Group PNG…"
	choose_button.pressed.connect(func(): _group_import_dialog_v0174.popup_centered_ratio(0.72))
	import_box.add_child(choose_button)
	_group_import_summary_v0174 = RichTextLabel.new()
	_group_import_summary_v0174.bbcode_enabled = true
	_group_import_summary_v0174.fit_content = true
	_group_import_summary_v0174.custom_minimum_size.y = 115
	_group_import_summary_v0174.text = "[color=#a8acbd]No group card selected.[/color]"
	import_box.add_child(_group_import_summary_v0174)
	_group_import_button_v0174 = Button.new()
	_group_import_button_v0174.text = "Import as New Multi-Character Project"
	_group_import_button_v0174.disabled = true
	_group_import_button_v0174.pressed.connect(_import_group_project_v0174)
	import_box.add_child(_group_import_button_v0174)
	var boundary := Label.new()
	boundary.text = (
		"Portable boundary: CCF reads and writes Front Porch's fpa_group PNG metadata. "
		+ "Direct group installation is intentionally unavailable until Front Porch exposes "
		+ "a verified group-import API."
	)
	boundary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boundary.modulate = Color(0.78, 0.66, 0.48)
	page.add_child(boundary)


func _refresh_all() -> void:
	super._refresh_all()
	if _group_workflow_selector_v0174 != null:
		_refresh_group_workflows_v0174()


func release_project() -> void:
	super.release_project()
	_pending_group_payload_v0174.clear()
	_pending_group_source_v0174 = ""


func _refresh_group_workflows_v0174() -> void:
	var previous_id := ""
	if _group_workflow_selector_v0174.selected >= 0:
		previous_id = str(_group_workflow_selector_v0174.get_item_metadata(
			_group_workflow_selector_v0174.selected
		))
	_group_workflow_selector_v0174.clear()
	_group_workflow_selector_v0174.add_item("Choose a saved Group-card plan")
	_group_workflow_selector_v0174.set_item_metadata(0, "")
	var selected_index := 0
	for raw_workflow in _project.get("card_workflows", []):
		if not raw_workflow is Dictionary or str(raw_workflow.get("mode", "")) != "group_card":
			continue
		var workflow_id := str(raw_workflow.get("workflow_id", ""))
		var workflow_title := str(raw_workflow.get("title", "Untitled group")).strip_edges()
		if workflow_title.is_empty():
			workflow_title = "Untitled group"
		_group_workflow_selector_v0174.add_item("%s (%d members)" % [
			workflow_title, raw_workflow.get("selected_character_ids", []).size()
		])
		var item_index := _group_workflow_selector_v0174.item_count - 1
		_group_workflow_selector_v0174.set_item_metadata(item_index, workflow_id)
		if workflow_id == previous_id:
			selected_index = item_index
	_group_workflow_selector_v0174.select(selected_index)
	_refresh_group_export_preview_v0174()


func _selected_group_workflow_v0174() -> Dictionary:
	if _group_workflow_selector_v0174 == null or _group_workflow_selector_v0174.selected < 0:
		return {}
	var workflow_id := str(_group_workflow_selector_v0174.get_item_metadata(
		_group_workflow_selector_v0174.selected
	))
	for raw_workflow in _project.get("card_workflows", []):
		if raw_workflow is Dictionary and str(raw_workflow.get("workflow_id", "")) == workflow_id:
			return raw_workflow.duplicate(true)
	return {}


func _refresh_group_export_preview_v0174() -> void:
	var workflow := _selected_group_workflow_v0174()
	if workflow.is_empty():
		_group_export_summary_v0174.text = (
			"[color=#a8acbd]Save a Group-card plan in Card Workflow Studio, then select it here.[/color]"
		)
		return
	var built := GROUP_SERVICE_V0174.build_group_payload(_project, workflow)
	if not bool(built.get("ok", false)):
		_group_export_summary_v0174.text = "[color=#ff9b9b]%s[/color]" % str(
			built.get("error", "Could not build group payload."))
		return
	var report: Dictionary = built.get("report", {})
	var errors: Array = report.get("errors", [])
	var warnings: Array = report.get("warnings", [])
	var lines: Array[String] = []
	if errors.is_empty():
		lines.append("[color=#8ed6a3]Ready for Front Porch group-card export.[/color]")
	else:
		lines.append("[color=#ff9b9b]%d validation error(s).[/color]" % errors.size())
	lines.append("Members: %d • Spec: %s %s" % [report.get("member_count", 0),
		GROUP_SERVICE_V0174.GROUP_SPEC, GROUP_SERVICE_V0174.GROUP_SPEC_VERSION])
	for message in errors:
		lines.append("• %s" % str(message))
	for message in warnings:
		lines.append("[color=#e6c57a]• %s[/color]" % str(message))
	_group_export_summary_v0174.text = "\n".join(lines)


func _request_group_export_v0174() -> void:
	project_refresh_requested.emit()
	var workflow := _selected_group_workflow_v0174()
	if workflow.is_empty():
		_status.text = "Choose a saved Group-card plan first."
		return
	var group_name := str(workflow.get("title", "Front Porch Group")).strip_edges()
	if group_name.is_empty():
		group_name = "Front Porch Group"
	_group_save_dialog_v0174.current_file = "%s.group.png" % group_name.validate_filename()
	_group_save_dialog_v0174.popup_centered_ratio(0.72)


func _export_group_to_path_v0174(path: String) -> void:
	var workflow := _selected_group_workflow_v0174()
	if workflow.is_empty():
		_status.text = "Choose a saved Group-card plan first."
		return
	var output_path := path if path.get_extension().to_lower() == "png" else path + ".png"
	var result := GROUP_SERVICE_V0174.write_group_card(output_path, _project, workflow)
	if bool(result.get("ok", false)):
		_status.text = "Exported portable Front Porch group card to %s" % output_path
	else:
		_status.text = str(result.get("error", "Front Porch group-card export failed."))
	_refresh_group_export_preview_v0174()


func _preview_group_import_v0174(path: String) -> void:
	var loaded := GROUP_SERVICE_V0174.load_group_card(path)
	if not bool(loaded.get("ok", false)):
		_pending_group_payload_v0174.clear()
		_pending_group_source_v0174 = ""
		_group_import_button_v0174.disabled = true
		var report: Dictionary = loaded.get("report", {})
		var messages: Array = report.get("errors", [])
		_group_import_summary_v0174.text = "[color=#ff9b9b]%s[/color]" % (
			"\n".join(PackedStringArray(messages)) if not messages.is_empty()
			else str(loaded.get("error", "Could not read this group card."))
		)
		return
	_pending_group_payload_v0174 = loaded.get("payload", {}).duplicate(true)
	_pending_group_source_v0174 = path
	_group_import_button_v0174.disabled = false
	var report: Dictionary = loaded.get("report", {})
	var lines: Array[String] = [
		"[font_size=20]%s[/font_size]" % str(_pending_group_payload_v0174.get("name", "Untitled Group")),
		"Front Porch group card %s • %d members" % [
			str(_pending_group_payload_v0174.get("spec_version", "?")),
			int(report.get("member_count", 0))
		]
	]
	for warning in report.get("warnings", []):
		lines.append("[color=#e6c57a]• %s[/color]" % str(warning))
	_group_import_summary_v0174.text = "\n".join(lines)
	_status.text = "Front Porch group card loaded for import preview."


func _import_group_project_v0174() -> void:
	if _pending_group_payload_v0174.is_empty():
		return
	var imported := GROUP_SERVICE_V0174.import_group_to_project(
		_pending_group_payload_v0174, _pending_group_source_v0174
	)
	if not bool(imported.get("ok", false)):
		_status.text = str(imported.get("error", "Could not import this Front Porch group card."))
		return
	var project: Dictionary = imported.get("project", {})
	_pending_group_payload_v0174.clear()
	_pending_group_source_v0174 = ""
	_group_import_button_v0174.disabled = true
	_group_import_summary_v0174.text = "[color=#8ed6a3]Group imported as a new CCF project.[/color]"
	_status.text = "Front Porch group card imported as a new multi-character CCF project."
	project_imported.emit(project)


func front_porch_group_capabilities_v0174() -> Dictionary:
	return {
		"spec": GROUP_SERVICE_V0174.GROUP_SPEC,
		"spec_version": GROUP_SERVICE_V0174.GROUP_SPEC_VERSION,
		"png_key": GROUP_SERVICE_V0174.GROUP_PNG_KEY,
		"portable_import": true,
		"portable_export": true,
		"direct_database_writes": false,
		"direct_group_install": false
	}
