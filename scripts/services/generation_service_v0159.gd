class_name CCFGenerationServiceV0159
extends "res://scripts/services/generation_service_v0158.gd"

const AUTO_MAX_VISION_DIMENSION_V0159 := 4096
const AUTO_MAX_VISION_BYTES_V0159 := 8 * 1024 * 1024
const AUTO_VISION_WEBP_QUALITY_V0159 := 0.90


func queue_collaborator_vision_summary(
	image_path: String,
	profile: Dictionary,
	retry_count: int,
	session_id: String
) -> Dictionary:
	var vision_model := str(profile.get("vision_model", "")).strip_edges()
	if vision_model.is_empty():
		return {
			"ok": false,
			"error": "The selected Vision profile does not have a Vision model configured. Set Vision model in Settings before attaching images to Character Collaborator."
		}

	var vision_context := maxi(0, int(profile.get("vision_context_window_tokens", 0)))
	var vision_output := maxi(128, int(profile.get("vision_max_output_tokens", 4096)))
	if vision_context > 0 and vision_output >= vision_context:
		return {
			"ok": false,
			"error": "Vision Maximum Output Tokens (%d) must be smaller than the configured Vision Context Window (%d). Update the Vision token limits in Settings." % [vision_output, vision_context]
		}

	var routed_profile: Dictionary = profile.duplicate(true)
	routed_profile["model"] = vision_model
	routed_profile["context_window_tokens"] = vision_context
	routed_profile["max_output_tokens"] = vision_output

	var prepared := _prepare_vision_input_v0159(image_path)
	if not bool(prepared.get("ok", false)):
		return prepared
	var request_path := str(prepared.get("path", image_path))
	var result := super.queue_collaborator_vision_summary(
		request_path,
		routed_profile,
		retry_count,
		session_id
	)
	var temporary_path := str(prepared.get("temporary_path", ""))
	if not temporary_path.is_empty() and FileAccess.file_exists(temporary_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
	return result


func _prepare_vision_input_v0159(image_path: String) -> Dictionary:
	if image_path.is_empty() or not FileAccess.file_exists(image_path):
		return {"ok": false, "error": "The selected image file no longer exists."}

	var file := FileAccess.open(image_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read the selected image."}
	var byte_size := file.get_length()
	file.close()

	var image := Image.new()
	var load_error := image.load(image_path)
	if load_error != OK:
		# Keep the existing v0.15.7 loader as the authority for supported image
		# formats; preprocessing is optional and must never block a small valid
		# image just because Godot could not decode it for resizing.
		return {"ok": true, "path": image_path, "optimised": false}

	var width := image.get_width()
	var height := image.get_height()
	var longest := maxi(width, height)
	var needs_resize := longest > AUTO_MAX_VISION_DIMENSION_V0159
	var needs_compression := byte_size > AUTO_MAX_VISION_BYTES_V0159
	if not needs_resize and not needs_compression:
		return {
			"ok": true,
			"path": image_path,
			"optimised": false,
			"original_width": width,
			"original_height": height,
			"original_bytes": byte_size
		}

	if needs_resize:
		var scale := float(AUTO_MAX_VISION_DIMENSION_V0159) / float(longest)
		var target_width := maxi(1, int(round(float(width) * scale)))
		var target_height := maxi(1, int(round(float(height) * scale)))
		image.resize(target_width, target_height, Image.INTERPOLATE_LANCZOS)

	var cache_dir := "user://vision_cache"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cache_dir))
	var temporary_path := "%s/collaborator_%d.webp" % [cache_dir, Time.get_ticks_usec()]
	var save_error := image.save_webp(temporary_path, true, AUTO_VISION_WEBP_QUALITY_V0159)
	if save_error != OK:
		return {"ok": true, "path": image_path, "optimised": false}

	return {
		"ok": true,
		"path": temporary_path,
		"temporary_path": temporary_path,
		"optimised": true,
		"original_width": width,
		"original_height": height,
		"original_bytes": byte_size,
		"prepared_width": image.get_width(),
		"prepared_height": image.get_height()
	}
