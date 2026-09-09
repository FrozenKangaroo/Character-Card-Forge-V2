class_name CCFSettingsV0180Hotfix2View
extends "res://scripts/ui/settings_view_v01528.gd"

signal update_state_changed_v0180_hotfix2(result: Dictionary)

const UPDATE_SERVICE_V0180_HOTFIX2 = preload(
	"res://scripts/services/update_service_v0180_hotfix2.gd"
)

var _update_service_v0180_hotfix2: CCFUpdateServiceV0180Hotfix2
var _update_tab_index_v0180_hotfix2 := -1
var _update_current_version_v0180_hotfix2 := ""
var _automatic_checks_v0180_hotfix2: CheckBox
var _update_current_label_v0180_hotfix2: Label
var _update_latest_label_v0180_hotfix2: Label
var _update_status_v0180_hotfix2: Label
var _update_notes_v0180_hotfix2: TextEdit
var _update_check_button_v0180_hotfix2: Button
var _update_release_button_v0180_hotfix2: Button
var _update_download_button_v0180_hotfix2: Button
var _update_result_v0180_hotfix2: Dictionary = {}


func _ready() -> void:
	super._ready()
	_update_service_v0180_hotfix2 = UPDATE_SERVICE_V0180_HOTFIX2.new()
	add_child(_update_service_v0180_hotfix2)
	_update_service_v0180_hotfix2.check_started.connect(
		_on_update_check_started_v0180_hotfix2
	)
	_update_service_v0180_hotfix2.check_finished.connect(
		_on_update_check_finished_v0180_hotfix2
	)
	_build_updates_tab_v0180_hotfix2()
	_load_update_preferences_v0180_hotfix2()


func configure_updates_v0180_hotfix2(current_version: String) -> void:
	_update_current_version_v0180_hotfix2 = current_version.strip_edges()
	if _update_current_label_v0180_hotfix2 != null:
		_update_current_label_v0180_hotfix2.text = (
			"Installed version: v%s" % _update_current_version_v0180_hotfix2
		)


func begin_automatic_update_check_v0180_hotfix2() -> void:
	if (
		_update_service_v0180_hotfix2 == null
		or _update_current_version_v0180_hotfix2.is_empty()
	):
		return
	var cached := _update_service_v0180_hotfix2.cached_result_v0180_hotfix2(
		_update_current_version_v0180_hotfix2
	)
	if bool(cached.get("ok", false)):
		_apply_update_result_v0180_hotfix2(cached, true)
	if (
		_automatic_checks_v0180_hotfix2 == null
		or not _automatic_checks_v0180_hotfix2.button_pressed
	):
		return
	# Source/editor runs never make an unsolicited network request. Packaged
	# builds perform the disclosed startup check; developers can still use Check Now.
	if OS.has_feature("editor"):
		if not bool(cached.get("ok", false)):
			_update_status_v0180_hotfix2.text = (
				"Automatic checks start in packaged builds. Use Check Now while running from source."
			)
		return
	if not _update_service_v0180_hotfix2.automatic_check_due_v0180_hotfix2():
		return
	_start_update_check_v0180_hotfix2()


func show_updates_v0180_hotfix2() -> void:
	if _tabs != null and _update_tab_index_v0180_hotfix2 >= 0:
		_tabs.current_tab = _update_tab_index_v0180_hotfix2


func update_service_v0180_hotfix2() -> CCFUpdateServiceV0180Hotfix2:
	return _update_service_v0180_hotfix2


func load_settings(settings: Dictionary) -> void:
	super.load_settings(settings)
	_load_update_preferences_v0180_hotfix2()


func _build_updates_tab_v0180_hotfix2() -> void:
	var parent := _make_scroll_tab("Updates")
	_update_tab_index_v0180_hotfix2 = _tabs.get_tab_count() - 1

	var heading := Label.new()
	heading.text = "Application updates"
	heading.add_theme_font_size_override("font_size", 20)
	parent.add_child(heading)

	var explanation := Label.new()
	explanation.text = (
		"Character Card Forge checks the latest published GitHub Release. Automatic "
		+ "checks make one unauthenticated request at startup no more than once every "
		+ "24 hours. No AI-provider credentials, character data or project content are sent."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color(0.68, 0.72, 0.82)
	parent.add_child(explanation)

	_automatic_checks_v0180_hotfix2 = CheckBox.new()
	_automatic_checks_v0180_hotfix2.text = (
		"Automatically check GitHub for a newer published release"
	)
	_automatic_checks_v0180_hotfix2.tooltip_text = (
		"Checks only the public FrozenKangaroo/Character-Card-Forge-V2 latest-release endpoint."
	)
	parent.add_child(_automatic_checks_v0180_hotfix2)

	var preference_button := Button.new()
	preference_button.text = "Save Update Preference"
	preference_button.pressed.connect(
		_save_update_preference_v0180_hotfix2
	)
	parent.add_child(preference_button)

	parent.add_child(HSeparator.new())

	_update_current_label_v0180_hotfix2 = Label.new()
	_update_current_label_v0180_hotfix2.text = "Installed version: unknown"
	parent.add_child(_update_current_label_v0180_hotfix2)

	_update_latest_label_v0180_hotfix2 = Label.new()
	_update_latest_label_v0180_hotfix2.text = "Latest published release: not checked"
	parent.add_child(_update_latest_label_v0180_hotfix2)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	parent.add_child(actions)

	_update_check_button_v0180_hotfix2 = Button.new()
	_update_check_button_v0180_hotfix2.text = "Check Now"
	_update_check_button_v0180_hotfix2.pressed.connect(
		_start_update_check_v0180_hotfix2
	)
	actions.add_child(_update_check_button_v0180_hotfix2)

	_update_release_button_v0180_hotfix2 = Button.new()
	_update_release_button_v0180_hotfix2.text = "Open Release Page"
	_update_release_button_v0180_hotfix2.disabled = true
	_update_release_button_v0180_hotfix2.pressed.connect(
		_open_release_page_v0180_hotfix2
	)
	actions.add_child(_update_release_button_v0180_hotfix2)

	_update_download_button_v0180_hotfix2 = Button.new()
	_update_download_button_v0180_hotfix2.text = "Download for This Computer"
	_update_download_button_v0180_hotfix2.disabled = true
	_update_download_button_v0180_hotfix2.pressed.connect(
		_open_platform_download_v0180_hotfix2
	)
	actions.add_child(_update_download_button_v0180_hotfix2)

	_update_status_v0180_hotfix2 = Label.new()
	_update_status_v0180_hotfix2.text = "Ready to check."
	_update_status_v0180_hotfix2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_status_v0180_hotfix2.modulate = Color(0.72, 0.82, 0.72)
	parent.add_child(_update_status_v0180_hotfix2)

	var notes_heading := Label.new()
	notes_heading.text = "Release notes"
	notes_heading.add_theme_font_size_override("font_size", 18)
	parent.add_child(notes_heading)

	_update_notes_v0180_hotfix2 = TextEdit.new()
	_update_notes_v0180_hotfix2.editable = false
	_update_notes_v0180_hotfix2.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_update_notes_v0180_hotfix2.custom_minimum_size.y = 260
	_update_notes_v0180_hotfix2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_update_notes_v0180_hotfix2.text = "Check GitHub to load the latest published release notes."
	parent.add_child(_update_notes_v0180_hotfix2)

	var install_boundary := Label.new()
	install_boundary.text = (
		"Download opens GitHub's platform package in your browser. CCF never silently "
		+ "replaces a running executable; close the app and install the downloaded "
		+ "package when you are ready. Projects and settings remain under the normal user data folder."
	)
	install_boundary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	install_boundary.modulate = Color(0.74, 0.68, 0.52)
	parent.add_child(install_boundary)


func _load_update_preferences_v0180_hotfix2() -> void:
	if _automatic_checks_v0180_hotfix2 == null:
		return
	var update_value: Variant = _settings.get("updates", {})
	var update_settings: Dictionary = (
		update_value if update_value is Dictionary else {}
	)
	_automatic_checks_v0180_hotfix2.button_pressed = bool(
		update_settings.get("automatic_checks", true)
	)


func _save_update_preference_v0180_hotfix2() -> void:
	var fresh := CCFSettingsService.load_settings()
	var update_settings: Dictionary = fresh.get("updates", {}).duplicate(true)
	update_settings["automatic_checks"] = (
		_automatic_checks_v0180_hotfix2.button_pressed
	)
	fresh["updates"] = update_settings
	var save_result := CCFSettingsService.save_settings(fresh)
	if not bool(save_result.get("ok", false)):
		_update_status_v0180_hotfix2.text = str(
			save_result.get("error", "Could not save the update preference.")
		)
		return
	_settings = CCFSettingsService.load_settings()
	_update_status_v0180_hotfix2.text = (
		"Automatic update checks enabled."
		if _automatic_checks_v0180_hotfix2.button_pressed
		else "Automatic update checks disabled. Check Now remains available."
	)
	settings_saved.emit(_settings.duplicate(true))


func _start_update_check_v0180_hotfix2() -> void:
	if _update_current_version_v0180_hotfix2.is_empty():
		_update_status_v0180_hotfix2.text = (
			"The installed version is unavailable, so CCF cannot compare releases."
		)
		return
	var started := _update_service_v0180_hotfix2.check_for_updates_v0180_hotfix2(
		_update_current_version_v0180_hotfix2
	)
	if not bool(started.get("ok", false)):
		_update_status_v0180_hotfix2.text = str(
			started.get("error", "Could not start the update check.")
		)


func _on_update_check_started_v0180_hotfix2() -> void:
	_update_check_button_v0180_hotfix2.disabled = true
	_update_status_v0180_hotfix2.text = "Checking the latest published GitHub release…"


func _on_update_check_finished_v0180_hotfix2(result: Dictionary) -> void:
	_update_check_button_v0180_hotfix2.disabled = false
	_apply_update_result_v0180_hotfix2(result, false)


func _apply_update_result_v0180_hotfix2(
	result: Dictionary, from_cache: bool
) -> void:
	if not bool(result.get("ok", false)):
		_update_status_v0180_hotfix2.text = str(
			result.get("error", "The update check failed.")
		)
		update_state_changed_v0180_hotfix2.emit(result.duplicate(true))
		return
	_update_result_v0180_hotfix2 = result.duplicate(true)
	var latest := str(result.get("latest_version", "unknown"))
	_update_latest_label_v0180_hotfix2.text = (
		"Latest published release: v%s" % latest
	)
	var release: Dictionary = result.get("release", {})
	var notes := str(release.get("body", "")).strip_edges()
	_update_notes_v0180_hotfix2.text = (
		notes if not notes.is_empty() else "This release has no published notes."
	)
	_update_release_button_v0180_hotfix2.disabled = false
	var asset_value: Variant = result.get("asset", {})
	var asset: Dictionary = asset_value if asset_value is Dictionary else {}
	_update_download_button_v0180_hotfix2.disabled = asset.is_empty()
	if not asset.is_empty():
		_update_download_button_v0180_hotfix2.text = (
			"Download %s" % _compact_asset_name_v0180_hotfix2(
				str(asset.get("name", "update package"))
			)
		)
	else:
		_update_download_button_v0180_hotfix2.text = (
			"No Package for This Platform"
		)
	var cache_note := " (cached)" if from_cache else ""
	if bool(result.get("update_available", false)):
		_update_status_v0180_hotfix2.text = (
			"Update available: v%s%s. Review the notes, then download when ready."
			% [latest, cache_note]
		)
	elif int(result.get("comparison", 0)) < 0:
		_update_status_v0180_hotfix2.text = (
			"This development build is newer than the latest published release%s."
			% cache_note
		)
	else:
		_update_status_v0180_hotfix2.text = (
			"Character Card Forge is up to date%s." % cache_note
		)
	update_state_changed_v0180_hotfix2.emit(result.duplicate(true))


func _open_release_page_v0180_hotfix2() -> void:
	var release_value: Variant = _update_result_v0180_hotfix2.get(
		"release", {}
	)
	var release: Dictionary = (
		release_value if release_value is Dictionary else {}
	)
	var url := str(release.get("release_url", "")).strip_edges()
	if url.is_empty():
		url = _update_service_v0180_hotfix2.releases_page_v0180_hotfix2()
	var open_error := OS.shell_open(url)
	if open_error != OK:
		_update_status_v0180_hotfix2.text = (
			"Could not open the GitHub release page (error %s)." % open_error
		)


func _open_platform_download_v0180_hotfix2() -> void:
	var asset_value: Variant = _update_result_v0180_hotfix2.get("asset", {})
	var asset: Dictionary = asset_value if asset_value is Dictionary else {}
	var url := str(asset.get("download_url", "")).strip_edges()
	if url.is_empty():
		_update_status_v0180_hotfix2.text = (
			"No downloadable package was published for this platform."
		)
		return
	var open_error := OS.shell_open(url)
	if open_error != OK:
		_update_status_v0180_hotfix2.text = (
			"Could not open the platform download (error %s)." % open_error
		)


func _compact_asset_name_v0180_hotfix2(asset_name: String) -> String:
	if asset_name.contains("windows"):
		return "Windows"
	if asset_name.contains("linux"):
		return "Linux"
	if asset_name.contains("macos"):
		return "macOS"
	return "Update"
