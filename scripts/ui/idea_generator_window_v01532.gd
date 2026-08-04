class_name CCFIdeaGeneratorWindowV01532
extends "res://scripts/ui/idea_generator_window_v01412.gd"

const NOTEBOOK_SERVICE = preload("res://scripts/services/idea_notebook_service_v01532.gd")

var _last_generated_ideas_v01532: Array = []
var _last_generation_metadata_v01532: Dictionary = {}
var _save_generated_button_v01532: Button
var _last_batch_label_v01532: Label

var _notebook_tab_v01532: VBoxContainer
var _notebook_filter_v01532: OptionButton
var _tag_filter_v01532: OptionButton
var _search_v01532: LineEdit
var _show_archived_v01532: CheckBox
var _idea_list_v01532: ItemList
var _visible_idea_ids_v01532: Array[String] = []
var _selected_idea_id_v01532 := ""
var _title_v01532: LineEdit
var _concept_v01532: TextEdit
var _notes_v01532: TextEdit
var _tags_v01532: LineEdit
var _idea_notebook_v01532: OptionButton
var _identity_v01532: Label
var _hook_v01532: Label
var _status_v01532: Label
var _archive_button_v01532: Button
var _save_changes_button_v01532: Button
var _delete_idea_button_v01532: Button
var _use_idea_button_v01532: Button

var _name_dialog_v01532: ConfirmationDialog
var _name_input_v01532: LineEdit
var _name_action_v01532 := ""
var _delete_notebook_dialog_v01532: ConfirmationDialog
var _delete_idea_dialog_v01532: ConfirmationDialog
var _save_generated_window_v01532: Window
var _save_generated_checks_v01532: Array[CheckBox] = []
var _save_generated_notebook_v01532: OptionButton
var _save_generated_status_v01532: Label


func _ready() -> void:
	super._ready()
	title = "Idea Generator + Notebook"
	_build_notebook_tab_v01532()
	_build_notebook_dialogs_v01532()
	_refresh_notebook_v01532()


func _build_ai_tab() -> void:
	super._build_ai_tab()
	var tab := _tabs.get_node_or_null("AI Ideas") as VBoxContainer
	if tab == null:
		return
	var toolbar := HFlowContainer.new()
	toolbar.name = "IdeaNotebookActionsV01532"
	toolbar.add_theme_constant_override("separation", 8)
	_save_generated_button_v01532 = Button.new()
	_save_generated_button_v01532.text = "Save Generated Ideas…"
	_save_generated_button_v01532.disabled = true
	_save_generated_button_v01532.tooltip_text = "Choose which ideas from the latest completed AI Ideas batch to keep in Idea Notebook. Generated ideas are never saved automatically."
	_save_generated_button_v01532.pressed.connect(_open_save_generated_v01532)
	toolbar.add_child(_save_generated_button_v01532)
	var open_notebook := Button.new()
	open_notebook.text = "Open Idea Notebook"
	open_notebook.pressed.connect(_show_notebook_tab_v01532)
	toolbar.add_child(open_notebook)
	_last_batch_label_v01532 = Label.new()
	_last_batch_label_v01532.text = "No completed AI Ideas batch captured yet."
	_last_batch_label_v01532.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toolbar.add_child(_last_batch_label_v01532)
	tab.add_child(toolbar)
	if _ai_ideas_host != null:
		tab.move_child(toolbar, _ai_ideas_host.get_index())


func set_last_generated_ideas_v01532(ideas: Array, metadata: Dictionary = {}) -> void:
	_last_generated_ideas_v01532.clear()
	for value in ideas:
		if value is Dictionary:
			_last_generated_ideas_v01532.append((value as Dictionary).duplicate(true))
	_last_generation_metadata_v01532 = metadata.duplicate(true)
	if _save_generated_button_v01532 != null:
		_save_generated_button_v01532.disabled = _last_generated_ideas_v01532.is_empty()
	if _last_batch_label_v01532 != null:
		if _last_generated_ideas_v01532.is_empty():
			_last_batch_label_v01532.text = "The last AI Ideas job returned no saveable ideas."
		else:
			_last_batch_label_v01532.text = "%d unsaved generated idea%s available." % [
				_last_generated_ideas_v01532.size(),
				"" if _last_generated_ideas_v01532.size() == 1 else "s"
			]


func open_notebook_v01532() -> void:
	open_studio()
	_show_notebook_tab_v01532()


func _show_notebook_tab_v01532() -> void:
	_refresh_notebook_v01532()
	for index in range(_tabs.get_tab_count()):
		if _tabs.get_tab_title(index) == "Idea Notebook":
			_tabs.current_tab = index
			return


func _build_notebook_tab_v01532() -> void:
	_notebook_tab_v01532 = VBoxContainer.new()
	_notebook_tab_v01532.name = "Idea Notebook"
	_notebook_tab_v01532.add_theme_constant_override("separation", 8)
	_tabs.add_child(_notebook_tab_v01532)

	var intro := Label.new()
	intro.text = "Keep only the ideas you want. Named notebooks organise ideas; tags and search work across notebooks. Saved ideas live independently of Character Projects."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notebook_tab_v01532.add_child(intro)

	var filters := HFlowContainer.new()
	filters.add_theme_constant_override("separation", 8)
	_notebook_tab_v01532.add_child(filters)
	_notebook_filter_v01532 = OptionButton.new()
	_notebook_filter_v01532.custom_minimum_size.x = 220
	_notebook_filter_v01532.item_selected.connect(func(_index: int) -> void: _refresh_ideas_v01532())
	filters.add_child(_notebook_filter_v01532)
	var new_notebook := Button.new()
	new_notebook.text = "New Notebook…"
	new_notebook.pressed.connect(func() -> void: _open_name_dialog_v01532("new"))
	filters.add_child(new_notebook)
	var rename_notebook := Button.new()
	rename_notebook.text = "Rename…"
	rename_notebook.pressed.connect(func() -> void: _open_name_dialog_v01532("rename"))
	filters.add_child(rename_notebook)
	var delete_notebook := Button.new()
	delete_notebook.text = "Delete Notebook…"
	delete_notebook.tooltip_text = "Deletes the notebook only. Its ideas move to Unfiled."
	delete_notebook.pressed.connect(_request_delete_notebook_v01532)
	filters.add_child(delete_notebook)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(spacer)
	_search_v01532 = LineEdit.new()
	_search_v01532.placeholder_text = "Search saved ideas…"
	_search_v01532.custom_minimum_size.x = 230
	_search_v01532.text_changed.connect(func(_text: String) -> void: _refresh_ideas_v01532())
	filters.add_child(_search_v01532)
	_tag_filter_v01532 = OptionButton.new()
	_tag_filter_v01532.custom_minimum_size.x = 170
	_tag_filter_v01532.item_selected.connect(func(_index: int) -> void: _refresh_ideas_v01532())
	filters.add_child(_tag_filter_v01532)
	_show_archived_v01532 = CheckBox.new()
	_show_archived_v01532.text = "Show archived"
	_show_archived_v01532.toggled.connect(func(_pressed: bool) -> void: _refresh_notebook_v01532())
	filters.add_child(_show_archived_v01532)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 330
	_notebook_tab_v01532.add_child(split)

	var list_panel := VBoxContainer.new()
	list_panel.custom_minimum_size.x = 280
	split.add_child(list_panel)
	var list_heading := Label.new()
	list_heading.text = "Saved Ideas"
	list_heading.add_theme_font_size_override("font_size", 17)
	list_panel.add_child(list_heading)
	_idea_list_v01532 = ItemList.new()
	_idea_list_v01532.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_idea_list_v01532.allow_reselect = true
	_idea_list_v01532.item_selected.connect(_on_idea_selected_v01532)
	list_panel.add_child(_idea_list_v01532)

	var editor_scroll := ScrollContainer.new()
	editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(editor_scroll)
	var editor := VBoxContainer.new()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.add_theme_constant_override("separation", 7)
	editor_scroll.add_child(editor)

	var editor_heading := Label.new()
	editor_heading.text = "Idea Details"
	editor_heading.add_theme_font_size_override("font_size", 17)
	editor.add_child(editor_heading)
	_title_v01532 = LineEdit.new()
	_title_v01532.placeholder_text = "Idea title"
	editor.add_child(_labelled_control_v01532("Title", _title_v01532))
	_identity_v01532 = Label.new()
	_identity_v01532.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_identity_v01532.modulate = Color(0.72, 0.76, 0.86)
	editor.add_child(_identity_v01532)
	_hook_v01532 = Label.new()
	_hook_v01532.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hook_v01532.modulate = Color(0.72, 0.76, 0.86)
	editor.add_child(_hook_v01532)
	_concept_v01532 = TextEdit.new()
	_concept_v01532.custom_minimum_size.y = 220
	_concept_v01532.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.add_child(_labelled_control_v01532("Concept", _concept_v01532))
	_notes_v01532 = TextEdit.new()
	_notes_v01532.custom_minimum_size.y = 100
	_notes_v01532.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.add_child(_labelled_control_v01532("Private idea notes", _notes_v01532))
	_tags_v01532 = LineEdit.new()
	_tags_v01532.placeholder_text = "university, romance, roommates"
	editor.add_child(_labelled_control_v01532("Tags (comma separated)", _tags_v01532))
	_idea_notebook_v01532 = OptionButton.new()
	editor.add_child(_labelled_control_v01532("Notebook", _idea_notebook_v01532))

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	editor.add_child(actions)
	_save_changes_button_v01532 = Button.new()
	_save_changes_button_v01532.text = "Save Changes"
	_save_changes_button_v01532.pressed.connect(_save_selected_idea_v01532)
	actions.add_child(_save_changes_button_v01532)
	_archive_button_v01532 = Button.new()
	_archive_button_v01532.text = "Archive"
	_archive_button_v01532.pressed.connect(_toggle_archive_v01532)
	actions.add_child(_archive_button_v01532)
	_delete_idea_button_v01532 = Button.new()
	_delete_idea_button_v01532.text = "Delete…"
	_delete_idea_button_v01532.pressed.connect(_request_delete_idea_v01532)
	actions.add_child(_delete_idea_button_v01532)
	var action_spacer := Control.new()
	action_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(action_spacer)
	_use_idea_button_v01532 = Button.new()
	_use_idea_button_v01532.text = "Use as Main Concept"
	_use_idea_button_v01532.pressed.connect(_use_selected_idea_v01532)
	actions.add_child(_use_idea_button_v01532)

	_status_v01532 = Label.new()
	_status_v01532.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_v01532.modulate = Color(0.72, 0.76, 0.86)
	_notebook_tab_v01532.add_child(_status_v01532)
	_set_editor_enabled_v01532(false)


func _labelled_control_v01532(label_text: String, control: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var label := Label.new()
	label.text = label_text
	box.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(control)
	return box


func _build_notebook_dialogs_v01532() -> void:
	_name_dialog_v01532 = ConfirmationDialog.new()
	_name_dialog_v01532.visible = false
	_name_dialog_v01532.title = "Idea Notebook"
	_name_input_v01532 = LineEdit.new()
	_name_input_v01532.placeholder_text = "Notebook name"
	_name_input_v01532.custom_minimum_size.x = 360
	_name_dialog_v01532.add_child(_name_input_v01532)
	_name_dialog_v01532.confirmed.connect(_apply_name_dialog_v01532)
	add_child(_name_dialog_v01532)
	_name_dialog_v01532.hide()

	_delete_notebook_dialog_v01532 = ConfirmationDialog.new()
	_delete_notebook_dialog_v01532.visible = false
	_delete_notebook_dialog_v01532.title = "Delete Idea Notebook"
	_delete_notebook_dialog_v01532.ok_button_text = "Delete Notebook"
	_delete_notebook_dialog_v01532.confirmed.connect(_delete_selected_notebook_v01532)
	add_child(_delete_notebook_dialog_v01532)
	_delete_notebook_dialog_v01532.hide()

	_delete_idea_dialog_v01532 = ConfirmationDialog.new()
	_delete_idea_dialog_v01532.visible = false
	_delete_idea_dialog_v01532.title = "Delete Saved Idea"
	_delete_idea_dialog_v01532.ok_button_text = "Delete Idea"
	_delete_idea_dialog_v01532.confirmed.connect(_delete_selected_idea_v01532)
	add_child(_delete_idea_dialog_v01532)
	_delete_idea_dialog_v01532.hide()

	_save_generated_window_v01532 = Window.new()
	_save_generated_window_v01532.visible = false
	_save_generated_window_v01532.title = "Save Generated Ideas"
	_save_generated_window_v01532.size = Vector2i(760, 650)
	_save_generated_window_v01532.min_size = Vector2i(620, 480)
	_save_generated_window_v01532.force_native = true
	_save_generated_window_v01532.transient = false
	_save_generated_window_v01532.exclusive = false
	_save_generated_window_v01532.close_requested.connect(_save_generated_window_v01532.hide)
	add_child(_save_generated_window_v01532)
	_save_generated_window_v01532.hide()


func _open_save_generated_v01532() -> void:
	if _last_generated_ideas_v01532.is_empty():
		return
	for child in _save_generated_window_v01532.get_children():
		child.queue_free()
	_save_generated_checks_v01532.clear()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_save_generated_window_v01532.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var intro := Label.new()
	intro.text = "Choose which ideas from the latest completed batch to keep. Nothing is saved until Save Selected is pressed."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)
	var target_row := HBoxContainer.new()
	root.add_child(target_row)
	var target_label := Label.new()
	target_label.text = "Save to:"
	target_row.add_child(target_label)
	_save_generated_notebook_v01532 = OptionButton.new()
	_save_generated_notebook_v01532.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_row.add_child(_save_generated_notebook_v01532)
	_fill_destination_notebooks_v01532(_save_generated_notebook_v01532, "")
	var select_all := Button.new()
	select_all.text = "Select All"
	select_all.pressed.connect(func() -> void:
		for check in _save_generated_checks_v01532:
			check.button_pressed = true
	)
	target_row.add_child(select_all)
	var select_none := Button.new()
	select_none.text = "Select None"
	select_none.pressed.connect(func() -> void:
		for check in _save_generated_checks_v01532:
			check.button_pressed = false
	)
	target_row.add_child(select_none)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for index in range(_last_generated_ideas_v01532.size()):
		var idea_value: Variant = _last_generated_ideas_v01532[index]
		if not idea_value is Dictionary:
			continue
		var idea: Dictionary = idea_value
		var panel := VBoxContainer.new()
		panel.add_theme_constant_override("separation", 3)
		var check := CheckBox.new()
		check.button_pressed = true
		check.text = str(idea.get("title", "Untitled idea"))
		check.set_meta("idea_index_v01532", index)
		panel.add_child(check)
		_save_generated_checks_v01532.append(check)
		var preview := Label.new()
		preview.text = _truncate_v01532(str(idea.get("concept", "")), 320)
		preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview.modulate = Color(0.72, 0.76, 0.86)
		panel.add_child(preview)
		var tags := Label.new()
		tags.text = "Tags: %s" % ", ".join(idea.get("tags", []))
		tags.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(tags)
		list.add_child(panel)
		if index < _last_generated_ideas_v01532.size() - 1:
			list.add_child(HSeparator.new())
	_save_generated_status_v01532 = Label.new()
	_save_generated_status_v01532.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_save_generated_status_v01532)
	var actions := HBoxContainer.new()
	root.add_child(actions)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_save_generated_window_v01532.hide)
	actions.add_child(cancel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var save := Button.new()
	save.text = "Save Selected"
	save.pressed.connect(_save_selected_generated_v01532)
	actions.add_child(save)
	_save_generated_window_v01532.popup_centered()


func _save_selected_generated_v01532() -> void:
	var notebook_id := _selected_metadata_v01532(_save_generated_notebook_v01532, "")
	var source := {
		"type": "idea_generator",
		"seed_prompt": str(_last_generation_metadata_v01532.get("seed", "")),
		"idea_contract_version": str(_last_generation_metadata_v01532.get("idea_contract_version", "")),
		"project_id": str(_last_generation_metadata_v01532.get("project_id", "")),
		"captured_at": Time.get_datetime_string_from_system(true)
	}
	var saved_count := 0
	var errors: Array[String] = []
	for check in _save_generated_checks_v01532:
		if not check.button_pressed:
			continue
		var index := int(check.get_meta("idea_index_v01532", -1))
		if index < 0 or index >= _last_generated_ideas_v01532.size():
			continue
		var idea_value: Variant = _last_generated_ideas_v01532[index]
		if not idea_value is Dictionary:
			continue
		var result := NOTEBOOK_SERVICE.save_generated_idea(idea_value as Dictionary, notebook_id, source)
		if bool(result.get("ok", false)):
			saved_count += 1
		else:
			errors.append(str(result.get("error", "Unknown save error.")))
	if saved_count == 0 and errors.is_empty():
		_save_generated_status_v01532.text = "Select at least one idea to save."
		return
	if not errors.is_empty():
		_save_generated_status_v01532.text = "Saved %d idea%s; %d failed: %s" % [saved_count, "" if saved_count == 1 else "s", errors.size(), " | ".join(errors)]
		_refresh_notebook_v01532()
		return
	_save_generated_window_v01532.hide()
	_refresh_notebook_v01532()
	_status_v01532.text = "Saved %d generated idea%s to Idea Notebook." % [saved_count, "" if saved_count == 1 else "s"]


func _refresh_notebook_v01532() -> void:
	if _notebook_filter_v01532 == null:
		return
	var selected_filter := _selected_metadata_v01532(_notebook_filter_v01532, "__all__")
	var selected_tag := _selected_metadata_v01532(_tag_filter_v01532, "")
	var counts := NOTEBOOK_SERVICE.notebook_counts(_show_archived_v01532 != null and _show_archived_v01532.button_pressed)
	_notebook_filter_v01532.clear()
	_add_option_v01532(_notebook_filter_v01532, "All Ideas (%d)" % int(counts.get("__all__", 0)), "__all__")
	_add_option_v01532(_notebook_filter_v01532, "Unfiled (%d)" % int(counts.get("__unfiled__", 0)), "__unfiled__")
	for notebook in NOTEBOOK_SERVICE.list_notebooks():
		var notebook_id := str(notebook.get("id", ""))
		_add_option_v01532(_notebook_filter_v01532, "%s (%d)" % [str(notebook.get("name", "Notebook")), int(counts.get(notebook_id, 0))], notebook_id)
	_select_metadata_v01532(_notebook_filter_v01532, selected_filter, "__all__")
	_tag_filter_v01532.clear()
	_add_option_v01532(_tag_filter_v01532, "All Tags", "")
	for tag in NOTEBOOK_SERVICE.all_tags(_show_archived_v01532 != null and _show_archived_v01532.button_pressed):
		_add_option_v01532(_tag_filter_v01532, tag, tag)
	_select_metadata_v01532(_tag_filter_v01532, selected_tag, "")
	_refresh_ideas_v01532()


func _refresh_ideas_v01532() -> void:
	if _idea_list_v01532 == null:
		return
	var filters := {
		"notebook_id": _selected_metadata_v01532(_notebook_filter_v01532, "__all__"),
		"tag": _selected_metadata_v01532(_tag_filter_v01532, ""),
		"search": _search_v01532.text if _search_v01532 != null else "",
		"include_archived": _show_archived_v01532 != null and _show_archived_v01532.button_pressed
	}
	var rows := NOTEBOOK_SERVICE.list_ideas(filters)
	_idea_list_v01532.clear()
	_visible_idea_ids_v01532.clear()
	var reselect_index := -1
	for idea in rows:
		var title := str(idea.get("title", "Untitled idea"))
		if bool(idea.get("archived", false)):
			title += "  [Archived]"
		var subtitle := str(idea.get("character_role", "")).strip_edges()
		if subtitle.is_empty():
			subtitle = ", ".join(idea.get("tags", []))
		var display := title + ("\n" + subtitle if not subtitle.is_empty() else "")
		_idea_list_v01532.add_item(display)
		var idea_id := str(idea.get("id", ""))
		_visible_idea_ids_v01532.append(idea_id)
		if idea_id == _selected_idea_id_v01532:
			reselect_index = _visible_idea_ids_v01532.size() - 1
	if reselect_index >= 0:
		_idea_list_v01532.select(reselect_index)
		_load_selected_idea_v01532(_selected_idea_id_v01532)
	elif not rows.is_empty():
		_idea_list_v01532.select(0)
		_selected_idea_id_v01532 = _visible_idea_ids_v01532[0]
		_load_selected_idea_v01532(_selected_idea_id_v01532)
	else:
		_selected_idea_id_v01532 = ""
		_clear_editor_v01532()
		_set_editor_enabled_v01532(false)
		_status_v01532.text = "No saved ideas match the current notebook, tag and search filters."


func _on_idea_selected_v01532(index: int) -> void:
	if index < 0 or index >= _visible_idea_ids_v01532.size():
		return
	_selected_idea_id_v01532 = _visible_idea_ids_v01532[index]
	_load_selected_idea_v01532(_selected_idea_id_v01532)


func _load_selected_idea_v01532(idea_id: String) -> void:
	var loaded := NOTEBOOK_SERVICE.load_idea(idea_id)
	if not bool(loaded.get("ok", false)):
		_status_v01532.text = str(loaded.get("error", "Could not load saved idea."))
		return
	var idea: Dictionary = loaded.get("data", {})
	_title_v01532.text = str(idea.get("title", ""))
	_concept_v01532.text = str(idea.get("concept", ""))
	_notes_v01532.text = str(idea.get("notes", ""))
	_tags_v01532.text = ", ".join(idea.get("tags", []))
	var identity_parts: Array[String] = []
	var character_name := str(idea.get("character_name", "")).strip_edges()
	var character_role := str(idea.get("character_role", "")).strip_edges()
	if not character_name.is_empty():
		identity_parts.append(character_name)
	if not character_role.is_empty():
		identity_parts.append(character_role)
	_identity_v01532.text = "Generated character: %s" % " • ".join(identity_parts) if not identity_parts.is_empty() else ""
	var hook := str(idea.get("roleplay_hook", "")).strip_edges()
	_hook_v01532.text = "Roleplay hook: %s" % hook if not hook.is_empty() else ""
	_fill_destination_notebooks_v01532(_idea_notebook_v01532, str(idea.get("notebook_id", "")))
	_archive_button_v01532.text = "Restore" if bool(idea.get("archived", false)) else "Archive"
	_set_editor_enabled_v01532(true)
	_status_v01532.text = "Saved idea loaded. Changes remain local to Idea Notebook until you explicitly use the concept."


func _save_selected_idea_v01532() -> void:
	if _selected_idea_id_v01532.is_empty():
		return
	var result := NOTEBOOK_SERVICE.update_idea(
		_selected_idea_id_v01532,
		{
			"title": _title_v01532.text,
			"concept": _concept_v01532.text,
			"notes": _notes_v01532.text,
			"tags": _tags_v01532.text,
			"notebook_id": _selected_metadata_v01532(_idea_notebook_v01532, "")
		}
	)
	if not bool(result.get("ok", false)):
		_status_v01532.text = str(result.get("error", "Could not save idea."))
		return
	_status_v01532.text = "Idea changes saved."
	_refresh_notebook_v01532()


func _toggle_archive_v01532() -> void:
	if _selected_idea_id_v01532.is_empty():
		return
	var loaded := NOTEBOOK_SERVICE.load_idea(_selected_idea_id_v01532)
	if not bool(loaded.get("ok", false)):
		return
	var idea: Dictionary = loaded.get("data", {})
	var result := NOTEBOOK_SERVICE.update_idea(_selected_idea_id_v01532, {"archived": not bool(idea.get("archived", false))})
	if not bool(result.get("ok", false)):
		_status_v01532.text = str(result.get("error", "Could not update archive state."))
		return
	_refresh_notebook_v01532()


func _request_delete_idea_v01532() -> void:
	if _selected_idea_id_v01532.is_empty():
		return
	_delete_idea_dialog_v01532.dialog_text = "Delete this saved idea permanently? This does not affect any Character Project or character already created from its concept."
	_delete_idea_dialog_v01532.popup_centered()


func _delete_selected_idea_v01532() -> void:
	if _selected_idea_id_v01532.is_empty():
		return
	var result := NOTEBOOK_SERVICE.delete_idea(_selected_idea_id_v01532)
	if not bool(result.get("ok", false)):
		_status_v01532.text = str(result.get("error", "Could not delete idea."))
		return
	_selected_idea_id_v01532 = ""
	_refresh_notebook_v01532()
	_status_v01532.text = "Saved idea deleted."


func _use_selected_idea_v01532() -> void:
	if _selected_idea_id_v01532.is_empty():
		return
	var loaded := NOTEBOOK_SERVICE.load_idea(_selected_idea_id_v01532)
	if not bool(loaded.get("ok", false)):
		_status_v01532.text = str(loaded.get("error", "Could not load idea."))
		return
	var idea: Dictionary = loaded.get("data", {})
	var concept := str(idea.get("concept", "")).strip_edges()
	if concept.is_empty():
		_status_v01532.text = "This saved idea has no concept text."
		return
	concept_selected.emit(concept)
	hide()


func _open_name_dialog_v01532(action: String) -> void:
	_name_action_v01532 = action
	if action == "rename":
		var notebook_id := _selected_named_notebook_v01532()
		if notebook_id.is_empty():
			_status_v01532.text = "Select a named notebook before renaming it. All Ideas and Unfiled are built-in views."
			return
		_name_dialog_v01532.dialog_text = "Rename the selected notebook."
		_name_input_v01532.text = _selected_notebook_name_v01532()
		_name_dialog_v01532.ok_button_text = "Rename"
	else:
		_name_dialog_v01532.dialog_text = "Create a named notebook for organising saved ideas."
		_name_input_v01532.text = ""
		_name_dialog_v01532.ok_button_text = "Create"
	_name_dialog_v01532.popup_centered()
	_name_input_v01532.grab_focus()


func _apply_name_dialog_v01532() -> void:
	if _name_action_v01532 == "rename":
		var notebook_id := _selected_named_notebook_v01532()
		var result := NOTEBOOK_SERVICE.rename_notebook(notebook_id, _name_input_v01532.text)
		if not bool(result.get("ok", false)):
			_status_v01532.text = str(result.get("error", "Could not rename notebook."))
			return
	else:
		var result := NOTEBOOK_SERVICE.create_notebook(_name_input_v01532.text)
		if not bool(result.get("ok", false)):
			_status_v01532.text = str(result.get("error", "Could not create notebook."))
			return
	_refresh_notebook_v01532()


func _request_delete_notebook_v01532() -> void:
	var notebook_id := _selected_named_notebook_v01532()
	if notebook_id.is_empty():
		_status_v01532.text = "Select a named notebook before deleting it. All Ideas and Unfiled cannot be deleted."
		return
	_delete_notebook_dialog_v01532.dialog_text = "Delete notebook '%s'? Its saved ideas will be kept and moved to Unfiled." % _selected_notebook_name_v01532()
	_delete_notebook_dialog_v01532.popup_centered()


func _delete_selected_notebook_v01532() -> void:
	var notebook_id := _selected_named_notebook_v01532()
	if notebook_id.is_empty():
		return
	var result := NOTEBOOK_SERVICE.delete_notebook(notebook_id)
	if not bool(result.get("ok", false)):
		_status_v01532.text = str(result.get("error", "Could not delete notebook."))
		return
	_refresh_notebook_v01532()
	_status_v01532.text = "Notebook deleted; its ideas are now Unfiled."


func _fill_destination_notebooks_v01532(selector: OptionButton, selected_id: String) -> void:
	if selector == null:
		return
	selector.clear()
	_add_option_v01532(selector, "Unfiled", "")
	for notebook in NOTEBOOK_SERVICE.list_notebooks():
		_add_option_v01532(selector, str(notebook.get("name", "Notebook")), str(notebook.get("id", "")))
	_select_metadata_v01532(selector, selected_id, "")


func _selected_named_notebook_v01532() -> String:
	var value := _selected_metadata_v01532(_notebook_filter_v01532, "__all__")
	if value == "__all__" or value == "__unfiled__":
		return ""
	return value


func _selected_notebook_name_v01532() -> String:
	if _notebook_filter_v01532 == null or _notebook_filter_v01532.selected < 0:
		return ""
	var text := _notebook_filter_v01532.get_item_text(_notebook_filter_v01532.selected)
	var count_at := text.rfind(" (")
	return text.substr(0, count_at) if count_at > 0 else text


func _add_option_v01532(selector: OptionButton, text: String, value: String) -> void:
	selector.add_item(text)
	selector.set_item_metadata(selector.item_count - 1, value)


func _selected_metadata_v01532(selector: OptionButton, fallback: String) -> String:
	if selector == null or selector.selected < 0 or selector.selected >= selector.item_count:
		return fallback
	return str(selector.get_item_metadata(selector.selected))


func _select_metadata_v01532(selector: OptionButton, value: String, fallback: String) -> void:
	if selector == null:
		return
	var fallback_index := 0
	for index in range(selector.item_count):
		var metadata := str(selector.get_item_metadata(index))
		if metadata == fallback:
			fallback_index = index
		if metadata == value:
			selector.select(index)
			return
	if selector.item_count > 0:
		selector.select(fallback_index)


func _clear_editor_v01532() -> void:
	if _title_v01532 != null:
		_title_v01532.text = ""
	if _concept_v01532 != null:
		_concept_v01532.text = ""
	if _notes_v01532 != null:
		_notes_v01532.text = ""
	if _tags_v01532 != null:
		_tags_v01532.text = ""
	if _identity_v01532 != null:
		_identity_v01532.text = ""
	if _hook_v01532 != null:
		_hook_v01532.text = ""


func _set_editor_enabled_v01532(enabled: bool) -> void:
	for control in [_title_v01532, _concept_v01532, _notes_v01532, _tags_v01532, _idea_notebook_v01532]:
		if control == null:
			continue
		if control is LineEdit:
			(control as LineEdit).editable = enabled
		elif control is TextEdit:
			(control as TextEdit).editable = enabled
		elif control is OptionButton:
			(control as OptionButton).disabled = not enabled
	for button in [_save_changes_button_v01532, _archive_button_v01532, _delete_idea_button_v01532, _use_idea_button_v01532]:
		if button != null:
			button.disabled = not enabled


func _truncate_v01532(text: String, limit: int) -> String:
	var clean := text.strip_edges().replace("\n", " ")
	if clean.length() <= limit:
		return clean
	return clean.substr(0, maxi(0, limit - 1)).strip_edges() + "…"
