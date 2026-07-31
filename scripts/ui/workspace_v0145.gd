class_name CCFWorkspaceV0145View
extends "res://scripts/ui/workspace_v0144.gd"

const LOREBOOK_WINDOW = preload("res://scripts/ui/lorebook_window_v0145.gd")

var _lorebook_window: CCFLorebookWindowV0145
var _navigation_installed := false


func _ready() -> void:
	super._ready()
	_build_lorebook_window()
	_install_grouped_navigation()


func _build_lorebook_window() -> void:
	_lorebook_window = LOREBOOK_WINDOW.new()
	_lorebook_window.lorebooks_saved.connect(_on_lorebooks_saved)
	add_child(_lorebook_window)
	_lorebook_window.hide()


func _install_grouped_navigation() -> void:
	if _navigation_installed:
		return
	var top := _first_flow_row()
	if top == null:
		return
	_navigation_installed = true

	# Keep only high-frequency actions directly visible. Existing buttons remain
	# alive and connected so menu items can route through the exact same handlers.
	var author_routes := [
		{"label": "Idea Generator", "button": "Idea Generator"},
		{"label": "Character Builder", "button": "Character Builder"},
		{"label": "Manual Guided", "button": "Manual Guided"},
		{"label": "Controlled Build", "button": "Controlled Build"},
	]
	var project_routes := [
		{"label": "Shared Context", "button": "Shared Context"},
		{"label": "Group Scene Generator", "button": "Group Scene Generator"},
		{"label": "Relationships", "button": "Relationships"},
		{"label": "Card Workflows", "button": "Card Workflows"},
		{"label": "Auto Series", "button": "Auto Series"},
		{"label": "Apply Series Tags", "button": "Apply Series Tags"},
		{"label": "Manage Series", "button": "Manage Series"},
		{"label": "Import / Export", "button": "Import / Export"},
	]
	var character_routes := [
		{"label": "Vision / Attachments", "button": "Vision / Attachments"},
		{"label": "Lorebook", "callable": Callable(self, "_open_lorebook")},
		{"label": "Duplicate Character", "button": "Duplicate Character"},
		{"label": "Move / Copy…", "button": "Move / Copy…"},
		{"label": "Remove Character", "button": "Remove Character"},
	]
	var tools_routes := [
		{"label": "Manage Templates", "button": "Manage Templates"},
		{"label": "API Settings", "button": "API Settings"},
	]

	var author := _make_navigation_menu("Author", author_routes)
	var project_menu := _make_navigation_menu("Project", project_routes)
	var character_menu := _make_navigation_menu("Character", character_routes)
	var tools := _make_navigation_menu("Tools", tools_routes)
	top.add_child(author)
	top.add_child(project_menu)
	top.add_child(character_menu)
	top.add_child(tools)

	var generate_index := _child_index_by_button_text(top, "Generate Character")
	var insertion := generate_index + 1 if generate_index >= 0 else 0
	for menu in [author, project_menu, character_menu, tools]:
		top.move_child(menu, insertion)
		insertion += 1

	var grouped_button_texts := [
		"Idea Generator", "Character Builder", "Manual Guided", "Controlled Build",
		"Import / Export", "Vision / Attachments", "Manage Templates", "API Settings",
		"Auto Series", "Apply Series Tags", "Manage Series", "Shared Context",
		"Group Scene Generator", "Relationships", "Card Workflows",
		"Duplicate Character", "Move / Copy…", "Remove Character"
	]
	for text in grouped_button_texts:
		var button := _find_workspace_button(text)
		if button != null:
			button.visible = false

	_status.text = "Workspace navigation grouped into Author, Project, Character, and Tools menus."


func _make_navigation_menu(label: String, routes: Array) -> MenuButton:
	var menu := MenuButton.new()
	menu.text = label
	menu.tooltip_text = "%s actions" % label
	var popup := menu.get_popup()
	for index in range(routes.size()):
		var route: Dictionary = routes[index]
		popup.add_item(str(route.get("label", "Action")), index)
	popup.id_pressed.connect(func(id: int) -> void:
		if id < 0 or id >= routes.size():
			return
		var route: Dictionary = routes[id]
		var callable_value: Variant = route.get("callable", Callable())
		if callable_value is Callable and callable_value.is_valid():
			callable_value.call()
			return
		var button_text := str(route.get("button", ""))
		var target := _find_workspace_button(button_text)
		if target != null:
			target.pressed.emit()
	)
	return menu


func _first_flow_row() -> HFlowContainer:
	for child in get_children():
		if child is HFlowContainer:
			return child
	return null


func _child_index_by_button_text(parent: Control, text: String) -> int:
	for index in range(parent.get_child_count()):
		var child := parent.get_child(index)
		if child is Button and child.text == text:
			return index
	return -1


func _find_workspace_button(text: String) -> Button:
	for node in find_children("*", "Button", true, false):
		if node is Button and node.text == text:
			return node
	return null


func _open_lorebook() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a character before editing lorebooks."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	_lorebook_window.open_for_project(_project_container, _project)
	_status.text = "Lorebook Manager opened for project and active-character lore."


func _on_lorebooks_saved(project_book: Dictionary, character_book: Dictionary) -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_project_container["lorebook"] = project_book.duplicate(true)
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	var character_value: Variant = _project.get("character", {})
	var character_data: Dictionary = character_value.duplicate(true) if character_value is Dictionary else {}
	character_data["character_book"] = character_book.duplicate(true)
	_project["character"] = character_data
	CCFStorageService.update_character(_project_container, _project)
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	_apply_attachment_runtime_context()
	_dirty = true
	_rebuild_form()
	_update_header()
	_populate_project_controls()
	_status.text = "Project and character lorebooks updated. Save the project when ready."


func _close_tool_windows_for_project_change() -> void:
	if _lorebook_window != null and _lorebook_window.visible:
		_lorebook_window.hide()
	super._close_tool_windows_for_project_change()
