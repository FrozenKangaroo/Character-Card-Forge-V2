class_name CCFLibraryV0191View
extends "res://scripts/ui/library_view_v0185.gd"

const DENSITY_MINI := 0
const DENSITY_COMPACT := 1
const DENSITY_MEDIUM := 2
const DENSITY_COMFORTABLE := 3
const DEFAULT_DENSITY := DENSITY_MEDIUM

var _card_density_slider_v0191: HSlider
var _card_density_label_v0191: Label
var _active_project_toggle_v0191: Button
var _active_project_details_v0191: VBoxContainer
var _v0191_density_ready := false


func _ready() -> void:
	super._ready()
	_v0191_density_ready = true
	_apply_active_project_visibility_v0191(
		bool(_view_state.get("active_project_expanded_v0191", false)), false
	)
	_update_density_label_v0191()
	_apply_view_visibility()


func _build_toolbar() -> void:
	super._build_toolbar()
	if _view_option == null or _view_option.get_parent() == null:
		return
	var toolbar := _view_option.get_parent()
	_card_density_label_v0191 = Label.new()
	_card_density_label_v0191.name = "CardDensityLabelV0191"
	_card_density_label_v0191.text = "Cards"
	_card_density_label_v0191.tooltip_text = "Adjust thumbnail-card size and visible detail."
	toolbar.add_child(_card_density_label_v0191)
	toolbar.move_child(_card_density_label_v0191, _view_option.get_index() + 1)
	_card_density_slider_v0191 = HSlider.new()
	_card_density_slider_v0191.name = "CardDensitySliderV0191"
	_card_density_slider_v0191.min_value = DENSITY_MINI
	_card_density_slider_v0191.max_value = DENSITY_COMFORTABLE
	_card_density_slider_v0191.step = 1.0
	_card_density_slider_v0191.custom_minimum_size.x = 112
	_card_density_slider_v0191.value = clampi(
		int(_view_state.get("card_density_v0191", DEFAULT_DENSITY)),
		DENSITY_MINI,
		DENSITY_COMFORTABLE
	)
	_card_density_slider_v0191.tooltip_text = (
		"Smaller cards progressively hide secondary details. "
		+ "At the smallest size, the project name is overlaid on the artwork."
	)
	_card_density_slider_v0191.value_changed.connect(_on_card_density_changed_v0191)
	toolbar.add_child(_card_density_slider_v0191)
	toolbar.move_child(_card_density_slider_v0191, _card_density_label_v0191.get_index() + 1)
	_update_density_label_v0191()


func _build_bulk_toolbar() -> Control:
	var panel := super._build_bulk_toolbar()
	if panel.get_child_count() == 0:
		return panel
	var margin := panel.get_child(0) as MarginContainer
	if margin == null or margin.get_child_count() == 0:
		return panel
	var rows := margin.get_child(0) as VBoxContainer
	if rows == null or rows.get_child_count() == 0:
		return panel
	var selection_row := rows.get_child(0) as HFlowContainer
	if selection_row == null:
		return panel
	_active_project_toggle_v0191 = Button.new()
	_active_project_toggle_v0191.name = "ActiveProjectToggleV0191"
	_active_project_toggle_v0191.toggle_mode = true
	_active_project_toggle_v0191.tooltip_text = (
		"Show or hide project organisation and batch tools without losing the current selection."
	)
	_active_project_toggle_v0191.toggled.connect(_apply_active_project_visibility_v0191)
	selection_row.add_child(_active_project_toggle_v0191)
	_active_project_details_v0191 = VBoxContainer.new()
	_active_project_details_v0191.name = "ActiveProjectDetailsV0191"
	_active_project_details_v0191.add_theme_constant_override("separation", 8)
	var detail_rows: Array[Node] = []
	for child_index in range(1, rows.get_child_count()):
		detail_rows.append(rows.get_child(child_index))
	for detail_row in detail_rows:
		rows.remove_child(detail_row)
		_active_project_details_v0191.add_child(detail_row)
	rows.add_child(_active_project_details_v0191)
	_apply_active_project_visibility_v0191(
		bool(_view_state.get("active_project_expanded_v0191", false)), false
	)
	return panel


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_card_nodes.clear()
	var blur_sensitive := (
		_v0184_ready
		and _selected_metadata_v0184(_sensitive_policy) == "blur"
		and not _reveal_sensitive.button_pressed
	)
	for raw_row in _filtered:
		var row := _presentation_row(raw_row)
		if blur_sensitive and bool(row.get("sensitive", false)):
			row = row.duplicate(true)
			row["thumbnail_path"] = ""
			row["artwork_blurred"] = true
		var project_id := str(row.get("project_id", ""))
		var card := CCFLibraryProjectCard.new()
		card.configure(row, _selected_project_ids.has(project_id), _card_density_v0191())
		card.primary_requested.connect(_on_card_primary_requested)
		card.selection_changed.connect(_on_card_selection_changed)
		card.open_requested.connect(_open_project_id)
		card.context_requested.connect(_show_context_menu_v0184)
		_grid.add_child(card)
		_card_nodes[project_id] = card
	call_deferred("_update_grid_columns")


func _update_grid_columns() -> void:
	if _grid == null or _grid_scroll == null:
		return
	var card_widths := [130.0, 160.0, 195.0, 230.0]
	var card_width: float = card_widths[_card_density_v0191()]
	var usable_width := maxf(card_width, _grid_scroll.size.x - 20.0)
	_grid.columns = maxi(1, int(floor((usable_width + 12.0) / (card_width + 12.0))))


func _apply_view_visibility() -> void:
	super._apply_view_visibility()
	if _card_density_slider_v0191 != null:
		var grid_mode := str(_view_state.get("view_mode", VIEW_GRID)) == VIEW_GRID
		_card_density_slider_v0191.editable = grid_mode
		_card_density_label_v0191.modulate = (
			Color.WHITE if grid_mode else Color(0.55, 0.56, 0.62)
		)


func _save_view_state() -> void:
	super._save_view_state()
	if _card_density_slider_v0191 != null:
		_view_state["card_density_v0191"] = _card_density_v0191()
	if _active_project_toggle_v0191 != null:
		_view_state["active_project_expanded_v0191"] = (
			_active_project_toggle_v0191.button_pressed
		)
	CCFLibraryService.save_view_state(_view_state)


func _on_card_density_changed_v0191(_value: float) -> void:
	_update_density_label_v0191()
	if not _v0191_density_ready:
		return
	_view_state["card_density_v0191"] = _card_density_v0191()
	_rebuild_grid()
	_save_view_state()


func _apply_active_project_visibility_v0191(expanded: bool, save_state: bool = true) -> void:
	if _active_project_details_v0191 == null or _active_project_toggle_v0191 == null:
		return
	_active_project_details_v0191.visible = expanded
	_active_project_toggle_v0191.set_pressed_no_signal(expanded)
	_active_project_toggle_v0191.text = (
		"Hide project tools" if expanded else "Show project tools"
	)
	if save_state and _v0191_density_ready:
		_view_state["active_project_expanded_v0191"] = expanded
		_save_view_state()


func _card_density_v0191() -> int:
	if _card_density_slider_v0191 == null:
		return DEFAULT_DENSITY
	return clampi(
		roundi(_card_density_slider_v0191.value),
		DENSITY_MINI,
		DENSITY_COMFORTABLE
	)


func _update_density_label_v0191() -> void:
	if _card_density_label_v0191 == null:
		return
	var labels := ["Cards: Mini", "Cards: Compact", "Cards: Medium", "Cards: Large"]
	_card_density_label_v0191.text = labels[_card_density_v0191()]


func library_density_capabilities_v0191() -> Dictionary:
	return {
		"active_project_collapsible": _active_project_toggle_v0191 != null,
		"active_project_default_expanded": false,
		"persistent_card_density": _card_density_slider_v0191 != null,
		"density_levels": 4,
		"progressive_detail": true,
		"mini_name_overlay": true,
		"compact_list_unchanged": true
	}
