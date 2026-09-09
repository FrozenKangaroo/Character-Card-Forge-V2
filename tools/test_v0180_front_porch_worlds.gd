extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0180_FRONT_PORCH_WORLD_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var raw_package := {
		"formatVersion": 3,
		"id": "world-stable-1",
		"name": "Glass Archipelago",
		"description": "A chain of reflective islands.",
		"cover": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
		"lorebook": {
			"name": "Primary",
			"entries": [{
				"name": "Mirror Rain",
				"keys": ["rain", "mirror"],
				"content": "Rain remembers what it reflects.",
				"enabled": true,
				"futureEntryMode": {"weight": 9}
			}],
			"futureBookField": [1, 2, 3]
		},
		"lorebooks": [{
			"name": "Primary",
			"entries": [{"name": "Mirror Rain", "keys": ["rain"], "content": "Rain remembers.", "futureEntryMode": true}],
			"futureBookField": "keep"
		}, {
			"name": "Second Book",
			"entries": [{"name": "Harbour", "keys": ["harbour"], "content": "Safe anchorage."}],
			"vendorExtension": {"nested": "survives"}
		}],
		"climate_enabled": true,
		"biome": {"id": "crystal", "baseTemp": 17.5, "futureWeather": ["glass-storm"]},
		"place_traits": {"atmosphere": "breathable", "gravity": "low", "magicPressure": 42},
		"meta": {"author": "Test Author", "createdAt": "2026-09-09T00:00:00Z", "sourceId": "stoop-world-7", "futureMeta": true},
		"futureTopLevel": {"nested": ["must", "survive"]}
	}
	var import_path := "user://v0180-future.fpworld"
	var fixture := FileAccess.open(import_path, FileAccess.WRITE)
	if not _require(fixture != null, "The future .fpworld fixture must be writable."):
		return
	fixture.store_string(JSON.stringify(raw_package, "  "))
	fixture.close()
	var project := CCFStorageService.new_project()
	var imported := CCFFrontPorchWorldServiceV0180.import_fpworld(project, import_path)
	if not _require(bool(imported.get("ok", false)), "A future-version .fpworld envelope must import."):
		return
	project = imported.get("project", {})
	var record: Dictionary = imported.get("record", {})
	var validation: Dictionary = imported.get("validation", {})
	if not _require(
		str(record.get("package", {}).get("futureTopLevel", {}).get("nested", [])[1]) == "survive"
		and str(record.get("package", {}).get("lorebooks", [])[1].get("vendorExtension", {}).get("nested", "")) == "survives"
		and int(record.get("package", {}).get("place_traits", {}).get("magicPressure", 0)) == 42
		and validation.get("warnings", []).size() == 1,
		"Future top-level, lorebook, trait and version-warning data must survive import."
	):
		return
	var export_path := "user://v0180-roundtrip.fpworld"
	var exported := CCFFrontPorchWorldServiceV0180.export_fpworld(record, export_path)
	if not _require(bool(exported.get("ok", false)), "An imported future world must export."):
		return
	var roundtrip_file := FileAccess.open(export_path, FileAccess.READ)
	var roundtrip: Variant = JSON.parse_string(roundtrip_file.get_as_text())
	var json_normalised_source: Variant = JSON.parse_string(JSON.stringify(raw_package))
	if not _require(roundtrip == json_normalised_source, "Unedited import/export must preserve the complete .fpworld JSON envelope."):
		return

	var edited := CCFFrontPorchWorldServiceV0180.apply_editor_fields(record, {
		"name": "Glass Archipelago Revised",
		"publishing": {
			"summary": "A reflective setting for uncanny voyages.",
			"creator": "Revising Author",
			"tags": ["surreal", "voyage"],
			"adult_content": true,
			"stable_update_identity": "stoop-world-7"
		}
	})
	if not _require(
		str(edited.get("package", {}).get("name", "")) == "Glass Archipelago Revised"
		and bool(edited.get("package", {}).get("futureTopLevel", {}).get("nested", []).size() == 2)
		and bool(edited.get("package", {}).get("meta", {}).get("futureMeta", false))
		and str(edited.get("package", {}).get("meta", {}).get("author", "")) == "Revising Author",
		"Known edits must merge into the raw envelope without removing future fields."
	):
		return
	var readiness := CCFFrontPorchWorldServiceV0180.stoop_readiness(edited)
	if not _require(
		bool(readiness.get("ready", false))
		and bool(readiness.get("requires_private_context_review", false))
		and bool(readiness.get("requires_adult_declaration_review", false))
		and not bool(readiness.get("direct_publish_available", true)),
		"Stoop preparation must require explicit privacy/adult review without claiming direct publishing."
	):
		return

	var bare_path := "user://v0180-bare-lorebook.fpworld"
	var bare_file := FileAccess.open(bare_path, FileAccess.WRITE)
	bare_file.store_string(JSON.stringify({"name": "Bare Lore", "entries": [{"name": "One", "content": "Two", "bareFuture": 3}]}))
	bare_file.close()
	var bare := CCFFrontPorchWorldServiceV0180.import_fpworld(project, bare_path)
	if not _require(
		bool(bare.get("ok", false))
		and int(bare.get("record", {}).get("package", {}).get("formatVersion", -1)) == 0
		and int(bare.get("record", {}).get("package", {}).get("lorebook", {}).get("entries", [])[0].get("bareFuture", 0)) == 3,
		"Bare lorebook JSON must import as a compatible degenerate world without losing entry extensions."
	):
		return

	var cover_image := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	cover_image.fill(Color(0.18, 0.36, 0.62, 1.0))
	var cover_path := "user://v0180-cover.png"
	if not _require(cover_image.save_png(cover_path) == OK, "The cover fixture must save."):
		return
	var cover := CCFFrontPorchWorldServiceV0180.cover_data_url_from_image(cover_path)
	if not _require(
		bool(cover.get("ok", false))
		and str(cover.get("data_url", "")).begins_with("data:image/jpeg;base64,")
		and maxi(int(cover.get("width", 0)), int(cover.get("height", 0))) <= CCFFrontPorchWorldServiceV0180.MAX_COVER_EDGE
		and int(cover.get("byte_size", 999999)) <= CCFFrontPorchWorldServiceV0180.COVER_SOFT_LIMIT_BYTES,
		"Cover preparation must create a bounded portable data URL."
	):
		return

	var capabilities := CCFFrontPorchWorldServiceV0180.capabilities()
	if not _require(
		bool(capabilities.get("lossless_unknown_fields", false))
		and bool(capabilities.get("climate_authoring", false))
		and bool(capabilities.get("stoop_metadata", false))
		and not bool(capabilities.get("network_calls", true))
		and not bool(capabilities.get("raw_database_writes", true)),
		"The portable World capability boundary must be explicit."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.18.0 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		app.has_method("_update_build_version_label_v0180")
		and app.has_method("_update_build_version_label_v0175")
		and workspace_value is CCFWorkspaceV0180View,
		"The live shell must install v0.18.0 while retaining v0.17.5."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0180View
	workspace.load_project(project, CCFTemplateService.load_template("default"), {})
	workspace.call("_open_import_export_studio")
	await process_frame
	var window_value: Variant = workspace.get("_import_export_window")
	if not _require(window_value is CCFImportExportWindowV0180, "The live workspace must mount the v0.18.0 Import/Export window."):
		return
	var window := window_value as CCFImportExportWindowV0180
	var tabs: TabContainer = window.call("_primary_tabs_v0173")
	var captured_world: Dictionary = window.call("_capture_world_form_v0180")
	var found_world_tab := false
	for index in range(tabs.get_tab_count()):
		if tabs.get_tab_title(index) == "Front Porch Worlds":
			found_world_tab = true
			break
	if not _require(
		found_world_tab
		and window.get("_world_name_v0180") is LineEdit
		and window.get("_world_lore_list_v0180") is ItemList
		and window.get("_world_private_review_v0180") is CheckBox
		and int(window.get("_world_selector_v0180").item_count) >= 1
		and captured_world.get("package", {}).get("lorebook", {}).get("futureBookField", []) is Array
		and str(captured_world.get("package", {}).get("lorebooks", [])[1].get("vendorExtension", {}).get("nested", "")) == "survives",
		"The live World Studio must expose identity, lore, saved worlds and explicit review controls."
	):
		return
	app.queue_free()
	await process_frame
	print("v0.18.0 Front Porch Worlds regression passed")
	quit(0)
