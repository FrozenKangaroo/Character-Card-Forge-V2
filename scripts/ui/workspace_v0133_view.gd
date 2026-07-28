class_name CCFWorkspaceV0133View
extends CCFWorkspaceView

const MODE_STYLE_DEFAULTS := {
	"generation_mode": "full",
	"writing_style": "balanced",
	"first_message_style": "cinematic",
	"first_message_length": "detailed",
	"custom_writing_style": "",
	"first_message_custom_instructions": "",
	"custom_first_message_length": ""
}

var _loading_mode_style := false
var _generation_mode_selector: OptionButton
var _writing_style_selector: OptionButton
var _first_message_style_selector: OptionButton
var _first_message_length_selector: OptionButton
var _custom_writing_style_edit: LineEdit
var _first_message_custom_instructions_edit: TextEdit
var _custom_first_message_length_edit: LineEdit


func load_project(project: Dictionary, template: Dictionary, settings: Dictionary) -> void:
	super.load_project(project, template, settings)
	_ensure_mode_style_tab()


func _rebuild_form() -> void:
	super._rebuild_form()
	_ensure_mode_style_tab()


func _capture_all_fields() -> void:
	super._capture_all_fields()
	_capture_mode_style(false)


func _apply_preview() -> void:
	var compatible_preview := (
		_preview_project_id.is_empty()
		or _preview_project_id == str(_project.get("project_id", ""))
	)
	var selected_count := 0
	for row in _preview_rows:
		var checkbox: CheckBox = row.get("checkbox")
		if checkbox != null and checkbox.button_pressed:
			selected_count += 1

	super._apply_preview()

	if not compatible_preview or selected_count <= 0 or not _dirty:
		return
	var applied_count := selected_count
	save_project()
	if _dirty:
		_status.text = (
			"Applied %d generated field(s), but the automatic save did not complete. %s"
			% [applied_count, _status.text]
		)
	else:
		_status.text = "Applied %d generated field(s) and saved the project automatically." % applied_count


func _ensure_mode_style_tab() -> void:
	if _tabs == null or _project.is_empty():
		return
	for child in _tabs.get_children():
		if child.name == "Mode & Style":
			return
	_build_mode_style_tab()


func _build_mode_style_tab() -> void:
	_loading_mode_style = true
	var settings := _mode_style_settings()

	var scroll := ScrollContainer.new()
	scroll.name = "Mode & Style"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Mode & Style"
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	var intro := Label.new()
	intro.text = "Generation Mode controls overall card density. Writing Style controls prose tone. First Message Style and Length are independent so a cinematic opening can be brief or extended. The defaults deliberately favour a fuller cinematic greeting instead of forcing every character into a short opener."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.7, 0.73, 0.82)
	root.add_child(intro)

	_generation_mode_selector = _add_mode_selector(
		root,
		"Generation Mode",
		[
			{"label": "Full Prompt", "id": "full"},
			{"label": "Lite", "id": "lite"},
			{"label": "Compact Lite", "id": "compact_lite"}
		],
		str(settings.get("generation_mode", "full"))
	)

	var mode_hint := Label.new()
	mode_hint.text = "Full Prompt keeps the richer v0.13 generation contract. Lite and Compact Lite currently reduce prose density while preserving required fields; V1-style split/multi-pass execution remains a later parity step. First Message length is controlled separately."
	mode_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_hint.modulate = Color(0.6, 0.65, 0.76)
	root.add_child(mode_hint)

	_writing_style_selector = _add_mode_selector(
		root,
		"Writing Style",
		[
			{"label": "Balanced", "id": "balanced"},
			{"label": "Immersive", "id": "immersive"},
			{"label": "Dialogue-forward", "id": "dialogue_forward"},
			{"label": "Descriptive", "id": "descriptive"},
			{"label": "Concise", "id": "concise"},
			{"label": "Custom", "id": "custom"}
		],
		str(settings.get("writing_style", "balanced"))
	)

	_custom_writing_style_edit = LineEdit.new()
	_custom_writing_style_edit.placeholder_text = "Custom writing style, tone, pacing, voice, formatting, or genre direction"
	_custom_writing_style_edit.text = str(settings.get("custom_writing_style", ""))
	_custom_writing_style_edit.text_changed.connect(func(_value: String): _on_mode_style_changed())
	root.add_child(_label_for_control("Custom Writing Style"))
	root.add_child(_custom_writing_style_edit)

	root.add_child(HSeparator.new())

	var first_title := Label.new()
	first_title.text = "First Message"
	first_title.add_theme_font_size_override("font_size", 20)
	root.add_child(first_title)

	_first_message_style_selector = _add_mode_selector(
		root,
		"First Message Style",
		[
			{"label": "Cinematic", "id": "cinematic"},
			{"label": "Conversational", "id": "conversational"},
			{"label": "Immediate Dialogue", "id": "immediate_dialogue"},
			{"label": "Atmospheric", "id": "atmospheric"},
			{"label": "Action Opening", "id": "action_opening"},
			{"label": "Custom", "id": "custom"}
		],
		str(settings.get("first_message_style", "cinematic"))
	)

	_first_message_length_selector = _add_mode_selector(
		root,
		"First Message Length",
		[
			{"label": "Brief — about 60-160 words", "id": "brief"},
			{"label": "Standard — about 180-350 words", "id": "standard"},
			{"label": "Detailed — about 350-650 words", "id": "detailed"},
			{"label": "Extended — about 650-1000 words", "id": "extended"},
			{"label": "Custom", "id": "custom"}
		],
		str(settings.get("first_message_length", "detailed"))
	)

	_custom_first_message_length_edit = LineEdit.new()
	_custom_first_message_length_edit.placeholder_text = "Custom length target, e.g. 450-700 words or 6-8 paragraphs"
	_custom_first_message_length_edit.text = str(settings.get("custom_first_message_length", ""))
	_custom_first_message_length_edit.text_changed.connect(func(_value: String): _on_mode_style_changed())
	root.add_child(_label_for_control("Custom First Message Length"))
	root.add_child(_custom_first_message_length_edit)

	_first_message_custom_instructions_edit = TextEdit.new()
	_first_message_custom_instructions_edit.custom_minimum_size.y = 130
	_first_message_custom_instructions_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_first_message_custom_instructions_edit.placeholder_text = "Optional greeting-only instructions. Example: Start in a university classroom at sunset, let the scene breathe before {{char}} speaks, and do not narrate {{user}}'s choices."
	_first_message_custom_instructions_edit.text = str(settings.get("first_message_custom_instructions", ""))
	_first_message_custom_instructions_edit.text_changed.connect(_on_mode_style_changed)
	root.add_child(_label_for_control("First Message Custom Instructions"))
	root.add_child(_first_message_custom_instructions_edit)

	var note := Label.new()
	note.text = "These controls guide full generation and semantic repair. They are planning settings, not exported Character Card fields. Brief is an explicit option; it is not the default."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate = Color(0.62, 0.68, 0.8)
	root.add_child(note)

	_generation_mode_selector.item_selected.connect(func(_index: int): _on_mode_style_changed())
	_writing_style_selector.item_selected.connect(func(_index: int): _on_mode_style_changed())
	_first_message_style_selector.item_selected.connect(func(_index: int): _on_mode_style_changed())
	_first_message_length_selector.item_selected.connect(func(_index: int): _on_mode_style_changed())

	_loading_mode_style = false
	_refresh_custom_control_state()


func _add_mode_selector(
	parent: VBoxContainer,
	label_text: String,
	entries: Array,
	selected_id: String
) -> OptionButton:
	parent.add_child(_label_for_control(label_text))
	var selector := OptionButton.new()
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selected_index := 0
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		selector.add_item(str(entry.get("label", entry.get("id", "Option"))))
		selector.set_item_metadata(index, str(entry.get("id", "")))
		if str(entry.get("id", "")) == selected_id:
			selected_index = index
	selector.select(selected_index)
	parent.add_child(selector)
	return selector


func _label_for_control(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 16)
	return label


func _on_mode_style_changed() -> void:
	if _loading_mode_style:
		return
	_capture_mode_style(true)
	_refresh_custom_control_state()
	_status.text = "Mode & Style updated. These settings will guide the next character generation."


func _capture_mode_style(mark_dirty: bool) -> void:
	if _loading_mode_style or _project.is_empty() or _generation_mode_selector == null:
		return
	var generation_value: Variant = _project.get("generation", {})
	var generation: Dictionary = generation_value.duplicate(true) if generation_value is Dictionary else {}
	var current_value: Variant = generation.get("mode_style", {})
	var current: Dictionary = current_value if current_value is Dictionary else {}
	var updated := {
		"generation_mode": _selected_id(_generation_mode_selector, "full"),
		"writing_style": _selected_id(_writing_style_selector, "balanced"),
		"first_message_style": _selected_id(_first_message_style_selector, "cinematic"),
		"first_message_length": _selected_id(_first_message_length_selector, "detailed"),
		"custom_writing_style": _custom_writing_style_edit.text.strip_edges(),
		"first_message_custom_instructions": _first_message_custom_instructions_edit.text.strip_edges(),
		"custom_first_message_length": _custom_first_message_length_edit.text.strip_edges()
	}
	generation["mode_style"] = updated
	_project["generation"] = generation
	if mark_dirty and JSON.stringify(current) != JSON.stringify(updated):
		_mark_dirty()


func _mode_style_settings() -> Dictionary:
	var result := MODE_STYLE_DEFAULTS.duplicate(true)
	var generation_value: Variant = _project.get("generation", {})
	if not generation_value is Dictionary:
		return result
	var stored_value: Variant = generation_value.get("mode_style", {})
	if stored_value is Dictionary:
		result.merge(stored_value, true)
	return result


func _selected_id(selector: OptionButton, fallback: String) -> String:
	if selector == null or selector.selected < 0:
		return fallback
	var value := str(selector.get_item_metadata(selector.selected)).strip_edges()
	return fallback if value.is_empty() else value


func _refresh_custom_control_state() -> void:
	if _custom_writing_style_edit != null:
		_custom_writing_style_edit.editable = _selected_id(_writing_style_selector, "balanced") == "custom"
	if _custom_first_message_length_edit != null:
		_custom_first_message_length_edit.editable = _selected_id(_first_message_length_selector, "detailed") == "custom"
