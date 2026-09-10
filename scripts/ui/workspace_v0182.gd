class_name CCFWorkspaceV0182View
extends "res://scripts/ui/workspace_v0181.gd"

const IMPORT_EXPORT_WINDOW_V0182 = preload(
	"res://scripts/ui/import_export_window_v0182.gd"
)
const CARD_INSPECTOR_WINDOW_V0182 = preload(
	"res://scripts/ui/card_inspector_window_v0182.gd"
)

var _card_inspector_v0182: CCFCardInspectorWindowV0182
var _card_inspector_button_v0182: Button


func _ready() -> void:
	super._ready()
	_build_card_inspector_v0182()
	_install_card_inspector_navigation_v0182()


func _build_import_export_window() -> void:
	_import_export_window = IMPORT_EXPORT_WINDOW_V0182.new()
	_import_export_window.visible = false
	_import_export_window.project_refresh_requested.connect(
		_refresh_import_export_project_context
	)
	_import_export_window.project_imported.connect(_on_external_project_imported)
	_import_export_window.gallery_project_changed_v0175.connect(
		_on_front_porch_gallery_project_changed_v0175
	)
	_import_export_window.world_project_changed_v0180.connect(
		_on_front_porch_world_project_changed_v0180
	)
	_import_export_window.inspection_project_changed_v0182.connect(
		_on_inspection_project_changed_v0182
	)
	add_child(_import_export_window)
	_import_export_window.hide()


func _build_card_inspector_v0182() -> void:
	_card_inspector_v0182 = CARD_INSPECTOR_WINDOW_V0182.new()
	_card_inspector_v0182.visible = false
	_card_inspector_v0182.project_changed_v0182.connect(
		_on_inspection_project_changed_v0182
	)
	add_child(_card_inspector_v0182)
	_card_inspector_v0182.hide()


func _install_card_inspector_navigation_v0182() -> void:
	var top := _first_flow_row()
	if top == null or _find_workspace_button("Card Inspector") != null:
		return
	_card_inspector_button_v0182 = Button.new()
	_card_inspector_button_v0182.text = "Card Inspector"
	_card_inspector_button_v0182.tooltip_text = (
		"Check card health, token size, prompt composition, metadata, assets, "
		+ "expert JSON and a private quality checklist."
	)
	_card_inspector_button_v0182.pressed.connect(_open_card_inspector_v0182)
	top.add_child(_card_inspector_button_v0182)
	if _revision_button_v0181 != null:
		top.move_child(
			_card_inspector_button_v0182, _revision_button_v0181.get_index() + 1
		)


func _open_card_inspector_v0182() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a character before using Card Inspector."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_card_inspector_v0182.open_for_character(
		_project_container, _active_character_id
	)
	_status.text = "Card Inspector opened for the active character."


func _on_inspection_project_changed_v0182(
	updated_project: Dictionary,
	active_character_id: String,
	message_text: String
) -> void:
	if (
		str(updated_project.get("project_id", ""))
		!= str(_project_container.get("project_id", ""))
	):
		return
	_project_container = updated_project.duplicate(true)
	_active_character_id = active_character_id
	var workspace: Dictionary = _project_container.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = _active_character_id
	_project_container["workspace"] = workspace
	var save_result := CCFStorageService.save_project(_project_container)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not save inspection changes."))
		return
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	var generation_value: Variant = _project.get("generation", {})
	var template_id := "default"
	if generation_value is Dictionary:
		template_id = str((generation_value as Dictionary).get(
			"template_id", "default"
		))
	_template = CCFTemplateService.load_template(template_id)
	_apply_attachment_runtime_context()
	_dirty = false
	_populate_project_controls()
	_populate_template_selector()
	_rebuild_form()
	_update_header()
	_update_project_level_window_contexts()
	project_saved.emit(_project_container.duplicate(true))
	_status.text = message_text


func card_inspection_capabilities_v0182() -> Dictionary:
	return CCFCardInspectionServiceV0182.capabilities()
