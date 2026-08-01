class_name CCFWorkspaceV01420View
extends "res://scripts/ui/workspace_v01419.gd"

const VARIANT_SERVICE = preload("res://scripts/services/character_variant_service_v01420.gd")
const RELATIONSHIP_GRAPH_WINDOW = preload("res://scripts/ui/relationship_graph_window_v01420.gd")
const PROJECT_RELATIONSHIP_GRAPH_MENU_ID := 14200
const CHARACTER_VERSION_MENU_ID := 14201
const CONVERT_VARIANT_MENU_ID := 14202

var _relationship_graph_window: CCFRelationshipGraphWindowV01420
var _version_dialog: ConfirmationDialog
var _version_type: OptionButton
var _version_name: LineEdit


func _ready() -> void:
	super._ready()
	_build_relationship_graph_window_v01420()
	_build_character_version_dialog_v01420()
	_add_v01420_menu_routes()
	if _active_character_is_variant():
		_install_resolved_variant_workspace()


func load_project(project: Dictionary, template: Dictionary, settings: Dictionary) -> void:
	super.load_project(project, template, settings)
	if _active_character_is_variant():
		_install_resolved_variant_workspace()


func _switch_active_character(character_id: String) -> void:
	if CCFStorageService.character_index(_project_container, character_id) < 0:
		return
	_commit_active_character_to_container()
	_close_tool_windows_for_project_change()
	_active_character_id = character_id
	var workspace: Dictionary = _project_container.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = character_id
	_project_container["workspace"] = workspace
	var raw := CCFStorageService.get_character(_project_container, character_id)
	if VARIANT_SERVICE.is_variant(raw):
		_project = VARIANT_SERVICE.workspace_document(_project_container, character_id)
	else:
		_project = CCFStorageService.character_workspace_document(_project_container, character_id)
	_apply_attachment_runtime_context()
	var generation_value: Variant = _project.get("generation", {})
	var generation: Dictionary = generation_value if generation_value is Dictionary else {}
	_template = CCFTemplateService.load_template(str(generation.get("template_id", "default")))
	_populate_project_controls()
	_populate_template_selector()
	_rebuild_form()
	_update_header()
	_update_project_level_window_contexts()
	_update_variant_status()


func _commit_active_character_to_container() -> void:
	if _project_container.is_empty() or _project.is_empty() or _active_character_id.is_empty():
		return
	var raw := CCFStorageService.get_character(_project_container, _active_character_id)
	if not VARIANT_SERVICE.is_variant(raw):
		super._commit_active_character_to_container()
		return
	_capture_all_fields()
	_capture_builder_state_if_loaded()
	VARIANT_SERVICE.update_variant_from_resolved(_project_container, _active_character_id, _project)
	var workspace: Dictionary = _project_container.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = _active_character_id
	_project_container["workspace"] = workspace


func _install_resolved_variant_workspace() -> void:
	if not _active_character_is_variant():
		return
	_project = VARIANT_SERVICE.workspace_document(_project_container, _active_character_id)
	if _project.is_empty():
		_status.text = "Linked variant could not resolve its base character."
		return
	var generation_value: Variant = _project.get("generation", {})
	var generation: Dictionary = generation_value if generation_value is Dictionary else {}
	_template = CCFTemplateService.load_template(str(generation.get("template_id", "default")))
	_populate_project_controls()
	_populate_template_selector()
	_rebuild_form()
	_update_header()
	_update_variant_status()


func _active_character_is_variant() -> bool:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return false
	return VARIANT_SERVICE.is_variant(CCFStorageService.get_character(_project_container, _active_character_id))


func _update_variant_status() -> void:
	if not _active_character_is_variant():
		return
	var raw := CCFStorageService.get_character(_project_container, _active_character_id)
	var variant_data: Dictionary = raw.get("variant", {})
	var overrides_value: Variant = variant_data.get("overrides", {})
	var override_count := VARIANT_SERVICE.count_leaf_overrides(overrides_value)
	var base_id := str(variant_data.get("base_character_id", ""))
	var base := VARIANT_SERVICE.resolve_character(_project_container, base_id)
	_status.text = "Linked Variant of %s • %d stored override%s. Edit normally; unchanged fields continue to inherit." % [
		CCFStorageService.character_display_name(base),
		override_count,
		"" if override_count == 1 else "s"
	]


func _build_relationship_graph_window_v01420() -> void:
	_relationship_graph_window = RELATIONSHIP_GRAPH_WINDOW.new()
	_relationship_graph_window.visible = false
	_relationship_graph_window.force_native = true
	_relationship_graph_window.transient = false
	_relationship_graph_window.exclusive = false
	_relationship_graph_window.layout_saved.connect(_on_relationship_graph_layout_saved)
	_relationship_graph_window.character_selected.connect(_on_relationship_graph_character_selected)
	add_child(_relationship_graph_window)
	_relationship_graph_window.hide()


func _build_character_version_dialog_v01420() -> void:
	_version_dialog = ConfirmationDialog.new()
	_version_dialog.visible = false
	_version_dialog.title = "Create Character Version"
	_version_dialog.ok_button_text = "Create"
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	_version_dialog.add_child(root)
	var description := Label.new()
	description.text = "Choose whether this version is a lightweight linked diff or a full independent character."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(description)
	_version_type = OptionButton.new()
	_version_type.add_item("Linked Variant — store only differences")
	_version_type.set_item_metadata(0, "variant")
	_version_type.add_item("Full Character — independent copy")
	_version_type.set_item_metadata(1, "full")
	root.add_child(_version_type)
	_version_name = LineEdit.new()
	_version_name.placeholder_text = "Version name, e.g. Yui — NTR Route"
	root.add_child(_version_name)
	var hint := Label.new()
	hint.text = "Linked variants inherit unchanged fields and assets from the base. Export still produces a complete standalone Character Card."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)
	_version_dialog.confirmed.connect(_create_requested_character_version)
	add_child(_version_dialog)
	_version_dialog.hide()


func _add_v01420_menu_routes() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton:
			continue
		var menu := node as MenuButton
		var popup := menu.get_popup()
		if menu.text == "Project":
			popup.add_separator()
			popup.add_item("Relationship Graph…", PROJECT_RELATIONSHIP_GRAPH_MENU_ID)
			popup.id_pressed.connect(_on_v01420_project_menu)
		elif menu.text == "Character":
			popup.add_separator()
			popup.add_item("Create Character Version…", CHARACTER_VERSION_MENU_ID)
			popup.add_item("Convert Linked Variant to Full Character", CONVERT_VARIANT_MENU_ID)
			popup.id_pressed.connect(_on_v01420_character_menu)


func _on_v01420_project_menu(id: int) -> void:
	if id == PROJECT_RELATIONSHIP_GRAPH_MENU_ID:
		_open_relationship_graph_v01420()


func _on_v01420_character_menu(id: int) -> void:
	if id == CHARACTER_VERSION_MENU_ID:
		_open_character_version_dialog()
	elif id == CONVERT_VARIANT_MENU_ID:
		_convert_active_variant_to_full()


func _open_relationship_graph_v01420() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	_relationship_graph_window.open_for_project(_project_container)
	_status.text = "Relationship Graph opened. Drag nodes and Save Layout when ready."


func _on_relationship_graph_layout_saved(layout: Dictionary) -> void:
	var workspace: Dictionary = _project_container.get("workspace", {}).duplicate(true)
	workspace["relationship_graph"] = {
		"format_version": 1,
		"nodes": layout.duplicate(true)
	}
	_project_container["workspace"] = workspace
	_dirty = true


func _on_relationship_graph_character_selected(character_id: String) -> void:
	if character_id.is_empty() or character_id == _active_character_id:
		return
	_switch_active_character(character_id)


func _open_character_version_dialog() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_commit_active_character_to_container()
	var source := VARIANT_SERVICE.resolve_character(_project_container, _active_character_id)
	if source.is_empty():
		_status.text = "The active character could not be resolved."
		return
	_version_type.select(0)
	_version_name.text = "%s — Variant" % CCFStorageService.character_display_name(source)
	_version_dialog.popup_centered(Vector2i(620, 260))


func _create_requested_character_version() -> void:
	_commit_active_character_to_container()
	var mode := str(_version_type.get_item_metadata(_version_type.selected))
	var name := _version_name.text.strip_edges()
	var source := VARIANT_SERVICE.resolve_character(_project_container, _active_character_id)
	if source.is_empty():
		return
	if name.is_empty():
		name = "%s — Variant" % CCFStorageService.character_display_name(source)
	var created: Dictionary
	if mode == "variant":
		created = VARIANT_SERVICE.create_variant(source, name)
	else:
		created = source.duplicate(true)
		created.erase("record_type")
		created.erase("variant")
		var fresh := CCFStorageService.new_character_record(name)
		created["character_id"] = str(fresh.get("character_id", ""))
		created["created_at"] = str(fresh.get("created_at", ""))
		created["updated_at"] = str(fresh.get("updated_at", ""))
		var metadata: Dictionary = created.get("metadata", {}).duplicate(true)
		metadata["name"] = name
		created["metadata"] = metadata
		var card: Dictionary = created.get("character", {}).duplicate(true)
		card["name"] = name
		created["character"] = card
	if created.is_empty():
		_status.text = "Character version could not be created."
		return
	var characters: Array = _project_container.get("characters", []).duplicate(true)
	characters.append(created)
	_project_container["characters"] = characters
	_dirty = true
	_switch_active_character(str(created.get("character_id", "")))
	_status.text = (
		"Linked variant created. Only future differences will be stored."
		if mode == "variant"
		else "Full independent character version created."
	)


func _convert_active_variant_to_full() -> void:
	if not _active_character_is_variant():
		_status.text = "The active character is already a full character."
		return
	_commit_active_character_to_container()
	var result := VARIANT_SERVICE.convert_to_full_character(_project_container, _active_character_id)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not convert linked variant."))
		return
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	_dirty = true
	_populate_project_controls()
	_rebuild_form()
	_update_header()
	_status.text = "Linked variant materialised into a full independent character."


func _request_remove_active_character() -> void:
	var dependents := VARIANT_SERVICE.dependent_variant_ids(_project_container, _active_character_id)
	if not dependents.is_empty():
		_status.text = "This character is the base for %d linked variant%s. Convert or remove those variants before deleting the base." % [dependents.size(), "" if dependents.size() == 1 else "s"]
		return
	super._request_remove_active_character()


func _export_project_for_active_character() -> Dictionary:
	if _active_character_is_variant():
		return VARIANT_SERVICE.project_with_materialized_character(_project_container, _active_character_id)
	return _project_container.duplicate(true)


func _open_import_export_studio() -> void:
	if _project_container.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	_import_export_window.open_for_project(_export_project_for_active_character(), _settings, _active_character_id)


func _refresh_import_export_project_context() -> void:
	if _project_container.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	_import_export_window.update_project_context(_export_project_for_active_character(), _settings, _active_character_id)


func _update_import_export_context() -> void:
	if _import_export_window == null:
		return
	_commit_active_character_to_container()
	_import_export_window.update_project_context(_export_project_for_active_character(), _settings, _active_character_id)


func _close_tool_windows_for_project_change() -> void:
	if _relationship_graph_window != null and _relationship_graph_window.visible:
		_relationship_graph_window.hide()
	super._close_tool_windows_for_project_change()
