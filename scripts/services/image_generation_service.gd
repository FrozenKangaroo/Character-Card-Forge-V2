class_name CCFImageGenerationService
extends Node

signal generation_started
signal generation_completed(record: Dictionary)
signal generation_failed(message: String)
signal generation_cancelled

const IMAGE_RECORD_FORMAT_VERSION := 1
const PROVIDER_OPENAI_COMPATIBLE := "openai_compatible"

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
	model_override: String = ""
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
	var requested_model := model_override.strip_edges()
	if requested_model.is_empty():
		requested_model = str(profile.get("model", "")).strip_edges()
	if requested_model.is_empty():
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
	_downloading_remote = false
	_cancel_requested = false
	_active = true

	var payload := {
		"model": _pending_model,
		"prompt": _prompt_for_request(_pending_prompt, _pending_negative_prompt),
		"n": 1
	}
	if _pending_image_size.to_lower() != "auto":
		payload["size"] = _pending_image_size
	var request_error := _request.request(
		_image_generation_url(base_url),
		_request_headers(profile),
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if request_error != OK:
		_active = false
		return {
			"ok": false,
			"error": "Could not start image generation request (error %s)." % request_error
		}
	generation_started.emit()
	return {"ok": true}


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
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if not _active or _cancel_requested:
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("Image request failed (result %s)." % result)
		return
	if response_code < 200 or response_code >= 300:
		var response_text := body.get_string_from_utf8()
		_fail("Image provider error %s: %s" % [response_code, _error_detail(response_text)])
		return
	if _downloading_remote:
		_finish_image_bytes(body)
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		# A few compatible servers return raw image bytes even on generation routes.
		var raw_image := _image_from_bytes(body)
		if raw_image != null:
			_finish_image(raw_image)
			return
		_fail("The image provider returned neither a JSON response nor recognised image bytes.")
		return
	var image_result := _extract_image_payload(parsed)
	if not bool(image_result.get("ok", false)):
		_fail(str(image_result.get("error", "The image provider response did not contain an image.")))
		return
	var response_kind := str(image_result.get("kind", ""))
	if response_kind == "bytes":
		_finish_image_bytes(image_result.get("bytes", PackedByteArray()))
		return
	if response_kind == "url":
		var remote_url := str(image_result.get("url", "")).strip_edges()
		if remote_url.is_empty():
			_fail("The image provider returned an empty image URL.")
			return
		_downloading_remote = true
		var download_error := _request.request(remote_url)
		if download_error != OK:
			_fail("Could not download the generated image (error %s)." % download_error)
		return
	_fail("The image provider returned an unsupported image response.")


func _extract_image_payload(response: Dictionary) -> Dictionary:
	var candidates: Array = []
	var data_value = response.get("data", [])
	if data_value is Array:
		candidates.append_array(data_value)
	elif data_value is Dictionary:
		candidates.append(data_value)
	var images_value = response.get("images", [])
	if images_value is Array:
		candidates.append_array(images_value)
	elif images_value is Dictionary:
		candidates.append(images_value)
	var output_value = response.get("output", [])
	if output_value is Array:
		candidates.append_array(output_value)
	elif output_value is Dictionary:
		candidates.append(output_value)
	candidates.append(response)

	for candidate in candidates:
		if candidate is String:
			var string_result := _decode_image_string(candidate)
			if bool(string_result.get("ok", false)):
				return string_result
		if not candidate is Dictionary:
			continue
		for key_text in ["b64_json", "base64", "b64", "image", "image_base64"]:
			var encoded := str(candidate.get(key_text, "")).strip_edges()
			if encoded.is_empty():
				continue
			var decoded_result := _decode_image_string(encoded)
			if bool(decoded_result.get("ok", false)):
				return decoded_result
		for key_text in ["url", "image_url"]:
			var remote_url := str(candidate.get(key_text, "")).strip_edges()
			if remote_url.begins_with("http://") or remote_url.begins_with("https://"):
				return {"ok": true, "kind": "url", "url": remote_url}
	return {"ok": false, "error": "The image provider response did not contain base64 image data or a downloadable URL."}


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


func _finish_image_bytes(bytes: PackedByteArray) -> void:
	var decoded_image := _image_from_bytes(bytes)
	if decoded_image == null:
		_fail("The provider returned image data that Godot could not decode as PNG, JPEG, or WebP.")
		return
	_finish_image(decoded_image)


func _finish_image(decoded_image: Image) -> void:
	var generated_folder := (
		CCFStorageService.project_folder(_pending_project_id)
		+ "/characters/"
		+ _pending_character_id
		+ "/generated_images"
	)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(generated_folder))
	var stamp := int(Time.get_unix_time_from_system())
	var suffix := randi_range(1000, 9999)
	var file_name := "generated_%s_%s.png" % [stamp, suffix]
	var relative_path := "characters/%s/generated_images/%s" % [_pending_character_id, file_name]
	var user_path := CCFStorageService.project_folder(_pending_project_id) + "/" + relative_path
	var save_error := decoded_image.save_png(ProjectSettings.globalize_path(user_path))
	if save_error != OK:
		_fail("The generated image was received but could not be saved (error %s)." % save_error)
		return

	var image_record := {
		"format_version": IMAGE_RECORD_FORMAT_VERSION,
		"image_id": "image_%s_%s" % [stamp, suffix],
		"path": relative_path,
		"created_at": Time.get_datetime_string_from_system(true),
		"provider": PROVIDER_OPENAI_COMPATIBLE,
		"profile_id": str(_pending_profile.get("id", "default")),
		"profile_name": str(_pending_profile.get("name", "Profile")),
		"model": _pending_model,
		"size": _pending_image_size,
		"prompt_style": _pending_prompt_style,
		"prompt": _pending_prompt,
		"negative_prompt": _pending_negative_prompt,
		"width": decoded_image.get_width(),
		"height": decoded_image.get_height()
	}
	_reset_active_state()
	generation_completed.emit(image_record)


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


func _fail(message: String) -> void:
	_reset_active_state()
	generation_failed.emit(message)


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


func _request_headers(profile: Dictionary) -> PackedStringArray:
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	var api_key := str(profile.get("api_key", "")).strip_edges()
	if not api_key.is_empty():
		headers.append("Authorization: Bearer %s" % api_key)
	return headers


func _image_generation_url(base_url: String) -> String:
	var clean_url := base_url.strip_edges()
	while clean_url.ends_with("/"):
		clean_url = clean_url.left(clean_url.length() - 1)
	if clean_url.ends_with("/images/generations"):
		return clean_url
	return clean_url + "/images/generations"


func _prompt_for_request(prompt_text: String, negative_prompt: String) -> String:
	if negative_prompt.is_empty():
		return prompt_text
	# The OpenAI-compatible images route has no universal negative-prompt field.
	# Preserve the user's intent in a provider-neutral instruction instead.
	return "%s\n\nAvoid or exclude: %s" % [prompt_text, negative_prompt]


func _error_detail(response_text: String) -> String:
	var parsed = JSON.parse_string(response_text)
	if parsed is Dictionary:
		var error_value = parsed.get("error", {})
		if error_value is Dictionary:
			var message := str(error_value.get("message", "")).strip_edges()
			if not message.is_empty():
				return message.left(1200)
		var detail := str(parsed.get("detail", "")).strip_edges()
		if not detail.is_empty():
			return detail.left(1200)
	return response_text.strip_edges().left(1200)


static func _normalise_prompt_style(prompt_style: String) -> String:
	var clean_style := prompt_style.strip_edges().to_lower()
	if not clean_style in ["auto", "natural", "stable_diffusion"]:
		return "auto"
	return clean_style
