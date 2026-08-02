class_name CCFWorkspaceV01513View
extends "res://scripts/ui/workspace_v01512.gd"

const GENERATION_SERVICE_V01513 = preload("res://scripts/services/generation_service_v01513.gd")
const CHARACTER_COLLABORATOR_WINDOW_V01513 = preload("res://scripts/ui/character_collaborator_window_v01513.gd")


func _install_generation_service_v015() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V01513:
		return
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
		if previous_service.get_parent() == self:
			remove_child(previous_service)
		previous_service.queue_free()

	var upgraded: CCFGenerationService = GENERATION_SERVICE_V01513.new()
	add_child(upgraded)
	upgraded.job_started.connect(_on_job_started)
	upgraded.job_completed.connect(_on_job_completed)
	upgraded.job_failed.connect(_on_job_failed)
	upgraded.job_cancelled.connect(_on_job_cancelled)
	upgraded.queue_changed.connect(_on_queue_changed)
	_generation_service = upgraded
	if _builder_window != null:
		_builder_window.set_generation_service(_generation_service)
	if _attachment_window != null:
		_attachment_window.set_generation_service(_generation_service)
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(_generation_service)
	_wire_ai_idea_controller_to_current_service()


func _ensure_collaborator_generation_service_v015() -> bool:
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01513:
		_install_generation_service_v015()
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01513:
		_status.text = "Character Collaborator could not activate the v0.15.13 generation service."
		return false
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(_generation_service)
	return true


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V01513.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(_on_collaborator_sessions_changed_v015)
	_character_collaborator_window.character_draft_ready.connect(_on_collaborator_character_draft_ready_v015)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()


func _show_generation_preview(
	generated: Dictionary, metadata: Dictionary, preview_title: String
) -> void:
	# Full Workspace synthesis is an editorial materialisation pass, not a
	# difference detector. Show every returned template field so authors can
	# review the complete result even when a strong existing field was preserved
	# verbatim. Other generation modes retain the normal changed-fields-only UX.
	if not bool(metadata.get("preview_include_unchanged", false)):
		super._show_generation_preview(generated, metadata, preview_title)
		return

	_clear_children(_preview_result_box)
	_preview_rows.clear()
	_preview_metadata = metadata.duplicate(true)
	_preview_job_type = preview_title

	var proposed_count := 0
	var known_ids: Dictionary = {}
	var allowed_ids: Dictionary = {}
	var raw_allowed_ids = metadata.get("field_ids", [])
	if raw_allowed_ids is Array:
		for allowed_id in raw_allowed_ids:
			allowed_ids[str(allowed_id)] = true
	var restrict_to_allowed := not allowed_ids.is_empty()
	var scoped_ignored_count := 0
	var missing_count := 0
	var preview_fields: Array = []
	var preview_field_ids: Dictionary = {}
	var raw_preview_fields = metadata.get("preview_fields", [])
	if raw_preview_fields is Array:
		for raw_preview_field in raw_preview_fields:
			if not raw_preview_field is Dictionary:
				continue
			var custom_field_id := str(raw_preview_field.get("id", ""))
			if custom_field_id.is_empty() or preview_field_ids.has(custom_field_id):
				continue
			preview_fields.append(raw_preview_field.duplicate(true))
			preview_field_ids[custom_field_id] = true
	for template_field in CCFTemplateService.generation_fields(_template):
		if not template_field is Dictionary:
			continue
		var template_field_id := str(template_field.get("id", ""))
		if preview_field_ids.has(template_field_id):
			continue
		preview_fields.append(template_field.duplicate(true))
		preview_field_ids[template_field_id] = true

	for field in preview_fields:
		var field_id := str(field.get("id", ""))
		known_ids[field_id] = true
		if restrict_to_allowed and not allowed_ids.has(field_id):
			continue
		if not generated.has(field_id):
			missing_count += 1
			continue
		var path := str(field.get("path", ""))
		var current_value = CCFStorageService.get_value_at_path(
			_project, path, _default_value_for_type(str(field.get("type", "multiline")))
		)
		var proposed_value = generated.get(field_id)
		proposed_count += 1
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
		if restrict_to_allowed and not allowed_ids.has(key_text):
			scoped_ignored_count += 1
			continue
		if str(policy.get("unexpected_fields", "ignore")) == "store":
			var extra_field := _extra_generated_field(key_text, generated.get(generated_key))
			var current_extra = CCFStorageService.get_value_at_path(
				_project,
				str(extra_field.get("path", "")),
				_default_value_for_type(str(extra_field.get("type", "multiline")))
			)
			_add_preview_row(extra_field, current_extra, generated.get(generated_key))
			proposed_count += 1
			stored_extra_count += 1
		else:
			ignored_extra_count += 1

	if proposed_count == 0:
		_status.text = "Full character synthesis completed without any usable template fields."
		if missing_count > 0:
			_status.text += " The model omitted %d required synthesis field(s)." % missing_count
		return

	var policy_note := ""
	if missing_count > 0:
		policy_note += " Warning: the model omitted %d requested field(s); the returned fields are still available for review." % missing_count
	if stored_extra_count > 0:
		policy_note += " %d unexpected field(s) can be stored under character.custom.generated_extra." % stored_extra_count
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
		"%s returned %d template field(s). Full synthesis shows every returned field, including preserved values, so you can review the complete materialised character before applying it.%s"
		% [preview_title, proposed_count, policy_note]
	)
	_preview_window.title = preview_title
	_preview_project_id = str(metadata.get("project_id", _project.get("project_id", "")))
	_preview_window_has_been_shown = true
	CCFToolWindowStateService.show_window(_preview_window, "generation_preview", Vector2i(980, 720))
