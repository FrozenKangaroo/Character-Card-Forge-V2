class_name CCFImportExportWindowV0191
extends "res://scripts/ui/import_export_window_v0190.gd"

const ADAPTER_SERVICE = preload(
	"res://scripts/services/integration_adapter_service_v0191.gd"
)

var _export_profile_choice_v0191: OptionButton
var _export_profile_description_v0191: Label
var _export_profile_rules_v0191: Label
var _export_profile_report_v0191: TextEdit
var _export_document_preview_v0191: TextEdit
var _export_png_button_v0191: Button


func _build_export_tab(tabs: TabContainer) -> void:
	super._build_export_tab(tabs)
	var page := tabs.get_child(tabs.get_tab_count() - 1) as VBoxContainer
	if page == null:
		return
	var profile_panel := PanelContainer.new()
	profile_panel.name = "ExportProfilePanelV0191"
	var profile_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		profile_margin.add_theme_constant_override(side, 10)
	profile_panel.add_child(profile_margin)
	var profile_column := VBoxContainer.new()
	profile_column.add_theme_constant_override("separation", 6)
	profile_margin.add_child(profile_column)
	var profile_title := Label.new()
	profile_title.text = "Export Profile"
	profile_title.add_theme_font_size_override("font_size", 17)
	profile_column.add_child(profile_title)
	var profile_row := HFlowContainer.new()
	profile_column.add_child(profile_row)
	_export_profile_choice_v0191 = OptionButton.new()
	_export_profile_choice_v0191.custom_minimum_size.x = 420
	for profile in ADAPTER_SERVICE.profiles():
		_export_profile_choice_v0191.add_item(str(profile.get("name", "Export Profile")))
		_export_profile_choice_v0191.set_item_metadata(
			_export_profile_choice_v0191.item_count - 1,
			str(profile.get("id", ""))
		)
	profile_row.add_child(_export_profile_choice_v0191)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh Exact Preview"
	refresh_button.pressed.connect(_refresh_export_preview)
	profile_row.add_child(refresh_button)
	_export_profile_description_v0191 = Label.new()
	_export_profile_description_v0191.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_column.add_child(_export_profile_description_v0191)
	_export_profile_rules_v0191 = Label.new()
	_export_profile_rules_v0191.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_export_profile_rules_v0191.modulate = Color(0.68, 0.72, 0.82)
	profile_column.add_child(_export_profile_rules_v0191)
	page.add_child(profile_panel)
	page.move_child(profile_panel, 1)

	var preview_split := HSplitContainer.new()
	preview_split.name = "ExactExportPreviewV0191"
	preview_split.custom_minimum_size.y = 190
	page.add_child(preview_split)
	var report_column := VBoxContainer.new()
	report_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_split.add_child(report_column)
	var report_title := Label.new()
	report_title.text = "Preservation / Loss Report"
	report_column.add_child(report_title)
	_export_profile_report_v0191 = TextEdit.new()
	_export_profile_report_v0191.editable = false
	_export_profile_report_v0191.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_export_profile_report_v0191.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_column.add_child(_export_profile_report_v0191)
	var copy_report := Button.new()
	copy_report.text = "Copy Preservation Report"
	copy_report.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(_export_profile_report_v0191.text)
	)
	report_column.add_child(copy_report)
	var document_column := VBoxContainer.new()
	document_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_split.add_child(document_column)
	var document_title := Label.new()
	document_title.text = "Exact JSON Before Export"
	document_column.add_child(document_title)
	_export_document_preview_v0191 = TextEdit.new()
	_export_document_preview_v0191.editable = false
	_export_document_preview_v0191.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	_export_document_preview_v0191.size_flags_vertical = Control.SIZE_EXPAND_FILL
	document_column.add_child(_export_document_preview_v0191)
	var copy_document := Button.new()
	copy_document.text = "Copy Exact JSON"
	copy_document.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(_export_document_preview_v0191.text)
	)
	document_column.add_child(copy_document)
	page.move_child(preview_split, _mapping_tree.get_index() + 1)

	for node in page.find_children("*", "Button", true, false):
		if node is Button and node.text == "Export V2 JSON…":
			node.text = "Export Profile JSON…"
		elif node is Button and node.text == "Export V2 PNG Card…":
			_export_png_button_v0191 = node
			_export_png_button_v0191.text = "Export Profile PNG Card…"
	_export_profile_choice_v0191.item_selected.connect(
		_on_export_profile_selected_v0191
	)
	_select_profile_v0191(ADAPTER_SERVICE.DEFAULT_PROFILE_ID)
	_refresh_profile_details_v0191()


func _refresh_export_preview() -> void:
	if _export_profile_choice_v0191 == null:
		super._refresh_export_preview()
		return
	_refresh_profile_details_v0191()
	if _project.is_empty() or _active_character_id.is_empty():
		return
	var profile_id := _selected_export_profile_id_v0191()
	var preview := ADAPTER_SERVICE.preview_export(
		_project, _active_character_id, profile_id
	)
	if not bool(preview.get("ok", false)) and not preview.has("validation"):
		_validation_label.bbcode_enabled = true
		_validation_label.text = "[color=#ff9b9b]%s[/color]" % str(
			preview.get("error", "The export profile preview could not be built.")
		)
		_export_profile_report_v0191.text = "No preservation report is available."
		_export_document_preview_v0191.text = ""
		_mapping_tree.clear()
		return
	var validation_value: Variant = preview.get("validation", {})
	var validation: Dictionary = (
		validation_value if validation_value is Dictionary else {}
	)
	var errors: Array = validation.get("errors", [])
	var warnings: Array = validation.get("warnings", [])
	var lines: Array[String] = []
	if errors.is_empty():
		lines.append("[color=#8ed6a3]Ready for profile export.[/color]")
	else:
		lines.append("[color=#ff9b9b]%d export error(s).[/color]" % errors.size())
	if not warnings.is_empty():
		lines.append("[color=#e6c57a]%d warning(s) to review.[/color]" % warnings.size())
	for error_text in errors:
		lines.append("[color=#ff9b9b]• %s[/color]" % str(error_text))
	for warning_text in warnings:
		lines.append("[color=#e6c57a]• %s[/color]" % str(warning_text))
	_validation_label.bbcode_enabled = true
	_validation_label.text = "\n".join(lines)
	var report_value: Variant = preview.get("report", {})
	var report: Dictionary = report_value if report_value is Dictionary else {}
	_export_profile_report_v0191.text = ADAPTER_SERVICE.report_text(report)
	_export_document_preview_v0191.text = str(preview.get("json", ""))
	_mapping_tree.clear()
	_mapping_tree.set_column_title(0, "Source field")
	_mapping_tree.set_column_title(1, "Target adapter")
	_mapping_tree.set_column_title(2, "Disposition")
	_mapping_tree.set_column_title(3, "Reason")
	var root := _mapping_tree.create_item()
	for row_value in report.get("rows", []):
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		var item := _mapping_tree.create_item(root)
		item.set_text(0, str(row.get("path", "")))
		item.set_text(1, str(preview.get("adapter_id", "")))
		item.set_text(2, str(row.get("disposition", "")).capitalize())
		item.set_text(3, _truncate(str(row.get("detail", "")), 160))
		item.set_tooltip_text(3, str(row.get("detail", "")))


func _export_json_to_path(path: String) -> void:
	var output_path := path
	if output_path.get_extension().to_lower() != "json":
		output_path += ".json"
	var result := ADAPTER_SERVICE.export_json(
		_project,
		_active_character_id,
		_selected_export_profile_id_v0191(),
		output_path
	)
	if bool(result.get("ok", false)):
		_status.text = "Exported the selected profile to %s" % output_path
	else:
		_status.text = str(result.get("error", "Profile JSON export failed."))


func _export_png_to_path(path: String) -> void:
	if _pending_png_source.is_empty():
		_status.text = "Choose a source PNG image first."
		return
	var output_path := path
	if output_path.get_extension().to_lower() != "png":
		output_path += ".png"
	var result := ADAPTER_SERVICE.write_png(
		_pending_png_source,
		output_path,
		_project,
		_active_character_id,
		_selected_export_profile_id_v0191()
	)
	if bool(result.get("ok", false)):
		_status.text = "Exported the selected profile as a PNG card to %s" % output_path
	else:
		_status.text = str(result.get("error", "Profile PNG export failed."))


func _export_batch_to_directory(directory_path: String) -> void:
	var workflow := _selected_split_workflow()
	if workflow.is_empty():
		_status.text = "The selected split-card workflow no longer exists."
		return
	var character_ids: Array[String] = []
	for raw_id in workflow.get("selected_character_ids", []):
		character_ids.append(str(raw_id))
	var result := ADAPTER_SERVICE.export_characters_json(
		_project,
		character_ids,
		_selected_export_profile_id_v0191(),
		directory_path
	)
	if bool(result.get("ok", false)):
		var failures: Array = result.get("failures", [])
		var suffix := "."
		if not failures.is_empty():
			suffix = " with %d failure(s)." % failures.size()
		_status.text = "Batch exported %d profile JSON file(s) to %s%s" % [
			int(result.get("count", 0)), directory_path, suffix
		]
	else:
		_status.text = str(result.get("error", "Profile batch export failed."))


func _front_porch_install_payload_v0173(artwork_path: String) -> Dictionary:
	return ADAPTER_SERVICE.prepare_install_payload(
		_project,
		_active_character_id,
		ADAPTER_SERVICE.FRONT_PORCH_PROFILE_ID,
		artwork_path
	)


func _front_porch_export_document_v0185(
	project: Dictionary, character_id: String
) -> Dictionary:
	var preview := ADAPTER_SERVICE.preview_export(
		project, character_id, ADAPTER_SERVICE.FRONT_PORCH_PROFILE_ID
	)
	if not bool(preview.get("ok", false)):
		return {}
	return (
		(preview.get("document", {}) as Dictionary).duplicate(true)
		if preview.get("document", {}) is Dictionary
		else {}
	)


func _on_export_profile_selected_v0191(_index: int) -> void:
	_refresh_export_preview()


func _selected_export_profile_id_v0191() -> String:
	if (
		_export_profile_choice_v0191 == null
		or _export_profile_choice_v0191.selected < 0
	):
		return ADAPTER_SERVICE.DEFAULT_PROFILE_ID
	return str(_export_profile_choice_v0191.get_selected_metadata())


func _select_profile_v0191(profile_id: String) -> void:
	if _export_profile_choice_v0191 == null:
		return
	for index in range(_export_profile_choice_v0191.item_count):
		if str(_export_profile_choice_v0191.get_item_metadata(index)) == profile_id:
			_export_profile_choice_v0191.select(index)
			return


func _refresh_profile_details_v0191() -> void:
	if _export_profile_description_v0191 == null:
		return
	var profile := ADAPTER_SERVICE.profile_by_id(
		_selected_export_profile_id_v0191()
	)
	_export_profile_description_v0191.text = str(profile.get(
		"description", "The selected profile is unavailable."
	))
	_export_profile_rules_v0191.text = ADAPTER_SERVICE.profile_rules_text(profile)
	if _export_png_button_v0191 != null:
		_export_png_button_v0191.disabled = (
			"png" not in profile.get("output_extensions", [])
		)


func export_profile_capabilities_v0191() -> Dictionary:
	var result := ADAPTER_SERVICE.capabilities()
	result["profile_selector"] = _export_profile_choice_v0191 != null
	result["exact_json_preview"] = _export_document_preview_v0191 != null
	result["preservation_report"] = _export_profile_report_v0191 != null
	result["front_porch_install_uses_adapter"] = true
	result["front_porch_sync_uses_adapter"] = true
	return result
