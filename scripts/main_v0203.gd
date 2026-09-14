extends "res://scripts/main_v0202.gd"

const HELP_CENTER_V0203 = preload(
	"res://scripts/ui/help_center_window_v0203.gd"
)
const BUILD_DISPLAY_VERSION_V0203 := "0.20.3"

var _help_center_v0203: CCFHelpCenterWindowV0203


func _ready() -> void:
	super._ready()
	_build_help_center_v0203()
	_install_help_navigation_v0203()
	_update_build_version_label_v0203()


func _build_help_center_v0203() -> void:
	_help_center_v0203 = HELP_CENTER_V0203.new()
	_help_center_v0203.visible = false
	_help_center_v0203.action_requested.connect(_run_quick_action_v0201)
	add_child(_help_center_v0203)
	_help_center_v0203.hide()


func _install_help_navigation_v0203() -> void:
	var support := find_child("SupportCenterButtonV0202", true, false) as Button
	if support == null or support.get_parent() == null:
		return
	var side := support.get_parent() as VBoxContainer
	if side == null:
		return
	var help := Button.new()
	help.name = "HelpCenterButtonV0203"
	help.text = "Help Center"
	help.alignment = HORIZONTAL_ALIGNMENT_LEFT
	help.custom_minimum_size.y = 44
	help.tooltip_text = "Search offline task guides for Character Card Forge."
	help.pressed.connect(_open_help_center_v0203)
	side.add_child(help)
	side.move_child(help, support.get_index())


func _run_quick_action_v0201(action_id: String) -> void:
	if action_id == "help_center":
		_open_help_center_v0203()
		return
	super._run_quick_action_v0201(action_id)


func _open_help_center_v0203(article_id := "") -> void:
	if _help_center_v0203 != null:
		_help_center_v0203.open_help_center(article_id)


func help_capabilities_v0203() -> Dictionary:
	return CCFHelpContentServiceV0203.capabilities()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0203
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0203() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0203
			node.tooltip_text = (
				"v0.20.3 adds a searchable offline Help Center with versioned, "
				+ "task-focused guides and direct routes to existing app tools."
			)
			return
