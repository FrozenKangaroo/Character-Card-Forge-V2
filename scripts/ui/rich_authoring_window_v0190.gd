class_name CCFRichAuthoringWindowV0190
extends Window

signal project_changed_v0190(
	updated_project: Dictionary, active_character_id: String, message_text: String
)
signal project_created_v0190(project: Dictionary)
signal split_generation_requested_v0190(
	batch_id: String, retry_character_ids: Array[String]
)

const AUTHORING_SERVICE = preload(
	"res://scripts/services/rich_authoring_service_v0190.gd"
)

var _project: Dictionary = {}
var _active_character_id := ""
var _project_id := ""
var _status: Label

var _scenario_selector: OptionButton
var _scenario_title: LineEdit
var _scenario_text: TextEdit
var _scenario_opening: TextEdit
var _scenario_active_ids: LineEdit
var _scenario_world_ids: LineEdit
var _scenario_tags: LineEdit
var _scenario_favourite: CheckBox
var _scenario_preview: TextEdit

var _greeting_selector: OptionButton
var _greeting_text: TextEdit
var _greeting_category: LineEdit
var _greeting_tags: LineEdit
var _greeting_weight: SpinBox
var _greeting_favourite: CheckBox
var _greeting_front_porch_seed: TextEdit
var _greeting_preview: TextEdit

var _library_character_selector: OptionButton
var _new_member_name: LineEdit
var _ensemble_summary: RichTextLabel
var _shared_concept: TextEdit
var _member_seed_lines: TextEdit
var _batch_selector: OptionButton
var _batch_report: TextEdit

var _world_checks: Dictionary = {}
var _dependency_report: TextEdit
var _lineage_report: TextEdit
var _custom_metadata: TextEdit
var _export_mappings: TextEdit
var _mapping_preview: TextEdit


func _ready() -> void:
	visible = false
	title = "Rich Scenario, Greeting, World and Ensemble Authoring"
	size = Vector2i(1320, 900)
	min_size = Vector2i(980, 680)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(_hide_window)
	_build_ui()
	hide()


func open_for_project(project: Dictionary, active_character_id: String) -> void:
	_project = project.duplicate(true)
	_project_id = str(project.get("project_id", ""))
	_active_character_id = active_character_id
	_refresh_all()
	_status.text = "Authoring changes stay in this project until you save it. Materialised previews never alter their source characters."
	CCFToolWindowStateService.show_window(self, "rich_authoring_v0190", Vector2i(1320, 900))


func update_project_context(project: Dictionary, active_character_id: String) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	_project = project.duplicate(true)
	_active_character_id = active_character_id
	_refresh_all()


func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and project_id == _project_id


func save_window_state() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "rich_authoring_v0190")


func handle_split_completed(
	job_id: String, data: Variant, metadata: Dictionary
) -> bool:
	if str(metadata.get("project_id", "")) != _project_id:
		return false
	var batch_id := str(metadata.get("batch_id", ""))
	var result := AUTHORING_SERVICE.apply_split_result(
		_project,
		batch_id,
		data,
		{
			"model": str(metadata.get("model", "")),
			"profile_id": str(metadata.get("profile_id", "")),
			"job_id": job_id
		}
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "The split result could not be applied."))
		return true
	_project = result.get("project", {}).duplicate(true)
	_refresh_batches()
	_refresh_reports()
	var completed_count := (result.get("completed_character_ids", []) as Array).size()
	var message_text := "%d split character%s generated." % [
		completed_count, "" if completed_count == 1 else "s"
	]
	if bool(result.get("partial", false)):
		message_text += " Some members failed validation and can be retried independently."
	_status.text = message_text
	project_changed_v0190.emit(_project.duplicate(true), _active_character_id, message_text)
	return true


func handle_split_failed(message_text: String) -> void:
	_status.text = message_text


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	margin.add_child(root)

	var intro := Label.new()
	intro.text = "Create reusable setups and openings, coordinate ensembles, generate independent split sets, link shared worlds and inspect dependencies. Raw group JSON remains in Expert tools."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	_build_scenario_tab(tabs)
	_build_greeting_tab(tabs)
	_build_ensemble_tab(tabs)
	_build_world_tab(tabs)
	_build_metadata_tab(tabs)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.69, 0.73, 0.86)
	root.add_child(_status)


func _build_scenario_tab(tabs: TabContainer) -> void:
	var root := _tab_root(tabs, "Scenario Presets")
	var selector_row := HBoxContainer.new()
	selector_row.add_theme_constant_override("separation", 8)
	root.add_child(selector_row)
	_scenario_selector = OptionButton.new()
	_scenario_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scenario_selector.item_selected.connect(_load_selected_scenario)
	selector_row.add_child(_scenario_selector)
	selector_row.add_child(_button("New Setup", _new_scenario))
	selector_row.add_child(_button("Save Setup", _save_scenario))
	selector_row.add_child(_button("Delete", _delete_scenario))
	selector_row.add_child(_button("Preview Single-Scenario Export", _preview_scenario))
	_scenario_title = _line_field(root, "Setup name")
	_scenario_text = _text_field(root, "Scenario", 150)
	_scenario_opening = _text_field(root, "Opening message", 150)
	_scenario_active_ids = _line_field(root, "Characters active/present in this setup (stable IDs, comma separated)")
	_scenario_world_ids = _line_field(root, "Shared world IDs (comma separated)")
	_scenario_tags = _line_field(root, "Categories / tags (comma separated)")
	_scenario_favourite = CheckBox.new()
	_scenario_favourite.text = "Favourite setup"
	root.add_child(_scenario_favourite)
	_scenario_preview = _text_field(root, "Complete materialisation preview (read-only)", 230)
	_scenario_preview.editable = false


func _build_greeting_tab(tabs: TabContainer) -> void:
	var root := _tab_root(tabs, "Greeting Manager")
	var selector_row := HBoxContainer.new()
	selector_row.add_theme_constant_override("separation", 8)
	root.add_child(selector_row)
	_greeting_selector = OptionButton.new()
	_greeting_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_greeting_selector.item_selected.connect(_load_selected_greeting)
	selector_row.add_child(_greeting_selector)
	selector_row.add_child(_button("New Greeting", _new_greeting))
	selector_row.add_child(_button("Save Greeting", _save_greeting))
	selector_row.add_child(_button("Delete", _delete_greeting))
	selector_row.add_child(_button("Preview Weighted Choice", _preview_greeting_choice))
	_greeting_text = _text_field(root, "Playable opening", 220)
	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 8)
	root.add_child(detail_row)
	_greeting_category = _line_field(detail_row, "Category")
	_greeting_tags = _line_field(detail_row, "Tags")
	var weight_box := VBoxContainer.new()
	detail_row.add_child(weight_box)
	var weight_label := Label.new()
	weight_label.text = "Random weight"
	weight_box.add_child(weight_label)
	_greeting_weight = SpinBox.new()
	_greeting_weight.min_value = 1
	_greeting_weight.max_value = 100
	_greeting_weight.value = 1
	weight_box.add_child(_greeting_weight)
	_greeting_favourite = CheckBox.new()
	_greeting_favourite.text = "Favourite"
	detail_row.add_child(_greeting_favourite)
	_greeting_front_porch_seed = _text_field(root, "Optional Front Porch opening-state seed", 105)
	_greeting_preview = _text_field(root, "Preview / test entry point", 150)
	_greeting_preview.editable = false


func _build_ensemble_tab(tabs: TabContainer) -> void:
	var root := _tab_root(tabs, "Multi-Character Workspace")
	var create_row := HFlowContainer.new()
	create_row.add_theme_constant_override("separation", 8)
	root.add_child(create_row)
	create_row.add_child(_button("New Multi-Character / Group Project", _create_group_project))
	_new_member_name = LineEdit.new()
	_new_member_name.placeholder_text = "New member name"
	_new_member_name.custom_minimum_size.x = 210
	create_row.add_child(_new_member_name)
	create_row.add_child(_button("Add New Member", _add_new_member))
	_library_character_selector = OptionButton.new()
	_library_character_selector.custom_minimum_size.x = 330
	create_row.add_child(_library_character_selector)
	create_row.add_child(_button("Add Existing Library Character", _add_library_character))

	_ensemble_summary = RichTextLabel.new()
	_ensemble_summary.fit_content = true
	_ensemble_summary.custom_minimum_size.y = 105
	_ensemble_summary.bbcode_enabled = true
	root.add_child(_ensemble_summary)
	var workflow_hint := Label.new()
	workflow_hint.text = "Use Card Workflows for the primary group controls: name, roster, scenario, opening, prompts, turn behavior, Director/chaos settings, objectives, opening state and lore/world references. Roster and active/present members are stored separately."
	workflow_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(workflow_hint)

	root.add_child(HSeparator.new())
	var split_heading := Label.new()
	split_heading.text = "Split Character Set"
	split_heading.add_theme_font_size_override("font_size", 18)
	root.add_child(split_heading)
	_shared_concept = _text_field(root, "Shared concept / project plan", 125)
	_member_seed_lines = _text_field(root, "Independent members — one per line as Name | Role", 105)
	var split_row := HBoxContainer.new()
	split_row.add_theme_constant_override("separation", 8)
	root.add_child(split_row)
	split_row.add_child(_button("Seed and Generate Set", _create_and_generate_split))
	_batch_selector = OptionButton.new()
	_batch_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_batch_selector.item_selected.connect(_show_selected_batch)
	split_row.add_child(_batch_selector)
	split_row.add_child(_button("Retry Failed Members", _retry_failed_split))
	_batch_report = _text_field(root, "Recoverable parent job and per-character results", 160)
	_batch_report.editable = false


func _build_world_tab(tabs: TabContainer) -> void:
	var root := _tab_root(tabs, "Shared Worlds & Dependencies")
	var hint := Label.new()
	hint.text = "Link project-level .fpworld records instead of copying lore into every character. Dependency warnings are available before referenced content is removed."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)
	var link_row := HBoxContainer.new()
	link_row.add_theme_constant_override("separation", 8)
	root.add_child(link_row)
	var world_panel := VBoxContainer.new()
	world_panel.name = "WorldLinkListV0190"
	world_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	link_row.add_child(world_panel)
	link_row.add_child(_button("Save Shared World Links", _save_world_links))
	_dependency_report = _text_field(root, "Characters, worlds, images, groups and collection dependencies", 420)
	_dependency_report.editable = false


func _build_metadata_tab(tabs: TabContainer) -> void:
	var root := _tab_root(tabs, "Lineage & Custom Metadata")
	_lineage_report = _text_field(root, "Variant, timeline, family and derivative lineage", 190)
	_lineage_report.editable = false
	_custom_metadata = _text_field(root, "Private custom metadata JSON object", 180)
	_export_mappings = _text_field(root, "Explicit export mappings JSON array [{source_key, target_key}]", 130)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	root.add_child(action_row)
	action_row.add_child(_button("Save Private Metadata", _save_private_metadata))
	action_row.add_child(_button("Preview Export Mapping", _preview_mappings))
	_mapping_preview = _text_field(root, "Mapped fields and omitted private keys", 170)
	_mapping_preview.editable = false


func _tab_root(tabs: TabContainer, tab_title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_title.to_snake_case()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, tab_title)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	return root


func _line_field(parent: Container, field_label: String) -> LineEdit:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var label_node := Label.new()
	label_node.text = field_label
	box.add_child(label_node)
	var editor := LineEdit.new()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(editor)
	return editor


func _text_field(parent: Container, field_label: String, height: int) -> TextEdit:
	var label_node := Label.new()
	label_node.text = field_label
	parent.add_child(label_node)
	var editor := TextEdit.new()
	editor.custom_minimum_size.y = height
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	parent.add_child(editor)
	return editor


func _button(button_text: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = button_text
	control.pressed.connect(callback)
	return control


func _refresh_all() -> void:
	_refresh_scenarios()
	_refresh_greetings()
	_refresh_ensemble()
	_refresh_library_characters()
	_refresh_batches()
	_refresh_world_links()
	_refresh_reports()
	_refresh_private_metadata()


func _active_character() -> Dictionary:
	return CCFStorageService.get_character(_project, _active_character_id)


func _store_active_character(character_record: Dictionary, message_text: String) -> void:
	CCFStorageService.update_character(_project, character_record)
	_status.text = message_text
	project_changed_v0190.emit(_project.duplicate(true), _active_character_id, message_text)


func _refresh_scenarios(preferred_id: String = "") -> void:
	_scenario_selector.clear()
	_scenario_selector.add_item("New / unsaved setup")
	_scenario_selector.set_item_metadata(0, "")
	var selected_index := 0
	var item_index := 1
	for preset in AUTHORING_SERVICE.scenario_presets(_active_character()):
		_scenario_selector.add_item(str(preset.get("name", "Untitled Setup")))
		_scenario_selector.set_item_metadata(item_index, str(preset.get("scenario_id", "")))
		if str(preset.get("scenario_id", "")) == preferred_id:
			selected_index = item_index
		item_index += 1
	_scenario_selector.select(selected_index)
	_load_selected_scenario(selected_index)


func _load_selected_scenario(index: int) -> void:
	var selected_id := str(_scenario_selector.get_item_metadata(index))
	var selected: Dictionary = {}
	for preset in AUTHORING_SERVICE.scenario_presets(_active_character()):
		if str(preset.get("scenario_id", "")) == selected_id:
			selected = preset
			break
	_scenario_title.text = str(selected.get("name", ""))
	_scenario_text.text = str(selected.get("scenario", ""))
	_scenario_opening.text = str(selected.get("opening_message", ""))
	_scenario_active_ids.text = ", ".join(PackedStringArray(selected.get("active_character_ids", [])))
	_scenario_world_ids.text = ", ".join(PackedStringArray(selected.get("world_ids", [])))
	_scenario_tags.text = ", ".join(PackedStringArray(selected.get("tags", [])))
	_scenario_favourite.button_pressed = bool(selected.get("favourite", false))
	_scenario_preview.text = ""


func _new_scenario() -> void:
	_scenario_selector.select(0)
	_load_selected_scenario(0)


func _save_scenario() -> void:
	var character_record := _active_character()
	if character_record.is_empty():
		return
	var selected_id := str(_scenario_selector.get_selected_metadata())
	var record := AUTHORING_SERVICE.upsert_scenario(character_record, {
		"scenario_id": selected_id,
		"name": _scenario_title.text,
		"scenario": _scenario_text.text,
		"opening_message": _scenario_opening.text,
		"active_character_ids": _csv(_scenario_active_ids.text),
		"world_ids": _csv(_scenario_world_ids.text),
		"tags": _csv(_scenario_tags.text),
		"favourite": _scenario_favourite.button_pressed
	})
	_store_active_character(character_record, "Scenario preset saved. The main card remains unchanged.")
	_refresh_scenarios(str(record.get("scenario_id", "")))
	_refresh_reports()


func _delete_scenario() -> void:
	var selected_id := str(_scenario_selector.get_selected_metadata())
	if selected_id.is_empty():
		return
	var character_record := _active_character()
	if AUTHORING_SERVICE.remove_scenario(character_record, selected_id):
		_store_active_character(character_record, "Scenario preset deleted. The main card remains unchanged.")
		_refresh_scenarios()
		_refresh_reports()


func _preview_scenario() -> void:
	var selected_id := str(_scenario_selector.get_selected_metadata())
	var result := AUTHORING_SERVICE.materialise_scenario(
		_project, _active_character_id, selected_id
	)
	_scenario_preview.text = JSON.stringify(result, "  ")
	_status.text = "Scenario materialisation preview generated. No source data changed."


func _refresh_greetings(preferred_id: String = "") -> void:
	_greeting_selector.clear()
	_greeting_selector.add_item("New / unsaved greeting")
	_greeting_selector.set_item_metadata(0, "")
	var selected_index := 0
	var item_index := 1
	for record in AUTHORING_SERVICE.greeting_records(_active_character()):
		var label_text := str(record.get("category", "General")) + " — " + str(record.get("text", "")).replace("\n", " ").left(70)
		_greeting_selector.add_item(label_text)
		_greeting_selector.set_item_metadata(item_index, str(record.get("greeting_id", "")))
		if str(record.get("greeting_id", "")) == preferred_id:
			selected_index = item_index
		item_index += 1
	_greeting_selector.select(selected_index)
	_load_selected_greeting(selected_index)


func _load_selected_greeting(index: int) -> void:
	var selected_id := str(_greeting_selector.get_item_metadata(index))
	var selected: Dictionary = {}
	for record in AUTHORING_SERVICE.greeting_records(_active_character()):
		if str(record.get("greeting_id", "")) == selected_id:
			selected = record
			break
	_greeting_text.text = str(selected.get("text", ""))
	_greeting_category.text = str(selected.get("category", "General"))
	_greeting_tags.text = ", ".join(PackedStringArray(selected.get("tags", [])))
	_greeting_weight.value = int(selected.get("weight", 1))
	_greeting_favourite.button_pressed = bool(selected.get("favourite", false))
	_greeting_front_porch_seed.text = str(selected.get("front_porch_seed", ""))
	_greeting_preview.text = ""


func _new_greeting() -> void:
	_greeting_selector.select(0)
	_load_selected_greeting(0)


func _save_greeting() -> void:
	if _greeting_text.text.strip_edges().is_empty():
		_status.text = "Enter a playable greeting before saving it."
		return
	var character_record := _active_character()
	var selected_id := str(_greeting_selector.get_selected_metadata())
	var records := AUTHORING_SERVICE.greeting_records(character_record)
	var replacement := {
		"greeting_id": selected_id,
		"text": _greeting_text.text,
		"category": _greeting_category.text,
		"tags": _csv(_greeting_tags.text),
		"weight": int(_greeting_weight.value),
		"favourite": _greeting_favourite.button_pressed,
		"front_porch_seed": _greeting_front_porch_seed.text
	}
	var replaced := false
	for index in range(records.size()):
		if str(records[index].get("greeting_id", "")) == selected_id and not selected_id.is_empty():
			replacement["created_at"] = records[index].get("created_at", "")
			records[index] = replacement
			replaced = true
			break
	if not replaced:
		records.append(replacement)
	var saved := AUTHORING_SERVICE.set_greeting_records(character_record, records)
	var saved_id := str(saved[-1].get("greeting_id", "")) if not replaced else selected_id
	_store_active_character(character_record, "Greeting metadata and compatible Alternative Greetings updated.")
	_refresh_greetings(saved_id)


func _delete_greeting() -> void:
	var selected_id := str(_greeting_selector.get_selected_metadata())
	if selected_id.is_empty():
		return
	var character_record := _active_character()
	var kept: Array[Dictionary] = []
	for record in AUTHORING_SERVICE.greeting_records(character_record):
		if str(record.get("greeting_id", "")) != selected_id:
			kept.append(record)
	AUTHORING_SERVICE.set_greeting_records(character_record, kept)
	_store_active_character(character_record, "Greeting removed from the manager and compatible export list.")
	_refresh_greetings()


func _preview_greeting_choice() -> void:
	var choice := AUTHORING_SERVICE.choose_greeting(
		_active_character(), _greeting_category.text, str(Time.get_ticks_usec())
	)
	_greeting_preview.text = JSON.stringify(choice, "  ")
	_status.text = "Weighted greeting preview selected locally. Nothing was saved or sent."


func _refresh_ensemble() -> void:
	var lines := PackedStringArray(["[b]Project roster[/b]"])
	for summary in CCFStorageService.project_character_summaries(_project):
		lines.append("• %s — %s" % [str(summary.get("name", "")), str(summary.get("character_id", ""))])
	lines.append("\n[b]Saved Card Workflows[/b]: %d" % (_project.get("card_workflows", []) as Array).size())
	_ensemble_summary.text = "\n".join(lines)


func _refresh_library_characters() -> void:
	_library_character_selector.clear()
	_library_character_selector.add_item("Choose a character from another project…")
	_library_character_selector.set_item_metadata(0, {})
	for row in CCFStorageService.list_projects():
		var source_project_id := str(row.get("project_id", ""))
		if source_project_id == _project_id:
			continue
		for character_summary in row.get("characters", []):
			_library_character_selector.add_item("%s / %s" % [
				str(row.get("name", "Untitled Project")), str(character_summary.get("name", "Untitled Character"))
			])
			_library_character_selector.set_item_metadata(
				_library_character_selector.item_count - 1,
				{"project_id": source_project_id, "character_id": str(character_summary.get("character_id", ""))}
			)


func _create_group_project() -> void:
	var project_name := _new_member_name.text.strip_edges()
	if project_name.is_empty():
		project_name = "Untitled Ensemble"
	project_created_v0190.emit(AUTHORING_SERVICE.new_multi_character_project(project_name))
	_status.text = "New multi-character project created with two editable starter members."


func _add_new_member() -> void:
	var result := AUTHORING_SERVICE.add_new_member(_project, _new_member_name.text)
	_project = result.get("project", {}).duplicate(true)
	_new_member_name.text = ""
	_refresh_ensemble()
	_status.text = "New independent member added. Add it to the desired Card Workflow roster."
	project_changed_v0190.emit(_project.duplicate(true), _active_character_id, _status.text)


func _add_library_character() -> void:
	var selection: Variant = _library_character_selector.get_selected_metadata()
	if not selection is Dictionary or selection.is_empty():
		_status.text = "Choose an existing library character first."
		return
	var loaded := CCFStorageService.load_project(str(selection.get("project_id", "")))
	if not bool(loaded.get("ok", false)):
		_status.text = str(loaded.get("error", "Could not load the source project."))
		return
	var result := AUTHORING_SERVICE.add_existing_library_character(
		_project, loaded.get("data", {}), str(selection.get("character_id", ""))
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not add the library character."))
		return
	_project = result.get("project", {}).duplicate(true)
	_refresh_ensemble()
	_refresh_reports()
	_status.text = "Existing library character copied independently. %s" % str(result.get("warning", ""))
	project_changed_v0190.emit(_project.duplicate(true), _active_character_id, _status.text)


func _create_and_generate_split() -> void:
	var seeds: Array[Dictionary] = []
	for raw_line in _member_seed_lines.text.split("\n"):
		var clean_line := raw_line.strip_edges()
		if clean_line.is_empty():
			continue
		var pieces := clean_line.split("|", true, 1)
		seeds.append({
			"name": str(pieces[0]).strip_edges(),
			"role": str(pieces[1]).strip_edges() if pieces.size() > 1 else ""
		})
	var result := AUTHORING_SERVICE.create_split_batch(
		_project, _shared_concept.text, seeds
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not create the split set."))
		return
	_project = result.get("project", {}).duplicate(true)
	var batch: Dictionary = result.get("batch", {})
	var batch_id := str(batch.get("batch_id", ""))
	_refresh_ensemble()
	_refresh_batches(batch_id)
	project_changed_v0190.emit(
		_project.duplicate(true), _active_character_id,
		"Split set seeded as independent characters; parent generation queued."
	)
	split_generation_requested_v0190.emit(batch_id, [])
	_status.text = "Split set parent job queued. Each member will remain independently reviewable and retryable."


func _refresh_batches(preferred_id: String = "") -> void:
	_batch_selector.clear()
	_batch_selector.add_item("No split batch selected")
	_batch_selector.set_item_metadata(0, "")
	var selected_index := 0
	var item_index := 1
	var data := AUTHORING_SERVICE.ensure_project_data(_project)
	for raw_batch in data.get("split_batches", []):
		if not raw_batch is Dictionary:
			continue
		var batch_id := str(raw_batch.get("batch_id", ""))
		_batch_selector.add_item("%s — %s" % [batch_id.left(18), str(raw_batch.get("status", "pending"))])
		_batch_selector.set_item_metadata(item_index, batch_id)
		if batch_id == preferred_id:
			selected_index = item_index
		item_index += 1
	_batch_selector.select(selected_index)
	_show_selected_batch(selected_index)


func _show_selected_batch(index: int) -> void:
	var batch_id := str(_batch_selector.get_item_metadata(index))
	_batch_report.text = JSON.stringify(AUTHORING_SERVICE.split_batch(_project, batch_id), "  ")


func _retry_failed_split() -> void:
	var batch_id := str(_batch_selector.get_selected_metadata())
	var batch := AUTHORING_SERVICE.split_batch(_project, batch_id)
	var retry_ids: Array[String] = []
	for raw_member in batch.get("members", []):
		if raw_member is Dictionary and str(raw_member.get("status", "")) != "completed":
			retry_ids.append(str(raw_member.get("character_id", "")))
	if retry_ids.is_empty():
		_status.text = "This split batch has no failed or pending members."
		return
	split_generation_requested_v0190.emit(batch_id, retry_ids)
	_status.text = "Retry queued only for the failed or pending split members."


func _refresh_world_links() -> void:
	_world_checks.clear()
	var panel := find_child("WorldLinkListV0190", true, false) as VBoxContainer
	if panel == null:
		return
	_clear_children(panel)
	var linked: Array = AUTHORING_SERVICE.ensure_project_data(_project).get("shared_world_links", [])
	var worlds_value: Variant = _project.get("front_porch_worlds", [])
	if worlds_value is Array:
		for raw_world in worlds_value:
			if not raw_world is Dictionary:
				continue
			var world_id := str(raw_world.get("world_id", ""))
			var package_value: Variant = raw_world.get("package", {})
			var world_label := str((package_value as Dictionary).get("name", world_id)) if package_value is Dictionary else world_id
			var check := CheckBox.new()
			check.text = world_label
			check.button_pressed = world_id in linked
			panel.add_child(check)
			_world_checks[world_id] = check
	if _world_checks.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No .fpworld records are stored in this project yet. Use Front Porch World Studio to create or import one."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(empty_label)


func _save_world_links() -> void:
	var linked: Array[String] = []
	for world_id in _world_checks:
		var check: CheckBox = _world_checks[world_id]
		if check.button_pressed:
			linked.append(str(world_id))
	var data := AUTHORING_SERVICE.ensure_project_data(_project)
	data["shared_world_links"] = linked
	data["updated_at"] = Time.get_datetime_string_from_system(true)
	_project[AUTHORING_SERVICE.PROJECT_KEY] = data
	_status.text = "Shared world links saved without duplicating world or lorebook data."
	project_changed_v0190.emit(_project.duplicate(true), _active_character_id, _status.text)
	_refresh_reports()


func _refresh_reports() -> void:
	_dependency_report.text = JSON.stringify({
		"dependencies": AUTHORING_SERVICE.dependency_report(_project),
		"reference_graph": AUTHORING_SERVICE.reference_graph(_project)
	}, "  ")
	_lineage_report.text = JSON.stringify(AUTHORING_SERVICE.lineage_rows(_project), "  ")


func _refresh_private_metadata() -> void:
	var character_record := _active_character()
	var data := AUTHORING_SERVICE.character_data(character_record)
	_custom_metadata.text = JSON.stringify(data.get("custom_metadata", {}), "  ")
	_export_mappings.text = JSON.stringify(data.get("export_mappings", []), "  ")
	_mapping_preview.text = ""


func _save_private_metadata() -> void:
	var metadata_value: Variant = JSON.parse_string(_custom_metadata.text)
	var mappings_value: Variant = JSON.parse_string(_export_mappings.text)
	if not metadata_value is Dictionary or not mappings_value is Array:
		_status.text = "Private metadata must be a JSON object and export mappings must be a JSON array."
		return
	var clean_mappings: Array[Dictionary] = []
	for raw_mapping in mappings_value:
		if raw_mapping is Dictionary:
			clean_mappings.append(raw_mapping)
	var character_record := _active_character()
	AUTHORING_SERVICE.set_private_custom_metadata(
		character_record, metadata_value, clean_mappings
	)
	_store_active_character(character_record, "Private metadata saved. Unmapped fields remain CCF-private.")
	_preview_mappings()


func _preview_mappings() -> void:
	_mapping_preview.text = JSON.stringify(
		AUTHORING_SERVICE.mapped_export_preview(_active_character()), "  "
	)
	_status.text = "Export mapping preview updated. No export was written."


func _csv(value: String) -> Array[String]:
	var result: Array[String] = []
	for raw_value in value.replace("\n", ",").split(","):
		var clean := raw_value.strip_edges()
		if not clean.is_empty() and clean not in result:
			result.append(clean)
	return result


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _hide_window() -> void:
	CCFToolWindowStateService.save_window(self, "rich_authoring_v0190")
	hide()
