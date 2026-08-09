extends SceneTree

const LARGE_BASE64_CHARS := 4 * 1024 * 1024


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V01540_HOTFIX7_DIAGNOSTICS_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fake_image_data_url() -> String:
	return "data:image/png;base64," + "A".repeat(LARGE_BASE64_CHARS)


func _large_vision_failure_bundle(data_url: String) -> Dictionary:
	return {
		"format_version": 1,
		"captured_at": "2026-08-09T03:15:06Z",
		"job_id": "500001",
		"job_type": "collaborator_vision",
		"label": "Analyse collaborator reference image with Vision model",
		"failure_reason": "Vision provider request failed after waiting for a response.",
		"failure_stage": "request",
		"generation_strategy": "",
		"provider": {
			"profile_name": "Regression Vision",
			"model": "vision-regression-model"
		},
		"request": {
			"timestamp": "2026-08-09T03:15:00Z",
			"label": "Analyse collaborator reference image with Vision model",
			"stage": "generation",
			"attempt": 1,
			"payload": {
				"messages": [
					{
						"role": "user",
						"content": [
							{"type": "text", "text": "Analyse this image."},
							{
								"type": "image_url",
								"image_url": {
									"url": data_url,
									"detail": "high"
								}
							}
						]
					}
				]
			}
		},
		"raw_api_response": "Provider failed before returning a usable response body.",
		"extracted_assistant_text": "",
		"parsed_output": null,
		"parse_error": "No response payload could be parsed.",
		"validation_report": {},
		"repair": {},
		"metadata": {
			"image_name": "large_character_card.png",
			"image_path": "/tmp/large_character_card.png",
			"vision_profile_name": "Regression Vision",
			"vision_model": "vision-regression-model"
		},
		"events": [
			{
				"kind": "request",
				"payload": {
					"image_url": data_url,
					"note": "The binary request evidence used to be duplicated into Full Trace."
				}
			}
		]
	}


func _run() -> void:
	CCFStorageService.ensure_directories()
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.15.40-hotfix7 main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	if not _require(
		app.has_method("_update_build_version_label_v01540_hotfix7"),
		"The active application shell must identify hotfix7."
	):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV01540Hotfix7View,
		"The real app must install the hotfix7 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV01540Hotfix7View
	var services := workspace.concurrent_services_v01526()
	if not _require(services.size() == 5, "All five concurrent AI workers must remain installed."):
		return
	for worker_name in ["primary", "collaborator", "ideas", "tools", "vision"]:
		var service_value: Variant = services.get(worker_name)
		if not _require(
			service_value is CCFGenerationServiceV01540Hotfix7,
			"%s worker must use the hotfix7 diagnostics-safe generation service." % worker_name
		):
			return

	var collaborator_service := services.get("collaborator") as CCFGenerationServiceV01540Hotfix7
	var data_url := _fake_image_data_url()
	if not _require(
		data_url.length() > 4_000_000,
		"Regression fixture must contain a genuinely multi-megabyte embedded image payload."
	):
		return
	var raw_bundle := _large_vision_failure_bundle(data_url)
	var sanitized_value: Variant = collaborator_service.call(
		"sanitise_diagnostic_value_v01522",
		raw_bundle
	)
	if not _require(
		sanitized_value is Dictionary,
		"Diagnostics sanitizer must preserve the bundle structure."
	):
		return
	var sanitized: Dictionary = sanitized_value
	var sanitized_json := JSON.stringify(sanitized)
	if not _require(
		not sanitized_json.contains("data:image/png;base64,"),
		"Stored diagnostics must never retain the embedded image data URI."
	):
		return
	if not _require(
		sanitized_json.contains("BINARY DATA OMITTED FROM DIAGNOSTICS"),
		"Stored diagnostics must explain that binary evidence was deliberately omitted."
	):
		return
	if not _require(
		sanitized_json.length() < 900000,
		"Sanitized multi-megabyte Vision diagnostics must remain bounded."
	):
		return
	var huge_text := "Z".repeat(500000)
	var bounded_text := str(
		collaborator_service.call(
			"sanitise_diagnostic_value_v01522",
			huge_text
		)
	)
	if not _require(
		bounded_text.length() <= 180000,
		"Single pathological diagnostic strings must be capped before storage."
	):
		return
	if not _require(
		bounded_text.contains("DIAGNOSTIC TEXT TRUNCATED"),
		"Bounded text must report that truncation occurred."
	):
		return

	var diagnostics_value: Variant = workspace.get(
		"_generation_diagnostics_window_v01522"
	)
	if not _require(
		diagnostics_value is CCFGenerationDiagnosticsWindowV01540Hotfix7,
		"Workspace must upgrade the Diagnostics viewer to hotfix7."
	):
		return
	var diagnostics := diagnostics_value as CCFGenerationDiagnosticsWindowV01540Hotfix7
	var viewer_caps := diagnostics.diagnostic_viewer_capabilities_v01540_hotfix7()
	if not _require(
		bool(viewer_caps.get("lazy_tab_rendering", false)),
		"Diagnostics viewer must advertise lazy tab rendering."
	):
		return

	# Reproduce the user-facing sequence without a provider call: diagnostics are
	# delivered for a failed Vision job, the failure dialog opens, then View
	# Diagnostics is activated with the deliberately UNSANITIZED 4 MB image bundle.
	# If the viewer regresses to eager deep-copy/stringify/wrap behaviour this test
	# stalls and the strict wrapper times out.
	workspace.call(
		"_on_generation_diagnostics_available_v01522",
		"500001",
		"collaborator_vision",
		raw_bundle
	)
	workspace.call(
		"_on_job_failed",
		"500001",
		"collaborator_vision",
		"Vision provider request failed after waiting for a response."
	)
	await process_frame

	var failure_window := workspace.get("_generation_failure_window_v01522") as Window
	if not _require(failure_window != null, "Vision failure window must exist."):
		return
	if not _require(
		failure_window.title == "Vision Analysis Failed",
		"Collaborator Vision failures must be labelled as Vision Analysis Failed."
	):
		return
	var vision_heading_found := false
	for node in failure_window.find_children("*", "Label", true, false):
		if node is Label and (node as Label).text == "Vision analysis failed":
			vision_heading_found = true
			break
	if not _require(
		vision_heading_found,
		"Vision failure dialog heading must identify the failed operation."
	):
		return

	workspace.call("_show_last_generation_diagnostics_v01522")
	await process_frame
	await process_frame
	if not _require(
		diagnostics.visible,
		"View Diagnostics must return control and display the diagnostics window."
	):
		return
	var display_bundle_value: Variant = diagnostics.get("_bundle")
	if not _require(
		display_bundle_value is Dictionary,
		"Diagnostics window must retain a bounded display bundle."
	):
		return
	var display_json := JSON.stringify(display_bundle_value)
	if not _require(
		not display_json.contains("data:image/png;base64,"),
		"Viewer safety boundary must remove an unsanitized image data URI defensively."
	):
		return
	if not _require(
		display_json.length() < 700000,
		"Viewer display bundle must stay well below the original multi-megabyte payload."
	):
		return

	var request_edit := diagnostics.get("_request") as TextEdit
	var events_edit := diagnostics.get("_events") as TextEdit
	var tabs := diagnostics.get("_tabs_v01540_hotfix7") as TabContainer
	if not _require(
		request_edit != null and events_edit != null and tabs != null,
		"Lazy diagnostics controls must exist."
	):
		return
	if not _require(
		request_edit.text.begins_with("Select this tab"),
		"Heavy Request diagnostics must not render before the tab is selected."
	):
		return

	tabs.current_tab = 1
	await process_frame
	if not _require(
		request_edit.text.contains("BINARY DATA OMITTED"),
		"Request tab must render compact binary-omission evidence on demand."
	):
		return
	if not _require(
		request_edit.text.length() <= 220000,
		"Rendered Request tab must remain bounded."
	):
		return
	tabs.current_tab = 7
	await process_frame
	if not _require(
		events_edit.text.contains("BINARY DATA OMITTED"),
		"Full Trace must remain useful while omitting embedded binary data."
	):
		return
	if not _require(
		events_edit.text.length() <= 220000,
		"Rendered Full Trace tab must remain bounded."
	):
		return

	# Prove the window is still responsive after rendering diagnostic tabs.
	diagnostics.hide()
	await process_frame
	if not _require(
		not diagnostics.visible,
		"Diagnostics window must remain interactive and closable after a large Vision failure."
	):
		return

	app.queue_free()
	await process_frame
	print("v0.15.40-hotfix7 lightweight diagnostics regression passed")
	quit(0)
