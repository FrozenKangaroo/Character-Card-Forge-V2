class_name CCFCharacterCollaboratorWindowV01537
extends "res://scripts/ui/character_collaborator_window_v01535.gd"

const SOURCE_SERVICE_V01537 = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)

var _suppress_legacy_source_v01537 := false
var _multi_source_list_v01537: VBoxContainer
var _paste_source_dialog_v01537: ConfirmationDialog
var _paste_source_label_v01537: LineEdit
var _paste_source_text_v01537: TextEdit


func _ready() -> void:
	super._ready()
	_install_multi_source_controls_v01537()
	_build_paste_source_dialog_v01537()
	_refresh_source_panel_v01533()
