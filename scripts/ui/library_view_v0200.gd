class_name CCFLibraryV0200View
extends "res://scripts/ui/library_view_v0191.gd"

const LIBRARY_CACHE_SERVICE_V0200 = preload(
	"res://scripts/services/library_cache_service_v0200.gd"
)

const VIRTUAL_CARD_WIDTHS_V0200 := [130.0, 160.0, 195.0, 230.0]
const VIRTUAL_CARD_HEIGHTS_V0200 := [170.0, 226.0, 286.0, 330.0]
const GRID_GAP_V0200 := 12.0

var _virtual_host_v0200: VBoxContainer
var _virtual_top_spacer_v0200: Control
var _virtual_bottom_spacer_v0200: Control
var _library_storage_banner_v0200: Label
var _virtual_start_v0200 := -1
var _virtual_end_v0200 := -1
var _virtual_columns_v0200 := 1
var _virtual_refresh_pending_v0200 := false
var _virtual_update_active_v0200 := false
var _v0200_ready := false
var _library_settings_v0200: Dictionary = {}


func _ready() -> void:
	super._ready()
	_v0200_ready = true
	if _grid_scroll != null:
		var scroll_bar := _grid_scroll.get_v_scroll_bar()
		if scroll_bar != null and not scroll_bar.value_changed.is_connected(
			_on_virtual_scroll_v0200
		):
			scroll_bar.value_changed.connect(_on_virtual_scroll_v0200)
	_update_storage_banner_v0200()
	_update_grid_columns()


func _build_library_body() -> void:
	super._build_library_body()
	if _grid_scroll == null or _grid == null:
		return
	var centre := _grid_scroll.get_parent()
	_library_storage_banner_v0200 = Label.new()
	_library_storage_banner_v0200.name = "LibraryStorageBannerV0200"
	_library_storage_banner_v0200.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_library_storage_banner_v0200.modulate = Color(0.68, 0.72, 0.82)
	centre.add_child(_library_storage_banner_v0200)
	centre.move_child(
		_library_storage_banner_v0200, maxi(0, _grid_scroll.get_index())
	)

	_grid_scroll.remove_child(_grid)
	_virtual_host_v0200 = VBoxContainer.new()
	_virtual_host_v0200.name = "VirtualLibraryHostV0200"
	_virtual_host_v0200.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_virtual_host_v0200.add_theme_constant_override("separation", 0)
	_grid_scroll.add_child(_virtual_host_v0200)
	_virtual_top_spacer_v0200 = Control.new()
	_virtual_top_spacer_v0200.name = "VirtualTopSpacerV0200"
	_virtual_top_spacer_v0200.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_virtual_host_v0200.add_child(_virtual_top_spacer_v0200)
	_virtual_host_v0200.add_child(_grid)
	_virtual_bottom_spacer_v0200 = Control.new()
	_virtual_bottom_spacer_v0200.name = "VirtualBottomSpacerV0200"
	_virtual_bottom_spacer_v0200.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_virtual_host_v0200.add_child(_virtual_bottom_spacer_v0200)


func refresh_projects(force_rebuild: bool = false) -> void:
	super.refresh_projects(force_rebuild)
	_library_settings_v0200 = CCFSettingsService.load_settings()
	var cache_result := LIBRARY_CACHE_SERVICE_V0200.maintain_v0200(
		_library_settings_v0200
	)
	if _v0200_ready and bool(cache_result.get("ok", false)) and _status != null:
		var removed := int(cache_result.get("removed", 0))
		if removed > 0:
			_status.text += " • %d expired cache file%s cleaned" % [
				removed, "" if removed == 1 else "s"
			]
	_update_storage_banner_v0200()


func _rebuild_grid() -> void:
	_virtual_start_v0200 = -1
	_virtual_end_v0200 = -1
	_render_virtual_window_v0200(true)


func _update_detail(row: Dictionary) -> void:
	var display_row := row
	var blur_sensitive := (
		_v0184_ready
		and _selected_metadata_v0184(_sensitive_policy) == "blur"
		and not _reveal_sensitive.button_pressed
		and bool(row.get("sensitive", false))
	)
	if not row.is_empty() and not blur_sensitive:
		display_row = row.duplicate(true)
		display_row["thumbnail_path"] = (
			LIBRARY_CACHE_SERVICE_V0200.thumbnail_for_density_v0200(
				display_row, DENSITY_COMFORTABLE
			)
		)
		LIBRARY_CACHE_SERVICE_V0200.flush_accesses_v0200()
	super._update_detail(display_row)


func _update_grid_columns() -> void:
	if _grid == null or _grid_scroll == null:
		return
	var density := _card_density_v0191()
	var card_width: float = VIRTUAL_CARD_WIDTHS_V0200[density]
	var usable_width := maxf(card_width, _grid_scroll.size.x - 20.0)
	var next_columns := maxi(
		1, int(floor((usable_width + GRID_GAP_V0200) / (card_width + GRID_GAP_V0200)))
	)
	_grid.columns = next_columns
	if next_columns != _virtual_columns_v0200:
		_virtual_columns_v0200 = next_columns
		_virtual_start_v0200 = -1
		_virtual_end_v0200 = -1
	_schedule_virtual_refresh_v0200()


func _on_virtual_scroll_v0200(_value: float) -> void:
	_schedule_virtual_refresh_v0200()


func _schedule_virtual_refresh_v0200() -> void:
	if _virtual_refresh_pending_v0200:
		return
	_virtual_refresh_pending_v0200 = true
	call_deferred("_run_virtual_refresh_v0200")


func _run_virtual_refresh_v0200() -> void:
	_virtual_refresh_pending_v0200 = false
	_render_virtual_window_v0200(false)


func _render_virtual_window_v0200(force: bool) -> void:
	if (
		_virtual_update_active_v0200
		or _grid == null
		or _grid_scroll == null
		or _virtual_top_spacer_v0200 == null
		or _virtual_bottom_spacer_v0200 == null
	):
		return
	_virtual_update_active_v0200 = true
	var density := _card_density_v0191()
	var card_height: float = VIRTUAL_CARD_HEIGHTS_V0200[density]
	var row_pitch := card_height + GRID_GAP_V0200
	var column_count := maxi(1, _grid.columns)
	var total_rows := ceili(float(_filtered.size()) / float(column_count))
	var scroll_value := _grid_scroll.get_v_scroll_bar().value
	var viewport_height := maxf(card_height, _grid_scroll.size.y)
	var first_visible_row := clampi(
		int(floor(scroll_value / row_pitch)), 0, maxi(0, total_rows - 1)
	)
	var visible_rows := maxi(1, ceili(viewport_height / row_pitch))
	var storage_value: Variant = _library_settings_v0200.get("library_storage", {})
	var storage: Dictionary = storage_value if storage_value is Dictionary else {}
	var buffer_rows := clampi(
		int(storage.get("virtualization_buffer_rows", 2)), 1, 8
	)
	var start_row := maxi(0, first_visible_row - buffer_rows)
	var end_row := mini(total_rows, first_visible_row + visible_rows + buffer_rows)
	var start_index := mini(_filtered.size(), start_row * column_count)
	var end_index := mini(_filtered.size(), end_row * column_count)
	_virtual_top_spacer_v0200.custom_minimum_size.y = float(start_row) * row_pitch
	_virtual_bottom_spacer_v0200.custom_minimum_size.y = float(
		maxi(0, total_rows - end_row)
	) * row_pitch
	if not force and start_index == _virtual_start_v0200 and end_index == _virtual_end_v0200:
		_virtual_update_active_v0200 = false
		return
	_virtual_start_v0200 = start_index
	_virtual_end_v0200 = end_index
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_card_nodes.clear()
	var blur_sensitive := (
		_v0184_ready
		and _selected_metadata_v0184(_sensitive_policy) == "blur"
		and not _reveal_sensitive.button_pressed
	)
	for row_index in range(start_index, end_index):
		var row := _presentation_row(_filtered[row_index])
		if blur_sensitive and bool(row.get("sensitive", false)):
			row = row.duplicate(true)
			row["thumbnail_path"] = ""
			row["artwork_blurred"] = true
		else:
			row = row.duplicate(true)
			row["thumbnail_path"] = LIBRARY_CACHE_SERVICE_V0200.thumbnail_for_density_v0200(
				row, density
			)
		var project_id := str(row.get("project_id", ""))
		var card := CCFLibraryProjectCard.new()
		card.configure(row, _selected_project_ids.has(project_id), density)
		card.primary_requested.connect(_on_card_primary_requested)
		card.selection_changed.connect(_on_card_selection_changed)
		card.open_requested.connect(_open_project_id)
		card.context_requested.connect(_show_context_menu_v0184)
		_grid.add_child(card)
		_card_nodes[project_id] = card
	LIBRARY_CACHE_SERVICE_V0200.flush_accesses_v0200()
	_update_storage_banner_v0200()
	_virtual_update_active_v0200 = false


func _update_storage_banner_v0200() -> void:
	if _library_storage_banner_v0200 == null:
		return
	var status := CCFStorageService.library_storage_status_v0200()
	var mode := str(status.get("mode", "local"))
	if not bool(status.get("available", false)):
		_library_storage_banner_v0200.text = (
			"Portable library unavailable — no local fallback was opened. Reconnect the share or choose a library in Settings."
		)
		_library_storage_banner_v0200.modulate = Color(1.0, 0.55, 0.48)
		return
	if mode == "portable":
		_library_storage_banner_v0200.text = (
			"Portable library • cooperative single writer • indexes and thumbnails stay local"
		)
		_library_storage_banner_v0200.modulate = Color(0.65, 0.82, 0.72)
	else:
		_library_storage_banner_v0200.text = (
			"Local library • virtualized view renders %d of %d matching cards" % [
				maxi(0, _virtual_end_v0200 - _virtual_start_v0200), _filtered.size()
			]
		)
		_library_storage_banner_v0200.modulate = Color(0.68, 0.72, 0.82)


func large_library_capabilities_v0200() -> Dictionary:
	var storage_value: Variant = _library_settings_v0200.get("library_storage", {})
	var storage: Dictionary = storage_value if storage_value is Dictionary else {}
	return {
		"virtualized_grid": true,
		"list_uses_native_item_rendering": true,
		"rendered_card_count": maxi(0, _virtual_end_v0200 - _virtual_start_v0200),
		"matching_card_count": _filtered.size(),
		"buffer_rows": clampi(
			int(storage.get("virtualization_buffer_rows", 2)), 1, 8
		),
		"local_thumbnail_derivatives": true,
		"bounded_thumbnail_cache": true,
		"portable_library": true,
		"unavailable_share_fallback": false
	}
