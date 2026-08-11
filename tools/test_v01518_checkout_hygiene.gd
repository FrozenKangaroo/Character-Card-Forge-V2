extends SceneTree


func _init() -> void:
	var gitignore_source := FileAccess.get_file_as_string("res://.gitignore")
	assert(
		gitignore_source.contains("*.gd.uid"),
		"Generated GDScript UID sidecars must be ignored until a canonical UID migration is deliberately performed."
	)

	var project_source := FileAccess.get_file_as_string("res://project.godot")
	assert(
		not project_source.contains('window/stretch/mode="disabled"'),
		"project.godot should use Godot 4.6 canonical serialization instead of repeatedly restoring the default disabled stretch line."
	)
	assert(
		str(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "disabled",
		"Omitting the redundant serialized stretch setting must still resolve to disabled at runtime."
	)

	var workspace_source := FileAccess.get_file_as_string(
		"res://scripts/ui/workspace_v01517.gd"
	)
	assert(
		not workspace_source.contains("\tvar name := str(lorebook.get("),
		"v0.15.17 Lorebook normalisation must not shadow Node.name."
	)
	assert(
		workspace_source.contains("\tvar book_name := str(lorebook.get("),
		"v0.15.17 Lorebook normalisation should use the warning-safe book_name local."
	)

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01518.gd")
	assert(
		main_source.contains('BUILD_DISPLAY_VERSION_V01518 := "0.15.18"'),
		"The v0.15.18 shell must expose its build version."
	)
	if not _active_main_shell_inherits("res://scripts/main_v01518.gd"):
		push_error("The active main-shell inheritance chain no longer retains the v0.15.18 checkout-hygiene layer.")
		quit(1)
		return

	var update_source := FileAccess.get_file_as_string("res://update.sh")
	assert(
		update_source.contains("git status --porcelain --untracked-files=normal"),
		"update.sh must continue protecting meaningful local changes; ignored UID sidecars are filtered by Git itself."
	)
	var release_source := FileAccess.get_file_as_string("res://release.sh")
	assert(
		release_source.contains("git -C \"${repo_dir}\" ls-files --others --exclude-standard -z"),
		"release.sh must continue using standard Git excludes when checking untracked files."
	)

	print("v0.15.18 checkout hygiene and warning cleanup regression passed")
	quit(0)


func _active_main_shell_inherits(target_script: String) -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var scene_regex := RegEx.new()
	if scene_regex.compile('\\[ext_resource path="(res://scripts/main[^\"]*\\.gd)" type="Script" id="1_main"\\]') != OK:
		return false
	var scene_match := scene_regex.search(scene_source)
	if scene_match == null:
		return false
	var extends_regex := RegEx.new()
	if extends_regex.compile('(?m)^extends\\s+"(res://[^\"]+\\.gd)"\\s*$') != OK:
		return false
	var current := scene_match.get_string(1)
	var visited: Dictionary = {}
	for _index in range(64):
		if current == target_script:
			return true
		if visited.has(current) or not FileAccess.file_exists(current):
			return false
		visited[current] = true
		var source_text := FileAccess.get_file_as_string(current)
		var extends_match := extends_regex.search(source_text)
		if extends_match == null:
			return false
		current = extends_match.get_string(1)
	return false
