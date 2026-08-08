extends SceneTree

const PICKER_INDEX_SERVICE_V01538 = preload(
	"res://scripts/services/character_picker_index_service_v01538.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
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

	var index_rows := PICKER_INDEX_SERVICE_V01538.build_index(synthetic_projects)
	if not _require(index_rows.size() == 540, "Every synthetic character should receive one lightweight picker row."):
		return

	var unfiltered := PICKER_INDEX_SERVICE_V01538.filter_rows(index_rows, "", 250)
	if not _require(unfiltered.size() == 250, "The unfiltered picker must stay bounded even with hundreds of characters."):
		return

	var needle := PICKER_INDEX_SERVICE_V01538.filter_rows(index_rows, "Needle Star", 250)
	if not _require(needle.size() == 1, "A character beyond the initial 250 rows must still be directly searchable."):
		return
	if not _require(str(needle[0].get("character_id", "")) == "char-527", "Direct character search returned the wrong character ID."):
		return
	if not _require(str(needle[0].get("project_id", "")) == "project-175", "Direct character search returned the wrong project ID."):
		return

	var by_project := PICKER_INDEX_SERVICE_V01538.filter_rows(index_rows, "Archive Project 175", 250)
	if not _require(by_project.size() == 3, "Searching a project name should expose its characters."):
		return

	var by_role := PICKER_INDEX_SERVICE_V01538.filter_rows(index_rows, "navigator", 250)
	if not _require(by_role.size() == 1, "Character roles must participate in direct search."):
		return
	if not _require(str(by_role[0].get("character_name", "")) == "Needle Star", "Role search returned the wrong character."):
		return

	var by_tag := PICKER_INDEX_SERVICE_V01538.filter_rows(index_rows, "rare-tag", 250)
	if not _require(by_tag.size() == 1, "Character tags must participate in direct search."):
		return

	var by_series_and_folder := PICKER_INDEX_SERVICE_V01538.filter_rows(
		index_rows, "series-07 folder-04", 250
	)
	if not _require(not by_series_and_folder.is_empty(), "Series/folder terms should be combinable."):
		return
	for row in by_series_and_folder:
		if not _require(str(row.get("series_id", "")) == "series-07", "Combined search returned the wrong series."):
			return
		if not _require(str(row.get("folder", "")) == "folder-04", "Combined search returned the wrong folder."):
			return

	var by_collection := PICKER_INDEX_SERVICE_V01538.filter_rows(index_rows, "collection-03", 250)
	if not _require(not by_collection.is_empty(), "Collections must participate in direct search."):
		return

	if not _require(
		PICKER_INDEX_SERVICE_V01538.count_matches(index_rows, "") == 540,
		"The full lightweight index match count must remain available even when rendered results are capped."
	):
		return

	# Confirm that the active application remains layered on the v0.15.38 Image
	# Studio contract. Later compatible shells may inherit it through several
	# versioned shells, so follow the actual extends chain instead of requiring a
	# direct parent relationship.
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var active_main_path := _active_main_script_path(scene_source)
	if not _require(not active_main_path.is_empty(), "The current main scene must reference a versioned application shell."):
		return
	if not _require(
		_script_inherits_path(active_main_path, "res://scripts/main_v01538.gd", 12),
		"The current application shell must preserve the v0.15.38 Image Studio layer somewhere in its versioned inheritance chain."
	):
		return

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01538.gd")
	if not _require(main_source.contains("image_generation_window_v01538_indexed.gd"), "The v0.15.38 shell must install the indexed Image Studio leaf."):
		return
	var indexed_source := FileAccess.get_file_as_string("res://scripts/ui/image_generation_window_v01538_indexed.gd")
	if not _require(indexed_source.contains("character_picker_index_service_v01538.gd"), "The live Image Studio picker must delegate to the reusable index service."):
		return
	if not _require(indexed_source.contains("build_index(project_rows)"), "The live picker must use the shared index builder."):
		return
	if not _require(indexed_source.contains("filter_rows(rows, query, limit)"), "The live picker must use the shared filter implementation."):
		return
	var image_source := FileAccess.get_file_as_string("res://scripts/ui/image_generation_window_v01538.gd")
	if not _require(
		image_source.contains("extends \"res://scripts/ui/image_generation_window_v01531.gd\""),
		"The v0.15.38 Image Studio must preserve the v0.15.31 AI Jobs inspection/cancellation layer."
	):
		return
	if not _require(image_source.contains("_project_selector.visible = false"), "The unbounded Project dropdown must be hidden in the live controller."):
		return
	if not _require(image_source.contains("_character_selector.visible = false"), "The unbounded Character dropdown must be hidden in the live controller."):
		return
	if not _require(image_source.contains("ImageStudioCharacterPickerButtonV01538"), "The live controller must expose the searchable Character picker button."):
		return
	if not _require(image_source.contains("ImageStudioCharacterPickerDialogV01538"), "The live controller must build the searchable Character picker dialog."):
		return

	print("v0.15.38 Image Studio character picker regression passed")
	quit(0)


func _active_main_script_path(scene_source: String) -> String:
	var marker := "[ext_resource path=\""
	var start := scene_source.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var finish := scene_source.find("\"", start)
	if finish < 0:
		return ""
	return scene_source.substr(start, finish - start)


func _script_inherits_path(start_path: String, target_path: String, max_depth: int) -> bool:
	var current_path := start_path
	var visited: Dictionary = {}
	for _depth in range(max_depth + 1):
		if current_path == target_path:
			return true
		if current_path.is_empty() or visited.has(current_path):
			return false
		visited[current_path] = true
		var source := FileAccess.get_file_as_string(current_path)
		if source.is_empty():
			return false
		current_path = _extends_script_path(source)
	return false


func _extends_script_path(source: String) -> String:
	var marker := "extends \""
	var start := source.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var finish := source.find("\"", start)
	if finish < 0:
		return ""
	return source.substr(start, finish - start)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	print("v0.15.38 picker regression failure: %s" % message)
	quit(1)
	return false
