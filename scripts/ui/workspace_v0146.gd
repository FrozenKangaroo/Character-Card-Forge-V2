class_name CCFWorkspaceV0146View
extends "res://scripts/ui/workspace_v0145.gd"


func _apply_preview() -> void:
	if (
		not _preview_project_id.is_empty()
		and _preview_project_id != str(_project.get("project_id", ""))
	):
		_status.text = "This generation preview belongs to a different character and was not applied."
		_hide_preview()
		return

	# Preview can stay open while the live workspace is edited, and Vision Preview
	# can be opened from a project-level tool that refreshes its own project copy.
	# Capture the visible workspace immediately before applying so every unchecked
	# field means exactly "leave my current value alone" rather than restoring an
	# older/stale value from when generation began.
	_capture_all_fields()

	var applied_fields := _apply_selected_preview_rows_to_project(_project, _preview_rows)
	if applied_fields.is_empty():
		_status.text = "No generated fields were applied. Existing workspace values were left unchanged."
		_hide_preview()
		return

	_record_generation_history(applied_fields, _preview_job_type, _preview_metadata)
	_dirty = true
	_rebuild_form()
	_update_header()
	_status.text = (
		"Applied %d generated field(s). Unchecked fields were preserved. Review them, then Save when ready."
		% applied_fields.size()
	)
	_hide_preview()


func _apply_selected_preview_rows_to_project(
	target_project: Dictionary, rows: Array
) -> Array[String]:
	var applied_fields: Array[String] = []
	for row in rows:
		if not row is Dictionary:
			continue
		var checkbox_value: Variant = row.get("checkbox")
		if not checkbox_value is CheckBox:
			continue
		var checkbox := checkbox_value as CheckBox
		if not checkbox.button_pressed:
			# Critical safety rule: unchecked proposals do not write defaults, blanks,
			# nulls, or stale generated values. They perform no write at all.
			continue
		var field_value: Variant = row.get("field", {})
		if not field_value is Dictionary:
			continue
		var field: Dictionary = field_value
		var path := str(field.get("path", "")).strip_edges()
		if path.is_empty():
			continue
		var editor_value: Variant = row.get("editor")
		if not editor_value is Control:
			continue
		var editor := editor_value as Control
		var field_type := str(field.get("type", "multiline"))
		var value: Variant = _default_value_for_type(field_type)
		if editor is LineEdit:
			value = editor.text
		elif editor is TextEdit:
			value = editor.text
		elif editor is SpinBox:
			value = editor.value
		elif editor is CheckBox:
			value = editor.button_pressed
		elif editor is OptionButton:
			value = str(editor.get_selected_metadata()) if editor.selected >= 0 else ""
		else:
			continue
		if field_type == "tags":
			value = _parse_tags(str(value))
		CCFStorageService.set_value_at_path(target_project, path, value)
		applied_fields.append(str(field.get("id", "field")))
	return applied_fields
