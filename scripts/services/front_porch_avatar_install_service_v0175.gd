class_name CCFFrontPorchAvatarInstallServiceV0175
extends CCFFrontPorchInstallServiceV0173


static func character_list_path_v0175() -> String:
	return "/api/characters?scope=allCharacters&sort=name"


static func avatar_list_path_v0175(character_id: String) -> String:
	return "/api/characters/%s/avatars" % character_id.uri_encode()


static func avatar_upload_path_v0175(
	character_id: String, entry_kind: String, expression_label := ""
) -> String:
	if entry_kind == "look":
		return "/api/characters/%s/looks" % character_id.uri_encode()
	return "/api/characters/%s/avatars?label=%s" % [
		character_id.uri_encode(), expression_label.uri_encode()
	]


static func favourite_path_v0175(
	character_id: String, avatar_id: String
) -> String:
	return "/api/characters/%s/favorite?avatarId=%s" % [
		character_id.uri_encode(), avatar_id.uri_encode()
	]


static func classify_character_list_response_v0175(raw: Dictionary) -> Dictionary:
	var failure := _transport_failure(raw)
	if not failure.is_empty():
		return failure
	var code := int(raw.get("response_code", 0))
	var payload: Variant = _payload(raw)
	if code == 200 and payload is Array:
		var characters: Array[Dictionary] = []
		for value in payload:
			if not value is Dictionary:
				continue
			var character_id := str(value.get("id", "")).strip_edges()
			if character_id.is_empty():
				continue
			characters.append({
				"id": character_id,
				"name": str(value.get("name", "Untitled Character")),
				"has_avatar": bool(value.get("hasAvatar", false))
			})
		return {"ok": true, "characters": characters}
	if code == 401:
		return {
			"ok": false,
			"auth_required": true,
			"response_code": code,
			"error": "Front Porch login expired. Connect again and retry."
		}
	return _http_failure(code, payload, "Could not list Front Porch characters.")


static func classify_avatar_response_v0175(
	raw: Dictionary, previous_ids := PackedStringArray()
) -> Dictionary:
	var failure := _transport_failure(raw)
	if not failure.is_empty():
		return failure
	var code := int(raw.get("response_code", 0))
	var payload: Variant = _payload(raw)
	if code == 200 and payload is Dictionary:
		var avatars_value: Variant = payload.get("avatars", [])
		if avatars_value is Array:
			var avatars: Array[Dictionary] = []
			var created_id := ""
			for value in avatars_value:
				if not value is Dictionary:
					continue
				var avatar := (value as Dictionary).duplicate(true)
				var avatar_id := str(avatar.get("id", ""))
				if avatar_id.is_empty():
					continue
				avatars.append(avatar)
				if not previous_ids.has(avatar_id):
					created_id = avatar_id
			return {
				"ok": true,
				"avatars": avatars,
				"created_avatar_id": created_id,
				"payload": payload
			}
	if code == 401:
		return {
			"ok": false,
			"auth_required": true,
			"response_code": code,
			"error": "Front Porch login expired. Connect again and retry."
		}
	return _http_failure(code, payload, "Front Porch declined the avatar request.")


func list_characters_v0175() -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	var raw := await _perform_request(
		HTTPClient.METHOD_GET, character_list_path_v0175(), "", _session_headers()
	)
	var result := classify_character_list_response_v0175(raw)
	if bool(result.get("auth_required", false)):
		clear_session()
	return result


func list_avatars_v0175(character_id: String) -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	var raw := await _perform_request(
		HTTPClient.METHOD_GET,
		avatar_list_path_v0175(character_id),
		"",
		_session_headers()
	)
	var result := classify_avatar_response_v0175(raw)
	if bool(result.get("auth_required", false)):
		clear_session()
	return result


func install_gallery_image_v0175(
	character_id: String,
	image_bytes: PackedByteArray,
	entry_kind: String,
	expression_label := ""
) -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	if image_bytes.is_empty():
		return {"ok": false, "error": "The selected gallery image is empty."}
	if entry_kind not in ["look", "expression"]:
		return {"ok": false, "error": "Choose a Front Porch look or expression."}
	var before := await list_avatars_v0175(character_id)
	if not bool(before.get("ok", false)):
		return before
	var previous_ids := PackedStringArray()
	for avatar in before.get("avatars", []):
		previous_ids.append(str(avatar.get("id", "")))
	var headers := _session_headers()
	headers.append("Content-Type: image/png")
	var raw := await _perform_raw_request(
		HTTPClient.METHOD_POST,
		avatar_upload_path_v0175(character_id, entry_kind, expression_label),
		image_bytes,
		headers
	)
	var result := classify_avatar_response_v0175(raw, previous_ids)
	if bool(result.get("auth_required", false)):
		clear_session()
	return result


func set_favourite_v0175(character_id: String, avatar_id: String) -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	var raw := await _perform_request(
		HTTPClient.METHOD_POST,
		favourite_path_v0175(character_id, avatar_id),
		"",
		_session_headers()
	)
	var result := classify_avatar_response_v0175(raw)
	if bool(result.get("auth_required", false)):
		clear_session()
	return result


func gallery_capabilities_v0175() -> Dictionary:
	return {
		"front_porch_version": "1.3.2+",
		"character_listing": true,
		"expression_upload": true,
		"look_upload": true,
		"favourite_selection": true,
		"cookie_session_auth": true,
		"raw_database_writes": false
	}
