extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")

var _failed := false
var _isolation := TEST_USER_DATA_ISOLATION.activate("v02112-settings-data-loss-hotfix")
var _test_root := OS.get_temp_dir().path_join(
	"ccf-v02112-settings-hotfix-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_test_root)
	_test_direct_execution_barriers()
	_test_repository_persistence_audit_barrier()
	_test_format_9_migration_and_streaming_persistence()
	_test_atomic_save_and_backup()
	_test_backup_recovery()
	_test_both_invalid_are_preserved()
	_cleanup_test_root()
	if _failed:
		quit(1)
		return
	print("V02112_SETTINGS_DATA_LOSS_HOTFIX_OK")
	quit(0)


func _test_direct_execution_barriers() -> void:
	_require(
		bool(_isolation.get("ok", false)),
		"Persistence regressions must establish process-level user-data isolation."
	)
	if not bool(_isolation.get("runner_isolated", false)):
		_require(
			bool(_isolation.get("direct_isolated", false))
			and str(_isolation.get("path", "")).contains("ccf-regression-direct")
			and str(_isolation.get("path", "")) != str(
				_isolation.get("original_path", "")
			),
			"A directly launched persistence regression must relocate user:// before any service writes."
		)
	var streaming_test := FileAccess.get_file_as_string(
		"res://tools/test_v02112_global_ai_streaming.gd"
	)
	_require(
		streaming_test.contains("save_settings_to_path")
		and streaming_test.contains("_settings_test_path_v02112")
		and not streaming_test.contains(
			"CCFSettingsService.save_settings(settings)"
		),
		"The streaming test must use explicit disposable settings storage rather than the production wrapper."
	)
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_require(
		main_source.contains(
			"if str(ui.get(\"last_view\", \"\")) != view_id:"
		),
		"View navigation must save settings only when the persisted last_view actually changes."
	)


func _test_repository_persistence_audit_barrier() -> void:
	var tools := DirAccess.open("res://tools")
	_require(tools != null, "The regression tools directory must be readable.")
	if tools == null:
		return
	var persistence_markers := [
		"FileAccess.WRITE",
		".save_settings(",
		".save_project(",
		".save_template(",
		".save_sessions(",
		".save_generated_idea(",
		".save_source(",
		".save_profile(",
		".save_checklist_settings(",
		".save_view(",
		".upsert_global_preset(",
		".save_png("
	]
	for file_name in tools.get_files():
		if not file_name.begins_with("test_") or not file_name.ends_with(".gd"):
			continue
		if file_name == "test_user_data_isolation.gd":
			continue
		var source := FileAccess.get_file_as_string("res://tools/" + file_name)
		var writes_persistent_data := false
		for marker in persistence_markers:
			if source.contains(marker):
				writes_persistent_data = true
				break
		if not writes_persistent_data:
			continue
		_require(
			source.contains("test_user_data_isolation.gd"),
			"Persistence regression %s must activate intrinsic direct-run isolation."
			% file_name
		)


func _test_format_9_migration_and_streaming_persistence() -> void:
	var path := _test_root.path_join("migration.json")
	var legacy := _format_9_fixture()
	_write_text(path, JSON.stringify(legacy, "  "))
	var loaded_result := CCFSettingsService.load_settings_result_from_path(path)
	var loaded: Dictionary = loaded_result.get("data", {})
	var profiles: Array = loaded.get("api_profiles", [])
	var image_profiles: Array = loaded.get("image_profiles", [])
	var roles: Dictionary = loaded.get("provider_roles", {})
	var generation: Dictionary = loaded.get("generation", {})
	var ui: Dictionary = loaded.get("ui", {})
	_require(
		bool(loaded_result.get("ok", false))
		and int(loaded.get("format_version", 0)) == 10
		and profiles.size() == 3
		and image_profiles.size() == 2
		and str(loaded.get("active_api_profile_id", "")) == "primary-a"
		and str((profiles[0] as Dictionary).get("base_url", "")) == "https://primary.invalid/v1"
		and str((profiles[0] as Dictionary).get("api_key", "")) == "test-key-not-real"
		and int((profiles[0] as Dictionary).get("context_window_tokens", 0)) == 262144
		and int((profiles[0] as Dictionary).get("max_output_tokens", 0)) == 32768
		and int((profiles[0] as Dictionary).get("collaborator_reply_output_tokens", 0)) == 12000
		and str(roles.get("text_profile_id", "")) == "primary-a"
		and str(roles.get("text_fast_profile_id", "")) == "fast-b"
		and str(roles.get("text_deep_profile_id", "")) == "deep-c"
		and str(roles.get("text_fallback_profile_id", "")) == "fast-b"
		and str(roles.get("vision_profile_id", "")) == "deep-c"
		and str(roles.get("image_profile_id", "")) == "image-b"
		and bool(generation.get("text_fallback_enabled", false))
		and not bool(generation.get("stream_ai_responses", true))
		and bool(ui.get("getting_started_seen_v0201", false))
		and str(ui.get("last_view", "")) == "workspace"
		and str(ui.get("future_ui_field", "")) == "preserved"
		and str(loaded.get("future_top_level", "")) == "preserved",
		"Format 9 → 10 migration must add streaming=false without erasing profiles, routing, UI state, keys, limits or supported unknown fields."
	)

	(generation as Dictionary)["stream_ai_responses"] = true
	loaded["generation"] = generation
	var saved_true := CCFSettingsService.save_settings_to_path(loaded, path)
	var reloaded_true := CCFSettingsService.load_settings_from_path(path)
	_require(
		bool(saved_true.get("ok", false))
		and bool((reloaded_true.get("generation", {}) as Dictionary).get(
			"stream_ai_responses", false
		))
		and bool((reloaded_true.get("ui", {}) as Dictionary).get(
			"getting_started_seen_v0201", false
		)),
		"Streaming=true and Getting Started dismissal must survive isolated atomic save/reload."
	)
	var false_generation: Dictionary = reloaded_true.get("generation", {}).duplicate(true)
	false_generation["stream_ai_responses"] = false
	reloaded_true["generation"] = false_generation
	var saved_false := CCFSettingsService.save_settings_to_path(reloaded_true, path)
	var reloaded_false := CCFSettingsService.load_settings_from_path(path)
	_require(
		bool(saved_false.get("ok", false))
		and not bool((reloaded_false.get("generation", {}) as Dictionary).get(
			"stream_ai_responses", true
		))
		and (reloaded_false.get("api_profiles", []) as Array).size() == 3
		and str((reloaded_false.get("ui", {}) as Dictionary).get(
			"last_view", ""
		)) == "workspace",
		"Streaming=false must persist without reducing profiles or resetting UI state."
	)


func _test_atomic_save_and_backup() -> void:
	var path := _test_root.path_join("atomic.json")
	var first := _format_9_fixture()
	(first.get("ui", {}) as Dictionary)["last_view"] = "library"
	var first_save := CCFSettingsService.save_settings_to_path(first, path)
	var second := CCFSettingsService.load_settings_from_path(path)
	(second.get("ui", {}) as Dictionary)["last_view"] = "settings"
	var second_save := CCFSettingsService.save_settings_to_path(second, path)
	var primary := CCFSettingsService.load_settings_result_from_path(path)
	var backup := CCFSettingsService.load_settings_result_from_path(
		CCFSettingsService.settings_backup_path(path)
	)
	_require(
		bool(first_save.get("ok", false))
		and bool(second_save.get("ok", false))
		and bool(primary.get("ok", false))
		and bool(backup.get("ok", false))
		and str((primary.get("data", {}).get("ui", {}) as Dictionary).get(
			"last_view", ""
		)) == "settings"
		and str((backup.get("data", {}).get("ui", {}) as Dictionary).get(
			"last_view", ""
		)) == "library",
		"Atomic save must install valid JSON while retaining the previous valid file as .bak."
	)
	var primary_before := FileAccess.get_file_as_string(path)
	var missing_stage := _test_root.path_join("missing-stage.json")
	var failed_replace := CCFSettingsService._replace_staged_file(
		missing_stage, path
	)
	_require(
		not bool(failed_replace.get("ok", true))
		and FileAccess.get_file_as_string(path) == primary_before,
		"A replacement failure before installation must leave the prior valid settings byte-for-byte intact."
	)


func _test_backup_recovery() -> void:
	var path := _test_root.path_join("recover.json")
	var original := _format_9_fixture()
	(original.get("ui", {}) as Dictionary)["last_view"] = "series"
	CCFSettingsService.save_settings_to_path(original, path)
	var newer := CCFSettingsService.load_settings_from_path(path)
	(newer.get("ui", {}) as Dictionary)["last_view"] = "templates"
	CCFSettingsService.save_settings_to_path(newer, path)
	_write_text(path, "{broken primary")
	var corrupt_before := FileAccess.get_file_as_string(path)
	var recovered := CCFSettingsService.load_settings_result_from_path(path)
	_require(
		bool(recovered.get("ok", false))
		and bool(recovered.get("recovered_from_backup", false))
		and bool(recovered.get("recovery_needed", false))
		and str((recovered.get("data", {}).get("ui", {}) as Dictionary).get(
			"last_view", ""
		)) == "series"
		and FileAccess.get_file_as_string(path) == corrupt_before,
		"A corrupt primary must recover the last-known-good backup without destroying the corrupt evidence."
	)


func _test_both_invalid_are_preserved() -> void:
	var path := _test_root.path_join("both-invalid.json")
	var backup_path := CCFSettingsService.settings_backup_path(path)
	_write_text(path, "{invalid primary")
	_write_text(backup_path, "[invalid backup")
	var primary_before := FileAccess.get_file_as_string(path)
	var backup_before := FileAccess.get_file_as_string(backup_path)
	var loaded := CCFSettingsService.load_settings_result_from_path(path)
	var attempted_save := CCFSettingsService.save_settings_to_path(
		loaded.get("data", {}), path
	)
	_require(
		not bool(loaded.get("ok", true))
		and bool(loaded.get("degraded", false))
		and bool(loaded.get("recovery_needed", false))
		and not bool(attempted_save.get("ok", true))
		and bool(attempted_save.get("recovery_needed", false))
		and FileAccess.get_file_as_string(path) == primary_before
		and FileAccess.get_file_as_string(backup_path) == backup_before,
		"When primary and backup are invalid, defaults may run in memory but neither broken file may be silently overwritten."
	)


func _format_9_fixture() -> Dictionary:
	return {
		"format_version": 9,
		"active_api_profile_id": "primary-a",
		"provider_roles": {
			"text_profile_id": "primary-a",
			"text_fast_profile_id": "fast-b",
			"text_deep_profile_id": "deep-c",
			"text_fallback_profile_id": "fast-b",
			"vision_profile_id": "deep-c",
			"image_profile_id": "image-b"
		},
		"api_profiles": [
			{
				"id": "primary-a", "name": "Primary", "base_url": "https://primary.invalid/v1",
				"api_key": "test-key-not-real", "model": "primary-model", "temperature": 0.4,
				"max_output_tokens": 32768, "collaborator_reply_output_tokens": 12000,
				"context_window_tokens": 262144, "vision_model": "vision-model",
				"vision_context_window_tokens": 131072, "vision_max_output_tokens": 8192
			},
			{
				"id": "fast-b", "name": "Fast", "base_url": "https://fast.invalid/v1",
				"api_key": "test-key-fast-not-real", "model": "fast-model", "temperature": 0.2,
				"max_output_tokens": 4096
			},
			{
				"id": "deep-c", "name": "Deep", "base_url": "https://deep.invalid/v1",
				"api_key": "test-key-deep-not-real", "model": "deep-model", "temperature": 0.7,
				"max_output_tokens": 65536
			}
		],
		"image_profiles": [
			{
				"id": "image-a", "name": "Image A", "base_url": "https://image-a.invalid/v1",
				"api_key": "test-key-image-a-not-real", "model": "image-a", "image_backend": "openai_compatible"
			},
			{
				"id": "image-b", "name": "Image B", "base_url": "http://127.0.0.1:7860",
				"api_key": "", "model": "checkpoint-b", "image_backend": "automatic1111",
				"image_settings": {"sampler": "Euler a", "steps": 24, "cfg_scale": 6.5, "seed": 42, "batch_size": 2}
			}
		],
		"generation": {
			"include_existing_fields": false,
			"retry_count": 3,
			"default_idea_count": 9,
			"attachment_context_character_limit": 64000,
			"text_fallback_enabled": true,
			"default_image_size": "832x1216",
			"default_image_prompt_style": "natural",
			"future_generation_field": "preserved"
		},
		"library_storage": {
			"mode": "local", "portable_root": "", "writer_id": "writer-test",
			"thumbnail_cache_max_mb": 768, "thumbnail_cache_max_age_days": 120,
			"virtualization_buffer_rows": 4
		},
		"ui": {
			"last_view": "workspace",
			"getting_started_seen_v0201": true,
			"future_ui_field": "preserved"
		},
		"future_top_level": "preserved"
	}


func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	_require(file != null, "The isolated test fixture must be writable.")
	if file == null:
		return
	file.store_string(text)
	file.close()


func _cleanup_test_root() -> void:
	_remove_tree(_test_root)


func _remove_tree(path: String) -> void:
	if not path.begins_with(OS.get_temp_dir()) or not DirAccess.dir_exists_absolute(path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := path.path_join(entry)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
