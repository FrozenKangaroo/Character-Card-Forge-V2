class_name CCFWorkspaceV01532View
extends "res://scripts/ui/workspace_v01531.gd"

const IDEA_GENERATOR_V01532 = preload("res://scripts/ui/idea_generator_window_v01532.gd")

var _idea_generator_v01532: CCFIdeaGeneratorWindowV01532


func _ready() -> void:
	super._ready()
	_connect_idea_capture_v01532()


func _build_concept_studio() -> void:
	_idea_generator_v01532 = IDEA_GENERATOR_V01532.new()
	_idea_generator_v01532.visible = false
	_idea_generator_v01532.concept_selected.connect(_on_structured_concept_selected)
	add_child(_idea_generator_v01532)
	_idea_generator_v01532.hide()
	_idea_generator_v01412 = _idea_generator_v01532
	_concept_studio = _idea_generator_v01532


func _rebind_concurrent_clients_v01526() -> void:
	super._rebind_concurrent_clients_v01526()
	_connect_idea_capture_v01532()


func _connect_idea_capture_v01532() -> void:
	if _idea_service_v01526 == null:
		return
	var callback := Callable(self, "_on_idea_job_completed_v01532")
	if not _idea_service_v01526.job_completed.is_connected(callback):
		_idea_service_v01526.job_completed.connect(callback)


func _on_idea_job_completed_v01532(
	_job_id: String,
	job_type: String,
	data: Variant,
	metadata: Dictionary
) -> void:
	if job_type != "ideas" or not data is Array:
		return
	if _idea_generator_v01532 == null:
		return
	_idea_generator_v01532.set_last_generated_ideas_v01532(data as Array, metadata)


func _finish_opening_unified_idea_generator() -> void:
	super._finish_opening_unified_idea_generator()
	if _status != null:
		_status.text = "Idea Generator opened. Choose AI Ideas, Structured Builder or Idea Notebook."


func open_idea_notebook_v01532() -> void:
	_finish_opening_unified_idea_generator()
	if _idea_generator_v01532 != null:
		_idea_generator_v01532.open_notebook_v01532()
