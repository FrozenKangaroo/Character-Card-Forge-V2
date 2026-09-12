class_name CCFWorkspaceV0192View
extends "res://scripts/ui/workspace_v0191.gd"

const TEST_CHAT_WINDOW_V0192 = preload(
	"res://scripts/ui/test_chat_window_v0192.gd"
)

var _test_chat_window_v0192: CCFTestChatWindowV0192
var _test_chat_button_v0192: Button


func _ready() -> void:
	super._ready()
	_build_test_chat_v0192()
	_install_test_chat_navigation_v0192()


func _build_test_chat_v0192() -> void:
	_test_chat_window_v0192 = TEST_CHAT_WINDOW_V0192.new()
	_test_chat_window_v0192.visible = false
	add_child(_test_chat_window_v0192)
	_test_chat_window_v0192.hide()


func _install_test_chat_navigation_v0192() -> void:
	var top := _first_flow_row()
	if top == null or _find_workspace_button("Test Chat") != null:
		return
	_test_chat_button_v0192 = Button.new()
	_test_chat_button_v0192.text = "Test Chat"
	_test_chat_button_v0192.tooltip_text = (
		"Run an explicit Front Porch-backed single-character test, or inspect and "
		+ "transfer .fpchat and SillyTavern chat files."
	)
	_test_chat_button_v0192.pressed.connect(_open_test_chat_v0192)
	top.add_child(_test_chat_button_v0192)
	if _rich_authoring_button_v0190 != null:
		top.move_child(
			_test_chat_button_v0192,
			_rich_authoring_button_v0190.get_index() + 1
		)


func _open_test_chat_v0192() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a project before using Test Chat."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_test_chat_window_v0192.open_for_project(
		_project_container, _active_character_id
	)
	_status.text = "Test Chat opened. No network request or chat creation occurs until you choose an explicit action."


func _update_project_level_window_contexts() -> void:
	super._update_project_level_window_contexts()
	if (
		_test_chat_window_v0192 != null
		and _test_chat_window_v0192.visible
		and _test_chat_window_v0192.owns_project(
			str(_project_container.get("project_id", ""))
		)
	):
		_test_chat_window_v0192.update_project_context(
			_project_container, _active_character_id
		)


func _close_tool_windows_for_project_change() -> void:
	if _test_chat_window_v0192 != null and _test_chat_window_v0192.visible:
		_test_chat_window_v0192.close_for_project_change()
	super._close_tool_windows_for_project_change()


func test_chat_capabilities_v0192() -> Dictionary:
	if _test_chat_window_v0192 == null:
		return {}
	return _test_chat_window_v0192.capabilities_v0192()
