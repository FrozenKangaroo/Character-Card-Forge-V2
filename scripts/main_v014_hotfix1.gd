extends "res://scripts/main_v014.gd"

const GENERATION_SERVICE_V014_HOTFIX1 = preload("res://scripts/services/generation_service_v014_hotfix1.gd")
const BUILD_DISPLAY_VERSION_V014_HOTFIX1 := "0.14.0-hotfix1"


func _install_generation_parity_service() -> void:
	if _workspace == null:
		return
	var current_service: CCFGenerationService = _workspace._generation_service
	if current_service != null and current_service.get_script() == GENERATION_SERVICE_V014_HOTFIX1:
		return
	if current_service != null:
		_disconnect_workspace_generation_signals(current_service)
		if current_service.get_parent() == _workspace:
			_workspace.remove_child(current_service)
		current_service.queue_free()
	var upgraded_service: CCFGenerationService = GENERATION_SERVICE_V014_HOTFIX1.new()
	_workspace._generation_service = upgraded_service
	_workspace.add_child(upgraded_service)
	upgraded_service.job_started.connect(_workspace._on_job_started)
	upgraded_service.job_completed.connect(_workspace._on_job_completed)
	upgraded_service.job_failed.connect(_workspace._on_job_failed)
	upgraded_service.job_cancelled.connect(_workspace._on_job_cancelled)
	upgraded_service.queue_changed.connect(_workspace._on_queue_changed)
	_rebind_workspace_generation_clients(upgraded_service)


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V014_HOTFIX1
			node.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return
