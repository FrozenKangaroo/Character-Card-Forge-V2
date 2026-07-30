extends "res://scripts/main_v0139.gd"

const BUILD_DISPLAY_VERSION_V01310 := "0.13.10"
const TEMPLATE_PREFERENCES = preload("res://scripts/services/template_preference_service.gd")
const WORKSPACE_V01310 = preload("res://scripts/ui/workspace_v01310.gd")
const SETTINGS_V01310 = preload("res://scripts/ui/settings_view_v01310.gd")
const TEMPLATE_MANAGER_V01310 = preload("res://scripts/ui/template_manager_v01310_view.gd")


func _install_settings_v0135() -> void:
	if _content == null:
		return
	var previous_settings: CCFSettingsView = _settings_view
	if previous_settings != null and previous_settings.get_script() == SETTINGS_V01310:
		return
	var should_be_visible := _current_view == "settings"
	if previous_settings != null:
		if previous_settings.settings_saved.is_connected(_on_settings_saved):
			previous_settings.settings_saved.disconnect(_on_settings_saved)
		if previous_settings.get_parent() == _content:
			_content.remove_child(previous_settings)
		previous_settings.queue_free()
	var upgraded: CCFSettingsView = SETTINGS_V01310.new()
	upgraded.visible = should_be_visible
	upgraded.settings_saved.connect(_on_settings_saved)
	_settings_view = upgraded
	_content.add_child(upgraded)
	upgraded.load_settings(_settings)


func _install_workspace_v0133() -> void:
	if _content == null:
		return
	var previous_workspace: CCFWorkspaceView = _workspace
	if previous_workspace != null and previous_workspace.get_script() == WORKSPACE_V01310:
		return
	var should_be_visible := _current_view == "workspace"
	if previous_workspace != null:
		if previous_workspace.project_saved.is_connected(_on_project_saved):
			previous_workspace.project_saved.disconnect(_on_project_saved)
		if previous_workspace.library_requested.is_connected(_show_library_from_workspace):
			previous_workspace.library_requested.disconnect(_show_library_from_workspace)
		if previous_workspace.settings_requested.is_connected(_show_settings_from_workspace):
			previous_workspace.settings_requested.disconnect(_show_settings_from_workspace)
		if previous_workspace.template_manager_requested.is_connected(_show_templates_from_workspace):
			previous_workspace.template_manager_requested.disconnect(_show_templates_from_workspace)
		if previous_workspace.series_manager_requested.is_connected(_show_series_from_workspace):
			previous_workspace.series_manager_requested.disconnect(_show_series_from_workspace)
		if previous_workspace.project_imported.is_connected(_on_project_imported):
			previous_workspace.project_imported.disconnect(_on_project_imported)
		if previous_workspace.get_parent() == _content:
			_content.remove_child(previous_workspace)
		previous_workspace.queue_free()
	var upgraded: CCFWorkspaceView = WORKSPACE_V01310.new()
	upgraded.visible = should_be_visible
	upgraded.project_saved.connect(_on_project_saved)
	upgraded.library_requested.connect(_show_library_from_workspace)
	upgraded.settings_requested.connect(_show_settings_from_workspace)
	upgraded.template_manager_requested.connect(_show_templates_from_workspace)
	upgraded.series_manager_requested.connect(_show_series_from_workspace)
	upgraded.project_imported.connect(_on_project_imported)
	_workspace = upgraded
	_content.add_child(upgraded)


func _install_v013_template_manager() -> void:
	if _content == null:
		return
	var previous_manager: CCFTemplateManagerView = _template_manager
	if previous_manager != null and previous_manager.get_script() == TEMPLATE_MANAGER_V01310:
		return
	var should_be_visible := _current_view == "templates"
	if previous_manager != null:
		if previous_manager.templates_changed.is_connected(_on_templates_changed):
			previous_manager.templates_changed.disconnect(_on_templates_changed)
		if previous_manager.get_parent() == _content:
			_content.remove_child(previous_manager)
		previous_manager.queue_free()
	var upgraded_manager: CCFTemplateManagerView = TEMPLATE_MANAGER_V01310.new()
	upgraded_manager.visible = should_be_visible
	upgraded_manager.templates_changed.connect(_on_templates_changed)
	_template_manager = upgraded_manager
	_content.add_child(upgraded_manager)
	if should_be_visible:
		upgraded_manager.refresh_templates()


func _create_new_character() -> void:
	var project := CCFStorageService.new_project()
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["name"] = ""
	metadata["name_is_manual"] = false
	project["metadata"] = metadata
	var characters: Array = project.get("characters", []).duplicate(true)
	if not characters.is_empty() and characters[0] is Dictionary:
		var first_character: Dictionary = characters[0].duplicate(true)
		var character_metadata: Dictionary = first_character.get("metadata", {}).duplicate(true)
		var card: Dictionary = first_character.get("character", {}).duplicate(true)
		character_metadata["name"] = ""
		card["name"] = ""
		first_character["metadata"] = character_metadata
		first_character["character"] = card
		characters[0] = first_character
		project["characters"] = characters
	var character_id := CCFStorageService.active_character_id(project)
	var default_template_id: String = TEMPLATE_PREFERENCES.default_template_id(_settings)
	TEMPLATE_PREFERENCES.assign_character_template(project, character_id, default_template_id)
	_workspace.load_project(project, CCFTemplateService.load_template(default_template_id), _settings)
	_show_view("workspace")
	_global_status.text = "New Character Project draft using '%s' — it will appear in the Library after its first real character is saved." % str(_workspace._template.get("name", "Default Character Card"))


func _on_templates_changed() -> void:
	_settings = CCFSettingsService.load_settings()
	_workspace.update_settings(_settings)
	if _settings_view != null:
		_settings_view.load_settings(_settings)
	super._on_templates_changed()


func _on_settings_saved(settings: Dictionary) -> void:
	super._on_settings_saved(settings)
	if _template_manager != null:
		_template_manager.refresh_templates()


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01310
			node.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return
