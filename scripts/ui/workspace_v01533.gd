class_name CCFWorkspaceV01533View
extends "res://scripts/ui/workspace_v01532.gd"

const GENERATION_SERVICE_V01533 = preload(
	"res://scripts/services/generation_service_v01533.gd"
)
const CHARACTER_COLLABORATOR_WINDOW_V01533 = preload(
	"res://scripts/ui/character_collaborator_window_v01533.gd"
)
const IDEA_GENERATOR_V01533 = preload(
	"res://scripts/ui/idea_generator_window_v01533.gd"
)


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V01533.new()
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


func _build_concept_studio() -> void:
	_idea_generator_v01532 = IDEA_GENERATOR_V01533.new()
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


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V01533.new() as CCFGenerationServiceV01526
	add_child(service)
	service.configure_scheduler_v01526(
		_ai_scheduler_v01526, worker_id, worker_label, job_number_base
	)
	service.job_started.connect(_on_job_started)
	service.job_completed.connect(_on_job_completed)
	service.job_failed.connect(_on_job_failed)
	service.job_cancelled.connect(_on_job_cancelled)
	service.queue_changed.connect(_on_worker_queue_changed_v01526)
	service.diagnostics_available.connect(_on_generation_diagnostics_available_v01522)
	return service


func open_collaborator_with_source_v01533(source: Dictionary) -> Dictionary:
	if _project_container.is_empty():
		return {"ok": false, "error": "Open or create a Character Project first."}
	if not _ensure_collaborator_generation_service_v015():
		return {"ok": false, "error": "Character Collaborator could not activate its AI service."}
	if (
		_character_collaborator_window == null
		or not _character_collaborator_window.has_method("open_with_source_v01533")
	):
		return {"ok": false, "error": "The active Character Collaborator does not support structured source context."}

	_commit_active_character_to_container()
	_capture_project_name()
	_character_collaborator_window.set_generation_service(
		_collaborator_service_v01526
	)
	var result_value: Variant = _character_collaborator_window.call(
		"open_with_source_v01533",
		_project_container,
		_settings,
		_active_character_id,
		_template,
		source
	)
	var result: Dictionary = result_value if result_value is Dictionary else {
		"ok": false,
		"error": "Character Collaborator did not return a source-handoff result."
	}
	if bool(result.get("ok", false)):
		if _idea_generator_v01532 != null:
			_idea_generator_v01532.hide()
		_status.text = "Character Collaborator opened with a read-only structured source snapshot. Existing source facts remain authoritative unless you explicitly change or branch them."
	else:
		_status.text = str(result.get("error", "Could not open Character Collaborator from this source."))
	return result


func collaborator_source_capabilities_v01533() -> Dictionary:
	return {
		"format_version": 1,
		"generated_idea_handoff": true,
		"saved_idea_handoff": true,
		"existing_character_source_schema": true,
		"existing_character_workspace_action": false,
		"multi_source": false
	}


func _on_collaborator_source_requested_v01533(source: Dictionary) -> void:
	open_collaborator_with_source_v01533(source)
