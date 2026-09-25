extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0202_SUPPORTABILITY_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _button_with_text(parent: Node, button_text: String) -> Button:
	for node in parent.find_children("*", "Button", true, false):
		if node is Button and node.text == button_text:
			return node as Button
	return null


func _run() -> void:
	var capabilities := CCFSupportReportServiceV0202.capabilities()
	if not _require(
		bool(capabilities.get("privacy_safe_by_default", false))
		and bool(capabilities.get("credentials_omitted", false))
		and bool(capabilities.get("endpoint_addresses_omitted", false))
		and bool(capabilities.get("library_paths_omitted", false))
		and bool(capabilities.get("character_content_omitted", false))
		and bool(capabilities.get("model_identifiers_opt_in", false)),
		"The support contract must make every privacy boundary explicit."
	):
		return

	var settings := CCFSettingsService.default_settings()
	var profile: Dictionary = (settings.get("api_profiles", []) as Array)[0]
	profile["name"] = "PRIVATE_PROFILE_NAME_SENTINEL"
	profile["base_url"] = "https://private.example.test/v1?token=URL_SECRET_SENTINEL"
	profile["api_key"] = "API_KEY_SECRET_SENTINEL"
	profile["model"] = "MODEL_IDENTIFIER_SENTINEL"
	settings["api_profiles"] = [profile]
	var storage: Dictionary = settings.get("library_storage", {})
	storage["mode"] = "portable"
	storage["portable_root"] = "/home/private/LIBRARY_PATH_SENTINEL"
	settings["library_storage"] = storage
	settings["private_test_content"] = {
		"description": "CHARACTER_CONTENT_SENTINEL",
		"prompt": "PROMPT_CONTENT_SENTINEL",
	}

	var default_report := CCFSupportReportServiceV0202.build_report(
		settings, "0.20.2", false
	)
	var default_text := JSON.stringify(default_report)
	for forbidden in [
		"PRIVATE_PROFILE_NAME_SENTINEL",
		"private.example.test",
		"URL_SECRET_SENTINEL",
		"API_KEY_SECRET_SENTINEL",
		"MODEL_IDENTIFIER_SENTINEL",
		"LIBRARY_PATH_SENTINEL",
		"CHARACTER_CONTENT_SENTINEL",
		"PROMPT_CONTENT_SENTINEL",
		"api_key",
		"base_url",
		"portable_root",
	]:
		if not _require(
			not default_text.contains(forbidden),
			"Default support reports must omit private value or key: %s" % forbidden
		):
			return
	if not _require(
		default_text.contains("remote_service")
		and default_text.contains("credential_configured")
		and default_text.contains("omitted_by_default"),
		"Safe categorical configuration state must remain useful for troubleshooting."
	):
		return

	var opted_in := CCFSupportReportServiceV0202.build_report(
		settings, "0.20.2", true
	)
	var opted_in_text := JSON.stringify(opted_in)
	if not _require(
		opted_in_text.contains("MODEL_IDENTIFIER_SENTINEL")
		and not opted_in_text.contains("API_KEY_SECRET_SENTINEL")
		and not opted_in_text.contains("private.example.test"),
		"The model opt-in must reveal only model identifiers, never credentials or endpoints."
	):
		return

	var action_found := false
	for action in CCFWorkflowDiscoveryServiceV0201.quick_actions():
		if str(action.get("id", "")) == "support_diagnostics":
			action_found = true
			break
	if not _require(
		action_found,
		"Support & Diagnostics must remain searchable through Quick Actions."
	):
		return

	var app_scene := load("res://scenes/main.tscn") as PackedScene
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var support_button := app.find_child(
		"SupportCenterButtonV0202", true, false
	) as Button
	var support_window := app.get(
		"_support_center_v0202"
	) as CCFSupportCenterWindowV0202
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.20.2", "Godot rewrite • v0.20.3",
			"Godot rewrite • v0.20.4", "Godot rewrite • v0.20.5",
			"Godot rewrite • v0.20.6", "Godot rewrite • v0.20.7",
			"Godot rewrite • v0.20.8", "Godot rewrite • v0.20.9",
			"Godot rewrite • v0.21.0", "Godot rewrite • v0.21.1"
		]:
			version_found = true
			break
	if not _require(
		support_button != null
		and support_button.tooltip_text.contains("privacy-safe")
		and support_window != null
		and version_found,
		"The live v0.20.2 app must expose the support center in permanent navigation."
	):
		return

	app.call("_run_quick_action_v0201", "support_diagnostics")
	await process_frame
	if not _require(
		support_window.visible,
		"The searchable support action must route into the live support center."
	):
		return
	support_window.hide()
	support_window.open_support_center(settings, "0.20.2")
	await process_frame
	var report_editor := support_window.find_child(
		"PrivacySafeSupportReportV0202", true, false
	) as TextEdit
	var include_models := support_window.get("_include_models") as CheckBox
	if not _require(
		support_window.visible
		and report_editor != null
		and not report_editor.editable
		and report_editor.text.contains('"version": "0.20.2"')
		and not report_editor.text.contains("MODEL_IDENTIFIER_SENTINEL")
		and include_models != null
		and not include_models.button_pressed
		and _button_with_text(support_window, "Copy Support Summary") != null
		and _button_with_text(support_window, "Export Diagnostic Bundle…") != null
		and _button_with_text(support_window, "Open Bug Report…") != null,
		"The support center must visibly preview an inspectable default-safe report and explicit actions."
	):
		return

	include_models.button_pressed = true
	await process_frame
	if not _require(
		report_editor.text.contains("MODEL_IDENTIFIER_SENTINEL")
		and not report_editor.text.contains("API_KEY_SECRET_SENTINEL"),
		"The live opt-in control must refresh the preview without weakening hard privacy boundaries."
	):
		return

	app.queue_free()
	await process_frame
	print("V0202_SUPPORTABILITY_OK")
	quit(0)
