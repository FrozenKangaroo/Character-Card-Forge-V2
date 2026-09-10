class_name CCFWorkspaceV0183View
extends "res://scripts/ui/workspace_v0182.gd"

const GENERATION_SERVICE_V0183 = preload(
	"res://scripts/services/generation_service_v0183.gd"
)
const AI_REVIEW_WINDOW_V0183 = preload(
	"res://scripts/ui/ai_review_window_v0183.gd"
)

var _ai_review_window_v0183: CCFAIReviewWindowV0183
var _ai_review_button_v0183: Button


func _ready() -> void:
	super._ready()
	_build_ai_review_v0183()
	_install_ai_review_navigation_v0183()


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V0183.new() as CCFGenerationServiceV01526
	add_child(service)
	service.configure_scheduler_v01526(
		_ai_scheduler_v01526, worker_id, worker_label, job_number_base
	)
	service.job_started.connect(_on_job_started)
	service.job_completed.connect(_on_job_completed)
	service.job_failed.connect(_on_job_failed)
	service.job_cancelled.connect(_on_job_cancelled)
	service.queue_changed.connect(_on_worker_queue_changed_v01526)
	service.diagnostics_available.connect(
		_on_generation_diagnostics_available_v01522
	)
	return service


func _build_ai_review_v0183() -> void:
	_ai_review_window_v0183 = AI_REVIEW_WINDOW_V0183.new()
	_ai_review_window_v0183.visible = false
	_ai_review_window_v0183.review_requested_v0183.connect(
		_queue_ai_review_v0183
	)
	_ai_review_window_v0183.project_changed_v0183.connect(
		_on_inspection_project_changed_v0182
	)
	add_child(_ai_review_window_v0183)
	_ai_review_window_v0183.hide()


func _install_ai_review_navigation_v0183() -> void:
	var top := _first_flow_row()
	if top == null or _find_workspace_button("AI Review") != null:
		return
	_ai_review_button_v0183 = Button.new()
	_ai_review_button_v0183.text = "AI Review"
	_ai_review_button_v0183.tooltip_text = (
		"Run an optional advisory consistency review, inspect the visible rubric and "
		+ "approve, reject or edit every proposed field before applying it."
	)
	_ai_review_button_v0183.pressed.connect(_open_ai_review_v0183)
	top.add_child(_ai_review_button_v0183)
	if _card_inspector_button_v0182 != null:
		top.move_child(
			_ai_review_button_v0183, _card_inspector_button_v0182.get_index() + 1
		)


func _open_ai_review_v0183() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a character before using AI Review."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_ai_review_window_v0183.open_for_character(
		_project_container, _active_character_id
	)
	_status.text = "AI Review opened. It runs only when you explicitly request it."


func _queue_ai_review_v0183() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var service := _generation_service as CCFGenerationServiceV0183
	if service == null:
		_status.text = "The v0.18.3 AI Review service is unavailable."
		return
	var result := service.queue_ai_review_v0183(
		_project_container,
		_active_character_id,
		profile,
		int(_generation_settings().get("retry_count", 1))
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue AI Review."))
		return
	_ai_review_window_v0183.begin_review(str(result.get("job_id", "")))
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "AI Review queued%s." % (
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else ""
	)


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	if job_type == "ai_review" and _ai_review_window_v0183 != null:
		if (
			str(metadata.get("project_id", ""))
			!= str(_project_container.get("project_id", ""))
			or str(metadata.get("character_id", "")) != _active_character_id
		):
			_ai_review_window_v0183.handle_job_failed(
				job_id,
				"AI Review result discarded because its originating project or character is no longer active."
			)
			_status.text = "AI Review result discarded because its originating project or character is no longer active."
			return
		if _ai_review_window_v0183.handle_job_completed(job_id, data, metadata):
			_status.text = "AI Review finished. Review the complete proposal set before applying anything."
			return
	super._on_job_completed(job_id, job_type, data, metadata)


func _on_job_failed(job_id: String, job_type: String, message: String) -> void:
	if job_type == "ai_review" and _ai_review_window_v0183 != null:
		if _ai_review_window_v0183.handle_job_failed(job_id, message):
			_status.text = message
			return
	super._on_job_failed(job_id, job_type, message)


func _on_job_cancelled(job_id: String, job_type: String) -> void:
	if job_type == "ai_review" and _ai_review_window_v0183 != null:
		if _ai_review_window_v0183.handle_job_cancelled(job_id):
			_status.text = "AI Review cancelled. No card fields changed."
			return
	super._on_job_cancelled(job_id, job_type)


func _update_project_level_window_contexts() -> void:
	super._update_project_level_window_contexts()
	if (
		_ai_review_window_v0183 != null
		and _ai_review_window_v0183.visible
		and _ai_review_window_v0183.owns_project(
			str(_project_container.get("project_id", ""))
		)
	):
		_ai_review_window_v0183.update_project_context(
			_project_container, _active_character_id
		)


func _close_tool_windows_for_project_change() -> void:
	if _ai_review_window_v0183 != null and _ai_review_window_v0183.visible:
		_ai_review_window_v0183.hide()
	super._close_tool_windows_for_project_change()


func ai_review_capabilities_v0183() -> Dictionary:
	return CCFAIReviewServiceV0183.capabilities()
