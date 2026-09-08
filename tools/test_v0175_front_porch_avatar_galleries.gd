extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0175_FRONT_PORCH_GALLERY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var project := CCFStorageService.new_project()
	var character: Dictionary = project.get("characters", [])[0]
	var character_id := str(character.get("character_id", ""))
	character["metadata"]["name"] = "Gallery Test"
	character["character"]["name"] = "Gallery Test"
	var image := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.21, 0.48, 0.78, 1.0))
	var relative_path := "characters/%s/generated_images/gallery_source.png" % character_id
	var image_path := CCFStorageService.project_folder(
		str(project.get("project_id", ""))
	).path_join(relative_path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(image_path.get_base_dir()))
	if not _require(image.save_png(ProjectSettings.globalize_path(image_path)) == OK, "The fixture image must save."):
		return
	character["assets"]["generated_images"] = [{
		"format_version": 2,
		"image_id": "generated-regression",
		"path": relative_path,
		"provider": "openrouter_images",
		"model": "example/image-model",
		"prompt": "A calm portrait",
		"seed": 42,
		"created_at": "2026-09-08T00:00:00Z"
	}]
	project["characters"][0] = character
	var sources := CCFFrontPorchAvatarGalleryServiceV0175.available_sources(
		project, character_id
	)
	if not _require(sources.size() == 1, "Image Studio results must be available as gallery sources."):
		return
	var look_result := CCFFrontPorchAvatarGalleryServiceV0175.add_source(
		project, character_id, sources[0], "look"
	)
	if not _require(bool(look_result.get("ok", false)), "A generated result must be linkable as a look."):
		return
	project = look_result.get("project", {})
	var look_entry: Dictionary = look_result.get("entry", {})
	var expression_result := CCFFrontPorchAvatarGalleryServiceV0175.add_source(
		project, character_id, sources[0], "expression", "joy"
	)
	if not _require(bool(expression_result.get("ok", false)), "A generated result must be linkable as an expression."):
		return
	project = expression_result.get("project", {})
	var expression_entry: Dictionary = expression_result.get("entry", {})
	var entries := CCFFrontPorchAvatarGalleryServiceV0175.entries_for_character(
		CCFStorageService.get_character(project, character_id)
	)
	if not _require(
		entries.size() == 2
		and str(entries[0].get("kind", "")) == "look"
		and str(entries[1].get("label", "")) == "joy"
		and str(entries[1].get("provenance", {}).get("source_image_id", "")) == "generated-regression"
		and str(entries[1].get("provenance", {}).get("image_studio", {}).get("model", "")) == "example/image-model",
		"Looks, expression labels and Image Studio provenance must remain distinct."
	):
		return
	var favourite := CCFFrontPorchAvatarGalleryServiceV0175.set_favourite(
		project, character_id, str(expression_entry.get("gallery_id", ""))
	)
	project = favourite.get("project", {})
	var portrait_before := str(CCFStorageService.get_character(
		project, character_id
	).get("assets", {}).get("portrait", ""))
	if not _require(
		bool(favourite.get("ok", false)) and portrait_before.is_empty(),
		"Choosing a canonical favourite must not silently assign the CCF portrait."
	):
		return
	var portrait := CCFFrontPorchAvatarGalleryServiceV0175.set_portrait(
		project, character_id, str(look_entry.get("gallery_id", ""))
	)
	project = portrait.get("project", {})
	if not _require(
		str(CCFStorageService.get_character(project, character_id).get("assets", {}).get("portrait", "")) == relative_path,
		"Portrait assignment must remain an explicit separate action."
	):
		return

	var pack_path := "user://v0175-expression-pack.zip"
	var exported := CCFFrontPorchAvatarGalleryServiceV0175.export_expression_zip(
		project, character_id, pack_path
	)
	if not _require(bool(exported.get("ok", false)), "The expression ZIP must export."):
		return
	var reader := ZIPReader.new()
	if not _require(reader.open(pack_path) == OK, "The exported expression ZIP must reopen."):
		return
	var files := reader.get_files()
	var parsed_manifest: Variant = JSON.parse_string(
		reader.read_file(CCFFrontPorchAvatarGalleryServiceV0175.MANIFEST_ENTRY).get_string_from_utf8()
	)
	reader.close()
	if not _require(
		files.has("expressions/joy.png")
		and parsed_manifest is Dictionary
		and str(parsed_manifest.get("package_type", "")) == CCFFrontPorchAvatarGalleryServiceV0175.PACK_TYPE,
		"The ZIP must use Front Porch filename matching and carry a versioned CCF manifest."
	):
		return
	if not _require(
		CCFFrontPorchAvatarGalleryServiceV0175.expression_label_for_filename("sprites/sadness-2.png") == "sadness"
		and CCFFrontPorchAvatarGalleryServiceV0175.expression_label_for_filename("sadness2.png").is_empty(),
		"Sprite-pack filenames must follow Front Porch's exact label/separator rule."
	):
		return
	var imported := CCFFrontPorchAvatarGalleryServiceV0175.import_expression_zip(
		project, character_id, pack_path
	)
	if not _require(
		bool(imported.get("ok", false)) and int(imported.get("imported", 0)) == 1,
		"A portable expression ZIP must import into managed project assets."
	):
		return

	if not _require(
		CCFFrontPorchAvatarInstallServiceV0175.avatar_upload_path_v0175("char 1", "look") == "/api/characters/char%201/looks"
		and CCFFrontPorchAvatarInstallServiceV0175.avatar_upload_path_v0175("char 1", "expression", "joy") == "/api/characters/char%201/avatars?label=joy",
		"Direct install must use Front Porch's supported look and expression endpoints."
	):
		return
	var avatar_response := CCFFrontPorchAvatarInstallServiceV0175.classify_avatar_response_v0175({
		"network_result": 0,
		"response_code": 200,
		"body": JSON.stringify({"avatars": [{"id": "old"}, {"id": "new", "label": "joy"}]})
	}, PackedStringArray(["old"]))
	if not _require(
		bool(avatar_response.get("ok", false))
		and str(avatar_response.get("created_avatar_id", "")) == "new",
		"Avatar upload responses must identify the newly created Front Porch row."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.17.5 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	var image_window_value: Variant = app.get("_image_generation_window")
	if not _require(
		app.has_method("_update_build_version_label_v0175")
		and app.has_method("_update_build_version_label_v0174")
		and workspace_value is CCFWorkspaceV0175View
		and image_window_value is CCFImageGenerationWindowV0175,
		"The live shell must install v0.17.5 while retaining v0.17.4."
	):
		return
	var capabilities := (workspace_value as CCFWorkspaceV0175View).front_porch_avatar_gallery_capabilities_v0175()
	if not _require(
		bool(capabilities.get("manual_image_import", false))
		and bool(capabilities.get("image_studio_sources", false))
		and bool(capabilities.get("portable_expression_zip", false))
		and bool(capabilities.get("front_porch_api_install", false))
		and not bool(capabilities.get("raw_database_writes", true)),
		"The live UI must expose manual/AI sources, portable ZIP and supported API install without database writes."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0175View
	workspace.load_project(
		project, CCFTemplateService.load_template("default"), {}
	)
	await process_frame
	workspace.call("_open_import_export_studio")
	await process_frame
	var import_export_value: Variant = workspace.get("_import_export_window")
	if not _require(
		import_export_value is CCFImportExportWindowV0175
		and int((import_export_value as CCFImportExportWindowV0175).get("_gallery_list_v0175").item_count) == 2
		and int((import_export_value as CCFImportExportWindowV0175).get("_gallery_source_v0175").item_count) >= 1,
		"The mounted Avatar Gallery tab must render saved roles and available image sources."
	):
		return
	app.queue_free()
	await process_frame
	print("v0.17.5 Front Porch avatar-gallery regression passed")
	quit(0)
