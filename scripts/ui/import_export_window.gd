class_name CCFImportExportWindow
extends Window

signal project_refresh_requested
signal project_imported(project: Dictionary)

var _project: Dictionary = {}
var _settings: Dictionary = {}
var _project_id := ""
var _active_character_id := ""
var _status: Label
var _character_summary: Label
var _mapping_tree: Tree
var _validation_label: RichTextLabel
var _import_summary: RichTextLabel
var _import_button: Button
var _pending_import_card: Dictionary = {}
var _pending_import_source_path := ""
var _pending_import_source_format := ""
var _package_summary: RichTextLabel
var _package_import_button: Button
var _pending_package_path := ""
var _workflow_selector: OptionButton
var _batch_summary: Label
var _pending_png_source := ""

var _json_save_dialog: FileDialog
var _png_source_dialog: FileDialog
var _png_save_dialog: FileDialog
var _card_import_dialog: FileDialog
var _package_save_dialog: FileDialog
var _package_import_dialog: FileDialog
var _batch_directory_dialog: FileDialog


func _ready() -> void:
	visible = false
	title = "Import / Export Studio"
	size = Vector2i(1320, 880)
	min_size = Vector2i(940, 660)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(_hide_window)
	_build_ui()
	_build_dialogs()
	hide()


func open_for_project(project: Dictionary, settings: Dictionary, character_id: String) -> void:
	_project = project.duplicate(true)
	_settings = settings.duplicate(true)
	_project_id = str(project.get("project_id", ""))
	_active_character_id = character_id
	_refresh_all()
	_status.text = "Character Card V2, PNG metadata, portable project packages, and split-workflow batch export are available here."
	CCFToolWindowStateService.show_window(self, "import_export_studio", Vector2i(1320, 880))


func update_project_context(project: Dictionary, settings: Dictionary, character_id: String) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	_project = project.duplicate(true)
	_settings = settings.duplicate(true)
	_active_character_id = character_id
	_refresh_all()


func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and _project_id == project_id


func release_project() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "import_export_studio")
	hide()
	_project.clear()
	_project_id = ""
	_active_character_id = ""
	_pending_import_card.clear()
	_pending_import_source_path = ""
	_pending_import_source_format = ""
	_pending_package_path = ""


func save_window_state() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "import_export_studio")


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	_character_summary = Label.new()
	_character_summary.add_theme_font_size_override("font_size", 18)
	_character_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_character_summary)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	_build_export_tab(tabs)
	_build_import_tab(tabs)
	_build_package_tab(tabs)
	_build_batch_tab(tabs)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.7, 0.74, 0.84)
	root.add_child(_status)


func _build_export_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Export"
	page.add_theme_constant_override("separation", 10)
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Export Card")

	var intro := Label.new()
	intro.text = "Preview the exact mapping from the active CCF character into Character Card V2 before exporting."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)

	_validation_label = RichTextLabel.new()
	_validation_label.fit_content = true
	_validation_label.custom_minimum_size.y = 82
	page.add_child(_validation_label)

	_mapping_tree = Tree.new()
	_mapping_tree.columns = 4
	_mapping_tree.set_column_title(0, "CCF source")
	_mapping_tree.set_column_title(1, "Card target")
	_mapping_tree.set_column_title(2, "Status")
	_mapping_tree.set_column_title(3, "Current value")
	_mapping_tree.column_titles_visible = true
	_mapping_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mapping_tree.hide_root = true
	page.add_child(_mapping_tree)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	page.add_child(actions)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh Preview"
	refresh_button.pressed.connect(_request_refresh_export_preview)
	actions.add_child(refresh_button)
	var json_button := Button.new()
	json_button.text = "Export V2 JSON…"
	json_button.pressed.connect(_request_json_export)
	actions.add_child(json_button)
	var png_button := Button.new()
	png_button.text = "Export V2 PNG Card…"
	png_button.tooltip_text = "Choose an existing PNG image, then CCF writes the Character Card V2 metadata into a new PNG file."
	png_button.pressed.connect(_request_png_source)
	actions.add_child(png_button)


func _build_import_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Import"
	page.add_theme_constant_override("separation", 10)
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Import Card")

	var intro := Label.new()
	intro.text = "Import Character Card V2 JSON/PNG or legacy V1 JSON into a new clean CCF project. Imported unknown extension data and embedded lorebooks are preserved."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)

	var choose_button := Button.new()
	choose_button.text = "Choose Character Card…"
	choose_button.pressed.connect(func(): _card_import_dialog.popup_centered_ratio(0.72))
	page.add_child(choose_button)

	_import_summary = RichTextLabel.new()
	_import_summary.bbcode_enabled = true
	_import_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_import_summary.text = "[color=#a8acbd]No card selected.[/color]"
	page.add_child(_import_summary)

	_import_button = Button.new()
	_import_button.text = "Import as New CCF Project"
	_import_button.disabled = true
	_import_button.pressed.connect(_import_selected_card)
	page.add_child(_import_button)


func _build_package_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "PortableProject"
	page.add_theme_constant_override("separation", 10)
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Portable Project")

	var intro := Label.new()
	intro.text = "Portable .ccfproject files are renamed ZIP packages containing the complete project JSON plus project assets. They are independent from Character Card V2 export."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	page.add_child(actions)
	var export_button := Button.new()
	export_button.text = "Export Current Project…"
	export_button.pressed.connect(_request_project_package_export)
	actions.add_child(export_button)
	var choose_package_button := Button.new()
	choose_package_button.text = "Choose Project Package…"
	choose_package_button.pressed.connect(func(): _package_import_dialog.popup_centered_ratio(0.72))
	actions.add_child(choose_package_button)

	_package_summary = RichTextLabel.new()
	_package_summary.bbcode_enabled = true
	_package_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_package_summary.text = "[color=#a8acbd]No project package selected for import.[/color]"
	page.add_child(_package_summary)

	_package_import_button = Button.new()
	_package_import_button.text = "Import Portable Project"
	_package_import_button.disabled = true
	_package_import_button.pressed.connect(_import_selected_package)
	page.add_child(_package_import_button)


func _build_batch_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Batch"
	page.add_theme_constant_override("separation", 10)
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Batch Export")

	var intro := Label.new()
	intro.text = "Export all characters selected by a saved Split-card batch workflow as individual Character Card V2 JSON files."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)

	var workflow_label := Label.new()
	workflow_label.text = "Split-card workflow"
	page.add_child(workflow_label)
	_workflow_selector = OptionButton.new()
	_workflow_selector.item_selected.connect(_on_batch_workflow_selected)
	page.add_child(_workflow_selector)

	_batch_summary = Label.new()
	_batch_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_batch_summary.modulate = Color(0.68, 0.72, 0.82)
	page.add_child(_batch_summary)

	var export_button := Button.new()
	export_button.text = "Export Workflow Characters to Folder…"
	export_button.pressed.connect(_request_batch_directory)
	page.add_child(export_button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(spacer)


func _build_dialogs() -> void:
	_json_save_dialog = _new_file_dialog(FileDialog.FILE_MODE_SAVE_FILE, ["*.json ; Character Card JSON"])
	_json_save_dialog.file_selected.connect(_export_json_to_path)
	_png_source_dialog = _new_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, ["*.png ; PNG image"])
	_png_source_dialog.file_selected.connect(_on_png_source_selected)
	_png_save_dialog = _new_file_dialog(FileDialog.FILE_MODE_SAVE_FILE, ["*.png ; Character Card PNG"])
	_png_save_dialog.file_selected.connect(_export_png_to_path)
	_card_import_dialog = _new_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, ["*.json, *.png, *.apng ; Character card files"])
	_card_import_dialog.file_selected.connect(_on_card_import_selected)
	_package_save_dialog = _new_file_dialog(FileDialog.FILE_MODE_SAVE_FILE, ["*.ccfproject ; Character Card Forge project package"])
	_package_save_dialog.file_selected.connect(_export_project_package_to_path)
	_package_import_dialog = _new_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, ["*.ccfproject ; Character Card Forge project package"])
	_package_import_dialog.file_selected.connect(_on_package_import_selected)
	_batch_directory_dialog = _new_file_dialog(FileDialog.FILE_MODE_OPEN_DIR, [])
	_batch_directory_dialog.dir_selected.connect(_export_batch_to_directory)


func _new_file_dialog(file_mode: int, filters: Array[String]) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.visible = false
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = file_mode as FileDialog.FileMode
	dialog.filters = PackedStringArray(filters)
	dialog.min_size = Vector2i(760, 520)
	add_child(dialog)
	dialog.hide()
	return dialog


func _refresh_all() -> void:
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var project_metadata = _project.get("metadata", {})
	var project_name := "Untitled Project"
	if project_metadata is Dictionary:
		project_name = str(project_metadata.get("name", project_name))
	_character_summary.text = "%s • Active character: %s" % [
		project_name,
		CCFStorageService.character_display_name(character)
	]
	_refresh_export_preview()
	_refresh_batch_workflows()


func _request_refresh_export_preview() -> void:
	project_refresh_requested.emit()


func _refresh_export_preview() -> void:
	if _project.is_empty() or _active_character_id.is_empty():
		return
	var report := CCFCardFormatService.compatibility_report(_project, _active_character_id)
	var validation: Dictionary = report.get("validation", {})
	var errors: Array = validation.get("errors", [])
	var warnings: Array = validation.get("warnings", [])
	var notes: Array = validation.get("notes", [])
	var lines: Array[String] = []
	if errors.is_empty():
		lines.append("[color=#8ed6a3]Ready for Character Card V2 export.[/color]")
	else:
		lines.append("[color=#ff9b9b]%d export error(s).[/color]" % errors.size())
	if not warnings.is_empty():
		lines.append("[color=#e6c57a]%d compatibility warning(s).[/color]" % warnings.size())
	for note in notes:
		lines.append("• %s" % str(note))
	_validation_label.bbcode_enabled = true
	_validation_label.text = "\n".join(lines)
	_mapping_tree.clear()
	var root := _mapping_tree.create_item()
	for row_value in report.get("rows", []):
		if not row_value is Dictionary:
			continue
		var row: Dictionary = row_value
		var item := _mapping_tree.create_item(root)
		item.set_text(0, str(row.get("source", "")))
		item.set_text(1, str(row.get("target", "")))
		item.set_text(2, str(row.get("status", "")))
		item.set_text(3, str(row.get("value_summary", "")))
		item.set_tooltip_text(0, str(row.get("note", "")))


func _request_json_export() -> void:
	project_refresh_requested.emit()
	_json_save_dialog.current_file = CCFCardFormatService.suggested_filename(_project, _active_character_id, "json")
	_json_save_dialog.popup_centered_ratio(0.72)


func _export_json_to_path(path: String) -> void:
	var output_path := path
	if output_path.get_extension().to_lower() != "json":
		output_path += ".json"
	var result := CCFCardFormatService.export_json(_project, _active_character_id, output_path)
	if result.get("ok", false):
		_status.text = "Exported Character Card V2 JSON to %s" % output_path
	else:
		_status.text = str(result.get("error", "JSON export failed."))


func _request_png_source() -> void:
	project_refresh_requested.emit()
	_pending_png_source = ""
	_png_source_dialog.popup_centered_ratio(0.72)


func _on_png_source_selected(path: String) -> void:
	_pending_png_source = path
	_png_save_dialog.current_file = CCFCardFormatService.suggested_filename(_project, _active_character_id, "png")
	_png_save_dialog.popup_centered_ratio(0.72)


func _export_png_to_path(path: String) -> void:
	if _pending_png_source.is_empty():
		_status.text = "Choose a source PNG image first."
		return
	var output_path := path
	if output_path.get_extension().to_lower() != "png":
		output_path += ".png"
	var result := CCFCardFormatService.write_png_card(
		_pending_png_source, output_path, _project, _active_character_id
	)
	if result.get("ok", false):
		_status.text = "Exported Character Card V2 PNG to %s" % output_path
	else:
		_status.text = str(result.get("error", "PNG export failed."))


func _on_card_import_selected(path: String) -> void:
	var result := CCFCardFormatService.load_card_file(path)
	if not result.get("ok", false):
		_pending_import_card.clear()
		_import_button.disabled = true
		_import_summary.text = "[color=#ff9b9b]%s[/color]" % str(result.get("error", "Could not load character card."))
		return
	_pending_import_card = result.get("data", {}).duplicate(true)
	_pending_import_source_path = path
	_pending_import_source_format = str(result.get("source_format", "json"))
	var normalised := CCFCardFormatService.normalise_to_v2(_pending_import_card)
	var data: Dictionary = normalised.get("data", {})
	var report: Dictionary = result.get("report", {})
	var lines: Array[String] = []
	lines.append("[font_size=20]%s[/font_size]" % str(data.get("name", "Untitled Character")))
	lines.append("Detected: %s from %s" % [str(result.get("detected_format", "unknown")), _pending_import_source_format.to_upper()])
	lines.append("Description: %s" % _truncate(str(data.get("description", "")), 260))
	var warnings: Array = report.get("warnings", [])
	var notes: Array = report.get("notes", [])
	if not warnings.is_empty():
		lines.append("[color=#e6c57a]Warnings:[/color]")
		for warning in warnings:
			lines.append("• %s" % str(warning))
	if not notes.is_empty():
		lines.append("[color=#9ec8ff]Preservation notes:[/color]")
		for note in notes:
			lines.append("• %s" % str(note))
	_import_summary.text = "\n".join(lines)
	_import_button.disabled = false
	_status.text = "Card loaded for import preview."


func _import_selected_card() -> void:
	if _pending_import_card.is_empty():
		return
	var import_result := CCFCardFormatService.import_card_to_project(
		_pending_import_card, _pending_import_source_format
	)
	if not import_result.get("ok", false):
		_status.text = str(import_result.get("error", "Could not import character card."))
		return
	var project: Dictionary = import_result.get("project", {})
	var save_result := CCFStorageService.save_project(project)
	if not save_result.get("ok", false):
		_status.text = str(save_result.get("error", "Could not save imported project."))
		return
	if _pending_import_source_format == "png":
		_copy_imported_portrait(project, _pending_import_source_path)
		CCFStorageService.save_project(project)
	_pending_import_card.clear()
	_import_button.disabled = true
	_status.text = "Character card imported as a new CCF project."
	project_imported.emit(project)


func _copy_imported_portrait(project: Dictionary, source_path: String) -> void:
	var characters: Array = project.get("characters", [])
	if characters.is_empty() or not characters[0] is Dictionary:
		return
	var character: Dictionary = characters[0]
	var character_id := str(character.get("character_id", ""))
	var project_id := str(project.get("project_id", ""))
	if character_id.is_empty() or project_id.is_empty():
		return
	var relative_path := "characters/%s/assets/imported_card.png" % character_id
	var destination := ProjectSettings.globalize_path(CCFStorageService.project_folder(project_id).path_join(relative_path))
	DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return
	var buffer := source.get_buffer(source.get_length())
	source.close()
	var output := FileAccess.open(destination, FileAccess.WRITE)
	if output == null:
		return
	output.store_buffer(buffer)
	output.close()
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	assets["portrait"] = relative_path
	character["assets"] = assets
	characters[0] = character
	project["characters"] = characters


func _request_project_package_export() -> void:
	project_refresh_requested.emit()
	_package_save_dialog.current_file = CCFProjectPackageService.suggested_filename(_project)
	_package_save_dialog.popup_centered_ratio(0.72)


func _export_project_package_to_path(path: String) -> void:
	var output_path := path
	if output_path.get_extension().to_lower() != CCFProjectPackageService.PACKAGE_EXTENSION:
		output_path += ".%s" % CCFProjectPackageService.PACKAGE_EXTENSION
	var result := CCFProjectPackageService.export_project(_project, output_path)
	if result.get("ok", false):
		_status.text = "Exported portable CCF project to %s" % output_path
	else:
		_status.text = str(result.get("error", "Project package export failed."))


func _on_package_import_selected(path: String) -> void:
	var result := CCFProjectPackageService.inspect_package(path)
	if not result.get("ok", false):
		_pending_package_path = ""
		_package_import_button.disabled = true
		_package_summary.text = "[color=#ff9b9b]%s[/color]" % str(result.get("error", "Could not inspect project package."))
		return
	_pending_package_path = path
	_package_import_button.disabled = false
	var manifest: Dictionary = result.get("manifest", {})
	_package_summary.text = "[font_size=20]%s[/font_size]\nPackage format: %s\nProject format: %s\nCharacters: %s\nArchive entries: %s" % [
		str(manifest.get("project_name", "Untitled Project")),
		str(manifest.get("package_format_version", "?")),
		str(manifest.get("project_format_version", "?")),
		str(manifest.get("character_count", "?")),
		str(result.get("file_count", "?"))
	]
	_status.text = "Portable project package loaded for import preview."


func _import_selected_package() -> void:
	if _pending_package_path.is_empty():
		return
	var result := CCFProjectPackageService.import_project(_pending_package_path)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not import portable project."))
		return
	var project: Dictionary = result.get("project", {})
	_pending_package_path = ""
	_package_import_button.disabled = true
	_status.text = "Portable Character Card Forge project imported."
	project_imported.emit(project)


func _refresh_batch_workflows() -> void:
	_workflow_selector.clear()
	_workflow_selector.add_item("Choose a saved split-card workflow")
	_workflow_selector.set_item_metadata(0, "")
	for raw_workflow in _project.get("card_workflows", []):
		if not raw_workflow is Dictionary:
			continue
		var workflow: Dictionary = raw_workflow
		if str(workflow.get("mode", "")) != "split_batch":
			continue
		var workflow_title := str(workflow.get("title", "")).strip_edges()
		if workflow_title.is_empty():
			workflow_title = "Untitled split-card workflow"
		_workflow_selector.add_item("%s (%d characters)" % [workflow_title, workflow.get("selected_character_ids", []).size()])
		_workflow_selector.set_item_metadata(_workflow_selector.item_count - 1, str(workflow.get("workflow_id", "")))
	_on_batch_workflow_selected(_workflow_selector.selected)


func _on_batch_workflow_selected(_index: int) -> void:
	var workflow := _selected_split_workflow()
	if workflow.is_empty():
		_batch_summary.text = "Save a Split-card batch plan in Card Workflow Studio, then select it here."
		return
	var names: Array[String] = []
	for raw_id in workflow.get("selected_character_ids", []):
		var character := CCFStorageService.get_character(_project, str(raw_id))
		if not character.is_empty():
			names.append(CCFStorageService.character_display_name(character))
	_batch_summary.text = "%s\nWill export: %s" % [
		str(workflow.get("summary", "")).strip_edges(),
		", ".join(names)
	]


func _request_batch_directory() -> void:
	project_refresh_requested.emit()
	if _selected_split_workflow().is_empty():
		_status.text = "Choose a saved Split-card batch workflow first."
		return
	_batch_directory_dialog.popup_centered_ratio(0.72)


func _export_batch_to_directory(directory_path: String) -> void:
	var workflow := _selected_split_workflow()
	if workflow.is_empty():
		_status.text = "The selected split-card workflow no longer exists."
		return
	var character_ids: Array[String] = []
	for raw_id in workflow.get("selected_character_ids", []):
		character_ids.append(str(raw_id))
	var result := CCFCardFormatService.export_characters_json(_project, character_ids, directory_path)
	if result.get("ok", false):
		var failures: Array = result.get("failures", [])
		var suffix := "."
		if not failures.is_empty():
			suffix = " with %d failure(s)." % failures.size()
		_status.text = "Batch exported %d Character Card V2 JSON file(s) to %s%s" % [
			int(result.get("count", 0)),
			directory_path,
			suffix
		]
	else:
		_status.text = str(result.get("error", "Batch export failed."))


func _selected_split_workflow() -> Dictionary:
	if _workflow_selector.selected < 0:
		return {}
	var workflow_id := str(_workflow_selector.get_item_metadata(_workflow_selector.selected))
	if workflow_id.is_empty():
		return {}
	for raw_workflow in _project.get("card_workflows", []):
		if raw_workflow is Dictionary and str(raw_workflow.get("workflow_id", "")) == workflow_id:
			return raw_workflow.duplicate(true)
	return {}


func _hide_window() -> void:
	CCFToolWindowStateService.save_window(self, "import_export_studio")
	hide()


func _truncate(text: String, limit: int) -> String:
	var clean := text.strip_edges().replace("\n", " ")
	if clean.length() > limit:
		return clean.substr(0, limit - 1) + "…"
	return clean
