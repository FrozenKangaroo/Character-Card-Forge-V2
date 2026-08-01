extends SceneTree

const WORKSPACE = preload("res://scripts/ui/workspace_v01410.gd")


func _init() -> void:
	var workspace := WORKSPACE.new()
	workspace._active_character_id = "source-a"
	workspace._project_container = {
		"project_id": "project-a",
		"shared_context": {
			"premise": "Two sisters navigate university life.",
			"setting": "Melbourne"
		},
		"relationships": [
			{
				"character_a_id": "source-a",
				"character_b_id": "friend-b",
				"label": "best friends"
			}
		]
	}
	var source := {
		"character_id": "source-a",
		"metadata": {"name": "Rina"},
		"concept": {"prompt": "A confident university student."},
		"character": {
			"name": "Rina",
			"description": "Black hair and green eyes.",
			"personality": "Playful, direct, and loyal.",
			"scenario": "University life."
		}
	}

	var related := workspace._build_derivation_concept(source, {
		"mode": "related",
		"instruction": "Create her older sister Mika.",
		"include_source_card": true,
		"include_shared_context": true,
		"include_relationships": true
	})
	assert(related.contains("DERIVATION TASK: RELATED CHARACTER"), "Related-character mode marker is missing.")
	assert(related.contains("Create her older sister Mika."), "User derivation instruction must be authoritative context.")
	assert(related.contains("Black hair and green eyes."), "Source Character Card context must be available when enabled.")
	assert(related.contains("Two sisters navigate university life."), "Shared project context must be available when enabled.")
	assert(related.contains("best friends"), "Established source relationships must be available when enabled.")

	var variation := workspace._build_derivation_concept(source, {
		"mode": "variation",
		"instruction": "Create a 35-year-old version ten years later.",
		"include_source_card": true,
		"include_shared_context": false,
		"include_relationships": false
	})
	assert(variation.contains("DERIVATION TASK: AI VARIATION"), "Variation mode marker is missing.")
	assert(variation.contains("Preserve established identity anchors"), "Variation guidance must preserve identity anchors unless transformed.")
	assert(not variation.contains("Two sisters navigate university life."), "Disabled shared context must not be injected.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01410.gd")
	assert(workspace_source.contains("Create Related Character / AI Variation"), "Character menu must expose derivation workflow.")
	assert(workspace_source.contains("source_character_id"), "Derivation provenance must retain source character identity.")
	assert(workspace_source.contains("derivation_type"), "Derivation provenance must retain related/variation type.")
	assert(workspace_source.contains("Generate Character"), "Auto-generate must route through the normal generation workflow.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01410.gd")
	assert(main_source.contains("0.14.10"), "v0.14.10 development layer is missing.")
	var current_main_source := FileAccess.get_file_as_string("res://scripts/main_v01411.gd")
	if not current_main_source.is_empty():
		assert(current_main_source.contains("main_v01410.gd"), "Newer application shells must retain the v0.14.10 derivation layer.")

	workspace.free()
	print("v0.14.10 related character / AI variation regression passed")
	quit(0)
