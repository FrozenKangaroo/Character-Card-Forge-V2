extends "res://scripts/main_with_image_page.gd"

const BUILD_DISPLAY_VERSION := "0.13.7"


func _build_image_generation_window() -> void:
	_image_generation_window = CCFImageGenerationControllerV0133.new()
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


func _ready() -> void:
	super._ready()
	_install_library_v0135()
	_install_settings_v0135()
	_install_workspace_v0133()
	_install_v013_template_manager()
	_install_generation_parity_service()
	_update_build_version_label()


func _install_library_v0135() -> void:
	if _content == null or _library is CCFLibraryV0135View:
		return
	var previous_library: CCFLibraryView = _library
	var should_be_visible := _current_view == "library"
	if previous_library != null:
		if previous_library.new_character_requested.is_connected(_create_new_character):
			previous_library.new_character_requested.disconnect(_create_new_character)
		if previous_library.open_project_requested.is_connected(_open_project):
			previous_library.open_project_requested.disconnect(_open_project)
		if previous_library.project_changed.is_connected(_refresh_home_and_library):
			previous_library.project_changed.disconnect(_refresh_home_and_library)
		if previous_library.get_parent() == _content:
			_content.remove_child(previous_library)
		previous_library.queue_free()
	var upgraded := CCFLibraryV0135View.new()
	upgraded.visible = should_be_visible
	upgraded.new_character_requested.connect(_create_new_character)
	upgraded.open_project_requested.connect(_open_project)
	upgraded.project_changed.connect(_refresh_home_and_library)
	_library = upgraded
	_content.add_child(upgraded)
	if should_be_visible:
		upgraded.refresh_projects()


func _install_settings_v0135() -> void:
	if _content == null or _settings_view is CCFSettingsV0135View:
		return
	var previous_settings: CCFSettingsView = _settings_view
	var should_be_visible := _current_view == "settings"
	if previous_settings != null:
		if previous_settings.settings_saved.is_connected(_on_settings_saved):
			previous_settings.settings_saved.disconnect(_on_settings_saved)
		if previous_settings.get_parent() == _content:
			_content.remove_child(previous_settings)
		previous_settings.queue_free()
	var upgraded := CCFSettingsV0135View.new()
	upgraded.visible = should_be_visible
	upgraded.settings_saved.connect(_on_settings_saved)
	_settings_view = upgraded
	_content.add_child(upgraded)
	upgraded.load_settings(_settings)


func _install_workspace_v0133() -> void:
	if _content == null or _workspace is CCFWorkspaceV0137View:
		return
	var previous_workspace: CCFWorkspaceView = _workspace
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

	var upgraded := CCFWorkspaceV0137View.new()
	upgraded.visible = should_be_visible
	upgraded.project_saved.connect(_on_project_saved)
	upgraded.library_requested.connect(_show_library_from_workspace)
	upgraded.settings_requested.connect(_show_settings_from_workspace)
	upgraded.template_manager_requested.connect(_show_templates_from_workspace)
	upgraded.series_manager_requested.connect(_show_series_from_workspace)
	upgraded.project_imported.connect(_on_project_imported)
	_workspace = upgraded
	_content.add_child(upgraded)


func _show_library_from_workspace() -> void:
	_show_view("library")


func _show_settings_from_workspace() -> void:
	_show_view("settings")


func _show_templates_from_workspace() -> void:
	_show_view("templates")


func _show_series_from_workspace() -> void:
	_show_view("series")


func _install_v013_template_manager() -> void:
	if _content == null:
		return
	var previous_manager: CCFTemplateManagerView = _template_manager
	if previous_manager is CCFTemplateManagerV013View:
		return
	var should_be_visible := _current_view == "templates"
	if previous_manager != null:
		if previous_manager.templates_changed.is_connected(_on_templates_changed):
			previous_manager.templates_changed.disconnect(_on_templates_changed)
		if previous_manager.get_parent() == _content:
			_content.remove_child(previous_manager)
		previous_manager.queue_free()
	var upgraded_manager := CCFTemplateManagerV013View.new()
	upgraded_manager.visible = should_be_visible
	upgraded_manager.templates_changed.connect(_on_templates_changed)
	_template_manager = upgraded_manager
	_content.add_child(upgraded_manager)
	if should_be_visible:
		upgraded_manager.refresh_templates()


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if not node is Label:
			continue
		var label: Label = node
		if label.text.begins_with("Godot rewrite • v"):
			label.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION
			label.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return


func _install_generation_parity_service() -> void:
	if _workspace == null:
		return
	var current_service: CCFGenerationService = _workspace._generation_service
	if current_service is CCFGenerationServiceV0135:
		return
	if current_service != null:
		_disconnect_workspace_generation_signals(current_service)
		if current_service.get_parent() == _workspace:
			_workspace.remove_child(current_service)
		current_service.queue_free()
	var parity_service := CCFGenerationServiceV0135.new()
	_workspace._generation_service = parity_service
	_workspace.add_child(parity_service)
	parity_service.job_started.connect(_workspace._on_job_started)
	parity_service.job_completed.connect(_workspace._on_job_completed)
	parity_service.job_failed.connect(_workspace._on_job_failed)
	parity_service.job_cancelled.connect(_workspace._on_job_cancelled)
	parity_service.queue_changed.connect(_workspace._on_queue_changed)
	_rebind_workspace_generation_clients(parity_service)


func _disconnect_workspace_generation_signals(service: CCFGenerationService) -> void:
	if service.job_started.is_connected(_workspace._on_job_started):
		service.job_started.disconnect(_workspace._on_job_started)
	if service.job_completed.is_connected(_workspace._on_job_completed):
		service.job_completed.disconnect(_workspace._on_job_completed)
	if service.job_failed.is_connected(_workspace._on_job_failed):
		service.job_failed.disconnect(_workspace._on_job_failed)
	if service.job_cancelled.is_connected(_workspace._on_job_cancelled):
		service.job_cancelled.disconnect(_workspace._on_job_cancelled)
	if service.queue_changed.is_connected(_workspace._on_queue_changed):
		service.queue_changed.disconnect(_workspace._on_queue_changed)


func _rebind_workspace_generation_clients(service: CCFGenerationService) -> void:
	var clients: Array[Variant] = [
		_workspace._builder_window,
		_workspace._controlled_build_window,
		_workspace._group_scene_window,
		_workspace._relationship_window,
		_workspace._card_workflow_window,
		_workspace._attachment_window
	]
	for client in clients:
		if client != null and client.has_method("set_generation_service"):
			client.call("set_generation_service", service)


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
	_workspace.load_project(project, CCFTemplateService.load_default_template(), _settings)
	_show_view("workspace")
	_global_status.text = "New Character Project draft — it will appear in the Library after its first real character is saved."
