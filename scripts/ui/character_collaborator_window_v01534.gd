class_name CCFCharacterCollaboratorWindowV01534
extends "res://scripts/ui/character_collaborator_window_v01533.gd"


func _refresh_source_panel_v01533() -> void:
	super._refresh_source_panel_v01533()
	if _source_note_v01533 == null:
		return
	var source := active_source_context_v01533()
	if source.is_empty() or str(source.get("source_type", "")) != "character":
		return
	var provenance_value: Variant = source.get("provenance", {})
	if not provenance_value is Dictionary:
		return
	var derivation_value: Variant = (provenance_value as Dictionary).get("derivation", {})
	if not derivation_value is Dictionary:
		return
	var derivation: Dictionary = derivation_value as Dictionary
	var intent_label := str(derivation.get("intent_label", "")).strip_edges()
	if intent_label.is_empty():
		return
	_source_note_v01533.text = (
		"Starting direction: %s • Read-only source • established facts stay authoritative unless you explicitly ask to change or branch them."
	) % intent_label


func existing_character_source_capabilities_v01534() -> Dictionary:
	return {
		"version": "0.15.34",
		"visible_author_intent": true,
		"read_only_source": true,
		"source_persists_with_session": true,
		"automatic_source_replacement": false
	}
