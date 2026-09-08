extends SceneTree


class CapturingFrontPorchClient:
	extends CCFFrontPorchInstallServiceV0173

	var captured_path := ""
	var captured_body := PackedByteArray()
	var captured_headers := PackedStringArray()

	func is_authenticated() -> bool:
		return true

	func _perform_raw_request(
		_method: HTTPClient.Method,
		path: String,
		body: PackedByteArray,
		headers := PackedStringArray()
	) -> Dictionary:
		captured_path = path
		captured_body = body.duplicate()
		captured_headers = headers.duplicate()
		return {
			"network_result": 0,
			"response_code": 200,
			"headers": PackedStringArray(),
			"body": JSON.stringify({"id": "front-png-17", "name": "Mara"})
		}


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0173_FRONT_PORCH_INSTALL_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var extension_source := FileAccess.get_file_as_string(
		"res://scripts/services/front_porch_extension_service_v0172.gd"
	)
	var install_source := FileAccess.get_file_as_string(
		"res://scripts/services/front_porch_install_service_v0173.gd"
	)
	var window_source := FileAccess.get_file_as_string(
		"res://scripts/ui/import_export_window_v0173.gd"
	)
	var workspace_source := FileAccess.get_file_as_string(
		"res://scripts/ui/workspace_v0172.gd"
	)
	if not _require(
		not extension_source.contains("var seed: Dictionary")
		and not install_source.contains("func configure(base_url:")
		and not window_source.contains("var title :=")
		and not window_source.contains("var name := str(result.get"),
		"v0.17.2/v0.17.3 source must avoid the reported Godot built-in and base-class shadow warnings."
	):
		return
	if not _require(
		not workspace_source.contains("A later version will install")
		and workspace_source.contains("Use Import / Export → ")
		and workspace_source.contains(
			"Install to Front Porch for supported local API installation."
		),
		"The live Front Porch workspace must point to the shipped direct-install workflow rather than describing it as future work."
	):
		return

	var service := CCFFrontPorchInstallServiceV0173.new()
	var capabilities := service.capabilities()
	if not _require(
		bool(capabilities.get("health_detection", false))
		and bool(capabilities.get("cookie_session_auth", false))
		and bool(capabilities.get("character_import", false))
		and bool(capabilities.get("character_card_png_upload", false))
		and bool(capabilities.get("portrait_included_when_available", false))
		and bool(capabilities.get("json_definition_fallback", false))
		and bool(capabilities.get("collision_ask", false))
		and bool(capabilities.get("collision_keep_both", false))
		and bool(capabilities.get("collision_replace", false))
		and bool(capabilities.get("stable_identity_server_owned", false))
		and bool(capabilities.get("portable_json_fallback", false))
		and not bool(capabilities.get("password_persisted", true))
		and not bool(capabilities.get("totp_persisted", true))
		and not bool(capabilities.get("raw_database_writes", true)),
		"Direct install must upload portrait-bearing PNG cards, retain a JSON fallback, use explicit collision policies, keep secrets session-only and avoid SQLite writes."
	):
		return

	var default_url := CCFFrontPorchInstallServiceV0173.validate_base_url(
		"http://127.0.0.1:8085/"
	)
	var localhost_url := CCFFrontPorchInstallServiceV0173.validate_base_url(
		"http://localhost:8085"
	)
	var remote_plain := CCFFrontPorchInstallServiceV0173.validate_base_url(
		"http://192.168.1.20:8085"
	)
	var remote_secure := CCFFrontPorchInstallServiceV0173.validate_base_url(
		"https://porch.example.test"
	)
	if not _require(
		bool(default_url.get("ok", false))
		and str(default_url.get("base_url", "")) == "http://127.0.0.1:8085"
		and bool(localhost_url.get("ok", false))
		and not bool(remote_plain.get("ok", true))
		and bool(remote_secure.get("ok", false)),
		"Connection validation must allow loopback HTTP, require HTTPS remotely and normalise trailing slashes."
	):
		return

	var clean_connection := CCFFrontPorchInstallServiceV0173.sanitise_connection({
		"base_url": "http://127.0.0.1:8085/",
		"username": " porch-author ",
		"password": "must-not-persist",
		"totpCode": "123456",
		"fpa_session": "must-not-persist"
	})
	if not _require(
		str(clean_connection.get("username", "")) == "porch-author"
		and clean_connection.keys().size() == 3
		and not clean_connection.has("password")
		and not clean_connection.has("totpCode")
		and not clean_connection.has("fpa_session"),
		"Persisted Front Porch connection settings must exclude every credential and session secret."
	):
		return

	var ask_path := CCFFrontPorchInstallServiceV0173.import_path(
		"A Character.json", "ask"
	)
	var copy_path := CCFFrontPorchInstallServiceV0173.import_path(
		"A Character.json", "keepBoth"
	)
	var replace_path := CCFFrontPorchInstallServiceV0173.import_path(
		"A Character.json", "replace", "id with space"
	)
	if not _require(
		ask_path.contains("filename=A%20Character.json")
		and ask_path.contains("collision=ask")
		and copy_path.contains("collision=keepBoth")
		and replace_path.contains("collision=replace")
		and replace_path.contains("replaceId=id%20with%20space"),
		"Import URLs must safely encode the filename, collision choice and replacement ID."
	):
		return

	var health := CCFFrontPorchInstallServiceV0173.classify_health_response(
		_raw_response(200, {
			"status": "ok",
			"version": "1.3.2",
			"setupRequired": false,
			"secure": false
		})
	)
	var setup_health := CCFFrontPorchInstallServiceV0173.classify_health_response(
		_raw_response(200, {
			"status": "ok",
			"version": "1.3.2",
			"setupRequired": true,
			"setupTokenRequired": false
		})
	)
	if not _require(
		bool(health.get("ok", false))
		and str(health.get("version", "")) == "1.3.2"
		and not bool(health.get("setup_required", true))
		and bool(setup_health.get("setup_required", false)),
		"Health detection must report the Front Porch version and setup requirement exactly."
	):
		return

	var auth_state := CCFFrontPorchInstallServiceV0173.classify_auth_state_response(
		_raw_response(200, {
			"authenticated": true,
			"setupRequired": false,
			"username": "porch-author",
			"totpEnabled": true
		})
	)
	var totp_login := CCFFrontPorchInstallServiceV0173.classify_login_response(
		_raw_response(401, {"error": "Two-factor code required", "totpRequired": true})
	)
	if not _require(
		bool(auth_state.get("authenticated", false))
		and bool(auth_state.get("totp_enabled", false))
		and bool(totp_login.get("totp_required", false)),
		"Authentication responses must distinguish an active session from a two-factor challenge."
	):
		return

	var accepted := CCFFrontPorchInstallServiceV0173.classify_import_response(
		_raw_response(200, {"id": "front-17", "name": "Mara"})
	)
	var replaced := CCFFrontPorchInstallServiceV0173.classify_import_response(
		_raw_response(200, {"id": "front-17", "name": "Mara", "replaced": true})
	)
	var collision := CCFFrontPorchInstallServiceV0173.classify_import_response(
		_raw_response(409, {
			"error": "name_collision",
			"status": "name_collision",
			"name": "Mara",
			"existing": [{"id": "front-17", "name": "Mara"}]
		})
	)
	var expired := CCFFrontPorchInstallServiceV0173.classify_import_response(
		_raw_response(401, {"error": "Authentication required"})
	)
	if not _require(
		bool(accepted.get("ok", false))
		and str(accepted.get("character_id", "")) == "front-17"
		and bool(replaced.get("replaced", false))
		and bool(collision.get("collision", false))
		and (collision.get("existing", []) as Array).size() == 1
		and bool(expired.get("auth_required", false)),
		"Install handling must distinguish accepted, replaced, collision and expired-session outcomes."
	):
		return

	var cookie := CCFFrontPorchInstallServiceV0173._session_cookie_from_headers(
		PackedStringArray([
			"Content-Type: application/json",
			"Set-Cookie: fpa_session=session-value; Path=/; HttpOnly; SameSite=Lax"
		])
	)
	if not _require(
		cookie == "fpa_session=session-value",
		"Only the Front Porch session cookie pair should be retained in memory."
	):
		return

	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(
		project, character_id
	)
	CCFStorageService.set_value_at_path(document, "character.name", "Mara")
	CCFStorageService.set_value_at_path(
		document,
		"character.description",
		"A completed direct-install regression character."
	)
	CCFStorageService.set_value_at_path(
		document,
		"character.card_extensions.front_porch",
		{
			"version": "2.5",
			"realism_engine": {"stable_id": "stable-mara-17"}
		}
	)
	CCFStorageService.update_character(project, document)
	var card := CCFCardFormatService.export_character_v2(project, character_id)
	var validation := CCFCardFormatService.validate_card(card)
	if not _require(
		validation.get("errors", []).is_empty()
		and str(CCFStorageService.get_value_at_path(
			card, "data.extensions.front_porch.realism_engine.stable_id", ""
		)) == "stable-mara-17",
		"The direct-install payload must be a valid Character Card V2 document retaining Front Porch stable identity."
	):
		return

	var portrait_path := "res://.v0173_front_porch_portrait_test.png"
	var card_path := "res://.v0173_front_porch_card_test.png"
	var portrait := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	portrait.fill(Color(0.18, 0.42, 0.76, 1.0))
	if not _require(
		portrait.save_png(portrait_path) == OK,
		"The PNG upload regression fixture must be writable."
	):
		return
	var artwork_document := CCFStorageService.character_workspace_document(
		project, character_id
	)
	CCFStorageService.set_value_at_path(
		artwork_document,
		"assets.generated_images",
		[{
			"image_id": "generated-artwork-v0173",
			"path": portrait_path,
			"created_at": "2026-09-07T12:00:00"
		}]
	)
	CCFStorageService.set_value_at_path(
		artwork_document, "assets.portrait", ""
	)
	CCFStorageService.update_character(project, artwork_document)
	var png_card := CCFCardFormatService.build_png_card_bytes(
		portrait_path, project, character_id
	)
	if not _require(
		bool(png_card.get("ok", false))
		and (png_card.get("bytes", PackedByteArray()) as PackedByteArray).size() > 8,
		"Direct install must build a binary Character Card PNG from the active portrait."
	):
		return
	var card_file := FileAccess.open(card_path, FileAccess.WRITE)
	if not _require(card_file != null, "The generated PNG card fixture must be writable."):
		return
	card_file.store_buffer(png_card.get("bytes", PackedByteArray()))
	card_file.close()
	var embedded := CCFCardFormatService.read_png_card(card_path)
	if not _require(
		bool(embedded.get("ok", false))
		and str(CCFStorageService.get_value_at_path(
			embedded.get("data", {}), "data.name", ""
		)) == "Mara",
		"The uploaded PNG bytes must retain valid embedded Character Card V2 metadata."
	):
		return
	var capture_client := CapturingFrontPorchClient.new()
	var upload_result := await capture_client.install_card_bytes(
		png_card.get("bytes", PackedByteArray()),
		"Mara.png",
		"image/png",
		"ask"
	)
	if not _require(
		bool(upload_result.get("ok", false))
		and capture_client.captured_path.contains("filename=Mara.png")
		and capture_client.captured_path.contains("collision=ask")
		and capture_client.captured_body == png_card.get("bytes", PackedByteArray())
		and capture_client.captured_headers.has("Content-Type: image/png"),
		"The Front Porch client must send the complete PNG as raw binary bytes with a .png filename and image/png content type."
	):
		return
	capture_client.free()

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.17.3 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(
		app.has_method("_update_build_version_label_v0173"),
		"The active application shell must identify v0.17.3."
	):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0173View,
		"The application must install the v0.17.3 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0173View
	workspace.load_project(project, CCFTemplateService.load_template("default"), {})
	await process_frame
	workspace.call("_open_import_export_studio")
	await process_frame
	var live_capabilities := workspace.front_porch_direct_install_capabilities_v0173()
	if not _require(
		bool(live_capabilities.get("install_tab", false))
		and bool(live_capabilities.get("collision_controls", false))
		and bool(live_capabilities.get("artwork_picker", false))
		and bool(live_capabilities.get("selected_artwork_available", false))
		and str(live_capabilities.get("selected_artwork_kind", "")) == "generated"
		and bool(live_capabilities.get("character_card_png_upload", false))
		and bool(live_capabilities.get("portrait_included_when_available", false))
		and bool(live_capabilities.get("portable_json_fallback", false))
		and not bool(live_capabilities.get("connected", true))
		and not bool(live_capabilities.get("raw_database_writes", true)),
		"The live Import/Export Studio must expose direct install, generated-artwork selection, explicit collision controls and portable fallback without automatic connection or SQLite access. Capabilities: %s"
		% JSON.stringify(live_capabilities)
	):
		return
	app.queue_free()
	service.free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(portrait_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(card_path))
	print("v0.17.3 Front Porch direct install regression passed")
	quit(0)


func _raw_response(response_code: int, payload: Dictionary) -> Dictionary:
	return {
		"network_result": 0,
		"response_code": response_code,
		"headers": PackedStringArray(),
		"body": JSON.stringify(payload)
	}
