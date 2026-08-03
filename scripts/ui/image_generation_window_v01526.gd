class_name CCFImageGenerationWindowV01526
extends "res://scripts/ui/image_generation_window.gd"

const IMAGE_SERVICE_V01526 = preload(
	"res://scripts/services/image_generation_service_v01526.gd"
)

var _scheduler_for_image_v01526: CCFAIJobSchedulerV01526


func _ready() -> void:
	super._ready()
	_install_image_service_v01526()


func set_scheduler_v01526(scheduler: CCFAIJobSchedulerV01526) -> void:
	_scheduler_for_image_v01526 = scheduler
	if _image_service is CCFImageGenerationServiceV01526:
		(_image_service as CCFImageGenerationServiceV01526).configure_scheduler_v01526(
			scheduler
		)


func scheduler_v01526() -> CCFAIJobSchedulerV01526:
	return _scheduler_for_image_v01526


func _install_image_service_v01526() -> void:
	var previous := _image_service
	if previous != null:
		if previous.generation_started.is_connected(_on_generation_started):
			previous.generation_started.disconnect(_on_generation_started)
		if previous.generation_batch_completed.is_connected(_on_generation_batch_completed):
			previous.generation_batch_completed.disconnect(_on_generation_batch_completed)
		if previous.generation_failed.is_connected(_on_generation_failed):
			previous.generation_failed.disconnect(_on_generation_failed)
		if previous.generation_cancelled.is_connected(_on_generation_cancelled):
			previous.generation_cancelled.disconnect(_on_generation_cancelled)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded := IMAGE_SERVICE_V01526.new() as CCFImageGenerationServiceV01526
	add_child(upgraded)
	upgraded.generation_started.connect(_on_generation_started)
	upgraded.generation_batch_completed.connect(_on_generation_batch_completed)
	upgraded.generation_failed.connect(_on_generation_failed)
	upgraded.generation_cancelled.connect(_on_generation_cancelled)
	upgraded.generation_queued.connect(_on_image_generation_queued_v01526)
	_image_service = upgraded
	if _scheduler_for_image_v01526 != null:
		upgraded.configure_scheduler_v01526(_scheduler_for_image_v01526)


func _on_image_generation_queued_v01526() -> void:
	if _status != null:
		_status.text = "Image generation is queued and will start when its configured AI-job pool has capacity."
