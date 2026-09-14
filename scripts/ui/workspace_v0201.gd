class_name CCFWorkspaceV0201View
extends "res://scripts/ui/workspace_v0195.gd"

const LAYOUT_EDITING := 0
const LAYOUT_REVIEW := 1
const LAYOUT_LOREBOOK := 2
const LAYOUT_FRONT_PORCH := 3
const LAYOUT_GROUP_CARD := 4

var _layout_menu_v0201: MenuButton
var _active_layout_v0201 := "editing"


func _ready() -> void:
	super._ready()
	_install_layout_menu_v0201()
	_decorate_shortcuts_v0201()


func update_settings(settings: Dictionary) -> void:
	super.update_settings(settings)
	var ui_value: Variant = _settings.get("ui", {})
	if ui_value is Dictionary:
		_active_layout_v0201 = str(
			(ui_value as Dictionary).get("workspace_layout_v0201", "editing")
		)
	_sync_layout_menu_v0201()


func run_shortcut_action_v0201(action_id: String) -> bool:
	match action_id:
		"save":
			save_project()
		"next_field":
			_focus_relative_field_v0201(1)
		"previous_field":
			_focus_relative_field_v0201(-1)
		"ai_review":
			_open_ai_review_v0183()
		"compare":
			_open_refinement_compare_v01536()
		"export_install":
			_open_import_export_studio()
		"lorebook":
			_open_lorebook()
		"layout_editing":
			apply_workspace_layout_v0201("editing")
		"layout_review":
			apply_workspace_layout_v0201("review")
		"layout_lorebook":
			apply_workspace_layout_v0201("lorebook")
		"layout_front_porch":
			apply_workspace_layout_v0201("front_porch")
		"layout_group_card":
			apply_workspace_layout_v0201("group_card")
		_:
			return false
	return true


func apply_workspace_layout_v0201(layout_id: String) -> void:
	if _project_container.is_empty():
		_status.text = "Open or create a character project before choosing a workspace layout."
		return
	_active_layout_v0201 = layout_id
	match layout_id:
		"editing":
			_select_workspace_tab_v0201("")
			_focus_relative_field_v0201(1)
			_status.text = "Editing layout selected. Character fields have focus."
		"review":
			_open_ai_review_v0183()
		"lorebook":
			_open_lorebook()
		"front_porch":
			_select_workspace_tab_v0201("Front Porch — Optional")
			_open_import_export_studio()
			_status.text = "Front Porch Deployment layout opened authoring plus export/install tools."
		"group_card":
			_open_card_workflow_studio()
			_status.text = "Group Card layout opened Card Workflows for the current project."
		_:
			_active_layout_v0201 = "editing"
			_select_workspace_tab_v0201("")
	_store_layout_v0201()
	_sync_layout_menu_v0201()


func workflow_capabilities_v0201() -> Dictionary:
	return {
		"format_version": 1,
		"layout_presets": CCFWorkflowDiscoveryServiceV0201.workspace_layouts().size(),
		"field_navigation": true,
		"save_shortcut": true,
		"review_shortcut": true,
		"compare_shortcut": true,
		"export_install_shortcut": true,
		"lorebook_shortcut": true,
		"detachable_windows_preserved": true,
	}


func _install_layout_menu_v0201() -> void:
	var top := _first_flow_row()
	if top == null:
		return
	_layout_menu_v0201 = MenuButton.new()
	_layout_menu_v0201.name = "WorkspaceLayoutMenuV0201"
	_layout_menu_v0201.text = "Layout: Editing"
	_layout_menu_v0201.tooltip_text = "Switch between task-focused workspace arrangements without closing detachable tools."
	var popup := _layout_menu_v0201.get_popup()
	for index in range(CCFWorkflowDiscoveryServiceV0201.workspace_layouts().size()):
		var layout := CCFWorkflowDiscoveryServiceV0201.workspace_layouts()[index]
		popup.add_item(str(layout.get("label", "Layout")), index)
		popup.set_item_tooltip(index, str(layout.get("description", "")))
	popup.id_pressed.connect(_on_layout_selected_v0201)
	top.add_child(_layout_menu_v0201)
	var save_index := _child_index_by_button_text(top, "Save")
	if save_index >= 0:
		top.move_child(_layout_menu_v0201, save_index + 1)


func _decorate_shortcuts_v0201() -> void:
	if _save_button != null:
		_save_button.tooltip_text = "Save the current project (Ctrl+S)."
	var review_button := _find_workspace_button("AI Review")
	if review_button != null:
		review_button.tooltip_text += " Shortcut: Ctrl+Shift+R."


func _on_layout_selected_v0201(index: int) -> void:
	var layouts := CCFWorkflowDiscoveryServiceV0201.workspace_layouts()
	if index < 0 or index >= layouts.size():
		return
	apply_workspace_layout_v0201(str(layouts[index].get("id", "editing")))


func _sync_layout_menu_v0201() -> void:
	if _layout_menu_v0201 == null:
		return
	var active_label := "Editing"
	for layout in CCFWorkflowDiscoveryServiceV0201.workspace_layouts():
		if str(layout.get("id", "")) == _active_layout_v0201:
			active_label = str(layout.get("label", "Editing"))
			break
	_layout_menu_v0201.text = "Layout: %s" % active_label


func _store_layout_v0201() -> void:
	var ui_value: Variant = _settings.get("ui", {})
	var ui: Dictionary = {}
	if ui_value is Dictionary:
		ui = (ui_value as Dictionary).duplicate(true)
	ui["workspace_layout_v0201"] = _active_layout_v0201
	_settings["ui"] = ui
	CCFSettingsService.save_settings(_settings)


func _select_workspace_tab_v0201(title_text: String) -> void:
	if _tabs == null or _tabs.get_tab_count() == 0:
		return
	if title_text.is_empty():
		_tabs.current_tab = 0
		return
	for index in range(_tabs.get_tab_count()):
		if _tabs.get_tab_title(index) == title_text:
			_tabs.current_tab = index
			return


func _focus_relative_field_v0201(direction: int) -> void:
	var controls: Array[Control] = []
	for field_row_value in _field_controls.values():
		if not field_row_value is Dictionary:
			continue
		var control := (field_row_value as Dictionary).get("control") as Control
		if (
			control != null
			and control.is_visible_in_tree()
			and control.focus_mode != Control.FOCUS_NONE
		):
			controls.append(control)
	if controls.is_empty():
		return
	var current := get_viewport().gui_get_focus_owner()
	var current_index := controls.find(current)
	var next_index := 0
	if current_index >= 0:
		next_index = posmod(current_index + direction, controls.size())
	elif direction < 0:
		next_index = controls.size() - 1
	controls[next_index].grab_focus()
