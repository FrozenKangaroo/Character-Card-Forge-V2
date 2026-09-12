class_name CCFWorkspaceV0190View
extends "res://scripts/ui/workspace_v0186.gd"

const GENERATION_SERVICE_V0190 = preload(
	"res://scripts/services/generation_service_v0190.gd"
)
const RICH_AUTHORING_WINDOW_V0190 = preload(
	"res://scripts/ui/rich_authoring_window_v0190.gd"
)
const CARD_WORKFLOW_WINDOW_V0190 = preload(
	"res://scripts/ui/card_workflow_window_v0190.gd"
)
const IMPORT_EXPORT_WINDOW_V0190 = preload(
	"res://scripts/ui/import_export_window_v0190.gd"
)

var _rich_authoring_window_v0190: CCFRichAuthoringWindowV0190
var _rich_authoring_button_v0190: Button


func _ready() -> void:
	super._ready()
	_build_rich_authoring_v0190()
	_install_rich_authoring_navigation_v0190()


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V0190.new() as CCFGenerationServiceV01526
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


func _build_card_workflow_window() -> void:
	_card_workflow_window = CARD_WORKFLOW_WINDOW_V0190.new()
	_card_workflow_window.visible = false
	_card_workflow_window.set_generation_service(_generation_service)
	_card_workflow_window.project_refresh_requested.connect(
		_refresh_card_workflow_project_context
	)
	_card_workflow_window.workflow_saved.connect(_on_card_workflow_saved)
	_card_workflow_window.workflow_deleted.connect(_on_card_workflow_deleted)
	add_child(_card_workflow_window)
	_card_workflow_window.hide()


func _build_import_export_window() -> void:
	_import_export_window = IMPORT_EXPORT_WINDOW_V0190.new()
	_import_export_window.visible = false
	_import_export_window.project_refresh_requested.connect(
		_refresh_import_export_project_context
	)
	_import_export_window.project_imported.connect(_on_external_project_imported)
	_import_export_window.gallery_project_changed_v0175.connect(
		_on_front_porch_gallery_project_changed_v0175
	)
	_import_export_window.world_project_changed_v0180.connect(
		_on_front_porch_world_project_changed_v0180
	)
	_import_export_window.inspection_project_changed_v0182.connect(
		_on_inspection_project_changed_v0182
	)
	_import_export_window.front_porch_sync_project_changed_v0185.connect(
		_on_front_porch_sync_project_changed_v0185
	)
	add_child(_import_export_window)
	_import_export_window.hide()


func _request_remove_active_character() -> void:
	if _project_container.get("characters", []).size() <= 1:
		_status.text = "A project must contain at least one character."
		return
	var character_record := CCFStorageService.get_character(
		_project_container, _active_character_id
	)
	var prompt := "Remove %s from this project? This removes the character's project data when you next save." % CCFStorageService.character_display_name(character_record)
	var warnings := CCFRichAuthoringServiceV0190.deletion_warnings(
		_project_container, "character", _active_character_id
	)
	if not warnings.is_empty():
		prompt += "\n\nReferenced content warning:\n• " + "\n• ".join(warnings)
	_delete_character_confirm.dialog_text = prompt
	_delete_character_confirm.popup_centered()


func _build_rich_authoring_v0190() -> void:
	_rich_authoring_window_v0190 = RICH_AUTHORING_WINDOW_V0190.new()
	_rich_authoring_window_v0190.visible = false
	_rich_authoring_window_v0190.project_changed_v0190.connect(
		_on_rich_authoring_project_changed_v0190
	)
	_rich_authoring_window_v0190.project_created_v0190.connect(
		_on_external_project_imported
	)
	_rich_authoring_window_v0190.split_generation_requested_v0190.connect(
		_queue_split_generation_v0190
	)
	add_child(_rich_authoring_window_v0190)
	_rich_authoring_window_v0190.hide()


func _install_rich_authoring_navigation_v0190() -> void:
	var top := _first_flow_row()
	if top == null or _find_workspace_button("Rich Authoring") != null:
		return
	_rich_authoring_button_v0190 = Button.new()
	_rich_authoring_button_v0190.text = "Rich Authoring"
	_rich_authoring_button_v0190.tooltip_text = (
		"Manage scenario presets, weighted greetings, ensemble creation, split sets, "
		+ "shared worlds, dependencies, lineage and private export mappings."
	)
	_rich_authoring_button_v0190.pressed.connect(_open_rich_authoring_v0190)
	top.add_child(_rich_authoring_button_v0190)
	if _compact_derivative_button_v0186 != null:
		top.move_child(
			_rich_authoring_button_v0190,
			_compact_derivative_button_v0186.get_index() + 1
		)


func _open_rich_authoring_v0190() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a project before using Rich Authoring."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_rich_authoring_window_v0190.open_for_project(
		_project_container, _active_character_id
	)
	_status.text = "Rich Authoring opened. All generation and materialisation remain review-first."


func _on_rich_authoring_project_changed_v0190(
	updated_project: Dictionary,
	active_character_id: String,
	message_text: String
) -> void:
	_on_inspection_project_changed_v0182(
		updated_project, active_character_id, message_text
	)


func _queue_split_generation_v0190(
	batch_id: String, retry_character_ids: Array[String]
) -> void:
	if _project_container.is_empty():
		return
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var service := _generation_service as CCFGenerationServiceV0190
	if service == null:
		_status.text = "The v0.19.0 split-generation service is unavailable."
		return
	var result := service.queue_split_character_set_v0190(
		_project_container,
		batch_id,
		retry_character_ids,
		profile,
		int(_generation_settings().get("retry_count", 1))
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue split generation."))
		_rich_authoring_window_v0190.handle_split_failed(_status.text)
		return
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "Split-set generation queued%s." % (
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else ""
	)


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	if (
		job_type == "split_character_set_v0190"
		and _rich_authoring_window_v0190 != null
	):
		if _rich_authoring_window_v0190.handle_split_completed(
			job_id, data, metadata
		):
			_status.text = "Split character set completed. Review and save every independent member."
			return
	super._on_job_completed(job_id, job_type, data, metadata)


func _on_job_failed(job_id: String, job_type: String, message: String) -> void:
	if job_type == "split_character_set_v0190" and _rich_authoring_window_v0190 != null:
		_rich_authoring_window_v0190.handle_split_failed(message)
		_status.text = message
		return
	super._on_job_failed(job_id, job_type, message)


func _on_job_cancelled(job_id: String, job_type: String) -> void:
	if job_type == "split_character_set_v0190" and _rich_authoring_window_v0190 != null:
		_rich_authoring_window_v0190.handle_split_failed(
			"Split character set generation cancelled. Seeded members remain recoverable."
		)
		_status.text = "Split generation cancelled; seeded members were retained."
		return
	super._on_job_cancelled(job_id, job_type)


func _update_project_level_window_contexts() -> void:
	super._update_project_level_window_contexts()
	if (
		_rich_authoring_window_v0190 != null
		and _rich_authoring_window_v0190.visible
		and _rich_authoring_window_v0190.owns_project(
			str(_project_container.get("project_id", ""))
		)
	):
		_rich_authoring_window_v0190.update_project_context(
			_project_container, _active_character_id
		)


func _close_tool_windows_for_project_change() -> void:
	if _rich_authoring_window_v0190 != null and _rich_authoring_window_v0190.visible:
		_rich_authoring_window_v0190.hide()
	super._close_tool_windows_for_project_change()


func rich_authoring_capabilities_v0190() -> Dictionary:
	return CCFRichAuthoringServiceV0190.capabilities()
