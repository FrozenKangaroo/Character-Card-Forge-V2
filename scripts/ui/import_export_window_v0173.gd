class_name CCFImportExportWindowV0173
extends CCFImportExportWindowV0135

const FRONT_PORCH_INSTALL_SERVICE_V0173 = preload(
	"res://scripts/services/front_porch_install_service_v0173.gd"
)

var _front_porch_client_v0173: CCFFrontPorchInstallServiceV0173
var _front_porch_url_v0173: LineEdit
var _front_porch_username_v0173: LineEdit
var _front_porch_password_v0173: LineEdit
var _front_porch_totp_v0173: LineEdit
var _front_porch_connect_v0173: Button
var _front_porch_disconnect_v0173: Button
var _front_porch_install_v0173: Button
var _front_porch_artwork_choice_v0173: OptionButton
var _front_porch_artwork_status_v0173: Label
var _front_porch_status_v0173: Label
var _front_porch_report_v0173: RichTextLabel
var _front_porch_collision_panel_v0173: VBoxContainer
var _front_porch_collision_label_v0173: Label
var _front_porch_collision_choice_v0173: OptionButton
var _front_porch_collision_create_v0173: Button
var _front_porch_collision_update_v0173: Button
var _front_porch_collision_cancel_v0173: Button
var _front_porch_busy_v0173 := false
var _front_porch_connected_v0173 := false
var _front_porch_version_v0173 := ""
var _pending_front_porch_bytes_v0173 := PackedByteArray()
var _pending_front_porch_filename_v0173 := ""
var _pending_front_porch_content_type_v0173 := ""
var _pending_front_porch_payload_label_v0173 := ""
var _front_porch_artwork_context_v0173 := ""


func _ready() -> void:
	_front_porch_client_v0173 = FRONT_PORCH_INSTALL_SERVICE_V0173.new()
	add_child(_front_porch_client_v0173)
	super._ready()


func _build_ui() -> void:
	super._build_ui()
	var tabs := _primary_tabs_v0173()
	if tabs != null:
		_build_front_porch_install_tab_v0173(tabs)


func open_for_project(
	project: Dictionary, settings: Dictionary, character_id: String
) -> void:
	super.open_for_project(project, settings, character_id)
	_load_front_porch_connection_v0173()
	_refresh_front_porch_artwork_options_v0173()
	_refresh_front_porch_install_state_v0173()


func update_project_context(
	project: Dictionary, settings: Dictionary, character_id: String
) -> void:
	super.update_project_context(project, settings, character_id)
	_refresh_front_porch_artwork_options_v0173()
	_refresh_front_porch_install_state_v0173()


func release_project() -> void:
	super.release_project()
	_clear_pending_front_porch_collision_v0173()


func _primary_tabs_v0173() -> TabContainer:
	for child in find_children("*", "TabContainer", true, false):
		if child is TabContainer:
			return child as TabContainer
	return null


func _build_front_porch_install_tab_v0173(tabs: TabContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "FrontPorchInstall"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Install to Front Porch")

	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	scroll.add_child(page)

	var page_title := Label.new()
	page_title.text = "Direct Front Porch Install"
	page_title.add_theme_font_size_override("font_size", 22)
	page.add_child(page_title)

	var intro := Label.new()
	intro.text = (
		"Send the active character through Front Porch's supported local Character "
		+ "Card import API. Character Card Forge never opens or modifies the Front "
		+ "Porch database. Existing conversations are left in Front Porch's care."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)

	var setup_panel := PanelContainer.new()
	page.add_child(setup_panel)
	var setup := VBoxContainer.new()
	setup.add_theme_constant_override("separation", 8)
	setup_panel.add_child(setup)

	var setup_title := Label.new()
	setup_title.text = "Connection"
	setup_title.add_theme_font_size_override("font_size", 18)
	setup.add_child(setup_title)

	var setup_hint := Label.new()
	setup_hint.text = (
		"In Front Porch: Settings → Advanced → Web Server → Enable Web Server. "
		+ "Create its web login in Front Porch first. The default address is "
		+ "http://127.0.0.1:8085."
	)
	setup_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	setup_hint.modulate = Color(0.68, 0.72, 0.82)
	setup.add_child(setup_hint)

	_front_porch_url_v0173 = _labelled_line_v0173(
		setup, "Front Porch address", "http://127.0.0.1:8085"
	)
	_front_porch_username_v0173 = _labelled_line_v0173(
		setup, "Web login username", "Front Porch web username"
	)
	_front_porch_password_v0173 = _labelled_line_v0173(
		setup, "Password — session only", "Never saved by Character Card Forge"
	)
	_front_porch_password_v0173.secret = true
	_front_porch_totp_v0173 = _labelled_line_v0173(
		setup, "Two-factor code — when enabled", "Current six-digit code"
	)
	_front_porch_totp_v0173.secret = true

	var connection_actions := HFlowContainer.new()
	connection_actions.add_theme_constant_override("separation", 8)
	setup.add_child(connection_actions)
	_front_porch_connect_v0173 = Button.new()
	_front_porch_connect_v0173.text = "Connect & Test"
	_front_porch_connect_v0173.pressed.connect(_connect_front_porch_v0173)
	connection_actions.add_child(_front_porch_connect_v0173)
	_front_porch_disconnect_v0173 = Button.new()
	_front_porch_disconnect_v0173.text = "Forget Session"
	_front_porch_disconnect_v0173.pressed.connect(_disconnect_front_porch_v0173)
	connection_actions.add_child(_front_porch_disconnect_v0173)

	_front_porch_status_v0173 = Label.new()
	_front_porch_status_v0173.text = "Not connected."
	_front_porch_status_v0173.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_porch_status_v0173.modulate = Color(0.72, 0.76, 0.86)
	setup.add_child(_front_porch_status_v0173)

	var install_panel := PanelContainer.new()
	page.add_child(install_panel)
	var install := VBoxContainer.new()
	install.add_theme_constant_override("separation", 8)
	install_panel.add_child(install)
	var install_title := Label.new()
	install_title.text = "Active Character"
	install_title.add_theme_font_size_override("font_size", 18)
	install.add_child(install_title)

	var install_hint := Label.new()
	install_hint.text = (
		"When the character has a portrait, CCF installs a real Character Card PNG "
		+ "containing both the artwork and embedded V2 metadata. Without a portrait, "
		+ "it installs the V2 JSON definition. The first request asks Front Porch to "
		+ "detect a stable-ID or name collision. "
		+ "For a name collision, choose Create Copy, Update Selected, or Cancel. "
		+ "Updating keeps Front Porch conversations but replaces that library card's authored definition."
	)
	install_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	install_hint.modulate = Color(0.68, 0.72, 0.82)
	install.add_child(install_hint)

	var artwork_label := Label.new()
	artwork_label.text = "Card artwork"
	install.add_child(artwork_label)
	_front_porch_artwork_choice_v0173 = OptionButton.new()
	_front_porch_artwork_choice_v0173.tooltip_text = (
		"Choose the image to embed in this Front Porch card. This does not change "
		+ "the character's assigned portrait."
	)
	_front_porch_artwork_choice_v0173.item_selected.connect(
		func(_item_index: int): _refresh_front_porch_artwork_status_v0173()
	)
	install.add_child(_front_porch_artwork_choice_v0173)
	_front_porch_artwork_status_v0173 = Label.new()
	_front_porch_artwork_status_v0173.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	install.add_child(_front_porch_artwork_status_v0173)

	var install_actions := HFlowContainer.new()
	install_actions.add_theme_constant_override("separation", 8)
	install.add_child(install_actions)
	_front_porch_install_v0173 = Button.new()
	_front_porch_install_v0173.text = "Install / Update Active Character"
	_front_porch_install_v0173.pressed.connect(_install_active_character_v0173)
	install_actions.add_child(_front_porch_install_v0173)
	var fallback := Button.new()
	fallback.text = "Export Portable JSON Instead…"
	fallback.tooltip_text = (
		"Always available when Front Porch is stopped, incompatible, or declines the request."
	)
	fallback.pressed.connect(_request_front_porch_fallback_v0173)
	install_actions.add_child(fallback)

	_build_front_porch_collision_panel_v0173(install)

	_front_porch_report_v0173 = RichTextLabel.new()
	_front_porch_report_v0173.bbcode_enabled = true
	_front_porch_report_v0173.fit_content = true
	_front_porch_report_v0173.custom_minimum_size.y = 110
	_front_porch_report_v0173.text = (
		"[color=#a8acbd]No direct-install request has been sent.[/color]"
	)
	install.add_child(_front_porch_report_v0173)

	var boundary := Label.new()
	boundary.text = (
		"Safety boundary: the address and username may be remembered. Passwords, "
		+ "two-factor codes, and Front Porch session cookies stay in memory only. "
		+ "No install happens automatically."
	)
	boundary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boundary.modulate = Color(0.78, 0.66, 0.48)
	page.add_child(boundary)


func _build_front_porch_collision_panel_v0173(parent: VBoxContainer) -> void:
	_front_porch_collision_panel_v0173 = VBoxContainer.new()
	_front_porch_collision_panel_v0173.add_theme_constant_override("separation", 7)
	_front_porch_collision_panel_v0173.visible = false
	parent.add_child(_front_porch_collision_panel_v0173)
	_front_porch_collision_label_v0173 = Label.new()
	_front_porch_collision_label_v0173.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_porch_collision_panel_v0173.add_child(_front_porch_collision_label_v0173)
	_front_porch_collision_choice_v0173 = OptionButton.new()
	_front_porch_collision_panel_v0173.add_child(_front_porch_collision_choice_v0173)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_front_porch_collision_panel_v0173.add_child(actions)
	_front_porch_collision_create_v0173 = Button.new()
	_front_porch_collision_create_v0173.text = "Create Copy"
	_front_porch_collision_create_v0173.pressed.connect(
		_resolve_front_porch_copy_v0173
	)
	actions.add_child(_front_porch_collision_create_v0173)
	_front_porch_collision_update_v0173 = Button.new()
	_front_porch_collision_update_v0173.text = "Update Selected"
	_front_porch_collision_update_v0173.pressed.connect(
		_resolve_front_porch_update_v0173
	)
	actions.add_child(_front_porch_collision_update_v0173)
	_front_porch_collision_cancel_v0173 = Button.new()
	_front_porch_collision_cancel_v0173.text = "Cancel"
	_front_porch_collision_cancel_v0173.pressed.connect(
		_cancel_front_porch_collision_v0173
	)
	actions.add_child(_front_porch_collision_cancel_v0173)


func _labelled_line_v0173(
	parent: VBoxContainer, label_text: String, placeholder: String
) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	parent.add_child(edit)
	return edit


func _load_front_porch_connection_v0173() -> void:
	if _front_porch_url_v0173 == null:
		return
	var saved := CCFFrontPorchInstallServiceV0173.load_connection()
	_front_porch_url_v0173.text = str(
		saved.get("base_url", CCFFrontPorchInstallServiceV0173.DEFAULT_BASE_URL)
	)
	_front_porch_username_v0173.text = str(saved.get("username", ""))
	_front_porch_client_v0173.configure(_front_porch_url_v0173.text)


func _connect_front_porch_v0173() -> void:
	if _front_porch_busy_v0173:
		return
	_set_front_porch_busy_v0173(true)
	_clear_pending_front_porch_collision_v0173()
	var configured := _front_porch_client_v0173.configure(
		_front_porch_url_v0173.text
	)
	if not bool(configured.get("ok", false)):
		_show_front_porch_connection_error_v0173(str(configured.get("error", "Invalid address.")))
		return
	_front_porch_url_v0173.text = str(configured.get("base_url", ""))
	var saved := CCFFrontPorchInstallServiceV0173.save_connection({
		"base_url": _front_porch_url_v0173.text,
		"username": _front_porch_username_v0173.text
	})
	if not bool(saved.get("ok", false)):
		_show_front_porch_connection_error_v0173(str(saved.get("error", "Could not save connection.")))
		return
	_front_porch_status_v0173.text = "Checking Front Porch…"
	var health := await _front_porch_client_v0173.detect()
	if not bool(health.get("ok", false)):
		_show_front_porch_connection_error_v0173(str(health.get("error", "Front Porch is unavailable.")))
		return
	_front_porch_version_v0173 = str(health.get("version", "unknown"))
	if bool(health.get("setup_required", false)):
		_show_front_porch_connection_error_v0173(
			(
				"Front Porch %s is running, but its web login is not configured. Open "
				+ "Front Porch in a browser and create the login there first."
			) % _front_porch_version_v0173
		)
		return
	var state := await _front_porch_client_v0173.auth_state()
	if bool(state.get("authenticated", false)):
		await _finish_front_porch_connection_v0173()
		return
	var username := _front_porch_username_v0173.text.strip_edges()
	var password := _front_porch_password_v0173.text
	var totp := _front_porch_totp_v0173.text.strip_edges()
	if username.is_empty() or password.is_empty():
		_show_front_porch_connection_error_v0173(
			"Front Porch %s is available. Enter its web username and password to connect."
			% _front_porch_version_v0173
		)
		return
	var login := await _front_porch_client_v0173.login(username, password, totp)
	_front_porch_password_v0173.text = ""
	_front_porch_totp_v0173.text = ""
	if not bool(login.get("ok", false)):
		_show_front_porch_connection_error_v0173(str(login.get("error", "Login failed.")))
		return
	await _finish_front_porch_connection_v0173()


func _finish_front_porch_connection_v0173() -> void:
	_clear_front_porch_credentials_v0173()
	var capability := await _front_porch_client_v0173.probe_character_api()
	if not bool(capability.get("ok", false)):
		_show_front_porch_connection_error_v0173(str(capability.get("error", "Character API unavailable.")))
		return
	_front_porch_connected_v0173 = true
	_set_front_porch_busy_v0173(false)
	_refresh_front_porch_install_state_v0173()
	_front_porch_status_v0173.text = (
		"Connected to Front Porch %s. Supported character import API confirmed."
		% _front_porch_version_v0173
	)
	_front_porch_report_v0173.text = (
		"[color=#8ed6a3]Connection ready.[/color] Nothing has been installed yet."
	)


func _show_front_porch_connection_error_v0173(message: String) -> void:
	_clear_front_porch_credentials_v0173()
	_front_porch_connected_v0173 = false
	_set_front_porch_busy_v0173(false)
	_refresh_front_porch_install_state_v0173()
	_front_porch_status_v0173.text = message
	_front_porch_report_v0173.text = (
		"[color=#e6c57a]%s[/color]\nPortable JSON export remains available."
		% _escape_bbcode_v0173(message)
	)


func _disconnect_front_porch_v0173() -> void:
	_front_porch_client_v0173.clear_session()
	_front_porch_connected_v0173 = false
	_clear_front_porch_credentials_v0173()
	_clear_pending_front_porch_collision_v0173()
	_refresh_front_porch_install_state_v0173()
	_front_porch_status_v0173.text = "Front Porch session forgotten. No saved password was stored."


func _clear_front_porch_credentials_v0173() -> void:
	if _front_porch_password_v0173 != null:
		_front_porch_password_v0173.text = ""
	if _front_porch_totp_v0173 != null:
		_front_porch_totp_v0173.text = ""


func _refresh_front_porch_artwork_options_v0173() -> void:
	if _front_porch_artwork_choice_v0173 == null:
		return
	var context_key := "%s:%s" % [
		str(_project.get("project_id", "")), _active_character_id
	]
	var preserve_selection := context_key == _front_porch_artwork_context_v0173
	var previous_metadata: Variant = null
	if preserve_selection and _front_porch_artwork_choice_v0173.selected >= 0:
		previous_metadata = _front_porch_artwork_choice_v0173.get_selected_metadata()
	_front_porch_artwork_choice_v0173.clear()
	_front_porch_artwork_choice_v0173.add_item("No artwork — install definition-only JSON")
	_front_porch_artwork_choice_v0173.set_item_metadata(
		0, {"kind": "json", "path": ""}
	)

	var options: Array[Dictionary] = []
	var active_portrait := _active_portrait_source_path()
	if not active_portrait.is_empty():
		options.append({
			"kind": "portrait",
			"path": active_portrait,
			"created_at": "",
			"label": "Active portrait — %s" % active_portrait.get_file()
		})
	var character := CCFStorageService.get_character(
		_project, _active_character_id
	)
	var assets_value: Variant = character.get("assets", {})
	if assets_value is Dictionary:
		var generated_value: Variant = (assets_value as Dictionary).get(
			"generated_images", []
		)
		if generated_value is Array:
			for record_value in generated_value:
				if not record_value is Dictionary:
					continue
				var record := record_value as Dictionary
				var resolved_path := _resolve_front_porch_artwork_path_v0173(
					str(record.get("path", ""))
				)
				if resolved_path.is_empty() or resolved_path == active_portrait:
					continue
				var already_listed := false
				for existing in options:
					if str(existing.get("path", "")) == resolved_path:
						already_listed = true
						break
				if already_listed:
					continue
				var created_at := str(record.get("created_at", "")).strip_edges()
				var detail := " — %s" % created_at if not created_at.is_empty() else ""
				options.append({
					"kind": "generated",
					"path": resolved_path,
					"created_at": created_at,
					"label": "Generated image — %s%s" % [resolved_path.get_file(), detail]
				})

	options.sort_custom(_front_porch_artwork_option_before_v0173)
	var selected_index := 0
	for option in options:
		_front_porch_artwork_choice_v0173.add_item(str(option.get("label", "Artwork")))
		var option_index := _front_porch_artwork_choice_v0173.item_count - 1
		_front_porch_artwork_choice_v0173.set_item_metadata(
			option_index,
			{"kind": option.get("kind", "generated"), "path": option.get("path", "")}
		)
		if selected_index == 0:
			selected_index = option_index
		if preserve_selection and previous_metadata is Dictionary:
			if str((previous_metadata as Dictionary).get("path", "")) == str(option.get("path", "")):
				selected_index = option_index
	if preserve_selection and previous_metadata is Dictionary:
		if str((previous_metadata as Dictionary).get("kind", "")) == "json":
			selected_index = 0
	_front_porch_artwork_choice_v0173.select(selected_index)
	_front_porch_artwork_context_v0173 = context_key
	_refresh_front_porch_artwork_status_v0173()


func _front_porch_artwork_option_before_v0173(
	left_option: Dictionary, right_option: Dictionary
) -> bool:
	var left_kind := str(left_option.get("kind", "generated"))
	var right_kind := str(right_option.get("kind", "generated"))
	if left_kind == "portrait":
		return right_kind != "portrait"
	if right_kind == "portrait":
		return false
	return str(left_option.get("created_at", "")) > str(
		right_option.get("created_at", "")
	)


func _resolve_front_porch_artwork_path_v0173(stored_path: String) -> String:
	var clean_path := stored_path.strip_edges()
	if clean_path.is_empty():
		return ""
	var resolved_path := clean_path
	if not clean_path.begins_with("user://") and not clean_path.is_absolute_path() and not clean_path.begins_with("res://"):
		resolved_path = CCFStorageService.project_folder(
			str(_project.get("project_id", ""))
		).path_join(clean_path)
	return resolved_path if FileAccess.file_exists(resolved_path) else ""


func _selected_front_porch_artwork_v0173() -> Dictionary:
	if _front_porch_artwork_choice_v0173 == null or _front_porch_artwork_choice_v0173.selected < 0:
		return {"kind": "json", "path": ""}
	var metadata: Variant = _front_porch_artwork_choice_v0173.get_selected_metadata()
	return (metadata as Dictionary).duplicate(true) if metadata is Dictionary else {"kind": "json", "path": ""}


func _refresh_front_porch_artwork_status_v0173() -> void:
	if _front_porch_artwork_status_v0173 == null:
		return
	var artwork := _selected_front_porch_artwork_v0173()
	var artwork_path := str(artwork.get("path", ""))
	var artwork_kind := str(artwork.get("kind", "json"))
	if artwork_path.is_empty():
		_front_porch_artwork_status_v0173.text = (
			"No artwork selected. Front Porch will receive the character definition as JSON."
		)
		_front_porch_artwork_status_v0173.modulate = Color(0.88, 0.73, 0.42)
		return
	_front_porch_artwork_status_v0173.text = (
		"Ready to embed %s as the Front Porch card artwork%s."
		% [
			artwork_path.get_file(),
			" (active portrait)" if artwork_kind == "portrait" else " (generated image)"
		]
	)
	_front_porch_artwork_status_v0173.modulate = Color(0.56, 0.84, 0.64)


func _install_active_character_v0173() -> void:
	if _front_porch_busy_v0173 or not _front_porch_connected_v0173:
		return
	project_refresh_requested.emit()
	var selected_artwork := _selected_front_porch_artwork_v0173()
	var artwork_path := str(selected_artwork.get("path", ""))
	var payload := _front_porch_install_payload_v0173(artwork_path)
	if not bool(payload.get("ok", false)):
		_show_front_porch_install_error_v0173(
			str(payload.get("error", "The Front Porch card payload could not be built."))
		)
		return
	_pending_front_porch_bytes_v0173 = payload.get("bytes", PackedByteArray())
	_pending_front_porch_filename_v0173 = str(payload.get("filename", "card.json"))
	_pending_front_porch_content_type_v0173 = str(payload.get(
		"content_type", "application/json; charset=utf-8"
	))
	_pending_front_porch_payload_label_v0173 = str(payload.get(
		"label", "Character Card JSON"
	))
	_set_front_porch_busy_v0173(true)
	_front_porch_report_v0173.text = "Sending %s to Front Porch for collision review…" % _pending_front_porch_payload_label_v0173
	var result := await _front_porch_client_v0173.install_card_bytes(
		_pending_front_porch_bytes_v0173,
		_pending_front_porch_filename_v0173,
		_pending_front_porch_content_type_v0173,
		"ask"
	)
	_set_front_porch_busy_v0173(false)
	_handle_front_porch_install_result_v0173(result, "ask")


func _front_porch_install_payload_v0173(artwork_path: String) -> Dictionary:
	var card := CCFCardFormatService.export_character_v2(
		_project, _active_character_id
	)
	if card.is_empty():
		return {"ok": false, "error": "The active character could not be found."}
	var validation := CCFCardFormatService.validate_card(card)
	var errors: Array = validation.get("errors", [])
	if not errors.is_empty():
		return {
			"ok": false,
			"error": "The card is not valid for installation: %s" % "; ".join(errors)
		}
	if not artwork_path.is_empty():
		var png_card := CCFCardFormatService.build_png_card_bytes(
			artwork_path, _project, _active_character_id
		)
		if not bool(png_card.get("ok", false)):
			return png_card
		return {
			"ok": true,
			"bytes": png_card.get("bytes", PackedByteArray()),
			"filename": CCFCardFormatService.suggested_filename(
				_project, _active_character_id, "png"
			),
			"content_type": "image/png",
			"label": "Character Card PNG with portrait"
		}
	return {
		"ok": true,
		"bytes": JSON.stringify(card, "  ").to_utf8_buffer(),
		"filename": CCFCardFormatService.suggested_filename(
			_project, _active_character_id, "json"
		),
		"content_type": "application/json; charset=utf-8",
		"label": "Character Card JSON (no portrait available)"
	}


func _resolve_front_porch_copy_v0173() -> void:
	await _send_front_porch_collision_choice_v0173("keepBoth", "")


func _resolve_front_porch_update_v0173() -> void:
	if _front_porch_collision_choice_v0173.selected < 0:
		_show_front_porch_install_error_v0173("Choose the Front Porch character to update.")
		return
	var replace_id := str(
		_front_porch_collision_choice_v0173.get_selected_metadata()
	)
	if replace_id.is_empty():
		_show_front_porch_install_error_v0173("The selected Front Porch character has no ID.")
		return
	await _send_front_porch_collision_choice_v0173("replace", replace_id)


func _send_front_porch_collision_choice_v0173(
	policy: String, replace_id: String
) -> void:
	if _front_porch_busy_v0173 or _pending_front_porch_bytes_v0173.is_empty():
		return
	_set_front_porch_busy_v0173(true)
	var result := await _front_porch_client_v0173.install_card_bytes(
		_pending_front_porch_bytes_v0173,
		_pending_front_porch_filename_v0173,
		_pending_front_porch_content_type_v0173,
		policy,
		replace_id
	)
	_set_front_porch_busy_v0173(false)
	_handle_front_porch_install_result_v0173(result, policy)


func _handle_front_porch_install_result_v0173(
	result: Dictionary, requested_policy: String
) -> void:
	if bool(result.get("ok", false)):
		var payload_label := _pending_front_porch_payload_label_v0173
		var action := "accepted"
		if bool(result.get("replaced", false)) or requested_policy == "replace":
			action = "updated"
		elif requested_policy == "keepBoth":
			action = "installed as a copy"
		var accepted_name := str(result.get("name", "Untitled Character"))
		var character_id := str(result.get("character_id", ""))
		_front_porch_report_v0173.text = (
			"[color=#8ed6a3]Front Porch %s the character.[/color]\n"
			+ "Name: %s\nFront Porch character ID: %s\nInstalled: %s\n"
			+ "Existing conversations were not edited by Character Card Forge."
		) % [
			action,
			_escape_bbcode_v0173(accepted_name),
			_escape_bbcode_v0173(character_id),
			_escape_bbcode_v0173(payload_label)
		]
		_status.text = "Front Porch %s %s." % [action, accepted_name]
		_clear_pending_front_porch_collision_v0173()
		return
	if bool(result.get("collision", false)):
		_show_front_porch_collision_v0173(result)
		return
	if bool(result.get("auth_required", false)):
		_front_porch_connected_v0173 = false
		_refresh_front_porch_install_state_v0173()
	_show_front_porch_install_error_v0173(str(result.get("error", "Front Porch declined the request.")))


func _show_front_porch_collision_v0173(result: Dictionary) -> void:
	_front_porch_collision_choice_v0173.clear()
	var existing_value: Variant = result.get("existing", [])
	if existing_value is Array:
		for candidate_value in existing_value:
			if not candidate_value is Dictionary:
				continue
			var candidate := candidate_value as Dictionary
			var candidate_id := str(candidate.get("id", ""))
			var candidate_name := str(candidate.get("name", "Untitled Character"))
			_front_porch_collision_choice_v0173.add_item(
				"%s — %s" % [candidate_name, candidate_id]
			)
			_front_porch_collision_choice_v0173.set_item_metadata(
				_front_porch_collision_choice_v0173.item_count - 1, candidate_id
			)
	_front_porch_collision_label_v0173.text = (
		"Front Porch already has a character named “%s”. Choose exactly what to do."
		% str(result.get("name", "Untitled Character"))
	)
	_front_porch_collision_update_v0173.disabled = (
		_front_porch_collision_choice_v0173.item_count == 0
	)
	_front_porch_collision_panel_v0173.visible = true
	_front_porch_report_v0173.text = (
		"[color=#e6c57a]Name collision — nothing changed yet.[/color]\n"
		+ "Create Copy adds another library card. Update Selected replaces the "
		+ "chosen authored card while Front Porch retains its conversations."
	)


func _cancel_front_porch_collision_v0173() -> void:
	_clear_pending_front_porch_collision_v0173()
	_front_porch_report_v0173.text = (
		"[color=#a8acbd]Direct install cancelled. Front Porch was not changed.[/color]"
	)


func _clear_pending_front_porch_collision_v0173() -> void:
	_pending_front_porch_bytes_v0173 = PackedByteArray()
	_pending_front_porch_filename_v0173 = ""
	_pending_front_porch_content_type_v0173 = ""
	_pending_front_porch_payload_label_v0173 = ""
	if _front_porch_collision_panel_v0173 != null:
		_front_porch_collision_panel_v0173.visible = false
	if _front_porch_collision_choice_v0173 != null:
		_front_porch_collision_choice_v0173.clear()


func _show_front_porch_install_error_v0173(message: String) -> void:
	_front_porch_report_v0173.text = (
		"[color=#ff9b9b]%s[/color]\nNo success was recorded. Export Portable JSON remains available."
		% _escape_bbcode_v0173(message)
	)
	_status.text = message


func _request_front_porch_fallback_v0173() -> void:
	_status.text = (
		"Portable Character Card V2 JSON selected. Import that file through Front Porch if direct install is unavailable."
	)
	_request_json_export()


func _set_front_porch_busy_v0173(busy: bool) -> void:
	_front_porch_busy_v0173 = busy
	if _front_porch_connect_v0173 != null:
		_front_porch_connect_v0173.disabled = busy
	if _front_porch_disconnect_v0173 != null:
		_front_porch_disconnect_v0173.disabled = busy
	if _front_porch_collision_create_v0173 != null:
		_front_porch_collision_create_v0173.disabled = busy
	if _front_porch_collision_cancel_v0173 != null:
		_front_porch_collision_cancel_v0173.disabled = busy
	_refresh_front_porch_install_state_v0173()


func _refresh_front_porch_install_state_v0173() -> void:
	if _front_porch_install_v0173 == null:
		return
	var has_character := (
		not _project.is_empty()
		and not _active_character_id.is_empty()
		and not CCFStorageService.get_character(
			_project, _active_character_id
		).is_empty()
	)
	_front_porch_install_v0173.disabled = (
		_front_porch_busy_v0173
		or not _front_porch_connected_v0173
		or not has_character
	)
	if _front_porch_collision_update_v0173 != null:
		_front_porch_collision_update_v0173.disabled = (
			_front_porch_busy_v0173
			or _front_porch_collision_choice_v0173 == null
			or _front_porch_collision_choice_v0173.item_count == 0
		)


func _escape_bbcode_v0173(value: String) -> String:
	return value.replace("[", "[​")


func front_porch_install_capabilities_v0173() -> Dictionary:
	var result := _front_porch_client_v0173.capabilities()
	result["install_tab"] = _front_porch_install_v0173 != null
	result["collision_controls"] = (
		_front_porch_collision_create_v0173 != null
		and _front_porch_collision_update_v0173 != null
		and _front_porch_collision_cancel_v0173 != null
	)
	var selected_artwork := _selected_front_porch_artwork_v0173()
	result["artwork_picker"] = _front_porch_artwork_choice_v0173 != null
	result["selected_artwork_kind"] = str(selected_artwork.get("kind", "json"))
	result["selected_artwork_available"] = not str(
		selected_artwork.get("path", "")
	).is_empty()
	result["connected"] = _front_porch_connected_v0173
	return result
