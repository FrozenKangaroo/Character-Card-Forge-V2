class_name CCFCardInspectorWindowV0182
extends Window

signal project_changed_v0182(
	project: Dictionary, active_character_id: String, message: String
)

const INSPECTION_SERVICE = preload(
	"res://scripts/services/card_inspection_service_v0182.gd"
)

var _project_data: Dictionary = {}
var _character_id := ""
var _health_tree: Tree
var _health_summary: Label
var _token_tree: Tree
var _token_summary: Label
var _compiled_prompt: TextEdit
var _metadata_view: TextEdit
var _raw_editor: TextEdit
var _raw_status: Label
var _raw_confirm: ConfirmationDialog
var _pending_raw_text := ""
var _asset_tree: Tree
var _asset_status: Label
var _relink_dialog: FileDialog
var _selected_missing_asset: Dictionary = {}
var _group_replacement_selector: OptionButton
var _checklist_tree: Tree
var _manual_review: CheckBox
var _test_complete: CheckBox
var _token_limit: SpinBox
var _checklist_summary: Label


func _ready() -> void:
	title = "Card Inspector"
	size = Vector2i(1180, 820)
	min_size = Vector2i(900, 650)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(hide)
	_build_ui()
	_build_dialogs()
	hide()


func open_for_character(project: Dictionary, character_id: String) -> void:
	_project_data = project.duplicate(true)
	_character_id = character_id
	_refresh_all()
	popup_centered()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)
	var heading := Label.new()
	heading.text = "Card Health, Tokens and Interchange Inspector"
	heading.add_theme_font_size_override("font_size", 22)
	page.add_child(heading)
	var intro := Label.new()
	intro.text = (
		"Inspect without changing the card. Health findings are advisory. Expert Raw "
		+ "JSON and asset repairs require explicit review and create revision recovery points."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(tabs)
	_build_health_tab(tabs)
	_build_tokens_tab(tabs)
	_build_metadata_tab(tabs)
	_build_raw_tab(tabs)
	_build_assets_tab(tabs)
	_build_checklist_tab(tabs)


func _build_health_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Health"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Health")
	_health_summary = Label.new()
	_health_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_health_summary)
	_health_tree = Tree.new()
	_health_tree.columns = 4
	_health_tree.column_titles_visible = true
	_health_tree.set_column_title(0, "Severity")
	_health_tree.set_column_title(1, "Field")
	_health_tree.set_column_title(2, "Finding")
	_health_tree.set_column_title(3, "Code")
	_health_tree.set_column_expand(2, true)
	_health_tree.hide_root = true
	_health_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_health_tree)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh Health Check"
	refresh_button.pressed.connect(_refresh_health)
	page.add_child(refresh_button)


func _build_tokens_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "TokensPrompt"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Tokens & Prompt")
	_token_summary = Label.new()
	_token_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_token_summary)
	var split := VSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(split)
	_token_tree = Tree.new()
	_token_tree.columns = 4
	_token_tree.column_titles_visible = true
	_token_tree.set_column_title(0, "Section")
	_token_tree.set_column_title(1, "Characters")
	_token_tree.set_column_title(2, "Estimated tokens")
	_token_tree.set_column_title(3, "Source")
	_token_tree.hide_root = true
	_token_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(_token_tree)
	_compiled_prompt = TextEdit.new()
	_compiled_prompt.editable = false
	_compiled_prompt.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_compiled_prompt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(_compiled_prompt)


func _build_metadata_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Metadata"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Technical Metadata")
	var notice := Label.new()
	notice.text = (
		"Read-only technical identity, source format, extension and revision information. "
		+ "Use Raw JSON only when normal editors cannot represent an intentional value."
	)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(notice)
	_metadata_view = TextEdit.new()
	_metadata_view.editable = false
	_metadata_view.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_metadata_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_metadata_view)


func _build_raw_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "RawJSON"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Expert Raw JSON")
	var warning := Label.new()
	warning.text = (
		"Expert mode. Revision history and private lineage are intentionally hidden "
		+ "and preserved by CCF. Validate first; Apply requires a second confirmation."
	)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.modulate = Color(0.94, 0.72, 0.38)
	page.add_child(warning)
	_raw_editor = TextEdit.new()
	_raw_editor.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	_raw_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_raw_editor)
	var actions := HBoxContainer.new()
	page.add_child(actions)
	var validate_button := Button.new()
	validate_button.text = "Validate JSON"
	validate_button.pressed.connect(_validate_raw)
	actions.add_child(validate_button)
	var reload_button := Button.new()
	reload_button.text = "Reload Current"
	reload_button.pressed.connect(_reload_raw)
	actions.add_child(reload_button)
	var apply_button := Button.new()
	apply_button.text = "Review and Apply…"
	apply_button.pressed.connect(_request_raw_apply)
	actions.add_child(apply_button)
	_raw_status = Label.new()
	_raw_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_raw_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(_raw_status)


func _build_assets_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "MissingAssets"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Missing Assets")
	_asset_status = Label.new()
	_asset_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_asset_status)
	_asset_tree = Tree.new()
	_asset_tree.columns = 3
	_asset_tree.column_titles_visible = true
	_asset_tree.set_column_title(0, "Kind")
	_asset_tree.set_column_title(1, "Stored reference")
	_asset_tree.set_column_title(2, "Resolved location")
	_asset_tree.set_column_expand(1, true)
	_asset_tree.set_column_expand(2, true)
	_asset_tree.hide_root = true
	_asset_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_asset_tree)
	var actions := HBoxContainer.new()
	page.add_child(actions)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh Missing Assets"
	refresh_button.pressed.connect(_refresh_assets)
	actions.add_child(refresh_button)
	var relink_button := Button.new()
	relink_button.text = "Relink Selected…"
	relink_button.pressed.connect(_request_relink)
	actions.add_child(relink_button)
	_group_replacement_selector = OptionButton.new()
	_group_replacement_selector.tooltip_text = "Replacement character for a selected missing group member."
	_group_replacement_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_group_replacement_selector)
	var repair_member_button := Button.new()
	repair_member_button.text = "Repair Group Member"
	repair_member_button.pressed.connect(_repair_group_member)
	actions.add_child(repair_member_button)


func _build_checklist_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Checklist"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Quality Checklist")
	var intro := Label.new()
	intro.text = (
		"Choose which checks matter for this character. These are private workflow "
		+ "preferences and do not block export or enter Character Card metadata."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)
	_checklist_tree = Tree.new()
	_checklist_tree.columns = 3
	_checklist_tree.column_titles_visible = true
	_checklist_tree.set_column_title(0, "Use")
	_checklist_tree.set_column_title(1, "Check")
	_checklist_tree.set_column_title(2, "Status")
	_checklist_tree.set_column_expand(1, true)
	_checklist_tree.hide_root = true
	_checklist_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_checklist_tree)
	var settings_row := HFlowContainer.new()
	page.add_child(settings_row)
	_manual_review = CheckBox.new()
	_manual_review.text = "Manual review complete"
	settings_row.add_child(_manual_review)
	_test_complete = CheckBox.new()
	_test_complete.text = "Optional roleplay test complete"
	settings_row.add_child(_test_complete)
	settings_row.add_child(_label("Token checklist limit"))
	_token_limit = SpinBox.new()
	_token_limit.min_value = 256
	_token_limit.max_value = 1000000
	_token_limit.step = 256
	settings_row.add_child(_token_limit)
	var save_button := Button.new()
	save_button.text = "Save Checklist"
	save_button.pressed.connect(_save_checklist)
	settings_row.add_child(save_button)
	_checklist_summary = Label.new()
	_checklist_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_checklist_summary)


func _build_dialogs() -> void:
	_raw_confirm = ConfirmationDialog.new()
	_raw_confirm.title = "Apply validated Raw JSON"
	_raw_confirm.dialog_text = (
		"Apply the validated Raw JSON to this character? CCF will create a recovery "
		+ "checkpoint first and preserve private revision history."
	)
	_raw_confirm.confirmed.connect(_apply_raw)
	add_child(_raw_confirm)
	_relink_dialog = FileDialog.new()
	_relink_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_relink_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_relink_dialog.file_selected.connect(_relink_selected)
	add_child(_relink_dialog)


func _refresh_all() -> void:
	_refresh_health()
	_refresh_tokens()
	_metadata_view.text = JSON.stringify(
		INSPECTION_SERVICE.technical_metadata(_project_data, _character_id), "  "
	)
	_reload_raw()
	_refresh_assets()
	_refresh_checklist()


func _refresh_health() -> void:
	var report := INSPECTION_SERVICE.health_report(_project_data, _character_id)
	_health_tree.clear()
	var root := _health_tree.create_item()
	for finding in report.get("findings", []):
		var item := _health_tree.create_item(root)
		item.set_text(0, str(finding.get("severity", "info")).capitalize())
		item.set_text(1, str(finding.get("path", "")))
		item.set_text(2, str(finding.get("message", "")))
		item.set_text(3, str(finding.get("code", "")))
	_health_summary.text = str(report.get("summary", "Health check unavailable."))


func _refresh_tokens() -> void:
	var report := INSPECTION_SERVICE.token_report(_project_data, _character_id)
	_token_tree.clear()
	var root := _token_tree.create_item()
	for section in report.get("sections", []):
		var item := _token_tree.create_item(root)
		item.set_text(0, str(section.get("label", "Section")))
		item.set_text(1, str(section.get("characters", 0)))
		item.set_text(2, str(section.get("tokens", 0)))
		item.set_text(3, str(section.get("path", "")))
	_token_summary.text = "Approximately %d authored tokens. %s" % [
		int(report.get("total_tokens", 0)), str(report.get("notice", ""))
	]
	var prompt := INSPECTION_SERVICE.compiled_prompt_preview(
		_project_data, _character_id
	)
	_compiled_prompt.text = str(prompt.get("text", prompt.get("error", "")))


func _reload_raw() -> void:
	_raw_editor.text = INSPECTION_SERVICE.raw_character_json(
		_project_data, _character_id
	)
	_raw_status.text = "Loaded the current editable character JSON."


func _validate_raw() -> Dictionary:
	var result := INSPECTION_SERVICE.validate_raw_character_json(
		_raw_editor.text, _character_id
	)
	if bool(result.get("ok", false)):
		var warning_count: int = result.get("warnings", []).size()
		_raw_status.text = "Valid character JSON%s." % (
			" with %d warning(s)" % warning_count if warning_count > 0 else ""
		)
	else:
		_raw_status.text = "Validation failed: %s" % "; ".join(result.get("errors", []))
	return result


func _request_raw_apply() -> void:
	var validation := _validate_raw()
	if not bool(validation.get("ok", false)):
		return
	_pending_raw_text = _raw_editor.text
	_raw_confirm.popup_centered()


func _apply_raw() -> void:
	var result := INSPECTION_SERVICE.apply_raw_character_json(
		_project_data, _character_id, _pending_raw_text
	)
	_pending_raw_text = ""
	if not bool(result.get("ok", false)):
		_raw_status.text = "Apply failed: %s" % "; ".join(result.get("errors", []))
		return
	_project_data = result.get("project", {}).duplicate(true)
	_emit_change("Validated Raw JSON applied with a recovery checkpoint.")
	_refresh_all()


func _refresh_assets() -> void:
	var report := INSPECTION_SERVICE.missing_asset_report(
		_project_data, _character_id
	)
	_asset_tree.clear()
	_group_replacement_selector.clear()
	for character_value in _project_data.get("characters", []):
		if not character_value is Dictionary:
			continue
		var candidate: Dictionary = character_value
		_group_replacement_selector.add_item(
			CCFStorageService.character_display_name(candidate)
		)
		_group_replacement_selector.set_item_metadata(
			_group_replacement_selector.item_count - 1,
			str(candidate.get("character_id", ""))
		)
	var root := _asset_tree.create_item()
	for missing_item in report.get("missing", []):
		var item := _asset_tree.create_item(root)
		item.set_text(0, str(missing_item.get("kind", "asset")).replace("_", " ").capitalize())
		item.set_text(1, str(missing_item.get("stored_path", "")))
		item.set_text(2, str(missing_item.get("resolved_path", "")))
		item.set_metadata(0, missing_item.duplicate(true))
	_asset_status.text = (
		"No missing file references found."
		if report.get("missing", []).is_empty()
		else "%d missing file reference(s) found. Select one to relink it."
		% report.get("missing", []).size()
	)


func _request_relink() -> void:
	var item := _asset_tree.get_selected()
	if item == null or not item.get_metadata(0) is Dictionary:
		_asset_status.text = "Select a missing asset row first."
		return
	_selected_missing_asset = (item.get_metadata(0) as Dictionary).duplicate(true)
	if str(_selected_missing_asset.get("kind", "")) == "group_member":
		_asset_status.text = "Choose a replacement character, then use Repair Group Member."
		return
	_relink_dialog.popup_centered_ratio(0.72)


func _repair_group_member() -> void:
	var item := _asset_tree.get_selected()
	if item == null or not item.get_metadata(0) is Dictionary:
		_asset_status.text = "Select a missing group member row first."
		return
	var missing_item: Dictionary = (item.get_metadata(0) as Dictionary).duplicate(true)
	if str(missing_item.get("kind", "")) != "group_member":
		_asset_status.text = "The selected row is a file. Use Relink Selected instead."
		return
	if _group_replacement_selector.item_count == 0:
		_asset_status.text = "No replacement character is available in this project."
		return
	var replacement_id := str(_group_replacement_selector.get_selected_metadata())
	var result := INSPECTION_SERVICE.repair_group_member(
		_project_data, missing_item, replacement_id
	)
	if not bool(result.get("ok", false)):
		_asset_status.text = str(result.get("error", "Could not repair group member."))
		return
	_project_data = result.get("project", {}).duplicate(true)
	_emit_change("Missing group member reference repaired after explicit selection.")
	_refresh_all()


func _relink_selected(replacement_path: String) -> void:
	var result := INSPECTION_SERVICE.relink_asset(
		_project_data, _character_id, _selected_missing_asset, replacement_path
	)
	if not bool(result.get("ok", false)):
		_asset_status.text = str(result.get("error", "Could not relink asset."))
		return
	_project_data = result.get("project", {}).duplicate(true)
	_selected_missing_asset.clear()
	_emit_change("Missing asset relinked with a recovery checkpoint.")
	_refresh_all()


func _refresh_checklist() -> void:
	var report := INSPECTION_SERVICE.checklist_report(
		_project_data, _character_id
	)
	var settings: Dictionary = report.get("settings", {})
	_manual_review.button_pressed = bool(settings.get("manual_review_complete", false))
	_test_complete.button_pressed = bool(settings.get("test_complete", false))
	_token_limit.value = int(settings.get("token_limit", INSPECTION_SERVICE.TOTAL_WARNING_TOKENS))
	_checklist_tree.clear()
	var root := _checklist_tree.create_item()
	for checklist_item in report.get("items", []):
		var item := _checklist_tree.create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_checked(0, bool(checklist_item.get("enabled", true)))
		item.set_text(1, str(checklist_item.get("label", "Check")))
		item.set_text(2, "Passed" if bool(checklist_item.get("passed", false)) else "Needs attention")
		item.set_tooltip_text(1, str(checklist_item.get("detail", "")))
		item.set_metadata(0, str(checklist_item.get("id", "")))
	_checklist_summary.text = "%d of %d enabled checks pass%s." % [
		int(report.get("passed_count", 0)),
		int(report.get("enabled_count", 0)),
		" — checklist complete" if bool(report.get("complete", false)) else ""
	]


func _save_checklist() -> void:
	var character_record := CCFStorageService.get_character(
		_project_data, _character_id
	)
	var settings := INSPECTION_SERVICE.checklist_settings(character_record)
	var enabled: Dictionary = {}
	var root := _checklist_tree.get_root()
	var item := root.get_first_child() if root != null else null
	while item != null:
		enabled[str(item.get_metadata(0))] = item.is_checked(0)
		item = item.get_next()
	settings["enabled"] = enabled
	settings["manual_review_complete"] = _manual_review.button_pressed
	settings["test_complete"] = _test_complete.button_pressed
	settings["token_limit"] = int(_token_limit.value)
	var result := INSPECTION_SERVICE.save_checklist_settings(
		_project_data, _character_id, settings
	)
	if not bool(result.get("ok", false)):
		_checklist_summary.text = str(result.get("error", "Could not save checklist."))
		return
	_project_data = result.get("project", {}).duplicate(true)
	_emit_change("Private quality checklist saved.")
	_refresh_checklist()


func _emit_change(message_text: String) -> void:
	project_changed_v0182.emit(
		_project_data.duplicate(true), _character_id, message_text
	)


func _label(label_text: String) -> Label:
	var result := Label.new()
	result.text = label_text
	return result
