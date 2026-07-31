class_name CCFWorkspaceV0147View
extends "res://scripts/ui/workspace_v0146.gd"

const MANUAL_GUIDED_WINDOW_V0147 = preload("res://scripts/ui/manual_guided_window_v0147.gd")


func _build_manual_guided_window() -> void:
	_manual_guided_window = MANUAL_GUIDED_WINDOW_V0147.new()
	# Window nodes begin visible. Hide before add_child so _ready() may configure
	# force_native without Godot reporting that the window is already displayed.
	_manual_guided_window.visible = false
	_manual_guided_window.draft_saved.connect(_on_manual_guided_draft_saved)
	_manual_guided_window.apply_requested.connect(_on_manual_guided_apply_requested)
	add_child(_manual_guided_window)
	_manual_guided_window.hide()
