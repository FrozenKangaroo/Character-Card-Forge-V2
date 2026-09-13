class_name CCFImageGenerationWindowV0193
extends CCFImageGenerationWindowV0175

const EXPRESSION_SERVICE = preload(
	"res://scripts/services/expression_set_service_v0193.gd"
)
const EXPRESSION_WINDOW = preload(
	"res://scripts/ui/expression_set_window_v0193.gd"
)

var _expression_set_button_v0193: Button
var _expression_window_v0193: CCFExpressionSetWindowV0193
var _expression_batch_id_v0193 := ""
var _expression_label_v0193 := ""
var _expression_character_id_v0193 := ""
var _expression_sequence_active_v0193 := false


func _ready() -> void:
	super._ready()
	ensure_expression_set_surface_v0193()


func _build_ui() -> void:
	super._build_ui()
	_install_expression_set_surface_v0193()


func ensure_expression_set_surface_v0193() -> void:
	_install_expression_set_surface_v0193()
	_refresh_expression_context_v0193()


func expression_set_capabilities_v0193() -> Dictionary:
	return EXPRESSION_SERVICE.capabilities()


func expression_set_surface_ready_v0193() -> bool:
	return (
		_expression_set_button_v0193 != null
		and is_instance_valid(_expression_set_button_v0193)
		and _expression_set_button_v0193.is_inside_tree()
		and _expression_window_v0193 != null
		and is_instance_valid(_expression_window_v0193)
		and not _expression_window_v0193.visible
	)


func _install_expression_set_surface_v0193() -> void:
	if (
		_expression_set_button_v0193 != null
		and is_instance_valid(_expression_set_button_v0193)
		and _expression_set_button_v0193.is_inside_tree()
		and _expression_window_v0193 != null
		and is_instance_valid(_expression_window_v0193)
	):
		return
	if _gallery == null or _gallery.get_parent() == null:
		return
	if _expression_set_button_v0193 != null and is_instance_valid(_expression_set_button_v0193):
		_expression_set_button_v0193.queue_free()
	_expression_set_button_v0193 = Button.new()
	_expression_set_button_v0193.name = "GenerateExpressionSetV0193"
	_expression_set_button_v0193.text = "Generate Expression Set…"
	_expression_set_button_v0193.tooltip_text = "Generate selected Front Porch expressions through the managed Image Studio queue, then review each result before adding it to Avatar Gallery."
	_expression_set_button_v0193.pressed.connect(_open_expression_set_v0193)
	_gallery.get_parent().add_child(_expression_set_button_v0193)
	_gallery.get_parent().move_child(_expression_set_button_v0193, _gallery.get_index() + 1)
	if _expression_window_v0193 == null or not is_instance_valid(_expression_window_v0193):
		_expression_window_v0193 = EXPRESSION_WINDOW.new()
		_expression_window_v0193.visible = false
		_expression_window_v0193.transient = true
		_expression_window_v0193.exclusive = false
		_expression_window_v0193.create_requested.connect(_create_expression_batch_v0193)
		_expression_window_v0193.resume_requested.connect(_resume_expression_batch_v0193)
		_expression_window_v0193.pause_requested.connect(_pause_expression_batch_v0193)
		_expression_window_v0193.retry_requested.connect(_retry_expression_item_v0193)
		_expression_window_v0193.accept_requested.connect(_accept_expression_item_v0193)
		add_child(_expression_window_v0193)
		_expression_window_v0193.hide()


func _open_expression_set_v0193() -> void:
	if _project.is_empty() or _active_character_id.is_empty():
		_status.text = "Select a saved project and character first."
		return
	_expression_window_v0193.open_for_context(
		_project, _active_character_id, _baseline_availability_v0193()
	)


func _create_expression_batch_v0193(labels: Array, baseline_mode: String) -> void:
	if _image_service.is_active() or _expression_sequence_active_v0193:
		_status.text = "Wait for the current Image Studio job to finish before starting an expression set."
		return
	var baseline_result := _baseline_for_mode_v0193(baseline_mode)
	if not bool(baseline_result.get("ok", false)):
		_status.text = str(baseline_result.get("error", "The selected identity baseline is unavailable."))
		return
	var options := _current_generation_options("expression_set", "")
	options["batch_size"] = 1
	options.merge(baseline_result.get("options", {}), true)
	var snapshot := CCFImageResultWorkflowServiceV01610.execution_snapshot(
		_selected_profile(), _model_edit.text.strip_edges(), _image_size_edit.text.strip_edges(),
		_selected_prompt_style(), _prompt_edit.text, _negative_prompt_edit.text, options
	)
	var creation := EXPRESSION_SERVICE.create_batch(
		_project, _active_character_id, labels,
		baseline_result.get("baseline", {}), snapshot
	)
	if not bool(creation.get("ok", false)):
		_status.text = str(creation.get("error", "Could not create the expression batch."))
		return
	_project = (creation.get("project", {}) as Dictionary).duplicate(true)
	_expression_batch_id_v0193 = str((creation.get("batch", {}) as Dictionary).get("batch_id", ""))
	_expression_character_id_v0193 = _active_character_id
	_expression_sequence_active_v0193 = true
	if not _save_expression_project_v0193("Created an expression batch. Starting the first queued expression…"):
		_expression_sequence_active_v0193 = false
		return
	call_deferred("_start_next_expression_v0193")


func _start_next_expression_v0193() -> void:
	if not _expression_sequence_active_v0193 or _image_service.is_active():
		return
	var batch := EXPRESSION_SERVICE.batch_by_id(
		_project, _expression_character_id_v0193, _expression_batch_id_v0193
	)
	if batch.is_empty() or bool(batch.get("paused", false)):
		_expression_sequence_active_v0193 = false
		_refresh_expression_context_v0193()
		return
	var item := EXPRESSION_SERVICE.next_queued_item(batch)
	if item.is_empty():
		_expression_sequence_active_v0193 = false
		_status.text = "Expression batch generation finished. Review and accept each successful result individually."
		_refresh_expression_context_v0193()
		return
	_expression_label_v0193 = str(item.get("label", ""))
	var marked := EXPRESSION_SERVICE.mark_generating(
		_project, _expression_character_id_v0193, _expression_batch_id_v0193, _expression_label_v0193
	)
	if not _apply_expression_mutation_v0193(marked):
		_expression_sequence_active_v0193 = false
		return
	batch = EXPRESSION_SERVICE.batch_by_id(_project, _expression_character_id_v0193, _expression_batch_id_v0193)
	var snapshot_value: Variant = batch.get("execution_snapshot", {})
	var snapshot: Dictionary = snapshot_value if snapshot_value is Dictionary else {}
	var profile := _expression_profile_v0193(str(snapshot.get("profile_id", "")))
	if profile.is_empty():
		var missing_profile := EXPRESSION_SERVICE.mark_failed(
			_project, _expression_character_id_v0193, _expression_batch_id_v0193,
			_expression_label_v0193,
			"The Image Generation Profile used to create this batch no longer exists. Choose current settings and start a new batch."
		)
		_apply_expression_mutation_v0193(missing_profile)
		_apply_expression_mutation_v0193(EXPRESSION_SERVICE.set_paused(
			_project, _expression_character_id_v0193, _expression_batch_id_v0193, true
		))
		_expression_sequence_active_v0193 = false
		_expression_label_v0193 = ""
		return
	var options := _options_from_expression_snapshot_v0193(snapshot)
	var generation := _image_service.generate(
		str(_project.get("project_id", "")), _expression_character_id_v0193, profile,
		str(item.get("prompt", "")), str(snapshot.get("negative_prompt", "")),
		str(snapshot.get("size", "1024x1024")), str(snapshot.get("prompt_style", "auto")),
		str(snapshot.get("model", "")), options
	)
	if not bool(generation.get("ok", false)):
		var failure := EXPRESSION_SERVICE.mark_failed(
			_project, _expression_character_id_v0193, _expression_batch_id_v0193,
			_expression_label_v0193, str(generation.get("error", "Could not start generation."))
		)
		_apply_expression_mutation_v0193(failure)
		call_deferred("_start_next_expression_v0193")


func _on_generation_started() -> void:
	super._on_generation_started()
	if _expression_sequence_active_v0193 and not _expression_label_v0193.is_empty():
		_status.text = "Generating the %s expression through the managed Image Studio queue…" % _expression_label_v0193


func _on_generation_batch_completed(records: Array) -> void:
	var expression_was_active := _expression_sequence_active_v0193 and not _expression_label_v0193.is_empty()
	var completed_label := _expression_label_v0193
	super._on_generation_batch_completed(records)
	if not expression_was_active:
		return
	if records.is_empty() or not records[0] is Dictionary:
		var empty_failure := EXPRESSION_SERVICE.mark_failed(
			_project, _expression_character_id_v0193, _expression_batch_id_v0193,
			completed_label, "The provider completed without a reviewable image record."
		)
		_apply_expression_mutation_v0193(empty_failure)
	else:
		var attached := EXPRESSION_SERVICE.attach_result(
			_project, _expression_character_id_v0193, _expression_batch_id_v0193,
			completed_label, (records[0] as Dictionary).duplicate(true)
		)
		_apply_expression_mutation_v0193(attached)
	_expression_label_v0193 = ""
	call_deferred("_start_next_expression_v0193")


func _on_generation_failed(message_text: String) -> void:
	var expression_was_active := _expression_sequence_active_v0193 and not _expression_label_v0193.is_empty()
	var failed_label := _expression_label_v0193
	super._on_generation_failed(message_text)
	if not expression_was_active:
		return
	var failure := EXPRESSION_SERVICE.mark_failed(
		_project, _expression_character_id_v0193, _expression_batch_id_v0193,
		failed_label, message_text
	)
	_apply_expression_mutation_v0193(failure)
	_expression_label_v0193 = ""
	call_deferred("_start_next_expression_v0193")


func _on_generation_cancelled() -> void:
	var expression_was_active := _expression_sequence_active_v0193 and not _expression_label_v0193.is_empty()
	var cancelled_label := _expression_label_v0193
	super._on_generation_cancelled()
	if not expression_was_active:
		return
	var cancelled := EXPRESSION_SERVICE.mark_failed(
		_project, _expression_character_id_v0193, _expression_batch_id_v0193,
		cancelled_label, "Cancelled by the author.", true
	)
	if _apply_expression_mutation_v0193(cancelled):
		_apply_expression_mutation_v0193(EXPRESSION_SERVICE.set_paused(
			_project, _expression_character_id_v0193, _expression_batch_id_v0193, true
		))
	_expression_sequence_active_v0193 = false
	_expression_label_v0193 = ""
	_status.text = "Expression batch paused. Completed results were kept; resume or retry only the remaining item when ready."


func _resume_expression_batch_v0193(batch_id: String) -> void:
	if _image_service.is_active() or _expression_sequence_active_v0193:
		_status.text = "Wait for the current Image Studio job before resuming this batch."
		return
	_expression_batch_id_v0193 = batch_id
	_expression_character_id_v0193 = _active_character_id
	var resumed := EXPRESSION_SERVICE.set_paused(_project, _expression_character_id_v0193, batch_id, false)
	if not _apply_expression_mutation_v0193(resumed):
		return
	_expression_sequence_active_v0193 = true
	call_deferred("_start_next_expression_v0193")


func _pause_expression_batch_v0193(batch_id: String) -> void:
	var paused := EXPRESSION_SERVICE.set_paused(_project, _active_character_id, batch_id, true)
	if _apply_expression_mutation_v0193(paused):
		_status.text = "Expression batch will remain paused after the current provider request."


func _retry_expression_item_v0193(batch_id: String, label: String) -> void:
	if _image_service.is_active() or _expression_sequence_active_v0193:
		_status.text = "Wait for the current expression request before retrying another member."
		return
	var retry := EXPRESSION_SERVICE.retry_item(_project, _active_character_id, batch_id, label)
	if not _apply_expression_mutation_v0193(retry):
		return
	_expression_batch_id_v0193 = batch_id
	_expression_character_id_v0193 = _active_character_id
	_apply_expression_mutation_v0193(EXPRESSION_SERVICE.set_paused(_project, _active_character_id, batch_id, false))
	_expression_sequence_active_v0193 = true
	call_deferred("_start_next_expression_v0193")


func _accept_expression_item_v0193(batch_id: String, label: String, replace_existing: bool) -> void:
	var acceptance := EXPRESSION_SERVICE.accept_item(
		_project, _active_character_id, batch_id, label, replace_existing
	)
	if not _apply_expression_mutation_v0193(acceptance):
		return
	_status.text = "%s expression accepted into Avatar Gallery.%s" % [
		label.capitalize(),
		" The previous label association was removed; its image file remains recoverable." if replace_existing else ""
	]


func _baseline_availability_v0193() -> Dictionary:
	var capabilities := current_normalized_capabilities_v0161()
	return {
		"prompt": true,
		"portrait": not _portrait_baseline_v0193().is_empty() and CCFImageInputAssetServiceV0168.operation_execution_ready(capabilities, CCFImageInputAssetServiceV0168.OP_REFERENCE_IMAGES),
		"selected_result": not _selected_gallery_entry().is_empty() and CCFImageInputAssetServiceV0168.operation_execution_ready(capabilities, CCFImageInputAssetServiceV0168.OP_IMAGE_TO_IMAGE)
	}


func _baseline_for_mode_v0193(baseline_mode: String) -> Dictionary:
	var capabilities := current_normalized_capabilities_v0161()
	if baseline_mode == "portrait":
		var portrait := _portrait_baseline_v0193()
		if portrait.is_empty():
			return {"ok": false, "error": "This character has no available portrait."}
		if not CCFImageInputAssetServiceV0168.operation_execution_ready(capabilities, CCFImageInputAssetServiceV0168.OP_REFERENCE_IMAGES):
			return {"ok": false, "error": "The selected provider profile has not proven Reference Images execution support."}
		return {"ok": true, "baseline": portrait, "options": {
			"image_operation": CCFImageInputAssetServiceV0168.OP_REFERENCE_IMAGES,
			"reference_image_paths": [str(portrait.get("path", ""))],
			"source_image_path": "", "source_image_id": ""
		}}
	if baseline_mode == "selected_result":
		var selected := _selected_gallery_entry()
		var selected_path := CCFImageGenerationService.resolve_generated_image_path(
			str(_project.get("project_id", "")), str(selected.get("path", ""))
		)
		if selected.is_empty() or selected_path.is_empty() or not FileAccess.file_exists(selected_path):
			return {"ok": false, "error": "Select an available Image Studio result first."}
		if not CCFImageInputAssetServiceV0168.operation_execution_ready(capabilities, CCFImageInputAssetServiceV0168.OP_IMAGE_TO_IMAGE):
			return {"ok": false, "error": "The selected provider profile has not proven Image to Image execution support."}
		return {"ok": true, "baseline": {
			"mode": baseline_mode, "path": selected_path,
			"source_image_id": str(selected.get("image_id", "")), "source_record": selected
		}, "options": {
			"image_operation": CCFImageInputAssetServiceV0168.OP_IMAGE_TO_IMAGE,
			"source_image_path": selected_path,
			"source_image_id": str(selected.get("image_id", "")),
			"reference_image_paths": []
		}}
	return {"ok": true, "baseline": {"mode": "prompt", "label": "Current Image Studio prompt and style"}, "options": {
		"image_operation": CCFImageInputAssetServiceV0168.OP_TEXT_TO_IMAGE,
		"source_image_path": "", "source_image_id": "", "reference_image_paths": []
	}}


func _portrait_baseline_v0193() -> Dictionary:
	var character := CCFStorageService.get_character(_project, _active_character_id)
	var assets_value: Variant = character.get("assets", {})
	if not assets_value is Dictionary:
		return {}
	var stored_path := str((assets_value as Dictionary).get("portrait", ""))
	var path := CCFImageGenerationService.resolve_generated_image_path(str(_project.get("project_id", "")), stored_path)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	return {"mode": "portrait", "label": "Current character portrait", "path": path, "stored_path": stored_path}


func _options_from_expression_snapshot_v0193(snapshot: Dictionary) -> Dictionary:
	return {
		"sampler": str(snapshot.get("sampler", "")),
		"steps": int(snapshot.get("steps", 28)),
		"cfg_scale": float(snapshot.get("cfg_scale", 7.0)),
		"seed": int(snapshot.get("seed", -1)),
		"batch_size": 1,
		"generation_mode": "expression_set",
		"provider_parameters": (snapshot.get("provider_parameters", {}) as Dictionary).duplicate(true) if snapshot.get("provider_parameters", {}) is Dictionary else {},
		"image_operation": str(snapshot.get("image_operation", CCFImageInputAssetServiceV0168.OP_TEXT_TO_IMAGE)),
		"source_image_path": str(snapshot.get("source_image_path", "")),
		"source_image_id": str(snapshot.get("source_image_id", "")),
		"mask_image_path": "",
		"reference_image_paths": (snapshot.get("reference_image_paths", []) as Array).duplicate() if snapshot.get("reference_image_paths", []) is Array else [],
		"denoise_strength": float(snapshot.get("denoise_strength", 0.65)),
		"mask_blur": int(snapshot.get("mask_blur", 4))
	}


func _expression_profile_v0193(profile_id: String) -> Dictionary:
	for raw_profile in CCFSettingsService.image_profiles(_settings):
		if raw_profile is Dictionary and str((raw_profile as Dictionary).get("id", "")) == profile_id:
			return (raw_profile as Dictionary).duplicate(true)
	return {}


func _apply_expression_mutation_v0193(result: Dictionary) -> bool:
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not update the expression set."))
		_refresh_expression_context_v0193()
		return false
	_project = (result.get("project", {}) as Dictionary).duplicate(true)
	return _save_expression_project_v0193("")


func _save_expression_project_v0193(status_text: String) -> bool:
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not save expression-set progress."))
		return false
	project_changed.emit(_project.duplicate(true))
	if not status_text.is_empty():
		_status.text = status_text
	_refresh_expression_context_v0193()
	return true


func _refresh_expression_context_v0193() -> void:
	if _expression_window_v0193 != null and is_instance_valid(_expression_window_v0193):
		_expression_window_v0193.update_context(_project, _active_character_id, _baseline_availability_v0193())
	if _expression_set_button_v0193 != null:
		_expression_set_button_v0193.disabled = _project.is_empty() or _active_character_id.is_empty()


func _load_project(project_id: String) -> void:
	super._load_project(project_id)
	_refresh_expression_context_v0193()


func _on_character_selected(index: int) -> void:
	super._on_character_selected(index)
	_refresh_expression_context_v0193()
