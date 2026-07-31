extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_check_file("res://scripts/ui/workspace_v0145.gd", [
		"Author", "Project", "Character", "Tools", "Lorebook",
		"_on_lorebooks_saved", "character_book", "_install_grouped_navigation"
	], failures)
	_check_file("res://scripts/ui/lorebook_window_v0145.gd", [
		"Project Lorebook", "Character Lorebook", "Primary keys", "Secondary keys",
		"Constant", "Selective", "Case sensitive", "insertion_order", "priority",
		"lorebooks_saved"
	], failures)
	_check_file("res://scripts/main_v0145.gd", ["0.14.5", "workspace_v0145.gd"], failures)
	_check_file("res://scenes/main.tscn", ["main_v0145.gd"], failures)
	_check_file("res://roadmap.md", ["v0.14.5", "Lorebook", "grouped navigation"], failures)

	if failures.is_empty():
		print("v0.14.5 navigation/lorebook regression: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_file(path: String, needles: Array[String], failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing file: %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Could not open: %s" % path)
		return
	var text := file.get_as_text()
	for needle in needles:
		if text.find(needle) < 0:
			failures.append("%s is missing expected marker: %s" % [path, needle])
