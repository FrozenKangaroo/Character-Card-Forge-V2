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
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(
		scene_source.contains("res://scripts/main_v015"),
		"The active scene must remain on the v0.15 inherited app-shell line."
	)

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
