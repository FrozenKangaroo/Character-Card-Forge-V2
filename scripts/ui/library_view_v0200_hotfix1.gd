class_name CCFLibraryV0200Hotfix1View
extends "res://scripts/ui/library_view_v0200.gd"

const PANEL_FILTERS := 0
const PANEL_PROJECT_TOOLS := 1
const PANEL_DETAILS := 2
const PANEL_AUTO_HIDE := 3
const PANEL_SHOW_ALL := 10
const PANEL_FOCUS_CARDS := 11

var _library_split_v0200_hotfix1: HSplitContainer
var _library_centre_v0200_hotfix1: Control
var _filter_panel_v0200_hotfix1: Control
var _detail_panel_v0200_hotfix1: Control
var _filter_wrapper_v0200_hotfix1: HBoxContainer
var _detail_wrapper_v0200_hotfix1: HBoxContainer
var _filter_handle_v0200_hotfix1: Button
var _detail_handle_v0200_hotfix1: Button
var _panels_menu_v0200_hotfix1: MenuButton
var _side_auto_hide_v0200_hotfix1 := false
var _panels_ready_v0200_hotfix1 := false


func _ready() -> void:
	super._ready()
	_panels_ready_v0200_hotfix1 = true
	_side_auto_hide_v0200_hotfix1 = bool(
		_view_state.get("library_side_auto_hide_v0200_hotfix1", false)
	)
	_set_filter_panel_expanded_v0200_hotfix1(
		bool(_view_state.get("library_filters_expanded_v0200_hotfix1", true)),
		false
	)
	_set_detail_panel_expanded_v0200_hotfix1(
		bool(_view_state.get("library_details_expanded_v0200_hotfix1", true)),
		false
	)
	if _side_auto_hide_v0200_hotfix1:
		_collapse_auto_hide_side_panels_v0200_hotfix1()
	if (
		_active_project_toggle_v0191 != null
		and not _active_project_toggle_v0191.toggled.is_connected(
			_on_project_tools_toggled_v0200_hotfix1
		)
	):
		_active_project_toggle_v0191.toggled.connect(
			_on_project_tools_toggled_v0200_hotfix1
		)
	_sync_panels_menu_v0200_hotfix1()


func _build_toolbar() -> void:
	super._build_toolbar()
	if _view_option == null or _view_option.get_parent() == null:
		return
	_panels_menu_v0200_hotfix1 = MenuButton.new()
	_panels_menu_v0200_hotfix1.name = "LibraryPanelsMenuV0200Hotfix1"
	_panels_menu_v0200_hotfix1.text = "Panels"
	_panels_menu_v0200_hotfix1.tooltip_text = (
		"Show, hide or auto-hide Library Filters, Project Tools and Details."
	)
	var popup := _panels_menu_v0200_hotfix1.get_popup()
	popup.add_check_item("Library Filters", PANEL_FILTERS)
	popup.add_check_item("Project Tools", PANEL_PROJECT_TOOLS)
	popup.add_check_item("Project Details", PANEL_DETAILS)
	popup.add_separator()
	popup.add_check_item("Auto-hide side panels", PANEL_AUTO_HIDE)
	popup.add_separator()
	popup.add_item("Show all panels", PANEL_SHOW_ALL)
	popup.add_item("Focus card area", PANEL_FOCUS_CARDS)
	popup.id_pressed.connect(_on_panels_menu_v0200_hotfix1)
	popup.about_to_popup.connect(_sync_panels_menu_v0200_hotfix1)
	_view_option.get_parent().add_child(_panels_menu_v0200_hotfix1)


func _build_library_body() -> void:
	super._build_library_body()
	if _grid_scroll == null or _grid_scroll.get_parent() == null:
		return
	_library_centre_v0200_hotfix1 = _grid_scroll.get_parent() as Control
	if _library_centre_v0200_hotfix1 == null:
		return
	_library_split_v0200_hotfix1 = (
		_library_centre_v0200_hotfix1.get_parent() as HSplitContainer
	)
	if _library_split_v0200_hotfix1 == null:
		return
	var centre_index := _library_centre_v0200_hotfix1.get_index()
	if centre_index <= 0 or centre_index >= _library_split_v0200_hotfix1.get_child_count() - 1:
		return
	_filter_panel_v0200_hotfix1 = _library_split_v0200_hotfix1.get_child(
		centre_index - 1
	) as Control
	_detail_panel_v0200_hotfix1 = _library_split_v0200_hotfix1.get_child(
		centre_index + 1
	) as Control
	if _filter_panel_v0200_hotfix1 == null or _detail_panel_v0200_hotfix1 == null:
		return

	_filter_wrapper_v0200_hotfix1 = HBoxContainer.new()
	_filter_wrapper_v0200_hotfix1.name = "LibraryFilterWrapperV0200Hotfix1"
	_filter_wrapper_v0200_hotfix1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_filter_wrapper_v0200_hotfix1.add_theme_constant_override("separation", 4)
	_library_split_v0200_hotfix1.remove_child(_filter_panel_v0200_hotfix1)
	_library_split_v0200_hotfix1.add_child(_filter_wrapper_v0200_hotfix1)
	_library_split_v0200_hotfix1.move_child(
		_filter_wrapper_v0200_hotfix1,
		_library_centre_v0200_hotfix1.get_index()
	)
	_filter_wrapper_v0200_hotfix1.add_child(_filter_panel_v0200_hotfix1)
	_filter_handle_v0200_hotfix1 = _panel_handle_v0200_hotfix1(
		"LibraryFilterHandleV0200Hotfix1",
		"Collapse or reveal Library Filters",
		_toggle_filter_panel_v0200_hotfix1
	)
	_filter_handle_v0200_hotfix1.mouse_entered.connect(
		_reveal_filter_for_auto_hide_v0200_hotfix1
	)
	_filter_wrapper_v0200_hotfix1.add_child(_filter_handle_v0200_hotfix1)

	_detail_wrapper_v0200_hotfix1 = HBoxContainer.new()
	_detail_wrapper_v0200_hotfix1.name = "LibraryDetailWrapperV0200Hotfix1"
	_detail_wrapper_v0200_hotfix1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_wrapper_v0200_hotfix1.add_theme_constant_override("separation", 4)
	_library_split_v0200_hotfix1.remove_child(_detail_panel_v0200_hotfix1)
	_library_split_v0200_hotfix1.add_child(_detail_wrapper_v0200_hotfix1)
	_detail_handle_v0200_hotfix1 = _panel_handle_v0200_hotfix1(
		"LibraryDetailHandleV0200Hotfix1",
		"Collapse or reveal Project Details",
		_toggle_detail_panel_v0200_hotfix1
	)
	_detail_handle_v0200_hotfix1.mouse_entered.connect(
		_reveal_detail_for_auto_hide_v0200_hotfix1
	)
	_detail_wrapper_v0200_hotfix1.add_child(_detail_handle_v0200_hotfix1)
	_detail_wrapper_v0200_hotfix1.add_child(_detail_panel_v0200_hotfix1)


func _input(event: InputEvent) -> void:
	if (
		not _panels_ready_v0200_hotfix1
		or not _side_auto_hide_v0200_hotfix1
		or not visible
		or not event is InputEventMouseButton
		or not event.pressed
		or _library_centre_v0200_hotfix1 == null
	):
		return
	var mouse_event := event as InputEventMouseButton
	if _library_centre_v0200_hotfix1.get_global_rect().has_point(mouse_event.position):
		call_deferred("_collapse_auto_hide_side_panels_v0200_hotfix1")


func _save_view_state() -> void:
	super._save_view_state()
	if not _panels_ready_v0200_hotfix1:
		return
	_view_state["library_filters_expanded_v0200_hotfix1"] = (
		_filter_panel_v0200_hotfix1 != null and _filter_panel_v0200_hotfix1.visible
	)
	_view_state["library_details_expanded_v0200_hotfix1"] = (
		_detail_panel_v0200_hotfix1 != null and _detail_panel_v0200_hotfix1.visible
	)
	_view_state["library_side_auto_hide_v0200_hotfix1"] = (
		_side_auto_hide_v0200_hotfix1
	)
	CCFLibraryService.save_view_state(_view_state)


func _panel_handle_v0200_hotfix1(
	handle_name: String, tooltip: String, callback: Callable
) -> Button:
	var handle := Button.new()
	handle.name = handle_name
	handle.custom_minimum_size = Vector2(28, 52)
	handle.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	handle.tooltip_text = tooltip
	handle.pressed.connect(callback)
	return handle


func _toggle_filter_panel_v0200_hotfix1() -> void:
	_set_filter_panel_expanded_v0200_hotfix1(
		not _filter_panel_v0200_hotfix1.visible
	)


func _toggle_detail_panel_v0200_hotfix1() -> void:
	_set_detail_panel_expanded_v0200_hotfix1(
		not _detail_panel_v0200_hotfix1.visible
	)


func _set_filter_panel_expanded_v0200_hotfix1(
	expanded: bool, save_state: bool = true
) -> void:
	if _filter_panel_v0200_hotfix1 == null or _filter_handle_v0200_hotfix1 == null:
		return
	_filter_panel_v0200_hotfix1.visible = expanded
	_filter_handle_v0200_hotfix1.text = "◀" if expanded else "▶"
	_filter_handle_v0200_hotfix1.tooltip_text = (
		"Collapse Library Filters" if expanded else "Reveal Library Filters"
	)
	_after_panel_visibility_changed_v0200_hotfix1(save_state)


func _set_detail_panel_expanded_v0200_hotfix1(
	expanded: bool, save_state: bool = true
) -> void:
	if _detail_panel_v0200_hotfix1 == null or _detail_handle_v0200_hotfix1 == null:
		return
	_detail_panel_v0200_hotfix1.visible = expanded
	_detail_handle_v0200_hotfix1.text = "▶" if expanded else "◀"
	_detail_handle_v0200_hotfix1.tooltip_text = (
		"Collapse Project Details" if expanded else "Reveal Project Details"
	)
	_after_panel_visibility_changed_v0200_hotfix1(save_state)


func _after_panel_visibility_changed_v0200_hotfix1(save_state: bool) -> void:
	_sync_panels_menu_v0200_hotfix1()
	call_deferred("_update_grid_columns")
	if save_state and _panels_ready_v0200_hotfix1:
		_save_view_state()


func _reveal_filter_for_auto_hide_v0200_hotfix1() -> void:
	if _side_auto_hide_v0200_hotfix1 and not _filter_panel_v0200_hotfix1.visible:
		_set_filter_panel_expanded_v0200_hotfix1(true, false)


func _reveal_detail_for_auto_hide_v0200_hotfix1() -> void:
	if _side_auto_hide_v0200_hotfix1 and not _detail_panel_v0200_hotfix1.visible:
		_set_detail_panel_expanded_v0200_hotfix1(true, false)


func _collapse_auto_hide_side_panels_v0200_hotfix1() -> void:
	if not _side_auto_hide_v0200_hotfix1:
		return
	_set_filter_panel_expanded_v0200_hotfix1(false, false)
	_set_detail_panel_expanded_v0200_hotfix1(false, false)


func _on_project_tools_toggled_v0200_hotfix1(_expanded: bool) -> void:
	_sync_panels_menu_v0200_hotfix1()


func _on_panels_menu_v0200_hotfix1(action_id: int) -> void:
	match action_id:
		PANEL_FILTERS:
			_toggle_filter_panel_v0200_hotfix1()
		PANEL_PROJECT_TOOLS:
			_apply_active_project_visibility_v0191(
				not _active_project_toggle_v0191.button_pressed
			)
		PANEL_DETAILS:
			_toggle_detail_panel_v0200_hotfix1()
		PANEL_AUTO_HIDE:
			_side_auto_hide_v0200_hotfix1 = not _side_auto_hide_v0200_hotfix1
			if _side_auto_hide_v0200_hotfix1:
				_collapse_auto_hide_side_panels_v0200_hotfix1()
			_save_view_state()
		PANEL_SHOW_ALL:
			_side_auto_hide_v0200_hotfix1 = false
			_set_filter_panel_expanded_v0200_hotfix1(true, false)
			_set_detail_panel_expanded_v0200_hotfix1(true, false)
			_apply_active_project_visibility_v0191(true, false)
			_save_view_state()
		PANEL_FOCUS_CARDS:
			_set_filter_panel_expanded_v0200_hotfix1(false, false)
			_set_detail_panel_expanded_v0200_hotfix1(false, false)
			_apply_active_project_visibility_v0191(false, false)
			_save_view_state()
	_sync_panels_menu_v0200_hotfix1()


func _sync_panels_menu_v0200_hotfix1() -> void:
	if _panels_menu_v0200_hotfix1 == null:
		return
	var popup := _panels_menu_v0200_hotfix1.get_popup()
	var filters_index := popup.get_item_index(PANEL_FILTERS)
	var tools_index := popup.get_item_index(PANEL_PROJECT_TOOLS)
	var details_index := popup.get_item_index(PANEL_DETAILS)
	var auto_hide_index := popup.get_item_index(PANEL_AUTO_HIDE)
	if filters_index >= 0:
		popup.set_item_checked(
			filters_index,
			_filter_panel_v0200_hotfix1 != null and _filter_panel_v0200_hotfix1.visible
		)
	if tools_index >= 0:
		popup.set_item_checked(
			tools_index,
			_active_project_toggle_v0191 != null
			and _active_project_toggle_v0191.button_pressed
		)
	if details_index >= 0:
		popup.set_item_checked(
			details_index,
			_detail_panel_v0200_hotfix1 != null and _detail_panel_v0200_hotfix1.visible
		)
	if auto_hide_index >= 0:
		popup.set_item_checked(auto_hide_index, _side_auto_hide_v0200_hotfix1)


func library_panel_capabilities_v0200_hotfix1() -> Dictionary:
	return {
		"filters_collapsible": _filter_handle_v0200_hotfix1 != null,
		"details_collapsible": _detail_handle_v0200_hotfix1 != null,
		"project_tools_in_panel_menu": _active_project_toggle_v0191 != null,
		"side_auto_hide_opt_in": true,
		"side_auto_hide_enabled": _side_auto_hide_v0200_hotfix1,
		"persistent_layout": true,
		"filter_handle_visible": (
			_filter_handle_v0200_hotfix1 != null and _filter_handle_v0200_hotfix1.visible
		),
		"detail_handle_visible": (
			_detail_handle_v0200_hotfix1 != null and _detail_handle_v0200_hotfix1.visible
		)
	}
