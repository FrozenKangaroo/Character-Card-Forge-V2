class_name CCFWorkspaceV01417View
extends "res://scripts/ui/workspace_v01416.gd"

const LOREBOOK_WINDOW_V01417 = preload("res://scripts/ui/lorebook_window_v01415.gd")


func _build_lorebook_window() -> void:
	_lorebook_window = LOREBOOK_WINDOW_V01417.new()
	# Configure native-window behaviour before the node is added or displayed.
	# Godot cannot switch force_native while a Window is already visible.
	_lorebook_window.visible = false
	_lorebook_window.force_native = true
	_lorebook_window.transient = false
	_lorebook_window.exclusive = false
	_lorebook_window.lorebooks_saved.connect(_on_lorebooks_saved)
	add_child(_lorebook_window)
	_lorebook_window.hide()
