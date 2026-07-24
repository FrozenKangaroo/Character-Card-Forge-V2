class_name CCFWorkspaceView
extends VBoxContainer
signal project_saved(project: Dictionary)
signal library_requested
signal settings_requested
signal template_manager_requested
signal series_manager_requested
signal project_imported(project: Dictionary)
var _project: Dictionary = {}
var _project_container: Dictionary = {}
var _active_character_id := ""
var _template: Dictionary = {}
var _settings: Dictionary = {}
var _field_controls: Dictionary = {}
var _dirty := false
var _title: Label
var _status: Label
var _queue_status: Label
var _save_button: Button
var _generate_button: Button
var _cancel_button: Button
var _tabs: TabContainer
var _generation_service: CCFGenerationService
var _concept_token_label: Label
var _template_selector: OptionButton
var _loading_template_selector := false
var _project_name_edit: LineEdit
var _series_selector: OptionButton
var _loading_series_selector := false
var _character_selector: OptionButton
var _character_role_edit: LineEdit
var _loading_character_selector := false
var _loading_project_controls := false
var _delete_character_confirm: ConfirmationDialog
var _preview_window: Window
var _preview_rows: Array[Dictionary] = []
var _preview_metadata: Dictionary = {}
var _preview_job_type := ""
var _preview_result_box: VBoxContainer
var _preview_summary: Label
var _preview_project_id := ""
var _preview_window_has_been_shown := false
var _idea_window: Window
var _idea_seed: TextEdit
var _idea_count: SpinBox
var _idea_generate_button: Button
var _idea_status: Label
var _idea_result_box: VBoxContainer
var _idea_job_id := ""
var _idea_window_has_been_shown := false
var _builder_window: CCFCharacterBuilderWindow
var _builder_window_has_been_shown := false
var _controlled_build_window: CCFControlledBuildWindow
var _controlled_build_window_has_been_shown := false
var _project_context_window: CCFProjectContextWindow
var _group_scene_window: CCFGroupSceneWindow
var _relationship_window: CCFRelationshipMatrixWindow
var _card_workflow_window: CCFCardWorkflowWindow
var _import_export_window: CCFImportExportWindow


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_generation_service = CCFGenerationService.new()
	add_child(_generation_service)
	_generation_service.job_started.connect(_on_job_started)
	_generation_service.job_completed.connect(_on_job_completed)
	_generation_service.job_failed.connect(_on_job_failed)
	_generation_service.job_cancelled.connect(_on_job_cancelled)
	_generation_service.queue_changed.connect(_on_queue_changed)
	var top := HFlowContainer.new()
	top.add_theme_constant_override("separation", 8)
	add_child(top)
	_title = Label.new()
	_title.text = "Character Workspace"
	_title.add_theme_font_size_override("font_size", 22)
	_title.custom_minimum_size.x = 220
	top.add_child(_title)
	_save_button = Button.new()
	_save_button.text = "Save"
	_save_button.pressed.connect(save_project)
	top.add_child(_save_button)
	_generate_button = Button.new()
	_generate_button.text = "Generate Character"
	_generate_button.pressed.connect(_generate_character)
	top.add_child(_generate_button)
	var ideas_button := Button.new()
	ideas_button.text = "Idea Generator"
	ideas_button.pressed.connect(_open_idea_generator)
	top.add_child(ideas_button)
	var builder_button := Button.new()
	builder_button.text = "Character Builder"
	builder_button.pressed.connect(_open_character_builder)
	top.add_child(builder_button)
	var controlled_build_button := Button.new()
	controlled_build_button.text = "Controlled Build"
	controlled_build_button.tooltip_text = "Build or revise only selected template sections and fields."
	controlled_build_button.pressed.connect(_open_controlled_build)
	top.add_child(controlled_build_button)
	var import_export_button := Button.new()
	import_export_button.text = "Import / Export"
	import_export_button.pressed.connect(_open_import_export_studio)
	top.add_child(import_export_button)
	var templates_button := Button.new()
	templates_button.text = "Manage Templates"
	templates_button.pressed.connect(func(): template_manager_requested.emit())
	top.add_child(templates_button)
	var settings_button := Button.new()
	settings_button.text = "API Settings"
	settings_button.pressed.connect(func(): settings_requested.emit())
	top.add_child(settings_button)
	var library_button := Button.new()
	library_button.text = "Library"
	library_button.pressed.connect(func(): library_requested.emit())
	top.add_child(library_button)

	var project_row := HFlowContainer.new()
	project_row.add_theme_constant_override("separation", 8)
	add_child(project_row)
	var project_label := Label.new()
	project_label.text = "Project"
	project_row.add_child(project_label)
	_project_name_edit = LineEdit.new()
	_project_name_edit.placeholder_text = "Project name"
	_project_name_edit.custom_minimum_size.x = 360
	_project_name_edit.text_changed.connect(_on_project_name_changed)
	project_row.add_child(_project_name_edit)
	var series_label := Label.new()
	series_label.text = "Series"
	project_row.add_child(series_label)
	_series_selector = OptionButton.new()
	_series_selector.custom_minimum_size.x = 240
	_series_selector.item_selected.connect(_on_series_selected)
	project_row.add_child(_series_selector)
	var auto_series_button := Button.new()
	auto_series_button.text = "Auto Series"
	auto_series_button.tooltip_text = "Match this project against local series aliases, tags, categories, and keywords."
	auto_series_button.pressed.connect(_auto_assign_series)
	project_row.add_child(auto_series_button)
	var series_tags_button := Button.new()
	series_tags_button.text = "Apply Series Tags"
	series_tags_button.pressed.connect(_apply_series_tags)
	project_row.add_child(series_tags_button)
	var manage_series_button := Button.new()
	manage_series_button.text = "Manage Series"
	manage_series_button.pressed.connect(func(): series_manager_requested.emit())
	project_row.add_child(manage_series_button)
	var context_button := Button.new()
	context_button.text = "Shared Context"
	context_button.pressed.connect(_open_project_context)
	project_row.add_child(context_button)
	var group_scene_button := Button.new()
	group_scene_button.text = "Group Scene Generator"
	group_scene_button.pressed.connect(_open_group_scene_generator)
	project_row.add_child(group_scene_button)
	var relationships_button := Button.new()
	relationships_button.text = "Relationships"
	relationships_button.pressed.connect(_open_relationship_matrix)
	project_row.add_child(relationships_button)
	var card_workflows_button := Button.new()
	card_workflows_button.text = "Card Workflows"
	card_workflows_button.pressed.connect(_open_card_workflow_studio)
	project_row.add_child(card_workflows_button)

	var character_row := HFlowContainer.new()
	character_row.add_theme_constant_override("separation", 8)
	add_child(character_row)
	var character_label := Label.new()
	character_label.text = "Active character"
	character_row.add_child(character_label)
	_character_selector = OptionButton.new()
	_character_selector.custom_minimum_size.x = 360
	_character_selector.item_selected.connect(_on_character_selected)
	character_row.add_child(_character_selector)
	var role_label := Label.new()
	role_label.text = "Group role"
	character_row.add_child(role_label)
	_character_role_edit = LineEdit.new()
	_character_role_edit.placeholder_text = "Optional role"
	_character_role_edit.custom_minimum_size.x = 180
	_character_role_edit.text_changed.connect(_on_character_role_changed)
	character_row.add_child(_character_role_edit)
	var add_character_button := Button.new()
	add_character_button.text = "+ Character"
	add_character_button.pressed.connect(_add_character)
	character_row.add_child(add_character_button)
	var duplicate_character_button := Button.new()
	duplicate_character_button.text = "Duplicate Character"
	duplicate_character_button.pressed.connect(_duplicate_active_character)
	character_row.add_child(duplicate_character_button)
	var remove_character_button := Button.new()
	remove_character_button.text = "Remove Character"
	remove_character_button.pressed.connect(_request_remove_active_character)
	character_row.add_child(remove_character_button)

	var template_row := HFlowContainer.new()
	template_row.add_theme_constant_override("separation", 8)
	add_child(template_row)
	var template_label := Label.new()
	template_label.text = "Workspace template"
	template_row.add_child(template_label)
	_template_selector = OptionButton.new()
	_template_selector.custom_minimum_size.x = 320
	_template_selector.item_selected.connect(_on_template_selected)
	template_row.add_child(_template_selector)
	var template_hint := Label.new()
	template_hint.text = "Changing templates keeps existing project data and changes which fields are shown."
	template_hint.modulate = Color(0.62, 0.65, 0.74)
	template_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	template_hint.custom_minimum_size.x = 420
	template_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	template_row.add_child(template_hint)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 10)
	add_child(status_row)
	_status = Label.new()
	_status.text = "No character loaded."
	_status.modulate = Color(0.73, 0.75, 0.83)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_row.add_child(_status)
	_queue_status = Label.new()
	_queue_status.text = "AI queue: idle"
	_queue_status.modulate = Color(0.64, 0.68, 0.82)
	status_row.add_child(_queue_status)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel Active"
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_cancel_active_job)
	status_row.add_child(_cancel_button)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)
	_build_preview_window()
	_build_idea_window()
	_build_character_builder_window()
	_build_controlled_build_window()
	_build_project_context_window()
	_build_group_scene_window()
	_build_relationship_window()
	_build_card_workflow_window()
	_build_import_export_window()
	_build_delete_character_confirmation()


func load_project(project: Dictionary, template: Dictionary, settings: Dictionary) -> void:
	var incoming_project_id := str(project.get("project_id", ""))
	var current_container_id := str(_project_container.get("project_id", ""))
	if not current_container_id.is_empty() and incoming_project_id != current_container_id:
		_close_tool_windows_for_project_change()
		_release_project_level_windows()
	_project_container = project.duplicate(true)
	_active_character_id = CCFStorageService.active_character_id(_project_container)
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	_template = template.duplicate(true)
	_settings = settings.duplicate(true)
	_dirty = false
	var generation: Dictionary = _project.get("generation", {}).duplicate(true)
	generation["template_id"] = str(_template.get("template_id", "default"))
	_project["generation"] = generation
	_populate_project_controls()
	_populate_series_selector()
	_populate_template_selector()
	_rebuild_form()
	_update_header()
	_update_project_level_window_contexts()
	_status.text = "Loaded. Changes remain local until you press Save."


func update_settings(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	if _idea_count != null:
		_idea_count.value = int(_generation_settings().get("default_idea_count", 6))
	if (
		_builder_window != null
		and _builder_window.owns_project(str(_project.get("project_id", "")))
	):
		_builder_window.update_project_context(_project, _settings)
	if (
		_controlled_build_window != null
		and _controlled_build_window.owns_project(str(_project.get("project_id", "")))
	):
		_capture_all_fields()
		_controlled_build_window.update_project_context(_project, _template, _settings)
	if (
		_group_scene_window != null
		and _group_scene_window.owns_project(str(_project_container.get("project_id", "")))
	):
		_commit_active_character_to_container()
		_group_scene_window.update_project_context(_project_container, _settings)
	if (
		_relationship_window != null
		and _relationship_window.owns_project(str(_project_container.get("project_id", "")))
	):
		_commit_active_character_to_container()
		_relationship_window.update_project_context(_project_container, _settings)
	if (
		_card_workflow_window != null
		and _card_workflow_window.owns_project(str(_project_container.get("project_id", "")))
	):
		_commit_active_character_to_container()
		_card_workflow_window.update_project_context(_project_container, _settings)
	if (
		_import_export_window != null
		and _import_export_window.owns_project(str(_project_container.get("project_id", "")))
	):
		_commit_active_character_to_container()
		_import_export_window.update_project_context(
			_project_container, _settings, _active_character_id
		)


func refresh_series() -> void:
	if _series_selector == null:
		return
	if not _project_container.is_empty():
		_commit_active_character_to_container()
	_populate_series_selector()
	if not _project_container.is_empty():
		_project = CCFStorageService.character_workspace_document(
			_project_container, _active_character_id
		)
		_update_project_level_window_contexts()


func refresh_templates() -> void:
	if _project.is_empty():
		_populate_template_selector()
		return
	_capture_all_fields()
	var generation: Dictionary = _project.get("generation", {}).duplicate(true)
	var requested_id := str(generation.get("template_id", "default"))
	var available := false
	for summary in CCFTemplateService.list_templates():
		if summary is Dictionary and str(summary.get("template_id", "")) == requested_id:
			available = true
			break
	if not available:
		requested_id = "default"
		generation["template_id"] = requested_id
		_project["generation"] = generation
		_dirty = true
	_template = CCFTemplateService.load_template(requested_id)
	_populate_template_selector()
	_rebuild_form()
	_update_header()
	if (
		_controlled_build_window != null
		and _controlled_build_window.owns_project(str(_project.get("project_id", "")))
	):
		_controlled_build_window.update_project_context(_project, _template, _settings)


func _populate_template_selector() -> void:
	if _template_selector == null:
		return
	_loading_template_selector = true
	_template_selector.clear()
	var active_id := str(_template.get("template_id", "default"))
	var selected_index := 0
	var index := 0
	for summary in CCFTemplateService.list_templates():
		if not summary is Dictionary:
			continue
		var template_id := str(summary.get("template_id", ""))
		var label := str(summary.get("name", "Template"))
		if bool(summary.get("built_in", false)):
			label += " • Built-in"
		_template_selector.add_item(label)
		_template_selector.set_item_metadata(index, template_id)
		if template_id == active_id:
			selected_index = index
		index += 1
	if _template_selector.item_count > 0:
		_template_selector.select(clampi(selected_index, 0, _template_selector.item_count - 1))
	_loading_template_selector = false


func _on_template_selected(index: int) -> void:
	if _loading_template_selector or _project.is_empty():
		return
	var template_id := str(_template_selector.get_item_metadata(index))
	if template_id.is_empty() or template_id == str(_template.get("template_id", "")):
		return
	_capture_all_fields()
	_template = CCFTemplateService.load_template(template_id)
	var generation: Dictionary = _project.get("generation", {}).duplicate(true)
	generation["template_id"] = template_id
	_project["generation"] = generation
	_dirty = true
	_rebuild_form()
	_update_header()
	if (
		_controlled_build_window != null
		and _controlled_build_window.owns_project(str(_project.get("project_id", "")))
	):
		_controlled_build_window.update_project_context(_project, _template, _settings)
	_status.text = (
		"Template changed to %s. Existing project data has been kept."
		% str(_template.get("name", "Template"))
	)


func save_project() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	var result := CCFStorageService.save_project(_project_container)
	if result.get("ok", false):
		_dirty = false
		_populate_project_controls()
		_status.text = "Saved at %s" % Time.get_time_string_from_system()
		_update_header()
		project_saved.emit(_project_container.duplicate(true))
	else:
		_status.text = str(result.get("error", "Could not save project."))


func has_unsaved_changes() -> bool:
	return _dirty


func current_project() -> Dictionary:
	_commit_active_character_to_container()
	_capture_project_name()
	return _project_container.duplicate(true)


func _populate_series_selector() -> void:
	if _series_selector == null:
		return
	_loading_series_selector = true
	_series_selector.clear()
	_series_selector.add_item("Unassigned")
	_series_selector.set_item_metadata(0, "")
	var metadata_value: Variant = _project_container.get("metadata", {})
	var active_series_id := ""
	if metadata_value is Dictionary:
		active_series_id = str(metadata_value.get("series_id", "")).strip_edges()
	var selected_index := 0
	var found_active := active_series_id.is_empty()
	for series in CCFSeriesService.list_series():
		var series_id := str(series.get("series_id", ""))
		var label := str(series.get("name", "Untitled Series"))
		var categories: Array[String] = []
		var raw_categories: Variant = series.get("categories", [])
		if raw_categories is Array:
			for raw_category in raw_categories:
				var category := str(raw_category).strip_edges()
				if not category.is_empty():
					categories.append(category)
		if not categories.is_empty():
			label += " — %s" % _join_values(categories, ", ")
		var item_index := _series_selector.item_count
		_series_selector.add_item(label)
		_series_selector.set_item_metadata(item_index, series_id)
		if series_id == active_series_id:
			selected_index = item_index
			found_active = true
	if not found_active and not active_series_id.is_empty():
		selected_index = _series_selector.item_count
		_series_selector.add_item("Missing series — %s" % active_series_id.left(18))
		_series_selector.set_item_metadata(selected_index, active_series_id)
	_series_selector.select(selected_index)
	_loading_series_selector = false


func _on_series_selected(index: int) -> void:
	if _loading_series_selector or _project_container.is_empty():
		return
	if index < 0 or index >= _series_selector.item_count:
		return
	var series_id := str(_series_selector.get_item_metadata(index))
	_commit_active_character_to_container()
	var result := CCFSeriesService.assign_project(_project_container, series_id)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not assign the series."))
		_populate_series_selector()
		return
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	_dirty = true
	_update_project_level_window_contexts()
	_status.text = (
		"Project series cleared. Save the project when ready."
		if series_id.is_empty()
		else "Project assigned to %s. Series guidance is now active for AI tools." % _series_selector.get_item_text(index)
	)


func _auto_assign_series() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	var result := CCFSeriesService.match_project(_project_container)
	var candidates_value: Variant = result.get("candidates", [])
	var candidates: Array = []
	if candidates_value is Array:
		candidates = candidates_value
	if not bool(result.get("confident", false)):
		if candidates.is_empty():
			_status.text = "Auto Series found no local series keywords matching this project."
		else:
			var best_candidate: Dictionary = result.get("best", {})
			_status.text = "Auto Series is ambiguous. Best candidate: %s (score %d). Choose manually or add more matching keywords." % [
				str(best_candidate.get("name", "Series")), int(best_candidate.get("score", 0))
			]
		return
	var selected_candidate: Dictionary = result.get("best", {})
	var series_id := str(selected_candidate.get("series_id", ""))
	CCFSeriesService.assign_project(_project_container, series_id)
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	_dirty = true
	_populate_series_selector()
	_update_project_level_window_contexts()
	_status.text = "Auto Series assigned %s (score %d). Save the project when ready." % [
		str(selected_candidate.get("name", "Series")),
		int(selected_candidate.get("score", 0))
	]


func _apply_series_tags() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	var result := CCFSeriesService.apply_default_tags(_project_container)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not apply series tags."))
		return
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	_dirty = true
	_status.text = "%d new series tag%s added to the project. Save when ready." % [
		int(result.get("added", 0)), "" if int(result.get("added", 0)) == 1 else "s"
	]


func _populate_project_controls() -> void:
	_loading_project_controls = true
	_loading_character_selector = true
	var metadata = _project_container.get("metadata", {})
	_project_name_edit.text = (
		str(metadata.get("name", "Untitled Project")) if metadata is Dictionary else "Untitled Project"
	)
	_character_selector.clear()
	var selected_index := 0
	var index := 0
	for summary in CCFStorageService.project_character_summaries(_project_container):
		var character_id := str(summary.get("character_id", ""))
		var label := str(summary.get("name", "Untitled Character"))
		var role := str(summary.get("role", "")).strip_edges()
		if not role.is_empty():
			label += " — %s" % role
		_character_selector.add_item(label)
		_character_selector.set_item_metadata(index, character_id)
		if character_id == _active_character_id:
			selected_index = index
		index += 1
	if _character_selector.item_count > 0:
		_character_selector.select(clampi(selected_index, 0, _character_selector.item_count - 1))
	var active_character := CCFStorageService.get_character(_project_container, _active_character_id)
	var active_metadata = active_character.get("metadata", {})
	_character_role_edit.text = (
		str(active_metadata.get("role", "")) if active_metadata is Dictionary else ""
	)
	_loading_character_selector = false
	_loading_project_controls = false


func _capture_project_name() -> void:
	if _project_container.is_empty() or _project_name_edit == null:
		return
	var metadata: Dictionary = _project_container.get("metadata", {}).duplicate(true)
	var project_name := _project_name_edit.text.strip_edges()
	if project_name.is_empty():
		project_name = "Untitled Project"
	metadata["name"] = project_name
	_project_container["metadata"] = metadata


func _on_project_name_changed(_new_text: String) -> void:
	if _loading_project_controls or _project_container.is_empty():
		return
	_capture_project_name()
	_mark_dirty()


func _on_character_role_changed(new_role: String) -> void:
	if _loading_project_controls or _project.is_empty():
		return
	var metadata: Dictionary = _project.get("metadata", {}).duplicate(true)
	metadata["role"] = new_role
	_project["metadata"] = metadata
	var selected_index := _character_selector.selected
	if selected_index >= 0 and selected_index < _character_selector.item_count:
		var character_name := CCFStorageService.character_display_name(_project)
		var clean_role := new_role.strip_edges()
		_character_selector.set_item_text(
			selected_index,
			character_name if clean_role.is_empty() else "%s — %s" % [character_name, clean_role]
		)
	_mark_dirty()


func _on_character_selected(index: int) -> void:
	if _loading_character_selector or _project_container.is_empty():
		return
	if index < 0 or index >= _character_selector.item_count:
		return
	var character_id := str(_character_selector.get_item_metadata(index))
	if character_id.is_empty() or character_id == _active_character_id:
		return
	_switch_active_character(character_id)


func _switch_active_character(character_id: String) -> void:
	if CCFStorageService.character_index(_project_container, character_id) < 0:
		return
	_commit_active_character_to_container()
	_close_tool_windows_for_project_change()
	_active_character_id = character_id
	var workspace: Dictionary = _project_container.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = character_id
	_project_container["workspace"] = workspace
	_project = CCFStorageService.character_workspace_document(_project_container, character_id)
	var generation = _project.get("generation", {})
	var template_id := "default"
	if generation is Dictionary:
		template_id = str(generation.get("template_id", "default"))
	_template = CCFTemplateService.load_template(template_id)
	_populate_project_controls()
	_populate_template_selector()
	_rebuild_form()
	_update_header()
	_update_project_level_window_contexts()
	_status.text = "Switched active character. Unsaved project changes are still in memory."


func _commit_active_character_to_container() -> void:
	if _project_container.is_empty() or _project.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_capture_builder_state_if_loaded()
	CCFStorageService.update_character(_project_container, _project)
	var workspace: Dictionary = _project_container.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = _active_character_id
	_project_container["workspace"] = workspace


func _add_character() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	var character_number: int = int(_project_container.get("characters", []).size()) + 1
	var character_id := CCFStorageService.add_character(
		_project_container, "Untitled Character %d" % character_number
	)
	_dirty = true
	_switch_active_character(character_id)
	_status.text = "New character added to this project."


func _duplicate_active_character() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_commit_active_character_to_container()
	var result := CCFStorageService.duplicate_character(_project_container, _active_character_id)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not duplicate the active character."))
		return
	_dirty = true
	_switch_active_character(str(result.get("character_id", "")))
	_status.text = "Character duplicated inside this project."


func _request_remove_active_character() -> void:
	if _project_container.get("characters", []).size() <= 1:
		_status.text = "A project must contain at least one character."
		return
	_delete_character_confirm.dialog_text = (
		"Remove %s from this project? This removes the character's project data when you next save."
		% CCFStorageService.character_display_name(
			CCFStorageService.get_character(_project_container, _active_character_id)
		)
	)
	_delete_character_confirm.popup_centered()


func _remove_active_character() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_commit_active_character_to_container()
	var result := CCFStorageService.delete_character(_project_container, _active_character_id)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not remove the character."))
		return
	_dirty = true
	# The current character has already been removed from the container, so prevent the
	# normal switch path from trying to commit that stale workspace document again.
	_active_character_id = ""
	_switch_active_character(str(result.get("active_character_id", "")))
	_status.text = "Character removed from this project. Save to make the change permanent."


func _build_delete_character_confirmation() -> void:
	_delete_character_confirm = ConfirmationDialog.new()
	_delete_character_confirm.visible = false
	_delete_character_confirm.title = "Remove Character from Project"
	_delete_character_confirm.confirmed.connect(_remove_active_character)
	add_child(_delete_character_confirm)
	_delete_character_confirm.hide()


func _build_project_context_window() -> void:
	_project_context_window = CCFProjectContextWindow.new()
	_project_context_window.visible = false
	_project_context_window.context_applied.connect(_on_shared_context_applied)
	add_child(_project_context_window)
	_project_context_window.hide()


func _open_project_context() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	_project_context_window.open_for_project(_project_container)


func _on_shared_context_applied(context: Dictionary) -> void:
	if _project_container.is_empty():
		return
	_project_container["shared_context"] = context.duplicate(true)
	_project["shared_context"] = context.duplicate(true)
	_dirty = true
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	_update_project_level_window_contexts()
	_status.text = "Shared project context updated. Save the project when ready."


func _build_group_scene_window() -> void:
	_group_scene_window = CCFGroupSceneWindow.new()
	_group_scene_window.visible = false
	_group_scene_window.set_generation_service(_generation_service)
	_group_scene_window.project_refresh_requested.connect(_refresh_group_scene_project_context)
	_group_scene_window.result_apply_requested.connect(_on_group_scene_result_apply_requested)
	add_child(_group_scene_window)
	_group_scene_window.hide()


func _refresh_group_scene_project_context() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	_group_scene_window.update_project_context(_project_container, _settings)


func _open_group_scene_generator() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	if _project_container.get("characters", []).size() < 2:
		_status.text = "Add at least one more character before using Group Scene Generator."
		return
	_group_scene_window.open_for_project(_project_container, _settings)


func _on_group_scene_result_apply_requested(
	shared_context: Dictionary, character_scenarios: Dictionary, metadata: Dictionary
) -> void:
	_commit_active_character_to_container()
	if str(metadata.get("project_id", "")) != str(_project_container.get("project_id", "")):
		_status.text = "Group-scene result belongs to a different project and was not applied."
		return
	var current_context: Dictionary = _project_container.get("shared_context", {}).duplicate(true)
	for field_id in shared_context:
		current_context[field_id] = shared_context[field_id]
	_project_container["shared_context"] = current_context
	for character_id in character_scenarios:
		var workspace_document := CCFStorageService.character_workspace_document(
			_project_container, str(character_id)
		)
		if workspace_document.is_empty():
			continue
		CCFStorageService.set_value_at_path(
			workspace_document, "character.scenario", str(character_scenarios[character_id])
		)
		CCFStorageService.update_character(_project_container, workspace_document)
	# Reload the active character because its scenario may have been changed by the group proposal.
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	var generation = _project.get("generation", {})
	var template_id := str(generation.get("template_id", "default")) if generation is Dictionary else "default"
	_template = CCFTemplateService.load_template(template_id)
	_dirty = true
	_rebuild_form()
	_update_header()
	_populate_project_controls()
	_update_project_level_window_contexts()
	_status.text = "Selected group-scene content applied. Save the project when ready."


func _build_relationship_window() -> void:
	_relationship_window = CCFRelationshipMatrixWindow.new()
	_relationship_window.visible = false
	_relationship_window.set_generation_service(_generation_service)
	_relationship_window.project_refresh_requested.connect(_refresh_relationship_project_context)
	_relationship_window.relationships_applied.connect(_on_relationships_applied)
	add_child(_relationship_window)
	_relationship_window.hide()


func _refresh_relationship_project_context() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	_relationship_window.update_project_context(_project_container, _settings)


func _open_relationship_matrix() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	if _project_container.get("characters", []).size() < 2:
		_status.text = "Add at least one more character before creating relationships."
		return
	_relationship_window.open_for_project(_project_container, _settings)


func _on_relationships_applied(relationships: Array) -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_project_container["relationships"] = relationships.duplicate(true)
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	_dirty = true
	_update_project_level_window_contexts()
	_status.text = "Relationship matrix updated. Character generation can now use the new relationship context. Save the project when ready."


func _build_card_workflow_window() -> void:
	_card_workflow_window = CCFCardWorkflowWindow.new()
	_card_workflow_window.visible = false
	_card_workflow_window.set_generation_service(_generation_service)
	_card_workflow_window.project_refresh_requested.connect(_refresh_card_workflow_project_context)
	_card_workflow_window.workflow_saved.connect(_on_card_workflow_saved)
	_card_workflow_window.workflow_deleted.connect(_on_card_workflow_deleted)
	add_child(_card_workflow_window)
	_card_workflow_window.hide()


func _refresh_card_workflow_project_context() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	_card_workflow_window.update_project_context(_project_container, _settings)


func _open_card_workflow_studio() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	if _project_container.get("characters", []).size() < 2:
		_status.text = "Add at least one more character before creating a multi-character card workflow."
		return
	_card_workflow_window.open_for_project(_project_container, _settings)


func _on_card_workflow_saved(workflow: Dictionary) -> void:
	_commit_active_character_to_container()
	var workflows: Array = _project_container.get("card_workflows", []).duplicate(true)
	var workflow_id := str(workflow.get("workflow_id", ""))
	var replaced := false
	for index in range(workflows.size()):
		var existing = workflows[index]
		if existing is Dictionary and str(existing.get("workflow_id", "")) == workflow_id:
			workflows[index] = workflow.duplicate(true)
			replaced = true
			break
	if not replaced:
		workflows.append(workflow.duplicate(true))
	_project_container["card_workflows"] = workflows
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	_dirty = true
	_update_card_workflow_context()
	_status.text = "Card workflow draft saved into the project. Save the project file when ready."


func _on_card_workflow_deleted(workflow_id: String) -> void:
	_commit_active_character_to_container()
	var workflows: Array = []
	for raw_workflow in _project_container.get("card_workflows", []):
		if raw_workflow is Dictionary and str(raw_workflow.get("workflow_id", "")) == workflow_id:
			continue
		workflows.append(raw_workflow)
	_project_container["card_workflows"] = workflows
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	_dirty = true
	_update_card_workflow_context()
	_status.text = "Card workflow draft removed. Save the project file when ready."


func _build_import_export_window() -> void:
	_import_export_window = CCFImportExportWindow.new()
	_import_export_window.visible = false
	_import_export_window.project_refresh_requested.connect(_refresh_import_export_project_context)
	_import_export_window.project_imported.connect(_on_external_project_imported)
	add_child(_import_export_window)
	_import_export_window.hide()


func _refresh_import_export_project_context() -> void:
	if _project_container.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	_import_export_window.update_project_context(
		_project_container, _settings, _active_character_id
	)


func _open_import_export_studio() -> void:
	if _project_container.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	_import_export_window.open_for_project(
		_project_container, _settings, _active_character_id
	)


func _on_external_project_imported(imported_project: Dictionary) -> void:
	project_imported.emit(imported_project)


func _update_project_level_window_contexts() -> void:
	if (
		_project_context_window != null
		and _project_context_window.owns_project(str(_project_container.get("project_id", "")))
	):
		_project_context_window.update_project_context(_project_container)
	_update_group_scene_context()
	_update_relationship_context()
	_update_card_workflow_context()
	_update_import_export_context()


func _update_group_scene_context() -> void:
	if (
		_group_scene_window != null
		and _group_scene_window.owns_project(str(_project_container.get("project_id", "")))
	):
		_commit_active_character_to_container()
		_group_scene_window.update_project_context(_project_container, _settings)


func _update_relationship_context() -> void:
	if (
		_relationship_window != null
		and _relationship_window.owns_project(str(_project_container.get("project_id", "")))
	):
		_commit_active_character_to_container()
		_relationship_window.update_project_context(_project_container, _settings)


func _update_card_workflow_context() -> void:
	if (
		_card_workflow_window != null
		and _card_workflow_window.owns_project(str(_project_container.get("project_id", "")))
	):
		_commit_active_character_to_container()
		_card_workflow_window.update_project_context(_project_container, _settings)


func _update_import_export_context() -> void:
	if (
		_import_export_window != null
		and _import_export_window.owns_project(str(_project_container.get("project_id", "")))
	):
		_commit_active_character_to_container()
		_import_export_window.update_project_context(
			_project_container, _settings, _active_character_id
		)


func _release_project_level_windows() -> void:
	if _project_context_window != null:
		_project_context_window.release_project()
	if _group_scene_window != null:
		_group_scene_window.release_project()
	if _relationship_window != null:
		_relationship_window.release_project()
	if _card_workflow_window != null:
		_card_workflow_window.release_project()
	if _import_export_window != null:
		_import_export_window.release_project()


func _rebuild_form() -> void:
	if _tabs == null:
		return

	var previous_tab := _tabs.current_tab
	for child in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	_field_controls.clear()
	_concept_token_label = null

	var section_index := 0
	for section in _template.get("sections", []):
		if not section is Dictionary:
			continue
		var section_title := str(section.get("title", "Section"))
		var scroll := ScrollContainer.new()
		scroll.name = "section_%d" % section_index
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_tabs.add_child(scroll)
		_tabs.set_tab_title(_tabs.get_tab_count() - 1, section_title)
		section_index += 1

		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 18)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_bottom", 24)
		scroll.add_child(margin)

		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 12)
		margin.add_child(content)

		var description := str(section.get("description", "")).strip_edges()
		if not description.is_empty():
			var description_label := Label.new()
			description_label.text = description
			description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			description_label.modulate = Color(0.72, 0.74, 0.82)
			content.add_child(description_label)

		if str(section.get("kind", "standard")) == "interview":
			var interview_label := Label.new()
			interview_label.text = "Interview / Q&A section — field instructions can act as direct questions for AI generation."
			interview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			interview_label.modulate = Color(0.63, 0.67, 0.82)
			content.add_child(interview_label)

		for field in section.get("fields", []):
			if field is Dictionary:
				_add_field(content, field)

	if _tabs.get_tab_count() > 0:
		_tabs.current_tab = clampi(previous_tab, 0, _tabs.get_tab_count() - 1)
	_update_concept_estimate()


func _add_field(parent: VBoxContainer, field: Dictionary) -> void:
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 8)
	parent.add_child(heading_row)

	var field_label := Label.new()
	field_label.text = (
		"%s%s"
		% [
			str(field.get("label", field.get("id", "Field"))),
			" *" if bool(field.get("required", false)) else ""
		]
	)
	field_label.add_theme_font_size_override("font_size", 16)
	field_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if bool(field.get("required", false)):
		field_label.tooltip_text = "Required field"
	heading_row.add_child(field_label)

	if bool(field.get("generate", false)):
		var suggest_button := Button.new()
		suggest_button.text = "AI Suggest"
		suggest_button.tooltip_text = "Queue an AI suggestion for only this field"
		suggest_button.pressed.connect(_suggest_field.bind(field.duplicate(true)))
		heading_row.add_child(suggest_button)

	var generation_prompt := str(field.get("generation_prompt", "")).strip_edges()
	if not generation_prompt.is_empty():
		var prompt_hint := Label.new()
		prompt_hint.text = generation_prompt
		prompt_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		prompt_hint.modulate = Color(0.62, 0.65, 0.74)
		parent.add_child(prompt_hint)

	var field_type := str(field.get("type", "multiline"))
	var path := str(field.get("path", ""))
	var value = CCFStorageService.get_value_at_path(
		_project, path, _default_value_for_type(field_type)
	)
	var control: Control

	match field_type:
		"line", "tags":
			var line_edit := LineEdit.new()
			line_edit.placeholder_text = str(field.get("placeholder", ""))
			if field_type == "tags" and value is Array:
				line_edit.text = _join_values(value, ", ")
			else:
				line_edit.text = str(value)
			line_edit.text_changed.connect(
				func(_new_text: String):
					_mark_dirty()
					if path == "concept.prompt":
						_update_concept_estimate()
			)
			control = line_edit
		"number":
			var spin_box := SpinBox.new()
			spin_box.min_value = float(field.get("minimum", -1000000.0))
			spin_box.max_value = float(field.get("maximum", 1000000.0))
			spin_box.step = maxf(0.001, float(field.get("step", 1.0)))
			spin_box.value = float(value)
			spin_box.value_changed.connect(func(_new_value: float): _mark_dirty())
			control = spin_box
		"checkbox":
			var check_box := CheckBox.new()
			check_box.text = str(field.get("placeholder", "Enabled"))
			check_box.button_pressed = bool(value)
			check_box.toggled.connect(func(_pressed: bool): _mark_dirty())
			control = check_box
		"select":
			var option_button := OptionButton.new()
			var options = field.get("options", [])
			var selected_index := 0
			if options is Array:
				for option_index in range(options.size()):
					var option_text := str(options[option_index])
					option_button.add_item(option_text)
					option_button.set_item_metadata(option_index, option_text)
					if option_text == str(value):
						selected_index = option_index
			if option_button.item_count > 0:
				option_button.select(selected_index)
			option_button.item_selected.connect(func(_selected: int): _mark_dirty())
			control = option_button
		_:
			var text_edit := TextEdit.new()
			text_edit.placeholder_text = str(field.get("placeholder", ""))
			text_edit.text = str(value)
			text_edit.custom_minimum_size.y = float(field.get("height", 150))
			text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			text_edit.text_changed.connect(
				func():
					_mark_dirty()
					if path == "concept.prompt":
						_update_concept_estimate()
			)
			control = text_edit

	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	_field_controls[path] = {"control": control, "type": field_type, "field": field.duplicate(true)}

	if path == "concept.prompt":
		_concept_token_label = Label.new()
		_concept_token_label.modulate = Color(0.6, 0.64, 0.75)
		parent.add_child(_concept_token_label)


func _capture_all_fields() -> void:
	if _project.is_empty():
		return
	for path in _field_controls:
		var row: Dictionary = _field_controls[path]
		var control: Control = row.get("control")
		var field_type := str(row.get("type", "multiline"))
		var value: Variant = _default_value_for_type(field_type)
		if control is LineEdit:
			value = control.text
		elif control is TextEdit:
			value = control.text
		elif control is SpinBox:
			value = control.value
		elif control is CheckBox:
			value = control.button_pressed
		elif control is OptionButton:
			value = str(control.get_selected_metadata()) if control.selected >= 0 else ""
		if field_type == "tags":
			value = _parse_tags(str(value))
		CCFStorageService.set_value_at_path(_project, path, value)
	_update_header()


func _generate_character() -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	var profile := CCFSettingsService.active_profile(_settings)
	var generation_settings := _generation_settings()
	var result := _generation_service.queue_character_generation(
		_project,
		_template,
		profile,
		bool(generation_settings.get("include_existing_fields", true)),
		int(generation_settings.get("retry_count", 1))
	)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not queue generation."))
		return
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = (
		"Character generation queued%s."
		% (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
	)


func _suggest_field(field: Dictionary) -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	var profile := CCFSettingsService.active_profile(_settings)
	var result := _generation_service.queue_field_suggestion(
		_project, _template, field, profile, int(_generation_settings().get("retry_count", 1))
	)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not queue field suggestion."))
		return
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = (
		"%s queued%s."
		% [
			str(field.get("label", "Field suggestion")),
			" behind %d job(s)" % queued_ahead if queued_ahead > 0 else ""
		]
	)


func _cancel_active_job() -> void:
	_generation_service.cancel_active_job()


func _on_job_started(_job_id: String, _job_type: String, label: String) -> void:
	_status.text = "%s is running…" % label


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	var origin_project_id := str(metadata.get("project_id", ""))
	var project_level_job := job_type in [
		"group_scene", "relationship_generation", "multi_card_workflow"
	]
	var active_project_id := (
		str(_project_container.get("project_id", ""))
		if project_level_job
		else str(_project.get("project_id", ""))
	)
	if not origin_project_id.is_empty() and origin_project_id != active_project_id:
		if job_type == "ideas" and job_id == _idea_job_id:
			_idea_job_id = ""
			_idea_generate_button.disabled = false
		_status.text = "AI result discarded because its originating project or character is no longer active."
		return
	if job_type == "group_scene" and _group_scene_window != null:
		if _group_scene_window.handle_job_completed(job_id, data, metadata):
			_status.text = "Group scene generation finished. Review the detachable proposal window."
			return
	if job_type == "relationship_generation" and _relationship_window != null:
		if _relationship_window.handle_job_completed(job_id, data, metadata):
			_status.text = "Relationship generation finished. Review the local matrix before applying it."
			return
	if job_type == "multi_card_workflow" and _card_workflow_window != null:
		if _card_workflow_window.handle_job_completed(job_id, data, metadata):
			_status.text = "Card workflow generation finished. Review and save the draft when ready."
			return
	if job_type == "controlled_build" and _controlled_build_window != null:
		if _controlled_build_window.handle_job_completed(job_id, data, metadata):
			return
	if job_type in ["builder_fill", "builder_extract"] and _builder_window != null:
		if _builder_window.handle_job_completed(job_id, job_type, data, metadata):
			_status.text = "Character Builder AI job finished. Review the builder before applying it."
			return
	match job_type:
		"character":
			if data is Dictionary:
				_show_generation_preview(data, metadata, "Full character generation")
		"field":
			var field: Dictionary = metadata.get("field", {})
			var field_id := str(metadata.get("field_id", field.get("id", "field")))
			_show_generation_preview(
				{field_id: data}, metadata, "AI suggestion: %s" % str(field.get("label", field_id))
			)
		"ideas":
			if job_id == _idea_job_id:
				_idea_job_id = ""
				_idea_generate_button.disabled = false
			if data is Array:
				_render_ideas(data)
	if job_type != "ideas":
		_status.text = "Generation finished. Review the proposed changes before applying them."


func _on_job_failed(job_id: String, job_type: String, message: String) -> void:
	if job_type == "group_scene" and _group_scene_window != null:
		if _group_scene_window.handle_job_failed(job_id, message):
			_status.text = message
			return
	if job_type == "relationship_generation" and _relationship_window != null:
		if _relationship_window.handle_job_failed(job_id, message):
			_status.text = message
			return
	if job_type == "multi_card_workflow" and _card_workflow_window != null:
		if _card_workflow_window.handle_job_failed(job_id, message):
			_status.text = message
			return
	if job_type == "controlled_build" and _controlled_build_window != null:
		if _controlled_build_window.handle_job_failed(job_id, message):
			_status.text = message
			return
	if job_type in ["builder_fill", "builder_extract"] and _builder_window != null:
		if _builder_window.handle_job_failed(job_id, message):
			_status.text = message
			return
	if job_type == "ideas" and job_id == _idea_job_id:
		_idea_job_id = ""
		_idea_generate_button.disabled = false
		_idea_status.text = message
	else:
		_status.text = message


func _on_job_cancelled(job_id: String, job_type: String) -> void:
	if job_type == "group_scene" and _group_scene_window != null:
		if _group_scene_window.handle_job_cancelled(job_id):
			_status.text = "Group scene generation cancelled."
			return
	if job_type == "relationship_generation" and _relationship_window != null:
		if _relationship_window.handle_job_cancelled(job_id):
			_status.text = "Relationship generation cancelled."
			return
	if job_type == "multi_card_workflow" and _card_workflow_window != null:
		if _card_workflow_window.handle_job_cancelled(job_id):
			_status.text = "Card workflow generation cancelled."
			return
	if job_type == "controlled_build" and _controlled_build_window != null:
		if _controlled_build_window.handle_job_cancelled(job_id):
			_status.text = "Controlled build cancelled."
			return
	if job_type in ["builder_fill", "builder_extract"] and _builder_window != null:
		if _builder_window.handle_job_cancelled(job_id):
			_status.text = "Character Builder AI job cancelled."
			return
	if job_type == "ideas" and job_id == _idea_job_id:
		_idea_job_id = ""
		_idea_generate_button.disabled = false
		_idea_status.text = "Idea generation cancelled."
	_status.text = "Active AI job cancelled."


func _on_queue_changed(pending_count: int, active_job_id: String, active_label: String) -> void:
	_cancel_button.disabled = active_job_id.is_empty()
	if active_job_id.is_empty():
		_queue_status.text = (
			"AI queue: idle" if pending_count == 0 else "AI queue: %d waiting" % pending_count
		)
	else:
		_queue_status.text = (
			"AI: %s%s" % [active_label, " • %d queued" % pending_count if pending_count > 0 else ""]
		)


func _build_preview_window() -> void:
	_preview_window = Window.new()
	# Window nodes begin life visible. Hide them before configuring force_native;
	# Godot does not allow that property to change while a window is displayed.
	_preview_window.visible = false
	_preview_window.title = "Generation Preview"
	_preview_window.size = Vector2i(980, 720)
	_preview_window.min_size = Vector2i(720, 520)
	_preview_window.force_native = true
	_preview_window.transient = true
	_preview_window.exclusive = false
	_preview_window.close_requested.connect(_hide_preview)
	add_child(_preview_window)
	_preview_window.hide()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_preview_window.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	_preview_summary = Label.new()
	_preview_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_preview_summary)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_preview_result_box = VBoxContainer.new()
	_preview_result_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_result_box.add_theme_constant_override("separation", 12)
	scroll.add_child(_preview_result_box)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)

	var discard_button := Button.new()
	discard_button.text = "Discard"
	discard_button.pressed.connect(_hide_preview)
	actions.add_child(discard_button)

	var apply_button := Button.new()
	apply_button.text = "Apply Selected"
	apply_button.pressed.connect(_apply_preview)
	actions.add_child(apply_button)


func _show_generation_preview(
	generated: Dictionary, metadata: Dictionary, preview_title: String
) -> void:
	_clear_children(_preview_result_box)
	_preview_rows.clear()
	_preview_metadata = metadata.duplicate(true)
	_preview_job_type = preview_title

	var changed_count := 0
	var known_ids: Dictionary = {}
	var allowed_ids: Dictionary = {}
	var raw_allowed_ids = metadata.get("field_ids", [])
	if raw_allowed_ids is Array:
		for allowed_id in raw_allowed_ids:
			allowed_ids[str(allowed_id)] = true
	var restrict_to_allowed := not allowed_ids.is_empty()
	var scoped_ignored_count := 0
	for field in CCFTemplateService.generation_fields(_template):
		var field_id := str(field.get("id", ""))
		known_ids[field_id] = true
		if not generated.has(field_id):
			continue
		if restrict_to_allowed and not allowed_ids.has(field_id):
			scoped_ignored_count += 1
			continue
		var path := str(field.get("path", ""))
		var current_value = CCFStorageService.get_value_at_path(
			_project, path, _default_value_for_type(str(field.get("type", "multiline")))
		)
		var proposed_value = generated.get(field_id)
		if _values_equal(current_value, proposed_value):
			continue
		changed_count += 1
		_add_preview_row(field, current_value, proposed_value)

	var stored_extra_count := 0
	var ignored_extra_count := 0
	var raw_policy = metadata.get("output_policy", CCFTemplateService.output_policy(_template))
	var policy: Dictionary = (
		raw_policy if raw_policy is Dictionary else CCFTemplateService.output_policy(_template)
	)
	for generated_key in generated:
		var key_text := str(generated_key)
		if known_ids.has(key_text):
			continue
		if str(policy.get("unexpected_fields", "ignore")) == "store":
			var extra_field := _extra_generated_field(key_text, generated.get(generated_key))
			var current_extra = CCFStorageService.get_value_at_path(
				_project,
				str(extra_field.get("path", "")),
				_default_value_for_type(str(extra_field.get("type", "multiline")))
			)
			if not _values_equal(current_extra, generated.get(generated_key)):
				_add_preview_row(extra_field, current_extra, generated.get(generated_key))
				changed_count += 1
				stored_extra_count += 1
		else:
			ignored_extra_count += 1

	if changed_count == 0:
		_status.text = "The generation completed, but it did not propose any changed template fields."
		if ignored_extra_count > 0:
			_status.text += (
				" %d unexpected field(s) were ignored by the template policy." % ignored_extra_count
			)
		if scoped_ignored_count > 0:
			_status.text += (
				" %d out-of-scope field(s) were blocked by the controlled-build boundary."
				% scoped_ignored_count
			)
		return

	var policy_note := ""
	if stored_extra_count > 0:
		policy_note += (
			" %d unexpected field(s) can be stored under character.custom.generated_extra."
			% stored_extra_count
		)
	elif ignored_extra_count > 0:
		policy_note += " %d unexpected field(s) were ignored." % ignored_extra_count
	if scoped_ignored_count > 0:
		policy_note += " %d out-of-scope field(s) were blocked." % scoped_ignored_count
	var repair_attempts := int(metadata.get("response_repair_attempts", 0))
	var parse_strategy := str(metadata.get("parse_strategy", "direct"))
	if repair_attempts > 0:
		policy_note += " The response required %d automatic JSON repair pass(es)." % repair_attempts
	elif parse_strategy == "local_json_repair":
		policy_note += " Minor malformed JSON was repaired locally before preview."
	_preview_summary.text = (
		"%s proposed %d changed field(s). Tick the fields you want, edit the proposal if needed, then apply them.%s"
		% [preview_title, changed_count, policy_note]
	)
	_preview_window.title = preview_title
	_preview_project_id = str(metadata.get("project_id", _project.get("project_id", "")))
	_preview_window_has_been_shown = true
	CCFToolWindowStateService.show_window(_preview_window, "generation_preview", Vector2i(980, 720))


func _add_preview_row(field: Dictionary, current_value: Variant, proposed_value: Variant) -> void:
	var panel := PanelContainer.new()
	_preview_result_box.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	var checkbox := CheckBox.new()
	checkbox.text = str(field.get("label", field.get("id", "Field")))
	checkbox.button_pressed = true
	content.add_child(checkbox)

	var current_text := _value_to_text(current_value).strip_edges()
	if not current_text.is_empty():
		var current_label := Label.new()
		current_label.text = "Current: %s" % _shorten(current_text, 360)
		current_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		current_label.modulate = Color(0.62, 0.65, 0.73)
		content.add_child(current_label)

	var field_type := str(field.get("type", "multiline"))
	var editor: Control
	match field_type:
		"line", "tags":
			var line_edit := LineEdit.new()
			line_edit.text = _value_to_text(proposed_value)
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content.add_child(line_edit)
			editor = line_edit
		"number":
			var spin_box := SpinBox.new()
			spin_box.min_value = float(field.get("minimum", -1000000.0))
			spin_box.max_value = float(field.get("maximum", 1000000.0))
			spin_box.step = maxf(0.001, float(field.get("step", 1.0)))
			spin_box.value = float(proposed_value)
			spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content.add_child(spin_box)
			editor = spin_box
		"checkbox":
			var check_box := CheckBox.new()
			check_box.text = "Enabled"
			check_box.button_pressed = bool(proposed_value)
			content.add_child(check_box)
			editor = check_box
		"select":
			var option_button := OptionButton.new()
			var options = field.get("options", [])
			var selected_index := 0
			if options is Array:
				for option_index in range(options.size()):
					var option_text := str(options[option_index])
					option_button.add_item(option_text)
					option_button.set_item_metadata(option_index, option_text)
					if option_text == str(proposed_value):
						selected_index = option_index
			if option_button.item_count == 0:
				option_button.add_item(str(proposed_value))
				option_button.set_item_metadata(0, str(proposed_value))
			option_button.select(selected_index)
			option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content.add_child(option_button)
			editor = option_button
		_:
			var text_edit := TextEdit.new()
			text_edit.text = _value_to_text(proposed_value)
			text_edit.custom_minimum_size.y = 140
			text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content.add_child(text_edit)
			editor = text_edit

	_preview_rows.append({"field": field.duplicate(true), "checkbox": checkbox, "editor": editor})


func _apply_preview() -> void:
	if (
		not _preview_project_id.is_empty()
		and _preview_project_id != str(_project.get("project_id", ""))
	):
		_status.text = "This generation preview belongs to a different character and was not applied."
		_hide_preview()
		return
	var applied_fields: Array[String] = []
	for row in _preview_rows:
		var checkbox: CheckBox = row.get("checkbox")
		if not checkbox.button_pressed:
			continue
		var field: Dictionary = row.get("field", {})
		var editor: Control = row.get("editor")
		var field_type := str(field.get("type", "multiline"))
		var value: Variant = _default_value_for_type(field_type)
		if editor is LineEdit:
			value = editor.text
		elif editor is TextEdit:
			value = editor.text
		elif editor is SpinBox:
			value = editor.value
		elif editor is CheckBox:
			value = editor.button_pressed
		elif editor is OptionButton:
			value = str(editor.get_selected_metadata()) if editor.selected >= 0 else ""
		if field_type == "tags":
			value = _parse_tags(str(value))
		CCFStorageService.set_value_at_path(_project, str(field.get("path", "")), value)
		applied_fields.append(str(field.get("id", "field")))

	if applied_fields.is_empty():
		_status.text = "No generated fields were applied."
		_hide_preview()
		return

	_record_generation_history(applied_fields, _preview_job_type, _preview_metadata)
	_dirty = true
	_rebuild_form()
	_update_header()
	_status.text = (
		"Applied %d generated field(s). Review them, then Save when ready." % applied_fields.size()
	)
	_hide_preview()


func _hide_preview() -> void:
	if _preview_window != null:
		if _preview_window_has_been_shown:
			CCFToolWindowStateService.save_window(_preview_window, "generation_preview")
		_preview_window.hide()
	_preview_project_id = ""


func _build_idea_window() -> void:
	_idea_window = Window.new()
	# Hide before configuring force_native for the same reason as Generation Preview.
	_idea_window.visible = false
	_idea_window.title = "Idea Generator"
	_idea_window.size = Vector2i(900, 720)
	_idea_window.min_size = Vector2i(680, 500)
	_idea_window.force_native = true
	_idea_window.transient = true
	_idea_window.exclusive = false
	_idea_window.close_requested.connect(_hide_idea_window)
	add_child(_idea_window)
	_idea_window.hide()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_idea_window.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var hint := Label.new()
	hint.text = "Give the AI a theme, fragments, constraints, or leave it blank for varied character concepts."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)

	_idea_seed = TextEdit.new()
	_idea_seed.placeholder_text = "Example: cyberpunk Australia, reluctant healer, enemies-to-allies dynamic…"
	_idea_seed.custom_minimum_size.y = 110
	_idea_seed.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	root.add_child(_idea_seed)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)

	var count_label := Label.new()
	count_label.text = "Ideas"
	controls.add_child(count_label)

	_idea_count = SpinBox.new()
	_idea_count.min_value = 1
	_idea_count.max_value = 12
	_idea_count.step = 1
	_idea_count.value = 6
	controls.add_child(_idea_count)

	_idea_generate_button = Button.new()
	_idea_generate_button.text = "Generate Ideas"
	_idea_generate_button.pressed.connect(_generate_ideas)
	controls.add_child(_idea_generate_button)

	_idea_status = Label.new()
	_idea_status.text = "Ready"
	_idea_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_idea_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_child(_idea_status)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_idea_result_box = VBoxContainer.new()
	_idea_result_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_idea_result_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_idea_result_box)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_hide_idea_window)
	root.add_child(close_button)


func _open_idea_generator() -> void:
	_capture_all_fields()
	var existing_concept := (
		str(CCFStorageService.get_value_at_path(_project, "concept.prompt", "")).strip_edges()
	)
	if _idea_seed.text.strip_edges().is_empty() and not existing_concept.is_empty():
		_idea_seed.text = existing_concept
	_idea_count.value = int(_generation_settings().get("default_idea_count", 6))
	_idea_window_has_been_shown = true
	CCFToolWindowStateService.show_window(_idea_window, "idea_generator", Vector2i(900, 720))


func _generate_ideas() -> void:
	var profile := CCFSettingsService.active_profile(_settings)
	var result := _generation_service.queue_idea_generation(
		_idea_seed.text,
		profile,
		int(_idea_count.value),
		int(_generation_settings().get("retry_count", 1)),
		str(_project.get("project_id", "")),
		CCFSeriesService.generation_context_for_project(_project)
	)
	if not result.get("ok", false):
		_idea_status.text = str(result.get("error", "Could not queue idea generation."))
		return
	_idea_job_id = str(result.get("job_id", ""))
	_idea_generate_button.disabled = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	_idea_status.text = (
		"Queued%s" % (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
	)


func _render_ideas(ideas: Array) -> void:
	_clear_children(_idea_result_box)
	if ideas.is_empty():
		_idea_status.text = "No usable ideas were returned."
		return

	for idea in ideas:
		if not idea is Dictionary:
			continue
		var panel := PanelContainer.new()
		_idea_result_box.add_child(panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 12)
		panel.add_child(margin)

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 7)
		margin.add_child(content)

		var idea_title := Label.new()
		idea_title.text = str(idea.get("title", "Untitled idea"))
		idea_title.add_theme_font_size_override("font_size", 18)
		content.add_child(idea_title)

		var tags := _value_to_text(idea.get("tags", []))
		if not tags.is_empty():
			var tags_label := Label.new()
			tags_label.text = tags
			tags_label.modulate = Color(0.64, 0.68, 0.82)
			tags_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(tags_label)

		var concept_label := Label.new()
		concept_label.text = str(idea.get("concept", ""))
		concept_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(concept_label)

		var use_button := Button.new()
		use_button.text = "Use This Idea"
		use_button.pressed.connect(_use_idea.bind(idea.duplicate(true)))
		content.add_child(use_button)

	_idea_status.text = "Generated %d idea(s)." % ideas.size()


func _use_idea(idea: Dictionary) -> void:
	var concept := str(idea.get("concept", "")).strip_edges()
	if concept.is_empty():
		return
	CCFStorageService.set_value_at_path(_project, "concept.prompt", concept)

	var current_name := (
		str(CCFStorageService.get_value_at_path(_project, "character.name", "Untitled Character"))
		. strip_edges()
	)
	var suggested_name := str(idea.get("title", "")).strip_edges()
	if (
		(current_name.is_empty() or current_name == "Untitled Character")
		and not suggested_name.is_empty()
	):
		CCFStorageService.set_value_at_path(_project, "character.name", suggested_name)

	var existing_tags = CCFStorageService.get_value_at_path(_project, "metadata.tags", [])
	var merged_tags: Array[String] = []
	if existing_tags is Array:
		for existing_tag in existing_tags:
			var clean_existing := str(existing_tag).strip_edges()
			if not clean_existing.is_empty() and not merged_tags.has(clean_existing):
				merged_tags.append(clean_existing)
	var suggested_tags = idea.get("tags", [])
	if suggested_tags is Array:
		for suggested_tag in suggested_tags:
			var clean_suggested := str(suggested_tag).strip_edges()
			if not clean_suggested.is_empty() and not merged_tags.has(clean_suggested):
				merged_tags.append(clean_suggested)
	CCFStorageService.set_value_at_path(_project, "metadata.tags", merged_tags)

	_dirty = true
	_rebuild_form()
	_update_header()
	_status.text = "Idea applied to the concept. Generate the character when you are ready."
	_hide_idea_window()


func _hide_idea_window() -> void:
	if _idea_window != null:
		if _idea_window_has_been_shown:
			CCFToolWindowStateService.save_window(_idea_window, "idea_generator")
		_idea_window.hide()


func _build_character_builder_window() -> void:
	_builder_window = CCFCharacterBuilderWindow.new()
	_builder_window.visible = false
	_builder_window.title = "Character Builder"
	_builder_window.size = Vector2i(1180, 820)
	_builder_window.min_size = Vector2i(880, 620)
	_builder_window.force_native = true
	_builder_window.transient = true
	_builder_window.exclusive = false
	_builder_window.set_generation_service(_generation_service)
	_builder_window.builder_state_changed.connect(_on_builder_state_changed)
	_builder_window.concept_apply_requested.connect(_on_builder_concept_apply_requested)
	_builder_window.character_apply_requested.connect(_on_builder_character_apply_requested)
	_builder_window.concept_refresh_requested.connect(_refresh_builder_project_context)
	add_child(_builder_window)
	_builder_window.hide()


func _open_character_builder() -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	_capture_builder_state_if_loaded()
	_builder_window.open_for_project(_project, _settings)
	_builder_window_has_been_shown = true
	CCFToolWindowStateService.show_window(_builder_window, "character_builder", Vector2i(1180, 820))


func _on_builder_state_changed(builder_state: Dictionary) -> void:
	if _project.is_empty() or not _builder_window.owns_project(str(_project.get("project_id", ""))):
		return
	var workspace: Dictionary = _project.get("workspace", {})
	var existing_builder = workspace.get("builder", {})
	var normalised_existing := CCFBuilderService.normalise_state(
		existing_builder if existing_builder is Dictionary else {}
	)
	var normalised_incoming := CCFBuilderService.normalise_state(builder_state)
	if JSON.stringify(normalised_existing) == JSON.stringify(normalised_incoming):
		return
	_store_builder_state(normalised_incoming)
	_dirty = true
	_status.text = "Unsaved Character Builder changes"
	_update_header()


func _on_builder_concept_apply_requested(builder_state: Dictionary) -> void:
	if _project.is_empty() or not _builder_window.owns_project(str(_project.get("project_id", ""))):
		return
	_capture_all_fields()
	_store_builder_state(builder_state)
	var changed_paths := CCFBuilderService.write_concept_to_project(_project, builder_state)
	if changed_paths.is_empty():
		_status.text = "The builder does not contain enough information to create a concept."
		return
	_dirty = true
	_rebuild_form()
	_update_header()
	_builder_window.update_project_context(_project, _settings)
	_status.text = "Builder brief sent to the generation concept. Review it in the workspace, then Save when ready."


func _on_builder_character_apply_requested(
	builder_state: Dictionary, overwrite_existing: bool
) -> void:
	if _project.is_empty() or not _builder_window.owns_project(str(_project.get("project_id", ""))):
		return
	_capture_all_fields()
	_store_builder_state(builder_state)
	var changed_paths := CCFBuilderService.apply_to_project(
		_project, builder_state, overwrite_existing
	)
	if changed_paths.is_empty():
		_status.text = "No character fields changed. Enable overwrite if the destination fields already contain content."
		return
	_dirty = true
	_rebuild_form()
	_update_header()
	_builder_window.update_project_context(_project, _settings)
	_status.text = (
		"Applied Character Builder data to %d workspace field(s). Review them, then Save when ready."
		% changed_paths.size()
	)


func _refresh_builder_project_context() -> void:
	if _project.is_empty() or _builder_window == null:
		return
	_capture_all_fields()
	_builder_window.update_project_context(_project, _settings)


func _store_builder_state(builder_state: Dictionary) -> void:
	var workspace: Dictionary = _project.get("workspace", {}).duplicate(true)
	workspace["builder"] = CCFBuilderService.normalise_state(builder_state)
	_project["workspace"] = workspace


func _capture_builder_state_if_loaded() -> void:
	if _builder_window == null or _project.is_empty():
		return
	if not _builder_window.owns_project(str(_project.get("project_id", ""))):
		return
	_store_builder_state(_builder_window.current_state())


func _hide_character_builder() -> void:
	if _builder_window == null:
		return
	if _builder_window.owns_project(str(_project.get("project_id", ""))):
		_store_builder_state(_builder_window.current_state())
	if _builder_window_has_been_shown:
		CCFToolWindowStateService.save_window(_builder_window, "character_builder")
	_builder_window.hide()


func _build_controlled_build_window() -> void:
	_controlled_build_window = CCFControlledBuildWindow.new()
	_controlled_build_window.visible = false
	_controlled_build_window.title = "Controlled Build"
	_controlled_build_window.size = Vector2i(1040, 760)
	_controlled_build_window.min_size = Vector2i(760, 560)
	_controlled_build_window.force_native = true
	_controlled_build_window.transient = true
	_controlled_build_window.exclusive = false
	_controlled_build_window.set_generation_service(_generation_service)
	_controlled_build_window.preview_requested.connect(_show_generation_preview)
	_controlled_build_window.project_refresh_requested.connect(_refresh_controlled_build_context)
	add_child(_controlled_build_window)
	_controlled_build_window.hide()


func _open_controlled_build() -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	_controlled_build_window.open_for_project(_project, _template, _settings)
	_controlled_build_window_has_been_shown = true
	CCFToolWindowStateService.show_window(
		_controlled_build_window, "controlled_build", Vector2i(1040, 760)
	)


func _refresh_controlled_build_context() -> void:
	if _project.is_empty() or _controlled_build_window == null:
		return
	_capture_all_fields()
	_controlled_build_window.update_project_context(_project, _template, _settings)


func _hide_controlled_build() -> void:
	if _controlled_build_window == null:
		return
	if _controlled_build_window_has_been_shown:
		CCFToolWindowStateService.save_window(_controlled_build_window, "controlled_build")
	_controlled_build_window.hide()


func save_tool_window_state() -> void:
	if _preview_window != null and _preview_window_has_been_shown:
		CCFToolWindowStateService.save_window(_preview_window, "generation_preview")
	if _idea_window != null and _idea_window_has_been_shown:
		CCFToolWindowStateService.save_window(_idea_window, "idea_generator")
	if _builder_window != null and _builder_window_has_been_shown:
		CCFToolWindowStateService.save_window(_builder_window, "character_builder")
	if _controlled_build_window != null and _controlled_build_window_has_been_shown:
		CCFToolWindowStateService.save_window(_controlled_build_window, "controlled_build")
	if _project_context_window != null:
		_project_context_window.save_window_state()
	if _group_scene_window != null:
		_group_scene_window.save_window_state()
	if _relationship_window != null:
		_relationship_window.save_window_state()
	if _card_workflow_window != null:
		_card_workflow_window.save_window_state()
	if _import_export_window != null:
		_import_export_window.save_window_state()


func _close_tool_windows_for_project_change() -> void:
	_hide_preview()
	_hide_idea_window()
	_idea_job_id = ""
	_idea_generate_button.disabled = false
	_idea_seed.text = ""
	_idea_status.text = "Ready"
	_clear_children(_idea_result_box)
	_hide_character_builder()
	_builder_window.release_project()
	_hide_controlled_build()
	_controlled_build_window.release_project()


func _record_generation_history(
	applied_fields: Array[String], job_type: String, metadata: Dictionary
) -> void:
	var generation: Dictionary = _project.get("generation", {}).duplicate(true)
	var generated_at := Time.get_datetime_string_from_system(true)
	generation["last_model"] = str(metadata.get("model", ""))
	generation["last_generated_at"] = generated_at
	var history: Array = generation.get("history", []).duplicate(true)
	history.push_front(
		{
			"generated_at": generated_at,
			"model": str(metadata.get("model", "")),
			"profile_name": str(metadata.get("profile_name", "")),
			"job_type": job_type,
			"fields": applied_fields,
			"attempts": int(metadata.get("attempts", 1)),
			"response_repair_attempts": int(metadata.get("response_repair_attempts", 0)),
			"parse_strategy": str(metadata.get("parse_strategy", "direct"))
		}
	)
	if history.size() > 50:
		history.resize(50)
	generation["history"] = history
	_project["generation"] = generation


func _generation_settings() -> Dictionary:
	var generation_settings = _settings.get("generation", {})
	if generation_settings is Dictionary:
		return generation_settings
	return {}


func _update_concept_estimate() -> void:
	if _concept_token_label == null:
		return
	var row = _field_controls.get("concept.prompt", {})
	if not row is Dictionary:
		return
	var control: Control = row.get("control")
	var concept_text := ""
	if control is LineEdit:
		concept_text = control.text
	elif control is TextEdit:
		concept_text = control.text
	_concept_token_label.text = (
		"Approximate concept input size: %d tokens"
		% CCFGenerationService.estimate_tokens(concept_text)
	)


func _mark_dirty() -> void:
	if _project.is_empty():
		return
	_dirty = true
	_status.text = "Unsaved changes"
	_update_header()


func _update_header() -> void:
	if _project.is_empty():
		_title.text = "Character Workspace"
		return
	var character_name := (
		str(CCFStorageService.get_value_at_path(_project, "character.name", "Untitled Character"))
		. strip_edges()
	)
	if character_name.is_empty():
		character_name = "Untitled Character"
	var project_name := "Untitled Project"
	var metadata = _project_container.get("metadata", {})
	if metadata is Dictionary:
		project_name = str(metadata.get("name", project_name)).strip_edges()
	_title.text = "%s  •  %s%s" % [project_name, character_name, " *" if _dirty else ""]


func _default_value_for_type(field_type: String) -> Variant:
	match field_type:
		"tags":
			return []
		"number":
			return 0.0
		"checkbox":
			return false
		_:
			return ""


func _values_equal(first: Variant, second: Variant) -> bool:
	if first is String and second is String:
		return first.strip_edges() == second.strip_edges()
	return JSON.stringify(first) == JSON.stringify(second)


func _extra_generated_field(field_id: String, value: Variant) -> Dictionary:
	var field_type := "multiline"
	if value is bool:
		field_type = "checkbox"
	elif value is int or value is float:
		field_type = "number"
	elif value is Array:
		field_type = "tags"
	return {
		"id": field_id,
		"label": "%s (extra)" % field_id.replace("_", " ").capitalize(),
		"type": field_type,
		"path": "character.custom.generated_extra.%s" % _safe_path_key(field_id),
		"generate": true,
		"required": false,
		"minimum": -1000000.0,
		"maximum": 1000000.0,
		"step": 1.0
	}


func _safe_path_key(value: String) -> String:
	var result := ""
	for character in value.to_lower():
		if (
			(character >= "a" and character <= "z")
			or (character >= "0" and character <= "9")
			or character == "_"
		):
			result += character
		else:
			result += "_"
	while "__" in result:
		result = result.replace("__", "_")
	result = result.trim_prefix("_").trim_suffix("_")
	return result if not result.is_empty() else "extra_field"


func _parse_tags(text: String) -> Array[String]:
	var tags: Array[String] = []
	for raw_tag in text.split(",", false):
		var clean_tag := raw_tag.strip_edges()
		if not clean_tag.is_empty() and not tags.has(clean_tag):
			tags.append(clean_tag)
	return tags


func _value_to_text(value: Variant) -> String:
	if value is Array:
		return _join_values(value, ", ")
	return str(value)


func _shorten(text: String, maximum_length: int) -> String:
	if text.length() <= maximum_length:
		return text
	return text.left(maximum_length).strip_edges() + "…"


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _join_values(values: Array, separator: String) -> String:
	var result := ""
	for index in range(values.size()):
		if index > 0:
			result += separator
		result += str(values[index])
	return result
