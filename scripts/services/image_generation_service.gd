class_name CCFImageGenerationService
extends Node

signal generation_started
signal generation_completed(record: Dictionary)
signal generation_batch_completed(records: Array)
signal generation_failed(message: String)
signal generation_cancelled

const IMAGE_RECORD_FORMAT_VERSION := 2
const PROVIDER_OPENAI_COMPATIBLE := CCFSettingsService.IMAGE_BACKEND_OPENAI
const PROVIDER_AUTOMATIC1111 := CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111

var _request: HTTPRequest
var _active := false
var _downloading_remote := false
var _cancel_requested := false
var _pending_project_id := ""
var _pending_character_id := ""
var _pending_profile: Dictionary = {}
var _pending_prompt := ""
var _pending_negative_prompt := ""
var _pending_prompt_style := "auto"
var _pending_image_size := "1024x1024"
var _pending_model := ""
var _pending_backend := PROVIDER_OPENAI_COMPATIBLE
var _pending_options: Dictionary = {}
var _pending_payloads: Array[Dictionary] = []
var _pending_records: Array[Dictionary] = []
var _pending_seeds: Array[int] = []
var _pending_payload_index := 0


func _ready() -> void:
	_create_request()


func generate(
	project_id: String,
	character_id: String,
	profile: Dictionary,
	prompt_text: String,
	negative_prompt: String,
	image_size: String,
	prompt_style: String,
	model_override: String = "",
	options: Dictionary = {}
) -> Dictionary:
	if _active:
		return {"ok": false, "error": "An image generation request is already running."}
	var clean_project_id := project_id.strip_edges()
	var clean_character_id := character_id.strip_edges()
	if clean_project_id.is_empty() or clean_character_id.is_empty():
		return {"ok": false, "error": "Select a saved character project before generating an image."}
	var clean_prompt := prompt_text.strip_edges()
	if clean_prompt.is_empty():
		return {"ok": false, "error": "Enter or build an image prompt before generating."}
	var base_url := str(profile.get("base_url", "")).strip_edges()
	if base_url.is_empty():
		return {"ok": false, "error": "The selected image provider profile does not have a base URL."}

	_pending_backend = backend_for_profile(profile)
	var requested_model := model_override.strip_edges()
	if requested_model.is_empty():
		requested_model = str(profile.get("model", "")).strip_edges()
	if _pending_backend == PROVIDER_OPENAI_COMPATIBLE and requested_model.is_empty():
		return {"ok": false, "error": "Enter an image model ID or choose a profile that already has one."}

	_pending_project_id = clean_project_id
	_pending_character_id = clean_character_id
	_pending_profile = profile.duplicate(true)
	_pending_prompt = clean_prompt
	_pending_negative_prompt = negative_prompt.strip_edges()
	_pending_prompt_style = _normalise_prompt_style(prompt_style)
	_pending_image_size = image_size.strip_edges()
	if _pending_image_size.is_empty():
		_pending_image_size = "1024x1024"
	_pending_model = requested_model
	_pending_options = _normalise_generation_options(profile, options)
	_pending_payloads.clear()
	_pending_records.clear()
	_pending_seeds.clear()
	_pending_payload_index = 0
	_downloading_remote = false
	_cancel_requested = false
	_active = true

	var payload := _build_generation_payload()
	var request_error := _request.request(
		_generation_url(base_url, _pending_backend),
		_request_headers(profile),
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if request_error != OK:
		_reset_active_state()
		return {
			"ok": false,
			"error": "Could not start image generation request (error %s)." % request_error
		}
	generation_started.emit()
	return {"ok": true, "backend": _pending_backend}


func cancel() -> void:
	if not _active or _request == null:
		return
	_cancel_requested = true
	_request.cancel_request()
	_reset_active_state()
	_create_request()
	generation_cancelled.emit()


func is_active() -> bool:
	return _active


static func backend_for_profile(profile: Dictionary) -> String:
	return CCFSettingsService.image_backend(profile)


static func build_prompt(
	project: Dictionary,
	character_id: String,
	prompt_style: String,
	extra_direction: String = ""
) -> String:
	var character := CCFStorageService.get_character(project, character_id)
	if character.is_empty():
		return extra_direction.strip_edges()
	var character_data: Dictionary = character.get("character", {})
	var character_metadata: Dictionary = character.get("metadata", {})
	var concept_data: Dictionary = character.get("concept", {})
	var character_name := CCFStorageService.character_display_name(character)
	var description := str(character_data.get("description", "")).strip_edges()
	var personality := str(character_data.get("personality", "")).strip_edges()
	var concept := str(concept_data.get("prompt", "")).strip_edges()
	var role_text := str(character_metadata.get("role", "")).strip_edges()
	var extra_text := extra_direction.strip_edges()
	var resolved_style := _normalise_prompt_style(prompt_style)
	if resolved_style == "auto":
		resolved_style = "natural"

	if resolved_style == "stable_diffusion":
		var tags: Array[String] = ["solo", "character portrait", "character focus"]
		if not character_name.is_empty() and character_name != "Untitled Character":
			tags.append(character_name)
		if not role_text.is_empty():
			tags.append(role_text)
		if not description.is_empty():
			tags.append(description)
		elif not concept.is_empty():
			tags.append(concept)
		if not extra_text.is_empty():
			tags.append(extra_text)
		return ", ".join(tags)

	var sections: Array[String] = [
		"Create a polished character portrait suitable for an AI roleplay character card. Keep the character visually coherent and make the character the clear focus of the image."
	]
	if not character_name.is_empty() and character_name != "Untitled Character":
		sections.append("Character: %s." % character_name)
	if not role_text.is_empty():
		sections.append("Role or archetype: %s." % role_text)
	if not description.is_empty():
		sections.append("Appearance and character description: %s" % description.left(5000))
	elif not concept.is_empty():
		sections.append("Character concept: %s" % concept.left(5000))
	if not personality.is_empty():
		sections.append("Personality cues to reflect visually: %s" % personality.left(1800))
	if not extra_text.is_empty():
		sections.append("Additional visual direction: %s" % extra_text)
	return "\n\n".join(sections)


static func resolve_generated_image_path(project_id: String, relative_path: String) -> String:
	var clean_relative := relative_path.strip_edges().replace("\\", "/")
	if clean_relative.is_empty() or clean_relative.begins_with("/") or clean_relative.contains(".."):
		return ""
	return CCFStorageService.project_folder(project_id) + "/" + clean_relative


func _build_generation_payload() -> Dictionary:
	var batch_size := int(_pending_options.get("batch_size", 1))
	if _pending_backend == PROVIDER_AUTOMATIC1111:
		var payload := {
			"prompt": _pending_prompt,
			"negative_prompt": _pending_negative_prompt,
			"batch_size": batch_size,
			"n_iter": 1,
			"steps": int(_pending_options.get("steps", 28)),
			"cfg_scale": float(_pending_options.get("cfg_scale", 7.0)),
			"seed": int(_pending_options.get("seed", -1)),
			"save_images": false,
			"send_images": true
		}
		var sampler_name := str(_pending_options.get("sampler", "")).strip_edges()
		if not sampler_name.is_empty():
			payload["sampler_name"] = sampler_name
		var dimensions := _parse_image_size(_pending_image_size)
		if not dimensions.is_empty():
			payload["width"] = int(dimensions.get("width", 1024))
			payload["height"] = int(dimensions.get("height", 1024))
		if not _pending_model.is_empty():
			payload["override_settings"] = {"sd_model_checkpoint": _pending_model}
			payload["override_settings_restore_afterwards"] = true
		return payload

	var openai_payload := {
		"model": _pending_model,
		"prompt": _prompt_for_openai_request(_pending_prompt, _pending_negative_prompt),
		"n": batch_size
	}
	if _pending_image_size.to_lower() != "auto":
		openai_payload["size"] = _pending_image_size
	return openai_payload


func _normalise_generation_options(profile: Dictionary, overrides: Dictionary) -> Dictionary:
	var image_options := CCFSettingsService.image_settings(profile)
	image_options.merge(overrides, true)
	image_options["sampler"] = str(image_options.get("sampler", "Euler a")).strip_edges()
	image_options["steps"] = clampi(int(image_options.get("steps", 28)), 1, 150)
	image_options["cfg_scale"] = clampf(float(image_options.get("cfg_scale", 7.0)), 1.0, 30.0)
	image_options["seed"] = int(image_options.get("seed", -1))
	image_options["batch_size"] = clampi(int(image_options.get("batch_size", 1)), 1, 8)
	image_options["generation_mode"] = str(image_options.get("generation_mode", "new")).strip_edges()
	image_options["source_image_id"] = str(image_options.get("source_image_id", "")).strip_edges()
	return image_options


func _create_request() -> void:
	if _request != null:
		if _request.request_completed.is_connected(_on_request_completed):
			_request.request_completed.disconnect(_on_request_completed)
		if _request.get_parent() == self:
			remove_child(_request)
		_request.queue_free()
	_request = HTTPRequest.new()
	_request.timeout = 300.0
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)


func _on_request_completed(
	request_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if not _active or _cancel_requested:
		return
	if request_result != HTTPRequest.RESULT_SUCCESS:
		_fail("Image request failed (result %s)." % request_result)
		return
	if response_code < 200 or response_code >= 300:
		_fail("Image provider error %s: %s" % [response_code, _error_detail(body.get_string_from_utf8())])
		return

	if _downloading_remote:
		_downloading_remote = false
		var decoded_remote := _image_from_bytes(body)
		if decoded_remote == null:
			_fail("The generated image URL returned data Godot could not decode as PNG, JPEG, or WebP.")
			return
		_append_saved_image(decoded_remote, _seed_for_index(_pending_payload_index))
		if not _active:
			return
		_pending_payload_index += 1
		call_deferred("_process_pending_payloads")
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		var raw_image := _image_from_bytes(body)
		if raw_image != null:
			_pending_payloads = [{"kind": "image", "image": raw_image}]
			_pending_seeds = [int(_pending_options.get("seed", -1))]
			_process_pending_payloads()
			return
		_fail("The image provider returned neither a JSON response nor recognised image bytes.")
		return

	_pending_payloads = _extract_image_payloads(parsed)
	if _pending_payloads.is_empty():
		_fail("The image provider response did not contain generated image data or downloadable URLs.")
		return
	_pending_seeds = _extract_response_seeds(parsed, _pending_payloads.size())
	_pending_payload_index = 0
	_process_pending_payloads()


func _process_pending_payloads() -> void:
	if not _active or _cancel_requested:
		return
	while _pending_payload_index < _pending_payloads.size():
		var image_payload: Dictionary = _pending_payloads[_pending_payload_index]
		var payload_kind := str(image_payload.get("kind", ""))
		if payload_kind == "bytes":
			var decoded_image := _image_from_bytes(image_payload.get("bytes", PackedByteArray()))
			if decoded_image == null:
				_fail("The provider returned image data that Godot could not decode as PNG, JPEG, or WebP.")
				return
			_append_saved_image(decoded_image, _seed_for_index(_pending_payload_index))
			if not _active:
				return
			_pending_payload_index += 1
			continue
		if payload_kind == "image":
			var decoded_variant = image_payload.get("image")
			if decoded_variant is Image:
				_append_saved_image(decoded_variant, _seed_for_index(_pending_payload_index))
				if not _active:
					return
				_pending_payload_index += 1
				continue
		if payload_kind == "url":
			var remote_url := str(image_payload.get("url", "")).strip_edges()
			if remote_url.is_empty():
				_fail("The image provider returned an empty generated-image URL.")
				return
			_downloading_remote = true
			var download_error := _request.request(remote_url)
			if download_error != OK:
				_fail("Could not download a generated image (error %s)." % download_error)
			return
		_fail("The image provider returned an unsupported generated-image payload.")
		return
	_finish_batch()


func _extract_image_payloads(response: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var containers: Array = []
	for key_text in ["data", "images", "output"]:
		var value = response.get(key_text, [])
		if value is Array:
			containers.append_array(value)
		elif value is Dictionary or value is String:
			containers.append(value)
	if containers.is_empty():
		containers.append(response)

	for candidate in containers:
		if candidate is String:
			var string_result := _decode_image_string(candidate)
			if bool(string_result.get("ok", false)):
				results.append(_payload_without_ok(string_result))
			continue
		if not candidate is Dictionary:
			continue
		var found_candidate := false
		for key_text in ["b64_json", "base64", "b64", "image", "image_base64"]:
			var encoded := str(candidate.get(key_text, "")).strip_edges()
			if encoded.is_empty():
				continue
			var decoded_result := _decode_image_string(encoded)
			if bool(decoded_result.get("ok", false)):
				results.append(_payload_without_ok(decoded_result))
				found_candidate = true
				break
		if found_candidate:
			continue
		for key_text in ["url", "image_url"]:
			var remote_url := str(candidate.get(key_text, "")).strip_edges()
			if remote_url.begins_with("http://") or remote_url.begins_with("https://"):
				results.append({"kind": "url", "url": remote_url})
				break
	return results


func _payload_without_ok(decoded_result: Dictionary) -> Dictionary:
	var result := decoded_result.duplicate(true)
	result.erase("ok")
	return result


func _decode_image_string(encoded: String) -> Dictionary:
	var clean_encoded := encoded.strip_edges()
	if clean_encoded.begins_with("http://") or clean_encoded.begins_with("https://"):
		return {"ok": true, "kind": "url", "url": clean_encoded}
	if clean_encoded.begins_with("data:image/"):
		var comma_index := clean_encoded.find(",")
		if comma_index < 0:
			return {"ok": false}
		clean_encoded = clean_encoded.substr(comma_index + 1)
	var bytes := Marshalls.base64_to_raw(clean_encoded)
	if bytes.is_empty():
		return {"ok": false}
	return {"ok": true, "kind": "bytes", "bytes": bytes}


func _extract_response_seeds(response: Dictionary, image_count: int) -> Array[int]:
	var seeds: Array[int] = []
	if _pending_backend == PROVIDER_AUTOMATIC1111:
		var info_value = response.get("info", {})
		var info_dictionary: Dictionary = {}
		if info_value is String:
			var parsed_info = JSON.parse_string(info_value)
			if parsed_info is Dictionary:
				info_dictionary = parsed_info
		elif info_value is Dictionary:
			info_dictionary = info_value
		var all_seeds = info_dictionary.get("all_seeds", [])
		if all_seeds is Array:
			for raw_seed in all_seeds:
				seeds.append(int(raw_seed))
		if seeds.is_empty() and info_dictionary.has("seed"):
			seeds.append(int(info_dictionary.get("seed", -1)))
	var requested_seed := int(_pending_options.get("seed", -1))
	while seeds.size() < image_count:
		if requested_seed >= 0:
			seeds.append(requested_seed + seeds.size())
		else:
			seeds.append(-1)
	return seeds


func _seed_for_index(image_index: int) -> int:
	if image_index >= 0 and image_index < _pending_seeds.size():
		return _pending_seeds[image_index]
	return int(_pending_options.get("seed", -1))


func _append_saved_image(decoded_image: Image, actual_seed: int) -> void:
	var record := _save_image(decoded_image, _pending_records.size(), actual_seed)
	if record.is_empty():
		return
	_pending_records.append(record)


func _save_image(decoded_image: Image, batch_index: int, actual_seed: int) -> Dictionary:
	var generated_folder := (
		CCFStorageService.project_folder(_pending_project_id)
		+ "/characters/"
		+ _pending_character_id
		+ "/generated_images"
	)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(generated_folder))
	var stamp := int(Time.get_unix_time_from_system())
	var suffix := randi_range(1000, 9999)
	var file_name := "generated_%s_%s_%s.png" % [stamp, batch_index + 1, suffix]
	var relative_path := "characters/%s/generated_images/%s" % [_pending_character_id, file_name]
	var user_path := CCFStorageService.project_folder(_pending_project_id) + "/" + relative_path
	var save_error := decoded_image.save_png(ProjectSettings.globalize_path(user_path))
	if save_error != OK:
		_fail("A generated image was received but could not be saved (error %s)." % save_error)
		return {}

	var image_record := {
		"format_version": IMAGE_RECORD_FORMAT_VERSION,
		"image_id": "image_%s_%s_%s" % [stamp, batch_index + 1, suffix],
		"path": relative_path,
		"created_at": Time.get_datetime_string_from_system(true),
		"provider": _pending_backend,
		"backend": _pending_backend,
		"profile_id": str(_pending_profile.get("id", "default")),
		"profile_name": str(_pending_profile.get("name", "Profile")),
		"model": _pending_model,
		"size": _pending_image_size,
		"prompt_style": _pending_prompt_style,
		"prompt": _pending_prompt,
		"negative_prompt": _pending_negative_prompt,
		"batch_index": batch_index,
		"batch_size": int(_pending_options.get("batch_size", 1)),
		"sampler": str(_pending_options.get("sampler", "")),
		"steps": int(_pending_options.get("steps", 28)),
		"cfg_scale": float(_pending_options.get("cfg_scale", 7.0)),
		"seed": actual_seed,
		"generation_mode": str(_pending_options.get("generation_mode", "new")),
		"source_image_id": str(_pending_options.get("source_image_id", "")),
		"width": decoded_image.get_width(),
		"height": decoded_image.get_height()
	}
	return image_record


func _finish_batch() -> void:
	if _pending_records.is_empty():
		_fail("The image provider completed successfully but no generated images could be saved.")
		return
	var completed_records: Array = _pending_records.duplicate(true)
	_reset_active_state()
	for raw_record in completed_records:
		if raw_record is Dictionary:
			generation_completed.emit(raw_record)
	generation_batch_completed.emit(completed_records)


func _image_from_bytes(bytes: PackedByteArray) -> Image:
	if bytes.is_empty():
		return null
	var decoded_image := Image.new()
	if decoded_image.load_png_from_buffer(bytes) == OK:
		return decoded_image
	decoded_image = Image.new()
	if decoded_image.load_jpg_from_buffer(bytes) == OK:
		return decoded_image
	decoded_image = Image.new()
	if decoded_image.load_webp_from_buffer(bytes) == OK:
		return decoded_image
	return null


func _fail(message_text: String) -> void:
	_reset_active_state()
	generation_failed.emit(message_text)


func _reset_active_state() -> void:
	_active = false
	_downloading_remote = false
	_cancel_requested = false
	_pending_project_id = ""
	_pending_character_id = ""
	_pending_profile.clear()
	_pending_prompt = ""
	_pending_negative_prompt = ""
	_pending_prompt_style = "auto"
	_pending_image_size = "1024x1024"
	_pending_model = ""
	_pending_backend = PROVIDER_OPENAI_COMPATIBLE
	_pending_options.clear()
	_pending_payloads.clear()
	_pending_records.clear()
	_pending_seeds.clear()
	_pending_payload_index = 0


func _request_headers(profile: Dictionary) -> PackedStringArray:
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	var api_key := str(profile.get("api_key", "")).strip_edges()
	if not api_key.is_empty():
		headers.append("Authorization: Bearer %s" % api_key)
	return headers


func _generation_url(base_url: String, backend: String) -> String:
	if backend == PROVIDER_AUTOMATIC1111:
		return _a1111_endpoint(base_url, "txt2img")
	var clean_url := _trim_url(base_url)
	if clean_url.ends_with("/images/generations"):
		return clean_url
	return clean_url + "/images/generations"


func _a1111_endpoint(base_url: String, endpoint_name: String) -> String:
	var clean_url := _trim_url(base_url)
	if clean_url.ends_with("/sdapi/v1"):
		return clean_url + "/" + endpoint_name
	if clean_url.contains("/sdapi/v1/"):
		var api_index := clean_url.find("/sdapi/v1/")
		clean_url = clean_url.left(api_index + "/sdapi/v1".length())
		return clean_url + "/" + endpoint_name
	return clean_url + "/sdapi/v1/" + endpoint_name


func _trim_url(base_url: String) -> String:
	var clean_url := base_url.strip_edges()
	while clean_url.ends_with("/"):
		clean_url = clean_url.left(clean_url.length() - 1)
	return clean_url


func _prompt_for_openai_request(prompt_text: String, negative_prompt: String) -> String:
	if negative_prompt.is_empty():
		return prompt_text
	return "%s\n\nAvoid or exclude: %s" % [prompt_text, negative_prompt]


func _parse_image_size(image_size: String) -> Dictionary:
	var clean_size := image_size.strip_edges().to_lower()
	if clean_size.is_empty() or clean_size == "auto":
		return {}
	var pieces := clean_size.split("x", false, 1)
	if pieces.size() != 2:
		return {}
	if not pieces[0].is_valid_int() or not pieces[1].is_valid_int():
		return {}
	var width_value := clampi(int(pieces[0]), 64, 4096)
	var height_value := clampi(int(pieces[1]), 64, 4096)
	return {"width": width_value, "height": height_value}


func _error_detail(response_text: String) -> String:
	var parsed = JSON.parse_string(response_text)
	if parsed is Dictionary:
		var error_value = parsed.get("error", {})
		if error_value is Dictionary:
			var message_text := str(error_value.get("message", "")).strip_edges()
			if not message_text.is_empty():
				return message_text.left(1200)
		var detail := str(parsed.get("detail", "")).strip_edges()
		if not detail.is_empty():
			return detail.left(1200)
	return response_text.strip_edges().left(1200)


static func _normalise_prompt_style(prompt_style: String) -> String:
	var clean_style := prompt_style.strip_edges().to_lower()
	if clean_style not in ["auto", "natural", "stable_diffusion"]:
		return "auto"
	return clean_style
