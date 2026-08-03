class_name CCFImageGenerationWindowV01530
extends "res://scripts/ui/image_generation_window_v01529.gd"


func _ready() -> void:
	super._ready()
	_apply_prompt_word_wrap_v01530()


func _apply_prompt_word_wrap_v01530() -> void:
	_configure_prompt_editor_v01530(_prompt_edit)
	_configure_prompt_editor_v01530(_negative_prompt_edit)


func _configure_prompt_editor_v01530(editor: TextEdit) -> void:
	if editor == null:
		return
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.scroll_horizontal = 0
