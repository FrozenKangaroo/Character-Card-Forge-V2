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
const IDEA_DIVERSITY_V0214 = preload(
	"res://scripts/services/idea_diversity_guardrails_v0214.gd"
)
const IDEA_FINAL_REVIEW_V0218 = preload(
	"res://scripts/services/idea_final_review_service_v0218.gd"
)
const IDEA_REVIEW_PRESENTATION_V02110 = preload(
	"res://scripts/services/idea_review_presentation_service_v02110.gd"
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
const CHARACTER_COLLABORATOR_CURRENT = preload(
	"res://scripts/ui/character_collaborator_window_current.gd"
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
var _idea_prevent_repeats_v0214: CheckButton
var _idea_final_similarity_v0214: OptionButton
var _idea_review_adherence_v0218: CheckButton
var _idea_review_similarity_v0218: CheckButton
var _idea_final_top_up_v0214: CheckButton
var _idea_diversity_session_v0214: Dictionary = {}
var _idea_diversity_review_job_id_v0214 := ""
var _idea_similarity_review_window_v0214: Window
var _idea_similarity_review_text_v0214: TextEdit
var _idea_review_list_v0218: VBoxContainer
var _idea_review_checks_v0218: Array[CheckBox] = []
var _idea_review_detail_panels_v02110: Array[Control] = []
var _idea_review_detail_buttons_v02110: Array[Button] = []
var _idea_review_resume_v0218: Button
var _idea_generate_more_v0218: Button
var _idea_generate_more_dialog_v0218: Window
var _idea_generate_more_count_v0218: SpinBox
var _idea_generate_more_instruction_v0219: TextEdit
var _idea_generate_more_instruction_label_v0219: Label
var _idea_generate_more_source_row_v0219: VBoxContainer
var _idea_generate_more_source_value_v0219: Label
var _idea_generate_more_context_hint_v0219: Label
var _idea_generate_more_dialog_prepared_v0219 := false
var _idea_curation_session_v0218: Dictionary = {}
var _idea_review_awaiting_user_v0218 := false
var _idea_manual_extension_active_v0218 := false
var _idea_last_completed_metadata_v0218: Dictionary = {}
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
var _idea_preset_autofill_text_v02111 := ""
var _idea_preset_autofill_source_v02111 := ""
var _idea_preset_text_update_v02111 := false
var _stream_complete_units_v02112: Dictionary = {}


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_CURRENT.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(
		_on_collaborator_sessions_changed_v015
	)
	_character_collaborator_window.character_draft_ready.connect(
		_on_collaborator_character_draft_ready_v015
	)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()


func _ready() -> void:
	super._ready()
	_build_similar_ideas_window_v0213()
	_build_idea_similarity_review_window_v0214()
	_build_generate_more_dialog_v0218()
	_add_generate_similar_ideas_action_v0213()
	_install_idea_prompt_presentation_v0213()


func _init() -> void:
	_front_porch_service_v0172 = FRONT_PORCH_SERVICE_CURRENT.new()


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := super._create_worker_service_v01526(
		worker_id, worker_label, job_number_base
	)
	service.job_stream_started.connect(_on_job_stream_started_v02112)
	service.job_stream_item.connect(_on_job_stream_item_v02112)
	service.job_stream_finished.connect(_on_job_stream_finished_v02112)
	service.job_stream_reset.connect(_on_job_stream_reset_v02112)
	service.job_phase_changed.connect(_on_job_phase_changed_v02112)
	return service


func _on_job_stream_started_v02112(
	job_id: String, job_type: String, metadata: Dictionary
) -> void:
	_stream_complete_units_v02112[job_id] = 0
	if (
		job_type == "ideas"
		and _idea_batch_job_indices_v0211.has(job_id)
		and _idea_generator_v01532 != null
	):
		_idea_generator_v01532.call("begin_provisional_ideas_v02112", job_id, metadata)
	_status.text = "● Streaming… waiting for provider output."


func _on_job_stream_item_v02112(
	job_id: String, job_type: String, provisional_item: Variant, metadata: Dictionary
) -> void:
	var count := int(_stream_complete_units_v02112.get(job_id, 0)) + 1
	_stream_complete_units_v02112[job_id] = count
	if (
		job_type == "ideas"
		and _idea_batch_job_indices_v0211.has(job_id)
		and provisional_item is Dictionary
		and str(metadata.get("unit_kind", "")) == "array_item"
		and _idea_generator_v01532 != null
	):
		_idea_generator_v01532.call(
			"append_provisional_idea_v02112", job_id, provisional_item
		)
		return
	_status.text = "● Generating… %d complete structured unit%s received provisionally." % [
		count, "" if count == 1 else "s"
	]


func _on_job_stream_finished_v02112(
	job_id: String, job_type: String, _metadata: Dictionary
) -> void:
	if (
		job_type == "ideas"
		and _idea_batch_job_indices_v0211.has(job_id)
		and _idea_generator_v01532 != null
	):
		_idea_generator_v01532.call("set_provisional_ideas_checking_v02112", job_id)
	_status.text = "◌ Checking… parsing and validating the completed AI response."


func _on_job_stream_reset_v02112(
	job_id: String, job_type: String, metadata: Dictionary
) -> void:
	_stream_complete_units_v02112.erase(job_id)
	if job_type == "ideas" and _idea_generator_v01532 != null:
		_idea_generator_v01532.call(
			"discard_provisional_attempt_v02112",
			job_id,
			str(metadata.get("reason", "stream reset")),
			metadata
		)


func _on_job_phase_changed_v02112(
	job_id: String, job_type: String, phase: String, metadata: Dictionary
) -> void:
	if job_type == "ideas" and _idea_generator_v01532 != null:
		_idea_generator_v01532.call(
			"set_provisional_phase_v02112", job_id, phase, metadata
		)
	match phase:
		"connecting":
			_status.text = "● Connecting to AI provider…"
		"thinking":
			_status.text = "● Thinking… private reasoning is not shown or retained."
		"generating_final":
			_status.text = "● Generating final response…"
		"retrying":
			_status.text = "Stream interrupted — retrying with provisional output discarded."
		"json_repair":
			_status.text = "Generated response needs JSON repair — requesting corrected output."
		"transport_fallback":
			_status.text = "Streaming unavailable — continuing with a completed response."
		"checking":
			_status.text = "◌ Checking/parsing the completed AI response…"
	if phase == "ready":
		_stream_complete_units_v02112.erase(job_id)
	elif phase in ["failed", "cancelled"]:
		_stream_complete_units_v02112.erase(job_id)
		if job_type == "ideas" and _idea_generator_v01532 != null:
			_idea_generator_v01532.call(
				"discard_provisional_attempt_v02112", job_id, phase, metadata
			)


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
	if _idea_generator_v01532.has_signal("direction_preset_selected_v02111"):
		_idea_generator_v01532.connect(
			"direction_preset_selected_v02111",
			Callable(self, "_on_direction_preset_selected_v02111")
		)
	if _idea_generator_v01532.has_signal("original_prompt_requested_v02114"):
		_idea_generator_v01532.connect(
			"original_prompt_requested_v02114",
			Callable(self, "_on_original_idea_prompt_requested_v02114")
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
		"Accepted-idea target. CCF can combine several sequential generation batches up to a maximum of %d ideas."
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
	label.text = "Ideas per generation batch"
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
		"Use 1 for one idea per generation batch on smaller models. Higher values usually reduce the number of generation batches."
	)
	row.add_child(_idea_batch_size_v0211)
	var diversity_row := HFlowContainer.new()
	diversity_row.name = "IdeaDiversityControlsV0214"
	diversity_row.add_theme_constant_override("separation", 10)
	panel.add_child(diversity_row)
	_idea_prevent_repeats_v0214 = CheckButton.new()
	_idea_prevent_repeats_v0214.name = "PreventRepeatsAcrossBatchesV0214"
	_idea_prevent_repeats_v0214.text = "Prevent repeats across batches"
	_idea_prevent_repeats_v0214.button_pressed = true
	_idea_prevent_repeats_v0214.tooltip_text = (
		"Later batches receive compact summaries of ideas already generated so the model can explore different concepts."
	)
	diversity_row.add_child(_idea_prevent_repeats_v0214)
	var review_label := Label.new()
	review_label.text = "Final AI Idea Review"
	diversity_row.add_child(review_label)
	_idea_review_adherence_v0218 = CheckButton.new()
	_idea_review_adherence_v0218.name = "FinalIdeaReviewAdherenceV0218"
	_idea_review_adherence_v0218.text = "Check request adherence"
	_idea_review_adherence_v0218.button_pressed = false
	_idea_review_adherence_v0218.tooltip_text = (
		"Uses the optional final review request to flag Ideas that may miss frozen prompt, Idea Source or Series requirements. Findings are advisory."
	)
	diversity_row.add_child(_idea_review_adherence_v0218)
	_idea_review_similarity_v0218 = CheckButton.new()
	_idea_review_similarity_v0218.name = "FinalIdeaReviewSimilarityV0218"
	_idea_review_similarity_v0218.text = "Check similarity / duplicates"
	_idea_review_similarity_v0218.button_pressed = false
	_idea_review_similarity_v0218.tooltip_text = (
		"Uses the same optional final review request to flag scenario-level duplicates and near-duplicates. Findings never remove Ideas automatically."
	)
	diversity_row.add_child(_idea_review_similarity_v0218)
	# Retain the old control as a hidden compatibility bridge for narrow historical
	# callers. The live UI uses the two advisory checkboxes above.
	_idea_final_similarity_v0214 = OptionButton.new()
	_idea_final_similarity_v0214.name = "FinalAISimilarityCheckV0214"
	_idea_final_similarity_v0214.add_item("Off")
	_idea_final_similarity_v0214.set_item_metadata(0, IDEA_DIVERSITY_V0214.FINAL_REVIEW_OFF)
	_idea_final_similarity_v0214.add_item("Flag Similar Ideas")
	_idea_final_similarity_v0214.set_item_metadata(1, IDEA_DIVERSITY_V0214.FINAL_REVIEW_FLAG)
	_idea_final_similarity_v0214.add_item("Reject Clear Duplicates")
	_idea_final_similarity_v0214.set_item_metadata(2, IDEA_DIVERSITY_V0214.FINAL_REVIEW_REJECT)
	_idea_final_similarity_v0214.select(0)
	_idea_final_similarity_v0214.hide()
	diversity_row.add_child(_idea_final_similarity_v0214)
	_idea_final_top_up_v0214 = CheckButton.new()
	_idea_final_top_up_v0214.name = "FinalIdeaTopUpV0214"
	_idea_final_top_up_v0214.text = "One final top-up request if short"
	_idea_final_top_up_v0214.button_pressed = false
	_idea_final_top_up_v0214.tooltip_text = (
		"If rejected ideas leave the result below the requested count, make one final request for the missing number, up to the provider-request limit. This occurs at most once."
	)
	diversity_row.add_child(_idea_final_top_up_v0214)
	_idea_review_resume_v0218 = Button.new()
	_idea_review_resume_v0218.name = "ResumeFinalIdeaReviewV0218"
	_idea_review_resume_v0218.text = "Open Final Idea Review…"
	_idea_review_resume_v0218.tooltip_text = "Generation is waiting for your checked Keep selection."
	_idea_review_resume_v0218.hide()
	_idea_review_resume_v0218.pressed.connect(_reopen_final_idea_review_v0218)
	diversity_row.add_child(_idea_review_resume_v0218)
	_idea_generate_more_v0218 = Button.new()
	_idea_generate_more_v0218.name = "GenerateMoreIdeasV0218"
	_idea_generate_more_v0218.text = "Generate More Ideas…"
	_idea_generate_more_v0218.tooltip_text = (
		"Append more Ideas using the completed batch's frozen creative context and its retained/rejected anti-repeat memory."
	)
	_idea_generate_more_v0218.disabled = true
	_idea_generate_more_v0218.pressed.connect(_open_generate_more_dialog_v0218)
	diversity_row.add_child(_idea_generate_more_v0218)
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
		"generation batch"
		if plan.size() == 1
		else "sequential generation batches"
	)
	var small_model_note := (
		" • one idea at a time for smaller models"
		if per_request == 1 and plan.size() > 1
		else ""
	)
	_idea_batch_plan_hint_v0211.text = (
		"Plan: target %d accepted ideas across up to %d %s%s. Each next request is recalculated from accepted results."
		% [total, plan.size(), request_phrase, small_model_note]
	)


func _build_idea_similarity_review_window_v0214() -> void:
	_idea_similarity_review_window_v0214 = Window.new()
	_idea_similarity_review_window_v0214.title = "Final Idea Review"
	_idea_similarity_review_window_v0214.size = Vector2i(980, 760)
	_idea_similarity_review_window_v0214.min_size = Vector2i(720, 520)
	_idea_similarity_review_window_v0214.visible = false
	_idea_similarity_review_window_v0214.force_native = true
	_idea_similarity_review_window_v0214.exclusive = false
	_idea_similarity_review_window_v0214.transient = false
	add_child(_idea_similarity_review_window_v0214)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_idea_similarity_review_window_v0214.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "Final Idea Review"
	heading.add_theme_font_size_override("font_size", 22)
	root.add_child(heading)
	var explanation := Label.new()
	explanation.text = (
		"AI findings are advisory. Every valid Idea starts checked. Checked Ideas will be kept; uncheck only the Ideas you want to reject from this generated batch. Automatic recovery is considered only after you apply this review."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(explanation)
	var scroll := ScrollContainer.new()
	scroll.name = "FinalIdeaReviewScrollV0218"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_idea_review_list_v0218 = VBoxContainer.new()
	_idea_review_list_v0218.name = "FinalIdeaReviewListV0218"
	_idea_review_list_v0218.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_idea_review_list_v0218.add_theme_constant_override("separation", 8)
	scroll.add_child(_idea_review_list_v0218)
	# Historical test/discovery alias. The interactive checklist is authoritative.
	_idea_similarity_review_text_v0214 = TextEdit.new()
	_idea_similarity_review_text_v0214.name = "IdeaSimilarityReviewReportV0214"
	_idea_similarity_review_text_v0214.editable = false
	_idea_similarity_review_text_v0214.hide()
	root.add_child(_idea_similarity_review_text_v0214)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var keep_all := Button.new()
	keep_all.text = "Keep All"
	keep_all.pressed.connect(_set_final_review_checks_v0218.bind(true))
	actions.add_child(keep_all)
	var select_none := Button.new()
	select_none.text = "Select None"
	select_none.pressed.connect(_set_final_review_checks_v0218.bind(false))
	actions.add_child(select_none)
	var expand_all := Button.new()
	expand_all.name = "ExpandAllFinalIdeasV02110"
	expand_all.text = "Expand All"
	expand_all.pressed.connect(_set_final_review_details_expanded_v02110.bind(true))
	actions.add_child(expand_all)
	var collapse_all := Button.new()
	collapse_all.name = "CollapseAllFinalIdeasV02110"
	collapse_all.text = "Collapse All"
	collapse_all.pressed.connect(_set_final_review_details_expanded_v02110.bind(false))
	actions.add_child(collapse_all)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var apply := Button.new()
	apply.name = "ApplyFinalIdeaReviewV0218"
	apply.text = "Apply Review & Continue"
	apply.tooltip_text = "Keep the checked Ideas, remember unchecked Ideas for repeat prevention, then continue to optional one-shot recovery."
	apply.pressed.connect(_apply_final_idea_review_v0218)
	actions.add_child(apply)
	_idea_similarity_review_window_v0214.close_requested.connect(
		_hide_pending_final_idea_review_v0218
	)


func _build_generate_more_dialog_v0218() -> void:
	_idea_generate_more_dialog_v0218 = Window.new()
	_idea_generate_more_dialog_v0218.title = "Generate More Ideas"
	_idea_generate_more_dialog_v0218.size = Vector2i(720, 520)
	_idea_generate_more_dialog_v0218.min_size = Vector2i(480, 320)
	_idea_generate_more_dialog_v0218.visible = false
	_idea_generate_more_dialog_v0218.force_native = true
	_idea_generate_more_dialog_v0218.transient = true
	_idea_generate_more_dialog_v0218.exclusive = false
	_idea_generate_more_dialog_v0218.close_requested.connect(
		_dismiss_generate_more_dialog_v02110
	)
	if _idea_generator_v01532 != null:
		_idea_generator_v01532.add_child(_idea_generate_more_dialog_v0218)
	else:
		add_child(_idea_generate_more_dialog_v0218)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	_idea_generate_more_dialog_v0218.add_child(margin)
	var root := VBoxContainer.new()
	root.name = "GenerateMoreLayoutV02110"
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var body_scroll := ScrollContainer.new()
	body_scroll.name = "GenerateMoreBodyScrollV02110"
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body_scroll)
	var content := VBoxContainer.new()
	content.name = "GenerateMoreContentV0219"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	body_scroll.add_child(content)
	var count_label := Label.new()
	count_label.text = "Number of additional Ideas"
	content.add_child(count_label)
	_idea_generate_more_count_v0218 = SpinBox.new()
	_idea_generate_more_count_v0218.name = "GenerateMoreIdeaCountV0218"
	_idea_generate_more_count_v0218.min_value = 1
	_idea_generate_more_count_v0218.max_value = IDEA_BATCHING_V0211.MAX_TOTAL_IDEAS
	_idea_generate_more_count_v0218.step = 1
	_idea_generate_more_count_v0218.value = 4
	_idea_generate_more_count_v0218.custom_minimum_size = Vector2(220, 38)
	content.add_child(_idea_generate_more_count_v0218)
	_idea_generate_more_source_row_v0219 = VBoxContainer.new()
	_idea_generate_more_source_row_v0219.name = "GenerateMoreIdeaSourceV0219"
	var source_label := Label.new()
	source_label.text = "Idea Source"
	_idea_generate_more_source_row_v0219.add_child(source_label)
	_idea_generate_more_source_value_v0219 = Label.new()
	_idea_generate_more_source_value_v0219.name = "GenerateMoreIdeaSourceValueV0219"
	_idea_generate_more_source_value_v0219.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_idea_generate_more_source_value_v0219.add_theme_font_size_override("font_size", 18)
	_idea_generate_more_source_row_v0219.add_child(_idea_generate_more_source_value_v0219)
	content.add_child(_idea_generate_more_source_row_v0219)
	_idea_generate_more_instruction_label_v0219 = Label.new()
	_idea_generate_more_instruction_label_v0219.name = "GenerateMoreInstructionLabelV0219"
	content.add_child(_idea_generate_more_instruction_label_v0219)
	_idea_generate_more_instruction_v0219 = TextEdit.new()
	_idea_generate_more_instruction_v0219.name = "GenerateMoreInstructionV0219"
	_idea_generate_more_instruction_v0219.custom_minimum_size = Vector2(0, 150)
	_idea_generate_more_instruction_v0219.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_idea_generate_more_instruction_v0219.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	content.add_child(_idea_generate_more_instruction_v0219)
	_idea_generate_more_context_hint_v0219 = Label.new()
	_idea_generate_more_context_hint_v0219.name = "GenerateMoreContextHintV0219"
	_idea_generate_more_context_hint_v0219.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_idea_generate_more_context_hint_v0219)
	var footer := HBoxContainer.new()
	footer.name = "GenerateMoreActionFooterV02110"
	footer.add_theme_constant_override("separation", 8)
	root.add_child(footer)
	var cancel := Button.new()
	cancel.name = "CancelGenerateMoreV02110"
	cancel.text = "Cancel"
	cancel.pressed.connect(_dismiss_generate_more_dialog_v02110)
	footer.add_child(cancel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var generate := Button.new()
	generate.name = "ConfirmGenerateMoreV02110"
	generate.text = "Generate & Append"
	generate.pressed.connect(_confirm_generate_more_dialog_v02110)
	footer.add_child(generate)


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
	_clear_idea_curation_session_v0218()
	_reset_idea_batch_state_v0211()
	var total := IDEA_BATCHING_V0211.normalise_total_ideas(
		int(_idea_count.value)
	)
	var per_request := _idea_batch_size_value_v0211()
	var plan := IDEA_BATCHING_V0211.request_plan(total, per_request)
	_queue_batched_ideas_v0211(total, plan)


func _queue_idea_request_v0211(request_size: int) -> Dictionary:
	var default_profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var profile_value: Variant = _idea_diversity_session_v0214.get(
		"profile_snapshot", default_profile
	)
	var profile: Dictionary = (
		(profile_value as Dictionary).duplicate(true)
		if profile_value is Dictionary
		else default_profile
	)
	var idea_seed := ""
	if _idea_diversity_session_v0214.has("seed_snapshot"):
		idea_seed = str(_idea_diversity_session_v0214.get("seed_snapshot", ""))
	else:
		idea_seed = _idea_seed_with_source_v0213()
	var series_context := ""
	if _idea_diversity_session_v0214.has("series_context_snapshot"):
		series_context = str(_idea_diversity_session_v0214.get(
			"series_context_snapshot", ""
		))
	else:
		series_context = CCFSeriesService.generation_context_for_project(_project)
	var detail_level := str(_idea_diversity_session_v0214.get(
		"detail_level_snapshot", _selected_idea_detail_level_v0167
	))
	var retry_count := int(_idea_diversity_session_v0214.get(
		"retry_count_snapshot", int(_generation_settings().get("retry_count", 1))
	))
	var project_id := str(_idea_diversity_session_v0214.get(
		"project_id_snapshot", str(_project.get("project_id", ""))
	))
	if detail_level == "custom":
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
			retry_count,
			project_id,
			series_context,
			int(_idea_diversity_session_v0214.get(
				"custom_target_snapshot", _idea_custom_target_characters_v0211()
			))
		) as Dictionary
	var clean_level := _idea_detail_service_v0167.normalise_level_id(
		detail_level
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
			retry_count,
			project_id,
			series_context,
			clean_level
		) as Dictionary
	return _generation_service.queue_idea_generation(
		idea_seed,
		profile,
		request_size,
		retry_count,
		project_id,
		series_context
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
	var generation_context := _idea_generation_context_snapshot_v0217()
	_idea_diversity_session_v0214 = IDEA_DIVERSITY_V0214.create_session(
		total,
		_idea_batch_size_value_v0211(),
		_idea_prevent_repeats_v0214 == null
		or _idea_prevent_repeats_v0214.button_pressed,
		_idea_final_review_mode_v0214(),
		_idea_final_top_up_v0214 != null
		and _idea_final_top_up_v0214.button_pressed,
		generation_context
	)
	_idea_diversity_session_v0214["final_review_check_adherence"] = (
		_idea_review_adherence_v0218 != null
		and _idea_review_adherence_v0218.button_pressed
	)
	_idea_diversity_session_v0214["final_review_check_similarity"] = (
		(_idea_review_similarity_v0218 != null
		and _idea_review_similarity_v0218.button_pressed)
		or _idea_final_review_mode_v0214() != IDEA_DIVERSITY_V0214.FINAL_REVIEW_OFF
	)
	_idea_diversity_session_v0214["fast_path_v02112"] = (
		_idea_fast_path_enabled_v02112(_idea_diversity_session_v0214)
	)
	_idea_diversity_session_v0214["seed_snapshot"] = _idea_seed_with_source_v0213()
	_idea_diversity_session_v0214["idea_source_id_snapshot"] = str(
		generation_context.get("idea_source_id", "")
	)
	_idea_diversity_session_v0214["idea_source_title_snapshot"] = str(
		generation_context.get("idea_source_title", "")
	)
	_idea_diversity_session_v0214["series_context_snapshot"] = str(
		generation_context.get("series_context", "")
	)
	_idea_diversity_session_v0214["profile_snapshot"] = (
		CCFSettingsService.profile_for_role(
			_settings, CCFSettingsService.ROLE_TEXT
		).duplicate(true)
	)
	_idea_diversity_session_v0214["retry_count_snapshot"] = int(
		_generation_settings().get("retry_count", 1)
	)
	_idea_diversity_session_v0214["project_id_snapshot"] = str(
		_project.get("project_id", "")
	)
	_idea_diversity_session_v0214["detail_level_snapshot"] = (
		_selected_idea_detail_level_v0167
	)
	_idea_diversity_session_v0214["custom_target_snapshot"] = (
		_idea_custom_target_characters_v0211()
	)
	_idea_job_id = _idea_batch_group_id_v0211
	_idea_generate_button.disabled = true
	_idea_status.text = (
		"Starting generation session • target %d accepted ideas • up to %d adaptive generation batches • %s detail."
		% [
			total,
			plan.size(),
			_idea_detail_label_v0211()
		]
	)
	_queue_next_normal_idea_batch_v0214()


func _queue_next_normal_idea_batch_v0214() -> void:
	if _idea_diversity_session_v0214.is_empty():
		return
	var request_size := IDEA_DIVERSITY_V0214.next_normal_request_size(
		_idea_diversity_session_v0214
	)
	if request_size <= 0:
		_finish_normal_idea_batches_v0214()
		return
	var batch_index := int(
		_idea_diversity_session_v0214.get("normal_requests_started", 0)
	)
	IDEA_DIVERSITY_V0214.mark_request_started(
		_idea_diversity_session_v0214, request_size, "normal"
	)
	var result := _queue_idea_request_v0211(request_size)
	if not bool(result.get("ok", false)):
		_idea_batch_errors_v0211.append(
			"Request %d/%d could not be queued: %s"
			% [
				batch_index + 1,
				_idea_batch_expected_requests_v0211,
				str(result.get("error", "Unknown queue error."))
			]
		)
		call_deferred("_queue_next_normal_idea_batch_v0214")
		return
	var job_id := str(result.get("job_id", ""))
	_idea_batch_job_indices_v0211[job_id] = batch_index
	_idea_batch_metadata_v0211[batch_index] = {
		"idea_batch_request_kind": "normal"
	}
	var anti_repeat := IDEA_DIVERSITY_V0214.anti_repeat_prompt(
		_idea_diversity_session_v0214
	)
	var decorated := bool(_generation_service.call(
		"decorate_idea_batch_job_v0211",
		job_id,
		_idea_batch_group_id_v0211,
		batch_index,
		_idea_batch_expected_requests_v0211,
		_idea_batch_requested_total_v0211,
			anti_repeat,
			"normal"
		))
	if not decorated:
		_idea_batch_errors_v0211.append(
			"Request %d/%d could not be marked for safe aggregation."
			% [batch_index + 1, _idea_batch_expected_requests_v0211]
		)
		if _generation_service.has_method("cancel_job_v01531"):
			_generation_service.call("cancel_job_v01531", job_id)
		return
	if bool(_idea_diversity_session_v0214.get("fast_path_v02112", false)):
		if _generation_service.has_method("set_idea_job_fast_path_v02112"):
			var fast_marked := bool(_generation_service.call(
				"set_idea_job_fast_path_v02112", job_id, true
			))
			if not fast_marked:
				_idea_diversity_session_v0214["fast_path_v02112"] = false
		else:
			_idea_diversity_session_v0214["fast_path_v02112"] = false
	_idea_status.text = (
		"Generating batch %d/%d… %d/%d unique ideas accepted • requesting %d."
		% [
			batch_index + 1,
			_idea_batch_expected_requests_v0211,
			IDEA_DIVERSITY_V0214.accepted_count(_idea_diversity_session_v0214),
			_idea_batch_requested_total_v0211,
			request_size
		]
	)


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	if job_type == "idea_source_title" and job_id == _idea_source_title_job_id_v0213:
		_handle_idea_source_title_completed_v0213(data, metadata)
		return
	if (
		job_type == "idea_similarity_review"
		and job_id == _idea_diversity_review_job_id_v0214
	):
		if not _idea_session_project_is_current_v0214():
			_discard_idea_session_for_project_change_v0214()
			return
		_handle_idea_similarity_review_completed_v0214(data)
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
	if (
		job_type == "idea_similarity_review"
		and job_id == _idea_diversity_review_job_id_v0214
	):
		if not _idea_session_project_is_current_v0214():
			_discard_idea_session_for_project_change_v0214()
			return
		_idea_batch_errors_v0211.append(
			"Final AI Idea Review failed: %s" % message
		)
		_idea_diversity_review_job_id_v0214 = ""
		_idea_diversity_session_v0214["final_review_completed"] = true
		_maybe_queue_final_top_up_v0214()
		return
	if job_type == "ideas" and _idea_batch_job_indices_v0211.has(job_id):
		_mark_idea_batch_terminal_v0211(job_id, "failed")
		var batch_index := int(_idea_batch_job_indices_v0211.get(job_id, 0))
		var request_kind := "normal"
		if _idea_batch_metadata_v0211.get(batch_index, {}) is Dictionary:
			request_kind = str(
				(_idea_batch_metadata_v0211.get(batch_index, {}) as Dictionary).get(
					"idea_batch_request_kind", "normal"
				)
			)
		_idea_batch_errors_v0211.append(
			"%s request %d failed: %s"
			% ["Recovery" if request_kind == "top_up" else "Generation", batch_index + 1, message]
		)
		if request_kind == "top_up":
			_idea_diversity_session_v0214["final_top_up_completed"] = true
			_finalize_idea_generation_session_v0214()
		else:
			_queue_next_normal_idea_batch_v0214()
		return
	super._on_job_failed(job_id, job_type, message)


func _on_job_cancelled(job_id: String, job_type: String) -> void:
	if job_type == "idea_source_title" and job_id == _idea_source_title_job_id_v0213:
		_handle_idea_source_title_failed_v0213("The name suggestion was cancelled.")
		return
	if (
		job_type == "idea_similarity_review"
		and job_id == _idea_diversity_review_job_id_v0214
	):
		if not _idea_session_project_is_current_v0214():
			_discard_idea_session_for_project_change_v0214()
			return
		_idea_batch_errors_v0211.append("Final AI Idea Review was cancelled.")
		_idea_diversity_review_job_id_v0214 = ""
		_idea_review_awaiting_user_v0218 = false
		if _idea_manual_extension_active_v0218:
			_restore_completed_curation_after_extension_v0219(
				"Generate More was cancelled. The completed working batch and its previous instruction were preserved."
			)
		else:
			_idea_diversity_session_v0214["final_review_completed"] = true
			_finalize_idea_generation_session_v0214()
		return
	if job_type == "ideas" and _idea_batch_job_indices_v0211.has(job_id):
		_mark_idea_batch_terminal_v0211(job_id, "cancelled")
		var batch_index := int(_idea_batch_job_indices_v0211.get(job_id, 0))
		_idea_batch_errors_v0211.append(
			"Request %d/%d was cancelled."
			% [batch_index + 1, _idea_batch_expected_requests_v0211]
		)
		if _idea_manual_extension_active_v0218:
			_restore_completed_curation_after_extension_v0219(
				"Generate More was cancelled. The completed working batch and its previous instruction were preserved."
			)
		else:
			_finalize_idea_generation_session_v0214()
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
		_finalize_idea_generation_session_v0214()
		return
	var ideas: Array = []
	if data is Array:
		for idea_value in data as Array:
			if idea_value is Dictionary:
				ideas.append((idea_value as Dictionary).duplicate(true))
	var request_kind := str(metadata.get("idea_batch_request_kind", "normal"))
	var rejected_value: Variant = metadata.get(
		"idea_diversity_validation_rejections", []
	)
	var validation_rejections: Array = (
		rejected_value if rejected_value is Array else []
	)
	var validation_count_hint := int(metadata.get(
		"idea_diversity_validation_candidate_count",
		metadata.get(
			"idea_diversity_raw_candidate_count",
			ideas.size() + validation_rejections.size()
		)
	))
	var telemetry := {
		"initial_generated_candidate_count": int(metadata.get(
			"idea_diversity_initial_generated_candidate_count",
			validation_count_hint
		)),
		"semantic_repair_pass_count": int(metadata.get(
			"idea_diversity_semantic_repair_pass_count", 0
		)),
		"semantic_repair_candidate_count": int(metadata.get(
			"idea_diversity_semantic_repair_candidate_count", 0
		)),
		"validation_candidate_count": validation_count_hint
	}
	var reviewed := IDEA_DIVERSITY_V0214.record_batch(
		_idea_diversity_session_v0214,
		ideas,
		validation_rejections,
		request_kind,
		validation_count_hint,
		telemetry
	)
	var accepted_ideas: Array = []
	for record_value in reviewed.get("accepted", []):
		if record_value is Dictionary:
			var idea_value: Variant = (record_value as Dictionary).get("idea", {})
			if idea_value is Dictionary:
				accepted_ideas.append((idea_value as Dictionary).duplicate(true))
	_idea_batch_results_v0211[batch_index] = accepted_ideas
	_idea_batch_metadata_v0211[batch_index] = metadata.duplicate(true)
	_mark_idea_batch_terminal_v0211(job_id, "completed")
	if _idea_generator_v01532 != null:
		_idea_generator_v01532.call(
			"retain_completed_provisional_batch_v02112",
			job_id,
			accepted_ideas,
			metadata
		)
	if bool(_idea_diversity_session_v0214.get("fast_path_v02112", false)):
		_idea_status.text = (
			"Batch %d/%d accepted immediately • %d/%d Ideas ready so far."
			% [
				batch_index + 1,
				_idea_batch_expected_requests_v0211,
				int(reviewed.get("accepted_count", 0)),
				_idea_batch_requested_total_v0211
			]
		)
	else:
		_idea_status.text = (
			"Batch %d/%d checked • %d/%d unique Ideas accepted • %d rejected candidates • %d similarity warnings."
			% [
				batch_index + 1,
				_idea_batch_expected_requests_v0211,
				int(reviewed.get("accepted_count", 0)),
				_idea_batch_requested_total_v0211,
				int(reviewed.get("rejected_count", 0)),
				(_idea_diversity_session_v0214.get("title_warnings", []) as Array).size()
			]
		)
	if request_kind == "top_up":
		_finalize_idea_generation_session_v0214()
	else:
		_queue_next_normal_idea_batch_v0214()


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
	# Compatibility entry point retained for historical callers. v0.21.4 queues
	# one request at a time, so completion is driven by the session phase methods.
	if not _idea_diversity_session_v0214.is_empty():
		_finish_normal_idea_batches_v0214()


func _finish_normal_idea_batches_v0214() -> void:
	if _idea_diversity_session_v0214.is_empty():
		return
	if not _idea_session_project_is_current_v0214():
		_discard_idea_session_for_project_change_v0214()
		return
	if (
		IDEA_FINAL_REVIEW_V0218.review_requested(_idea_diversity_session_v0214)
		and IDEA_DIVERSITY_V0214.accepted_count(_idea_diversity_session_v0214) >= 1
		and not bool(_idea_diversity_session_v0214.get("final_review_started", false))
	):
		_queue_final_idea_similarity_review_v0214()
		return
	_maybe_queue_final_top_up_v0214()


func _queue_final_idea_similarity_review_v0214() -> void:
	_idea_diversity_session_v0214["final_review_started"] = true
	if (
		_generation_service == null
		or not _generation_service.has_method("queue_idea_similarity_review_v0214")
	):
		_idea_batch_errors_v0211.append(
			"Final AI Idea Review is unavailable in this generation service."
		)
		_idea_diversity_session_v0214["final_review_completed"] = true
		_maybe_queue_final_top_up_v0214()
		return
	var profile_value: Variant = _idea_diversity_session_v0214.get(
		"profile_snapshot",
		CCFSettingsService.profile_for_role(
			_settings, CCFSettingsService.ROLE_TEXT
		)
	)
	var profile: Dictionary = (
		(profile_value as Dictionary).duplicate(true)
		if profile_value is Dictionary
		else {}
	)
	var result := _generation_service.call(
		"queue_idea_similarity_review_v0214",
		_idea_diversity_session_v0214,
		profile,
		int(_idea_diversity_session_v0214.get(
			"retry_count_snapshot", int(_generation_settings().get("retry_count", 1))
		)),
		str(_idea_diversity_session_v0214.get("project_id_snapshot", ""))
	) as Dictionary
	if not bool(result.get("ok", false)):
		_idea_batch_errors_v0211.append(
			"Final AI Idea Review could not be queued: %s"
			% str(result.get("error", "Unknown queue error."))
		)
		_idea_diversity_session_v0214["final_review_completed"] = true
		_maybe_queue_final_top_up_v0214()
		return
	_idea_diversity_review_job_id_v0214 = str(result.get("job_id", ""))
	_idea_status.text = "Running final Idea review…"


func _handle_idea_similarity_review_completed_v0214(data: Variant) -> void:
	var review := IDEA_FINAL_REVIEW_V0218.normalise_review(
		data, _idea_diversity_session_v0214
	)
	IDEA_FINAL_REVIEW_V0218.apply_advisory_review(
		_idea_diversity_session_v0214, review
	)
	_idea_diversity_review_job_id_v0214 = ""
	_idea_review_awaiting_user_v0218 = true
	if _idea_review_resume_v0218 != null:
		_idea_review_resume_v0218.show()
	_idea_status.text = "Waiting for final Idea review… checked Ideas will be kept."
	_show_idea_similarity_review_v0214(
		review.get("similarity_clusters", []) as Array[Dictionary]
	)


func _show_idea_similarity_review_v0214(clusters: Array[Dictionary]) -> void:
	if (
		_idea_similarity_review_window_v0214 == null
		or _idea_review_list_v0218 == null
	):
		return
	_clear_children(_idea_review_list_v0218)
	_idea_review_checks_v0218.clear()
	_idea_review_detail_panels_v02110.clear()
	_idea_review_detail_buttons_v02110.clear()
	var report_lines: Array[String] = [
		"Final Idea Review — advisory only",
		(
			"Only Ideas from this Generate More request are shown. Earlier Ideas remain retained automatically; similarity findings may reference them."
			if bool(_idea_diversity_session_v0214.get("manual_extension", false))
			else "All valid Ideas begin checked. User selection determines retention."
		)
	]
	for cluster in clusters:
		report_lines.append("%s — %s — %s" % [
			str(cluster.get("classification", "")).replace("_", " ").capitalize(),
			", ".join(cluster.get("idea_ids", []) as Array),
			str(cluster.get("reason", ""))
		])
	for record_value in IDEA_FINAL_REVIEW_V0218.review_records(
		_idea_diversity_session_v0214
	):
		if not record_value is Dictionary:
			continue
		var record: Dictionary = record_value
		var idea_id := str(record.get("id", ""))
		var panel := PanelContainer.new()
		_idea_review_list_v0218.add_child(panel)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		panel.add_child(margin)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 4)
		margin.add_child(content)
		var keep := CheckBox.new()
		keep.name = "KeepFinalIdeaV0218_%s" % idea_id
		keep.text = "%s — %s" % [idea_id, str(record.get("title", "Untitled idea"))]
		keep.button_pressed = true
		keep.set_meta("idea_id", idea_id)
		content.add_child(keep)
		_idea_review_checks_v0218.append(keep)
		var finding := IDEA_FINAL_REVIEW_V0218.findings_for_idea(
			_idea_diversity_session_v0214, idea_id
		)
		var adherence_value: Variant = finding.get("adherence", {})
		if adherence_value is Dictionary and not (adherence_value as Dictionary).is_empty():
			var adherence: Dictionary = adherence_value
			var adherence_id := str(adherence.get("adherence", "match"))
			var adherence_label := "✓ Matches request"
			if adherence_id == "partial_mismatch":
				adherence_label = "⚠ Possible request mismatch"
			elif adherence_id == "clear_mismatch":
				adherence_label = "⚠ Clear request mismatch"
			var label := Label.new()
			label.text = "%s\nAI: %s" % [
				adherence_label, str(adherence.get("reason", "No reason supplied."))
			]
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(label)
			report_lines.append("%s: %s — %s" % [idea_id, adherence_id, str(adherence.get("reason", ""))])
		var related_value: Variant = finding.get("similarity_clusters", [])
		if related_value is Array:
			for cluster_value in related_value as Array:
				if not cluster_value is Dictionary:
					continue
				var cluster: Dictionary = cluster_value
				var others: Array[String] = []
				for related_id_value in cluster.get("idea_ids", []):
					var related_id := str(related_id_value)
					if related_id != idea_id:
						others.append("%s — %s" % [related_id, _idea_ledger_title_v0214(related_id)])
				var similarity := Label.new()
				similarity.text = "⚠ %s with %s\nAI: %s" % [
					str(cluster.get("classification", "related")).replace("_", " ").capitalize(),
					", ".join(others),
					str(cluster.get("reason", "No reason supplied."))
				]
				similarity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				content.add_child(similarity)
		_append_final_idea_details_v02110(content, record, idea_id)
	if _idea_similarity_review_text_v0214 != null:
		_idea_similarity_review_text_v0214.text = "\n".join(report_lines)
	CCFToolWindowStateService.show_window(
		_idea_similarity_review_window_v0214,
		"final_idea_review_v0218",
		Vector2i(980, 760),
		_idea_generator_v01532
	)


func _append_final_idea_details_v02110(
	content: VBoxContainer, record: Dictionary, idea_id: String
) -> void:
	var sections := IDEA_REVIEW_PRESENTATION_V02110.detail_sections(record)
	if sections.is_empty():
		return
	var toggle := Button.new()
	toggle.name = "ToggleFinalIdeaDetailsV02110_%s" % idea_id
	toggle.text = "Show Idea"
	toggle.toggle_mode = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	content.add_child(toggle)
	var detail_panel := PanelContainer.new()
	detail_panel.name = "FinalIdeaDetailsV02110_%s" % idea_id
	detail_panel.visible = false
	content.add_child(detail_panel)
	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 10)
	detail_margin.add_theme_constant_override("margin_right", 10)
	detail_margin.add_theme_constant_override("margin_top", 8)
	detail_margin.add_theme_constant_override("margin_bottom", 8)
	detail_panel.add_child(detail_margin)
	var detail_content := VBoxContainer.new()
	detail_content.add_theme_constant_override("separation", 8)
	detail_margin.add_child(detail_content)
	for section_value in sections:
		var section: Dictionary = section_value
		var label := Label.new()
		label.text = "%s\n%s" % [
			str(section.get("label", "Detail")),
			str(section.get("text", ""))
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if bool(section.get("prominent", false)):
			label.add_theme_font_size_override("font_size", 17)
		detail_content.add_child(label)
	toggle.toggled.connect(
		_set_one_final_idea_detail_expanded_v02110.bind(toggle, detail_panel)
	)
	_idea_review_detail_buttons_v02110.append(toggle)
	_idea_review_detail_panels_v02110.append(detail_panel)


func _set_one_final_idea_detail_expanded_v02110(
	expanded: bool, toggle: Button, detail_panel: Control
) -> void:
	detail_panel.visible = expanded
	toggle.set_pressed_no_signal(expanded)
	toggle.text = "Hide Idea" if expanded else "Show Idea"


func _set_final_review_details_expanded_v02110(expanded: bool) -> void:
	for index in range(_idea_review_detail_panels_v02110.size()):
		var detail_panel := _idea_review_detail_panels_v02110[index]
		var toggle := _idea_review_detail_buttons_v02110[index]
		if is_instance_valid(detail_panel) and is_instance_valid(toggle):
			_set_one_final_idea_detail_expanded_v02110(
				expanded, toggle, detail_panel
			)


func _set_final_review_checks_v0218(pressed: bool) -> void:
	for checkbox in _idea_review_checks_v0218:
		if is_instance_valid(checkbox):
			checkbox.set_pressed_no_signal(pressed)


func _hide_pending_final_idea_review_v0218() -> void:
	if _idea_similarity_review_window_v0214 != null:
		CCFToolWindowStateService.save_window(
			_idea_similarity_review_window_v0214, "final_idea_review_v0218"
		)
		_idea_similarity_review_window_v0214.hide()
	if _idea_review_awaiting_user_v0218:
		_idea_status.text = "Waiting for final Idea review… use Open Final Idea Review to continue."


func _reopen_final_idea_review_v0218() -> void:
	if not _idea_review_awaiting_user_v0218:
		return
	CCFToolWindowStateService.show_window(
		_idea_similarity_review_window_v0214,
		"final_idea_review_v0218",
		Vector2i(980, 760),
		_idea_generator_v01532
	)


func _apply_final_idea_review_v0218() -> void:
	if not _idea_review_awaiting_user_v0218:
		return
	if not _idea_session_project_is_current_v0214():
		_discard_idea_session_for_project_change_v0214()
		return
	var kept_ids: Array[String] = []
	for checkbox in _idea_review_checks_v0218:
		if is_instance_valid(checkbox) and checkbox.button_pressed:
			kept_ids.append(str(checkbox.get_meta("idea_id", "")))
	var result := IDEA_FINAL_REVIEW_V0218.apply_user_selection(
		_idea_diversity_session_v0214, kept_ids
	)
	_idea_review_awaiting_user_v0218 = false
	if _idea_review_resume_v0218 != null:
		_idea_review_resume_v0218.hide()
	if _idea_similarity_review_window_v0214 != null:
		CCFToolWindowStateService.save_window(
			_idea_similarity_review_window_v0214, "final_idea_review_v0218"
		)
		_idea_similarity_review_window_v0214.hide()
	_idea_status.text = "Review applied — %d/%d reviewed Ideas kept." % [
		int(result.get("kept_count", 0)),
		int(result.get("reviewed_count", 0))
	]
	_maybe_queue_final_top_up_v0214()


func _idea_ledger_title_v0214(idea_id: String) -> String:
	for category in ["accepted", "rejected"]:
		for record_value in _idea_diversity_session_v0214.get(category, []):
			if (
				record_value is Dictionary
				and str((record_value as Dictionary).get("id", "")) == idea_id
			):
				return str((record_value as Dictionary).get("title", "Untitled idea"))
	return "Untitled idea"


func _maybe_queue_final_top_up_v0214() -> void:
	if not _idea_session_project_is_current_v0214():
		_discard_idea_session_for_project_change_v0214()
		return
	var request_size := IDEA_DIVERSITY_V0214.next_top_up_request_size(
		_idea_diversity_session_v0214
	)
	if request_size <= 0:
		_finalize_idea_generation_session_v0214()
		return
	IDEA_DIVERSITY_V0214.mark_request_started(
		_idea_diversity_session_v0214, request_size, "top_up"
	)
	var result := _queue_idea_request_v0211(request_size)
	if not bool(result.get("ok", false)):
		_idea_batch_errors_v0211.append(
			"The one-shot recovery request could not be queued: %s"
			% str(result.get("error", "Unknown queue error."))
		)
		_idea_diversity_session_v0214["final_top_up_completed"] = true
		_finalize_idea_generation_session_v0214()
		return
	var job_id := str(result.get("job_id", ""))
	var batch_index := _idea_batch_expected_requests_v0211
	_idea_batch_job_indices_v0211[job_id] = batch_index
	_idea_batch_metadata_v0211[batch_index] = {"idea_batch_request_kind": "top_up"}
	var anti_repeat := IDEA_DIVERSITY_V0214.anti_repeat_prompt(
		_idea_diversity_session_v0214
	)
	var decorated := bool(_generation_service.call(
		"decorate_idea_batch_job_v0211",
		job_id,
		_idea_batch_group_id_v0211,
		batch_index,
		_idea_batch_expected_requests_v0211 + 1,
		_idea_batch_requested_total_v0211,
			anti_repeat,
			"top_up"
		))
	if not decorated:
		_idea_batch_errors_v0211.append(
			"The one-shot recovery request could not be marked for safe aggregation."
		)
		if _generation_service.has_method("cancel_job_v01531"):
			_generation_service.call("cancel_job_v01531", job_id)
		return
	_idea_status.text = (
		"Making one final recovery request for %d missing idea%s… %d/%d accepted."
		% [
			request_size,
			"" if request_size == 1 else "s",
			IDEA_DIVERSITY_V0214.accepted_count(_idea_diversity_session_v0214),
			_idea_batch_requested_total_v0211
		]
	)


func _finalize_idea_generation_session_v0214() -> void:
	if _idea_diversity_session_v0214.is_empty():
		return
	if not _idea_session_project_is_current_v0214():
		_discard_idea_session_for_project_change_v0214()
		return
	if (
		_idea_manual_extension_active_v0218
		and IDEA_FINAL_REVIEW_V0218.review_scope_ids(
			_idea_diversity_session_v0214
		).is_empty()
	):
		_restore_completed_curation_after_extension_v0219(
			"Generate More completed without any retained new Ideas. The previous instruction remains the next prefill; rejected candidates remain repeat-prevention memory.",
			true
		)
		return
	var combined := IDEA_DIVERSITY_V0214.accepted_ideas(
		_idea_diversity_session_v0214
	)
	var aggregate_metadata: Dictionary = {}
	var streaming_used := false
	var streaming_fallback_used := false
	var reasoning_detected := false
	var reasoning_transports: Array[String] = []
	var stream_retries := 0
	var json_repairs := 0
	var metadata_keys := _idea_batch_metadata_v0211.keys()
	metadata_keys.sort()
	for key_value in metadata_keys:
		var metadata_value: Variant = _idea_batch_metadata_v0211.get(key_value, {})
		if metadata_value is Dictionary and not (metadata_value as Dictionary).is_empty():
			var batch_metadata: Dictionary = metadata_value as Dictionary
			if aggregate_metadata.is_empty():
				aggregate_metadata = batch_metadata.duplicate(true)
			streaming_used = streaming_used or bool(batch_metadata.get("streaming_used", false))
			streaming_fallback_used = (
				streaming_fallback_used
				or bool(batch_metadata.get("streaming_fallback_used", false))
			)
			reasoning_detected = reasoning_detected or bool(
				batch_metadata.get("reasoning_detected", false)
			)
			for transport_value in str(
				batch_metadata.get("reasoning_transport", "")
			).split(",", false):
				var reasoning_transport := str(transport_value).strip_edges()
				if (
					not reasoning_transport.is_empty()
					and not reasoning_transport in reasoning_transports
				):
					reasoning_transports.append(reasoning_transport)
			stream_retries += int(batch_metadata.get("stream_retries", 0))
			json_repairs += int(batch_metadata.get("response_repair_attempts", 0))
	aggregate_metadata["streaming_used"] = streaming_used
	aggregate_metadata["streaming_fallback_used"] = streaming_fallback_used
	aggregate_metadata["reasoning_detected"] = reasoning_detected
	aggregate_metadata["reasoning_transport"] = ", ".join(reasoning_transports)
	aggregate_metadata["stream_retries"] = stream_retries
	aggregate_metadata["response_repair_attempts"] = json_repairs
	var diversity_summary := IDEA_DIVERSITY_V0214.summary(
		_idea_diversity_session_v0214
	)
	diversity_summary["final_review_check_adherence"] = bool(
		_idea_diversity_session_v0214.get("final_review_check_adherence", false)
	)
	diversity_summary["final_review_check_similarity"] = bool(
		_idea_diversity_session_v0214.get("final_review_check_similarity", false)
	)
	diversity_summary["adherence_finding_count"] = (
		_idea_diversity_session_v0214.get("final_review_findings", []) as Array
	).size()
	diversity_summary["similarity_finding_count"] = (
		_idea_diversity_session_v0214.get("final_review_clusters", []) as Array
	).size()
	diversity_summary["user_review_rejected_count"] = int(
		_idea_diversity_session_v0214.get("user_review_rejected_count", 0)
	)
	diversity_summary["fast_path_v02112"] = bool(
		_idea_diversity_session_v0214.get("fast_path_v02112", false)
	)
	aggregate_metadata["idea_batch_contract_version"] = IDEA_BATCHING_V0211.CONTRACT_VERSION
	aggregate_metadata["idea_batch_group_id"] = _idea_batch_group_id_v0211
	aggregate_metadata["idea_batch_requested_total"] = _idea_batch_requested_total_v0211
	aggregate_metadata["idea_batch_request_count"] = int(
		diversity_summary.get("generation_batch_count", 0)
	)
	aggregate_metadata["idea_generation_batch_count"] = int(
		diversity_summary.get("generation_batch_count", 0)
	)
	aggregate_metadata["idea_batch_successful_requests"] = _idea_batch_results_v0211.size()
	aggregate_metadata["idea_batch_result_count"] = combined.size()
	aggregate_metadata["idea_batch_errors"] = _idea_batch_errors_v0211.duplicate()
	aggregate_metadata["idea_diversity_contract_version"] = IDEA_DIVERSITY_V0214.CONTRACT_VERSION
	aggregate_metadata["idea_diversity_summary"] = diversity_summary
	aggregate_metadata["idea_title_duplicate_warnings"] = (
		_idea_diversity_session_v0214.get("title_warnings", []) as Array
	).duplicate(true)
	aggregate_metadata["idea_similarity_clusters"] = (
		_idea_diversity_session_v0214.get("final_review_clusters", []) as Array
	).duplicate(true)
	aggregate_metadata["idea_adherence_findings"] = (
		_idea_diversity_session_v0214.get("final_review_findings", []) as Array
	).duplicate(true)
	aggregate_metadata["idea_user_review_rejected_count"] = int(
		_idea_diversity_session_v0214.get("user_review_rejected_count", 0)
	)
	if _idea_manual_extension_active_v0218:
		aggregate_metadata["idea_last_extension_retained_count"] = (
			IDEA_FINAL_REVIEW_V0218.review_scope_ids(
				_idea_diversity_session_v0214
			).size()
		)
		aggregate_metadata["idea_last_extension_errors"] = (
			_idea_batch_errors_v0211.duplicate()
		)
	aggregate_metadata["idea_source_id"] = str(
		_idea_diversity_session_v0214.get("idea_source_id_snapshot", "")
	)
	aggregate_metadata["idea_source_title"] = str(
		_idea_diversity_session_v0214.get("idea_source_title_snapshot", "")
	)
	if str(aggregate_metadata.get("idea_detail_level", "")) == "custom":
		var counts := IDEA_CUSTOM_LENGTH_V0211.actual_counts(combined)
		var target := int(aggregate_metadata.get("idea_custom_target_characters", 0))
		var target_met := 0
		for actual_count in counts:
			if IDEA_CUSTOM_LENGTH_V0211.count_within_target(actual_count, target):
				target_met += 1
		aggregate_metadata["idea_actual_character_counts"] = counts
		aggregate_metadata["idea_custom_target_met_count"] = target_met
	_idea_job_id = ""
	_idea_generate_button.disabled = false
	var previous_manual_count := int(
		_idea_curation_session_v0218.get("manual_generate_more_count", 0)
	)
	var previous_deleted_count := int(
		_idea_curation_session_v0218.get("user_deleted_count", 0)
	)
	_idea_curation_session_v0218 = IDEA_FINAL_REVIEW_V0218.create_curation_session(
		_idea_diversity_session_v0214, aggregate_metadata
	)
	_idea_curation_session_v0218["manual_generate_more_count"] = (
		previous_manual_count + (1 if _idea_manual_extension_active_v0218 else 0)
	)
	_idea_curation_session_v0218["user_deleted_count"] = previous_deleted_count
	aggregate_metadata["idea_manual_generate_more_count"] = int(
		_idea_curation_session_v0218.get("manual_generate_more_count", 0)
	)
	aggregate_metadata["idea_user_deleted_count"] = previous_deleted_count
	_idea_curation_session_v0218["metadata"] = aggregate_metadata.duplicate(true)
	_render_ideas(combined)
	if _idea_generator_v01532 != null:
		_idea_generator_v01532.call("clear_provisional_ideas_v02112")
		_idea_generator_v01532.set_last_generated_ideas_v01532(
			combined, aggregate_metadata
		)
	if _idea_generate_more_v0218 != null:
		# A completed empty batch is still a valid curation session: the author may
		# have unchecked or deleted every result and should be able to request a
		# replacement set without starting over and losing anti-repeat memory.
		_idea_generate_more_v0218.disabled = false
	_set_completed_idea_batch_status_v0211(combined, aggregate_metadata)
	_reset_idea_batch_state_v0211()
	_idea_manual_extension_active_v0218 = false


func _open_generate_more_dialog_v0218() -> void:
	if not _curation_project_is_current_v0218():
		_clear_idea_curation_session_v0218()
		return
	var visible_value: Variant = _idea_curation_session_v0218.get("visible_ideas", [])
	var visible_count := (visible_value as Array).size() if visible_value is Array else 0
	var remaining_capacity := IDEA_BATCHING_V0211.MAX_TOTAL_IDEAS - visible_count
	if remaining_capacity <= 0:
		_idea_status.text = "This working batch is already at the maximum Idea count. Delete Ideas before generating more."
		return
	_idea_generate_more_count_v0218.max_value = remaining_capacity
	_idea_generate_more_count_v0218.value = mini(4, remaining_capacity)
	var prompt_mode := IDEA_FINAL_REVIEW_V0218.extension_prompt_mode(
		_idea_curation_session_v0218
	)
	var uses_source := prompt_mode == "additional_direction"
	_idea_generate_more_instruction_label_v0219.text = (
		"Additional Direction" if uses_source else "Prompt"
	)
	_idea_generate_more_instruction_v0219.text = (
		IDEA_FINAL_REVIEW_V0218.extension_instruction(
			_idea_curation_session_v0218
		)
	)
	_idea_generate_more_dialog_prepared_v0219 = true
	_idea_generate_more_source_row_v0219.visible = uses_source
	if uses_source:
		var context_value: Variant = _idea_curation_session_v0218.get(
			"generation_context", {}
		)
		var context: Dictionary = context_value if context_value is Dictionary else {}
		var source_title := str(context.get("idea_source_title", "")).strip_edges()
		_idea_generate_more_source_value_v0219.text = (
			source_title if not source_title.is_empty() else "Untitled frozen Idea Source"
		)
		_idea_generate_more_context_hint_v0219.text = (
			"The Idea Source remains fixed for this working batch. Edit or clear Additional Direction to steer only these new Ideas. Retained, rejected and deleted concepts remain repeat-prevention memory."
		)
	else:
		_idea_generate_more_source_value_v0219.text = ""
		_idea_generate_more_context_hint_v0219.text = (
			"New Ideas will be appended to the current working batch and will avoid retained, rejected and deleted concepts."
		)
	CCFToolWindowStateService.show_window(
		_idea_generate_more_dialog_v0218,
		"generate_more_ideas_v02110",
		Vector2i(720, 520),
		_idea_generator_v01532,
		true
	)
	_idea_generate_more_instruction_v0219.grab_focus()


func _generate_more_ideas_v0218() -> void:
	if not _curation_project_is_current_v0218():
		_clear_idea_curation_session_v0218()
		return
	if not _idea_diversity_session_v0214.is_empty() or _idea_review_awaiting_user_v0218:
		_idea_status.text = "Finish the current generation or Final Idea Review before generating more."
		return
	var additional := IDEA_BATCHING_V0211.normalise_total_ideas(
		int(_idea_generate_more_count_v0218.value)
	)
	var visible_value: Variant = _idea_curation_session_v0218.get("visible_ideas", [])
	var visible_count := (visible_value as Array).size() if visible_value is Array else 0
	additional = mini(additional, IDEA_BATCHING_V0211.MAX_TOTAL_IDEAS - visible_count)
	if additional <= 0:
		return
	_reset_idea_batch_state_v0211()
	var per_request := int(_idea_curation_session_v0218.get(
		"batch_limit", _idea_batch_size_value_v0211()
	))
	per_request = IDEA_BATCHING_V0211.normalise_ideas_per_request(per_request)
	var edited_instruction := (
		_idea_generate_more_instruction_v0219.text
		if _idea_generate_more_dialog_prepared_v0219
		else IDEA_FINAL_REVIEW_V0218.extension_instruction(
			_idea_curation_session_v0218
		)
	)
	_idea_generate_more_dialog_prepared_v0219 = false
	_idea_diversity_session_v0214 = IDEA_FINAL_REVIEW_V0218.create_extension_session(
		_idea_curation_session_v0218,
		additional,
		per_request,
		edited_instruction
	)
	_idea_diversity_session_v0214["fast_path_v02112"] = (
		_idea_fast_path_enabled_v02112(_idea_diversity_session_v0214)
	)
	_idea_batch_group_id_v0211 = "idea-more-%d-%d" % [
		Time.get_ticks_usec(), get_instance_id()
	]
	_idea_batch_requested_total_v0211 = visible_count + additional
	_idea_batch_expected_requests_v0211 = IDEA_BATCHING_V0211.request_plan(
		additional, per_request
	).size()
	_idea_manual_extension_active_v0218 = true
	_idea_job_id = _idea_batch_group_id_v0211
	_idea_generate_button.disabled = true
	_idea_generate_more_v0218.disabled = true
	_idea_status.text = "Generating %d more Idea%s… %d retained Ideas remain visible until the extension finishes." % [
		additional, "" if additional == 1 else "s", visible_count
	]
	_queue_next_normal_idea_batch_v0214()


func _render_ideas(ideas: Array) -> void:
	_clear_children(_idea_result_box)
	if ideas.is_empty():
		var empty := Label.new()
		empty.name = "NoGeneratedIdeasV0218"
		empty.text = "No generated Ideas remain in this working batch."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_idea_result_box.add_child(empty)
		return
	for index in range(ideas.size()):
		var idea_value: Variant = ideas[index]
		if not idea_value is Dictionary:
			continue
		var idea: Dictionary = idea_value
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
		var actions := HFlowContainer.new()
		actions.add_theme_constant_override("separation", 8)
		content.add_child(actions)
		var use_button := Button.new()
		use_button.text = "Use This Idea"
		use_button.pressed.connect(_use_idea.bind(idea.duplicate(true)))
		actions.add_child(use_button)
		var delete_button := Button.new()
		delete_button.name = "DeleteGeneratedIdeaV0218_%d" % index
		delete_button.text = "Delete This Idea"
		delete_button.tooltip_text = "Remove this Idea only from the temporary generated working batch. Saved Library and project data are not changed."
		delete_button.pressed.connect(_delete_generated_idea_v0218.bind(index))
		actions.add_child(delete_button)


func _delete_generated_idea_v0218(index: int) -> void:
	if not _curation_project_is_current_v0218():
		_clear_idea_curation_session_v0218()
		return
	var removed := IDEA_FINAL_REVIEW_V0218.remove_visible_idea(
		_idea_curation_session_v0218, index
	)
	if not bool(removed.get("ok", false)):
		return
	var visible: Array = _idea_curation_session_v0218.get("visible_ideas", []) as Array
	var metadata: Dictionary = (
		_idea_curation_session_v0218.get("metadata", {}) as Dictionary
	).duplicate(true)
	metadata["idea_user_deleted_count"] = int(
		_idea_curation_session_v0218.get("user_deleted_count", 0)
	)
	_idea_curation_session_v0218["metadata"] = metadata.duplicate(true)
	_render_ideas(visible)
	if _idea_generator_v01532 != null:
		_idea_generator_v01532.set_last_generated_ideas_v01532(visible, metadata)
	if _idea_generate_more_v0218 != null:
		_idea_generate_more_v0218.disabled = false
	_idea_status.text = "%d generated Idea%s remain. The deleted concept stays in temporary repeat-prevention memory." % [
		visible.size(), "" if visible.size() == 1 else "s"
	]


func _curation_project_is_current_v0218() -> bool:
	if _idea_curation_session_v0218.is_empty():
		return false
	var origin := str(_idea_curation_session_v0218.get("project_id", ""))
	return origin.is_empty() or origin == str(_project.get("project_id", ""))


func _clear_idea_curation_session_v0218() -> void:
	_idea_curation_session_v0218.clear()
	_idea_last_completed_metadata_v0218.clear()
	_idea_manual_extension_active_v0218 = false
	_idea_generate_more_dialog_prepared_v0219 = false
	if _idea_generate_more_v0218 != null:
		_idea_generate_more_v0218.disabled = true


func _cancel_generate_more_dialog_v0219() -> void:
	_idea_generate_more_dialog_prepared_v0219 = false


func _dismiss_generate_more_dialog_v02110() -> void:
	if _idea_generate_more_dialog_v0218 != null:
		CCFToolWindowStateService.save_window(
			_idea_generate_more_dialog_v0218,
			"generate_more_ideas_v02110"
		)
		_idea_generate_more_dialog_v0218.hide()
	_cancel_generate_more_dialog_v0219()


func _confirm_generate_more_dialog_v02110() -> void:
	if _idea_generate_more_dialog_v0218 != null:
		CCFToolWindowStateService.save_window(
			_idea_generate_more_dialog_v0218,
			"generate_more_ideas_v02110"
		)
		_idea_generate_more_dialog_v0218.hide()
	_generate_more_ideas_v0218()


func _restore_completed_curation_after_extension_v0219(
	message: String, count_completed_request: bool = false
) -> void:
	IDEA_FINAL_REVIEW_V0218.merge_extension_rejected_memory(
		_idea_curation_session_v0218, _idea_diversity_session_v0214
	)
	var visible_value: Variant = _idea_curation_session_v0218.get(
		"visible_ideas", []
	)
	var visible: Array = (
		(visible_value as Array).duplicate(true)
		if visible_value is Array else []
	)
	var metadata_value: Variant = _idea_curation_session_v0218.get("metadata", {})
	var metadata: Dictionary = (
		(metadata_value as Dictionary).duplicate(true)
		if metadata_value is Dictionary else {}
	)
	if count_completed_request:
		_idea_curation_session_v0218["manual_generate_more_count"] = int(
			_idea_curation_session_v0218.get("manual_generate_more_count", 0)
		) + 1
		metadata["idea_manual_generate_more_count"] = int(
			_idea_curation_session_v0218.get("manual_generate_more_count", 0)
		)
		metadata["idea_last_extension_retained_count"] = 0
		metadata["idea_last_extension_errors"] = _idea_batch_errors_v0211.duplicate()
		_idea_curation_session_v0218["metadata"] = metadata.duplicate(true)
	_render_ideas(visible)
	if _idea_generator_v01532 != null:
		_idea_generator_v01532.set_last_generated_ideas_v01532(visible, metadata)
	if _idea_generate_more_v0218 != null:
		_idea_generate_more_v0218.disabled = false
	if _idea_similarity_review_window_v0214 != null:
		_idea_similarity_review_window_v0214.hide()
	_idea_job_id = ""
	_idea_generate_button.disabled = false
	_idea_status.text = message
	_reset_idea_batch_state_v0211()
	_idea_manual_extension_active_v0218 = false


func _idea_session_project_is_current_v0214() -> bool:
	if _idea_diversity_session_v0214.is_empty():
		return true
	var origin := str(_idea_diversity_session_v0214.get(
		"project_id_snapshot", ""
	))
	return origin.is_empty() or origin == str(_project.get("project_id", ""))


func _discard_idea_session_for_project_change_v0214() -> void:
	_idea_job_id = ""
	_idea_generate_button.disabled = false
	_idea_status.text = (
		"Idea generation result was discarded because the active project changed."
	)
	_clear_idea_curation_session_v0218()
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
	var diversity_value: Variant = aggregate_metadata.get(
		"idea_diversity_summary", {}
	)
	var diversity: Dictionary = (
		diversity_value if diversity_value is Dictionary else {}
	)
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
	var recovery_note := (
		" after final recovery"
		if bool(diversity.get("final_top_up_started", false))
		else ""
	)
	var rejected_count := int(diversity.get("rejected_count", 0))
	var warning_count := int(diversity.get("title_warning_count", 0))
	var generation_batches := int(diversity.get(
		"generation_batch_count",
		aggregate_metadata.get("idea_generation_batch_count", 0)
	))
	if bool(diversity.get("fast_path_v02112", false)):
		_idea_status.text = (
			"%d/%d Ideas accepted immediately across %d generation batch%s%s%s."
			% [
				combined.size(),
				_idea_batch_requested_total_v0211,
				generation_batches,
				"" if generation_batches == 1 else "es",
				custom_note,
				error_note
			]
		)
	else:
		_idea_status.text = (
			"%d/%d unique ideas accepted%s across %d generation batch%s • %d rejected candidate%s • %d similarity warning%s%s%s."
			% [
				combined.size(),
				_idea_batch_requested_total_v0211,
				recovery_note,
				generation_batches,
				"" if generation_batches == 1 else "es",
				rejected_count,
				"" if rejected_count == 1 else "s",
				warning_count,
				"" if warning_count == 1 else "s",
				custom_note,
				error_note
			]
		)
	var final_review_label := "Off"
	if bool(diversity.get("final_review_check_adherence", false)) or bool(
		diversity.get("final_review_check_similarity", false)
	):
		var review_parts: Array[String] = []
		if bool(diversity.get("final_review_check_adherence", false)):
			review_parts.append("request adherence")
		if bool(diversity.get("final_review_check_similarity", false)):
			review_parts.append("similarity")
		final_review_label = "Advisory: %s" % " + ".join(review_parts)
	elif str(diversity.get("final_review_mode", "off")) != "off":
		final_review_label = "Advisory similarity compatibility mode"
	var user_review_rejected := int(diversity.get("user_review_rejected_count", 0))
	var user_deleted := int(aggregate_metadata.get("idea_user_deleted_count", 0))
	var manual_more := int(aggregate_metadata.get("idea_manual_generate_more_count", 0))
	var detail_lines: Array[String] = [
		"Generation details",
		"Requested: %d" % _idea_batch_requested_total_v0211,
		"Accepted: %d" % combined.size(),
		"Generation batches: %d" % generation_batches,
		"Transport: %s" % (
			"Completed-response fallback"
			if bool(aggregate_metadata.get("streaming_fallback_used", false))
			else (
				"Streaming"
				if bool(aggregate_metadata.get("streaming_used", false))
				else "Completed response"
			)
		),
		"Stream retries: %d" % int(aggregate_metadata.get("stream_retries", 0)),
		"JSON repairs: %d" % int(aggregate_metadata.get("response_repair_attempts", 0)),
		"Reasoning detected: %s" % (
			"Yes" if bool(aggregate_metadata.get("reasoning_detected", false)) else "No"
		),
		"Initial generated candidates: %d" % int(diversity.get(
			"initial_generated_candidate_count", 0
		)),
		"Semantic repair passes: %d" % int(diversity.get(
			"semantic_repair_pass_count", 0
		)),
		"Repaired candidates processed: %d" % int(diversity.get(
			"semantic_repair_candidate_count", 0
		)),
		"Total validation-pass candidates: %d" % int(diversity.get(
			"validation_candidate_count", 0
		)),
		"Rejected candidates: %d" % rejected_count,
		"Similarity warnings: %d" % warning_count,
		"Final Idea Review: %s" % final_review_label,
		"All-options-off fast path: %s" % (
			"Yes" if bool(diversity.get("fast_path_v02112", false)) else "No"
		),
		"User-rejected during final review: %d" % user_review_rejected,
		"User-deleted after generation: %d" % user_deleted,
		"Manual Generate More requests: %d" % manual_more,
		"Final top-up used: %s" % (
			"Yes" if bool(diversity.get("final_top_up_started", false)) else "No"
		)
	]
	if bool(aggregate_metadata.get("reasoning_detected", false)):
		var reasoning_transport := str(
			aggregate_metadata.get("reasoning_transport", "")
		).strip_edges()
		if not reasoning_transport.is_empty():
			detail_lines.append("Reasoning signal: %s" % reasoning_transport)
	var warnings_value: Variant = aggregate_metadata.get(
		"idea_title_duplicate_warnings", []
	)
	if warnings_value is Array and not (warnings_value as Array).is_empty():
		detail_lines.append("")
		detail_lines.append(
			"Title similarity is a review signal, not an automatic duplicate verdict:"
		)
		for warning_value in warnings_value as Array:
			if warning_value is Dictionary:
				detail_lines.append("• %s ↔ %s" % [
					str((warning_value as Dictionary).get("existing_title", "Untitled idea")),
					str((warning_value as Dictionary).get("candidate_title", "Untitled idea"))
				])
	_idea_status.tooltip_text = "\n".join(detail_lines)


func _idea_batch_received_count_v0211() -> int:
	var count := 0
	for ideas_value in _idea_batch_results_v0211.values():
		if ideas_value is Array:
			count += (ideas_value as Array).size()
	return mini(count, _idea_batch_requested_total_v0211)


func _idea_fast_path_enabled_v02112(session: Dictionary) -> bool:
	return (
		not bool(session.get("prevent_repeats", true))
		and not bool(session.get("final_review_check_adherence", false))
		and not bool(session.get("final_review_check_similarity", false))
		and str(session.get("final_review_mode", "off"))
		== IDEA_DIVERSITY_V0214.FINAL_REVIEW_OFF
		and not bool(session.get("final_top_up_enabled", false))
	)


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
	_idea_diversity_session_v0214.clear()
	_idea_diversity_review_job_id_v0214 = ""
	_idea_review_awaiting_user_v0218 = false
	_idea_review_checks_v0218.clear()
	if _idea_review_resume_v0218 != null:
		_idea_review_resume_v0218.hide()


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
		"adaptive_accepted_target": true,
		"prevent_repeats": (
			_idea_prevent_repeats_v0214 != null
			and _idea_prevent_repeats_v0214.button_pressed
		),
		"final_similarity_mode": _idea_final_review_mode_v0214(),
		"final_review_adherence": (
			_idea_review_adherence_v0218 != null
			and _idea_review_adherence_v0218.button_pressed
		),
		"final_review_similarity": (
			_idea_review_similarity_v0218 != null
			and _idea_review_similarity_v0218.button_pressed
		),
		"advisory_final_review": true,
		"temporary_generated_idea_delete": true,
		"repeatable_generate_more": true,
		"one_shot_top_up": (
			_idea_final_top_up_v0214 != null
			and _idea_final_top_up_v0214.button_pressed
		),
		"diversity": IDEA_DIVERSITY_V0214.capabilities(),
		"service": service_capabilities
	}


func _idea_final_review_mode_v0214() -> String:
	if (
		_idea_review_similarity_v0218 != null
		and _idea_review_similarity_v0218.button_pressed
	):
		return IDEA_DIVERSITY_V0214.FINAL_REVIEW_FLAG
	if (
		_idea_final_similarity_v0214 == null
		or _idea_final_similarity_v0214.selected < 0
	):
		return IDEA_DIVERSITY_V0214.FINAL_REVIEW_OFF
	return IDEA_DIVERSITY_V0214.normalise_final_review_mode(
		_idea_final_similarity_v0214.get_item_metadata(
			_idea_final_similarity_v0214.selected
		)
	)


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


func _idea_generation_context_snapshot_v0217() -> Dictionary:
	var context := {
		"prompt_mode": "primary_prompt",
		"seed_text": _idea_seed.text.strip_edges() if _idea_seed != null else "",
		"series_context": CCFSeriesService.generation_context_for_project(_project),
		"idea_source_id": "",
		"idea_source_title": "",
		"idea_source_context": ""
	}
	if _idea_generator_v01532 == null:
		return IDEA_DIVERSITY_V0214.normalise_generation_context(context)
	if _idea_generator_v01532.has_method("prompt_presentation_v0213"):
		var presentation_value: Variant = _idea_generator_v01532.call(
			"prompt_presentation_v0213"
		)
		if presentation_value is Dictionary:
			context["prompt_mode"] = str(
				(presentation_value as Dictionary).get("mode", "primary_prompt")
			)
	if _idea_generator_v01532.has_method("active_idea_source_v0213"):
		var source_value: Variant = _idea_generator_v01532.call(
			"active_idea_source_v0213"
		)
		if source_value is Dictionary:
			context["idea_source_id"] = str(
				(source_value as Dictionary).get("id", "")
			)
			context["idea_source_title"] = str(
				(source_value as Dictionary).get("title", "")
			)
	if _idea_generator_v01532.has_method("active_idea_source_context_v0213"):
		context["idea_source_context"] = str(
			_idea_generator_v01532.call("active_idea_source_context_v0213")
		)
	return IDEA_DIVERSITY_V0214.normalise_generation_context(context)


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
	var changed_callback := Callable(self, "_on_idea_seed_text_changed_v02111")
	if not _idea_seed.text_changed.is_connected(changed_callback):
		_idea_seed.text_changed.connect(changed_callback)
	_update_idea_prompt_presentation_v0213()


func _on_active_idea_source_changed_v0213(source: Dictionary) -> void:
	var next_source_id := str(source.get("id", ""))
	if (
		not _idea_preset_autofill_source_v02111.is_empty()
		and next_source_id != _idea_preset_autofill_source_v02111
	):
		if _idea_seed != null and _idea_seed.text == _idea_preset_autofill_text_v02111:
			_idea_preset_text_update_v02111 = true
			_idea_seed.text = ""
			_idea_preset_text_update_v02111 = false
		_idea_preset_autofill_text_v02111 = ""
		_idea_preset_autofill_source_v02111 = ""
	_update_idea_prompt_presentation_v0213()


func _on_direction_preset_selected_v02111(
	preset: Dictionary, source_id: String
) -> void:
	if _idea_seed == null:
		return
	if preset.is_empty():
		if _idea_seed.text == _idea_preset_autofill_text_v02111:
			_idea_preset_text_update_v02111 = true
			_idea_seed.text = ""
			_idea_preset_text_update_v02111 = false
		_idea_preset_autofill_text_v02111 = ""
		_idea_preset_autofill_source_v02111 = ""
		return
	var direction := str(preset.get("direction", ""))
	_idea_preset_text_update_v02111 = true
	_idea_seed.text = direction
	_idea_preset_text_update_v02111 = false
	_idea_preset_autofill_text_v02111 = direction
	_idea_preset_autofill_source_v02111 = source_id


func _on_original_idea_prompt_requested_v02114(prompt: String) -> void:
	var clean_prompt := prompt.strip_edges()
	if clean_prompt.is_empty() or _idea_seed == null or _idea_generator_v01532 == null:
		return
	# The stored generation prompt is already complete. Clear the current source
	# so its context cannot be silently added to the restored prompt a second time.
	_idea_generator_v01532.clear_active_idea_source_v0213()
	_idea_seed.text = clean_prompt
	_idea_generator_v01532.open_generator()
	if _idea_status != null:
		_idea_status.text = "Original saved prompt restored. Edit it or generate new Ideas."


func _on_idea_seed_text_changed_v02111() -> void:
	if _idea_preset_text_update_v02111 or _idea_preset_autofill_text_v02111.is_empty():
		return
	if _idea_seed.text == _idea_preset_autofill_text_v02111:
		return
	_idea_preset_autofill_text_v02111 = ""
	_idea_preset_autofill_source_v02111 = ""
	if (
		_idea_generator_v01532 != null
		and _idea_generator_v01532.has_method("mark_direction_preset_custom_v02111")
	):
		_idea_generator_v01532.call("mark_direction_preset_custom_v02111")


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
	if _idea_similarity_review_window_v0214 != null:
		_idea_similarity_review_window_v0214.hide()
	if _idea_generate_more_dialog_v0218 != null:
		_idea_generate_more_dialog_v0218.hide()
	_clear_idea_curation_session_v0218()
	_reset_idea_batch_state_v0211()
	super._close_tool_windows_for_project_change()
