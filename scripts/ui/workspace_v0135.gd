class_name CCFWorkspaceV0135View
extends CCFWorkspaceV0133View


func _ready() -> void:
	super._ready()
	_apply_character_project_labels()


func _build_import_export_window() -> void:
	_import_export_window = CCFImportExportWindowV0135.new()
	_import_export_window.visible = false
	_import_export_window.project_refresh_requested.connect(_refresh_import_export_project_context)
	_import_export_window.project_imported.connect(_on_external_project_imported)
	add_child(_import_export_window)
	_import_export_window.hide()


func _apply_character_project_labels() -> void:
	for node in find_children("*", "Label", true, false):
		if not node is Label:
			continue
		var label: Label = node
		if label.text == "Project":
			label.text = "Character Project"
		elif label.text == "Group role":
			label.text = "Project role"
	if _project_name_edit != null:
		_project_name_edit.placeholder_text = "Character project name"
