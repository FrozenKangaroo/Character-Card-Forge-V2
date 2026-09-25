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
	add_child(_idea_generator_v01532)
	_idea_generator_v01532.hide()
	_idea_generator_v01412 = _idea_generator_v01532
	_concept_studio = _idea_generator_v01532


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
			_idea_seed.text,
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
			_idea_seed.text,
			profile,
			request_size,
			int(_generation_settings().get("retry_count", 1)),
			str(_project.get("project_id", "")),
			CCFSeriesService.generation_context_for_project(_project),
			clean_level
		) as Dictionary
	return _generation_service.queue_idea_generation(
		_idea_seed.text,
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
