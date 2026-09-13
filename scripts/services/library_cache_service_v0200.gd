class_name CCFLibraryCacheServiceV0200
extends RefCounted

const FORMAT_VERSION := 1
const CACHE_ROOT := CCFStorageService.CACHE_DIR + "/library_thumbnails"
const MANIFEST_FILE := CACHE_ROOT + "/cache_manifest_v0200.json"
const ALLOWED_EXTENSIONS := ["png", "webp"]

static var _pending_accesses_v0200: Dictionary = {}


static func thumbnail_for_density_v0200(row: Dictionary, density: int) -> String:
	var source_path := str(row.get("portrait_source_path", "")).strip_edges()
	if source_path.is_empty() or not FileAccess.file_exists(source_path):
		return ""
	var project_id := _safe_project_id_v0200(
		"%s_%s" % [
			str(row.get("library_cache_key_v0200", "local")),
			str(row.get("project_id", ""))
		]
	)
	if project_id.is_empty():
		return ""
	var base_path := str(row.get("thumbnail_path", "")).strip_edges()
	if base_path.is_empty() or not FileAccess.file_exists(base_path):
		base_path = _create_base_thumbnail_v0200(row, source_path)
	if base_path.is_empty():
		return ""
	if density >= 2:
		mark_accessed_v0200(base_path)
		return base_path
	var dimensions := Vector2i(144, 180) if density <= 0 else Vector2i(192, 240)
	var variant_path := CACHE_ROOT.path_join(
		"%s_%dx%d.webp" % [project_id, dimensions.x, dimensions.y]
	)
	var source_time := FileAccess.get_modified_time(base_path)
	if (
		FileAccess.file_exists(variant_path)
		and FileAccess.get_modified_time(variant_path) >= source_time
	):
		mark_accessed_v0200(variant_path)
		return variant_path
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(base_path)) != OK or image.is_empty():
		return base_path
	var scale_factor := minf(
		float(dimensions.x) / float(maxi(1, image.get_width())),
		float(dimensions.y) / float(maxi(1, image.get_height()))
	)
	if scale_factor < 1.0:
		image.resize(
			maxi(1, roundi(float(image.get_width()) * scale_factor)),
			maxi(1, roundi(float(image.get_height()) * scale_factor)),
			Image.INTERPOLATE_LANCZOS
		)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_ROOT))
	var save_error := image.save_webp(
		ProjectSettings.globalize_path(variant_path), true, 0.82
	)
	if save_error != OK:
		return base_path
	mark_accessed_v0200(variant_path)
	return variant_path


static func _create_base_thumbnail_v0200(
	row: Dictionary, source_path: String
) -> String:
	var library_key := _safe_project_id_v0200(
		str(row.get("library_cache_key_v0200", "local"))
	)
	var raw_project_id := _safe_project_id_v0200(str(row.get("project_id", "")))
	if library_key.is_empty() or raw_project_id.is_empty():
		return ""
	var base_path := CACHE_ROOT.path_join(
		"%s_%s.png" % [library_key, raw_project_id]
	)
	if (
		FileAccess.file_exists(base_path)
		and FileAccess.get_modified_time(base_path) >= FileAccess.get_modified_time(source_path)
	):
		return base_path
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(source_path)) != OK or image.is_empty():
		return ""
	var scale_factor := minf(
		320.0 / float(maxi(1, image.get_width())),
		400.0 / float(maxi(1, image.get_height()))
	)
	if scale_factor < 1.0:
		image.resize(
			maxi(1, roundi(float(image.get_width()) * scale_factor)),
			maxi(1, roundi(float(image.get_height()) * scale_factor)),
			Image.INTERPOLATE_LANCZOS
		)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_ROOT))
	if image.save_png(ProjectSettings.globalize_path(base_path)) != OK:
		return ""
	mark_accessed_v0200(base_path)
	return base_path


static func mark_accessed_v0200(path: String) -> void:
	if not _is_safe_cache_file_v0200(path):
		return
	_pending_accesses_v0200[path.get_file()] = {
		"last_accessed_unix": int(Time.get_unix_time_from_system()),
		"size_bytes": FileAccess.get_size(path),
		"extension": path.get_extension().to_lower()
	}


static func flush_accesses_v0200() -> void:
	if _pending_accesses_v0200.is_empty():
		return
	var manifest := _load_manifest_v0200()
	var entries: Dictionary = manifest.get("entries", {})
	for filename in _pending_accesses_v0200:
		entries[filename] = _pending_accesses_v0200[filename]
	manifest["entries"] = entries
	_save_manifest_v0200(manifest)
	_pending_accesses_v0200.clear()


static func maintain_v0200(settings: Dictionary) -> Dictionary:
	flush_accesses_v0200()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_ROOT))
	var storage_value: Variant = settings.get("library_storage", {})
	var storage: Dictionary = storage_value if storage_value is Dictionary else {}
	var max_bytes := clampi(
		int(storage.get("thumbnail_cache_max_mb", 512)), 64, 4096
	) * 1024 * 1024
	var max_age_seconds := clampi(
		int(storage.get("thumbnail_cache_max_age_days", 90)), 7, 3650
	) * 24 * 60 * 60
	var now := int(Time.get_unix_time_from_system())
	var manifest := _load_manifest_v0200()
	var prior_entries: Dictionary = manifest.get("entries", {})
	var candidates: Array[Dictionary] = []
	var removed := 0
	var removed_bytes := 0
	for filename in DirAccess.get_files_at(CACHE_ROOT):
		var path := CACHE_ROOT.path_join(filename)
		if not _is_safe_cache_file_v0200(path):
			continue
		var prior_value: Variant = prior_entries.get(filename, {})
		var prior: Dictionary = prior_value if prior_value is Dictionary else {}
		var accessed := int(
			prior.get("last_accessed_unix", FileAccess.get_modified_time(path))
		)
		var size_bytes := maxi(0, FileAccess.get_size(path))
		if accessed > 0 and now - accessed > max_age_seconds:
			if DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK:
				removed += 1
				removed_bytes += size_bytes
			continue
		candidates.append(
			{
				"filename": filename,
				"path": path,
				"last_accessed_unix": accessed,
				"size_bytes": size_bytes
			}
		)
	var total_bytes := 0
	for candidate in candidates:
		total_bytes += int(candidate.get("size_bytes", 0))
	candidates.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return int(first.get("last_accessed_unix", 0)) < int(
				second.get("last_accessed_unix", 0)
			)
	)
	while total_bytes > max_bytes and not candidates.is_empty():
		var oldest: Dictionary = candidates.pop_front()
		var oldest_size := int(oldest.get("size_bytes", 0))
		if DirAccess.remove_absolute(
			ProjectSettings.globalize_path(str(oldest.get("path", "")))
		) == OK:
			total_bytes -= oldest_size
			removed += 1
			removed_bytes += oldest_size
	var next_entries: Dictionary = {}
	for candidate in candidates:
		next_entries[str(candidate.get("filename", ""))] = {
			"last_accessed_unix": int(candidate.get("last_accessed_unix", now)),
			"size_bytes": int(candidate.get("size_bytes", 0)),
			"extension": str(candidate.get("path", "")).get_extension().to_lower()
		}
	_save_manifest_v0200(
		{
			"format_version": FORMAT_VERSION,
			"updated_at": Time.get_datetime_string_from_system(true),
			"max_bytes": max_bytes,
			"max_age_seconds": max_age_seconds,
			"entries": next_entries
		}
	)
	return {
		"ok": true,
		"entries": next_entries.size(),
		"bytes": total_bytes,
		"removed": removed,
		"removed_bytes": removed_bytes,
		"local_only": true,
		"originals_preserved": true
	}


static func clear_v0200() -> Dictionary:
	if not _cache_root_is_safe_v0200():
		return {"ok": false, "error": "The thumbnail cache path failed its safety check."}
	var removed := 0
	var removed_bytes := 0
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(CACHE_ROOT)):
		for filename in DirAccess.get_files_at(CACHE_ROOT):
			var path := CACHE_ROOT.path_join(filename)
			if path == MANIFEST_FILE or _is_safe_cache_file_v0200(path):
				removed_bytes += maxi(0, FileAccess.get_size(path))
				if DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK:
					removed += 1
	return {
		"ok": true,
		"removed": removed,
		"removed_bytes": removed_bytes,
		"originals_preserved": true
	}


static func _cache_root_is_safe_v0200() -> bool:
	return (
		CACHE_ROOT.begins_with(CCFStorageService.CACHE_DIR + "/")
		and CACHE_ROOT != CCFStorageService.CACHE_DIR
	)


static func _is_safe_cache_file_v0200(path: String) -> bool:
	return (
		_cache_root_is_safe_v0200()
		and path.get_base_dir() == CACHE_ROOT
		and path.get_extension().to_lower() in ALLOWED_EXTENSIONS
	)


static func _load_manifest_v0200() -> Dictionary:
	var defaults := {"format_version": FORMAT_VERSION, "entries": {}}
	if not FileAccess.file_exists(MANIFEST_FILE):
		return defaults
	var file := FileAccess.open(MANIFEST_FILE, FileAccess.READ)
	if file == null:
		return defaults
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("format_version", 0)) != FORMAT_VERSION:
		return defaults
	if not parsed.get("entries", {}) is Dictionary:
		parsed["entries"] = {}
	return parsed


static func _save_manifest_v0200(manifest: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_ROOT))
	var file := FileAccess.open(MANIFEST_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(manifest, "  "))
	file.close()


static func _safe_project_id_v0200(value: String) -> String:
	var result := ""
	for character_index in range(value.length()):
		var character := value.substr(character_index, 1).to_lower()
		if "abcdefghijklmnopqrstuvwxyz0123456789-_".contains(character):
			result += character
	return result.left(96)
