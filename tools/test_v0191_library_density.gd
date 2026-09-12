extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0191_LIBRARY_DENSITY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _card_row() -> Dictionary:
	return {
		"project_id": "density-fixture",
		"name": "Seraphina Vale",
		"favorite": true,
		"thumbnail_path": "",
		"character_count": 2,
		"workflow_state": "stable",
		"summary": "A complete summary that is progressively hidden at smaller sizes.",
		"character_names": ["Seraphina", "Mara"],
		"series_name": "Archive North",
		"folder": "Finished",
		"collections": ["Originals"]
	}


func _run() -> void:
	var view := CCFLibraryV0191View.new()
	root.add_child(view)
	await process_frame
	await process_frame
	var capabilities := view.library_density_capabilities_v0191()
	var details := view.find_child("ActiveProjectDetailsV0191", true, false) as Control
	var toggle := view.find_child("ActiveProjectToggleV0191", true, false) as Button
	var slider := view.find_child("CardDensitySliderV0191", true, false) as HSlider
	if not _require(
		bool(capabilities.get("active_project_collapsible", false))
		and bool(capabilities.get("persistent_card_density", false))
		and int(capabilities.get("density_levels", 0)) == 4
		and bool(capabilities.get("mini_name_overlay", false))
		and details != null
		and toggle != null
		and slider != null
		and not details.visible
		and int(slider.value) == CCFLibraryV0191View.DEFAULT_DENSITY,
		"The v0.19.1 Library must start compact with a four-level persistent card-size control."
	):
		return
	view.call("_apply_active_project_visibility_v0191", true, false)
	if not _require(
		details.visible and toggle.button_pressed and toggle.text == "Hide project tools",
		"The compact Active Project header must restore all project tools on demand."
	):
		return

	var mini_card := CCFLibraryProjectCard.new()
	mini_card.configure(_card_row(), false, CCFLibraryV0191View.DENSITY_MINI)
	root.add_child(mini_card)
	await process_frame
	var mini_title_row := mini_card.find_child("CardTitleRow", true, false) as Control
	var mini_overlay := mini_card.find_child("CardTitleOverlay", true, false) as Control
	var mini_count := mini_card.find_child("CardCharacterCount", true, false) as Control
	if not _require(
		is_equal_approx(mini_card.custom_minimum_size.x, 130.0)
		and mini_title_row != null and not mini_title_row.visible
		and mini_overlay != null and mini_overlay.visible
		and mini_count != null and not mini_count.visible,
		"Mini cards must use the artwork overlay and hide the separate title and secondary facts."
	):
		return

	var medium_card := CCFLibraryProjectCard.new()
	medium_card.configure(_card_row(), false, CCFLibraryV0191View.DENSITY_MEDIUM)
	root.add_child(medium_card)
	await process_frame
	var medium_title := medium_card.find_child("CardTitleRow", true, false) as Control
	var medium_count := medium_card.find_child("CardCharacterCount", true, false) as Control
	var medium_summary := medium_card.find_child("CardSummary", true, false) as Control
	var medium_organisation := medium_card.find_child("CardOrganisation", true, false) as Control
	if not _require(
		is_equal_approx(medium_card.custom_minimum_size.x, 195.0)
		and medium_title != null and medium_title.visible
		and medium_count != null and medium_count.visible
		and medium_summary != null and medium_summary.visible
		and medium_organisation != null and not medium_organisation.visible,
		"Medium cards must retain useful card facts while hiding lower-priority organisation text."
	):
		return

	var large_card := CCFLibraryProjectCard.new()
	large_card.configure(_card_row(), true, CCFLibraryV0191View.DENSITY_COMFORTABLE)
	root.add_child(large_card)
	await process_frame
	var large_organisation := large_card.find_child("CardOrganisation", true, false) as Control
	if not _require(
		is_equal_approx(large_card.custom_minimum_size.x, 230.0)
		and large_organisation != null and large_organisation.visible,
		"Large cards must retain the existing complete metadata presentation."
	):
		return

	print("V0191_LIBRARY_DENSITY_OK")
	view.queue_free()
	mini_card.queue_free()
	medium_card.queue_free()
	large_card.queue_free()
	await process_frame
	quit(0)
