extends "res://scripts/main_v0159.gd"

const FILE_DIALOG_STATE_SERVICE_V01510 = preload("res://scripts/services/file_dialog_state_service_v01510.gd")
const BUILD_DISPLAY_VERSION_V01510 := "0.15.10"

var _file_dialog_state_service_v01510: CCFFileDialogStateServiceV01510


func _ready() -> void:
	super._ready()
	_install_file_dialog_state_service_v01510()


func _install_file_dialog_state_service_v01510() -> void:
	if _file_dialog_state_service_v01510 != null and is_instance_valid(_file_dialog_state_service_v01510):
		return
	_file_dialog_state_service_v01510 = FILE_DIALOG_STATE_SERVICE_V01510.new()
	_file_dialog_state_service_v01510.name = "FileDialogStateServiceV01510"
	add_child(_file_dialog_state_service_v01510)


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01510
			node.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return
