class_name CCFSupportCenterWindowV0202
extends Window

const ISSUE_TRACKER_URL := (
	"https://github.com/FrozenKangaroo/Character-Card-Forge-V2/issues/new/choose"
)

var _settings: Dictionary = {}
var _application_version := "0.20.2"
var _include_models: CheckBox
var _report_text: TextEdit
var _status: Label
var _export_dialog: FileDialog


func _ready() -> void:
	title = "Support & Diagnostics"
	size = Vector2i(900, 760)
	min_size = Vector2i(680, 520)
	force_native = true
	transient = false
	exclusive = false
	close_requested.connect(hide)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "Support & Diagnostics"
	heading.add_theme_font_size_override("font_size", 24)
	root.add_child(heading)
	var explanation := Label.new()
	explanation.text = (
		"Create a technical summary for a bug report. Character and project content, "
		+ "prompts, conversations, credentials, session data, endpoint addresses and "
		+ "file paths are always omitted. Nothing is sent automatically."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(explanation)

	_include_models = CheckBox.new()
	_include_models.text = "Include configured model identifiers"
	_include_models.tooltip_text = (
		"Off by default. Enable only when the provider/model choice is relevant to the bug."
	)
	_include_models.toggled.connect(_refresh_report.unbind(1))
	root.add_child(_include_models)

	_report_text = TextEdit.new()
	_report_text.name = "PrivacySafeSupportReportV0202"
	_report_text.editable = false
	_report_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_report_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_report_text)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var refresh := Button.new()
	refresh.text = "Refresh"
	refresh.pressed.connect(_refresh_report)
	actions.add_child(refresh)
	var copy := Button.new()
	copy.text = "Copy Support Summary"
	copy.pressed.connect(_copy_report)
	actions.add_child(copy)
	var export := Button.new()
	export.text = "Export Diagnostic Bundle…"
	export.pressed.connect(_request_export)
	actions.add_child(export)
	var issue := Button.new()
	issue.text = "Open Bug Report…"
	issue.tooltip_text = "Opens the repository issue chooser after your explicit click."
	issue.pressed.connect(_open_issue_tracker)
	actions.add_child(issue)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(hide)
	actions.add_child(close)

	_status = Label.new()
	_status.text = "Ready. Review the summary before copying or exporting it."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)

	_export_dialog = FileDialog.new()
	_export_dialog.title = "Export Privacy-Safe Diagnostic Bundle"
	_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog.filters = PackedStringArray([
		"*.json ; Character Card Forge diagnostic bundle"
	])
	_export_dialog.file_selected.connect(_save_report)
	add_child(_export_dialog)


func open_support_center(settings: Dictionary, application_version: String) -> void:
	_settings = settings.duplicate(true)
	_application_version = application_version
	_refresh_report()
	popup_centered()


func current_report_v0202() -> Dictionary:
	return CCFSupportReportServiceV0202.build_report(
		_settings, _application_version, _include_models.button_pressed
	)


func _refresh_report() -> void:
	_report_text.text = CCFSupportReportServiceV0202.report_text(
		current_report_v0202()
	)
	_status.text = "Report refreshed. Review it before sharing."


func _copy_report() -> void:
	DisplayServer.clipboard_set(_report_text.text)
	_status.text = "Privacy-safe support summary copied to the clipboard."


func _request_export() -> void:
	_export_dialog.current_file = "ccf-support-v%s.json" % _application_version
	_export_dialog.popup_centered_ratio(0.72)


func _save_report(destination_path: String) -> void:
	var target := destination_path.strip_edges()
	if target.is_empty():
		return
	if not target.to_lower().ends_with(".json"):
		target += ".json"
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		_status.text = "Could not export the diagnostic bundle. Choose another location."
		return
	file.store_string(_report_text.text)
	file.close()
	_status.text = "Privacy-safe diagnostic bundle exported."


func _open_issue_tracker() -> void:
	var open_error := OS.shell_open(ISSUE_TRACKER_URL)
	if open_error == OK:
		_status.text = "Bug report page opened. Attach or paste the report if useful."
	else:
		_status.text = "Could not open the bug report page."
