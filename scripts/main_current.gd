extends "res://scripts/main_v0201.gd"

# This is the first semantic current-runtime layer. Historical versioned shells remain
# available for regression and compatibility evidence, but new releases should update
# this layer instead of extending the active main-shell chain again.
const SUPPORT_CENTER_CURRENT = preload(
	"res://scripts/ui/support_center_window_v0202.gd"
)
const HELP_CENTER_CURRENT = preload(
	"res://scripts/ui/help_center_window_v0203.gd"
)
const CURRENT_BUILD_VERSION := "0.20.7"

var _support_center_v0202: CCFSupportCenterWindowV0202
var _help_center_v0203: CCFHelpCenterWindowV0203


func _ready() -> void:
	super._ready()
	_build_support_center_current()
	_install_support_navigation_current()
	_build_help_center_current()
	_install_help_navigation_current()
	_update_current_build_label()


func _build_support_center_current() -> void:
	_support_center_v0202 = SUPPORT_CENTER_CURRENT.new()
	_support_center_v0202.visible = false
	add_child(_support_center_v0202)
	_support_center_v0202.hide()


func _install_support_navigation_current() -> void:
	var guide := find_child("GettingStartedButtonV0201", true, false) as Button
	if guide == null or guide.get_parent() == null:
		return
	var side := guide.get_parent() as VBoxContainer
	if side == null:
		return
	var support := Button.new()
	support.name = "SupportCenterButtonV0202"
	support.text = "Support & Diagnostics"
	support.alignment = HORIZONTAL_ALIGNMENT_LEFT
	support.custom_minimum_size.y = 44
	support.tooltip_text = "Create a privacy-safe technical report for troubleshooting."
	support.pressed.connect(_open_support_center_v0202)
	side.add_child(support)
	side.move_child(support, guide.get_index() + 1)


func _build_help_center_current() -> void:
	_help_center_v0203 = HELP_CENTER_CURRENT.new()
	_help_center_v0203.visible = false
	_help_center_v0203.action_requested.connect(_run_quick_action_v0201)
	add_child(_help_center_v0203)
	_help_center_v0203.hide()


func _install_help_navigation_current() -> void:
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
	match action_id:
		"help_center":
			_open_help_center_v0203()
		"support_diagnostics":
			_open_support_center_v0202()
		_:
			super._run_quick_action_v0201(action_id)


func _open_support_center_v0202() -> void:
	if _support_center_v0202 != null:
		_support_center_v0202.open_support_center(
			_settings, CURRENT_BUILD_VERSION
		)


func _open_help_center_v0203(article_id := "") -> void:
	if _help_center_v0203 != null:
		_help_center_v0203.open_help_center(article_id)


func support_capabilities_v0202() -> Dictionary:
	return CCFSupportReportServiceV0202.capabilities()


func help_capabilities_v0203() -> Dictionary:
	return CCFHelpContentServiceV0203.capabilities()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return CURRENT_BUILD_VERSION
	return super._update_comparison_version_v0180_hotfix2()


func _update_current_build_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % CURRENT_BUILD_VERSION
			node.tooltip_text = (
				"v0.20.7 continues measured runtime consolidation by composing recent "
				+ "AI Review, Compact Derivative, Split Character Set and Text-routing "
				+ "behavior in one semantic current generation service."
			)
			return
