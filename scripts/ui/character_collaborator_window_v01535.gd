class_name CCFCharacterCollaboratorWindowV01535
extends "res://scripts/ui/character_collaborator_window_v01534.gd"


func _ready() -> void:
	super._ready()
	if _handoff_label_v01515 != null:
		_handoff_label_v01515.text = "Handoff format"
		_handoff_label_v01515.tooltip_text = (
			"Choose the generated handoff format. After generation, Workspace asks where the completed character should be placed."
		)
	if _generate_button != null:
		_generate_button.text = "Complete Character → Workspace…"
		_generate_button.tooltip_text = (
			"Generate the selected handoff format, then choose a safe Workspace destination. An occupied current character is never overwritten automatically."
		)


func completion_routing_capabilities_v01535() -> Dictionary:
	return {
		"version": "0.15.35",
		"destination_after_generation": true,
		"occupied_character_overwrite": false,
		"compare_apply_reserved_v01536": true
	}
