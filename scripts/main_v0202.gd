extends "res://scripts/main_v0201.gd"

const SUPPORT_CENTER_V0202 = preload(
	"res://scripts/ui/support_center_window_v0202.gd"
)
const BUILD_DISPLAY_VERSION_V0202 := "0.20.2"

var _support_center_v0202: CCFSupportCenterWindowV0202


func _ready() -> void:
	super._ready()
	_build_support_center_v0202()
	_install_support_navigation_v0202()
	_update_build_version_label_v0202()


func _build_support_center_v0202() -> void:
	_support_center_v0202 = SUPPORT_CENTER_V0202.new()
	_support_center_v0202.visible = false
	add_child(_support_center_v0202)
	_support_center_v0202.hide()


func _install_support_navigation_v0202() -> void:
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


func _run_quick_action_v0201(action_id: String) -> void:
	if action_id == "support_diagnostics":
		_open_support_center_v0202()
		return
	super._run_quick_action_v0201(action_id)


func _open_support_center_v0202() -> void:
	if _support_center_v0202 != null:
		_support_center_v0202.open_support_center(
			_settings, BUILD_DISPLAY_VERSION_V0202
		)


func support_capabilities_v0202() -> Dictionary:
	return CCFSupportReportServiceV0202.capabilities()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0202
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0202() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0202
			node.tooltip_text = (
				"v0.20.2 adds a privacy-safe Support & Diagnostics center for "
				+ "the public bake period, with explicit copy, export and issue handoff."
			)
			return
