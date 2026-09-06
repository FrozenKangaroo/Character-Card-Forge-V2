class_name CCFWorkspaceV0171View
extends "res://scripts/ui/workspace_v0170.gd"

const CHARACTER_COLLABORATOR_WINDOW_V0171 = preload(
	"res://scripts/ui/character_collaborator_window_v0171.gd"
)


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V0171.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(
		_on_collaborator_sessions_changed_v015
	)
	_character_collaborator_window.character_draft_ready.connect(
		_on_collaborator_character_draft_ready_v015
	)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()


func collaborator_precedence_capabilities_v0171() -> Dictionary:
	if (
		_character_collaborator_window != null
		and _character_collaborator_window.has_method(
			"source_precedence_capabilities_v0171"
		)
	):
		return _character_collaborator_window.call(
			"source_precedence_capabilities_v0171"
		) as Dictionary
	return {}
