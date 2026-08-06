extends SceneTree

const IMAGE_WINDOW_V01538 = preload(
	"res://scripts/ui/image_generation_window_v01538.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# The index/filter helpers are deliberately pure. Do not attach a full Image
	# Studio Window to the SceneTree here: inherited Image Studio lifecycle work
	# includes provider/gallery state that belongs to its own regressions.
	var picker := IMAGE_WINDOW_V01538.new() as CCFImageGenerationWindowV01538
	var capabilities := picker.character_picker_capabilities_v01538()
	assert(bool(capabilities.get("searchable_character_picker", false)))
	assert(bool(capabilities.get("direct_character_selection", false)))
	assert(bool(capabilities.get("legacy_project_dropdown_hidden", false)))
	assert(int(capabilities.get("max_visible_results", 0)) == 250)

	var synthetic_projects: Array = []
	for project_index in range(180):
		var project_name := "Archive Project %03d" % project_index
		var characters: Array = []
		for character_index in range(3):
			var serial := project_index * 3 + character_index
			var character_name := "Character %03d" % serial
			var role_text := "support"
			var tags: Array[String] = ["general"]
			if serial == 527:
				character_name = "Needle Star"
				role_text = "navigator"
				tags = ["rare-tag", "space"]
			characters.append({
				"character_id": "char-%03d" % serial,
				"name": character_name,
				"summary": "Synthetic character %03d" % serial,
				"role": role_text,
				"tags": tags,
				"creator": "Regression",
				"character_version": "1"
			})
		synthetic_projects.append({
			"project_id": "project-%03d" % project_index,
			"name": project_name,
			"summary": "Synthetic project %03d" % project_index,
			"all_tags": ["project-tag-%03d" % project_index],
			"series_id": "series-%02d" % (project_index % 12),
			"folder": "folder-%02d" % (project_index % 9),
			"collections": ["collection-%02d" % (project_index % 7)],
			"updated_at": "2026-08-06T00:%02d:00Z" % (project_index % 60),
			"characters": characters
		})

	var index_rows := picker.build_character_picker_index_v01538(synthetic_projects)
	assert(index_rows.size() == 540, "Every synthetic character should receive one lightweight picker row.")

	var unfiltered := picker.filter_character_picker_rows_v01538(index_rows, "", 250)
	assert(unfiltered.size() == 250, "The unfiltered picker must stay bounded even with hundreds of characters.")

	var needle := picker.filter_character_picker_rows_v01538(index_rows, "Needle Star", 250)
	assert(needle.size() == 1, "A character beyond the initial 250 rows must still be directly searchable.")
	assert(str(needle[0].get("character_id", "")) == "char-527")
	assert(str(needle[0].get("project_id", "")) == "project-175")

	var by_project := picker.filter_character_picker_rows_v01538(index_rows, "Archive Project 175", 250)
	assert(by_project.size() == 3, "Searching a project name should expose its characters.")

	var by_role := picker.filter_character_picker_rows_v01538(index_rows, "navigator", 250)
	assert(by_role.size() == 1, "Character roles must participate in direct search.")
	assert(str(by_role[0].get("character_name", "")) == "Needle Star")

	var by_tag := picker.filter_character_picker_rows_v01538(index_rows, "rare-tag", 250)
	assert(by_tag.size() == 1, "Character tags must participate in direct search.")

	var by_series_and_folder := picker.filter_character_picker_rows_v01538(
		index_rows, "series-07 folder-04", 250
	)
	assert(not by_series_and_folder.is_empty(), "Series/folder terms should be combinable.")
	for row in by_series_and_folder:
		assert(str(row.get("series_id", "")) == "series-07")
		assert(str(row.get("folder", "")) == "folder-04")

	var by_collection := picker.filter_character_picker_rows_v01538(
		index_rows, "collection-03", 250
	)
	assert(not by_collection.is_empty(), "Collections must participate in direct search.")
	picker.free()

	# Live wiring is asserted at source level here so this focused search test does
	# not spin up provider/image-window lifecycle work. v0.15.28-v0.15.30 keep the
	# real Image Studio runtime contracts covered in the same dedicated workflow.
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene_source.contains("res://scripts/main_v01538.gd"), "The current main scene must activate v0.15.38.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01538.gd")
	assert(main_source.contains("IMAGE_WINDOW_V01538"), "The v0.15.38 shell must preload the new Image Studio controller.")
	assert(main_source.contains("func _install_image_window_v01529()"), "The active shell must install the v0.15.38 Image Studio controller.")
	var image_source := FileAccess.get_file_as_string("res://scripts/ui/image_generation_window_v01538.gd")
	assert(image_source.contains("_project_selector.visible = false"), "The unbounded Project dropdown must be hidden in the live controller.")
	assert(image_source.contains("_character_selector.visible = false"), "The unbounded Character dropdown must be hidden in the live controller.")
	assert(image_source.contains("ImageStudioCharacterPickerButtonV01538"), "The live controller must expose the searchable Character picker button.")
	assert(image_source.contains("ImageStudioCharacterPickerDialogV01538"), "The live controller must build the searchable Character picker dialog.")

	print("v0.15.38 Image Studio character picker regression passed")
	quit(0)
