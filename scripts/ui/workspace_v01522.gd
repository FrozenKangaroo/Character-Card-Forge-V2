class_name CCFWorkspaceV01522View
extends "res://scripts/ui/workspace_v01521.gd"

const GENERATION_SERVICE_V01522 = preload("res://scripts/services/generation_service_v01522.gd")
const GENERATION_DIAGNOSTICS_WINDOW_V01522 = preload("res://scripts/ui/generation_diagnostics_window_v01522.gd")
const STRATEGY_SAFE_SECTION := "safe_section"
const STRATEGY_FAST_FULL := "fast_full"

var _generation_diagnostics_window_v01522: Window
var _generation_failure_window_v01522: Window
var _generation_failure_label_v01522: Label
var _last_generation_diagnostics_v01522: Dictionary = {}
var _last_generation_diagnostics_job_id_v01522 := ""


func _ready() -> void:
	super._ready()
	_build_generation_diagnostics_ui_v01522()


func _install_generation_service_v015() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V01522:
		return
	var diagnostics_callable := Callable(self, "_on_generation_diagnostics_available_v01522")
	if previous_service != null:
		if previous_service.job_started.is_connected(_on_job_started):
			previous_service.job_started.disconnect(_on_job_started)
		if previous_service.job_completed.is_connected(_on_job_completed):
			previous_service.job_completed.disconnect(_on_job_completed)
		if previous_service.job_failed.is_connected(_on_job_failed):
			previous_service.job_failed.disconnect(_on_job_failed)
		if previous_service.job_cancelled.is_connected(_on_job_cancelled):
			previous_service.job_cancelled.disconnect(_on_job_cancelled)
		if previous_service.queue_changed.is_connected(_on_queue_changed):
			previous_service.queue_changed.disconnect(_on_queue_changed)
		if previous_service.has_signal("diagnostics_available") and previous_service.is_connected("diagnostics_available", diagnostics_callable):
			previous_service.disconnect("diagnostics_available", diagnostics_callable)
		if previous_service.get_parent() == self:
			remove_child(previous_service)
		previous_service.queue_free()

	var upgraded: CCFGenerationService = GENERATION_SERVICE_V01522.new()
	add_child(upgraded)
	upgraded.job_started.connect(_on_job_started)
	upgraded.job_completed.connect(_on_job_completed)
	upgraded.job_failed.connect(_on_job_failed)
	upgraded.job_cancelled.connect(_on_job_cancelled)
	upgraded.queue_changed.connect(_on_queue_changed)
	upgraded.connect("diagnostics_available", diagnostics_callable)
	_generation_service = upgraded

	for client in [
		_builder_window,
		_controlled_build_window,
		_group_scene_window,
		_relationship_window,
		_card_workflow_window,
		_attachment_window,
		_character_collaborator_window
	]:
		if client != null and client.has_method("set_generation_service"):
			client.call("set_generation_service", _generation_service)
	_wire_ai_idea_controller_to_current_service()


func _ensure_collaborator_generation_service_v015() -> bool:
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01522:
		_install_generation_service_v015()
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01522:
		_status.text = "Character Collaborator could not activate the v0.15.22 generation service."
		return false
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(_generation_service)
	return true


func _generate_character() -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var generation_settings := _generation_settings()
	var retry_count := int(generation_settings.get("retry_count", 1))
	var strategy := str(generation_settings.get("generation_strategy", STRATEGY_SAFE_SECTION))
	if strategy != STRATEGY_FAST_FULL:
		strategy = STRATEGY_SAFE_SECTION

	var supplement_request := _blueprint_supplement_request_v01517()
	var supplement_queued := false
	var supplement_error := ""
	if bool(supplement_request.get("needed", false)):
		var supplement_result: Dictionary = _generation_service.call(
			"queue_blueprint_supplemental_material",
			_project,
			profile,
			retry_count,
			bool(supplement_request.get("fill_alternate_greetings", false)),
			bool(supplement_request.get("fill_lorebook", false))
		)
		supplement_queued = bool(supplement_result.get("ok", false))
		if not supplement_queued:
			supplement_error = str(
				supplement_result.get(
					"error", "Could not queue Blueprint supplementary materialisation."
				)
			)

	var result: Dictionary = _generation_service.call(
		"queue_character_generation_with_strategy",
		_project,
		_template,
		profile,
		true,
		retry_count,
		strategy
	)
	if not bool(result.get("ok", false)):
		_status.text = str(
			result.get("error", "Could not queue validated character generation.")
		)
		if supplement_queued:
			_status.text += " Blueprint supplementary material is still queued independently."
		return

	var queued_ahead := int(result.get("queued_ahead", 0))
	var strategy_text := (
		"Safe Section Build"
		if strategy == STRATEGY_SAFE_SECTION
		else "Fast Full Card"
	)
	if supplement_queued:
		_status.text = (
			"Blueprint supplementary materialisation queued first; %s character generation is queued behind it. Interview/Q&A, Generation Components and the active template contract remain part of the validated pipeline."
			% strategy_text
		)
	elif not supplement_error.is_empty():
		_status.text = (
			"%s character generation queued%s. Blueprint supplementary material could not be queued: %s"
			% [
				strategy_text,
				" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "",
				supplement_error
			]
		)
	elif strategy == STRATEGY_SAFE_SECTION:
		_status.text = (
			"Safe Section Build queued%s. Each enabled Generation Output Group and standalone generatable field will use a fresh request; required missing components are repaired individually before the final validated preview."
			% (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
		)
	else:
		_status.text = (
			"Fast Full Card queued%s. This uses fewer provider requests but has a higher risk of incomplete initial output; the existing validation and bounded repair pipeline remains active."
			% (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
		)


func _on_job_failed(job_id: String, job_type: String, message: String) -> void:
	super._on_job_failed(job_id, job_type, message)
	if job_id != _last_generation_diagnostics_job_id_v01522 or _last_generation_diagnostics_v01522.is_empty():
		return
	if _generation_failure_window_v01522 == null:
		return
	var section := str(_last_generation_diagnostics_v01522.get("active_section", "")).strip_edges()
	var stage := str(_last_generation_diagnostics_v01522.get("failure_stage", "")).strip_edges()
	var text := message
	if not section.is_empty():
		text += "\n\nSection: %s" % section
	if not stage.is_empty():
		text += "\nStage: %s" % stage
	text += "\n\nThe failed request and raw provider response were preserved. Use View Diagnostics to inspect exactly what CCF sent, received, extracted, parsed and validated."
	_generation_failure_label_v01522.text = text
	_generation_failure_window_v01522.popup_centered(Vector2i(760, 320))


func _on_generation_diagnostics_available_v01522(
	job_id: String, _job_type: String, diagnostics: Dictionary
) -> void:
	_last_generation_diagnostics_job_id_v01522 = job_id
	_last_generation_diagnostics_v01522 = diagnostics.duplicate(true)


func _build_generation_diagnostics_ui_v01522() -> void:
	if _generation_diagnostics_window_v01522 != null:
		return
	_generation_diagnostics_window_v01522 = GENERATION_DIAGNOSTICS_WINDOW_V01522.new()
	add_child(_generation_diagnostics_window_v01522)

	_generation_failure_window_v01522 = Window.new()
	_generation_failure_window_v01522.visible = false
	_generation_failure_window_v01522.title = "Character Generation Failed"
	_generation_failure_window_v01522.size = Vector2i(760, 320)
	_generation_failure_window_v01522.min_size = Vector2i(620, 260)
	_generation_failure_window_v01522.force_native = true
	_generation_failure_window_v01522.transient = true
	_generation_failure_window_v01522.exclusive = false
	_generation_failure_window_v01522.close_requested.connect(_generation_failure_window_v01522.hide)
	add_child(_generation_failure_window_v01522)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_generation_failure_window_v01522.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "Generation failed"
	heading.add_theme_font_size_override("font_size", 22)
	root.add_child(heading)
	_generation_failure_label_v01522 = Label.new()
	_generation_failure_label_v01522.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_generation_failure_label_v01522.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_generation_failure_label_v01522)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var diagnostics_button := Button.new()
	diagnostics_button.text = "View Diagnostics…"
	diagnostics_button.pressed.connect(_show_last_generation_diagnostics_v01522)
	actions.add_child(diagnostics_button)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_generation_failure_window_v01522.hide)
	actions.add_child(close_button)


func _show_last_generation_diagnostics_v01522() -> void:
	if _generation_diagnostics_window_v01522 == null or _last_generation_diagnostics_v01522.is_empty():
		return
	_generation_failure_window_v01522.hide()
	_generation_diagnostics_window_v01522.call(
		"show_diagnostics", _last_generation_diagnostics_v01522
	)
