class_name CCFWorkspaceCurrent
extends "res://scripts/ui/workspace_v0201.gd"

const FRONT_PORCH_SERVICE_CURRENT = preload(
	"res://scripts/services/front_porch_extension_service_current.gd"
)
const FRONT_PORCH_WORK_HOURS_CONTROL_V0209 = preload(
	"res://scripts/ui/front_porch_work_hours_control_v0209.gd"
)
const IDEA_GENERATOR_CURRENT = preload(
	"res://scripts/ui/idea_generator_window_current.gd"
)
const IDEA_CUSTOM_LENGTH_V0211 = preload(
	"res://scripts/services/idea_generator_custom_length_v0211.gd"
)
const IDEA_BATCHING_V0211 = preload(
	"res://scripts/services/idea_generator_batching_v0211.gd"
)
const PERSONALITY_READABILITY_V0212 = preload(
	"res://scripts/services/personality_readability_service_v0212.gd"
)
const IDEA_SOURCE_SERVICE_V0213 = preload(
	"res://scripts/services/idea_source_service_v0213.gd"
)
const SIMILAR_IDEA_SOURCE_V0213 = preload(
	"res://scripts/services/similar_idea_source_service_v0213.gd"
)

const GENERATE_SIMILAR_IDEAS_MENU_ID_V0213 := 21300

var _idea_custom_length_panel_v0211: VBoxContainer
var _idea_custom_target_v0211: SpinBox
var _idea_batch_size_v0211: SpinBox
var _idea_batch_plan_hint_v0211: Label
var _idea_batch_group_id_v0211 := ""
var _idea_batch_requested_total_v0211 := 0
var _idea_batch_expected_requests_v0211 := 0
var _idea_batch_job_indices_v0211: Dictionary = {}
var _idea_batch_terminal_jobs_v0211: Dictionary = {}
var _idea_batch_results_v0211: Dictionary = {}
var _idea_batch_metadata_v0211: Dictionary = {}
var _idea_batch_errors_v0211: Array[String] = []
var _idea_batch_cancelling_v0211 := false
var _similar_ideas_window_v0213: Window
var _similarity_mode_v0213: OptionButton
var _similar_source_title_v0213: LineEdit
var _similar_source_preview_v0213: TextEdit
var _similar_source_status_v0213: Label
var _similar_source_card_v0213: Dictionary = {}
var _similar_extracted_source_v0213: Dictionary = {}
var _idea_source_title_job_id_v0213 := ""
var _idea_source_title_id_v0213 := ""
var _idea_prompt_hint_v0213: Label


func _ready() -> void:
	super._ready()
	_build_similar_ideas_window_v0213()
	_add_generate_similar_ideas_action_v0213()
	_install_idea_prompt_presentation_v0213()


func _init() -> void:
	_front_porch_service_v0172 = FRONT_PORCH_SERVICE_CURRENT.new()


func _build_concept_studio() -> void:
	_idea_generator_v01532 = IDEA_GENERATOR_CURRENT.new()
	_idea_generator_v01532.visible = false
	_idea_generator_v01532.concept_selected.connect(_on_structured_concept_selected)
	if _idea_generator_v01532.has_signal("collaborator_source_requested"):
		_idea_generator_v01532.connect(
			"collaborator_source_requested",
			Callable(self, "_on_collaborator_source_requested_v01533")
		)
	if _idea_generator_v01532.has_signal(
		"idea_source_title_requested_v0213"
	):
		_idea_generator_v01532.connect(
			"idea_source_title_requested_v0213",
			Callable(self, "_on_idea_source_title_requested_v0213")
		)
	if _idea_generator_v01532.has_signal(
		"active_idea_source_changed_v0213"
	):
		_idea_generator_v01532.connect(
			"active_idea_source_changed_v0213",
			Callable(self, "_on_active_idea_source_changed_v0213")
		)
	add_child(_idea_generator_v01532)
	_idea_generator_v01532.hide()
	_idea_generator_v01412 = _idea_generator_v01532
	_concept_studio = _idea_generator_v01532


func _add_field(parent: VBoxContainer, field: Dictionary) -> void:
	var first_added_index := parent.get_child_count()
	super._add_field(parent, field)
	if str(field.get("path", "")) != "character.personality":
		return
	var row_value: Variant = _field_controls.get("character.personality", {})
	if not row_value is Dictionary:
		return
	var editor_value: Variant = (row_value as Dictionary).get("control")
	if not editor_value is TextEdit:
		return
	var heading_row: HBoxContainer = null
	if (
		first_added_index >= 0
		and first_added_index < parent.get_child_count()
		and parent.get_child(first_added_index) is HBoxContainer
	):
		heading_row = parent.get_child(first_added_index) as HBoxContainer
	if heading_row == null:
		return
	_install_personality_readable_view_v0212(
		editor_value as TextEdit,
		parent,
		heading_row,
		"PersonalityReadablePreviewV0212"
	)


func _add_preview_row(
	field: Dictionary, current_value: Variant, proposed_value: Variant
) -> void:
	var previous_count := _preview_rows.size()
	super._add_preview_row(field, current_value, proposed_value)
	if (
		str(field.get("path", "")) != "character.personality"
		or _preview_rows.size() <= previous_count
	):
		return
	var row_value: Variant = _preview_rows[-1]
	if not row_value is Dictionary:
		return
	var editor_value: Variant = (row_value as Dictionary).get("editor")
	if not editor_value is TextEdit:
		return
	var editor := editor_value as TextEdit
	if not editor.get_parent() is VBoxContainer:
		return
	var content := editor.get_parent() as VBoxContainer
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	content.add_child(toolbar)
	content.move_child(toolbar, editor.get_index())
	var label := Label.new()
	label.text = "Personality display"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.modulate = Color(0.68, 0.71, 0.82)
	toolbar.add_child(label)
	_install_personality_readable_view_v0212(
		editor,
		content,
		toolbar,
		"PersonalityGeneratedReadablePreviewV0212"
	)


func _install_personality_readable_view_v0212(
	editor: TextEdit,
	parent: VBoxContainer,
	toolbar: HBoxContainer,
	preview_name: String
) -> void:
	editor.name = "%sRawEditor" % preview_name
	var toggle := Button.new()
	toggle.name = "%sToggle" % preview_name
	toggle.tooltip_text = (
		"Switch between visual section spacing and the exact stored text. Readable spacing never changes the card, exports or token estimate."
	)
	toolbar.add_child(toggle)
	var preview := TextEdit.new()
	preview.name = preview_name
	preview.editable = false
	preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	preview.custom_minimum_size.y = editor.custom_minimum_size.y
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.tooltip_text = (
		"Display-only spacing before Personality section headings. The underlying card text is unchanged."
	)
	parent.add_child(preview)
	var hint := Label.new()
	hint.name = "%sHint" % preview_name
	hint.text = (
		"Readable spacing is visual only — saved cards, exports and token estimates use the unchanged text."
	)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.62, 0.66, 0.77)
	parent.add_child(hint)
	var headings := _personality_heading_labels_v0212()
	toggle.pressed.connect(
		_toggle_personality_readable_view_v0212.bind(
			editor, preview, toggle, hint, headings
		)
	)
	editor.text_changed.connect(
		_refresh_personality_readable_view_v0212.bind(
			editor, preview, toggle, hint, headings
		)
	)
	_refresh_personality_readable_view_v0212(
		editor, preview, toggle, hint, headings
	)
	var result := PERSONALITY_READABILITY_V0212.format_for_display(
		editor.text, headings
	)
	_set_personality_readable_mode_v0212(
		editor,
		preview,
		toggle,
		hint,
		bool(result.get("readable_view_recommended", false))
	)


func _refresh_personality_readable_view_v0212(
	editor: TextEdit,
	preview: TextEdit,
	toggle: Button,
	hint: Label,
	headings: Array
) -> void:
	if not is_instance_valid(editor) or not is_instance_valid(preview):
		return
	var result := PERSONALITY_READABILITY_V0212.format_for_display(
		editor.text, headings
	)
	preview.text = str(result.get("display_text", editor.text))
	var structured := bool(result.get("readable_view_recommended", false))
	toggle.disabled = not structured
	if not structured and preview.visible:
		_set_personality_readable_mode_v0212(
			editor, preview, toggle, hint, false
		)


func _toggle_personality_readable_view_v0212(
	editor: TextEdit,
	preview: TextEdit,
	toggle: Button,
	hint: Label,
	headings: Array
) -> void:
	if preview.visible:
		_set_personality_readable_mode_v0212(
			editor, preview, toggle, hint, false
		)
		editor.grab_focus()
		return
	_refresh_personality_readable_view_v0212(
		editor, preview, toggle, hint, headings
	)
	if not toggle.disabled:
		_set_personality_readable_mode_v0212(
			editor, preview, toggle, hint, true
		)


func _set_personality_readable_mode_v0212(
	editor: TextEdit,
	preview: TextEdit,
	toggle: Button,
	hint: Label,
	readable: bool
) -> void:
	editor.visible = not readable
	preview.visible = readable
	hint.visible = readable
	toggle.text = "Edit text" if readable else "Readable view"


func _personality_heading_labels_v0212() -> Array:
	var headings: Array = []
	var groups_value: Variant = _template.get("generation_groups", [])
	if not groups_value is Array:
		return headings
	for group_value in groups_value as Array:
		if not group_value is Dictionary:
			continue
		var group := group_value as Dictionary
		if str(group.get("output_field_id", "")) != "personality":
			continue
		headings.append(str(group.get("title", "")))
		var components_value: Variant = group.get("components", [])
		if not components_value is Array:
			continue
		for component_value in components_value as Array:
			if component_value is Dictionary:
				headings.append(
					str((component_value as Dictionary).get("label", ""))
				)
	return headings


func personality_readability_capabilities_v0212() -> Dictionary:
	var result := PERSONALITY_READABILITY_V0212.capabilities()
	result["workspace_readable_view"] = true
	result["generation_preview_readable_view"] = true
	result["template_heading_count"] = (
		_personality_heading_labels_v0212().size()
	)
	return result


func _install_idea_detail_selector_v0167() -> void:
	super._install_idea_detail_selector_v0167()
	if _idea_detail_selector_v0167 == null:
		return
	var custom_index := _idea_detail_selector_v0167.item_count
	_idea_detail_selector_v0167.add_item("Custom")
	_idea_detail_selector_v0167.set_item_metadata(custom_index, "custom")
	_idea_detail_selector_v0167.tooltip_text += (
		" Custom adds an approximate text-character target for each idea's concept."
	)
	var controls := _idea_detail_selector_v0167.get_parent() as HBoxContainer
	if controls == null or not controls.get_parent() is VBoxContainer:
		return
	var root := controls.get_parent() as VBoxContainer
	_idea_custom_length_panel_v0211 = VBoxContainer.new()
	_idea_custom_length_panel_v0211.name = "IdeaCustomLengthPanelV0211"
	_idea_custom_length_panel_v0211.add_theme_constant_override("separation", 4)
	root.add_child(_idea_custom_length_panel_v0211)
	root.move_child(
		_idea_custom_length_panel_v0211, controls.get_index() + 1
	)
	var target_row := HFlowContainer.new()
	target_row.name = "IdeaCustomLengthControlsV0211"
	target_row.add_theme_constant_override("separation", 8)
	_idea_custom_length_panel_v0211.add_child(target_row)
	var target_label := Label.new()
	target_label.text = "Target characters per idea"
	target_row.add_child(target_label)
	_idea_custom_target_v0211 = SpinBox.new()
	_idea_custom_target_v0211.name = "IdeaCustomTargetCharactersV0211"
	_idea_custom_target_v0211.min_value = (
		IDEA_CUSTOM_LENGTH_V0211.MIN_TARGET_CHARACTERS
	)
	_idea_custom_target_v0211.max_value = (
		IDEA_CUSTOM_LENGTH_V0211.MAX_TARGET_CHARACTERS
	)
	_idea_custom_target_v0211.step = 250
	_idea_custom_target_v0211.value = (
		IDEA_CUSTOM_LENGTH_V0211.DEFAULT_TARGET_CHARACTERS
	)
	_idea_custom_target_v0211.allow_greater = false
	_idea_custom_target_v0211.allow_lesser = false
	_idea_custom_target_v0211.suffix = " chars/idea"
	_idea_custom_target_v0211.custom_minimum_size.x = 210
	_idea_custom_target_v0211.tooltip_text = (
		"Approximate Unicode text-character target for each generated idea's concept field. Model compliance varies."
	)
	_idea_custom_target_v0211.value_changed.connect(
		_on_idea_custom_target_changed_v0211
	)
	target_row.add_child(_idea_custom_target_v0211)
	var guidance := Label.new()
	guidance.name = "IdeaCustomLengthGuidanceV0211"
	guidance.text = (
		"This is a soft target. CCF requests enough output capacity when possible, but the selected model controls the final length."
	)
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guidance.modulate = Color(0.64, 0.68, 0.82)
	_idea_custom_length_panel_v0211.add_child(guidance)
	_idea_custom_length_panel_v0211.hide()
	_install_idea_batch_controls_v0211(root, controls)


func _install_idea_batch_controls_v0211(
	root: VBoxContainer, controls: HBoxContainer
) -> void:
	_idea_count.max_value = IDEA_BATCHING_V0211.MAX_TOTAL_IDEAS
	_idea_count.allow_greater = false
	_idea_count.tooltip_text = (
		"Total ideas to generate. CCF can combine several sequential provider requests up to a maximum of %d ideas."
		% IDEA_BATCHING_V0211.MAX_TOTAL_IDEAS
	)
	var panel := VBoxContainer.new()
	panel.name = "IdeaRequestBatchingV0211"
	panel.add_theme_constant_override("separation", 3)
	root.add_child(panel)
	root.move_child(panel, controls.get_index() + 1)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var label := Label.new()
	label.text = "Ideas per provider request"
	row.add_child(label)
	_idea_batch_size_v0211 = SpinBox.new()
	_idea_batch_size_v0211.name = "IdeasPerRequestV0211"
	_idea_batch_size_v0211.min_value = 1
	_idea_batch_size_v0211.max_value = IDEA_BATCHING_V0211.MAX_IDEAS_PER_REQUEST
	_idea_batch_size_v0211.step = 1
	_idea_batch_size_v0211.value = IDEA_BATCHING_V0211.DEFAULT_IDEAS_PER_REQUEST
	_idea_batch_size_v0211.allow_greater = false
	_idea_batch_size_v0211.allow_lesser = false
	_idea_batch_size_v0211.custom_minimum_size.x = 100
	_idea_batch_size_v0211.tooltip_text = (
		"Use 1 for one idea per request on smaller models. Higher values reduce the number of provider calls."
	)
	row.add_child(_idea_batch_size_v0211)
	_idea_batch_plan_hint_v0211 = Label.new()
	_idea_batch_plan_hint_v0211.name = "IdeaBatchPlanHintV0211"
	_idea_batch_plan_hint_v0211.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_idea_batch_plan_hint_v0211.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_idea_batch_plan_hint_v0211.modulate = Color(0.64, 0.68, 0.82)
	panel.add_child(_idea_batch_plan_hint_v0211)
	_idea_count.value_changed.connect(
		func(_value: float) -> void: _refresh_idea_batch_plan_v0211()
	)
	_idea_batch_size_v0211.value_changed.connect(
		func(_value: float) -> void: _refresh_idea_batch_plan_v0211()
	)
	_refresh_idea_batch_plan_v0211()


func _refresh_idea_batch_plan_v0211() -> void:
	if _idea_batch_plan_hint_v0211 == null or _idea_count == null:
		return
	var total := IDEA_BATCHING_V0211.normalise_total_ideas(
		int(_idea_count.value)
	)
	var per_request := _idea_batch_size_value_v0211()
	var plan := IDEA_BATCHING_V0211.request_plan(total, per_request)
	var request_phrase := (
		"provider request"
		if plan.size() == 1
		else "sequential provider requests"
	)
	var small_model_note := (
		" • one idea at a time for smaller models"
		if per_request == 1 and plan.size() > 1
		else ""
	)
	_idea_batch_plan_hint_v0211.text = (
		"Plan: %d ideas across %d %s%s. Successful requests are combined in order."
		% [total, plan.size(), request_phrase, small_model_note]
	)


func _on_idea_detail_selected_v0167(index: int) -> void:
	var selected_id := ""
	if (
		_idea_detail_selector_v0167 != null
		and index >= 0
		and index < _idea_detail_selector_v0167.item_count
	):
		selected_id = str(
			_idea_detail_selector_v0167.get_item_metadata(index)
		)
	if selected_id == "custom":
		_selected_idea_detail_level_v0167 = "custom"
		if _idea_custom_length_panel_v0211 != null:
			_idea_custom_length_panel_v0211.show()
		_refresh_idea_detail_hint_v0167()
		return
	super._on_idea_detail_selected_v0167(index)
	if _idea_custom_length_panel_v0211 != null:
		_idea_custom_length_panel_v0211.hide()


func _on_idea_custom_target_changed_v0211(_value: float) -> void:
	if _selected_idea_detail_level_v0167 == "custom":
		_refresh_idea_detail_hint_v0167()


func _refresh_idea_detail_hint_v0167() -> void:
	if _selected_idea_detail_level_v0167 != "custom":
		super._refresh_idea_detail_hint_v0167()
		return
	if _idea_detail_hint_v0167 == null:
		return
	var target := _idea_custom_target_characters_v0211()
	_idea_detail_hint_v0167.text = (
		"Custom — aim for approximately %s text characters in each idea's concept. This is model-guided, not guaranteed."
		% _format_integer_v0211(target)
	)


func _generate_ideas() -> void:
	_reset_idea_batch_state_v0211()
	var total := IDEA_BATCHING_V0211.normalise_total_ideas(
		int(_idea_count.value)
	)
	var per_request := _idea_batch_size_value_v0211()
	var plan := IDEA_BATCHING_V0211.request_plan(total, per_request)
	if plan.size() == 1:
		var result := _queue_idea_request_v0211(plan[0])
		if not bool(result.get("ok", false)):
			_idea_status.text = str(
				result.get("error", "Could not queue idea generation.")
			)
			return
		_idea_job_id = str(result.get("job_id", ""))
		_idea_generate_button.disabled = true
		_set_single_idea_queue_status_v0211(result)
		return
	_queue_batched_ideas_v0211(total, plan)


func _queue_idea_request_v0211(request_size: int) -> Dictionary:
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var idea_seed := _idea_seed_with_source_v0213()
	if _selected_idea_detail_level_v0167 == "custom":
		if (
			_generation_service == null
			or not _generation_service.has_method(
				"queue_idea_generation_with_custom_length_v0211"
			)
		):
			return {
				"ok": false,
				"error": "The Custom Idea length service is unavailable."
			}
		return _generation_service.call(
			"queue_idea_generation_with_custom_length_v0211",
			idea_seed,
			profile,
			request_size,
			int(_generation_settings().get("retry_count", 1)),
			str(_project.get("project_id", "")),
			CCFSeriesService.generation_context_for_project(_project),
			_idea_custom_target_characters_v0211()
		) as Dictionary
	var clean_level := _idea_detail_service_v0167.normalise_level_id(
		_selected_idea_detail_level_v0167
	)
	if (
		_generation_service != null
		and _generation_service.has_method(
			"queue_idea_generation_with_detail_v0167"
		)
	):
		return _generation_service.call(
			"queue_idea_generation_with_detail_v0167",
			idea_seed,
			profile,
			request_size,
			int(_generation_settings().get("retry_count", 1)),
			str(_project.get("project_id", "")),
			CCFSeriesService.generation_context_for_project(_project),
			clean_level
		) as Dictionary
	return _generation_service.queue_idea_generation(
		idea_seed,
		profile,
		request_size,
		int(_generation_settings().get("retry_count", 1)),
		str(_project.get("project_id", "")),
		CCFSeriesService.generation_context_for_project(_project)
	)


func _set_single_idea_queue_status_v0211(result: Dictionary) -> void:
	var queued_ahead := int(result.get("queued_ahead", 0))
	if _selected_idea_detail_level_v0167 == "custom":
		var capped_note := (
			" • capped by model/profile output maximum"
			if bool(result.get("budget_limited", false))
			else ""
		)
		_idea_status.text = (
			"Queued • Custom ~%s characters/idea • request %s output tokens%s%s"
			% [
				_format_integer_v0211(_idea_custom_target_characters_v0211()),
				_format_integer_v0211(int(result.get("request_max_tokens", 0))),
				capped_note,
				(" • behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
			]
		)
		return
	_idea_status.text = (
		"Queued • %s detail%s"
		% [
			_idea_detail_service_v0167.label_for(
				_idea_detail_service_v0167.normalise_level_id(
					_selected_idea_detail_level_v0167
				)
			),
			(" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
		]
	)


func _queue_batched_ideas_v0211(total: int, plan: Array[int]) -> void:
	if (
		_generation_service == null
		or not _generation_service.has_method("decorate_idea_batch_job_v0211")
	):
		_idea_status.text = "The optional Idea request batching service is unavailable."
		return
	_idea_batch_group_id_v0211 = "idea-batch-%d-%d" % [
		Time.get_ticks_usec(), get_instance_id()
	]
	_idea_batch_requested_total_v0211 = total
	_idea_batch_expected_requests_v0211 = plan.size()
	var queued_count := 0
	for batch_index in range(plan.size()):
		var result := _queue_idea_request_v0211(plan[batch_index])
		if not bool(result.get("ok", false)):
			var pseudo_id := "%s-unqueued-%d" % [
				_idea_batch_group_id_v0211, batch_index
			]
			_idea_batch_job_indices_v0211[pseudo_id] = batch_index
			_idea_batch_terminal_jobs_v0211[pseudo_id] = "failed"
			_idea_batch_errors_v0211.append(
				"Request %d/%d could not be queued: %s"
				% [
					batch_index + 1,
					plan.size(),
					str(result.get("error", "Unknown queue error."))
				]
			)
			continue
		var job_id := str(result.get("job_id", ""))
		_idea_batch_job_indices_v0211[job_id] = batch_index
		var decorated := bool(_generation_service.call(
			"decorate_idea_batch_job_v0211",
			job_id,
			_idea_batch_group_id_v0211,
			batch_index,
			plan.size(),
			total
		))
		if not decorated:
			_idea_batch_errors_v0211.append(
				"Request %d/%d could not be marked for safe aggregation."
				% [batch_index + 1, plan.size()]
			)
			if _generation_service.has_method("cancel_job_v01531"):
				_generation_service.call("cancel_job_v01531", job_id)
			continue
		queued_count += 1
	_idea_job_id = _idea_batch_group_id_v0211
	_idea_generate_button.disabled = queued_count > 0
	if queued_count == 0:
		_maybe_finish_idea_batch_v0211()
		return
	_idea_status.text = (
		"Queued %d ideas across %d sequential provider requests • up to %d ideas/request • %s detail."
		% [
			total,
			plan.size(),
			_idea_batch_size_value_v0211(),
			_idea_detail_label_v0211()
		]
	)


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	if job_type == "idea_source_title" and job_id == _idea_source_title_job_id_v0213:
		_handle_idea_source_title_completed_v0213(data, metadata)
		return
	if job_type == "ideas" and _idea_batch_job_indices_v0211.has(job_id):
		_handle_completed_idea_batch_v0211(job_id, data, metadata)
		return
	super._on_job_completed(job_id, job_type, data, metadata)
	if (
		job_type != "ideas"
		or str(metadata.get("idea_detail_level", "")) != "custom"
	):
		return
	var counts_value: Variant = metadata.get(
		"idea_actual_character_counts", []
	)
	if not counts_value is Array or (counts_value as Array).is_empty():
		return
	var minimum_actual := 2147483647
	var maximum_actual := 0
	var total_actual := 0
	for count_value in counts_value:
		var actual := maxi(0, int(count_value))
		minimum_actual = mini(minimum_actual, actual)
		maximum_actual = maxi(maximum_actual, actual)
		total_actual += actual
	var average_actual := int(round(
		float(total_actual) / float((counts_value as Array).size())
	))
	var target := int(metadata.get("idea_custom_target_characters", 0))
	var target_met := int(metadata.get("idea_custom_target_met_count", 0))
	_idea_status.text = (
		"Generated %d idea(s) • target ~%s characters each • actual %s–%s (average %s) • %d within the guide range."
		% [
			(counts_value as Array).size(),
			_format_integer_v0211(target),
			_format_integer_v0211(minimum_actual),
			_format_integer_v0211(maximum_actual),
			_format_integer_v0211(average_actual),
			target_met
		]
	)


func _on_job_failed(job_id: String, job_type: String, message: String) -> void:
	if job_type == "idea_source_title" and job_id == _idea_source_title_job_id_v0213:
		_handle_idea_source_title_failed_v0213(message)
		return
	if job_type == "ideas" and _idea_batch_job_indices_v0211.has(job_id):
		_mark_idea_batch_terminal_v0211(job_id, "failed")
		var batch_index := int(_idea_batch_job_indices_v0211.get(job_id, 0))
		_idea_batch_errors_v0211.append(
			"Request %d/%d failed: %s"
			% [batch_index + 1, _idea_batch_expected_requests_v0211, message]
		)
		_maybe_finish_idea_batch_v0211()
		return
	super._on_job_failed(job_id, job_type, message)


func _on_job_cancelled(job_id: String, job_type: String) -> void:
	if job_type == "idea_source_title" and job_id == _idea_source_title_job_id_v0213:
		_handle_idea_source_title_failed_v0213("The name suggestion was cancelled.")
		return
	if job_type == "ideas" and _idea_batch_job_indices_v0211.has(job_id):
		_mark_idea_batch_terminal_v0211(job_id, "cancelled")
		var batch_index := int(_idea_batch_job_indices_v0211.get(job_id, 0))
		_idea_batch_errors_v0211.append(
			"Request %d/%d was cancelled."
			% [batch_index + 1, _idea_batch_expected_requests_v0211]
		)
		if not _idea_batch_cancelling_v0211:
			_cancel_remaining_idea_batches_v0211()
		_maybe_finish_idea_batch_v0211()
		return
	super._on_job_cancelled(job_id, job_type)


func _on_idea_job_completed_v01532(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	if (
		job_type in ["ideas", "idea_generation"]
		and not str(metadata.get("idea_batch_group_id", "")).is_empty()
	):
		return
	super._on_idea_job_completed_v01532(job_id, job_type, data, metadata)


func _handle_completed_idea_batch_v0211(
	job_id: String, data: Variant, metadata: Dictionary
) -> void:
	if _idea_batch_terminal_jobs_v0211.has(job_id):
		return
	var batch_index := int(_idea_batch_job_indices_v0211.get(job_id, 0))
	var origin_project_id := str(metadata.get("project_id", ""))
	var active_project_id := str(_project.get("project_id", ""))
	if (
		not origin_project_id.is_empty()
		and origin_project_id != active_project_id
	):
		_idea_batch_errors_v0211.append(
			"Request %d/%d was discarded because the active project changed."
			% [batch_index + 1, _idea_batch_expected_requests_v0211]
		)
		_mark_idea_batch_terminal_v0211(job_id, "discarded")
		_maybe_finish_idea_batch_v0211()
		return
	var ideas: Array = []
	if data is Array:
		for idea_value in data as Array:
			if idea_value is Dictionary:
				ideas.append((idea_value as Dictionary).duplicate(true))
	_idea_batch_results_v0211[batch_index] = ideas
	_idea_batch_metadata_v0211[batch_index] = metadata.duplicate(true)
	_mark_idea_batch_terminal_v0211(job_id, "completed")
	var received := _idea_batch_received_count_v0211()
	_idea_status.text = (
		"Idea request %d/%d finished • %d/%d usable ideas received so far."
		% [
			batch_index + 1,
			_idea_batch_expected_requests_v0211,
			received,
			_idea_batch_requested_total_v0211
		]
	)
	_maybe_finish_idea_batch_v0211()


func _mark_idea_batch_terminal_v0211(job_id: String, outcome: String) -> void:
	_idea_batch_terminal_jobs_v0211[job_id] = outcome


func _cancel_remaining_idea_batches_v0211() -> void:
	if _generation_service == null or not _generation_service.has_method(
		"cancel_job_v01531"
	):
		return
	_idea_batch_cancelling_v0211 = true
	var job_ids := _idea_batch_job_indices_v0211.keys().duplicate()
	for job_id_value in job_ids:
		var job_id := str(job_id_value)
		if _idea_batch_terminal_jobs_v0211.has(job_id):
			continue
		_generation_service.call("cancel_job_v01531", job_id)
	_idea_batch_cancelling_v0211 = false


func _maybe_finish_idea_batch_v0211() -> void:
	if _idea_batch_group_id_v0211.is_empty() or _idea_batch_cancelling_v0211:
		return
	if (
		_idea_batch_terminal_jobs_v0211.size()
		< _idea_batch_expected_requests_v0211
	):
		return
	var combined: Array = []
	var aggregate_metadata: Dictionary = {}
	for batch_index in range(_idea_batch_expected_requests_v0211):
		var metadata_value: Variant = _idea_batch_metadata_v0211.get(
			batch_index, {}
		)
		if aggregate_metadata.is_empty() and metadata_value is Dictionary:
			aggregate_metadata = (metadata_value as Dictionary).duplicate(true)
		var ideas_value: Variant = _idea_batch_results_v0211.get(batch_index, [])
		if not ideas_value is Array:
			continue
		for idea_value in ideas_value as Array:
			if combined.size() >= _idea_batch_requested_total_v0211:
				break
			if idea_value is Dictionary:
				combined.append((idea_value as Dictionary).duplicate(true))
	aggregate_metadata["idea_batch_contract_version"] = (
		IDEA_BATCHING_V0211.CONTRACT_VERSION
	)
	aggregate_metadata["idea_batch_group_id"] = _idea_batch_group_id_v0211
	aggregate_metadata["idea_batch_requested_total"] = (
		_idea_batch_requested_total_v0211
	)
	aggregate_metadata["idea_batch_request_count"] = (
		_idea_batch_expected_requests_v0211
	)
	aggregate_metadata["idea_batch_successful_requests"] = (
		_idea_batch_results_v0211.size()
	)
	aggregate_metadata["idea_batch_result_count"] = combined.size()
	aggregate_metadata["idea_batch_errors"] = _idea_batch_errors_v0211.duplicate()
	if str(aggregate_metadata.get("idea_detail_level", "")) == "custom":
		var counts := IDEA_CUSTOM_LENGTH_V0211.actual_counts(combined)
		var target := int(aggregate_metadata.get(
			"idea_custom_target_characters", 0
		))
		var target_met := 0
		for actual_count in counts:
			if IDEA_CUSTOM_LENGTH_V0211.count_within_target(
				actual_count, target
			):
				target_met += 1
		aggregate_metadata["idea_actual_character_counts"] = counts
		aggregate_metadata["idea_custom_target_met_count"] = target_met
	_idea_job_id = ""
	_idea_generate_button.disabled = false
	_render_ideas(combined)
	if _idea_generator_v01532 != null and not combined.is_empty():
		_idea_generator_v01532.set_last_generated_ideas_v01532(
			combined, aggregate_metadata
		)
	_set_completed_idea_batch_status_v0211(combined, aggregate_metadata)
	_reset_idea_batch_state_v0211()


func _set_completed_idea_batch_status_v0211(
	combined: Array, aggregate_metadata: Dictionary
) -> void:
	var error_note := (
		" • %d request problem%s; successful results were kept"
		% [
			_idea_batch_errors_v0211.size(),
			"" if _idea_batch_errors_v0211.size() == 1 else "s"
		]
		if not _idea_batch_errors_v0211.is_empty()
		else ""
	)
	if combined.is_empty():
		_idea_status.text = "No usable ideas completed.%s" % error_note
		return
	var custom_note := ""
	if str(aggregate_metadata.get("idea_detail_level", "")) == "custom":
		var counts_value: Variant = aggregate_metadata.get(
			"idea_actual_character_counts", []
		)
		if counts_value is Array and not (counts_value as Array).is_empty():
			var minimum_actual := 2147483647
			var maximum_actual := 0
			var total_actual := 0
			for count_value in counts_value as Array:
				var actual := maxi(0, int(count_value))
				minimum_actual = mini(minimum_actual, actual)
				maximum_actual = maxi(maximum_actual, actual)
				total_actual += actual
			var average_actual := int(round(
				float(total_actual) / float((counts_value as Array).size())
			))
			custom_note = " • actual %s–%s chars (average %s)" % [
				_format_integer_v0211(minimum_actual),
				_format_integer_v0211(maximum_actual),
				_format_integer_v0211(average_actual)
			]
	_idea_status.text = (
		"Generated %d/%d usable ideas across %d provider requests%s%s."
		% [
			combined.size(),
			_idea_batch_requested_total_v0211,
			_idea_batch_expected_requests_v0211,
			custom_note,
			error_note
		]
	)


func _idea_batch_received_count_v0211() -> int:
	var count := 0
	for ideas_value in _idea_batch_results_v0211.values():
		if ideas_value is Array:
			count += (ideas_value as Array).size()
	return mini(count, _idea_batch_requested_total_v0211)


func _reset_idea_batch_state_v0211() -> void:
	_idea_batch_group_id_v0211 = ""
	_idea_batch_requested_total_v0211 = 0
	_idea_batch_expected_requests_v0211 = 0
	_idea_batch_job_indices_v0211.clear()
	_idea_batch_terminal_jobs_v0211.clear()
	_idea_batch_results_v0211.clear()
	_idea_batch_metadata_v0211.clear()
	_idea_batch_errors_v0211.clear()
	_idea_batch_cancelling_v0211 = false


func _idea_batch_size_value_v0211() -> int:
	if _idea_batch_size_v0211 == null:
		return IDEA_BATCHING_V0211.DEFAULT_IDEAS_PER_REQUEST
	return IDEA_BATCHING_V0211.normalise_ideas_per_request(
		int(_idea_batch_size_v0211.value)
	)


func _idea_detail_label_v0211() -> String:
	if _selected_idea_detail_level_v0167 == "custom":
		return "Custom"
	return _idea_detail_service_v0167.label_for(
		_idea_detail_service_v0167.normalise_level_id(
			_selected_idea_detail_level_v0167
		)
	)


func idea_custom_length_capabilities_v0211() -> Dictionary:
	var service_capabilities := {}
	if (
		_generation_service != null
		and _generation_service.has_method(
			"idea_custom_length_capabilities_v0211"
		)
	):
		service_capabilities = _generation_service.call(
			"idea_custom_length_capabilities_v0211"
		) as Dictionary
	return {
		"custom_selector": true,
		"presets_preserved": true,
		"selected_level": _selected_idea_detail_level_v0167,
		"target_characters": _idea_custom_target_characters_v0211(),
		"custom_controls_visible": (
			_idea_custom_length_panel_v0211 != null
			and _idea_custom_length_panel_v0211.visible
		),
		"service": service_capabilities
	}


func idea_batching_capabilities_v0211() -> Dictionary:
	var total := (
		IDEA_BATCHING_V0211.normalise_total_ideas(int(_idea_count.value))
		if _idea_count != null
		else 6
	)
	var per_request := _idea_batch_size_value_v0211()
	var service_capabilities := {}
	if (
		_generation_service != null
		and _generation_service.has_method(
			"idea_batching_capabilities_v0211"
		)
	):
		service_capabilities = _generation_service.call(
			"idea_batching_capabilities_v0211"
		) as Dictionary
	return {
		"controls": true,
		"total_ideas": total,
		"ideas_per_request": per_request,
		"request_plan": IDEA_BATCHING_V0211.request_plan(total, per_request),
		"request_plan_visible": _idea_batch_plan_hint_v0211 != null,
		"service": service_capabilities
	}


func _idea_custom_target_characters_v0211() -> int:
	if _idea_custom_target_v0211 == null:
		return IDEA_CUSTOM_LENGTH_V0211.DEFAULT_TARGET_CHARACTERS
	return IDEA_CUSTOM_LENGTH_V0211.normalise_target_characters(
		int(_idea_custom_target_v0211.value)
	)


func _format_integer_v0211(value: int) -> String:
	var digits := str(maxi(0, value))
	var formatted := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			formatted += ","
		formatted += digits[index]
	return formatted


func _build_front_porch_group_v0172(group: Dictionary) -> void:
	super._build_front_porch_group_v0172(group)
	if _front_porch_group_tabs_v0172 == null:
		return
	var tab_count := _front_porch_group_tabs_v0172.get_tab_count()
	if tab_count <= 0:
		return
	var page := _front_porch_group_tabs_v0172.get_child(tab_count - 1)
	var action_rows := page.find_children("*", "HFlowContainer", true, false)
	if action_rows.is_empty() or not action_rows[0] is HFlowContainer:
		return
	var actions := action_rows[0] as HFlowContainer
	var group_id := str(group.get("id", ""))
	var select_all := Button.new()
	select_all.name = "FrontPorchSelectAll_%s_V0209" % group_id
	select_all.text = "Select All Fields"
	select_all.tooltip_text = (
		"Select every visible field in this Front Porch tab for editing or generation."
	)
	select_all.pressed.connect(
		_set_front_porch_group_selection_v0209.bind(group_id, true)
	)
	actions.add_child(select_all)
	actions.move_child(select_all, 2)
	var select_none := Button.new()
	select_none.name = "FrontPorchSelectNone_%s_V0209" % group_id
	select_none.text = "Select None"
	select_none.tooltip_text = "Clear the field selection in this Front Porch tab."
	select_none.pressed.connect(
		_set_front_porch_group_selection_v0209.bind(group_id, false)
	)
	actions.add_child(select_none)
	actions.move_child(select_none, 3)


func _create_front_porch_input_v0172(
	field: Dictionary, value: Variant
) -> Control:
	if str(field.get("id", "")) == "fp_work_hours":
		var hours := FRONT_PORCH_WORK_HOURS_CONTROL_V0209.new()
		hours.set_work_hours_value_v0209(value)
		hours.value_changed.connect(_mark_dirty)
		return hours
	return super._create_front_porch_input_v0172(field, value)


func _front_porch_input_value_v0172(
	input_value: Variant, field: Dictionary
) -> Variant:
	var raw_value: Variant
	if input_value is CCFFrontPorchWorkHoursControlV0209:
		raw_value = (
			input_value as CCFFrontPorchWorkHoursControlV0209
		).work_hours_value_v0209()
	else:
		raw_value = super._front_porch_input_value_v0172(input_value, field)
	var field_id := str(field.get("id", ""))
	if field_id not in ["fp_work_days", "fp_work_hours"]:
		return raw_value
	var normalised := (
		_front_porch_service_v0172 as CCFFrontPorchExtensionServiceCurrent
	).normalise_preview_value_v0209(field, raw_value)
	return normalised.get("value", raw_value) if bool(normalised.get("ok", false)) else raw_value


func _set_front_porch_input_enabled_v0172(
	input: Control, enabled: bool
) -> void:
	if input is CCFFrontPorchWorkHoursControlV0209:
		(input as CCFFrontPorchWorkHoursControlV0209).set_editable_v0209(enabled)
		return
	super._set_front_porch_input_enabled_v0172(input, enabled)


func _set_front_porch_control_value_v0172(
	input_value: Variant, value: Variant, field: Dictionary
) -> void:
	if input_value is CCFFrontPorchWorkHoursControlV0209:
		(
			input_value as CCFFrontPorchWorkHoursControlV0209
		).set_work_hours_value_v0209(value)
		return
	super._set_front_porch_control_value_v0172(input_value, value, field)


func _normalise_front_porch_preview_metadata_v0175(
	metadata: Dictionary
) -> Dictionary:
	var result := super._normalise_front_porch_preview_metadata_v0175(metadata)
	if int(result.get("front_porch_generation_contract", 0)) != 1:
		return result
	var preview_fields_value: Variant = result.get("preview_fields", [])
	if not preview_fields_value is Array:
		return result
	var preview_fields: Array = preview_fields_value
	for index in range(preview_fields.size()):
		var field_value: Variant = preview_fields[index]
		if not field_value is Dictionary:
			continue
		var field := (field_value as Dictionary).duplicate(true)
		if str(field.get("id", "")) == "fp_work_hours":
			field["type"] = "line"
			field["front_porch_source_type"] = "work_hours"
			preview_fields[index] = field
	result["preview_fields"] = preview_fields
	return result


func _set_front_porch_group_selection_v0209(
	group_id: String, selected: bool
) -> void:
	var changed := 0
	for field_id in _front_porch_controls_v0172:
		var row: Dictionary = _front_porch_controls_v0172[field_id]
		var field: Dictionary = row.get("field", {})
		if str(field.get("group_id", "")) != group_id:
			continue
		if bool(field.get("adult", false)) and not _front_porch_adult_unlocked_v0172:
			continue
		var include_value: Variant = row.get("include")
		var input_value: Variant = row.get("input")
		if not include_value is CheckBox:
			continue
		var include := include_value as CheckBox
		if include.button_pressed != selected:
			include.set_pressed_no_signal(selected)
			changed += 1
		if input_value is Control:
			_set_front_porch_input_enabled_v0172(input_value as Control, selected)
	_mark_dirty()
	_update_front_porch_summary_v0172()
	_status.text = "%s %d field(s) in this Front Porch tab." % [
		"Selected" if selected else "Cleared",
		changed
	]


func front_porch_current_capabilities_v0209() -> Dictionary:
	return {
		"version": "0.20.9",
		"select_all_per_tab": true,
		"typed_work_hours": true,
		"work_days_apply_normalisation": true
	}


func _idea_seed_with_source_v0213() -> String:
	var ordinary_seed := _idea_seed.text.strip_edges() if _idea_seed != null else ""
	if (
		_idea_generator_v01532 == null
		or not _idea_generator_v01532.has_method("prepared_generation_input_v0213")
	):
		return ordinary_seed
	return str(_idea_generator_v01532.call(
		"prepared_generation_input_v0213", ordinary_seed
	))


func _install_idea_prompt_presentation_v0213() -> void:
	if _idea_seed == null or _idea_seed.get_parent() == null:
		return
	var parent := _idea_seed.get_parent()
	for child in parent.get_children():
		if (
			child is Label
			and child.get_index() < _idea_seed.get_index()
			and (child as Label).text.begins_with("Give the AI")
		):
			_idea_prompt_hint_v0213 = child as Label
	_update_idea_prompt_presentation_v0213()


func _on_active_idea_source_changed_v0213(_source: Dictionary) -> void:
	_update_idea_prompt_presentation_v0213()


func _update_idea_prompt_presentation_v0213() -> void:
	if _idea_seed == null or _idea_generator_v01532 == null:
		return
	if not _idea_generator_v01532.has_method("prompt_presentation_v0213"):
		return
	var presentation: Dictionary = _idea_generator_v01532.call(
		"prompt_presentation_v0213"
	)
	if _idea_prompt_hint_v0213 != null:
		_idea_prompt_hint_v0213.text = str(presentation.get("label", ""))
	_idea_seed.placeholder_text = str(presentation.get("placeholder", ""))


func _on_idea_source_title_requested_v0213(
	source: Dictionary, source_context: String
) -> void:
	if (
		_generation_service == null
		or not _generation_service.has_method("queue_idea_source_title_v0213")
	):
		_apply_idea_source_title_fallback_v0213(str(source.get("id", "")))
		return
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var result := _generation_service.call(
		"queue_idea_source_title_v0213",
		source_context,
		profile,
		int(_generation_settings().get("retry_count", 1)),
		str(_project.get("project_id", "")),
		str(source.get("id", ""))
	) as Dictionary
	if not bool(result.get("ok", false)):
		_apply_idea_source_title_fallback_v0213(str(source.get("id", "")))
		return
	_idea_source_title_job_id_v0213 = str(result.get("job_id", ""))
	_idea_source_title_id_v0213 = str(source.get("id", ""))


func _handle_idea_source_title_completed_v0213(
	data: Variant, metadata: Dictionary
) -> void:
	var suggestion := ""
	if data is Dictionary:
		suggestion = str((data as Dictionary).get("title", "")).strip_edges()
	var source_id := str(metadata.get(
		"idea_source_id", _idea_source_title_id_v0213
	))
	if suggestion.is_empty():
		_apply_idea_source_title_fallback_v0213(source_id)
	elif _idea_generator_v01532 != null and _idea_generator_v01532.has_method(
		"apply_idea_source_title_suggestion_v0213"
	):
		_idea_generator_v01532.call(
			"apply_idea_source_title_suggestion_v0213",
			suggestion,
			source_id
		)
	_idea_source_title_job_id_v0213 = ""
	_idea_source_title_id_v0213 = ""


func _handle_idea_source_title_failed_v0213(_message: String) -> void:
	_apply_idea_source_title_fallback_v0213(_idea_source_title_id_v0213)
	_idea_source_title_job_id_v0213 = ""
	_idea_source_title_id_v0213 = ""


func _apply_idea_source_title_fallback_v0213(source_id: String) -> void:
	if _idea_generator_v01532 != null and _idea_generator_v01532.has_method(
		"apply_idea_source_title_fallback_v0213"
	):
		_idea_generator_v01532.call(
			"apply_idea_source_title_fallback_v0213", source_id
		)


func _build_similar_ideas_window_v0213() -> void:
	_similar_ideas_window_v0213 = Window.new()
	_similar_ideas_window_v0213.visible = false
	_similar_ideas_window_v0213.title = "Generate Similar Ideas"
	_similar_ideas_window_v0213.size = Vector2i(900, 760)
	_similar_ideas_window_v0213.min_size = Vector2i(720, 580)
	_similar_ideas_window_v0213.force_native = true
	_similar_ideas_window_v0213.transient = false
	_similar_ideas_window_v0213.exclusive = false
	_similar_ideas_window_v0213.close_requested.connect(
		_similar_ideas_window_v0213.hide
	)
	add_child(_similar_ideas_window_v0213)
	_similar_ideas_window_v0213.hide()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_similar_ideas_window_v0213.add_child(margin)
	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 9)
	margin.add_child(root_box)
	var heading := Label.new()
	heading.text = "Extract a reusable engine for new ideas"
	heading.add_theme_font_size_override("font_size", 21)
	root_box.add_child(heading)
	var intro := Label.new()
	intro.text = (
		"This is different from Alternative Version: it discards character-specific surface details and creates entirely new characters and scenarios from the underlying engine. The source card is never changed."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.70, 0.74, 0.84)
	root_box.add_child(intro)
	var controls := HFlowContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root_box.add_child(controls)
	var similarity_label := Label.new()
	similarity_label.text = "Similarity"
	controls.add_child(similarity_label)
	_similarity_mode_v0213 = OptionButton.new()
	_similarity_mode_v0213.custom_minimum_size.x = 190
	_add_similarity_option_v0213("Close", "close")
	_add_similarity_option_v0213("Balanced", "balanced")
	_add_similarity_option_v0213("Loose", "loose")
	_similarity_mode_v0213.select(1)
	_similarity_mode_v0213.item_selected.connect(
		func(_index: int) -> void: _refresh_similar_source_v0213()
	)
	controls.add_child(_similarity_mode_v0213)
	var similarity_hint := Label.new()
	similarity_hint.text = "Balanced preserves the main concept while changing several structural axes."
	similarity_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	similarity_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(similarity_hint)
	var title_label := Label.new()
	title_label.text = "Extracted source title (optional and editable)"
	root_box.add_child(title_label)
	_similar_source_title_v0213 = LineEdit.new()
	_similar_source_title_v0213.placeholder_text = "Leave blank to let the generator infer a concise reusable name"
	root_box.add_child(_similar_source_title_v0213)
	var preview_label := Label.new()
	preview_label.text = "Extracted reusable source preview"
	root_box.add_child(preview_label)
	_similar_source_preview_v0213 = TextEdit.new()
	_similar_source_preview_v0213.editable = false
	_similar_source_preview_v0213.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_similar_source_preview_v0213.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(_similar_source_preview_v0213)
	_similar_source_status_v0213 = Label.new()
	_similar_source_status_v0213.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_similar_source_status_v0213.modulate = Color(0.76, 0.72, 0.50)
	root_box.add_child(_similar_source_status_v0213)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root_box.add_child(actions)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_similar_ideas_window_v0213.hide)
	actions.add_child(cancel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var edit_source := Button.new()
	edit_source.text = "Edit Extracted Source"
	edit_source.pressed.connect(_edit_similar_source_v0213)
	actions.add_child(edit_source)
	var save_source := Button.new()
	save_source.text = "Save as Idea Source"
	save_source.pressed.connect(_save_similar_source_v0213)
	actions.add_child(save_source)
	var generate_now := Button.new()
	generate_now.text = "Generate Now"
	generate_now.tooltip_text = "Activate the extracted source and start generation with the current Idea Generator settings."
	generate_now.pressed.connect(_generate_similar_now_v0213)
	actions.add_child(generate_now)


func _add_similarity_option_v0213(label: String, value: String) -> void:
	_similarity_mode_v0213.add_item(label)
	_similarity_mode_v0213.set_item_metadata(
		_similarity_mode_v0213.item_count - 1, value
	)


func _add_generate_similar_ideas_action_v0213() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton or (node as MenuButton).text != "Character":
			continue
		var popup := (node as MenuButton).get_popup()
		popup.add_separator()
		popup.add_item(
			"Generate Similar Ideas…",
			GENERATE_SIMILAR_IDEAS_MENU_ID_V0213
		)
		popup.id_pressed.connect(_on_generate_similar_menu_v0213)
		return


func _on_generate_similar_menu_v0213(id: int) -> void:
	if id == GENERATE_SIMILAR_IDEAS_MENU_ID_V0213:
		_open_generate_similar_v0213()


func _open_generate_similar_v0213() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a finished character card before generating similar ideas."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_similar_source_card_v0213 = CCFStorageService.get_character(
		_project_container, _active_character_id
	).duplicate(true)
	if _similar_source_card_v0213.is_empty():
		_status.text = "The source character could not be found."
		return
	_similarity_mode_v0213.select(1)
	_similar_source_title_v0213.text = ""
	_refresh_similar_source_v0213()
	_similar_source_status_v0213.text = (
		"Review the extraction. Generate, edit or save it without altering the original card."
	)
	_similar_ideas_window_v0213.popup_centered()


func _refresh_similar_source_v0213() -> void:
	if _similar_source_card_v0213.is_empty():
		return
	var mode := _selected_similarity_mode_v0213()
	_similar_extracted_source_v0213 = SIMILAR_IDEA_SOURCE_V0213.extract_source(
		_similar_source_card_v0213, _project_container, mode
	)
	var edited_title := _similar_source_title_v0213.text.strip_edges()
	if not edited_title.is_empty():
		_similar_extracted_source_v0213["title"] = edited_title
	_similar_source_preview_v0213.text = IDEA_SOURCE_SERVICE_V0213.new().generation_context(
		_similar_extracted_source_v0213, mode
	)


func _captured_similar_source_v0213() -> Dictionary:
	var source := _similar_extracted_source_v0213.duplicate(true)
	source["title"] = _similar_source_title_v0213.text.strip_edges()
	source["similarity_mode"] = _selected_similarity_mode_v0213()
	return source


func _edit_similar_source_v0213() -> void:
	var source := _captured_similar_source_v0213()
	_similar_ideas_window_v0213.hide()
	if _idea_generator_v01532 != null and _idea_generator_v01532.has_method(
		"load_temporary_source_v0213"
	):
		_idea_generator_v01532.call(
			"load_temporary_source_v0213", source, true, false
		)
	_status.text = "Extracted reusable engine opened as a temporary, editable Idea Source."


func _save_similar_source_v0213() -> void:
	var source := _captured_similar_source_v0213()
	var service := IDEA_SOURCE_SERVICE_V0213.new()
	var result := service.save_source(source)
	if not bool(result.get("ok", false)):
		_similar_source_status_v0213.text = str(
			result.get("error", "Could not save the extracted Idea Source.")
		)
		return
	_similar_ideas_window_v0213.hide()
	if _idea_generator_v01532 != null:
		if _idea_generator_v01532.has_method("load_saved_source_v0213"):
			_idea_generator_v01532.call(
				"load_saved_source_v0213",
				str((result.get("source", {}) as Dictionary).get("id", "")),
				true
			)
		elif _idea_generator_v01532.has_method("open_source_library_v0213"):
			_idea_generator_v01532.call("open_source_library_v0213")
	_status.text = "Extracted engine saved to the Idea Source Library. The source card was not changed."


func _generate_similar_now_v0213() -> void:
	var source := _captured_similar_source_v0213()
	_similar_ideas_window_v0213.hide()
	if _idea_generator_v01532 != null and _idea_generator_v01532.has_method(
		"load_temporary_source_v0213"
	):
		_idea_generator_v01532.call(
			"load_temporary_source_v0213", source, false, true
		)
		_idea_generator_v01532.open_generator()
	_status.text = "Generating new Ideas from the extracted reusable engine. The original card remains unchanged."
	call_deferred("_generate_ideas")


func _selected_similarity_mode_v0213() -> String:
	if _similarity_mode_v0213 == null or _similarity_mode_v0213.selected < 0:
		return "balanced"
	return str(_similarity_mode_v0213.get_selected_metadata())


func idea_source_capabilities_v0213() -> Dictionary:
	var generator_capabilities := {}
	if _idea_generator_v01532 != null and _idea_generator_v01532.has_method(
		"idea_source_capabilities_v0213"
	):
		generator_capabilities = _idea_generator_v01532.call(
			"idea_source_capabilities_v0213"
		) as Dictionary
	return {
		"version": "0.21.3",
		"idea_source_pipeline": true,
		"batch_source_reuse": true,
		"custom_lengths_preserved": true,
		"generate_similar_ideas": true,
		"alternative_version_unchanged": true,
		"similarity": SIMILAR_IDEA_SOURCE_V0213.capabilities(),
		"generator": generator_capabilities
	}


func _close_tool_windows_for_project_change() -> void:
	if _similar_ideas_window_v0213 != null and _similar_ideas_window_v0213.visible:
		_similar_ideas_window_v0213.hide()
	super._close_tool_windows_for_project_change()
