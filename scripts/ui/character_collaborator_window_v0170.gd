class_name CCFCharacterCollaboratorWindowV0170
extends "res://scripts/ui/character_collaborator_window_v0160.gd"

const IMAGE_SOURCE_SERVICE_V0170 = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)


func open_with_source_v01533(
	project: Dictionary,
	settings: Dictionary,
	character_id: String,
	template: Dictionary,
	source: Dictionary
) -> Dictionary:
	var clean := IMAGE_SOURCE_SERVICE_V0170.upgrade_source(source)
	if clean.is_empty():
		return {"ok": false, "error": "The Collaborator source context is invalid."}
	open_for_project(project, settings, character_id, template)
	return start_source_session_v01533(clean)


func image_source_capabilities_v0170() -> Dictionary:
	return {
		"version": "0.17.0",
		"image_studio_result_source": true,
		"legacy_structured_sources_preserved": true
	}
