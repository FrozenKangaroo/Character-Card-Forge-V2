class_name CCFWorkspaceV0186View
extends "res://scripts/ui/workspace_v0185.gd"

const GENERATION_SERVICE_V0186 = preload(
	"res://scripts/services/generation_service_v0186.gd"
)
const COMPACT_DERIVATIVE_WINDOW_V0186 = preload(
	"res://scripts/ui/compact_derivative_window_v0186.gd"
)

var _compact_derivative_window_v0186: CCFCompactDerivativeWindowV0186
var _compact_derivative_button_v0186: Button


func _ready() -> void:
	super._ready()
	_build_compact_derivative_v0186()
	_install_compact_derivative_navigation_v0186()


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V0186.new() as CCFGenerationServiceV01526
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


func _build_compact_derivative_v0186() -> void:
	_compact_derivative_window_v0186 = COMPACT_DERIVATIVE_WINDOW_V0186.new()
	_compact_derivative_window_v0186.visible = false
	_compact_derivative_window_v0186.generation_requested_v0186.connect(
		_queue_compact_derivative_v0186
	)
	_compact_derivative_window_v0186.project_changed_v0186.connect(
		_on_inspection_project_changed_v0182
	)
	add_child(_compact_derivative_window_v0186)
	_compact_derivative_window_v0186.hide()


func _install_compact_derivative_navigation_v0186() -> void:
	var top := _first_flow_row()
	if top == null or _find_workspace_button("Create Compact/Lite Derivative…") != null:
		return
	_compact_derivative_button_v0186 = Button.new()
	_compact_derivative_button_v0186.text = "Create Compact/Lite Derivative…"
	_compact_derivative_button_v0186.tooltip_text = (
		"Create a separate shorter character from this finished card. "
		+ "The source remains unchanged and every proposed field is reviewed first."
	)
	_compact_derivative_button_v0186.pressed.connect(
		_open_compact_derivative_v0186
	)
	top.add_child(_compact_derivative_button_v0186)
	if _ai_review_button_v0183 != null:
		top.move_child(
			_compact_derivative_button_v0186,
			_ai_review_button_v0183.get_index() + 1
		)


func _open_compact_derivative_v0186() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a finished character before creating a compact derivative."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_compact_derivative_window_v0186.open_for_character(
		_project_container, _active_character_id
	)
	_status.text = "Compact/Lite Derivative opened. The source character will not be changed."


func _queue_compact_derivative_v0186(options: Dictionary) -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var service := _generation_service as CCFGenerationServiceV0186
	if service == null:
		_status.text = "The v0.18.6 compact-derivative service is unavailable."
		return
	var result := service.queue_compact_derivative_v0186(
		_project_container,
		_active_character_id,
		options,
		profile,
		int(_generation_settings().get("retry_count", 1))
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue compact generation."))
		return
	_compact_derivative_window_v0186.begin_generation(
		str(result.get("job_id", ""))
	)
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "Compact preview queued%s." % (
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else ""
	)


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	if job_type == "compact_derivative" and _compact_derivative_window_v0186 != null:
		if (
			str(metadata.get("project_id", ""))
			!= str(_project_container.get("project_id", ""))
			or str(metadata.get("character_id", "")) != _active_character_id
		):
			_compact_derivative_window_v0186.handle_job_failed(
				job_id,
				"Compact result discarded because its source project or character is no longer active."
			)
			_status.text = "Compact result discarded because its source is no longer active."
			return
		if _compact_derivative_window_v0186.handle_job_completed(
			job_id, data, metadata
		):
			_status.text = "Compact preview finished. Review every field before creating the derivative."
			return
	super._on_job_completed(job_id, job_type, data, metadata)


func _on_job_failed(job_id: String, job_type: String, message: String) -> void:
	if (
		job_type == "compact_derivative"
		and _compact_derivative_window_v0186 != null
		and _compact_derivative_window_v0186.handle_job_failed(job_id, message)
	):
		_status.text = message
		return
	super._on_job_failed(job_id, job_type, message)


func _on_job_cancelled(job_id: String, job_type: String) -> void:
	if (
		job_type == "compact_derivative"
		and _compact_derivative_window_v0186 != null
		and _compact_derivative_window_v0186.handle_job_cancelled(job_id)
	):
		_status.text = "Compact preview generation cancelled. Nothing changed."
		return
	super._on_job_cancelled(job_id, job_type)


func _update_project_level_window_contexts() -> void:
	super._update_project_level_window_contexts()
	if (
		_compact_derivative_window_v0186 != null
		and _compact_derivative_window_v0186.visible
		and _compact_derivative_window_v0186.owns_project(
			str(_project_container.get("project_id", ""))
		)
	):
		_compact_derivative_window_v0186.update_project_context(
			_project_container, _active_character_id
		)


func _close_tool_windows_for_project_change() -> void:
	if (
		_compact_derivative_window_v0186 != null
		and _compact_derivative_window_v0186.visible
	):
		_compact_derivative_window_v0186.hide()
	super._close_tool_windows_for_project_change()


func compact_derivative_capabilities_v0186() -> Dictionary:
	return CCFCompactDerivativeServiceV0186.capabilities()
