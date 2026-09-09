class_name CCFImportExportWindowV0180
extends CCFImportExportWindowV0175

signal world_project_changed_v0180(project: Dictionary)

const WORLD_SERVICE_V0180 = preload(
	"res://scripts/services/front_porch_world_service_v0180.gd"
)

var _world_selector_v0180: OptionButton
var _world_name_v0180: LineEdit
var _world_description_v0180: TextEdit
var _world_cover_v0180: TextureRect
var _world_cover_status_v0180: Label
var _world_climate_v0180: CheckBox
var _world_biome_v0180: OptionButton
var _world_atmosphere_v0180: OptionButton
var _world_gravity_v0180: OptionButton
var _world_lore_list_v0180: ItemList
var _world_lore_name_v0180: LineEdit
var _world_lore_keys_v0180: LineEdit
var _world_lore_content_v0180: TextEdit
var _world_lore_enabled_v0180: CheckBox
var _world_lore_constant_v0180: CheckBox
var _world_summary_v0180: TextEdit
var _world_creator_v0180: LineEdit
var _world_original_creator_v0180: LineEdit
var _world_tags_v0180: LineEdit
var _world_adult_v0180: CheckBox
var _world_comments_v0180: CheckBox
var _world_stable_id_v0180: LineEdit
var _world_readiness_v0180: RichTextLabel
var _world_import_dialog_v0180: FileDialog
var _world_export_dialog_v0180: FileDialog
var _world_cover_dialog_v0180: FileDialog
var _world_review_dialog_v0180: ConfirmationDialog
var _world_private_review_v0180: CheckBox
var _world_adult_review_v0180: CheckBox
var _world_record_v0180: Dictionary = {}
var _world_entries_v0180: Array = []
var _world_cover_data_v0180 := ""
var _world_refreshing_v0180 := false


func _build_ui() -> void:
	super._build_ui()
	var tabs := _primary_tabs_v0173()
	if tabs != null:
		_build_world_tab_v0180(tabs)


func _build_dialogs() -> void:
	super._build_dialogs()
	_world_import_dialog_v0180 = _new_file_dialog(
		FileDialog.FILE_MODE_OPEN_FILE, ["*.fpworld ; Front Porch World"]
	)
	_world_import_dialog_v0180.file_selected.connect(_import_world_v0180)
	_world_export_dialog_v0180 = _new_file_dialog(
		FileDialog.FILE_MODE_SAVE_FILE, ["*.fpworld ; Front Porch World"]
	)
	_world_export_dialog_v0180.file_selected.connect(_export_world_v0180)
	_world_cover_dialog_v0180 = _new_file_dialog(
		FileDialog.FILE_MODE_OPEN_FILE,
		["*.png, *.jpg, *.jpeg, *.webp ; Cover images"]
	)
	_world_cover_dialog_v0180.file_selected.connect(_choose_world_cover_v0180)
	_build_world_review_dialog_v0180()


func _refresh_all() -> void:
	super._refresh_all()
	if _world_selector_v0180 != null:
		_refresh_world_selector_v0180()


func release_project() -> void:
	super.release_project()
	_world_record_v0180.clear()
	_world_entries_v0180.clear()


func front_porch_world_capabilities_v0180() -> Dictionary:
	return WORLD_SERVICE_V0180.capabilities()


func _build_world_tab_v0180(tabs: TabContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "FrontPorchWorlds"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Front Porch Worlds")
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	scroll.add_child(page)
	var heading := Label.new()
	heading.text = "Front Porch World Studio"
	heading.add_theme_font_size_override("font_size", 22)
	page.add_child(heading)
	var intro := Label.new()
	intro.text = (
		"Create or import portable .fpworld files while preserving fields from newer "
		+ "Front Porch versions. Prepare optional Stoop metadata here; this version "
		+ "does not upload, publish, or write to a Front Porch database."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)
	var toolbar := HBoxContainer.new()
	page.add_child(toolbar)
	_world_selector_v0180 = OptionButton.new()
	_world_selector_v0180.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_world_selector_v0180.item_selected.connect(_select_world_v0180)
	toolbar.add_child(_world_selector_v0180)
	var new_button := Button.new()
	new_button.text = "New"
	new_button.pressed.connect(_new_world_v0180)
	toolbar.add_child(new_button)
	var import_button := Button.new()
	import_button.text = "Import .fpworld…"
	import_button.pressed.connect(func(): _world_import_dialog_v0180.popup_centered_ratio(0.72))
	toolbar.add_child(import_button)
	var delete_button := Button.new()
	delete_button.text = "Remove"
	delete_button.pressed.connect(_remove_world_v0180)
	toolbar.add_child(delete_button)

	var identity := _panel_box_v0180(page, "World Identity and Cover")
	_world_name_v0180 = _line_field_v0180(identity, "Name")
	_world_description_v0180 = _text_field_v0180(identity, "Description", 110)
	_world_name_v0180.text_changed.connect(func(_value: String): _refresh_world_readiness_v0180())
	var cover_row := HBoxContainer.new()
	identity.add_child(cover_row)
	_world_cover_v0180 = TextureRect.new()
	_world_cover_v0180.custom_minimum_size = Vector2(150, 150)
	_world_cover_v0180.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_world_cover_v0180.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cover_row.add_child(_world_cover_v0180)
	var cover_actions := VBoxContainer.new()
	cover_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cover_row.add_child(cover_actions)
	_world_cover_status_v0180 = Label.new()
	_world_cover_status_v0180.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cover_actions.add_child(_world_cover_status_v0180)
	var choose_cover := Button.new()
	choose_cover.text = "Choose Cover Image…"
	choose_cover.pressed.connect(func(): _world_cover_dialog_v0180.popup_centered_ratio(0.72))
	cover_actions.add_child(choose_cover)
	var remove_cover := Button.new()
	remove_cover.text = "Remove Cover"
	remove_cover.pressed.connect(_remove_world_cover_v0180)
	cover_actions.add_child(remove_cover)

	var climate := _panel_box_v0180(page, "Optional Climate")
	_world_climate_v0180 = CheckBox.new()
	_world_climate_v0180.text = "Enable Front Porch climate simulation"
	_world_climate_v0180.toggled.connect(_toggle_world_climate_v0180)
	climate.add_child(_world_climate_v0180)
	_world_biome_v0180 = _option_field_v0180(climate, "Biome")
	_world_biome_v0180.add_item("Preserve imported/custom biome")
	_world_biome_v0180.set_item_metadata(0, "")
	for raw_biome in WORLD_SERVICE_V0180.catalog().get("biomes", []):
		if raw_biome is Dictionary:
			_world_biome_v0180.add_item(str(raw_biome.get("name", raw_biome.get("id", "Biome"))))
			_world_biome_v0180.set_item_metadata(_world_biome_v0180.item_count - 1, str(raw_biome.get("id", "")))
	_world_atmosphere_v0180 = _option_field_v0180(climate, "Atmosphere")
	_world_gravity_v0180 = _option_field_v0180(climate, "Gravity")
	var traits: Dictionary = WORLD_SERVICE_V0180.catalog().get("place_traits", {})
	for value in traits.get("atmosphere", []):
		_world_atmosphere_v0180.add_item(str(value).capitalize())
		_world_atmosphere_v0180.set_item_metadata(_world_atmosphere_v0180.item_count - 1, str(value))
	for value in traits.get("gravity", []):
		_world_gravity_v0180.add_item(str(value).capitalize())
		_world_gravity_v0180.set_item_metadata(_world_gravity_v0180.item_count - 1, str(value))

	var lore := _panel_box_v0180(page, "World Lore")
	var lore_intro := Label.new()
	lore_intro.text = "Edit the primary lorebook. Additional imported lorebooks and unknown entry fields remain in the package."
	lore_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.add_child(lore_intro)
	_world_lore_list_v0180 = ItemList.new()
	_world_lore_list_v0180.custom_minimum_size.y = 120
	_world_lore_list_v0180.item_selected.connect(_select_lore_entry_v0180)
	lore.add_child(_world_lore_list_v0180)
	_world_lore_name_v0180 = _line_field_v0180(lore, "Entry name")
	_world_lore_keys_v0180 = _line_field_v0180(lore, "Keys (comma separated)")
	_world_lore_content_v0180 = _text_field_v0180(lore, "Content", 120)
	var lore_flags := HBoxContainer.new()
	lore.add_child(lore_flags)
	_world_lore_enabled_v0180 = CheckBox.new()
	_world_lore_enabled_v0180.text = "Enabled"
	_world_lore_enabled_v0180.button_pressed = true
	lore_flags.add_child(_world_lore_enabled_v0180)
	_world_lore_constant_v0180 = CheckBox.new()
	_world_lore_constant_v0180.text = "Always active"
	lore_flags.add_child(_world_lore_constant_v0180)
	var lore_actions := HBoxContainer.new()
	lore.add_child(lore_actions)
	var add_lore := Button.new()
	add_lore.text = "Add Entry"
	add_lore.pressed.connect(_add_lore_entry_v0180)
	lore_actions.add_child(add_lore)
	var update_lore := Button.new()
	update_lore.text = "Update Selected"
	update_lore.pressed.connect(_update_lore_entry_v0180)
	lore_actions.add_child(update_lore)
	var remove_lore := Button.new()
	remove_lore.text = "Remove Selected"
	remove_lore.pressed.connect(_remove_lore_entry_v0180)
	lore_actions.add_child(remove_lore)

	var publishing := _panel_box_v0180(page, "Optional Stoop Preparation")
	var boundary := Label.new()
	boundary.text = "These values prepare a moderated WORLD submission. Export remains local and portable; no network request is made."
	boundary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boundary.modulate = Color(0.82, 0.68, 0.43)
	publishing.add_child(boundary)
	_world_summary_v0180 = _text_field_v0180(publishing, "Publishing summary", 90)
	_world_creator_v0180 = _line_field_v0180(publishing, "Creator")
	_world_original_creator_v0180 = _line_field_v0180(publishing, "Original creator (if different)")
	_world_tags_v0180 = _line_field_v0180(publishing, "Tags (comma separated)")
	_world_stable_id_v0180 = _line_field_v0180(publishing, "Stable update identity")
	_world_summary_v0180.text_changed.connect(_refresh_world_readiness_v0180)
	_world_stable_id_v0180.text_changed.connect(func(_value: String): _refresh_world_readiness_v0180())
	var publishing_flags := HBoxContainer.new()
	publishing.add_child(publishing_flags)
	_world_adult_v0180 = CheckBox.new()
	_world_adult_v0180.text = "Contains adult content"
	_world_adult_v0180.toggled.connect(func(_pressed: bool): _refresh_world_readiness_v0180())
	publishing_flags.add_child(_world_adult_v0180)
	_world_comments_v0180 = CheckBox.new()
	_world_comments_v0180.text = "Allow comments"
	_world_comments_v0180.button_pressed = true
	publishing_flags.add_child(_world_comments_v0180)
	_world_readiness_v0180 = RichTextLabel.new()
	_world_readiness_v0180.bbcode_enabled = true
	_world_readiness_v0180.fit_content = true
	_world_readiness_v0180.custom_minimum_size.y = 72
	publishing.add_child(_world_readiness_v0180)

	var actions := HBoxContainer.new()
	page.add_child(actions)
	var save_button := Button.new()
	save_button.text = "Save World to Project"
	save_button.pressed.connect(func(): _save_world_v0180(true))
	actions.add_child(save_button)
	var export_button := Button.new()
	export_button.text = "Review and Export .fpworld…"
	export_button.pressed.connect(_request_world_export_v0180)
	actions.add_child(export_button)


func _build_world_review_dialog_v0180() -> void:
	_world_review_dialog_v0180 = ConfirmationDialog.new()
	_world_review_dialog_v0180.visible = false
	_world_review_dialog_v0180.title = "Review portable world package"
	_world_review_dialog_v0180.ok_button_text = "Choose Export Location"
	_world_review_dialog_v0180.cancel_button_text = "Go Back"
	_world_review_dialog_v0180.confirmed.connect(
		func(): _world_export_dialog_v0180.popup_centered_ratio(0.72)
	)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(600, 130)
	_world_review_dialog_v0180.add_child(box)
	var message := Label.new()
	message.text = "A .fpworld file can include all world lore, descriptions and embedded cover data. Review it before sharing."
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(message)
	_world_private_review_v0180 = CheckBox.new()
	_world_private_review_v0180.text = "I reviewed the world for private project context."
	_world_private_review_v0180.toggled.connect(_update_world_review_button_v0180)
	box.add_child(_world_private_review_v0180)
	_world_adult_review_v0180 = CheckBox.new()
	_world_adult_review_v0180.text = "I confirm the adult-content declaration is correct."
	_world_adult_review_v0180.toggled.connect(_update_world_review_button_v0180)
	box.add_child(_world_adult_review_v0180)
	add_child(_world_review_dialog_v0180)
	_world_review_dialog_v0180.hide()


func _panel_box_v0180(parent: Control, title_text: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 18)
	box.add_child(heading)
	return box


func _line_field_v0180(parent: Control, label_text: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var editor := LineEdit.new()
	parent.add_child(editor)
	return editor


func _text_field_v0180(parent: Control, label_text: String, height: int) -> TextEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var editor := TextEdit.new()
	editor.custom_minimum_size.y = height
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	parent.add_child(editor)
	return editor


func _option_field_v0180(parent: Control, label_text: String) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var editor := OptionButton.new()
	parent.add_child(editor)
	return editor


func _refresh_world_selector_v0180() -> void:
	var previous_id := str(_world_record_v0180.get("world_id", ""))
	_world_selector_v0180.clear()
	var worlds := WORLD_SERVICE_V0180.worlds_for_project(_project)
	for value in worlds:
		if not value is Dictionary:
			continue
		var package: Dictionary = value.get("package", {})
		_world_selector_v0180.add_item(str(package.get("name", "Untitled World")))
		_world_selector_v0180.set_item_metadata(_world_selector_v0180.item_count - 1, str(value.get("world_id", "")))
	if worlds.is_empty():
		_world_record_v0180 = WORLD_SERVICE_V0180.new_world_record()
		_load_world_form_v0180()
		return
	var selected_index := 0
	for index in range(_world_selector_v0180.item_count):
		if str(_world_selector_v0180.get_item_metadata(index)) == previous_id:
			selected_index = index
			break
	_world_selector_v0180.select(selected_index)
	_select_world_v0180(selected_index)


func _select_world_v0180(index: int) -> void:
	if index < 0 or index >= _world_selector_v0180.item_count:
		return
	var world_id := str(_world_selector_v0180.get_item_metadata(index))
	for value in WORLD_SERVICE_V0180.worlds_for_project(_project):
		if value is Dictionary and str(value.get("world_id", "")) == world_id:
			_world_record_v0180 = value.duplicate(true)
			_load_world_form_v0180()
			return


func _load_world_form_v0180() -> void:
	_world_refreshing_v0180 = true
	var package: Dictionary = _world_record_v0180.get("package", {})
	var publishing: Dictionary = _world_record_v0180.get("publishing", {})
	_world_name_v0180.text = str(package.get("name", ""))
	_world_description_v0180.text = str(package.get("description", ""))
	_world_cover_data_v0180 = str(package.get("cover", ""))
	_refresh_world_cover_v0180()
	_world_climate_v0180.button_pressed = bool(package.get("climate_enabled", true))
	_select_metadata_v0180(_world_biome_v0180, str(package.get("biome", {}).get("id", "")))
	var place_traits: Dictionary = package.get("place_traits", {}) if package.get("place_traits", {}) is Dictionary else {}
	_select_metadata_v0180(_world_atmosphere_v0180, str(place_traits.get("atmosphere", "breathable")))
	_select_metadata_v0180(_world_gravity_v0180, str(place_traits.get("gravity", "earth")))
	_world_entries_v0180 = _primary_lorebook_v0180(package).get("entries", []).duplicate(true)
	_refresh_lore_list_v0180()
	_world_summary_v0180.text = str(publishing.get("summary", ""))
	_world_creator_v0180.text = str(publishing.get("creator", ""))
	_world_original_creator_v0180.text = str(publishing.get("original_creator", ""))
	_world_tags_v0180.text = ", ".join(publishing.get("tags", []))
	_world_adult_v0180.button_pressed = bool(publishing.get("adult_content", false))
	_world_comments_v0180.button_pressed = bool(publishing.get("comments_enabled", true))
	_world_stable_id_v0180.text = str(publishing.get("stable_update_identity", package.get("id", "")))
	_toggle_world_climate_v0180(_world_climate_v0180.button_pressed)
	_world_refreshing_v0180 = false
	_refresh_world_readiness_v0180()


func _capture_world_form_v0180() -> Dictionary:
	var package: Dictionary = _world_record_v0180.get("package", {}).duplicate(true)
	var lorebook := _primary_lorebook_v0180(package)
	lorebook["name"] = str(lorebook.get("name", _world_name_v0180.text))
	lorebook["entries"] = _world_entries_v0180.duplicate(true)
	var single_lorebook_value: Variant = package.get("lorebook", {})
	var lorebooks_value: Variant = package.get("lorebooks", [])
	var lorebooks: Array = lorebooks_value.duplicate(true) if lorebooks_value is Array else []
	var should_sync_single: bool = (
		lorebooks.is_empty()
		or (single_lorebook_value is Dictionary and lorebooks[0] is Dictionary and single_lorebook_value == lorebooks[0])
	)
	if lorebooks.is_empty():
		lorebooks.append(lorebook.duplicate(true))
	else:
		lorebooks[0] = lorebook.duplicate(true)
	var fields := {
		"name": _world_name_v0180.text.strip_edges(),
		"description": _world_description_v0180.text.strip_edges(),
		"cover": _world_cover_data_v0180,
		"climate_enabled": _world_climate_v0180.button_pressed,
		"lorebooks": lorebooks,
		"publishing": {
			"summary": _world_summary_v0180.text.strip_edges(),
			"creator": _world_creator_v0180.text.strip_edges(),
			"original_creator": _world_original_creator_v0180.text.strip_edges(),
			"tags": _split_tags_v0180(_world_tags_v0180.text),
			"adult_content": _world_adult_v0180.button_pressed,
			"comments_enabled": _world_comments_v0180.button_pressed,
			"stable_update_identity": _world_stable_id_v0180.text.strip_edges()
		}
	}
	if should_sync_single:
		fields["lorebook"] = lorebook
	if _world_climate_v0180.button_pressed:
		var biome_id := _selected_metadata_v0180(_world_biome_v0180)
		if not biome_id.is_empty():
			for value in WORLD_SERVICE_V0180.catalog().get("biomes", []):
				if value is Dictionary and str(value.get("id", "")) == biome_id:
					fields["biome"] = value.duplicate(true)
					break
		elif package.has("biome"):
			fields["biome"] = package.get("biome", {}).duplicate(true)
		var traits_value: Variant = package.get("place_traits", {})
		var merged_traits: Dictionary = traits_value.duplicate(true) if traits_value is Dictionary else {}
		merged_traits["atmosphere"] = _selected_metadata_v0180(_world_atmosphere_v0180)
		merged_traits["gravity"] = _selected_metadata_v0180(_world_gravity_v0180)
		fields["place_traits"] = merged_traits
	return WORLD_SERVICE_V0180.apply_editor_fields(_world_record_v0180, fields)


func _save_world_v0180(show_message: bool) -> bool:
	_world_record_v0180 = _capture_world_form_v0180()
	var validation := WORLD_SERVICE_V0180.validate_package(_world_record_v0180.get("package", {}))
	if not bool(validation.get("ok", false)):
		_status.text = "World not saved: %s" % "; ".join(validation.get("errors", []))
		return false
	_project = WORLD_SERVICE_V0180.upsert_world(_project, _world_record_v0180)
	var saved := CCFStorageService.save_project(_project)
	if not bool(saved.get("ok", false)):
		_status.text = str(saved.get("error", "Could not save the world."))
		return false
	_project = saved.get("project", _project)
	world_project_changed_v0180.emit(_project.duplicate(true))
	if show_message:
		_status.text = "World saved to this Character Card Forge project."
	_refresh_world_selector_v0180()
	return true


func _new_world_v0180() -> void:
	_world_record_v0180 = WORLD_SERVICE_V0180.new_world_record()
	_load_world_form_v0180()
	_status.text = "New world draft created. Save it to add it to this project."


func _remove_world_v0180() -> void:
	var world_id := str(_world_record_v0180.get("world_id", ""))
	if world_id.is_empty():
		return
	_project = WORLD_SERVICE_V0180.remove_world(_project, world_id)
	var saved := CCFStorageService.save_project(_project)
	if bool(saved.get("ok", false)):
		_project = saved.get("project", _project)
		world_project_changed_v0180.emit(_project.duplicate(true))
		_world_record_v0180.clear()
		_refresh_world_selector_v0180()
		_status.text = "World removed from this project."


func _import_world_v0180(path: String) -> void:
	var result := WORLD_SERVICE_V0180.import_fpworld(_project, path)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not import this .fpworld file."))
		return
	_project = result.get("project", _project)
	_world_record_v0180 = result.get("record", {})
	var saved := CCFStorageService.save_project(_project)
	if not bool(saved.get("ok", false)):
		_status.text = str(saved.get("error", "Could not save the imported world."))
		return
	_project = saved.get("project", _project)
	world_project_changed_v0180.emit(_project.duplicate(true))
	_refresh_world_selector_v0180()
	_status.text = "Imported .fpworld without discarding unknown fields."


func _request_world_export_v0180() -> void:
	if not _save_world_v0180(false):
		return
	_world_private_review_v0180.button_pressed = false
	_world_adult_review_v0180.button_pressed = false
	_world_adult_review_v0180.visible = _world_adult_v0180.button_pressed
	_update_world_review_button_v0180(false)
	_world_review_dialog_v0180.popup_centered()


func _export_world_v0180(path: String) -> void:
	var result := WORLD_SERVICE_V0180.export_fpworld(_world_record_v0180, path)
	_status.text = (
		"Exported portable Front Porch World to %s" % str(result.get("path", path))
		if bool(result.get("ok", false))
		else str(result.get("error", "World export failed."))
	)


func _update_world_review_button_v0180(_pressed: bool) -> void:
	if _world_review_dialog_v0180 == null:
		return
	var adult_ok := not _world_adult_v0180.button_pressed or _world_adult_review_v0180.button_pressed
	_world_review_dialog_v0180.get_ok_button().disabled = not _world_private_review_v0180.button_pressed or not adult_ok


func _choose_world_cover_v0180(path: String) -> void:
	var result := WORLD_SERVICE_V0180.cover_data_url_from_image(path)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not prepare the cover."))
		return
	_world_cover_data_v0180 = str(result.get("data_url", ""))
	_refresh_world_cover_v0180()
	_refresh_world_readiness_v0180()
	_status.text = "Cover embedded at %d × %d (%d KiB)." % [int(result.get("width", 0)), int(result.get("height", 0)), ceili(float(result.get("byte_size", 0)) / 1024.0)]


func _remove_world_cover_v0180() -> void:
	_world_cover_data_v0180 = ""
	_refresh_world_cover_v0180()
	_refresh_world_readiness_v0180()


func _refresh_world_cover_v0180() -> void:
	_world_cover_v0180.texture = null
	if _world_cover_data_v0180.is_empty():
		_world_cover_status_v0180.text = "No cover. Portable export is allowed, but The Stoop requires one."
		return
	var comma := _world_cover_data_v0180.find(",")
	if comma < 0:
		_world_cover_status_v0180.text = "Cover data is preserved but cannot be previewed."
		return
	var bytes := Marshalls.base64_to_raw(_world_cover_data_v0180.substr(comma + 1))
	var image := Image.new()
	var header := _world_cover_data_v0180.substr(0, comma).to_lower()
	var error := ERR_FILE_UNRECOGNIZED
	if header.contains("image/png"):
		error = image.load_png_from_buffer(bytes)
	elif header.contains("image/webp"):
		error = image.load_webp_from_buffer(bytes)
	else:
		error = image.load_jpg_from_buffer(bytes)
	if error == OK:
		_world_cover_v0180.texture = ImageTexture.create_from_image(image)
		_world_cover_status_v0180.text = "Embedded cover ready (%d × %d)." % [image.get_width(), image.get_height()]
	else:
		_world_cover_status_v0180.text = "Cover data is preserved but cannot be previewed."


func _toggle_world_climate_v0180(enabled: bool) -> void:
	_world_biome_v0180.disabled = not enabled
	_world_atmosphere_v0180.disabled = not enabled
	_world_gravity_v0180.disabled = not enabled


func _primary_lorebook_v0180(package: Dictionary) -> Dictionary:
	var many_value: Variant = package.get("lorebooks", [])
	if many_value is Array and not (many_value as Array).is_empty() and many_value[0] is Dictionary:
		return many_value[0].duplicate(true)
	var single_value: Variant = package.get("lorebook", {})
	return single_value.duplicate(true) if single_value is Dictionary else {"entries": []}


func _refresh_lore_list_v0180() -> void:
	_world_lore_list_v0180.clear()
	for index in range(_world_entries_v0180.size()):
		var entry: Dictionary = _world_entries_v0180[index] if _world_entries_v0180[index] is Dictionary else {}
		var entry_name := str(entry.get("name", "Lore %d" % (index + 1))).strip_edges()
		if entry_name.is_empty():
			entry_name = "Lore %d" % (index + 1)
		_world_lore_list_v0180.add_item(entry_name)
	_clear_lore_editor_v0180()


func _select_lore_entry_v0180(index: int) -> void:
	if index < 0 or index >= _world_entries_v0180.size() or not _world_entries_v0180[index] is Dictionary:
		return
	var entry: Dictionary = _world_entries_v0180[index]
	_world_lore_name_v0180.text = str(entry.get("name", ""))
	var keys_value: Variant = entry.get("keys", entry.get("key", []))
	_world_lore_keys_v0180.text = ", ".join(keys_value) if keys_value is Array else str(keys_value)
	_world_lore_content_v0180.text = str(entry.get("content", ""))
	_world_lore_enabled_v0180.button_pressed = bool(entry.get("enabled", true))
	_world_lore_constant_v0180.button_pressed = bool(entry.get("constant", false))


func _add_lore_entry_v0180() -> void:
	_world_entries_v0180.append(_lore_editor_value_v0180({}))
	_refresh_lore_list_v0180()
	_world_lore_list_v0180.select(_world_entries_v0180.size() - 1)
	_select_lore_entry_v0180(_world_entries_v0180.size() - 1)


func _update_lore_entry_v0180() -> void:
	var selected := _world_lore_list_v0180.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	var original: Dictionary = _world_entries_v0180[index] if _world_entries_v0180[index] is Dictionary else {}
	_world_entries_v0180[index] = _lore_editor_value_v0180(original)
	_refresh_lore_list_v0180()
	_world_lore_list_v0180.select(index)


func _remove_lore_entry_v0180() -> void:
	var selected := _world_lore_list_v0180.get_selected_items()
	if selected.is_empty():
		return
	_world_entries_v0180.remove_at(int(selected[0]))
	_refresh_lore_list_v0180()


func _lore_editor_value_v0180(original: Dictionary) -> Dictionary:
	var entry := original.duplicate(true)
	entry["name"] = _world_lore_name_v0180.text.strip_edges()
	entry["keys"] = _split_tags_v0180(_world_lore_keys_v0180.text)
	entry["content"] = _world_lore_content_v0180.text.strip_edges()
	entry["enabled"] = _world_lore_enabled_v0180.button_pressed
	entry["constant"] = _world_lore_constant_v0180.button_pressed
	return entry


func _clear_lore_editor_v0180() -> void:
	_world_lore_name_v0180.text = ""
	_world_lore_keys_v0180.text = ""
	_world_lore_content_v0180.text = ""
	_world_lore_enabled_v0180.button_pressed = true
	_world_lore_constant_v0180.button_pressed = false


func _refresh_world_readiness_v0180() -> void:
	if _world_refreshing_v0180 or _world_readiness_v0180 == null:
		return
	var draft := _capture_world_form_v0180()
	var report := WORLD_SERVICE_V0180.stoop_readiness(draft)
	if bool(report.get("ready", false)):
		_world_readiness_v0180.text = "[color=#8ed6a3]Stoop metadata is ready for Front Porch review.[/color]\nPortable export still requires an explicit privacy%s confirmation." % (" and adult-content" if bool(report.get("adult_content", false)) else "")
	else:
		_world_readiness_v0180.text = "[color=#e6c57a]Portable .fpworld is allowed. Stoop preparation still needs: %s.[/color]" % ", ".join(report.get("missing", []))


func _selected_metadata_v0180(option: OptionButton) -> String:
	return str(option.get_item_metadata(option.selected)) if option.selected >= 0 else ""


func _select_metadata_v0180(option: OptionButton, value: String) -> void:
	option.select(0)
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == value:
			option.select(index)
			return


func _split_tags_v0180(text: String) -> Array:
	var result: Array = []
	for value in text.split(",", false):
		var clean := value.strip_edges()
		if not clean.is_empty() and not result.has(clean):
			result.append(clean)
	return result
