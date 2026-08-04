class_name CCFWorkspaceV01533Hotfix2View
extends "res://scripts/ui/workspace_v01533_hotfix1.gd"

const IDEA_JOB_TYPES_V01533_HOTFIX2 := ["ideas", "idea_generation"]


func _ready() -> void:
	super._ready()
	_connect_idea_capture_v01532()


func _rebind_concurrent_clients_v01526() -> void:
	super._rebind_concurrent_clients_v01526()
	_connect_idea_capture_v01532()


func _finish_opening_unified_idea_generator() -> void:
	# The embedded AI Ideas controls are still owned by the retained legacy
	# controller Window. Rebinding that controller can change which live service
	# ultimately emits its completion, so refresh capture immediately before and
	# after every open rather than assuming one permanent worker reference.
	_connect_idea_capture_v01532()
	super._finish_opening_unified_idea_generator()
	_connect_idea_capture_v01532()


func _connect_idea_capture_v01532() -> void:
	var callback := Callable(self, "_on_idea_job_completed_v01532")
	# Keep the normal dedicated Idea worker explicit, then also cover every live
	# generation service below Workspace. This protects the Notebook bridge from
	# a retained/legacy controller temporarily owning a compatible service that is
	# not the current _idea_service_v01526 reference.
	if _idea_service_v01526 != null:
		_connect_idea_capture_service_v01533_hotfix2(
			_idea_service_v01526, callback
		)
	_connect_idea_capture_recursive_v01533_hotfix2(self, callback)


func _connect_idea_capture_recursive_v01533_hotfix2(
	root_node: Node, callback: Callable
) -> void:
	for child in root_node.get_children():
		if child is CCFGenerationService:
			_connect_idea_capture_service_v01533_hotfix2(
				child as CCFGenerationService, callback
			)
		_connect_idea_capture_recursive_v01533_hotfix2(child, callback)


func _connect_idea_capture_service_v01533_hotfix2(
	service: CCFGenerationService, callback: Callable
) -> void:
	if service == null:
		return
	if not service.job_completed.is_connected(callback):
		service.job_completed.connect(callback)


func _on_idea_job_completed_v01532(
	_job_id: String,
	job_type: String,
	data: Variant,
	metadata: Dictionary
) -> void:
	if job_type not in IDEA_JOB_TYPES_V01533_HOTFIX2:
		return
	var ideas: Array = []
	if data is Array:
		ideas = data as Array
	elif data is Dictionary:
		var envelope_value: Variant = (data as Dictionary).get("ideas", [])
		if envelope_value is Array:
			ideas = envelope_value as Array
	if ideas.is_empty() or _idea_generator_v01532 == null:
		return
	_idea_generator_v01532.set_last_generated_ideas_v01532(ideas, metadata)


func idea_notebook_capture_capabilities_v01533_hotfix2() -> Dictionary:
	return {
		"format_version": 1,
		"current_job_type": "ideas",
		"compatible_job_types": IDEA_JOB_TYPES_V01533_HOTFIX2.duplicate(),
		"all_live_generation_services": true,
		"capture_only": true,
		"auto_save": false
	}
