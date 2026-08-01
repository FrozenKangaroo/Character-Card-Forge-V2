class_name CCFWorkspaceV01419View
extends "res://scripts/ui/workspace_v01418.gd"


func _ready() -> void:
	super._ready()
	# v0.14.12 embeds the original AI Ideas controls while their callbacks still
	# belong to the hidden legacy controller Window. Whenever the workspace
	# upgrades its generation service, refresh that controller too so Generate
	# Ideas cannot keep calling a stale pre-v0.14.18 service instance.
	call_deferred("_wire_ai_idea_controller_to_current_service")


func _install_generation_service_v01418() -> void:
	super._install_generation_service_v01418()
	call_deferred("_wire_ai_idea_controller_to_current_service")


func _finish_opening_unified_idea_generator() -> void:
	# Rebind immediately before every open as well. This covers project reloads,
	# service replacement, and an already-embedded legacy controller.
	_wire_ai_idea_controller_to_current_service()
	super._finish_opening_unified_idea_generator()
	_wire_ai_idea_controller_to_current_service()


func _wire_ai_idea_controller_to_current_service() -> void:
	if _generation_service == null:
		return
	var legacy_window := _find_legacy_ai_idea_window()
	if legacy_window == null:
		return
	if legacy_window.has_method("set_generation_service"):
		legacy_window.call("set_generation_service", _generation_service)
		return
	# Older AI Ideas controllers exposed the service as a script property rather
	# than a setter. Detect it explicitly instead of blindly calling Object.set().
	for property_info in legacy_window.get_property_list():
		if not property_info is Dictionary:
			continue
		var property_name := str(property_info.get("name", ""))
		if property_name == "_generation_service" or property_name == "generation_service":
			legacy_window.set(property_name, _generation_service)
			return
