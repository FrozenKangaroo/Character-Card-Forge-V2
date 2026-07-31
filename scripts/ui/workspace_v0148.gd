class_name CCFWorkspaceV0148View
extends "res://scripts/ui/workspace_v0147.gd"

const MANUAL_GUIDED_WINDOW_V0148 = preload("res://scripts/ui/manual_guided_window_v0148.gd")


func _build_manual_guided_window() -> void:
	_manual_guided_window = MANUAL_GUIDED_WINDOW_V0148.new()
	_manual_guided_window.visible = false
	_manual_guided_window.draft_saved.connect(_on_manual_guided_draft_saved)
	_manual_guided_window.apply_requested.connect(_on_manual_guided_apply_requested)
	add_child(_manual_guided_window)
	_manual_guided_window.hide()


func _on_manual_guided_apply_requested(values_by_path: Dictionary, state: Dictionary) -> void:
	var augmented := values_by_path.duplicate(true)
	var greetings: Array[String] = []
	var raw = state.get("alternative_greetings", [])
	if raw is Array:
		for item in raw:
			var clean := str(item).strip_edges()
			if not clean.is_empty():
				greetings.append(clean)
	augmented["character.alternate_greetings"] = greetings
	super._on_manual_guided_apply_requested(augmented, state)
