class_name CCFTemplateManagerView
extends VBoxContainer

signal templates_changed()

var _template_list: ItemList
var _section_list: ItemList
var _field_list: ItemList
var _status: Label
var _save_button: Button
var _duplicate_button: Button
var _delete_button: Button
var _export_button: Button

var _template_name: LineEdit
var _template_description: TextEdit
var _global_rules: TextEdit
var _policy_mode: OptionButton
var _unexpected_fields: OptionButton

var _section_id: LineEdit
var _section_title: LineEdit
var _section_description: TextEdit
var _section_kind: OptionButton
var _section_editor: VBoxContainer
var _section_up: Button
var _section_down: Button
var _section_delete: Button

var _field_id: LineEdit
var _field_label: LineEdit
var _field_type: OptionButton
var _field_path: LineEdit
var _field_placeholder: LineEdit
var _field_generation_prompt: TextEdit
var _field_generate: CheckBox
var _field_required: CheckBox
var _field_height: SpinBox
var _field_minimum: SpinBox
var _field_maximum: SpinBox
var _field_step: SpinBox
var _field_options: LineEdit
var _field_editor: VBoxContainer
var _field_height_row: Control
var _field_number_row: Control
var _field_options_row: Control
var _field_up: Button
var _field_down: Button
var _field_delete: Button

var _import_dialog: FileDialog
var _export_dialog: FileDialog
var _delete_confirmation: ConfirmationDialog

var _current_template: Dictionary = {}
var _current_template_id := ""
var _selected_section := -1
var _selected_field := -1
var _loading_ui := false

func _ready() -> void:
    add_theme_constant_override("separation", 12)
    _build_toolbar()
    _build_editor()
    _build_dialogs()
    refresh_templates()

func refresh_templates(select_template_id := "") -> void:
    var preferred_id := select_template_id
    if preferred_id.is_empty():
        preferred_id = _current_template_id

    _template_list.clear()
    var summaries := CCFTemplateService.list_templates()
    var preferred_index := -1
    for summary in summaries:
        if not summary is Dictionary:
            continue
        var template_id := str(summary.get("template_id", ""))
        var label := str(summary.get("name", "Template"))
        if bool(summary.get("built_in", false)):
            label += "  • Built-in"
        var index := _template_list.add_item(label)
        _template_list.set_item_metadata(index, template_id)
        _template_list.set_item_tooltip(index, "%d sections • %d fields\n%s" % [
            int(summary.get("section_count", 0)),
            int(summary.get("field_count", 0)),
            str(summary.get("description", ""))
        ])
        if template_id == preferred_id:
            preferred_index = index

    if _template_list.item_count == 0:
        _load_template("")
        return
    if preferred_index < 0:
        preferred_index = 0
    _template_list.select(preferred_index)
    _load_template(str(_template_list.get_item_metadata(preferred_index)))

func _build_toolbar() -> void:
    var toolbar := HBoxContainer.new()
    toolbar.add_theme_constant_override("separation", 8)
    add_child(toolbar)

    var intro := Label.new()
    intro.text = "Templates define workspace fields, layout, and AI generation rules."
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    toolbar.add_child(intro)

    var new_button := Button.new()
    new_button.text = "New"
    new_button.pressed.connect(_create_template)
    toolbar.add_child(new_button)

    _duplicate_button = Button.new()
    _duplicate_button.text = "Duplicate"
    _duplicate_button.pressed.connect(_duplicate_template)
    toolbar.add_child(_duplicate_button)

    var import_button := Button.new()
    import_button.text = "Import"
    import_button.pressed.connect(func(): _import_dialog.popup_centered_ratio(0.75))
    toolbar.add_child(import_button)

    _export_button = Button.new()
    _export_button.text = "Export"
    _export_button.pressed.connect(_open_export_dialog)
    toolbar.add_child(_export_button)

    _delete_button = Button.new()
    _delete_button.text = "Delete"
    _delete_button.pressed.connect(_request_delete)
    toolbar.add_child(_delete_button)

    _save_button = Button.new()
    _save_button.text = "Save Template"
    _save_button.pressed.connect(_save_template)
    toolbar.add_child(_save_button)

func _build_editor() -> void:
    var split := HSplitContainer.new()
    split.size_flags_vertical = Control.SIZE_EXPAND_FILL
    split.split_offset = 270
    add_child(split)

    var template_panel := PanelContainer.new()
    template_panel.custom_minimum_size.x = 230
    split.add_child(template_panel)
    var template_margin := _make_margin(12)
    template_panel.add_child(template_margin)
    var template_column := VBoxContainer.new()
    template_column.add_theme_constant_override("separation", 8)
    template_margin.add_child(template_column)

    var template_heading := Label.new()
    template_heading.text = "Templates"
    template_heading.add_theme_font_size_override("font_size", 18)
    template_column.add_child(template_heading)

    _template_list = ItemList.new()
    _template_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _template_list.select_mode = ItemList.SELECT_SINGLE
    _template_list.item_selected.connect(_on_template_selected)
    template_column.add_child(_template_list)

    _status = Label.new()
    _status.text = "Ready"
    _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _status.modulate = Color(0.66, 0.69, 0.78)
    template_column.add_child(_status)

    var editor_scroll := ScrollContainer.new()
    editor_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    split.add_child(editor_scroll)

    var editor_margin := _make_margin(14)
    editor_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    editor_scroll.add_child(editor_margin)

    var editor := VBoxContainer.new()
    editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    editor.add_theme_constant_override("separation", 14)
    editor_margin.add_child(editor)

    _build_template_metadata(editor)
    editor.add_child(HSeparator.new())
    _build_structure_editor(editor)

func _build_template_metadata(parent: VBoxContainer) -> void:
    var heading := Label.new()
    heading.text = "Template settings"
    heading.add_theme_font_size_override("font_size", 20)
    parent.add_child(heading)

    _template_name = _add_line_field(parent, "Name")
    _template_name.text_changed.connect(func(value: String):
        if not _loading_ui:
            _current_template["name"] = value
            _refresh_selected_template_label()
    )

    _template_description = _add_text_field(parent, "Description", 85)
    _template_description.text_changed.connect(func():
        if not _loading_ui:
            _current_template["description"] = _template_description.text
    )

    var policy_row := HBoxContainer.new()
    policy_row.add_theme_constant_override("separation", 12)
    parent.add_child(policy_row)

    var mode_box := VBoxContainer.new()
    mode_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    policy_row.add_child(mode_box)
    var mode_label := Label.new()
    mode_label.text = "AI output discipline"
    mode_box.add_child(mode_label)
    _policy_mode = OptionButton.new()
    _policy_mode.add_item("Strict — requested fields only")
    _policy_mode.set_item_metadata(0, "strict")
    _policy_mode.add_item("Flexible — additional fields allowed")
    _policy_mode.set_item_metadata(1, "flexible")
    _policy_mode.item_selected.connect(_on_policy_changed)
    mode_box.add_child(_policy_mode)

    var unexpected_box := VBoxContainer.new()
    unexpected_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    policy_row.add_child(unexpected_box)
    var unexpected_label := Label.new()
    unexpected_label.text = "Unexpected generated fields"
    unexpected_box.add_child(unexpected_label)
    _unexpected_fields = OptionButton.new()
    _unexpected_fields.add_item("Ignore")
    _unexpected_fields.set_item_metadata(0, "ignore")
    _unexpected_fields.add_item("Store as custom fields")
    _unexpected_fields.set_item_metadata(1, "store")
    _unexpected_fields.item_selected.connect(_on_policy_changed)
    unexpected_box.add_child(_unexpected_fields)

    _global_rules = _add_text_field(parent, "Global AI rules — one instruction per line", 125)
    _global_rules.text_changed.connect(func():
        if not _loading_ui:
            _current_template["global_generation_instructions"] = _lines_to_array(_global_rules.text)
    )

func _build_structure_editor(parent: VBoxContainer) -> void:
    var heading := Label.new()
    heading.text = "Sections and fields"
    heading.add_theme_font_size_override("font_size", 20)
    parent.add_child(heading)

    var hint := Label.new()
    hint.text = "Interview sections behave like normal workspace sections but let you organise question-led fields. Per-field AI instructions can be written as direct questions or constraints."
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.modulate = Color(0.66, 0.69, 0.78)
    parent.add_child(hint)

    var columns := HSplitContainer.new()
    columns.custom_minimum_size.y = 650
    columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.split_offset = 235
    parent.add_child(columns)

    var section_column := VBoxContainer.new()
    section_column.custom_minimum_size.x = 210
    section_column.add_theme_constant_override("separation", 8)
    columns.add_child(section_column)
    var section_heading := Label.new()
    section_heading.text = "Sections"
    section_heading.add_theme_font_size_override("font_size", 18)
    section_column.add_child(section_heading)
    _section_list = ItemList.new()
    _section_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _section_list.item_selected.connect(_on_section_selected)
    section_column.add_child(_section_list)
    var section_actions := HBoxContainer.new()
    section_actions.add_theme_constant_override("separation", 6)
    section_column.add_child(section_actions)
    var add_section := Button.new()
    add_section.text = "+"
    add_section.tooltip_text = "Add section"
    add_section.pressed.connect(_add_section)
    section_actions.add_child(add_section)
    _section_up = Button.new()
    _section_up.text = "↑"
    _section_up.pressed.connect(_move_section.bind(-1))
    section_actions.add_child(_section_up)
    _section_down = Button.new()
    _section_down.text = "↓"
    _section_down.pressed.connect(_move_section.bind(1))
    section_actions.add_child(_section_down)
    _section_delete = Button.new()
    _section_delete.text = "−"
    _section_delete.tooltip_text = "Delete section"
    _section_delete.pressed.connect(_delete_section)
    section_actions.add_child(_section_delete)

    var right_split := HSplitContainer.new()
    right_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_split.split_offset = 250
    columns.add_child(right_split)

    var field_column := VBoxContainer.new()
    field_column.custom_minimum_size.x = 225
    field_column.add_theme_constant_override("separation", 8)
    right_split.add_child(field_column)
    var field_heading := Label.new()
    field_heading.text = "Fields"
    field_heading.add_theme_font_size_override("font_size", 18)
    field_column.add_child(field_heading)
    _field_list = ItemList.new()
    _field_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _field_list.item_selected.connect(_on_field_selected)
    field_column.add_child(_field_list)
    var field_actions := HBoxContainer.new()
    field_actions.add_theme_constant_override("separation", 6)
    field_column.add_child(field_actions)
    var add_field := Button.new()
    add_field.text = "+"
    add_field.tooltip_text = "Add field"
    add_field.pressed.connect(_add_field)
    field_actions.add_child(add_field)
    _field_up = Button.new()
    _field_up.text = "↑"
    _field_up.pressed.connect(_move_field.bind(-1))
    field_actions.add_child(_field_up)
    _field_down = Button.new()
    _field_down.text = "↓"
    _field_down.pressed.connect(_move_field.bind(1))
    field_actions.add_child(_field_down)
    _field_delete = Button.new()
    _field_delete.text = "−"
    _field_delete.tooltip_text = "Delete field"
    _field_delete.pressed.connect(_delete_field)
    field_actions.add_child(_field_delete)

    var properties_scroll := ScrollContainer.new()
    properties_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    properties_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right_split.add_child(properties_scroll)
    var properties_margin := _make_margin(10)
    properties_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    properties_scroll.add_child(properties_margin)
    var properties := VBoxContainer.new()
    properties.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    properties.add_theme_constant_override("separation", 12)
    properties_margin.add_child(properties)

    _build_section_properties(properties)
    properties.add_child(HSeparator.new())
    _build_field_properties(properties)

func _build_section_properties(parent: VBoxContainer) -> void:
    _section_editor = VBoxContainer.new()
    _section_editor.add_theme_constant_override("separation", 10)
    parent.add_child(_section_editor)
    var heading := Label.new()
    heading.text = "Section properties"
    heading.add_theme_font_size_override("font_size", 18)
    _section_editor.add_child(heading)

    _section_id = _add_line_field(_section_editor, "Section ID")
    _section_id.text_changed.connect(func(value: String): _update_section_property("id", value))
    _section_title = _add_line_field(_section_editor, "Title")
    _section_title.text_changed.connect(func(value: String):
        _update_section_property("title", value)
        _refresh_section_list_label()
    )
    _section_description = _add_text_field(_section_editor, "Description", 80)
    _section_description.text_changed.connect(func(): _update_section_property("description", _section_description.text))

    var kind_label := Label.new()
    kind_label.text = "Section kind"
    _section_editor.add_child(kind_label)
    _section_kind = OptionButton.new()
    _section_kind.add_item("Standard")
    _section_kind.set_item_metadata(0, "standard")
    _section_kind.add_item("Interview / Q&A")
    _section_kind.set_item_metadata(1, "interview")
    _section_kind.item_selected.connect(func(_index: int):
        if not _loading_ui:
            _update_section_property("kind", str(_section_kind.get_selected_metadata()))
    )
    _section_editor.add_child(_section_kind)

func _build_field_properties(parent: VBoxContainer) -> void:
    _field_editor = VBoxContainer.new()
    _field_editor.add_theme_constant_override("separation", 10)
    parent.add_child(_field_editor)
    var heading := Label.new()
    heading.text = "Field properties"
    heading.add_theme_font_size_override("font_size", 18)
    _field_editor.add_child(heading)

    _field_id = _add_line_field(_field_editor, "Field ID / AI JSON key")
    _field_id.text_changed.connect(func(value: String): _update_field_property("id", value))
    _field_label = _add_line_field(_field_editor, "Label")
    _field_label.text_changed.connect(func(value: String):
        _update_field_property("label", value)
        _refresh_field_list_label()
    )

    var type_label := Label.new()
    type_label.text = "Field type"
    _field_editor.add_child(type_label)
    _field_type = OptionButton.new()
    for field_type in ["line", "multiline", "tags", "number", "checkbox", "select"]:
        _field_type.add_item(field_type.capitalize())
        _field_type.set_item_metadata(_field_type.item_count - 1, field_type)
    _field_type.item_selected.connect(_on_field_type_changed)
    _field_editor.add_child(_field_type)

    _field_path = _add_line_field(_field_editor, "Project data path")
    _field_path.text_changed.connect(func(value: String): _update_field_property("path", value))
    _field_placeholder = _add_line_field(_field_editor, "Placeholder")
    _field_placeholder.text_changed.connect(func(value: String): _update_field_property("placeholder", value))

    _field_height_row = VBoxContainer.new()
    _field_editor.add_child(_field_height_row)
    var height_label := Label.new()
    height_label.text = "Multiline height"
    _field_height_row.add_child(height_label)
    _field_height = SpinBox.new()
    _field_height.min_value = 80
    _field_height.max_value = 800
    _field_height.step = 10
    _field_height.value_changed.connect(func(value: float): _update_field_property("height", int(value)))
    _field_height_row.add_child(_field_height)

    _field_number_row = VBoxContainer.new()
    _field_number_row.add_theme_constant_override("separation", 6)
    _field_editor.add_child(_field_number_row)
    var number_label := Label.new()
    number_label.text = "Number range"
    _field_number_row.add_child(number_label)
    var number_values := HBoxContainer.new()
    number_values.add_theme_constant_override("separation", 8)
    _field_number_row.add_child(number_values)
    _field_minimum = _make_spin(-1000000.0, 1000000.0, 1.0)
    _field_minimum.prefix = "Min "
    _field_minimum.value_changed.connect(func(value: float): _update_field_property("minimum", value))
    number_values.add_child(_field_minimum)
    _field_maximum = _make_spin(-1000000.0, 1000000.0, 1.0)
    _field_maximum.prefix = "Max "
    _field_maximum.value_changed.connect(func(value: float): _update_field_property("maximum", value))
    number_values.add_child(_field_maximum)
    _field_step = _make_spin(0.001, 100000.0, 0.1)
    _field_step.prefix = "Step "
    _field_step.value_changed.connect(func(value: float): _update_field_property("step", value))
    number_values.add_child(_field_step)

    _field_options_row = VBoxContainer.new()
    _field_editor.add_child(_field_options_row)
    var options_label := Label.new()
    options_label.text = "Select options — comma separated"
    _field_options_row.add_child(options_label)
    _field_options = LineEdit.new()
    _field_options.text_changed.connect(func(value: String):
        if not _loading_ui:
            _update_field_property("options", _comma_values(value))
    )
    _field_options_row.add_child(_field_options)

    _field_generation_prompt = _add_text_field(_field_editor, "Per-field AI instruction / interview question", 105)
    _field_generation_prompt.text_changed.connect(func(): _update_field_property("generation_prompt", _field_generation_prompt.text))

    _field_generate = CheckBox.new()
    _field_generate.text = "AI may generate this field"
    _field_generate.toggled.connect(func(value: bool):
        _update_field_property("generate", value)
        if not _loading_ui:
            _refresh_field_list_label()
    )
    _field_editor.add_child(_field_generate)

    _field_required = CheckBox.new()
    _field_required.text = "Required field"
    _field_required.toggled.connect(func(value: bool): _update_field_property("required", value))
    _field_editor.add_child(_field_required)

func _build_dialogs() -> void:
    _import_dialog = FileDialog.new()
    _import_dialog.title = "Import Character Card Forge Template"
    _import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    _import_dialog.access = FileDialog.ACCESS_FILESYSTEM
    _import_dialog.filters = PackedStringArray(["*.json ; JSON template files"])
    _import_dialog.visible = false
    _import_dialog.file_selected.connect(_import_template)
    add_child(_import_dialog)
    _import_dialog.hide()

    _export_dialog = FileDialog.new()
    _export_dialog.title = "Export Character Card Forge Template"
    _export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    _export_dialog.access = FileDialog.ACCESS_FILESYSTEM
    _export_dialog.filters = PackedStringArray(["*.json ; JSON template files"])
    _export_dialog.visible = false
    _export_dialog.file_selected.connect(_export_template)
    add_child(_export_dialog)
    _export_dialog.hide()

    _delete_confirmation = ConfirmationDialog.new()
    _delete_confirmation.title = "Delete Template"
    _delete_confirmation.visible = false
    _delete_confirmation.confirmed.connect(_delete_template)
    add_child(_delete_confirmation)
    _delete_confirmation.hide()

func _on_template_selected(index: int) -> void:
    _load_template(str(_template_list.get_item_metadata(index)))

func _load_template(template_id: String) -> void:
    if template_id.is_empty():
        _current_template = {}
        _current_template_id = ""
        return
    _current_template = CCFTemplateService.load_template(template_id).duplicate(true)
    _current_template_id = str(_current_template.get("template_id", template_id))
    _selected_section = 0 if not _current_template.get("sections", []).is_empty() else -1
    _selected_field = 0
    _populate_template_controls()
    _refresh_section_list()
    _update_read_only_state()
    _status.text = "Loaded %s" % str(_current_template.get("name", "Template"))

func _populate_template_controls() -> void:
    _loading_ui = true
    _template_name.text = str(_current_template.get("name", ""))
    _template_description.text = str(_current_template.get("description", ""))
    _global_rules.text = _join_values(_current_template.get("global_generation_instructions", []), "\n")
    var policy := CCFTemplateService.output_policy(_current_template)
    _select_option_by_metadata(_policy_mode, str(policy.get("mode", "strict")))
    _select_option_by_metadata(_unexpected_fields, str(policy.get("unexpected_fields", "ignore")))
    _loading_ui = false

func _refresh_section_list() -> void:
    _section_list.clear()
    var sections: Array = _current_template.get("sections", [])
    for section in sections:
        if section is Dictionary:
            _section_list.add_item(str(section.get("title", section.get("id", "Section"))))
    if sections.is_empty():
        _selected_section = -1
        _selected_field = -1
    else:
        _selected_section = clampi(_selected_section, 0, sections.size() - 1)
        _section_list.select(_selected_section)
    _refresh_field_list()
    _populate_section_controls()

func _refresh_field_list() -> void:
    _field_list.clear()
    var section := _selected_section_data()
    var fields: Array = section.get("fields", []) if not section.is_empty() else []
    for field in fields:
        if field is Dictionary:
            var label := str(field.get("label", field.get("id", "Field")))
            if bool(field.get("generate", false)):
                label += "  ✦"
            _field_list.add_item(label)
    if fields.is_empty():
        _selected_field = -1
    else:
        _selected_field = clampi(_selected_field, 0, fields.size() - 1)
        _field_list.select(_selected_field)
    _populate_field_controls()

func _populate_section_controls() -> void:
    var section := _selected_section_data()
    var has_section := not section.is_empty()
    _section_editor.visible = has_section
    if not has_section:
        return
    _loading_ui = true
    _section_id.text = str(section.get("id", ""))
    _section_title.text = str(section.get("title", ""))
    _section_description.text = str(section.get("description", ""))
    _select_option_by_metadata(_section_kind, str(section.get("kind", "standard")))
    _loading_ui = false

func _populate_field_controls() -> void:
    var field := _selected_field_data()
    var has_field := not field.is_empty()
    _field_editor.visible = has_field
    if not has_field:
        return
    _loading_ui = true
    _field_id.text = str(field.get("id", ""))
    _field_label.text = str(field.get("label", ""))
    _select_option_by_metadata(_field_type, str(field.get("type", "multiline")))
    _field_path.text = str(field.get("path", ""))
    _field_placeholder.text = str(field.get("placeholder", ""))
    _field_generation_prompt.text = str(field.get("generation_prompt", ""))
    _field_generate.button_pressed = bool(field.get("generate", false))
    _field_required.button_pressed = bool(field.get("required", false))
    _field_height.value = int(field.get("height", 150))
    _field_minimum.value = float(field.get("minimum", 0.0))
    _field_maximum.value = float(field.get("maximum", 100.0))
    _field_step.value = float(field.get("step", 1.0))
    _field_options.text = _join_values(field.get("options", []), ", ")
    _loading_ui = false
    _update_field_type_rows()

func _on_section_selected(index: int) -> void:
    _selected_section = index
    _selected_field = 0
    _refresh_field_list()
    _populate_section_controls()
    _update_read_only_state()

func _on_field_selected(index: int) -> void:
    _selected_field = index
    _populate_field_controls()
    _update_read_only_state()

func _create_template() -> void:
    var template := CCFTemplateService.create_template()
    var result := CCFTemplateService.save_template(template)
    if not result.get("ok", false):
        _status.text = str(result.get("error", "Could not create template."))
        return
    templates_changed.emit()
    refresh_templates(str(template.get("template_id", "")))
    _status.text = "New template created."

func _duplicate_template() -> void:
    if _current_template_id.is_empty():
        return
    var result := CCFTemplateService.duplicate_template(_current_template_id)
    if not result.get("ok", false):
        _status.text = str(result.get("error", "Could not duplicate template."))
        return
    var template: Dictionary = result.get("template", {})
    templates_changed.emit()
    refresh_templates(str(template.get("template_id", "")))
    _status.text = "Template duplicated."

func _save_template() -> void:
    if _current_template_id.is_empty() or _current_template_id == "default":
        return
    var result := CCFTemplateService.save_template(_current_template)
    if not result.get("ok", false):
        _status.text = str(result.get("error", "Could not save template."))
        return
    _current_template = result.get("template", _current_template)
    templates_changed.emit()
    refresh_templates(_current_template_id)
    _status.text = "Template saved."

func _request_delete() -> void:
    if _current_template_id.is_empty() or _current_template_id == "default":
        return
    _delete_confirmation.dialog_text = "Delete '%s'? Character projects using it will fall back to the Default template until another template is selected." % str(_current_template.get("name", "this template"))
    _delete_confirmation.popup_centered(Vector2i(560, 180))

func _delete_template() -> void:
    var result := CCFTemplateService.delete_template(_current_template_id)
    if not result.get("ok", false):
        _status.text = str(result.get("error", "Could not delete template."))
        return
    _current_template_id = ""
    templates_changed.emit()
    refresh_templates("default")
    _status.text = "Template deleted."

func _open_export_dialog() -> void:
    if _current_template_id.is_empty():
        return
    _export_dialog.current_file = "%s.json" % _safe_filename(str(_current_template.get("name", "template")))
    _export_dialog.popup_centered_ratio(0.75)

func _import_template(path: String) -> void:
    var result := CCFTemplateService.import_template(path)
    if not result.get("ok", false):
        _status.text = str(result.get("error", "Could not import template."))
        return
    var template: Dictionary = result.get("template", {})
    templates_changed.emit()
    refresh_templates(str(template.get("template_id", "")))
    _status.text = "Template imported."

func _export_template(path: String) -> void:
    var result := CCFTemplateService.export_template(_current_template_id, path)
    _status.text = "Template exported." if result.get("ok", false) else str(result.get("error", "Could not export template."))

func _add_section() -> void:
    if _is_read_only():
        return
    var sections: Array = _current_template.get("sections", []).duplicate(true)
    var suffix := sections.size() + 1
    sections.append({
        "id": "section_%d" % suffix,
        "title": "New Section",
        "description": "",
        "kind": "standard",
        "fields": []
    })
    _current_template["sections"] = sections
    _selected_section = sections.size() - 1
    _selected_field = -1
    _refresh_section_list()

func _move_section(direction: int) -> void:
    if _is_read_only():
        return
    var sections: Array = _current_template.get("sections", []).duplicate(true)
    if _selected_section < 0 or _selected_section >= sections.size():
        return
    var target := _selected_section + direction
    if target < 0 or target >= sections.size():
        return
    var moving = sections[_selected_section]
    sections[_selected_section] = sections[target]
    sections[target] = moving
    _current_template["sections"] = sections
    _selected_section = target
    _refresh_section_list()

func _delete_section() -> void:
    if _is_read_only():
        return
    var sections: Array = _current_template.get("sections", []).duplicate(true)
    if _selected_section < 0 or _selected_section >= sections.size():
        return
    sections.remove_at(_selected_section)
    _current_template["sections"] = sections
    _selected_section = mini(_selected_section, sections.size() - 1)
    _selected_field = 0
    _refresh_section_list()

func _add_field() -> void:
    if _is_read_only() or _selected_section < 0:
        return
    var sections: Array = _current_template.get("sections", []).duplicate(true)
    var section: Dictionary = sections[_selected_section].duplicate(true)
    var fields: Array = section.get("fields", []).duplicate(true)
    var suffix := fields.size() + 1
    var section_id := str(section.get("id", "section"))
    fields.append({
        "id": "field_%d" % suffix,
        "label": "New Field",
        "type": "multiline",
        "path": "character.custom.%s_field_%d" % [section_id, suffix],
        "placeholder": "",
        "generate": true,
        "required": false,
        "generation_prompt": "",
        "height": 150
    })
    section["fields"] = fields
    sections[_selected_section] = section
    _current_template["sections"] = sections
    _selected_field = fields.size() - 1
    _refresh_field_list()

func _move_field(direction: int) -> void:
    if _is_read_only():
        return
    var sections: Array = _current_template.get("sections", []).duplicate(true)
    if _selected_section < 0 or _selected_section >= sections.size():
        return
    var section: Dictionary = sections[_selected_section].duplicate(true)
    var fields: Array = section.get("fields", []).duplicate(true)
    if _selected_field < 0 or _selected_field >= fields.size():
        return
    var target := _selected_field + direction
    if target < 0 or target >= fields.size():
        return
    var moving = fields[_selected_field]
    fields[_selected_field] = fields[target]
    fields[target] = moving
    section["fields"] = fields
    sections[_selected_section] = section
    _current_template["sections"] = sections
    _selected_field = target
    _refresh_field_list()

func _delete_field() -> void:
    if _is_read_only():
        return
    var sections: Array = _current_template.get("sections", []).duplicate(true)
    if _selected_section < 0 or _selected_section >= sections.size():
        return
    var section: Dictionary = sections[_selected_section].duplicate(true)
    var fields: Array = section.get("fields", []).duplicate(true)
    if _selected_field < 0 or _selected_field >= fields.size():
        return
    fields.remove_at(_selected_field)
    section["fields"] = fields
    sections[_selected_section] = section
    _current_template["sections"] = sections
    _selected_field = mini(_selected_field, fields.size() - 1)
    _refresh_field_list()

func _update_section_property(key: String, value: Variant) -> void:
    if _loading_ui or _is_read_only():
        return
    var sections: Array = _current_template.get("sections", []).duplicate(true)
    if _selected_section < 0 or _selected_section >= sections.size():
        return
    var section: Dictionary = sections[_selected_section].duplicate(true)
    section[key] = value
    sections[_selected_section] = section
    _current_template["sections"] = sections

func _update_field_property(key: String, value: Variant) -> void:
    if _loading_ui or _is_read_only():
        return
    var sections: Array = _current_template.get("sections", []).duplicate(true)
    if _selected_section < 0 or _selected_section >= sections.size():
        return
    var section: Dictionary = sections[_selected_section].duplicate(true)
    var fields: Array = section.get("fields", []).duplicate(true)
    if _selected_field < 0 or _selected_field >= fields.size():
        return
    var field: Dictionary = fields[_selected_field].duplicate(true)
    field[key] = value
    fields[_selected_field] = field
    section["fields"] = fields
    sections[_selected_section] = section
    _current_template["sections"] = sections

func _on_policy_changed(_index: int) -> void:
    if _loading_ui or _is_read_only():
        return
    _current_template["output_policy"] = {
        "mode": str(_policy_mode.get_selected_metadata()),
        "unexpected_fields": str(_unexpected_fields.get_selected_metadata())
    }

func _on_field_type_changed(_index: int) -> void:
    if not _loading_ui:
        _update_field_property("type", str(_field_type.get_selected_metadata()))
    _update_field_type_rows()

func _update_field_type_rows() -> void:
    var field_type := str(_field_type.get_selected_metadata())
    _field_height_row.visible = field_type == "multiline"
    _field_number_row.visible = field_type == "number"
    _field_options_row.visible = field_type == "select"

func _refresh_selected_template_label() -> void:
    var selected := _template_list.get_selected_items()
    if selected.is_empty():
        return
    var index := selected[0]
    var label := _template_name.text.strip_edges()
    if label.is_empty():
        label = "Unnamed Template"
    _template_list.set_item_text(index, label)

func _refresh_section_list_label() -> void:
    if _selected_section < 0 or _selected_section >= _section_list.item_count:
        return
    var label := _section_title.text.strip_edges()
    _section_list.set_item_text(_selected_section, label if not label.is_empty() else "Untitled Section")

func _refresh_field_list_label() -> void:
    if _selected_field < 0 or _selected_field >= _field_list.item_count:
        return
    var label := _field_label.text.strip_edges()
    if label.is_empty():
        label = "Untitled Field"
    if _field_generate.button_pressed:
        label += "  ✦"
    _field_list.set_item_text(_selected_field, label)

func _update_read_only_state() -> void:
    var read_only := _is_read_only()
    _save_button.disabled = read_only or _current_template_id.is_empty()
    _delete_button.disabled = read_only or _current_template_id.is_empty()
    _duplicate_button.disabled = _current_template_id.is_empty()
    _export_button.disabled = _current_template_id.is_empty()

    for control in [
        _template_name,
        _template_description,
        _global_rules,
        _section_id,
        _section_title,
        _section_description,
        _field_id,
        _field_label,
        _field_path,
        _field_placeholder,
        _field_generation_prompt,
        _field_options
    ]:
        if control is LineEdit:
            control.editable = not read_only
        elif control is TextEdit:
            control.editable = not read_only

    for control in [_policy_mode, _unexpected_fields, _section_kind, _field_type]:
        control.disabled = read_only
    for control in [_field_height, _field_minimum, _field_maximum, _field_step]:
        control.editable = not read_only
    _field_generate.disabled = read_only
    _field_required.disabled = read_only
    _section_up.disabled = read_only or _selected_section <= 0
    _section_down.disabled = read_only or _selected_section < 0 or _selected_section >= _section_list.item_count - 1
    _section_delete.disabled = read_only or _selected_section < 0
    _field_up.disabled = read_only or _selected_field <= 0
    _field_down.disabled = read_only or _selected_field < 0 or _selected_field >= _field_list.item_count - 1
    _field_delete.disabled = read_only or _selected_field < 0

func _selected_section_data() -> Dictionary:
    var sections = _current_template.get("sections", [])
    if not sections is Array or _selected_section < 0 or _selected_section >= sections.size():
        return {}
    var section = sections[_selected_section]
    return section if section is Dictionary else {}

func _selected_field_data() -> Dictionary:
    var section := _selected_section_data()
    if section.is_empty():
        return {}
    var fields = section.get("fields", [])
    if not fields is Array or _selected_field < 0 or _selected_field >= fields.size():
        return {}
    var field = fields[_selected_field]
    return field if field is Dictionary else {}

func _is_read_only() -> bool:
    return _current_template_id == "default"

func _add_line_field(parent: VBoxContainer, label_text: String) -> LineEdit:
    var label := Label.new()
    label.text = label_text
    parent.add_child(label)
    var edit := LineEdit.new()
    edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(edit)
    return edit

func _add_text_field(parent: VBoxContainer, label_text: String, height: int) -> TextEdit:
    var label := Label.new()
    label.text = label_text
    parent.add_child(label)
    var edit := TextEdit.new()
    edit.custom_minimum_size.y = height
    edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(edit)
    return edit

func _make_margin(amount: int) -> MarginContainer:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", amount)
    margin.add_theme_constant_override("margin_right", amount)
    margin.add_theme_constant_override("margin_top", amount)
    margin.add_theme_constant_override("margin_bottom", amount)
    return margin

func _make_spin(minimum: float, maximum: float, step: float) -> SpinBox:
    var spin := SpinBox.new()
    spin.min_value = minimum
    spin.max_value = maximum
    spin.step = step
    spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return spin

func _select_option_by_metadata(option: OptionButton, metadata_value: String) -> void:
    for index in range(option.item_count):
        if str(option.get_item_metadata(index)) == metadata_value:
            option.select(index)
            return
    if option.item_count > 0:
        option.select(0)

func _lines_to_array(text: String) -> Array[String]:
    var result: Array[String] = []
    for line in text.split("\n", false):
        var clean := line.strip_edges()
        if not clean.is_empty():
            result.append(clean)
    return result

func _comma_values(text: String) -> Array[String]:
    var result: Array[String] = []
    for item in text.split(",", false):
        var clean := item.strip_edges()
        if not clean.is_empty() and not result.has(clean):
            result.append(clean)
    return result

func _join_values(values: Array, separator: String) -> String:
    var result := ""
    for index in range(values.size()):
        if index > 0:
            result += separator
        result += str(values[index])
    return result

func _safe_filename(value: String) -> String:
    var result := value.strip_edges()
    for character in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
        result = result.replace(character, "_")
    return result if not result.is_empty() else "template"
