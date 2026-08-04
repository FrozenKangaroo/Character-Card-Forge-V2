class_name CCFWorkspaceV01533Hotfix1View
extends "res://scripts/ui/workspace_v01533.gd"

const IDEA_GENERATOR_V01533_HOTFIX1 = preload(
	"res://scripts/ui/idea_generator_window_v01533_hotfix1.gd"
)


func _build_concept_studio() -> void:
	_idea_generator_v01532 = IDEA_GENERATOR_V01533_HOTFIX1.new()
	_idea_generator_v01532.visible = false
	_idea_generator_v01532.concept_selected.connect(_on_structured_concept_selected)
	if _idea_generator_v01532.has_signal("collaborator_source_requested"):
		_idea_generator_v01532.connect(
			"collaborator_source_requested",
			Callable(self, "_on_collaborator_source_requested_v01533")
		)
	add_child(_idea_generator_v01532)
	_idea_generator_v01532.hide()
	_idea_generator_v01412 = _idea_generator_v01532
	_concept_studio = _idea_generator_v01532


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["structured_builder_handoff"] = true
	return result
