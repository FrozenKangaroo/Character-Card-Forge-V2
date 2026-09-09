class_name CCFWorkspaceV0175View
extends CCFWorkspaceV0174View

const IMPORT_EXPORT_WINDOW_V0175 = preload(
	"res://scripts/ui/import_export_window_v0175.gd"
)
const GENERATION_SERVICE_V0175 = preload(
	"res://scripts/services/generation_service_v0175.gd"
)


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V0175.new() as CCFGenerationServiceV01526
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


func _show_generation_preview(
	generated: Dictionary, metadata: Dictionary, preview_title: String
) -> void:
	var normalised_metadata := _normalise_front_porch_preview_metadata_v0175(
		metadata
	)
	if _show_unchanged_front_porch_suggestion_v0175(
		generated, normalised_metadata, preview_title
	):
		return
	super._show_generation_preview(generated, normalised_metadata, preview_title)


func _normalise_front_porch_preview_metadata_v0175(
	metadata: Dictionary
) -> Dictionary:
	var result := metadata.duplicate(true)
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
		if str(field.get("type", "")) == "integer_tags":
			# The shared preview understands tag arrays as a one-line editor. The
			# canonical Front Porch field still performs integer/range validation
			# when the proposal is applied.
			field["type"] = "tags"
			field["front_porch_source_type"] = "integer_tags"
		preview_fields[index] = field
	result["preview_fields"] = preview_fields
	return result


func _show_unchanged_front_porch_suggestion_v0175(
	generated: Dictionary, metadata: Dictionary, preview_title: String
) -> bool:
	if int(metadata.get("front_porch_generation_contract", 0)) != 1:
		return false
	var field_ids_value: Variant = metadata.get("field_ids", [])
	if not field_ids_value is Array or field_ids_value.size() != 1:
		return false
	var field_id := str(field_ids_value[0])
	if not generated.has(field_id):
		return false
	var field: Dictionary = {}
	var preview_fields_value: Variant = metadata.get("preview_fields", [])
	if preview_fields_value is Array:
		for field_value in preview_fields_value:
			if field_value is Dictionary and str(field_value.get("id", "")) == field_id:
				field = (field_value as Dictionary).duplicate(true)
				break
	if field.is_empty():
		return false
	var default_value: Variant = ""
	if str(field.get("type", "")) == "tags":
		default_value = []
	var current_value: Variant = CCFStorageService.get_value_at_path(
		_project, str(field.get("path", "")), default_value
	)
	var proposed_value: Variant = generated.get(field_id)
	if not _values_equal(current_value, proposed_value):
		return false
	_clear_children(_preview_result_box)
	_preview_rows.clear()
	_preview_metadata = metadata.duplicate(true)
	_preview_job_type = preview_title
	_add_preview_row(field, current_value, proposed_value)
	_preview_summary.text = (
		"%s completed, but the proposed value matches the current value. "
		+ "You can edit it here before applying, discard it, or ask again."
	) % preview_title
	_preview_window.title = preview_title
	_preview_project_id = str(metadata.get("project_id", _project.get("project_id", "")))
	_preview_window_has_been_shown = true
	CCFToolWindowStateService.show_window(
		_preview_window, "generation_preview", Vector2i(980, 720)
	)
	return true


func _build_import_export_window() -> void:
	_import_export_window = IMPORT_EXPORT_WINDOW_V0175.new()
	_import_export_window.visible = false
	_import_export_window.project_refresh_requested.connect(
		_refresh_import_export_project_context
	)
	_import_export_window.project_imported.connect(_on_external_project_imported)
	_import_export_window.gallery_project_changed_v0175.connect(
		_on_front_porch_gallery_project_changed_v0175
	)
	add_child(_import_export_window)
	_import_export_window.hide()


func _on_front_porch_gallery_project_changed_v0175(
	updated_project: Dictionary
) -> void:
	if (
		str(updated_project.get("project_id", ""))
		!= str(_project_container.get("project_id", ""))
	):
		return
	_project_container = updated_project.duplicate(true)
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	_dirty = false
	_update_header()
	_update_project_level_window_contexts()
	project_saved.emit(_project_container.duplicate(true))
	_status.text = "Front Porch avatar gallery updated and saved."


func front_porch_avatar_gallery_capabilities_v0175() -> Dictionary:
	if (
		_import_export_window != null
		and _import_export_window.has_method(
			"front_porch_avatar_gallery_capabilities_v0175"
		)
	):
		return _import_export_window.call(
			"front_porch_avatar_gallery_capabilities_v0175"
		) as Dictionary
	return {
		"manual_image_import": false,
		"image_studio_sources": false,
		"front_porch_api_install": false,
		"raw_database_writes": false
	}
