class_name CCFImageGenerationServiceV01526
extends "res://scripts/services/image_generation_service.gd"

signal generation_queued

var _scheduler_v01526: CCFAIJobSchedulerV01526
var _worker_id_v01526 := "image_generation"
var _pending_generate_v01526: Dictionary = {}
var _scheduler_lease_v01526 := false


func _ready() -> void:
	super._ready()
	generation_batch_completed.connect(_on_batch_terminal_v01526)
	generation_failed.connect(_on_failure_terminal_v01526)
	generation_cancelled.connect(_on_cancel_terminal_v01526)


func configure_scheduler_v01526(
	scheduler: CCFAIJobSchedulerV01526, worker_id: String = "image_generation"
) -> void:
	if (
		_scheduler_v01526 != null
		and _scheduler_v01526.capacity_changed.is_connected(
			_on_scheduler_capacity_v01526
		)
	):
		_scheduler_v01526.capacity_changed.disconnect(_on_scheduler_capacity_v01526)
	_scheduler_v01526 = scheduler
	_worker_id_v01526 = worker_id.strip_edges()
	if _worker_id_v01526.is_empty():
		_worker_id_v01526 = "image_generation_%d" % get_instance_id()
	if (
		_scheduler_v01526 != null
		and not _scheduler_v01526.capacity_changed.is_connected(
			_on_scheduler_capacity_v01526
		)
	):
		_scheduler_v01526.capacity_changed.connect(_on_scheduler_capacity_v01526)


func generate(
	project_id: String,
	character_id: String,
	profile: Dictionary,
	prompt_text: String,
	negative_prompt: String,
	image_size: String,
	prompt_style: String,
	model_override: String = "",
	options: Dictionary = {}
) -> Dictionary:
	if is_active() or not _pending_generate_v01526.is_empty():
		return {"ok": false, "error": "An image generation request is already running or queued."}
	if _scheduler_v01526 == null:
		return super.generate(
			project_id,
			character_id,
			profile,
			prompt_text,
			negative_prompt,
			image_size,
			prompt_style,
			model_override,
			options
		)
	_pending_generate_v01526 = {
		"project_id": project_id,
		"character_id": character_id,
		"profile": profile.duplicate(true),
		"prompt_text": prompt_text,
		"negative_prompt": negative_prompt,
		"image_size": image_size,
		"prompt_style": prompt_style,
		"model_override": model_override,
		"options": options.duplicate(true)
	}
	var start_result := _try_start_pending_v01526()
	if not bool(start_result.get("ok", false)):
		return start_result
	if not bool(start_result.get("started", false)):
		generation_queued.emit()
		return {"ok": true, "queued": true}
	return {"ok": true, "queued": false}


func cancel() -> void:
	if not _pending_generate_v01526.is_empty() and not is_active():
		_pending_generate_v01526 = {}
		if _scheduler_v01526 != null:
			_scheduler_v01526.cancel_wait(_worker_id_v01526)
		generation_cancelled.emit()
		return
	super.cancel()


func _try_start_pending_v01526() -> Dictionary:
	if _pending_generate_v01526.is_empty():
		return {"ok": true, "started": false}
	if _scheduler_v01526 != null and not _scheduler_lease_v01526:
		if not _scheduler_v01526.request_slot(
			_worker_id_v01526,
			CCFAIJobSchedulerV01526.ROLE_IMAGE,
			"",
			null,
			"Image generation"
		):
			return {"ok": true, "started": false}
		_scheduler_lease_v01526 = true
	var request := _pending_generate_v01526.duplicate(true)
	_pending_generate_v01526 = {}
	var result := super.generate(
		str(request.get("project_id", "")),
		str(request.get("character_id", "")),
		request.get("profile", {}),
		str(request.get("prompt_text", "")),
		str(request.get("negative_prompt", "")),
		str(request.get("image_size", "")),
		str(request.get("prompt_style", "")),
		str(request.get("model_override", "")),
		request.get("options", {})
	)
	if not bool(result.get("ok", false)):
		_release_image_slot_v01526()
		return result
	return {"ok": true, "started": true}


func _on_scheduler_capacity_v01526() -> void:
	if not _pending_generate_v01526.is_empty():
		call_deferred("_try_start_pending_v01526")


func _on_batch_terminal_v01526(_records: Array) -> void:
	_release_image_slot_v01526()


func _on_failure_terminal_v01526(_message: String) -> void:
	_release_image_slot_v01526()


func _on_cancel_terminal_v01526() -> void:
	_release_image_slot_v01526()


func _release_image_slot_v01526() -> void:
	if _scheduler_v01526 != null:
		_scheduler_v01526.release_slot(_worker_id_v01526)
	_scheduler_lease_v01526 = false
