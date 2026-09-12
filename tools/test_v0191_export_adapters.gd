extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0191_EXPORT_ADAPTER_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _sample_project() -> Dictionary:
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var character_record := CCFStorageService.get_character(project, character_id)
	character_record["metadata"]["name"] = "Mara Vale"
	character_record["metadata"]["tags"] = ["mystery", "harbour"]
	character_record["character"]["name"] = "Mara Vale"
	character_record["character"]["description"] = "A precise investigator in a rain-soaked port."
	character_record["character"]["personality"] = "Measured, wry and relentless."
	character_record["character"]["scenario"] = "{{user}} brings Mara an impossible case."
	character_record["character"]["first_message"] = "Start at the beginning."
	character_record["character"]["example_dialogue"] = "{{char}}: Leave nothing out."
	character_record["character"]["tts_voice"] = "mara-voice"
	character_record["character"]["card_extensions"] = {
		"front_porch": {
			"extension_version": "2.5",
			"realism_engine": {"occupation": "Investigator"}
		},
		"future_tool": {"format_version": 9, "unknown_value": "keep me"}
	}
	character_record["workspace"]["private_note"] = "Never export this note."
	character_record["revision_history"] = [{"revision_id": "revision-private"}]
	CCFStorageService.update_character(project, character_record)
	return project


func _row_with(
	rows: Array, path: String, disposition: String
) -> Dictionary:
	for row_value in rows:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		if (
			str(row.get("path", "")) == path
			and str(row.get("disposition", "")) == disposition
		):
			return row
	return {}


func _run() -> void:
	var contract := CCFIntegrationAdapterServiceV0191.capabilities()
	if not _require(
		bool(contract.get("versioned_profiles", false))
		and bool(contract.get("detection", false))
		and bool(contract.get("import", false))
		and bool(contract.get("export", false))
		and bool(contract.get("validation", false))
		and bool(contract.get("capability_reporting", false))
		and bool(contract.get("install_payloads", false))
		and bool(contract.get("update_payloads", false))
		and bool(contract.get("before_export_preview", false))
		and bool(contract.get("include_rules", false))
		and bool(contract.get("omit_rules", false))
		and bool(contract.get("rename_rules", false))
		and bool(contract.get("transform_rules", false))
		and bool(contract.get("unknown_extension_preservation", false))
		and bool(contract.get("visible_loss_reports", false))
		and not bool(contract.get("third_party_executable_plugins", true))
		and not bool(contract.get("raw_database_writes", true))
		and not bool(contract.get("automatic_network_calls", true)),
		"v0.19.1 must expose the complete internal adapter and safety contract."
	):
		return

	var available_profiles := CCFIntegrationAdapterServiceV0191.profiles()
	if not _require(
		available_profiles.size() == 3
		and not CCFIntegrationAdapterServiceV0191.profile_by_id(
			CCFIntegrationAdapterServiceV0191.DEFAULT_PROFILE_ID
		).is_empty()
		and not CCFIntegrationAdapterServiceV0191.profile_by_id(
			CCFIntegrationAdapterServiceV0191.FRONT_PORCH_PROFILE_ID
		).is_empty()
		and not CCFIntegrationAdapterServiceV0191.profile_by_id(
			CCFIntegrationAdapterServiceV0191.SILLYTAVERN_PROFILE_ID
		).is_empty(),
		"The built-in catalog must provide V2, Front Porch and SillyTavern profiles."
	):
		return

	var project := _sample_project()
	var character_id := CCFStorageService.active_character_id(project)
	var source_guard := JSON.stringify(project)
	var full_preview := CCFIntegrationAdapterServiceV0191.preview_export(
		project,
		character_id,
		CCFIntegrationAdapterServiceV0191.DEFAULT_PROFILE_ID
	)
	var full_document: Dictionary = full_preview.get("document", {})
	var full_extensions: Dictionary = full_document.get("data", {}).get("extensions", {})
	if not _require(
		bool(full_preview.get("ok", false))
		and full_extensions.has("front_porch")
		and full_extensions.has("future_tool")
		and full_extensions.has(CCFCardFormatService.CCF_EXTENSION_KEY),
		"Full-fidelity V2 export must retain known, unknown and CCF extension namespaces."
	):
		return

	var porch_preview := CCFIntegrationAdapterServiceV0191.preview_export(
		project,
		character_id,
		CCFIntegrationAdapterServiceV0191.FRONT_PORCH_PROFILE_ID
	)
	var detected := CCFIntegrationAdapterServiceV0191.detect_document(
		porch_preview.get("document", {})
	)
	if not _require(
		bool(porch_preview.get("ok", false))
		and str(detected.get("adapter_id", "")) == "front_porch",
		"Front Porch extension data must be detected through the shared adapter contract."
	):
		return

	var silly_preview := CCFIntegrationAdapterServiceV0191.preview_export(
		project,
		character_id,
		CCFIntegrationAdapterServiceV0191.SILLYTAVERN_PROFILE_ID
	)
	var silly_document: Dictionary = silly_preview.get("document", {})
	var silly_extensions: Dictionary = silly_document.get("data", {}).get("extensions", {})
	var silly_report: Dictionary = silly_preview.get("report", {})
	if not _require(
		bool(silly_preview.get("ok", false))
		and not silly_extensions.has(CCFCardFormatService.CCF_EXTENSION_KEY)
		and silly_extensions.has("front_porch")
		and silly_extensions.has("future_tool")
		and not _row_with(
			silly_report.get("rows", []),
			"data.extensions.character_card_forge/v1",
			"omitted"
		).is_empty(),
		"Clean SillyTavern export must visibly omit only CCF private round-trip metadata."
	):
		return

	var custom_profile := CCFIntegrationAdapterServiceV0191.profile_by_id(
		CCFIntegrationAdapterServiceV0191.DEFAULT_PROFILE_ID
	).duplicate(true)
	custom_profile["id"] = "test_rename"
	custom_profile["name"] = "Test Rename"
	custom_profile["rules"] = {
		"include_paths": ["spec", "spec_version", "data"],
		"omit_paths": [],
		"rename_paths": {"data.tts_voice": "data.extensions.test_voice"},
		"transformations": []
	}
	var custom_preview := CCFIntegrationAdapterServiceV0191.preview_with_profile(
		project, character_id, custom_profile
	)
	var custom_document: Dictionary = custom_preview.get("document", {})
	if not _require(
		bool(custom_preview.get("ok", false))
		and not custom_document.get("data", {}).has("tts_voice")
		and str(custom_document.get("data", {}).get("extensions", {}).get(
			"test_voice", ""
		)) == "mara-voice"
		and JSON.stringify(project) == source_guard,
		"The adapter rule engine must apply explicit rename rules without changing the source."
	):
		return

	var batch_directory := "user://v0191_profile_batch"
	var batch_export := CCFIntegrationAdapterServiceV0191.export_characters_json(
		project,
		[character_id],
		CCFIntegrationAdapterServiceV0191.SILLYTAVERN_PROFILE_ID,
		batch_directory
	)
	var batch_files: Array = batch_export.get("exported", [])
	if not _require(
		bool(batch_export.get("ok", false))
		and batch_files.size() == 1
		and FileAccess.file_exists(str(batch_files[0])),
		"Batch export must use the selected versioned profile."
	):
		return

	var source_image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	source_image.fill(Color(0.2, 0.1, 0.4, 1.0))
	var source_path := "user://v0191_adapter_source.png"
	if not _require(
		source_image.save_png(source_path) == OK,
		"The PNG fixture could not be created."
	):
		return
	var payload := CCFIntegrationAdapterServiceV0191.prepare_install_payload(
		project,
		character_id,
		CCFIntegrationAdapterServiceV0191.FRONT_PORCH_PROFILE_ID,
		source_path
	)
	var payload_path := "user://v0191_adapter_payload.png"
	var payload_file := FileAccess.open(payload_path, FileAccess.WRITE)
	if not _require(
		bool(payload.get("ok", false)) and payload_file != null,
		"Front Porch adapter must prepare an inspectable PNG install payload."
	):
		return
	payload_file.store_buffer(payload.get("bytes", PackedByteArray()))
	payload_file.close()
	var decoded_payload := CCFCardFormatService.read_png_card(payload_path)
	var decoded_document: Dictionary = decoded_payload.get("data", {})
	var decoded_extensions: Dictionary = decoded_document.get("data", {}).get("extensions", {})
	if not _require(
		bool(decoded_payload.get("ok", false))
		and decoded_extensions.has("front_porch")
		and decoded_extensions.has("future_tool"),
		"Profile-aware PNG output must embed the exact adapter document."
	):
		return

	var imported := CCFIntegrationAdapterServiceV0191.import_document(
		porch_preview.get("document", {}), "front_porch_json"
	)
	if not _require(
		bool(imported.get("ok", false))
		and str(imported.get("adapter_id", "")) == "front_porch",
		"The shared adapter contract must import a detected Front Porch card."
	):
		return

	var export_window := CCFImportExportWindowV0191.new()
	root.add_child(export_window)
	await process_frame
	export_window.open_for_project(project, {}, character_id)
	await process_frame
	var window_contract := export_window.export_profile_capabilities_v0191()
	var profile_panel := export_window.find_child(
		"ExportProfilePanelV0191", true, false
	)
	var exact_preview := export_window.find_child(
		"ExactExportPreviewV0191", true, false
	)
	if not _require(
		bool(window_contract.get("profile_selector", false))
		and bool(window_contract.get("exact_json_preview", false))
		and bool(window_contract.get("preservation_report", false))
		and bool(window_contract.get("front_porch_install_uses_adapter", false))
		and bool(window_contract.get("front_porch_sync_uses_adapter", false))
		and profile_panel != null
		and exact_preview != null,
		"The live Import / Export Studio must expose profile selection and complete previews."
	):
		return
	export_window.call(
		"_select_profile_v0191",
		CCFIntegrationAdapterServiceV0191.SILLYTAVERN_PROFILE_ID
	)
	export_window.call("_refresh_export_preview")
	var exact_json_value: Variant = export_window.get(
		"_export_document_preview_v0191"
	)
	var report_text_value: Variant = export_window.get(
		"_export_profile_report_v0191"
	)
	if not _require(
		exact_json_value is TextEdit
		and report_text_value is TextEdit
		and not (exact_json_value as TextEdit).text.contains(
			CCFCardFormatService.CCF_EXTENSION_KEY
		)
		and (report_text_value as TextEdit).text.contains(
			"[OMITTED] data.extensions.character_card_forge/v1"
		),
		"Changing the live profile must immediately refresh exact JSON and its loss report."
	):
		return
	export_window.hide()
	export_window.queue_free()
	await process_frame

	var scene_text := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var main_text := FileAccess.get_file_as_string("res://scripts/main_v0191.gd")
	if not _require(
		scene_text.contains("scripts/main_v0191.gd")
		and main_text.contains("WORKSPACE_V0191")
		and main_text.contains("0.19.1"),
		"The live application must mount the v0.19.1 workspace and display its version."
	):
		return

	print("V0191_EXPORT_ADAPTER_OK")
	quit(0)
