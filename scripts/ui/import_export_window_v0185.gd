class_name CCFImportExportWindowV0185
extends "res://scripts/ui/import_export_window_v0182.gd"

signal front_porch_sync_project_changed_v0185(
	project: Dictionary, active_character_id: String, message: String
)

const SYNC_SERVICE = preload(
	"res://scripts/services/front_porch_sync_service_v0185.gd"
)
const CARD_INSPECTION_SERVICE = preload(
	"res://scripts/services/card_inspection_service_v0182.gd"
)

var _sync_client: CCFFrontPorchSyncServiceV0185
var _sync_state_label: Label
var _sync_remote_choice: OptionButton
var _sync_diff: TextEdit
var _sync_diagnostic_report: TextEdit
var _sync_queue_list: ItemList
var _sync_deployment_report: TextEdit
var _sync_update_button: Button
var _sync_import_button: Button
var _sync_remove_button: Button
var _sync_queue_update_button: Button
var _sync_group_notice: Label
var _sync_source_check: CheckButton
var _sync_source_check_now: Button
var _sync_source_status: Label
var _sync_confirmation: ConfirmationDialog
var _sync_pending_action := ""
var _sync_pending_remote_id := ""
var _sync_pending_remote_card: Dictionary = {}
var _sync_pending_remote_fingerprint := ""
var _sync_busy := false


func _ready() -> void:
	super._ready()
	if _front_porch_client_v0173 != null:
		remove_child(_front_porch_client_v0173)
		_front_porch_client_v0173.queue_free()
	_sync_client = SYNC_SERVICE.new()
	add_child(_sync_client)
	_front_porch_client_v0173 = _sync_client
	var connection := CCFFrontPorchInstallServiceV0173.load_connection()
	_sync_client.configure(str(connection.get("base_url", CCFFrontPorchInstallServiceV0173.DEFAULT_BASE_URL)))
	_build_front_porch_sync_tab_v0185()
	_refresh_sync_context_v0185()


func open_for_project(
	project: Dictionary, settings: Dictionary, character_id: String
) -> void:
	super.open_for_project(project, settings, character_id)
	_refresh_sync_context_v0185()


func update_project_context(
	project: Dictionary, settings: Dictionary, character_id: String
) -> void:
	super.update_project_context(project, settings, character_id)
	_refresh_sync_context_v0185()


func _build_front_porch_sync_tab_v0185() -> void:
	var tabs := _primary_tabs_v0173()
	if tabs == null or tabs.has_node("FrontPorchSync"):
		return
	var scroll := ScrollContainer.new()
	scroll.name = "FrontPorchSync"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Front Porch Sync")
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	scroll.add_child(page)

	var title_label := Label.new()
	title_label.text = "Front Porch Connection, Sync and Deployment"
	title_label.add_theme_font_size_override("font_size", 22)
	page.add_child(title_label)
	var intro := Label.new()
	intro.text = (
		"Compare the active character with an authenticated Front Porch library card, "
		+ "then explicitly choose the direction of each change. CCF never writes the "
		+ "Front Porch database and never overwrites a card automatically."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)

	var diagnostic_panel := _sync_panel_v0185(page, "Connection Diagnostics")
	var diagnostic_hint := Label.new()
	diagnostic_hint.text = "Runs safe reachability, login, library, export and portrait checks. Passwords and session cookies are omitted from the copyable report."
	diagnostic_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostic_panel.add_child(diagnostic_hint)
	var diagnostic_actions := HFlowContainer.new()
	diagnostic_panel.add_child(diagnostic_actions)
	var run_diagnostics := Button.new()
	run_diagnostics.text = "Run Connection Diagnostics"
	run_diagnostics.pressed.connect(_run_sync_diagnostics_v0185)
	diagnostic_actions.add_child(run_diagnostics)
	var copy_diagnostics := Button.new()
	copy_diagnostics.text = "Copy Safe Report"
	copy_diagnostics.pressed.connect(func(): DisplayServer.clipboard_set(_sync_diagnostic_report.text))
	diagnostic_actions.add_child(copy_diagnostics)
	_sync_diagnostic_report = TextEdit.new()
	_sync_diagnostic_report.editable = false
	_sync_diagnostic_report.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_sync_diagnostic_report.custom_minimum_size.y = 150
	_sync_diagnostic_report.text = "Connect on the Install to Front Porch tab, then run diagnostics."
	diagnostic_panel.add_child(_sync_diagnostic_report)

	var compare_panel := _sync_panel_v0185(page, "Identity and Comparison")
	_sync_state_label = Label.new()
	_sync_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	compare_panel.add_child(_sync_state_label)
	var remote_row := HFlowContainer.new()
	compare_panel.add_child(remote_row)
	_sync_remote_choice = OptionButton.new()
	_sync_remote_choice.custom_minimum_size.x = 360
	_sync_remote_choice.item_selected.connect(func(_index: int): _clear_sync_comparison_v0185())
	remote_row.add_child(_sync_remote_choice)
	var refresh_remote := Button.new()
	refresh_remote.text = "Refresh Front Porch Library"
	refresh_remote.pressed.connect(_refresh_remote_library_v0185)
	remote_row.add_child(refresh_remote)
	var compare_button := Button.new()
	compare_button.text = "Compare Selected"
	compare_button.pressed.connect(_compare_selected_remote_v0185)
	remote_row.add_child(compare_button)
	_sync_diff = TextEdit.new()
	_sync_diff.editable = false
	_sync_diff.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_sync_diff.custom_minimum_size.y = 230
	_sync_diff.text = "Choose a Front Porch character and compare before updating or importing changes."
	compare_panel.add_child(_sync_diff)
	var change_actions := HFlowContainer.new()
	compare_panel.add_child(change_actions)
	var install_button := Button.new()
	install_button.text = "Install New"
	install_button.tooltip_text = "Uses the existing collision review; nothing is silently replaced."
	install_button.pressed.connect(_install_active_character_v0173)
	change_actions.add_child(install_button)
	_sync_update_button = Button.new()
	_sync_update_button.text = "Update / Reinstall After Preview…"
	_sync_update_button.disabled = true
	_sync_update_button.pressed.connect(func(): _confirm_sync_action_v0185("update"))
	change_actions.add_child(_sync_update_button)
	_sync_import_button = Button.new()
	_sync_import_button.text = "Import Front Porch Changes After Preview…"
	_sync_import_button.disabled = true
	_sync_import_button.pressed.connect(func(): _confirm_sync_action_v0185("import"))
	change_actions.add_child(_sync_import_button)
	_sync_remove_button = Button.new()
	_sync_remove_button.text = "Remove from Front Porch…"
	_sync_remove_button.disabled = true
	_sync_remove_button.tooltip_text = "Enabled only when Front Porch explicitly reports a supported delete endpoint."
	_sync_remove_button.pressed.connect(func(): _confirm_sync_action_v0185("remove"))
	change_actions.add_child(_sync_remove_button)

	var queue_panel := _sync_panel_v0185(page, "Sequential Deployment Queue")
	var queue_hint := Label.new()
	queue_hint.text = "Queue stores project and character IDs only. It runs one item at a time and records success, failure, skip and warning outcomes."
	queue_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	queue_panel.add_child(queue_hint)
	var queue_actions := HFlowContainer.new()
	queue_panel.add_child(queue_actions)
	var queue_install := Button.new()
	queue_install.text = "Queue Active as Install"
	queue_install.pressed.connect(func(): _queue_active_v0185("install"))
	queue_actions.add_child(queue_install)
	_sync_queue_update_button = Button.new()
	_sync_queue_update_button.text = "Queue Active as Update"
	_sync_queue_update_button.pressed.connect(func(): _queue_active_v0185("update"))
	queue_actions.add_child(_sync_queue_update_button)
	var run_queue := Button.new()
	run_queue.text = "Run Queue Sequentially"
	run_queue.pressed.connect(_run_deployment_queue_v0185)
	queue_actions.add_child(run_queue)
	var clear_queue := Button.new()
	clear_queue.text = "Clear Queue"
	clear_queue.pressed.connect(_clear_deployment_queue_v0185)
	queue_actions.add_child(clear_queue)
	_sync_queue_list = ItemList.new()
	_sync_queue_list.custom_minimum_size.y = 120
	queue_panel.add_child(_sync_queue_list)
	_sync_deployment_report = TextEdit.new()
	_sync_deployment_report.editable = false
	_sync_deployment_report.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_sync_deployment_report.custom_minimum_size.y = 180
	queue_panel.add_child(_sync_deployment_report)
	var copy_deployment := Button.new()
	copy_deployment.text = "Copy Deployment History"
	copy_deployment.pressed.connect(func(): DisplayServer.clipboard_set(_sync_deployment_report.text))
	queue_panel.add_child(copy_deployment)

	var boundaries := _sync_panel_v0185(page, "Optional Features and Safety Boundaries")
	_sync_group_notice = Label.new()
	_sync_group_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boundaries.add_child(_sync_group_notice)
	_sync_source_check = CheckButton.new()
	_sync_source_check.text = "Opt in to advisory source update checks for this imported character"
	_sync_source_check.toggled.connect(_toggle_source_updates_v0185)
	boundaries.add_child(_sync_source_check)
	_sync_source_check_now = Button.new()
	_sync_source_check_now.text = "Check Public Source Now"
	_sync_source_check_now.disabled = true
	_sync_source_check_now.tooltip_text = "Fetches only the recorded public card URL after opt-in; it never installs the result."
	_sync_source_check_now.pressed.connect(_check_public_source_now_v0185)
	boundaries.add_child(_sync_source_check_now)
	_sync_source_status = Label.new()
	_sync_source_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boundaries.add_child(_sync_source_status)

	_sync_confirmation = ConfirmationDialog.new()
	_sync_confirmation.confirmed.connect(_perform_confirmed_sync_action_v0185)
	add_child(_sync_confirmation)


func _sync_panel_v0185(parent: VBoxContainer, heading: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var title_label := Label.new()
	title_label.text = heading
	title_label.add_theme_font_size_override("font_size", 18)
	column.add_child(title_label)
	return column


func _refresh_sync_context_v0185() -> void:
	if _sync_state_label == null:
		return
	var binding := SYNC_SERVICE.binding_for_character(_project, _active_character_id)
	var current_fingerprint := SYNC_SERVICE.character_fingerprint(_project, _active_character_id)
	var state_id := SYNC_SERVICE.sync_state(current_fingerprint, str(binding.get("last_exchanged_fingerprint", "")), str(binding.get("last_remote_fingerprint", "")))
	_sync_state_label.text = "Current state: %s%s" % [SYNC_SERVICE.sync_state_label(state_id), " — Front Porch ID %s" % str(binding.get("remote_id", "")) if not str(binding.get("remote_id", "")).is_empty() else ""]
	_sync_queue_update_button.disabled = str(binding.get("remote_id", "")).is_empty()
	_sync_group_notice.text = "Group-card direct install: %s. CCF will never send a Front Porch group package through the plain character import endpoint." % ("verified by this server" if _sync_client != null and bool(_sync_client.verified_capabilities().get("group_card_import", false)) else "not advertised by this server, so unavailable")
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var source := SYNC_SERVICE.source_update_eligibility(character)
	_sync_source_check.disabled = not bool(source.get("eligible", false))
	var local_state := SYNC_SERVICE.load_local_state()
	var preferences: Dictionary = local_state.get("source_update_opt_in", {}) if local_state.get("source_update_opt_in", {}) is Dictionary else {}
	var preference_key := "%s:%s" % [str(_project.get("project_id", "")), _active_character_id]
	var opted_in := bool(preferences.get(preference_key, false)) and bool(source.get("eligible", false))
	_sync_source_check.set_pressed_no_signal(opted_in)
	_sync_source_check_now.disabled = not opted_in or str(source.get("source_url", "")).is_empty()
	_sync_source_status.text = "%s Checks are advisory and never install changes.%s" % [str(source.get("reason", "")), " A stable ID exists, but this record has no fetchable URL." if bool(source.get("eligible", false)) and str(source.get("source_url", "")).is_empty() else ""]
	_refresh_queue_ui_v0185()


func _run_sync_diagnostics_v0185() -> void:
	if _sync_busy:
		return
	_sync_busy = true
	_sync_diagnostic_report.text = "Running credential-safe checks…"
	var result := await _sync_client.run_diagnostics(_selected_remote_id_v0185())
	_sync_diagnostic_report.text = str(result.get("report", "No report returned."))
	_sync_busy = false
	_refresh_sync_context_v0185()


func _refresh_remote_library_v0185() -> void:
	if _sync_busy:
		return
	_sync_busy = true
	_sync_remote_choice.clear()
	var result := await _sync_client.list_remote_characters()
	if not bool(result.get("ok", false)):
		_sync_diff.text = str(result.get("error", "Could not load Front Porch characters."))
		_sync_busy = false
		return
	for value in result.get("characters", []):
		if not value is Dictionary:
			continue
		var row := value as Dictionary
		var remote_id := str(row.get("id", row.get("characterId", "")))
		if remote_id.is_empty():
			continue
		_sync_remote_choice.add_item("%s — %s" % [str(row.get("name", "Untitled Character")), remote_id])
		_sync_remote_choice.set_item_metadata(_sync_remote_choice.item_count - 1, remote_id)
	var binding := SYNC_SERVICE.binding_for_character(_project, _active_character_id)
	_select_remote_id_v0185(str(binding.get("remote_id", "")))
	_sync_diff.text = "%d Front Porch character(s) loaded. Select one and compare." % _sync_remote_choice.item_count
	_sync_busy = false


func _compare_selected_remote_v0185() -> void:
	var remote_id := _selected_remote_id_v0185()
	if _sync_busy or remote_id.is_empty():
		_sync_diff.text = "Choose a Front Porch character first."
		return
	_sync_busy = true
	_sync_diff.text = "Fetching the selected Front Porch card for comparison…"
	var fetched := await _sync_client.fetch_remote_card(remote_id)
	if not bool(fetched.get("ok", false)):
		_sync_diff.text = str(fetched.get("error", "Could not fetch the Front Porch card."))
		_sync_busy = false
		return
	var remote_card: Dictionary = fetched.get("card", {})
	var local_card := _front_porch_export_document_v0185(
		_project, _active_character_id
	)
	_sync_pending_remote_id = remote_id
	_sync_pending_remote_card = remote_card.duplicate(true)
	_sync_pending_remote_fingerprint = SYNC_SERVICE.card_fingerprint(remote_card)
	var differences := SYNC_SERVICE.field_differences(local_card, remote_card)
	_sync_diff.text = SYNC_SERVICE.differences_text(differences)
	_sync_update_button.disabled = false
	_sync_import_button.disabled = false
	_sync_remove_button.disabled = not bool(_sync_client.verified_capabilities().get("character_delete", false))
	var observed := SYNC_SERVICE.record_remote_observation(_project, _active_character_id, _sync_pending_remote_fingerprint)
	if bool(observed.get("ok", false)):
		_project = observed.get("project", _project)
		front_porch_sync_project_changed_v0185.emit(_project.duplicate(true), _active_character_id, "Front Porch comparison recorded; no authored fields were changed.")
	_sync_busy = false
	_refresh_sync_context_v0185()


func _clear_sync_comparison_v0185() -> void:
	_sync_pending_remote_id = ""
	_sync_pending_remote_card.clear()
	_sync_pending_remote_fingerprint = ""
	if _sync_update_button != null:
		_sync_update_button.disabled = true
		_sync_import_button.disabled = true
		_sync_remove_button.disabled = true


func _confirm_sync_action_v0185(action: String) -> void:
	if _sync_pending_remote_id.is_empty() or _sync_pending_remote_card.is_empty():
		_sync_diff.text = "Run Compare Selected before choosing a change."
		return
	_sync_pending_action = action
	_sync_confirmation.title = {"update": "Confirm Front Porch Update", "import": "Confirm Import from Front Porch", "remove": "Confirm Front Porch Removal"}.get(action, "Confirm")
	_sync_confirmation.dialog_text = {"update": "Replace the selected Front Porch card with the currently previewed CCF definition? Existing Front Porch conversations remain under Front Porch control.", "import": "Replace the active CCF authored fields with the currently previewed Front Porch card? A recoverable revision checkpoint will be created.", "remove": "Remove the selected card from Front Porch? This is available only because the server explicitly advertised the supported endpoint."}.get(action, "Continue?")
	_sync_confirmation.popup_centered()


func _perform_confirmed_sync_action_v0185() -> void:
	match _sync_pending_action:
		"update": await _update_remote_after_preview_v0185()
		"import": _import_remote_after_preview_v0185()
		"remove": await _remove_remote_after_preview_v0185()
	_sync_pending_action = ""


func _update_remote_after_preview_v0185() -> void:
	if _sync_busy:
		return
	var card := _front_porch_export_document_v0185(
		_project, _active_character_id
	)
	_sync_busy = true
	var result := await _sync_client.install_json_card(JSON.stringify(card, "  "), CCFCardFormatService.suggested_filename(_project, _active_character_id, "json"), "replace", _sync_pending_remote_id)
	_sync_busy = false
	if not bool(result.get("ok", false)):
		_sync_diff.text = str(result.get("error", "Front Porch update failed."))
		return
	_record_successful_exchange_v0185(str(result.get("character_id", _sync_pending_remote_id)), "Front Porch card updated after comparison.")


func _import_remote_after_preview_v0185() -> void:
	var cache_path := CCFStorageService.CACHE_DIR.path_join("front_porch_import_v0185.json")
	CCFStorageService.ensure_directories()
	var file := FileAccess.open(cache_path, FileAccess.WRITE)
	if file == null:
		_sync_diff.text = "Could not stage the Front Porch card for inspected import."
		return
	file.store_string(JSON.stringify(_sync_pending_remote_card, "  "))
	file.close()
	var inspection := CARD_INSPECTION_SERVICE.import_inspection(cache_path)
	if not bool(inspection.get("ok", false)):
		_sync_diff.text = str(inspection.get("error", "The Front Porch card could not be inspected."))
		return
	var applied := CARD_INSPECTION_SERVICE.apply_import_to_current_project(_project, _active_character_id, inspection, "replace")
	if not bool(applied.get("ok", false)):
		_sync_diff.text = str(applied.get("error", "The Front Porch changes could not be imported."))
		return
	_project = applied.get("project", _project)
	_record_successful_exchange_v0185(_sync_pending_remote_id, "Front Porch changes imported with a revision recovery point.", _sync_pending_remote_fingerprint)


func _remove_remote_after_preview_v0185() -> void:
	_sync_busy = true
	var result := await _sync_client.delete_remote_character(_sync_pending_remote_id)
	_sync_busy = false
	_sync_diff.text = "Front Porch character removed. The CCF project remains available." if bool(result.get("ok", false)) else str(result.get("error", "Front Porch removal failed."))
	if bool(result.get("ok", false)):
		var cleared := SYNC_SERVICE.clear_binding(_project, _active_character_id)
		if bool(cleared.get("ok", false)):
			_project = cleared.get("project", _project)
			front_porch_sync_project_changed_v0185.emit(_project.duplicate(true), _active_character_id, "Front Porch character removed and the private sync link cleared.")
		_clear_sync_comparison_v0185()
		_refresh_sync_context_v0185()


func _record_successful_exchange_v0185(remote_id: String, message: String, remote_fingerprint := "") -> void:
	var recorded := SYNC_SERVICE.record_exchange(_project, _active_character_id, remote_id, remote_fingerprint)
	if not bool(recorded.get("ok", false)):
		_sync_diff.text = "%s\nWarning: %s" % [message, str(recorded.get("error", "Could not record sync identity."))]
		return
	_project = recorded.get("project", _project)
	_sync_diff.text = message
	front_porch_sync_project_changed_v0185.emit(_project.duplicate(true), _active_character_id, message)
	_refresh_sync_context_v0185()


func _handle_front_porch_install_result_v0173(result: Dictionary, requested_policy: String) -> void:
	var succeeded := bool(result.get("ok", false))
	var remote_id := str(result.get("character_id", ""))
	super._handle_front_porch_install_result_v0173(result, requested_policy)
	if succeeded and not remote_id.is_empty():
		_record_successful_exchange_v0185(remote_id, "Front Porch install identity and exchange fingerprint recorded.")


func _queue_active_v0185(action: String) -> void:
	var binding := SYNC_SERVICE.binding_for_character(_project, _active_character_id)
	var result := SYNC_SERVICE.enqueue_deployment({"project_id": str(_project.get("project_id", "")), "character_id": _active_character_id, "action": action, "remote_id": str(binding.get("remote_id", ""))})
	_sync_deployment_report.text = "Queued active character for %s." % action if bool(result.get("ok", false)) else str(result.get("error", "Could not queue deployment."))
	_refresh_queue_ui_v0185()


func _clear_deployment_queue_v0185() -> void:
	SYNC_SERVICE.replace_deployment_queue([])
	_refresh_queue_ui_v0185()


func _run_deployment_queue_v0185() -> void:
	if _sync_busy:
		return
	var queue := SYNC_SERVICE.deployment_queue()
	if queue.is_empty():
		_sync_deployment_report.text = "The deployment queue is empty."
		return
	_sync_busy = true
	var outcomes: Array[Dictionary] = []
	for item in queue:
		var project_id := str(item.get("project_id", ""))
		var character_id := str(item.get("character_id", ""))
		var loaded := CCFStorageService.load_project(project_id)
		if not bool(loaded.get("ok", false)):
			outcomes.append({"status": "failed", "name": project_id, "message": str(loaded.get("error", "Project unavailable."))})
			continue
		var project: Dictionary = loaded.get("data", {})
		var character := CCFStorageService.get_character(project, character_id)
		var character_name := CCFStorageService.character_display_name(character)
		var card := _front_porch_export_document_v0185(
			project, character_id
		)
		if card.is_empty():
			outcomes.append({"status": "failed", "name": character_name, "message": "Character card could not be built."})
			continue
		var action := str(item.get("action", "install"))
		var policy := "replace" if action == "update" else "ask"
		var remote_id := str(item.get("remote_id", ""))
		var result := await _sync_client.install_json_card(JSON.stringify(card, "  "), CCFCardFormatService.suggested_filename(project, character_id, "json"), policy, remote_id)
		if bool(result.get("ok", false)):
			var exchanged := SYNC_SERVICE.record_exchange(project, character_id, str(result.get("character_id", remote_id)))
			if bool(exchanged.get("ok", false)):
				var saved := CCFStorageService.save_project(exchanged.get("project", project))
				outcomes.append({"status": "success" if bool(saved.get("ok", false)) else "warning", "name": character_name, "message": "%s completed." % action.capitalize() if bool(saved.get("ok", false)) else "Front Porch changed, but local sync identity could not be saved."})
			else:
				outcomes.append({"status": "warning", "name": character_name, "message": "Front Porch changed, but local sync identity could not be recorded."})
		elif bool(result.get("collision", false)):
			outcomes.append({"status": "skipped", "name": character_name, "message": "Collision requires individual review; nothing was overwritten."})
		else:
			outcomes.append({"status": "failed", "name": character_name, "message": str(result.get("error", "Front Porch declined the deployment."))})
	SYNC_SERVICE.replace_deployment_queue([])
	SYNC_SERVICE.append_deployment_report({"summary": "%d queued item(s) completed" % queue.size(), "outcomes": outcomes})
	_sync_busy = false
	_refresh_queue_ui_v0185()


func _front_porch_export_document_v0185(
	project: Dictionary, character_id: String
) -> Dictionary:
	return CCFCardFormatService.export_character_v2(project, character_id)


func _refresh_queue_ui_v0185() -> void:
	if _sync_queue_list == null:
		return
	_sync_queue_list.clear()
	for item in SYNC_SERVICE.deployment_queue():
		_sync_queue_list.add_item("%s — %s / %s" % [str(item.get("action", "install")).capitalize(), str(item.get("project_id", "")), str(item.get("character_id", ""))])
	_sync_deployment_report.text = SYNC_SERVICE.deployment_report_text()


func _toggle_source_updates_v0185(enabled: bool) -> void:
	var state := SYNC_SERVICE.load_local_state()
	var preferences: Dictionary = state.get("source_update_opt_in", {}).duplicate(true)
	var key := "%s:%s" % [str(_project.get("project_id", "")), _active_character_id]
	preferences[key] = enabled
	state["source_update_opt_in"] = preferences
	SYNC_SERVICE.save_local_state(state)
	_sync_source_status.text = "Advisory source checks opted in; no update will be installed automatically." if enabled else "Advisory source checks are off."
	_refresh_sync_context_v0185()


func _check_public_source_now_v0185() -> void:
	if _sync_busy or not _sync_source_check.button_pressed:
		return
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var eligibility := SYNC_SERVICE.source_update_eligibility(character)
	var source_url := str(eligibility.get("source_url", ""))
	if source_url.is_empty():
		_sync_source_status.text = "This source has no fetchable public URL."
		return
	_sync_busy = true
	_sync_source_status.text = "Checking the recorded public source…"
	var result := await _sync_client.check_public_source_update(
		source_url,
		SYNC_SERVICE.character_fingerprint(_project, _active_character_id)
	)
	_sync_busy = false
	if not bool(result.get("ok", false)):
		_sync_source_status.text = str(result.get("error", "The public source check failed."))
		return
	_sync_source_status.text = (
		"A different public-source version is available. Review it through an explicit import; nothing was changed."
		if bool(result.get("update_available", false))
		else "The public source matches the current authored card."
	)


func _selected_remote_id_v0185() -> String:
	if _sync_remote_choice == null or _sync_remote_choice.selected < 0:
		return ""
	return str(_sync_remote_choice.get_selected_metadata())


func _select_remote_id_v0185(remote_id: String) -> void:
	if remote_id.is_empty():
		return
	for index in range(_sync_remote_choice.item_count):
		if str(_sync_remote_choice.get_item_metadata(index)) == remote_id:
			_sync_remote_choice.select(index)
			return


func front_porch_sync_capabilities_v0185() -> Dictionary:
	var result := SYNC_SERVICE.capabilities_v0185()
	result["sync_tab"] = _sync_diff != null
	result["diagnostic_report"] = _sync_diagnostic_report != null
	result["queue_ui"] = _sync_queue_list != null
	result["compare_required_for_update"] = _sync_update_button != null and _sync_update_button.disabled
	return result
