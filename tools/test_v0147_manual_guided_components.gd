extends SceneTree

const MANUAL = preload("res://scripts/ui/manual_guided_window_v0147.gd")


func _init() -> void:
	var manual := MANUAL.new()
	var template := CCFTemplateService.load_template("default")
	assert(not template.is_empty(), "Default template must load for Manual Guided regression.")
	manual._template = template.duplicate(true)
	manual._project = {
		"project_id": "project-a",
		"character_id": "character-a",
		"character": {"name": "A", "description": "", "personality": ""},
		"metadata": {}
	}
	manual._state = {
		"project_id": "project-a",
		"character_id": "character-a",
		"sections": {},
		"component_groups": {
			"description_structure": {
				"include": true,
				"components": {
					"age": "22",
					"appearance": "Black hair and green eyes.",
					"outfit_style": "Casual streetwear.",
					"distinguishing_features": "Star-shaped hair clip."
				}
			},
			"personality_structure": {
				"include": true,
				"components": {
					"mind": "Confident but thoughtful.",
					"moral_alignment": "Pragmatic good.",
					"speech_style": "Playful and direct."
				}
			}
		}
	}
	var outputs := manual._compose_component_outputs()
	assert(outputs.has("character.description"), "Description generation components must compose into Description.")
	assert(str(outputs["character.description"]).contains("Age: 22"), "Description component labels/values must be preserved.")
	assert(outputs.has("character.personality"), "Personality generation components must compose into Personality.")
	assert(str(outputs["character.personality"]).contains("Mind: Confident but thoughtful."), "Personality Mind must be exposed/composed.")
	assert(str(outputs["character.personality"]).contains("Moral Alignment: Pragmatic good."), "Optional enabled Personality components must be exposed/composed.")

	var edited := template.duplicate(true)
	for raw_group in edited.get("generation_groups", []):
		if raw_group is Dictionary and str(raw_group.get("id", "")) == "personality_structure":
			for raw_component in raw_group.get("components", []):
				if raw_component is Dictionary and str(raw_component.get("id", "")) == "loyalty":
					raw_component["enabled"] = false
			raw_group["components"].append({
				"id": "jealousy_style",
				"label": "Jealousy Style",
				"enabled": true,
				"required": false,
				"instruction": "How jealousy is expressed, if relevant."
			})
	manual._template = edited
	manual._state["component_groups"]["personality_structure"]["components"]["loyalty"] = "Old loyalty value"
	manual._ensure_state_from_project()
	var personality_state: Dictionary = manual._state["component_groups"]["personality_structure"]["components"]
	assert(personality_state.has("jealousy_style"), "New template components must appear automatically in Manual Guided state.")
	assert(str(personality_state["jealousy_style"]).is_empty(), "New components should initialise cleanly.")
	assert(not personality_state.has("loyalty"), "Disabled/removed template components must disappear from Manual Guided state.")

	var concept_field := {"id": "concept", "path": "concept.prompt"}
	assert(not manual._manual_field_allowed({"kind": "standard"}, concept_field), "Generation Concept must never appear in Manual Guided.")
	assert(not manual._manual_section_allowed({"kind": "interview"}), "Private Interview/Q&A sections must never appear in Manual Guided.")

	var source := FileAccess.get_file_as_string("res://scripts/ui/manual_guided_window_v0147.gd")
	assert(source.contains("_controls.clear()"), "Opening another character must clear the previous character's live controls before state replacement.")
	assert(source.contains("project_id"), "Manual Guided draft state must carry project identity.")
	assert(source.contains("character_id"), "Manual Guided draft state must carry character identity.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0147.gd")
	assert(main_source.contains("0.14.7"), "v0.14.7 development label is missing.")
	assert(FileAccess.file_exists("res://scripts/ui/workspace_v0147.gd"), "v0.14.7 workspace layer must remain available to newer shells.")

	manual.free()
	print("v0.14.7 Manual Guided component/state regression passed")
	quit(0)
