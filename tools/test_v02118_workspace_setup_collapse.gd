extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate(
	"v02118-workspace-setup-collapse"
)


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V02118_WORKSPACE_SETUP_COLLAPSE_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var workspace := CCFWorkspaceCurrent.new()
	root.add_child(workspace)
	await process_frame
	await process_frame
	await process_frame

	var toggle := workspace.get("_setup_toggle") as Button
	var panel := workspace.get("_setup_panel") as VBoxContainer
	var hint := workspace.get("_setup_hint") as Label
	if not _require(
		toggle != null and panel != null and hint != null,
		"The workspace must build the collapsible project setup controls."
	):
		return
	if not _require(
		workspace.find_child("ProjectSetupToggleV02118", true, false) == toggle
		and workspace.find_child("ProjectSetupPanelV02118", true, false) == panel,
		"The setup controls must be reachable by name for tests and automation."
	):
		return

	var project := CCFStorageService.new_project()
	var settings := CCFSettingsService.load_settings()
	workspace.load_project(
		project, CCFTemplateService.load_default_template(), settings
	)
	await process_frame
	await process_frame

	if not _require(
		panel.visible == false
		and toggle.text == "Project setup"
		and toggle.button_pressed == false,
		"Loading a project must collapse the setup rows behind one labelled control."
	):
		return
	if not _require(
		hint.text.contains("Template:"),
		"While collapsed the header must still name the active workspace template."
	):
		return
	var controls: Dictionary = workspace.get("_field_controls")
	if not _require(
		controls != null and controls.size() > 0,
		"Collapsing project setup must not disturb the field editor beneath it."
	):
		return

	workspace.call("_toggle_project_setup_v02118")
	await process_frame
	if not _require(
		panel.visible == true
		and toggle.text == "Hide project setup"
		and toggle.button_pressed == true,
		"The setup control must reveal the project, series, character and template rows."
	):
		return

	workspace.call("_toggle_project_setup_v02118")
	await process_frame
	if not _require(
		panel.visible == false and toggle.text == "Project setup",
		"The setup control must hide the rows again."
	):
		return

	# An author who explicitly expanded the block keeps it open across loads.
	workspace.call("_toggle_project_setup_v02118")
	workspace.load_project(
		project, CCFTemplateService.load_default_template(), settings
	)
	await process_frame
	if not _require(
		panel.visible == true,
		"An explicit author choice must survive the next project load."
	):
		return

	var tabs: TabContainer = workspace.get("_tabs")
	if not _require(
		tabs != null and tabs.get_tab_count() >= 6,
		"The workspace editor tabs must still be built."
	):
		return
	var front_porch_found := false
	for index in range(tabs.get_tab_count()):
		if tabs.get_tab_title(index).to_lower().contains("front porch"):
			front_porch_found = true
	if not _require(front_porch_found, "The Front Porch tab must remain available."):
		return
	print("V02118_WORKSPACE_SETUP_COLLAPSE_OK")
	quit(0)
