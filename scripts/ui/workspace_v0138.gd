class_name CCFWorkspaceV0138View
extends CCFWorkspaceV0137View

var _alternate_count: SpinBox
var _alternate_style: OptionButton
var _alternate_instructions: TextEdit
var _alternate_editors: VBoxContainer
var _alternate_generate_button: Button

func _rebuild_form() -> void:
	super._rebuild_form()
	_build_alternative_greetings_tab()

func _capture_all_fields() -> void:
	super._capture_all_fields()
	_capture_alternative_greetings()

func _build_alternative_greetings_tab() -> void:
	if _tabs == null:
		return
	var scroll := ScrollContainer.new()
	scroll.name = "alternative_greetings"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Alternative Greetings")
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var intro := Label.new()
	intro.text = "Create optional alternate playable openings. The main First Message remains unchanged. Character Card V2 exports these as alternate_greetings."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)
	var count_label := Label.new()
	count_label.text = "Greeting count"
	row.add_child(count_label)
	_alternate_count = SpinBox.new()
	_alternate_count.min_value = 1
	_alternate_count.max_value = 5
	_alternate_count.step = 1
	_alternate_count.value = 3
	row.add_child(_alternate_count)
	var style_label := Label.new()
	style_label.text = "Style"
	row.add_child(style_label)
	_alternate_style = OptionButton.new()
	for style in ["Varied", "Conversational", "Cinematic", "Immediate dialogue", "Atmospheric", "Action opening"]:
		_alternate_style.add_item(style)
	row.add_child(_alternate_style)
	_alternate_generate_button = Button.new()
	_alternate_generate_button.text = "Generate Alternatives"
	_alternate_generate_button.pressed.connect(_generate_alternative_greetings)
	row.add_child(_alternate_generate_button)
	var instruction_label := Label.new()
	instruction_label.text = "Alternative-specific instructions"
	root.add_child(instruction_label)
	_alternate_instructions = TextEdit.new()
	_alternate_instructions.custom_minimum_size.y = 90
	_alternate_instructions.placeholder_text = "Optional: different meeting point, mood, scenario branch, or opening constraint."
	_alternate_instructions.text_changed.connect(_mark_dirty)
	root.add_child(_alternate_instructions)
	_alternate_editors = VBoxContainer.new()
	_alternate_editors.add_theme_constant_override("separation", 10)
	root.add_child(_alternate_editors)
	_load_alternative_greetings_controls()

func _load_alternative_greetings_controls() -> void:
	if _project.is_empty() or _alternate_editors == null:
		return
	for child in _alternate_editors.get_children():
		child.queue_free()
	var settings_value: Variant = CCFStorageService.get_value_at_path(_project, "generation.alternate_greetings_settings", {})
	var settings: Dictionary = settings_value if settings_value is Dictionary else {}
	_alternate_count.value = clampi(int(settings.get("count", 3)), 1, 5)
	var style := str(settings.get("style", "Varied"))
	for index in range(_alternate_style.item_count):
		if _alternate_style.get_item_text(index) == style:
			_alternate_style.select(index)
			break
	_alternate_instructions.text = str(settings.get("instructions", ""))
	var greetings_value: Variant = CCFStorageService.get_value_at_path(_project, "character.alternate_greetings", [])
	var greetings: Array = greetings_value if greetings_value is Array else []
	if greetings.is_empty():
		_add_alternative_editor("")
	else:
		for greeting in greetings:
			_add_alternative_editor(str(greeting))
	var add_button := Button.new()
	add_button.text = "+ Add Greeting"
	add_button.pressed.connect(func(): _add_alternative_editor(""))
	_alternate_editors.add_child(add_button)

func _add_alternative_editor(value: String) -> void:
	var editor := TextEdit.new()
	editor.custom_minimum_size.y = 150
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.placeholder_text = "Alternative First Message"
	editor.text = value
	editor.text_changed.connect(_mark_dirty)
	_alternate_editors.add_child(editor)

func _capture_alternative_greetings() -> void:
	if _project.is_empty() or _alternate_editors == null:
		return
	var greetings: Array[String] = []
	for child in _alternate_editors.get_children():
		if child is TextEdit:
			var text := child.text.strip_edges()
			if not text.is_empty():
				greetings.append(text)
	CCFStorageService.set_value_at_path(_project, "character.alternate_greetings", greetings)
	CCFStorageService.set_value_at_path(_project, "generation.alternate_greetings_settings", {
		"count": int(_alternate_count.value),
		"style": _alternate_style.get_item_text(_alternate_style.selected),
		"instructions": _alternate_instructions.text.strip_edges()
	})

func _generate_alternative_greetings() -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	var count := int(_alternate_count.value)
	var style := _alternate_style.get_item_text(_alternate_style.selected)
	var instructions := _alternate_instructions.text.strip_edges()
	var field := {
		"id": "alternate_greetings",
		"label": "Alternative First Messages",
		"path": "character.alternate_greetings",
		"type": "tags",
		"required": false,
		"generation_prompt": "Return exactly %d complete, distinct playable opening messages as an array of strings. Style: %s. Each opening must preserve the established character, scenario and relationship context while offering a meaningfully different entry point. Do not replace or paraphrase the main First Message. %s" % [count, style, instructions]
	}
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var result := _generation_service.queue_field_suggestion(_project, _template, field, profile, int(_generation_settings().get("retry_count", 1)))
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue alternative greetings."))
		return
	_status.text = "Alternative First Messages queued. Review the generated list before saving."

func _on_job_completed(job_id: String, job_type: String, data: Variant, metadata: Dictionary) -> void:
	if job_type == "field" and str(metadata.get("field_id", "")) == "alternate_greetings":
		if data is Array:
			CCFStorageService.set_value_at_path(_project, "character.alternate_greetings", data.duplicate(true))
			_load_alternative_greetings_controls()
			_mark_dirty()
			_status.text = "Alternative First Messages generated. Review and edit them, then save the Character Project."
			return
	super._on_job_completed(job_id, job_type, data, metadata)
