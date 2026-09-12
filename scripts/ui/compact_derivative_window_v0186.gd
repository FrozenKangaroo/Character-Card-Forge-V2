class_name CCFCompactDerivativeWindowV0186
extends Window

signal generation_requested_v0186(options: Dictionary)
signal project_changed_v0186(
	project: Dictionary, active_character_id: String, message: String
)

const DERIVATIVE_SERVICE = preload(
	"res://scripts/services/compact_derivative_service_v0186.gd"
)

var _project_data: Dictionary = {}
var _source_character_id := ""
var _active_job_id := ""
var _source_hash := ""
var _request_metadata: Dictionary = {}
var _candidate: Dictionary = {}
var _source_tokens := 0

var _name_edit: LineEdit
var _level: OptionButton
var _target_tokens: SpinBox
var _preservation: Dictionary = {}
var _source_stats: Label
var _summary: TextEdit
var _comparison_list: VBoxContainer
var _comparison_rows: Array[Dictionary] = []
var _generate_button: Button
var _create_button: Button
var _status: Label
var _confirm: ConfirmationDialog


func _ready() -> void:
	title = "Create Compact/Lite Derivative"
	size = Vector2i(1280, 880)
	min_size = Vector2i(980, 700)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(hide)
	_build_ui()
	_build_confirmation()
	hide()


func open_for_character(project: Dictionary, character_id: String) -> void:
	_project_data = project.duplicate(true)
	_source_character_id = character_id
	_active_job_id = ""
	_candidate.clear()
	_source_hash = DERIVATIVE_SERVICE.source_content_hash(
		_project_data, _source_character_id
	)
	_source_tokens = DERIVATIVE_SERVICE.estimated_tokens(
		_project_data, _source_character_id
	)
	var source := CCFStorageService.get_character(
		_project_data, _source_character_id
	)
	_name_edit.text = "%s (Compact)" % CCFStorageService.character_display_name(source)
	var options := DERIVATIVE_SERVICE.default_options(
		_project_data, _source_character_id
	)
	_select_level(str(options.get("compression_level", "balanced")))
	_target_tokens.value = int(options.get("target_tokens", 1000))
	for key in _preservation.keys():
		(_preservation[key] as CheckBox).button_pressed = bool(options.get(key, true))
	_source_stats.text = (
		"Source estimate: ~%d authored tokens • Target: ~%d tokens"
		% [_source_tokens, int(_target_tokens.value)]
	)
	_summary.text = "Generate a preview to compare every compacted field. The source character will remain unchanged."
	_clear_comparison()
	_generate_button.disabled = not bool(
		CCFCardFormatService.export_safety_report(
			_project_data, _source_character_id
		).get("can_export", false)
	)
	_create_button.disabled = true
	_status.text = (
		"Ready to generate a separate derivative."
		if not _generate_button.disabled
		else "Complete at least one core authored field before creating a derivative."
	)
	popup_centered()


func owns_project(project_id: String) -> bool:
	return (
		not _project_data.is_empty()
		and str(_project_data.get("project_id", "")) == project_id
	)


func update_project_context(project: Dictionary, character_id: String) -> void:
	if not owns_project(str(project.get("project_id", ""))):
		return
	_project_data = project.duplicate(true)
	if character_id != _source_character_id:
		hide()


func begin_generation(job_id: String) -> void:
	_active_job_id = job_id
	_generate_button.disabled = true
	_create_button.disabled = true
	_status.text = "Generating compact preview… The source remains unchanged."


func handle_job_completed(
	job_id: String, data: Variant, metadata: Dictionary
) -> bool:
	if job_id != _active_job_id:
		return false
	_active_job_id = ""
	_generate_button.disabled = false
	if str(metadata.get("source_hash", "")) != DERIVATIVE_SERVICE.source_content_hash(
		_project_data, _source_character_id
	):
		_status.text = "The source changed while generation was running. This preview was discarded."
		return true
	var options_value: Variant = metadata.get("compact_options", current_options())
	var options: Dictionary = options_value if options_value is Dictionary else current_options()
	var validated := DERIVATIVE_SERVICE.validate_result(
		_project_data, _source_character_id, data, options
	)
	if not bool(validated.get("ok", false)):
		_status.text = str(validated.get("error", "The compact preview was unusable."))
		return true
	_candidate = validated.get("candidate", {}).duplicate(true)
	_source_hash = str(validated.get("source_hash", ""))
	_request_metadata = metadata.duplicate(true)
	_rebuild_comparison()
	_summary.text = "%s\n\nEstimated result: ~%d tokens; requested target: ~%d. Token counts are approximate and editable content is not saved yet." % [
		str(validated.get("summary", "Compact preview generated.")),
		int(validated.get("after_tokens", 0)),
		int(options.get("target_tokens", 0))
	]
	_create_button.disabled = false
	_status.text = "Preview ready. Review every field and edit or deselect compact replacements before creating the new character."
	return true


func handle_job_failed(job_id: String, message: String) -> bool:
	if job_id != _active_job_id:
		return false
	_active_job_id = ""
	_generate_button.disabled = false
	_status.text = message
	return true


func handle_job_cancelled(job_id: String) -> bool:
	if job_id != _active_job_id:
		return false
	_active_job_id = ""
	_generate_button.disabled = false
	_status.text = "Compact preview generation cancelled. Nothing was changed."
	return true


func current_options() -> Dictionary:
	var options := {
		"compression_level": str(
			_level.get_selected_metadata()
			if _level.selected >= 0
			else "balanced"
		),
		"target_tokens": int(_target_tokens.value)
	}
	for key in _preservation.keys():
		options[key] = (_preservation[key] as CheckBox).button_pressed
	return DERIVATIVE_SERVICE.normalise_options(options)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 9)
	margin.add_child(page)
	var heading := Label.new()
	heading.text = "Compact/Lite Derivative from Existing Character"
	heading.add_theme_font_size_override("font_size", 22)
	page.add_child(heading)
	var safety := Label.new()
	safety.text = "Creates a new independent character with private lineage. The source is never overwritten or compressed in place."
	safety.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(safety)

	var setup := HFlowContainer.new()
	setup.add_theme_constant_override("h_separation", 10)
	setup.add_theme_constant_override("v_separation", 8)
	page.add_child(setup)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "New derivative name"
	_name_edit.custom_minimum_size.x = 280
	setup.add_child(_name_edit)
	_level = OptionButton.new()
	for level in DERIVATIVE_SERVICE.LEVELS:
		_level.add_item(str(level.get("label", "Balanced")))
		_level.set_item_metadata(_level.item_count - 1, str(level.get("id", "balanced")))
	_level.item_selected.connect(_compression_level_changed)
	setup.add_child(_level)
	_target_tokens = SpinBox.new()
	_target_tokens.min_value = 128
	_target_tokens.max_value = 1000000
	_target_tokens.step = 64
	_target_tokens.custom_minimum_size.x = 170
	_target_tokens.prefix = "Target ~"
	_target_tokens.suffix = " tokens"
	_target_tokens.value_changed.connect(_target_changed)
	setup.add_child(_target_tokens)
	_source_stats = Label.new()
	_source_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup.add_child(_source_stats)

	var preservation_panel := PanelContainer.new()
	page.add_child(preservation_panel)
	var preservation_column := VBoxContainer.new()
	preservation_panel.add_child(preservation_column)
	var preservation_title := Label.new()
	preservation_title.text = "Preserve unchanged"
	preservation_column.add_child(preservation_title)
	var preservation_row := HFlowContainer.new()
	preservation_column.add_child(preservation_row)
	for definition in [
		["preserve_lorebook", "Lorebook"],
		["preserve_greetings", "Greetings"],
		["preserve_examples", "Examples"],
		["preserve_front_porch", "Front Porch/state"],
		["preserve_adult_traits", "Adult traits"],
		["preserve_tags", "Tags"],
		["preserve_image_prompt", "Image-prompt material"]
	]:
		var checkbox := CheckBox.new()
		checkbox.text = str(definition[1])
		checkbox.button_pressed = true
		_preservation[str(definition[0])] = checkbox
		preservation_row.add_child(checkbox)

	var actions := HFlowContainer.new()
	page.add_child(actions)
	_generate_button = Button.new()
	_generate_button.text = "Generate Compact Preview"
	_generate_button.pressed.connect(_request_generation)
	actions.add_child(_generate_button)
	_create_button = Button.new()
	_create_button.text = "Review and Create New Character…"
	_create_button.disabled = true
	_create_button.pressed.connect(_request_create)
	actions.add_child(_create_button)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(_status)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(tabs)
	var comparison_scroll := ScrollContainer.new()
	comparison_scroll.name = "FieldComparison"
	tabs.add_child(comparison_scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Complete Field Comparison")
	_comparison_list = VBoxContainer.new()
	_comparison_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comparison_list.add_theme_constant_override("separation", 10)
	comparison_scroll.add_child(_comparison_list)
	var summary_page := VBoxContainer.new()
	summary_page.name = "CompressionSummary"
	tabs.add_child(summary_page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Summary and Estimate")
	_summary = TextEdit.new()
	_summary.editable = false
	_summary.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_page.add_child(_summary)


func _build_confirmation() -> void:
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Create Independent Compact Derivative"
	_confirm.dialog_text = "Create a new character from the reviewed preview? The source character will remain unchanged."
	_confirm.confirmed.connect(_create_derivative)
	add_child(_confirm)


func _request_generation() -> void:
	_candidate.clear()
	_clear_comparison()
	_create_button.disabled = true
	generation_requested_v0186.emit(current_options())


func _request_create() -> void:
	if _candidate.is_empty():
		_status.text = "Generate and review a compact preview first."
		return
	_confirm.popup_centered()


func _create_derivative() -> void:
	var source := CCFStorageService.get_character(
		_project_data, _source_character_id
	)
	var reviewed := _candidate.duplicate(true)
	for row in _comparison_rows:
		var path := str(row.get("path", ""))
		var use_compact := row.get("use_compact") as CheckBox
		var editor := row.get("editor") as TextEdit
		if use_compact != null and use_compact.button_pressed and editor != null:
			CCFStorageService.set_value_at_path(reviewed, path, editor.text)
		else:
			CCFStorageService.set_value_at_path(
				reviewed,
				path,
				CCFStorageService.get_value_at_path(source, path, "")
			)
	var result := DERIVATIVE_SERVICE.create_derivative(
		_project_data,
		_source_character_id,
		reviewed,
		_name_edit.text,
		current_options(),
		_request_metadata,
		_source_hash
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not create the derivative."))
		_create_button.disabled = bool(result.get("stale", false))
		return
	_project_data = result.get("project", _project_data).duplicate(true)
	var new_id := str(result.get("character_id", ""))
	project_changed_v0186.emit(
		_project_data.duplicate(true),
		new_id,
		"Created independent compact derivative “%s”; the source character was not changed." % _name_edit.text.strip_edges()
	)
	hide()


func _rebuild_comparison() -> void:
	_clear_comparison()
	var source := CCFStorageService.get_character(
		_project_data, _source_character_id
	)
	for definition in DERIVATIVE_SERVICE.comparison_rows(source, _candidate):
		var panel := PanelContainer.new()
		_comparison_list.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		panel.add_child(column)
		var header := HFlowContainer.new()
		column.add_child(header)
		var field_label := Label.new()
		field_label.text = str(definition.get("label", "Field"))
		field_label.add_theme_font_size_override("font_size", 17)
		header.add_child(field_label)
		var use_compact := CheckBox.new()
		use_compact.text = "Use compact version"
		use_compact.button_pressed = true
		header.add_child(use_compact)
		var split := HSplitContainer.new()
		column.add_child(split)
		var source_edit := TextEdit.new()
		source_edit.editable = false
		source_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		source_edit.custom_minimum_size = Vector2(520, 150)
		source_edit.text = str(definition.get("source", ""))
		source_edit.tooltip_text = "Source — read only"
		split.add_child(source_edit)
		var candidate_edit := TextEdit.new()
		candidate_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		candidate_edit.custom_minimum_size = Vector2(520, 150)
		candidate_edit.text = str(definition.get("candidate", ""))
		candidate_edit.tooltip_text = "Compact candidate — editable"
		split.add_child(candidate_edit)
		_comparison_rows.append({
			"path": str(definition.get("path", "")),
			"use_compact": use_compact,
			"editor": candidate_edit
		})


func _clear_comparison() -> void:
	if _comparison_list != null:
		for child in _comparison_list.get_children():
			_comparison_list.remove_child(child)
			child.queue_free()
	_comparison_rows.clear()


func _compression_level_changed(_index: int) -> void:
	_target_tokens.value = DERIVATIVE_SERVICE.suggested_target(
		_source_tokens, str(_level.get_selected_metadata())
	)
	_target_changed(_target_tokens.value)


func _target_changed(value: float) -> void:
	if _source_stats != null:
		_source_stats.text = "Source estimate: ~%d authored tokens • Target: ~%d tokens" % [_source_tokens, int(value)]


func _select_level(level_id: String) -> void:
	for index in range(_level.item_count):
		if str(_level.get_item_metadata(index)) == level_id:
			_level.select(index)
			return


func compact_derivative_window_capabilities_v0186() -> Dictionary:
	return {
		"target_budget": _target_tokens != null,
		"four_levels": _level != null and _level.item_count == 4,
		"seven_preservation_controls": _preservation.size() == 7,
		"editable_comparison": _comparison_list != null,
		"create_disabled_before_preview": _create_button != null and _create_button.disabled
	}
