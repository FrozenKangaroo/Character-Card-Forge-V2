class_name CCFImportExportWindowV0175
extends CCFImportExportWindowV0174

signal gallery_project_changed_v0175(project: Dictionary)

const GALLERY_SERVICE_V0175 = preload(
	"res://scripts/services/front_porch_avatar_gallery_service_v0175.gd"
)
const AVATAR_INSTALL_SERVICE_V0175 = preload(
	"res://scripts/services/front_porch_avatar_install_service_v0175.gd"
)

var _gallery_source_v0175: OptionButton
var _gallery_role_v0175: OptionButton
var _gallery_list_v0175: ItemList
var _gallery_preview_v0175: TextureRect
var _gallery_summary_v0175: RichTextLabel
var _gallery_add_source_v0175: Button
var _gallery_favourite_v0175: Button
var _gallery_portrait_favourite_v0175: Button
var _gallery_portrait_v0175: Button
var _gallery_remove_v0175: Button
var _gallery_import_image_dialog_v0175: FileDialog
var _gallery_import_pack_dialog_v0175: FileDialog
var _gallery_export_pack_dialog_v0175: FileDialog
var _front_porch_gallery_target_v0175: OptionButton
var _front_porch_gallery_install_selected_v0175: Button
var _front_porch_gallery_install_all_v0175: Button
var _front_porch_gallery_remote_favourite_v0175: CheckBox
var _front_porch_gallery_remote_status_v0175: RichTextLabel
var _gallery_busy_v0175 := false


func _ready() -> void:
	super._ready()
	var previous_client := _front_porch_client_v0173
	var previous_url := (
		previous_client.base_url()
		if previous_client != null
		else CCFFrontPorchInstallServiceV0173.DEFAULT_BASE_URL
	)
	if previous_client != null:
		if previous_client.get_parent() == self:
			remove_child(previous_client)
		previous_client.queue_free()
	var upgraded := AVATAR_INSTALL_SERVICE_V0175.new()
	upgraded.configure(previous_url)
	add_child(upgraded)
	_front_porch_client_v0173 = upgraded


func _build_ui() -> void:
	super._build_ui()
	var tabs := _primary_tabs_v0173()
	if tabs != null:
		_build_avatar_gallery_tab_v0175(tabs)


func _build_dialogs() -> void:
	super._build_dialogs()
	_gallery_import_image_dialog_v0175 = _new_file_dialog(
		FileDialog.FILE_MODE_OPEN_FILE,
		["*.png, *.jpg, *.jpeg, *.webp ; Images"]
	)
	_gallery_import_image_dialog_v0175.file_selected.connect(
		_import_gallery_image_v0175
	)
	_gallery_import_pack_dialog_v0175 = _new_file_dialog(
		FileDialog.FILE_MODE_OPEN_FILE, ["*.zip ; Expression sprite packs"]
	)
	_gallery_import_pack_dialog_v0175.file_selected.connect(
		_import_expression_pack_v0175
	)
	_gallery_export_pack_dialog_v0175 = _new_file_dialog(
		FileDialog.FILE_MODE_SAVE_FILE, ["*.zip ; Front Porch expression pack"]
	)
	_gallery_export_pack_dialog_v0175.file_selected.connect(
		_export_expression_pack_v0175
	)


func _build_avatar_gallery_tab_v0175(tabs: TabContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "FrontPorchAvatarGallery"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Avatar Gallery")
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	scroll.add_child(page)
	var heading := Label.new()
	heading.text = "Front Porch Expressions & Alternate Looks"
	heading.add_theme_font_size_override("font_size", 22)
	page.add_child(heading)
	var intro := Label.new()
	intro.text = (
		"Build a character's optional Front Porch avatar gallery from Image Studio results "
		+ "or manually imported images. Gallery roles, portrait assignment, portable ZIP "
		+ "export and direct Front Porch installation remain separate explicit actions."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)

	var author_panel := PanelContainer.new()
	page.add_child(author_panel)
	var author_box := VBoxContainer.new()
	author_box.add_theme_constant_override("separation", 8)
	author_panel.add_child(author_box)
	var author_title := Label.new()
	author_title.text = "Author Gallery"
	author_title.add_theme_font_size_override("font_size", 18)
	author_box.add_child(author_title)
	var source_label := Label.new()
	source_label.text = "Existing portrait or Image Studio result"
	author_box.add_child(source_label)
	_gallery_source_v0175 = OptionButton.new()
	author_box.add_child(_gallery_source_v0175)
	var role_label := Label.new()
	role_label.text = "Front Porch role"
	author_box.add_child(role_label)
	_gallery_role_v0175 = OptionButton.new()
	_gallery_role_v0175.add_item("Alternate Look")
	_gallery_role_v0175.set_item_metadata(0, {"kind": "look", "label": ""})
	for emotion_value in GALLERY_SERVICE_V0175.EMOTION_LABELS:
		_gallery_role_v0175.add_item("Expression — %s" % str(emotion_value).capitalize())
		_gallery_role_v0175.set_item_metadata(
			_gallery_role_v0175.item_count - 1,
			{"kind": "expression", "label": emotion_value}
		)
	var neutral_index := GALLERY_SERVICE_V0175.EMOTION_LABELS.find("neutral") + 1
	_gallery_role_v0175.select(maxi(neutral_index, 0))
	author_box.add_child(_gallery_role_v0175)
	var author_actions := HFlowContainer.new()
	author_actions.add_theme_constant_override("separation", 8)
	author_box.add_child(author_actions)
	_gallery_add_source_v0175 = Button.new()
	_gallery_add_source_v0175.text = "Add Existing Image"
	_gallery_add_source_v0175.pressed.connect(_add_gallery_source_v0175)
	author_actions.add_child(_gallery_add_source_v0175)
	var import_image := Button.new()
	import_image.text = "Import Image…"
	import_image.pressed.connect(
		func(): _gallery_import_image_dialog_v0175.popup_centered_ratio(0.72)
	)
	author_actions.add_child(import_image)
	var import_pack := Button.new()
	import_pack.text = "Import Expression ZIP…"
	import_pack.pressed.connect(
		func(): _gallery_import_pack_dialog_v0175.popup_centered_ratio(0.72)
	)
	author_actions.add_child(import_pack)

	_gallery_list_v0175 = ItemList.new()
	_gallery_list_v0175.custom_minimum_size.y = 180
	_gallery_list_v0175.select_mode = ItemList.SELECT_SINGLE
	_gallery_list_v0175.item_selected.connect(
		func(_selected_index: int): _refresh_gallery_selection_v0175()
	)
	author_box.add_child(_gallery_list_v0175)
	_gallery_preview_v0175 = TextureRect.new()
	_gallery_preview_v0175.custom_minimum_size = Vector2(360, 260)
	_gallery_preview_v0175.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gallery_preview_v0175.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	author_box.add_child(_gallery_preview_v0175)
	_gallery_summary_v0175 = RichTextLabel.new()
	_gallery_summary_v0175.bbcode_enabled = true
	_gallery_summary_v0175.fit_content = true
	_gallery_summary_v0175.custom_minimum_size.y = 90
	author_box.add_child(_gallery_summary_v0175)
	var gallery_actions := HFlowContainer.new()
	gallery_actions.add_theme_constant_override("separation", 8)
	author_box.add_child(gallery_actions)
	_gallery_favourite_v0175 = Button.new()
	_gallery_favourite_v0175.text = "Mark as Canonical Favourite"
	_gallery_favourite_v0175.tooltip_text = (
		"Choose CCF's canonical Front Porch gallery image without changing the portrait."
	)
	_gallery_favourite_v0175.pressed.connect(_mark_gallery_favourite_v0175)
	gallery_actions.add_child(_gallery_favourite_v0175)
	_gallery_portrait_favourite_v0175 = Button.new()
	_gallery_portrait_favourite_v0175.text = "Use Portrait as Favourite"
	_gallery_portrait_favourite_v0175.pressed.connect(_mark_portrait_favourite_v0175)
	gallery_actions.add_child(_gallery_portrait_favourite_v0175)
	_gallery_portrait_v0175 = Button.new()
	_gallery_portrait_v0175.text = "Assign as CCF Portrait"
	_gallery_portrait_v0175.tooltip_text = (
		"Explicitly change the CCF character portrait to this image."
	)
	_gallery_portrait_v0175.pressed.connect(_assign_gallery_portrait_v0175)
	gallery_actions.add_child(_gallery_portrait_v0175)
	_gallery_remove_v0175 = Button.new()
	_gallery_remove_v0175.text = "Remove Gallery Role"
	_gallery_remove_v0175.tooltip_text = (
		"Remove only the gallery association. The image file and Image Studio record remain."
	)
	_gallery_remove_v0175.pressed.connect(_remove_gallery_entry_v0175)
	gallery_actions.add_child(_gallery_remove_v0175)
	var export_pack := Button.new()
	export_pack.text = "Export Expression ZIP…"
	export_pack.pressed.connect(_request_expression_pack_export_v0175)
	gallery_actions.add_child(export_pack)

	var install_panel := PanelContainer.new()
	page.add_child(install_panel)
	var install_box := VBoxContainer.new()
	install_box.add_theme_constant_override("separation", 8)
	install_panel.add_child(install_box)
	var install_title := Label.new()
	install_title.text = "Install Through Front Porch"
	install_title.add_theme_font_size_override("font_size", 18)
	install_box.add_child(install_title)
	var install_hint := Label.new()
	install_hint.text = (
		"Connect on the Install to Front Porch tab, then select the exact existing Front "
		+ "Porch character. Uploads use Front Porch 1.3.2+'s supported avatar/look API. "
		+ "Installing all again creates another set, so run it only when intended."
	)
	install_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	install_hint.modulate = Color(0.68, 0.72, 0.82)
	install_box.add_child(install_hint)
	var target_actions := HFlowContainer.new()
	target_actions.add_theme_constant_override("separation", 8)
	install_box.add_child(target_actions)
	_front_porch_gallery_target_v0175 = OptionButton.new()
	_front_porch_gallery_target_v0175.custom_minimum_size.x = 420
	_front_porch_gallery_target_v0175.add_item("Refresh Front Porch characters first")
	_front_porch_gallery_target_v0175.set_item_metadata(0, "")
	target_actions.add_child(_front_porch_gallery_target_v0175)
	var refresh_targets := Button.new()
	refresh_targets.text = "Refresh Characters"
	refresh_targets.pressed.connect(_refresh_front_porch_targets_v0175)
	target_actions.add_child(refresh_targets)
	_front_porch_gallery_remote_favourite_v0175 = CheckBox.new()
	_front_porch_gallery_remote_favourite_v0175.text = "Make uploaded selection the Front Porch favourite"
	install_box.add_child(_front_porch_gallery_remote_favourite_v0175)
	var install_actions := HFlowContainer.new()
	install_actions.add_theme_constant_override("separation", 8)
	install_box.add_child(install_actions)
	_front_porch_gallery_install_selected_v0175 = Button.new()
	_front_porch_gallery_install_selected_v0175.text = "Install Selected Image"
	_front_porch_gallery_install_selected_v0175.pressed.connect(
		_install_selected_gallery_entry_v0175
	)
	install_actions.add_child(_front_porch_gallery_install_selected_v0175)
	_front_porch_gallery_install_all_v0175 = Button.new()
	_front_porch_gallery_install_all_v0175.text = "Install Complete Gallery"
	_front_porch_gallery_install_all_v0175.pressed.connect(
		_install_complete_gallery_v0175
	)
	install_actions.add_child(_front_porch_gallery_install_all_v0175)
	_front_porch_gallery_remote_status_v0175 = RichTextLabel.new()
	_front_porch_gallery_remote_status_v0175.bbcode_enabled = true
	_front_porch_gallery_remote_status_v0175.fit_content = true
	_front_porch_gallery_remote_status_v0175.custom_minimum_size.y = 80
	_front_porch_gallery_remote_status_v0175.text = (
		"[color=#a8acbd]No avatar-gallery request has been sent.[/color]"
	)
	install_box.add_child(_front_porch_gallery_remote_status_v0175)
	var boundary := Label.new()
	boundary.text = (
		"Safety boundary: no gallery upload is automatic, no Front Porch conversation is "
		+ "changed, and Character Card Forge never opens or writes front_porch.db."
	)
	boundary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boundary.modulate = Color(0.78, 0.66, 0.48)
	page.add_child(boundary)


func _refresh_all() -> void:
	super._refresh_all()
	if _gallery_list_v0175 != null:
		_refresh_avatar_gallery_v0175()


func release_project() -> void:
	super.release_project()
	if _gallery_list_v0175 != null:
		_gallery_list_v0175.clear()
	if _front_porch_gallery_target_v0175 != null:
		_front_porch_gallery_target_v0175.clear()
		_front_porch_gallery_target_v0175.add_item("Refresh Front Porch characters first")
		_front_porch_gallery_target_v0175.set_item_metadata(0, "")


func front_porch_avatar_gallery_capabilities_v0175() -> Dictionary:
	var capabilities := GALLERY_SERVICE_V0175.capabilities()
	var client := _gallery_client_v0175()
	if client != null:
		capabilities.merge(client.gallery_capabilities_v0175(), true)
	return capabilities


func _refresh_avatar_gallery_v0175() -> void:
	_refresh_gallery_sources_v0175()
	_gallery_portrait_favourite_v0175.disabled = _active_portrait_source_path().is_empty()
	var previous_id := _selected_gallery_id_v0175()
	_gallery_list_v0175.clear()
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var gallery := GALLERY_SERVICE_V0175.gallery_for_character(character)
	var favourite_id := str(gallery.get("favourite_gallery_id", ""))
	var selected_index := -1
	for entry_value in gallery.get("entries", []):
		var entry := entry_value as Dictionary
		var entry_kind := str(entry.get("kind", ""))
		var role := (
			"Look"
			if entry_kind == "look"
			else "Expression: %s" % str(entry.get("label", "")).capitalize()
		)
		var star := "★ " if str(entry.get("gallery_id", "")) == favourite_id else ""
		_gallery_list_v0175.add_item(
			"%s%s — %s" % [star, role, str(entry.get("path", "")).get_file()]
		)
		var item_index := _gallery_list_v0175.item_count - 1
		_gallery_list_v0175.set_item_metadata(item_index, entry.duplicate(true))
		if str(entry.get("gallery_id", "")) == previous_id:
			selected_index = item_index
	if selected_index < 0 and _gallery_list_v0175.item_count > 0:
		selected_index = 0
	if selected_index >= 0:
		_gallery_list_v0175.select(selected_index)
	_refresh_gallery_selection_v0175()


func _refresh_gallery_sources_v0175() -> void:
	var previous_path := ""
	if _gallery_source_v0175.selected >= 0:
		var previous: Variant = _gallery_source_v0175.get_selected_metadata()
		if previous is Dictionary:
			previous_path = str(previous.get("path", ""))
	_gallery_source_v0175.clear()
	var selected_index := 0
	for source in GALLERY_SERVICE_V0175.available_sources(
		_project, _active_character_id
	):
		_gallery_source_v0175.add_item(str(source.get("label", "Image")))
		var item_index := _gallery_source_v0175.item_count - 1
		_gallery_source_v0175.set_item_metadata(item_index, source.duplicate(true))
		if str(source.get("path", "")) == previous_path:
			selected_index = item_index
	if _gallery_source_v0175.item_count == 0:
		_gallery_source_v0175.add_item("No portrait or Image Studio result is available")
		_gallery_source_v0175.set_item_metadata(0, {})
	_gallery_source_v0175.select(selected_index)
	_gallery_add_source_v0175.disabled = (
		_gallery_source_v0175.get_selected_metadata() as Dictionary
	).is_empty()


func _refresh_gallery_selection_v0175() -> void:
	var entry := _selected_gallery_entry_v0175()
	var available := not entry.is_empty()
	_gallery_favourite_v0175.disabled = not available
	_gallery_portrait_v0175.disabled = not available
	_gallery_remove_v0175.disabled = not available
	_front_porch_gallery_install_selected_v0175.disabled = (
		not available or _gallery_busy_v0175
	)
	if not available:
		_gallery_preview_v0175.texture = null
		_gallery_summary_v0175.text = (
			"[color=#a8acbd]No Front Porch gallery images have been authored yet.[/color]"
		)
		return
	var resolved_path := GALLERY_SERVICE_V0175._resolve_project_path(
		_project, str(entry.get("path", ""))
	)
	_gallery_preview_v0175.texture = _gallery_texture_v0175(resolved_path)
	var provenance: Dictionary = entry.get("provenance", {})
	var origin := str(provenance.get("origin", "existing_asset")).replace("_", " ")
	var image_studio: Dictionary = provenance.get("image_studio", {})
	var details := ""
	if not image_studio.is_empty():
		details = "\nModel: %s • Seed: %s" % [
			str(image_studio.get("model", "unknown")),
			str(image_studio.get("seed", "unknown"))
		]
	_gallery_summary_v0175.text = (
		"[color=#8ed6a3]%s[/color]\nPath: %s\nProvenance: %s%s"
		% [
			("Alternate look" if str(entry.get("kind", "")) == "look" else "Expression — %s" % str(entry.get("label", "")).capitalize()),
			_escape_bbcode_v0173(str(entry.get("path", ""))),
			_escape_bbcode_v0173(origin),
			_escape_bbcode_v0173(details)
		]
	)


func _gallery_texture_v0175(source_path: String) -> Texture2D:
	if source_path.is_empty():
		return null
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _selected_gallery_entry_v0175() -> Dictionary:
	if _gallery_list_v0175 == null or _gallery_list_v0175.get_selected_items().is_empty():
		return {}
	var selected_index := int(_gallery_list_v0175.get_selected_items()[0])
	var metadata: Variant = _gallery_list_v0175.get_item_metadata(selected_index)
	return (metadata as Dictionary).duplicate(true) if metadata is Dictionary else {}


func _selected_gallery_id_v0175() -> String:
	return str(_selected_gallery_entry_v0175().get("gallery_id", ""))


func _selected_gallery_role_v0175() -> Dictionary:
	if _gallery_role_v0175.selected < 0:
		return {"kind": "look", "label": ""}
	var metadata: Variant = _gallery_role_v0175.get_selected_metadata()
	return (metadata as Dictionary).duplicate(true) if metadata is Dictionary else {"kind": "look", "label": ""}


func _add_gallery_source_v0175() -> void:
	project_refresh_requested.emit()
	var source_value: Variant = _gallery_source_v0175.get_selected_metadata()
	if not source_value is Dictionary or (source_value as Dictionary).is_empty():
		_status.text = "Choose an available portrait or Image Studio result first."
		return
	var role := _selected_gallery_role_v0175()
	_apply_gallery_change_v0175(GALLERY_SERVICE_V0175.add_source(
		_project,
		_active_character_id,
		source_value as Dictionary,
		str(role.get("kind", "look")),
		str(role.get("label", ""))
	), "Added the image to the Front Porch avatar gallery.")


func _import_gallery_image_v0175(source_path: String) -> void:
	project_refresh_requested.emit()
	var role := _selected_gallery_role_v0175()
	_apply_gallery_change_v0175(GALLERY_SERVICE_V0175.import_image(
		_project,
		_active_character_id,
		source_path,
		str(role.get("kind", "look")),
		str(role.get("label", ""))
	), "Imported the image into the project and added its Front Porch gallery role.")


func _import_expression_pack_v0175(source_path: String) -> void:
	project_refresh_requested.emit()
	var result := GALLERY_SERVICE_V0175.import_expression_zip(
		_project, _active_character_id, source_path
	)
	var success_message := "Imported %d expression(s)" % int(result.get("imported", 0))
	if int(result.get("unrecognised", 0)) > 0:
		success_message += " • %d unrecognised" % int(result.get("unrecognised", 0))
	if int(result.get("skipped", 0)) > 0:
		success_message += " • %d skipped" % int(result.get("skipped", 0))
	_apply_gallery_change_v0175(result, success_message + ".")


func _mark_gallery_favourite_v0175() -> void:
	project_refresh_requested.emit()
	_apply_gallery_change_v0175(GALLERY_SERVICE_V0175.set_favourite(
		_project, _active_character_id, _selected_gallery_id_v0175()
	), "Marked the selected gallery image as the canonical favourite. The portrait is unchanged.")


func _mark_portrait_favourite_v0175() -> void:
	project_refresh_requested.emit()
	_apply_gallery_change_v0175(GALLERY_SERVICE_V0175.set_favourite(
		_project, _active_character_id, GALLERY_SERVICE_V0175.PORTRAIT_FAVOURITE_ID
	), "The current portrait is now the canonical favourite.")


func _assign_gallery_portrait_v0175() -> void:
	project_refresh_requested.emit()
	_apply_gallery_change_v0175(GALLERY_SERVICE_V0175.set_portrait(
		_project, _active_character_id, _selected_gallery_id_v0175()
	), "Assigned the selected gallery image as the CCF portrait.")


func _remove_gallery_entry_v0175() -> void:
	project_refresh_requested.emit()
	_apply_gallery_change_v0175(GALLERY_SERVICE_V0175.remove_entry(
		_project, _active_character_id, _selected_gallery_id_v0175()
	), "Removed the gallery role. The image file and Image Studio record remain available.")


func _apply_gallery_change_v0175(result: Dictionary, success_message: String) -> void:
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not update the avatar gallery."))
		return
	var project_value: Variant = result.get("project", {})
	if not project_value is Dictionary:
		_status.text = "The avatar gallery update returned no project data."
		return
	_project = (project_value as Dictionary).duplicate(true)
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not save the avatar gallery."))
		return
	_refresh_avatar_gallery_v0175()
	gallery_project_changed_v0175.emit(_project.duplicate(true))
	_status.text = success_message


func _request_expression_pack_export_v0175() -> void:
	project_refresh_requested.emit()
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var filename := "%s-expressions.zip" % CCFStorageService.character_display_name(character).validate_filename()
	_gallery_export_pack_dialog_v0175.current_file = filename
	_gallery_export_pack_dialog_v0175.popup_centered_ratio(0.72)


func _export_expression_pack_v0175(destination_path: String) -> void:
	var output_path := destination_path if destination_path.get_extension().to_lower() == "zip" else destination_path + ".zip"
	var result := GALLERY_SERVICE_V0175.export_expression_zip(
		_project, _active_character_id, output_path
	)
	_status.text = (
		"Exported a Front Porch-compatible expression ZIP to %s" % output_path
		if bool(result.get("ok", false))
		else str(result.get("error", "Expression ZIP export failed."))
	)


func _gallery_client_v0175() -> CCFFrontPorchAvatarInstallServiceV0175:
	return (
		_front_porch_client_v0173 as CCFFrontPorchAvatarInstallServiceV0175
		if _front_porch_client_v0173 is CCFFrontPorchAvatarInstallServiceV0175
		else null
	)


func _refresh_front_porch_targets_v0175() -> void:
	if _gallery_busy_v0175:
		return
	var client := _gallery_client_v0175()
	if client == null or not _front_porch_connected_v0173:
		_front_porch_gallery_remote_status_v0175.text = (
			"[color=#e6c57a]Connect on the Install to Front Porch tab first.[/color]"
		)
		return
	_set_gallery_busy_v0175(true)
	_front_porch_gallery_remote_status_v0175.text = "Loading Front Porch characters…"
	var result := await client.list_characters_v0175()
	_set_gallery_busy_v0175(false)
	if not bool(result.get("ok", false)):
		_front_porch_gallery_remote_status_v0175.text = "[color=#ff9b9b]%s[/color]" % _escape_bbcode_v0173(str(result.get("error", "Could not list Front Porch characters.")))
		if bool(result.get("auth_required", false)):
			_front_porch_connected_v0173 = false
			_refresh_front_porch_install_state_v0173()
		return
	_front_porch_gallery_target_v0175.clear()
	for character in result.get("characters", []):
		_front_porch_gallery_target_v0175.add_item(str(character.get("name", "Untitled Character")))
		_front_porch_gallery_target_v0175.set_item_metadata(
			_front_porch_gallery_target_v0175.item_count - 1, str(character.get("id", ""))
		)
	if _front_porch_gallery_target_v0175.item_count == 0:
		_front_porch_gallery_target_v0175.add_item("No Front Porch characters found")
		_front_porch_gallery_target_v0175.set_item_metadata(0, "")
	_front_porch_gallery_remote_status_v0175.text = "[color=#8ed6a3]Choose the exact Front Porch character to receive these images.[/color]"


func _selected_front_porch_target_v0175() -> String:
	if _front_porch_gallery_target_v0175.selected < 0:
		return ""
	return str(_front_porch_gallery_target_v0175.get_selected_metadata())


func _install_selected_gallery_entry_v0175() -> void:
	var entry := _selected_gallery_entry_v0175()
	if entry.is_empty():
		return
	await _install_gallery_entries_v0175([entry])


func _install_complete_gallery_v0175() -> void:
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var entries := GALLERY_SERVICE_V0175.entries_for_character(character)
	if entries.is_empty():
		_front_porch_gallery_remote_status_v0175.text = "[color=#e6c57a]Add at least one gallery image first.[/color]"
		return
	await _install_gallery_entries_v0175(entries)


func _install_gallery_entries_v0175(entries: Array) -> void:
	if _gallery_busy_v0175:
		return
	var target_id := _selected_front_porch_target_v0175()
	var client := _gallery_client_v0175()
	if client == null or not _front_porch_connected_v0173:
		_front_porch_gallery_remote_status_v0175.text = "[color=#e6c57a]Connect on the Install to Front Porch tab first.[/color]"
		return
	if target_id.is_empty():
		_front_porch_gallery_remote_status_v0175.text = "[color=#e6c57a]Refresh and choose a Front Porch character first.[/color]"
		return
	project_refresh_requested.emit()
	_set_gallery_busy_v0175(true)
	var installed := 0
	var failed := 0
	var local_favourite := str(GALLERY_SERVICE_V0175.gallery_for_character(
		CCFStorageService.get_character(_project, _active_character_id)
	).get("favourite_gallery_id", ""))
	var selected_gallery_id := _selected_gallery_id_v0175()
	var remote_favourite_id := ""
	for entry_value in entries:
		var entry := entry_value as Dictionary
		_front_porch_gallery_remote_status_v0175.text = "Installing %d of %d…" % [installed + failed + 1, entries.size()]
		var upload := await _upload_gallery_entry_v0175(client, target_id, entry)
		if bool(upload.get("ok", false)):
			installed += 1
			if (
				str(entry.get("gallery_id", "")) == local_favourite
				or (
					_front_porch_gallery_remote_favourite_v0175.button_pressed
					and str(entry.get("gallery_id", "")) == selected_gallery_id
				)
			):
				remote_favourite_id = str(upload.get("created_avatar_id", ""))
		else:
			failed += 1
	if not remote_favourite_id.is_empty():
		var favourite_result := await client.set_favourite_v0175(
			target_id, remote_favourite_id
		)
		if not bool(favourite_result.get("ok", false)):
			failed += 1
	_set_gallery_busy_v0175(false)
	_front_porch_gallery_remote_status_v0175.text = (
		"[color=#8ed6a3]Installed %d gallery image(s).[/color]%s"
		% [
			installed,
			(" [color=#e6c57a]%d request(s) failed.[/color]" % failed if failed > 0 else "")
		]
	)


func _upload_gallery_entry_v0175(
	client: CCFFrontPorchAvatarInstallServiceV0175,
	target_id: String,
	entry: Dictionary
) -> Dictionary:
	var stored_path := str(entry.get("path", ""))
	var resolved_path := GALLERY_SERVICE_V0175._resolve_project_path(
		_project, stored_path
	)
	if resolved_path.is_empty():
		return {"ok": false, "error": "Gallery image is missing: %s" % stored_path}
	var image := Image.load_from_file(resolved_path)
	if image == null or image.is_empty():
		return {"ok": false, "error": "Gallery image is unreadable: %s" % stored_path}
	return await client.install_gallery_image_v0175(
		target_id,
		image.save_png_to_buffer(),
		str(entry.get("kind", "expression")),
		str(entry.get("label", ""))
	)


func _set_gallery_busy_v0175(busy_state: bool) -> void:
	_gallery_busy_v0175 = busy_state
	_front_porch_gallery_install_all_v0175.disabled = busy_state
	_refresh_gallery_selection_v0175()
