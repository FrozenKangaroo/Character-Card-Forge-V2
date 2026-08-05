class_name CCFCollaboratorCompletionDestinationWindowV01536
extends "res://scripts/ui/collaborator_completion_destination_window_v01535.gd"

const REFINEMENT_SERVICE_V01536 = preload(
	"res://scripts/services/collaborator_refinement_service_v01536.gd"
)


func _ready() -> void:
	super._ready()
	title = "Choose Collaborator Completion Destination"
	if _safety_note_v01535 != null:
		_safety_note_v01535.text = (
			"Occupied characters are still never overwritten automatically. Existing-character sources may use Compare & Apply, where you inspect and select changes before Update Original becomes available."
		)


func open_for_completion_v01536(
	current_character: Dictionary,
	template: Dictionary,
	project_name: String,
	current_character_name: String,
	source_context: Dictionary,
	source_target_available: bool
) -> void:
	super.open_for_completion_v01535(
		current_character,
		template,
		project_name,
		current_character_name
	)
	if (
		source_target_available
		and REFINEMENT_SERVICE_V01536.can_compare_source(source_context)
	):
		var option := {
			"id": REFINEMENT_SERVICE_V01536.DEST_COMPARE_APPLY,
			"label": "Compare & Apply to Source Character…",
			"description": "Compare the exact source snapshot used by Collaborator with the proposal, choose changes field-by-field, then either update the original (for refinement directions) or create an improved copy.",
			"recommended": false
		}
		_options_v01535.append(option)
		_destination_v01535.add_item(str(option.get("label", "Compare & Apply")))
		var index := _destination_v01535.item_count - 1
		_destination_v01535.set_item_metadata(
			index,
			REFINEMENT_SERVICE_V01536.DEST_COMPARE_APPLY
		)
	_refresh_description_v01535()


func compare_apply_available_v01536() -> bool:
	return destination_ids_v01535().has(
		REFINEMENT_SERVICE_V01536.DEST_COMPARE_APPLY
	)
