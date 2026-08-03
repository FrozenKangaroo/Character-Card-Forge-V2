class_name CCFGenerationDiagnosticsWindowV01522
extends Window

var _bundle: Dictionary = {}
var _overview: TextEdit
var _request: TextEdit
var _raw_response: TextEdit
var _assistant_text: TextEdit
var _parsed_output: TextEdit
var _validation: TextEdit
var _repair: TextEdit
var _events: TextEdit
var _status: Label
var _save_dialog: FileDialog


func _ready() -> void:
	visible = false
	title = "Character Card Forge — Generation Diagnostics"
	size = Vector2i(1080, 780)
	min_size = Vector2i(760, 540)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(hide)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "Generation Diagnostics"
	heading.add_theme_font_size_override("font_size", 22)
	root.add_child(heading)

	var hint := Label.new()
	hint.text = "Failure evidence is kept exactly where useful: request payload, raw provider response, extracted assistant text, parsing/validation details, and repair history. Authentication headers and credential fields are redacted."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.68, 0.71, 0.8)
	root.add_child(hint)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	_overview = _add_text_tab(tabs, "Overview")
	_request = _add_text_tab(tabs, "Request")
	_raw_response = _add_text_tab(tabs, "Raw API Response")
	_assistant_text = _add_text_tab(tabs, "Assistant Text")
	_parsed_output = _add_text_tab(tabs, "Parsed Output")
	_validation = _add_text_tab(tabs, "Validation")
	_repair = _add_text_tab(tabs, "Repair")
	_events = _add_text_tab(tabs, "Full Trace")

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var copy_button := Button.new()
	copy_button.text = "Copy Full Diagnostic"
	copy_button.pressed.connect(_copy_bundle)
	actions.add_child(copy_button)
	var save_button := Button.new()
	save_button.text = "Save Diagnostic Bundle…"
	save_button.pressed.connect(_open_save_dialog)
	actions.add_child(save_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	_status = Label.new()
	_status.modulate = Color(0.66, 0.7, 0.8)
	actions.add_child(_status)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide)
	actions.add_child(close_button)

	_save_dialog = FileDialog.new()
	_save_dialog.visible = false
	_save_dialog.title = "Save Generation Diagnostic Bundle"
	_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_save_dialog.filters = PackedStringArray(["*.json ; JSON diagnostic bundle"])
	_save_dialog.file_selected.connect(_save_bundle)
	add_child(_save_dialog)


func show_diagnostics(bundle: Dictionary) -> void:
	_bundle = bundle.duplicate(true)
	var section := str(_bundle.get("active_section", "")).strip_edges()
	var overview_lines: Array[String] = []
	overview_lines.append("Failure: %s" % str(_bundle.get("failure_reason", "Unknown generation failure.")))
	overview_lines.append("Stage: %s" % str(_bundle.get("failure_stage", "unknown")))
	if not section.is_empty():
		overview_lines.append("Section: %s" % section)
	overview_lines.append("Job: %s (%s)" % [str(_bundle.get("job_id", "")), str(_bundle.get("job_type", ""))])
	overview_lines.append("Generation strategy: %s" % str(_bundle.get("generation_strategy", "")))
	var provider_value: Variant = _bundle.get("provider", {})
	if provider_value is Dictionary:
		overview_lines.append("Provider profile: %s" % str(provider_value.get("profile_name", "")))
		overview_lines.append("Model: %s" % str(provider_value.get("model", "")))
	overview_lines.append("Captured: %s" % str(_bundle.get("captured_at", "")))
	_overview.text = "\n".join(overview_lines)
	_request.text = _pretty(_bundle.get("request", {}))
	_raw_response.text = str(_bundle.get("raw_api_response", ""))
	if _raw_response.text.is_empty():
		_raw_response.text = "No raw response body was available."
	_assistant_text.text = str(_bundle.get("extracted_assistant_text", ""))
	if _assistant_text.text.is_empty():
		_assistant_text.text = "No assistant text was extracted from the provider response."
	_parsed_output.text = _pretty(_bundle.get("parsed_output", null))
	var parse_error := str(_bundle.get("parse_error", "")).strip_edges()
	if not parse_error.is_empty():
		_parsed_output.text = "PARSE ERROR:\n%s\n\nPARSED OUTPUT:\n%s" % [parse_error, _parsed_output.text]
	_validation.text = _pretty(_bundle.get("validation_report", {}))
	_repair.text = _pretty(_bundle.get("repair", {}))
	_events.text = _pretty(_bundle.get("events", []))
	_status.text = "Credentials are redacted."
	title = "Generation Diagnostics — %s" % str(_bundle.get("label", "Failed generation"))
	popup_centered(Vector2i(1080, 780))


func _add_text_tab(tabs: TabContainer, tab_title: String) -> TextEdit:
	var edit := TextEdit.new()
	edit.name = tab_title
	edit.editable = false
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(edit)
	tabs.set_tab_title(tabs.get_tab_count() - 1, tab_title)
	return edit


func _copy_bundle() -> void:
	if _bundle.is_empty():
		return
	DisplayServer.clipboard_set(JSON.stringify(_bundle, "  "))
	_status.text = "Full diagnostic copied to clipboard."


func _open_save_dialog() -> void:
	if _bundle.is_empty():
		return
	var suggested := "ccf_generation_diagnostic_%s.json" % str(_bundle.get("job_id", "failed"))
	_save_dialog.current_file = suggested
	_save_dialog.popup_centered_ratio(0.75)


func _save_bundle(path: String) -> void:
	var target := path.strip_edges()
	if target.is_empty():
		return
	if not target.to_lower().ends_with(".json"):
		target += ".json"
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		_status.text = "Could not save the diagnostic bundle."
		return
	file.store_string(JSON.stringify(_bundle, "  "))
	file.close()
	_status.text = "Diagnostic bundle saved."


func _pretty(value: Variant) -> String:
	if value == null:
		return "null"
	if value is String:
		return value
	return JSON.stringify(value, "  ")
