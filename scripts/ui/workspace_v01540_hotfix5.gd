class_name CCFWorkspaceV01540Hotfix5View
extends "res://scripts/ui/workspace_v01540_hotfix4.gd"

const CHARACTER_COLLABORATOR_WINDOW_V01540_HOTFIX5 = preload(
	"res://scripts/ui/character_collaborator_window_v01540_hotfix5.gd"
)


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V01540_HOTFIX5.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(_on_collaborator_sessions_changed_v015)
	_character_collaborator_window.character_draft_ready.connect(_on_collaborator_character_draft_ready_v015)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()


func multi_source_collaborator_capabilities_v01537() -> Dictionary:
	var result := super.multi_source_collaborator_capabilities_v01537()
	result["version"] = "0.15.40-hotfix5"
	result["composer_resize_guard"] = true
	result["godot_471_warning_cleanup"] = true
	return result
