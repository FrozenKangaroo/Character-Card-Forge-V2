extends "res://scripts/main_v01310.gd"

const SETTINGS_V01311 = preload("res://scripts/ui/settings_view_v01311.gd")
const GENERATION_SERVICE_V01311 = preload("res://scripts/services/generation_service_v01311.gd")
const BUILD_DISPLAY_VERSION_V01311 := "0.13.11"


func _ready() -> void:
	super._ready()
	call_deferred("_rename_creative_vision_mode")


func _install_settings_v0135() -> void:
	if _content == null:
		return
	var previous_settings: CCFSettingsView = _settings_view
	if previous_settings != null and previous_settings.get_script() == SETTINGS_V01311:
		return
	var should_be_visible := _current_view == "settings"
	if previous_settings != null:
		if previous_settings.settings_saved.is_connected(_on_settings_saved):
			previous_settings.settings_saved.disconnect(_on_settings_saved)
		if previous_settings.get_parent() == _content:
			_content.remove_child(previous_settings)
		previous_settings.queue_free()
	var upgraded: CCFSettingsView = SETTINGS_V01311.new()
	upgraded.visible = should_be_visible
	upgraded.settings_saved.connect(_on_settings_saved)
	_settings_view = upgraded
	_content.add_child(upgraded)
	upgraded.load_settings(_settings)


func _install_generation_parity_service() -> void:
	if _workspace == null:
		return
	var current_service: CCFGenerationService = _workspace._generation_service
	if current_service != null and current_service.get_script() == GENERATION_SERVICE_V01311:
		return
	if current_service != null:
		_disconnect_workspace_generation_signals(current_service)
		if current_service.get_parent() == _workspace:
			_workspace.remove_child(current_service)
		current_service.queue_free()
	var upgraded_service: CCFGenerationService = GENERATION_SERVICE_V01311.new()
	_workspace._generation_service = upgraded_service
	_workspace.add_child(upgraded_service)
	upgraded_service.job_started.connect(_workspace._on_job_started)
	upgraded_service.job_completed.connect(_workspace._on_job_completed)
	upgraded_service.job_failed.connect(_workspace._on_job_failed)
	upgraded_service.job_cancelled.connect(_workspace._on_job_cancelled)
	upgraded_service.queue_changed.connect(_workspace._on_queue_changed)
	_rebind_workspace_generation_clients(upgraded_service)


func _rename_creative_vision_mode() -> void:
	for node in find_children("*", "OptionButton", true, false):
		if not node is OptionButton:
			continue
		var selector: OptionButton = node
		for index in range(selector.item_count):
			var item_text := selector.get_item_text(index)
			if item_text in ["Full Card Suggestions", "Full Card", "Full card suggestions"]:
				selector.set_item_text(index, "Creative Concept")
				selector.tooltip_text = "Visual Analysis describes visible character traits conservatively. Creative Concept uses the image as a visual seed and invents a generation-ready character premise for the normal Character Card Forge generation pipeline."


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01311
			node.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return
