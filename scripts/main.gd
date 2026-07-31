extends Control

const APP_VERSION := "0.14.6"

var _settings: Dictionary
var _content: MarginContainer
var _page_title: Label
var _global_status: Label
var _dashboard: CCFDashboardView
var _library: CCFLibraryView
var _workspace: CCFWorkspaceView
var _settings_view: CCFSettingsView
var _template_manager: CCFTemplateManagerView
var _series_manager: CCFSeriesManagerView
var _image_generation_window: CCFImageGenerationWindow
var _current_view := "dashboard"
var _nav_buttons: Dictionary = {}


func _ready() -> void:
	CCFStorageService.ensure_directories()
	_settings = CCFSettingsService.load_settings()
	_build_theme()
	_build_shell()
	_build_image_generation_window()
	_show_view(str(_settings.get("ui", {}).get("last_view", "dashboard")))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _workspace != null:
			_workspace.save_tool_window_state()
		if _image_generation_window != null:
			_image_generation_window.save_window_state()
		if _workspace != null and _workspace.has_unsaved_changes():
			_global_status.text = "Unsaved workspace changes exist. Save them before closing if you want to keep them."
		get_tree().quit()


func _build_theme() -> void:
	var app_theme := Theme.new()
	app_theme.default_font_size = 15

	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("2b2d42")
	button_style.border_color = Color("474b6a")
	button_style.set_border_width_all(1)
	button_style.set_corner_radius_all(8)
	button_style.content_margin_left = 14
	button_style.content_margin_right = 14
	button_style.content_margin_top = 9
	button_style.content_margin_bottom = 9
	app_theme.set_stylebox("normal", "Button", button_style)

	var hover_style := button_style.duplicate()
	hover_style.bg_color = Color("383b57")
	hover_style.border_color = Color("8f79e8")
	app_theme.set_stylebox("hover", "Button", hover_style)

	var pressed_style := button_style.duplicate()
	pressed_style.bg_color = Color("5b4b92")
	pressed_style.border_color = Color("b7a4ff")
	app_theme.set_stylebox("pressed", "Button", pressed_style)

	var edit_style := StyleBoxFlat.new()
	edit_style.bg_color = Color("171925")
	edit_style.border_color = Color("3e425d")
	edit_style.set_border_width_all(1)
	edit_style.set_corner_radius_all(7)
	edit_style.content_margin_left = 10
	edit_style.content_margin_right = 10
	edit_style.content_margin_top = 8
	edit_style.content_margin_bottom = 8
	app_theme.set_stylebox("normal", "LineEdit", edit_style)
	app_theme.set_stylebox("normal", "TextEdit", edit_style)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("202231")
	panel_style.border_color = Color("34374f")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	app_theme.set_stylebox("panel", "PanelContainer", panel_style)

	app_theme.set_color("font_color", "Label", Color("ececf4"))
	app_theme.set_color("font_color", "Button", Color("e9e8f2"))
	app_theme.set_color("font_color", "LineEdit", Color("f1f0f7"))
	app_theme.set_color("font_color", "TextEdit", Color("f1f0f7"))
	self.theme = app_theme


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("10111a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shell := HBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("separation", 0)
	add_child(shell)

	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size.x = 245
	shell.add_child(sidebar)
	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 16)
	side_margin.add_theme_constant_override("margin_right", 16)
	side_margin.add_theme_constant_override("margin_top", 18)
	side_margin.add_theme_constant_override("margin_bottom", 18)
	sidebar.add_child(side_margin)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 8)
	side_margin.add_child(side)

	var brand := Label.new()
	brand.text = "CHARACTER\nCARD FORGE"
	brand.add_theme_font_size_override("font_size", 22)
	side.add_child(brand)
	var version_label := Label.new()
	version_label.text = "Godot rewrite • v%s" % APP_VERSION
	version_label.modulate = Color(0.64, 0.66, 0.75)
	side.add_child(version_label)
	side.add_child(HSeparator.new())

	_add_nav(side, "dashboard", "Home")
	_add_nav(side, "library", "Character Library")
	_add_nav(side, "workspace", "Workspace")
	_add_tool_button(side, "Image Studio", _open_image_studio)
	_add_nav(side, "series", "Series")
	_add_nav(side, "templates", "Templates")
	_add_nav(side, "settings", "Settings")

	var side_spacer := Control.new()
	side_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(side_spacer)
	var data_hint := Label.new()
	data_hint.text = "Projects are stored as lightweight JSON plus separate asset folders."
	data_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	data_hint.modulate = Color(0.58, 0.61, 0.7)
	side.add_child(data_hint)

	var main_content := VBoxContainer.new()
	main_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_content.add_theme_constant_override("separation", 0)
	shell.add_child(main_content)

	var header := PanelContainer.new()
	header.custom_minimum_size.y = 66
	main_content.add_child(header)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 22)
	header_margin.add_theme_constant_override("margin_right", 22)
	header_margin.add_theme_constant_override("margin_top", 12)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	header.add_child(header_margin)
	var header_row := HBoxContainer.new()
	header_margin.add_child(header_row)
	_page_title = Label.new()
	_page_title.text = "Home"
	_page_title.add_theme_font_size_override("font_size", 22)
	_page_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(_page_title)
	_global_status = Label.new()
	_global_status.text = "Ready"
	_global_status.modulate = Color(0.65, 0.69, 0.78)
	header_row.add_child(_global_status)

	_content = MarginContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("margin_left", 22)
	_content.add_theme_constant_override("margin_right", 22)
	_content.add_theme_constant_override("margin_top", 18)
	_content.add_theme_constant_override("margin_bottom", 20)
	main_content.add_child(_content)

	_dashboard = CCFDashboardView.new()
	_dashboard.new_character_requested.connect(_create_new_character)
	_dashboard.library_requested.connect(func(): _show_view("library"))
	_dashboard.settings_requested.connect(func(): _show_view("settings"))
	_dashboard.open_project_requested.connect(_open_project)
	_content.add_child(_dashboard)

	_library = CCFLibraryView.new()
	_library.visible = false
	_library.new_character_requested.connect(_create_new_character)
	_library.open_project_requested.connect(_open_project)
	_library.project_changed.connect(_refresh_home_and_library)
	_content.add_child(_library)

	_workspace = CCFWorkspaceView.new()
	_workspace.visible = false
	_workspace.project_saved.connect(_on_project_saved)
	_workspace.library_requested.connect(func(): _show_view("library"))
	_workspace.settings_requested.connect(func(): _show_view("settings"))
	_workspace.template_manager_requested.connect(func(): _show_view("templates"))
	_workspace.series_manager_requested.connect(func(): _show_view("series"))
	_workspace.project_imported.connect(_on_project_imported)
	_content.add_child(_workspace)

	_series_manager = CCFSeriesManagerView.new()
	_series_manager.visible = false
	_series_manager.load_settings(_settings)
	_series_manager.series_changed.connect(_on_series_changed)
	_content.add_child(_series_manager)

	_template_manager = CCFTemplateManagerView.new()
	_template_manager.visible = false
	_template_manager.templates_changed.connect(_on_templates_changed)
	_content.add_child(_template_manager)

	_settings_view = CCFSettingsView.new()
	_settings_view.visible = false
	_settings_view.settings_saved.connect(_on_settings_saved)
	_content.add_child(_settings_view)


func _build_image_generation_window() -> void:
	_image_generation_window = CCFImageGenerationWindow.new()
	_image_generation_window.visible = false
	_image_generation_window.title = "Character Card Forge — Image Generation Studio"
	_image_generation_window.size = Vector2i(1180, 820)
	_image_generation_window.min_size = Vector2i(920, 650)
	_image_generation_window.force_native = true
	_image_generation_window.transient = true
	_image_generation_window.exclusive = false
	_image_generation_window.project_changed.connect(_on_image_project_changed)
	add_child(_image_generation_window)
	_image_generation_window.hide()


func _add_nav(parent: VBoxContainer, view_id: String, button_text: String) -> void:
	var button := Button.new()
	button.text = button_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 44
	button.pressed.connect(func(): _show_view(view_id))
	parent.add_child(button)
	_nav_buttons[view_id] = button


func _add_tool_button(parent: VBoxContainer, button_text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = button_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 44
	button.pressed.connect(action)
	parent.add_child(button)


func _open_image_studio() -> void:
	if _workspace != null and _workspace.has_unsaved_changes():
		_global_status.text = "Image Studio uses saved projects. Save workspace changes first if you want them included in image prompts."
	_image_generation_window.open_studio()


func _show_view(view_id: String) -> void:
	if not view_id in ["dashboard", "library", "workspace", "series", "templates", "settings"]:
		view_id = "dashboard"
	if view_id == "workspace" and _workspace.current_project().is_empty():
		view_id = "dashboard"

	_current_view = view_id
	_dashboard.visible = view_id == "dashboard"
	_library.visible = view_id == "library"
	_workspace.visible = view_id == "workspace"
	_series_manager.visible = view_id == "series"
	_template_manager.visible = view_id == "templates"
	_settings_view.visible = view_id == "settings"
	_page_title.text = {
		"dashboard": "Home",
		"library": "Character Library",
		"workspace": "Character Workspace",
		"series": "Series Manager",
		"templates": "Template Manager",
		"settings": "Settings"
	}.get(view_id, "Character Card Forge")

	for nav_id in _nav_buttons:
		var button: Button = _nav_buttons[nav_id]
		button.disabled = nav_id == view_id

	if view_id == "dashboard":
		_dashboard.refresh()
	elif view_id == "library":
		_library.refresh_projects()
	elif view_id == "series":
		_series_manager.load_settings(_settings)
		_series_manager.refresh_series()
	elif view_id == "templates":
		_template_manager.refresh_templates()
	elif view_id == "settings":
		_settings_view.load_settings(_settings)

	var ui: Dictionary = _settings.get("ui", {})
	ui["last_view"] = view_id
	_settings["ui"] = ui
	CCFSettingsService.save_settings(_settings)


func _create_new_character() -> void:
	var project := CCFStorageService.new_project()
	var result := CCFStorageService.save_project(project)
	if not result.get("ok", false):
		_global_status.text = str(result.get("error", "Could not create project."))
		return
	_workspace.load_project(project, CCFTemplateService.load_default_template(), _settings)
	_show_view("workspace")
	_global_status.text = "New character project created"
	_refresh_home_and_library()


func _open_project(project_id: String) -> void:
	var loaded := CCFStorageService.load_project(project_id)
	if not loaded.get("ok", false):
		_global_status.text = str(loaded.get("error", "Could not load project."))
		return
	var project: Dictionary = loaded.get("data", {})
	var template_id := CCFStorageService.active_character_template_id(project)
	_workspace.load_project(project, CCFTemplateService.load_template(template_id), _settings)
	_show_view("workspace")
	_global_status.text = "Project loaded"


func _on_project_saved(_project: Dictionary) -> void:
	_global_status.text = "Project saved"
	_refresh_home_and_library()


func _on_project_imported(project: Dictionary) -> void:
	if project.is_empty():
		_global_status.text = "Imported project data was empty."
		return
	var template_id := CCFStorageService.active_character_template_id(project)
	_workspace.load_project(project, CCFTemplateService.load_template(template_id), _settings)
	_show_view("workspace")
	_global_status.text = "Project imported"
	_refresh_home_and_library()


func _on_image_project_changed(project: Dictionary) -> void:
	_refresh_home_and_library()
	var current_project := _workspace.current_project()
	if str(current_project.get("project_id", "")) != str(project.get("project_id", "")):
		_global_status.text = "Image Studio updated a saved character project."
		return
	if _workspace.has_unsaved_changes():
		_global_status.text = "Image Studio updated the saved project. The open workspace has unsaved edits, so it was not reloaded."
		return
	var template_id := CCFStorageService.active_character_template_id(project)
	_workspace.load_project(project, CCFTemplateService.load_template(template_id), _settings)
	_global_status.text = "Image Studio updated the open project and refreshed its saved portrait/gallery data."


func _on_settings_saved(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	_workspace.update_settings(_settings)
	_series_manager.load_settings(_settings)
	_global_status.text = "Settings saved"


func _on_templates_changed() -> void:
	_workspace.refresh_templates()
	_global_status.text = "Templates updated"


func _on_series_changed() -> void:
	_workspace.refresh_series()
	_library.refresh_projects(true)
	_dashboard.refresh()
	_global_status.text = "Series library updated"


func _refresh_home_and_library() -> void:
	_dashboard.refresh()
	_library.refresh_projects()
