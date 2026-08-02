extends SceneTree


func _init() -> void:
	var release_source := FileAccess.get_file_as_string("res://release.sh")
	assert(
		release_source.contains("resolve_repository_input"),
		"release.sh must resolve its repository target deliberately."
	)
	assert(
		release_source.contains('if [[ -n "${CCF_REPO_DIR:-}" ]]'),
		"An explicit CCF_REPO_DIR override must retain highest precedence."
	)
	assert(
		release_source.contains('git -C "${SOURCE_DIR}" rev-parse --show-toplevel'),
		"release.sh must detect when its own directory is already a Git checkout."
	)
	assert(
		release_source.contains('if [[ "${source_root}" == "${SOURCE_DIR}" ]]'),
		"Only the repository root containing release.sh should be auto-selected."
	)
	assert(
		release_source.contains('print_status "Using current repository checkout"'),
		"Direct releases from the current checkout should be visible instead of silently routing through a second clone."
	)
	assert(
		release_source.contains('chmod +x "${repo_dir}/release.sh" "${repo_dir}/update.sh"'),
		"Development-copy sync must restore executable bits for both helper scripts."
	)

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01519.gd")
	assert(
		main_source.contains('extends "res://scripts/main_v01518.gd"'),
		"v0.15.19 must preserve the v0.15.18 app-shell lineage."
	)
	assert(
		main_source.contains('BUILD_DISPLAY_VERSION_V01519 := "0.15.19"'),
		"The v0.15.19 shell must expose its build version."
	)
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(
		scene_source.contains("main_v01519.gd"),
		"The active scene must use the v0.15.19 shell."
	)

	print("v0.15.19 release checkout selection regression passed")
	quit(0)
