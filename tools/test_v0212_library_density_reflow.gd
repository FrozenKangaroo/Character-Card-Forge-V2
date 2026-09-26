extends SceneTree

const LIBRARY_CURRENT = preload("res://scripts/ui/library_view_current.gd")


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0212_LIBRARY_DENSITY_REFLOW_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _row(index: int) -> Dictionary:
	return {
		"project_id": "density-reflow-%02d" % index,
		"name": "Density Reflow %02d" % index,
		"summary": "A stable row for immediate card-density reflow coverage.",
		"thumbnail_path": "",
		"character_count": 1,
		"character_names": ["Character %02d" % index],
		"workflow_state": "draft",
		"favorite": false,
		"archived": false,
		"sensitive": false,
		"series_name": "",
		"folder": "",
		"collections": [],
		"all_tags": [],
		"front_porch_sync_states_v0185": [],
		"front_porch_deployment_queued_v0185": false,
	}


func _run() -> void:
	var view := LIBRARY_CURRENT.new()
	view.size = Vector2(1000, 720)
	root.add_child(view)
	await process_frame
	await process_frame

	var slider := view.find_child("CardDensitySliderV0191", true, false) as HSlider
	var grid := view.get("_grid") as GridContainer
	var grid_scroll := view.get("_grid_scroll") as ScrollContainer
	if not _require(
		slider != null and grid != null and grid_scroll != null,
		"The current Library must expose its density control and virtualized grid."
	):
		return

	var rows: Array[Dictionary] = []
	for index in range(42):
		rows.append(_row(index))
	view.set("_filtered", rows)
	# This width fits two Large cards and three Mini cards. It remains unchanged
	# across the density transition to reproduce the reported stale-column bug.
	grid_scroll.size = Vector2(500, 600)
	slider.set_value_no_signal(CCFLibraryV0191View.DENSITY_COMFORTABLE)
	view.call("_update_grid_columns")
	view.call("_rebuild_grid")
	var width_before := grid_scroll.size.x
	var large_columns := grid.columns

	slider.set_value_no_signal(CCFLibraryV0191View.DENSITY_MINI)
	view.call("_on_card_density_changed_v0191", float(CCFLibraryV0191View.DENSITY_MINI))
	var mini_columns := grid.columns
	var virtual_columns := int(view.get("_virtual_columns_v0200"))
	if not _require(
		is_equal_approx(width_before, grid_scroll.size.x)
		and large_columns == 2
		and mini_columns == 3
		and virtual_columns == mini_columns,
		"Large → Mini must immediately recalculate columns at the same window width."
	):
		return

	var capabilities: Dictionary = view.density_reflow_capabilities_v0212()
	if not _require(
		bool(capabilities.get("reflow_on_density_change", false))
		and bool(capabilities.get("window_resize_not_required", false))
		and bool(capabilities.get("virtualized_grid_preserved", false)),
		"The current Library must disclose its immediate density-reflow contract."
	):
		return

	await process_frame
	if not _require(
		grid.columns == int(view.get("_virtual_columns_v0200"))
		and grid.get_child_count() > 0,
		(
			"The deferred virtual refresh must preserve the recalculated Mini layout "
			+ "(grid=%d, virtual=%d, large=%d, cards=%d)."
			% [
				grid.columns,
				int(view.get("_virtual_columns_v0200")),
				large_columns,
				grid.get_child_count(),
			]
		)
	):
		return

	view.queue_free()
	await process_frame
	print("V0212_LIBRARY_DENSITY_REFLOW_OK")
	quit(0)
