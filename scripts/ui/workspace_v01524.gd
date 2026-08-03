class_name CCFWorkspaceV01524View
extends "res://scripts/ui/workspace_v01522.gd"

const REQUIRED_GENERATION_SERVICE_V01524 = preload("res://scripts/services/generation_service_v01522.gd")


func _ready() -> void:
	super._ready()
	# Do not assume an inherited _ready() path installed the newest generation
	# service. v0.15.22 could reach Generate Character with the older v0.14.3
	# instance still attached, making the strategy-aware method unavailable.
	_ensure_strategy_generation_service_v01524()


func _generate_character() -> void:
	if not _ensure_strategy_generation_service_v01524():
		return
	super._generate_character()


func _ensure_strategy_generation_service_v01524() -> bool:
	if not _has_strategy_generation_service_v01524():
		_install_generation_service_v015()
	if not _has_strategy_generation_service_v01524():
		if _status != null:
			_status.text = "Character Card Forge could not activate the Safe Section generation service. Restart the app and review the generation diagnostics if the problem continues."
		return false
	return true


func _has_strategy_generation_service_v01524() -> bool:
	if _generation_service == null:
		return false
	return (
		_generation_service.has_method("queue_character_generation_with_strategy")
		and _generation_service.has_signal("diagnostics_available")
		and _generation_service is CCFGenerationServiceV01522
	)
