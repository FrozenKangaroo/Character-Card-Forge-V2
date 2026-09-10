class_name CCFWorkspaceV0181View
extends "res://scripts/ui/workspace_v0180.gd"

const REVISION_WINDOW_V0181 = preload(
	"res://scripts/ui/revision_history_window_v0181.gd"
)
const REVISION_SERVICE_V0181 = preload(
	"res://scripts/services/revision_service_v0181.gd"
)
const REVISION_PERSISTENCE_V0181 = preload(
	"res://scripts/services/project_persistence_service_v01536_hotfix3.gd"
)

var _revision_window_v0181: CCFRevisionHistoryWindowV0181
var _revision_button_v0181: Button


func _ready() -> void:
	super._ready()
	_build_revision_window_v0181()
	_install_revision_navigation_v0181()


func _build_revision_window_v0181() -> void:
	_revision_window_v0181 = REVISION_WINDOW_V0181.new()
	_revision_window_v0181.project_changed_v0181.connect(
		_on_revision_project_changed_v0181
	)
	add_child(_revision_window_v0181)
	_revision_window_v0181.hide()


func _install_revision_navigation_v0181() -> void:
	var top := _first_flow_row()
	if top == null or _find_workspace_button("Revision History") != null:
		return
	_revision_button_v0181 = Button.new()
	_revision_button_v0181.text = "Revision History"
	_revision_button_v0181.tooltip_text = (
		"Create checkpoints, compare changes, restore, fork, merge, or export "
		+ "an earlier character revision."
	)
	_revision_button_v0181.pressed.connect(_open_revision_history_v0181)
	top.add_child(_revision_button_v0181)
	var character_menu_index := -1
	for index in range(top.get_child_count()):
		var child := top.get_child(index)
		if child is MenuButton and child.text == "Character":
			character_menu_index = index
			break
	if character_menu_index >= 0:
		top.move_child(_revision_button_v0181, character_menu_index + 1)


func _open_revision_history_v0181() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a character before viewing revision history."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_revision_window_v0181.open_for_character(
		_project_container, _active_character_id
	)
	_status.text = "Revision History opened for the active character."


func save_project() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	var persisted := REVISION_PERSISTENCE_V0181.is_project_persisted(
		_project_container
	)
	var meaningful := REVISION_PERSISTENCE_V0181.project_has_meaningful_content(
		_project_container, _template
	)
	if persisted or meaningful:
		_checkpoint_active_character_v0181(
			"Saved",
			"Durable checkpoint created by Save.",
			"save",
			{"source": "workspace_save"},
			false
		)
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	var result := REVISION_PERSISTENCE_V0181.save_if_meaningful(
		_project_container, _template
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not save project."))
		return
	if bool(result.get("skipped_empty", false)):
		_dirty = false
		_populate_project_controls()
		_status.text = (
			"Nothing to save yet. Empty projects stay in Workspace and are not added to the Library."
		)
		_update_header()
		return
	_dirty = false
	_populate_project_controls()
	_status.text = "Saved with revision checkpoint at %s" % Time.get_time_string_from_system()
	_update_header()
	project_saved.emit(_project_container.duplicate(true))


func _apply_preview() -> void:
	var before := REVISION_SERVICE_V0181.snapshot_character(
		CCFStorageService.get_character(_project_container, _active_character_id)
	)
	super._apply_preview()
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	var after := REVISION_SERVICE_V0181.snapshot_character(
		CCFStorageService.get_character(_project_container, _active_character_id)
	)
	if before == after:
		return
	_checkpoint_active_character_v0181(
		"Accepted AI changes",
		"Checkpoint created after applying selected fields from an AI preview.",
		"ai_apply",
		{"job_type": _preview_job_type},
		true
	)
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)


func _on_external_project_imported(imported_project: Dictionary) -> void:
	var prepared := imported_project.duplicate(true)
	var characters: Array = prepared.get("characters", []).duplicate(true)
	for index in range(characters.size()):
		if not characters[index] is Dictionary:
			continue
		var character_record: Dictionary = (characters[index] as Dictionary).duplicate(true)
		REVISION_SERVICE_V0181.create_checkpoint(
			character_record,
			"Imported",
			"Recovery baseline created after importing this character.",
			"import",
			{"source": "import_export"},
			false
		)
		characters[index] = character_record
	prepared["characters"] = characters
	CCFStorageService.save_project(prepared)
	project_imported.emit(prepared)


func _checkpoint_active_character_v0181(
	checkpoint_label: String,
	checkpoint_note: String,
	checkpoint_reason: String,
	provenance: Dictionary,
	force: bool
) -> Dictionary:
	var index := CCFStorageService.character_index(
		_project_container, _active_character_id
	)
	if index < 0:
		return {"ok": false, "error": "The active character could not be found."}
	var characters: Array = _project_container.get("characters", []).duplicate(true)
	var character_record: Dictionary = (characters[index] as Dictionary).duplicate(true)
	var result := REVISION_SERVICE_V0181.create_checkpoint(
		character_record,
		checkpoint_label,
		checkpoint_note,
		checkpoint_reason,
		provenance,
		force
	)
	characters[index] = character_record
	_project_container["characters"] = characters
	return result


func _on_revision_project_changed_v0181(
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
		_status.text = str(save_result.get("error", "Could not save revision changes."))
		return
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	var generation_value: Variant = _project.get("generation", {})
	var template_id := "default"
	if generation_value is Dictionary:
		template_id = str((generation_value as Dictionary).get("template_id", "default"))
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


func revision_capabilities_v0181() -> Dictionary:
	return REVISION_SERVICE_V0181.capabilities()
