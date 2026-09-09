extends "res://scripts/main_v0180.gd"

const SETTINGS_VIEW_V0180_HOTFIX2 = preload(
	"res://scripts/ui/settings_view_v0180_hotfix2.gd"
)
const BUILD_DISPLAY_VERSION_V0180_HOTFIX2 := "0.18.0-hotfix2"

var _update_notice_v0180_hotfix2: Button


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0180_hotfix2()
	_install_update_notice_v0180_hotfix2()
	var update_settings := _settings_view as CCFSettingsV0180Hotfix2View
	if update_settings == null:
		return
	update_settings.configure_updates_v0180_hotfix2(
		_update_comparison_version_v0180_hotfix2()
	)
	update_settings.update_state_changed_v0180_hotfix2.connect(
		_on_update_state_changed_v0180_hotfix2
	)
	update_settings.call_deferred(
		"begin_automatic_update_check_v0180_hotfix2"
	)


func _install_settings_view_v01528() -> void:
	if _content == null:
		return
	var previous_settings: CCFSettingsView = _settings_view
	if (
		previous_settings != null
		and previous_settings.get_script() == SETTINGS_VIEW_V0180_HOTFIX2
	):
		previous_settings.load_settings(_settings)
		return
	var should_be_visible := _current_view == "settings"
	if previous_settings != null:
		if previous_settings.settings_saved.is_connected(_on_settings_saved):
			previous_settings.settings_saved.disconnect(_on_settings_saved)
		if previous_settings.get_parent() == _content:
			_content.remove_child(previous_settings)
		previous_settings.queue_free()
	var upgraded: CCFSettingsView = SETTINGS_VIEW_V0180_HOTFIX2.new()
	upgraded.visible = should_be_visible
	upgraded.settings_saved.connect(_on_settings_saved)
	_settings_view = upgraded
	_content.add_child(upgraded)
	upgraded.load_settings(_settings)


func _install_update_notice_v0180_hotfix2() -> void:
	if _update_notice_v0180_hotfix2 != null:
		return
	for node in find_children("*", "Label", true, false):
		if not node is Label or not node.text.begins_with("Godot rewrite • v"):
			continue
		var parent_node := node.get_parent()
		if parent_node == null:
			return
		_update_notice_v0180_hotfix2 = Button.new()
		_update_notice_v0180_hotfix2.text = "Update available"
		_update_notice_v0180_hotfix2.tooltip_text = (
			"Open Settings → Updates to review the published GitHub release."
		)
		_update_notice_v0180_hotfix2.visible = false
		_update_notice_v0180_hotfix2.pressed.connect(
			_open_updates_settings_v0180_hotfix2
		)
		parent_node.add_child(_update_notice_v0180_hotfix2)
		parent_node.move_child(
			_update_notice_v0180_hotfix2, node.get_index() + 1
		)
		return


func _on_update_state_changed_v0180_hotfix2(result: Dictionary) -> void:
	if _update_notice_v0180_hotfix2 == null:
		return
	if not bool(result.get("ok", false)):
		return
	var available := bool(result.get("update_available", false))
	_update_notice_v0180_hotfix2.visible = available
	if available:
		var latest := str(result.get("latest_version", ""))
		_update_notice_v0180_hotfix2.text = "Update v%s available" % latest
		_global_status.text = "Character Card Forge v%s is available." % latest


func _open_updates_settings_v0180_hotfix2() -> void:
	_show_view("settings")
	if _settings_view is CCFSettingsV0180Hotfix2View:
		(_settings_view as CCFSettingsV0180Hotfix2View).show_updates_v0180_hotfix2()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0180_HOTFIX2
	var release_version := str(
		ProjectSettings.get_setting(
			"application/config/version", BUILD_DISPLAY_VERSION_V0180_HOTFIX2
		)
	).strip_edges()
	return (
		release_version
		if not release_version.is_empty()
		else BUILD_DISPLAY_VERSION_V0180_HOTFIX2
	)


func _update_build_version_label_v0180_hotfix2() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = (
				"Godot rewrite • v%s"
				% BUILD_DISPLAY_VERSION_V0180_HOTFIX2
			)
			node.tooltip_text = (
				"Development hotfix with model-tolerant Safe Section text recovery "
				+ "and optional GitHub Release update checks."
			)
			return
