class_name CCFWorkspaceV01311View
extends CCFWorkspaceV01310View

const ATTACHMENT_WINDOW_V01311 = preload("res://scripts/ui/attachment_manager_window_v01311.gd")


func _build_attachment_window() -> void:
	_attachment_window = ATTACHMENT_WINDOW_V01311.new()
	_attachment_window.visible = false
	_attachment_window.set_generation_service(_generation_service)
	_attachment_window.attachments_changed.connect(_on_attachments_changed)
	_attachment_window.vision_preview_requested.connect(_show_generation_preview)
	_attachment_window.project_refresh_requested.connect(_refresh_attachment_project_context)
	add_child(_attachment_window)
	_attachment_window.hide()
