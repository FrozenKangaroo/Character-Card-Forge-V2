extends SceneTree


func _init() -> void:
	var project := CCFStorageService.new_project()
	var base_id := CCFStorageService.active_character_id(project)
	var base := CCFStorageService.get_character(project, base_id)
	var base_card: Dictionary = base.get("character", {}).duplicate(true)
	base_card["name"] = "Yui"
	base_card["personality"] = "Cheerful, loyal, affectionate."
	base_card["first_message"] = "Hey {{user}}, you're home!"
	base["character"] = base_card
	var base_metadata: Dictionary = base.get("metadata", {}).duplicate(true)
	base_metadata["name"] = "Yui"
	base["metadata"] = base_metadata
	CCFStorageService.update_character(project, base)

	var variant := CCFCharacterVariantServiceV01420.create_variant(base, "Yui — NTR Route")
	assert(not variant.is_empty(), "A linked variant should be created from a full character.")
	var variant_id := str(variant.get("character_id", ""))
	var characters: Array = project.get("characters", []).duplicate(true)
	characters.append(variant)
	project["characters"] = characters

	var resolved := CCFCharacterVariantServiceV01420.resolve_character(project, variant_id)
	assert(str(resolved.get("character", {}).get("personality", "")) == "Cheerful, loyal, affectionate.", "Variant should inherit base Personality.")
	var edited := resolved.duplicate(true)
	var edited_card: Dictionary = edited.get("character", {}).duplicate(true)
	edited_card["personality"] = "Cheerful in public, secretive and thrill-seeking in private."
	edited_card["first_message"] = "Yui freezes when {{user}} comes home early."
	edited["character"] = edited_card
	var update_result := CCFCharacterVariantServiceV01420.update_variant_from_resolved(project, variant_id, edited)
	assert(bool(update_result.get("ok", false)), "Editing a linked variant should store a diff.")
	var stored_variant := CCFStorageService.get_character(project, variant_id)
	var overrides: Dictionary = stored_variant.get("variant", {}).get("overrides", {})
	assert(overrides.has("character"), "Variant diff should contain changed Character Card fields.")
	assert(not overrides.get("character", {}).has("description"), "Unchanged inherited fields must not be copied into the diff.")

	var materialized := CCFCharacterVariantServiceV01420.materialize_variant(project, variant_id)
	assert(not materialized.has("variant"), "Materialised exports must not depend on linked-variant metadata.")
	assert(str(materialized.get("character", {}).get("personality", "")) == edited_card["personality"], "Materialisation must apply variant overrides.")
	assert(str(materialized.get("character", {}).get("description", "")) == str(base_card.get("description", "")), "Materialisation must retain inherited fields.")

	var export_project := CCFCharacterVariantServiceV01420.project_with_materialized_character(project, variant_id)
	var export_record := CCFStorageService.get_character(export_project, variant_id)
	assert(not CCFCharacterVariantServiceV01420.is_variant(export_record), "Export project must contain a full resolved character.")

	var graph_source := FileAccess.get_file_as_string("res://scripts/ui/relationship_graph_window_v01420.gd")
	for marker in ["{{user}}", "Auto Layout", "Save Layout", "layout_saved", "character_selected"]:
		assert(graph_source.contains(marker), "Relationship Graph is missing %s." % marker)
	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01420.gd")
	for marker in ["Relationship Graph…", "Create Character Version…", "Linked Variant", "Convert Linked Variant to Full Character", "project_with_materialized_character"]:
		assert(workspace_source.contains(marker), "v0.14.20 workspace is missing %s." % marker)
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01420.gd")
	assert(main_source.contains("main_v01419.gd"), "v0.14.20 must preserve v0.14.19 through inheritance.")
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var shell_21 := FileAccess.get_file_as_string("res://scripts/main_v01421.gd")
	var shell_22 := FileAccess.get_file_as_string("res://scripts/main_v01422.gd")
	var shell_15 := FileAccess.get_file_as_string("res://scripts/main_v015.gd")
	assert(
		scene.contains("main_v01420.gd")
		or (scene.contains("main_v01421.gd") and shell_21.contains("main_v01420.gd"))
		or (scene.contains("main_v01422.gd") and shell_22.contains("main_v01421.gd") and shell_21.contains("main_v01420.gd"))
		or (
			scene.contains("main_v015.gd")
			and shell_15.contains("main_v01422.gd")
			and shell_22.contains("main_v01421.gd")
			and shell_21.contains("main_v01420.gd")
		),
		"The active main shell must preserve v0.14.20 through direct use or inheritance."
	)
	print("v0.14.20 Relationship Graph and linked variant regression passed")
	quit(0)
