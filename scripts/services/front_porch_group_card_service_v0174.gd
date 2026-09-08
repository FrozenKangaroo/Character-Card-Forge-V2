class_name CCFFrontPorchGroupCardServiceV0174
extends RefCounted

const GROUP_SPEC := "front_porch_group_card"
const GROUP_SPEC_VERSION := "1.0"
const GROUP_PNG_KEY := "fpa_group"
const CHARACTER_PNG_KEY := "chara"
const VALID_TURN_ORDERS := ["roundRobin", "random"]
const KNOWN_GROUP_FIELDS := [
	"spec", "spec_version", "name", "members", "raw_member_data", "turn_order",
	"auto_advance", "director_mode", "first_message", "scenario", "system_prompt",
	"character_system_prompts", "group_lorebook", "world_ids", "world_names",
	"inherit_character_lorebooks", "chaos_mode_enabled", "chaos_nsfw_enabled",
	"baseline_realism_state", "default_member_realism_state", "member_objectives",
	"extensions"
]
static var PNG_SIGNATURE := PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10])


static func default_group_options(project: Dictionary, workflow: Dictionary = {}) -> Dictionary:
	var selected_ids := _workflow_character_ids(project, workflow)
	var prompts: Dictionary = {}
	var objectives: Dictionary = {}
	for character_id in selected_ids:
		prompts[character_id] = ""
		objectives[character_id] = []
	return {
		"turn_order": "roundRobin",
		"auto_advance": true,
		"director_mode": false,
		"system_prompt": "",
		"character_system_prompts": prompts,
		"group_lorebook": "",
		"world_ids": [],
		"world_names": [],
		"inherit_character_lorebooks": true,
		"chaos_mode_enabled": false,
		"chaos_nsfw_enabled": false,
		"baseline_realism_state": JSON.stringify(_baseline_realism(selected_ids)),
		"default_member_realism_state": JSON.stringify(_default_realism(selected_ids)),
		"member_objectives": objectives,
		"extensions": {},
		"preserved_fields": {}
	}


static func build_group_payload(
	project: Dictionary, workflow: Dictionary, options_override: Dictionary = {}
) -> Dictionary:
	var options := default_group_options(project, workflow)
	var saved_options = workflow.get("front_porch_group", {})
	if saved_options is Dictionary:
		options.merge(saved_options, true)
	options.merge(options_override, true)
	var selected_ids := _workflow_character_ids(project, workflow)
	var members: Array = []
	var raw_members: Array = []
	for character_id in selected_ids:
		var character_record := CCFStorageService.get_character(project, character_id)
		if character_record.is_empty():
			continue
		var card := CCFCardFormatService.export_character_v2(project, character_id)
		var current_data = card.get("data", {})
		if not current_data is Dictionary:
			continue
		var preserved := _preserved_member_data(character_record)
		preserved.merge(current_data, true)
		preserved["_original_stable_id"] = character_id
		var origin_id := _member_origin_id(character_record)
		if not origin_id.is_empty() and origin_id != character_id:
			preserved["_origin_library_stable_id"] = origin_id
		else:
			preserved.erase("_origin_library_stable_id")
		var avatar_result := _member_avatar_base64(project, character_id)
		if not bool(avatar_result.get("ok", false)):
			return avatar_result
		preserved["avatar_base64"] = str(avatar_result.get("avatar_base64", ""))
		raw_members.append(preserved)
		members.append(current_data.duplicate(true))

	var payload: Dictionary = {}
	var preserved_fields = options.get("preserved_fields", {})
	if preserved_fields is Dictionary:
		payload = preserved_fields.duplicate(true)
	payload["spec"] = GROUP_SPEC
	payload["spec_version"] = GROUP_SPEC_VERSION
	payload["name"] = _group_name(project, workflow)
	payload["members"] = members
	payload["raw_member_data"] = raw_members
	payload["turn_order"] = _turn_order(options.get("turn_order", "roundRobin"))
	payload["auto_advance"] = bool(options.get("auto_advance", true))
	payload["director_mode"] = bool(options.get("director_mode", false))
	payload["first_message"] = str(workflow.get("opening_message", ""))
	payload["scenario"] = str(workflow.get("shared_scenario", ""))
	payload["system_prompt"] = str(options.get("system_prompt", ""))
	payload["character_system_prompts"] = _id_dictionary(
		options.get("character_system_prompts", {}), selected_ids, ""
	)
	payload["group_lorebook"] = str(options.get("group_lorebook", ""))
	payload["world_ids"] = _string_array(options.get("world_ids", []))
	payload["world_names"] = _string_array(options.get("world_names", []))
	payload["inherit_character_lorebooks"] = bool(
		options.get("inherit_character_lorebooks", true)
	)
	payload["chaos_mode_enabled"] = bool(options.get("chaos_mode_enabled", false))
	payload["chaos_nsfw_enabled"] = bool(options.get("chaos_nsfw_enabled", false))
	payload["baseline_realism_state"] = _json_object_string(
		options.get("baseline_realism_state", ""), _baseline_realism(selected_ids)
	)
	payload["default_member_realism_state"] = _json_object_string(
		options.get("default_member_realism_state", ""), _default_realism(selected_ids)
	)
	payload["member_objectives"] = _id_dictionary(
		options.get("member_objectives", {}), selected_ids, []
	)
	var extensions = options.get("extensions", {})
	payload["extensions"] = extensions.duplicate(true) if extensions is Dictionary else {}
	return {"ok": true, "payload": payload, "report": validate_group_payload(payload)}


static func validate_group_payload(payload: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if str(payload.get("spec", "")) != GROUP_SPEC:
		errors.append("The card spec must be '%s'." % GROUP_SPEC)
	if str(payload.get("spec_version", "")) != GROUP_SPEC_VERSION:
		errors.append("Only Front Porch group-card spec version %s is supported." % GROUP_SPEC_VERSION)
	if str(payload.get("name", "")).strip_edges().is_empty():
		errors.append("The group needs a name.")
	var raw_members = payload.get("raw_member_data", [])
	if not raw_members is Array or raw_members.size() < 2:
		errors.append("A Front Porch group card needs at least two raw members.")
	else:
		var stable_ids: Dictionary = {}
		for member_index in range(raw_members.size()):
			var raw_member = raw_members[member_index]
			if not raw_member is Dictionary:
				errors.append("Member %d is not a JSON object." % (member_index + 1))
				continue
			var stable_id := str(raw_member.get("_original_stable_id", "")).strip_edges()
			if stable_id.is_empty():
				errors.append("Member %d has no stable ID." % (member_index + 1))
			elif stable_ids.has(stable_id):
				errors.append("Stable member ID '%s' is duplicated." % stable_id)
			else:
				stable_ids[stable_id] = true
			if str(raw_member.get("name", "")).strip_edges().is_empty():
				errors.append("Member %d has no name." % (member_index + 1))
			var avatar_bytes := Marshalls.base64_to_raw(str(raw_member.get("avatar_base64", "")))
			if not _has_png_signature(avatar_bytes):
				errors.append("Member %d does not contain a valid PNG avatar." % (member_index + 1))
			elif not _png_has_text_key(avatar_bytes, CHARACTER_PNG_KEY):
				warnings.append("Member %d avatar has no Character Card V2 'chara' metadata." % (member_index + 1))
	if _turn_order(payload.get("turn_order", "")) != str(payload.get("turn_order", "")):
		errors.append("Turn order must be 'roundRobin' or 'random'.")
	for field_name in ["baseline_realism_state", "default_member_realism_state"]:
		var value := str(payload.get(field_name, "")).strip_edges()
		if not value.is_empty() and not JSON.parse_string(value) is Dictionary:
			errors.append("%s must contain a JSON object encoded as text." % field_name)
	var lorebook_text := str(payload.get("group_lorebook", "")).strip_edges()
	if not lorebook_text.is_empty() and JSON.parse_string(lorebook_text) == null:
		errors.append("The group lorebook must contain valid JSON text.")
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"member_count": raw_members.size() if raw_members is Array else 0
	}


static func build_group_png_bytes(
	project: Dictionary, workflow: Dictionary, options_override: Dictionary = {}
) -> Dictionary:
	var built := build_group_payload(project, workflow, options_override)
	if not bool(built.get("ok", false)):
		return built
	var report: Dictionary = built.get("report", {})
	if not bool(report.get("ok", false)):
		return {"ok": false, "error": "The group card did not pass validation.", "report": report}
	var payload: Dictionary = built.get("payload", {})
	var cover_result := _build_group_cover(payload)
	if not bool(cover_result.get("ok", false)):
		return cover_result
	var encoded := Marshalls.utf8_to_base64(JSON.stringify(payload))
	var injected := _inject_png_text(
		cover_result.get("bytes", PackedByteArray()), GROUP_PNG_KEY, encoded
	)
	if not bool(injected.get("ok", false)):
		return injected
	return {
		"ok": true,
		"bytes": injected.get("bytes", PackedByteArray()),
		"payload": payload,
		"report": report
	}


static func write_group_card(
	destination_path: String,
	project: Dictionary,
	workflow: Dictionary,
	options_override: Dictionary = {}
) -> Dictionary:
	var built := build_group_png_bytes(project, workflow, options_override)
	if not bool(built.get("ok", false)):
		return built
	var output := FileAccess.open(destination_path, FileAccess.WRITE)
	if output == null:
		return {"ok": false, "error": "Could not open the group-card destination for writing."}
	output.store_buffer(built.get("bytes", PackedByteArray()))
	output.close()
	return {"ok": true, "path": destination_path, "report": built.get("report", {})}


static func load_group_card(source_path: String) -> Dictionary:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return {"ok": false, "error": "Could not open the Front Porch group-card PNG."}
	var bytes := source.get_buffer(source.get_length())
	source.close()
	var extracted := _read_png_text(bytes, GROUP_PNG_KEY)
	if not bool(extracted.get("ok", false)):
		return extracted
	var decoded_text := Marshalls.base64_to_utf8(str(extracted.get("text", "")))
	var parsed = JSON.parse_string(decoded_text)
	if not parsed is Dictionary:
		return {"ok": false, "error": "The fpa_group metadata does not contain valid JSON."}
	var report := validate_group_payload(parsed)
	return {"ok": bool(report.get("ok", false)), "payload": parsed, "report": report,
		"error": "The Front Porch group card did not pass validation." if not bool(report.get("ok", false)) else ""}


static func import_group_to_project(payload: Dictionary, source_path: String = "") -> Dictionary:
	var report := validate_group_payload(payload)
	if not bool(report.get("ok", false)):
		return {"ok": false, "error": "The Front Porch group card did not pass validation.", "report": report}
	var project := CCFStorageService.new_project()
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["name"] = str(payload.get("name", "Imported Front Porch Group"))
	project["metadata"] = metadata
	var shared_context: Dictionary = project.get("shared_context", {}).duplicate(true)
	shared_context["title"] = str(payload.get("name", ""))
	shared_context["situation"] = str(payload.get("scenario", ""))
	project["shared_context"] = shared_context
	var imported_characters: Array = []
	var id_map: Dictionary = {}
	var pending_avatars: Array[Dictionary] = []
	for raw_value in payload.get("raw_member_data", []):
		var raw_member: Dictionary = raw_value
		var transport_free := raw_member.duplicate(true)
		var old_id := str(transport_free.get("_original_stable_id", ""))
		var avatar_base64 := str(transport_free.get("avatar_base64", ""))
		transport_free.erase("avatar_base64")
		transport_free.erase("_original_stable_id")
		transport_free.erase("_origin_library_stable_id")
		var card := {"spec": "chara_card_v2", "spec_version": "2.0", "data": transport_free}
		var imported := CCFCardFormatService.import_card_to_project(card, "front_porch_group_card")
		if not bool(imported.get("ok", false)):
			return {"ok": false, "error": "Could not import group member '%s'." % str(raw_member.get("name", "Untitled"))}
		var member_project: Dictionary = imported.get("project", {})
		var character: Dictionary = member_project.get("characters", [])[0]
		var new_id := str(character.get("character_id", ""))
		id_map[old_id] = new_id
		var interoperability: Dictionary = character.get("interoperability", {}).duplicate(true)
		var preserved := raw_member.duplicate(true)
		preserved.erase("avatar_base64")
		interoperability["front_porch_group_raw_member"] = preserved
		interoperability["front_porch_group_original_stable_id"] = old_id
		interoperability["front_porch_group_source"] = source_path
		character["interoperability"] = interoperability
		var relative_avatar := "characters/%s/assets/front_porch_group_avatar.png" % new_id
		var assets: Dictionary = character.get("assets", {}).duplicate(true)
		assets["portrait"] = relative_avatar
		character["assets"] = assets
		pending_avatars.append({"path": relative_avatar, "base64": avatar_base64})
		imported_characters.append(character)
	project["characters"] = imported_characters
	var workspace: Dictionary = project.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = str(imported_characters[0].get("character_id", ""))
	project["workspace"] = workspace
	var selected_ids: Array[String] = []
	var workflow_members: Array = []
	for character in imported_characters:
		var character_id := str(character.get("character_id", ""))
		selected_ids.append(character_id)
		workflow_members.append({"character_id": character_id, "role_in_output": "",
			"card_direction": "", "scenario_direction": "", "opening_direction": ""})
	var preserved_fields: Dictionary = {}
	for field_name in payload:
		if str(field_name) not in KNOWN_GROUP_FIELDS:
			preserved_fields[str(field_name)] = payload[field_name]
	var options := {
		"turn_order": _turn_order(payload.get("turn_order", "roundRobin")),
		"auto_advance": bool(payload.get("auto_advance", true)),
		"director_mode": bool(payload.get("director_mode", false)),
		"system_prompt": str(payload.get("system_prompt", "")),
		"character_system_prompts": _remap_dictionary_keys(payload.get("character_system_prompts", {}), id_map),
		"group_lorebook": str(payload.get("group_lorebook", "")),
		"world_ids": _string_array(payload.get("world_ids", [])),
		"world_names": _string_array(payload.get("world_names", [])),
		"inherit_character_lorebooks": bool(payload.get("inherit_character_lorebooks", true)),
		"chaos_mode_enabled": bool(payload.get("chaos_mode_enabled", false)),
		"chaos_nsfw_enabled": bool(payload.get("chaos_nsfw_enabled", false)),
		"baseline_realism_state": _remap_json_text(str(payload.get("baseline_realism_state", "")), id_map),
		"default_member_realism_state": _remap_json_text(str(payload.get("default_member_realism_state", "")), id_map),
		"member_objectives": _remap_dictionary_keys(payload.get("member_objectives", {}), id_map),
		"extensions": _remap_value(payload.get("extensions", {}), id_map),
		"preserved_fields": preserved_fields
	}
	project["card_workflows"] = [{
		"workflow_id": "workflow_%d" % Time.get_ticks_usec(),
		"created_at": Time.get_datetime_string_from_system(true),
		"updated_at": Time.get_datetime_string_from_system(true),
		"mode": "group_card",
		"title": str(payload.get("name", "Imported Front Porch Group")),
		"selected_character_ids": selected_ids,
		"instructions": "",
		"summary": "Imported from a Front Porch group card.",
		"shared_scenario": str(payload.get("scenario", "")),
		"opening_message": str(payload.get("first_message", "")),
		"notes": "",
		"members": workflow_members,
		"front_porch_group": options
	}]
	for avatar in pending_avatars:
		var destination := CCFStorageService.project_folder(str(project.get("project_id", ""))).path_join(str(avatar.get("path", "")))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))
		var avatar_file := FileAccess.open(destination, FileAccess.WRITE)
		if avatar_file == null:
			return {"ok": false, "error": "Could not save an imported group member's PNG artwork."}
		avatar_file.store_buffer(Marshalls.base64_to_raw(str(avatar.get("base64", ""))))
		avatar_file.close()
	var save_result := CCFStorageService.save_project(project)
	if not bool(save_result.get("ok", false)):
		return save_result
	return {"ok": true, "project": project, "id_map": id_map, "report": report}


static func _workflow_character_ids(project: Dictionary, workflow: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var raw_ids = workflow.get("selected_character_ids", [])
	if raw_ids is Array:
		for raw_id in raw_ids:
			var character_id := str(raw_id)
			if CCFStorageService.character_index(project, character_id) >= 0 and character_id not in result:
				result.append(character_id)
	return result


static func _group_name(project: Dictionary, workflow: Dictionary) -> String:
	var workflow_title := str(workflow.get("title", "")).strip_edges()
	if not workflow_title.is_empty():
		return workflow_title
	var metadata = project.get("metadata", {})
	if metadata is Dictionary:
		var project_name := str(metadata.get("name", "")).strip_edges()
		if not project_name.is_empty():
			return project_name
	return "Untitled Group"


static func _preserved_member_data(character: Dictionary) -> Dictionary:
	var interoperability = character.get("interoperability", {})
	if interoperability is Dictionary:
		var preserved = interoperability.get("front_porch_group_raw_member", {})
		if preserved is Dictionary:
			var copy: Dictionary = preserved.duplicate(true)
			copy.erase("avatar_base64")
			return copy
	return {}


static func _member_origin_id(character: Dictionary) -> String:
	var interoperability = character.get("interoperability", {})
	if interoperability is Dictionary:
		var original := str(interoperability.get("front_porch_group_original_stable_id", "")).strip_edges()
		if not original.is_empty():
			return original
	var character_data = character.get("character", {})
	if character_data is Dictionary:
		var extensions = character_data.get("card_extensions", {})
		if extensions is Dictionary:
			var front_porch = extensions.get("front_porch", {})
			if front_porch is Dictionary:
				var realism = front_porch.get("realism_engine", {})
				if realism is Dictionary:
					return str(realism.get("stable_id", "")).strip_edges()
	return ""


static func _member_avatar_base64(project: Dictionary, character_id: String) -> Dictionary:
	var source_path := _portrait_path(project, character_id)
	var png_bytes := PackedByteArray()
	if not source_path.is_empty():
		var built := CCFCardFormatService.build_png_card_bytes(source_path, project, character_id)
		if bool(built.get("ok", false)):
			png_bytes = built.get("bytes", PackedByteArray())
	if png_bytes.is_empty():
		var placeholder := Image.create(768, 1024, false, Image.FORMAT_RGBA8)
		var hue := float(abs(character_id.hash()) % 360) / 360.0
		placeholder.fill(Color.from_hsv(hue, 0.38, 0.42))
		var card := CCFCardFormatService.export_character_v2(project, character_id)
		var injected := _inject_png_text(
			placeholder.save_png_to_buffer(), CHARACTER_PNG_KEY,
			Marshalls.utf8_to_base64(JSON.stringify(card))
		)
		if not bool(injected.get("ok", false)):
			return injected
		png_bytes = injected.get("bytes", PackedByteArray())
	return {"ok": true, "avatar_base64": Marshalls.raw_to_base64(png_bytes)}


static func _portrait_path(project: Dictionary, character_id: String) -> String:
	var character := CCFStorageService.get_character(project, character_id)
	var assets = character.get("assets", {})
	if not assets is Dictionary:
		return ""
	var path := str(assets.get("portrait", "")).strip_edges()
	if path.is_empty():
		return ""
	if not path.begins_with("user://") and not path.is_absolute_path():
		path = CCFStorageService.project_folder(str(project.get("project_id", ""))).path_join(path)
	return path if FileAccess.file_exists(path) else ""


static func _build_group_cover(payload: Dictionary) -> Dictionary:
	var raw_members = payload.get("raw_member_data", [])
	var count: int = raw_members.size()
	var columns := ceili(sqrt(float(count)))
	var rows := ceili(float(count) / float(columns))
	var cover := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	cover.fill(Color("172033"))
	var cell_width := 1024 / columns
	var cell_height := 1024 / rows
	for index in range(count):
		var raw_member: Dictionary = raw_members[index]
		var portrait := Image.new()
		if portrait.load_png_from_buffer(Marshalls.base64_to_raw(str(raw_member.get("avatar_base64", "")))) != OK:
			continue
		portrait.resize(cell_width, cell_height, Image.INTERPOLATE_LANCZOS)
		cover.blit_rect(
			portrait,
			Rect2i(0, 0, cell_width, cell_height),
			Vector2i((index % columns) * cell_width, int(index / columns) * cell_height)
		)
	return {"ok": true, "bytes": cover.save_png_to_buffer()}


static func _baseline_realism(character_ids: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for character_id in character_ids:
		result[character_id] = {"affection": 35, "trust": 40, "emotion": "neutral",
			"emotionIntensity": "mild", "timeOfDay": "morning", "dayCount": 1}
	return result


static func _default_realism(character_ids: Array[String]) -> Dictionary:
	var per_character: Dictionary = {}
	for character_id in character_ids:
		per_character[character_id] = _neutral_realism_seed()
	return {"perChar": per_character, "timeOfDay": "morning", "dayCount": 1}


static func _neutral_realism_seed() -> Dictionary:
	return {
		"affection": 35, "trust": 40, "emotion": "neutral", "emotionIntensity": "mild",
		"timeOfDay": "morning", "dayCount": 1,
		"needs": {"hunger": 75, "bladder": 80, "energy": 80, "social": 65,
			"fun": 65, "hygiene": 75, "comfort": 70},
		"enjoysLowHygiene": false, "verificationEnabled": false,
		"verificationMaxReprocesses": 1, "verificationStrictness": 3,
		"needsDirectorAuthority": false, "needsSimStrength": 1,
		"needsBaselineHunger": 80, "needsBaselineBladder": 80,
		"needsBaselineEnergy": 80, "needsBaselineSocial": 80,
		"needsBaselineFun": 80, "needsBaselineHygiene": 80,
		"needsBaselineComfort": 80, "needsDecayHunger": 5,
		"needsDecayBladder": 5, "needsDecayEnergy": 5, "needsDecaySocial": 5,
		"needsDecayFun": 5, "needsDecayHygiene": 5, "needsDecayComfort": 5,
		"relationships": {}
	}


static func _id_dictionary(value: Variant, character_ids: Array[String], default_value: Variant) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	var result: Dictionary = {}
	for character_id in character_ids:
		result[character_id] = source.get(character_id, default_value).duplicate(true) if source.get(character_id, default_value) is Array or source.get(character_id, default_value) is Dictionary else source.get(character_id, default_value)
	return result


static func _json_object_string(value: Variant, fallback: Dictionary) -> String:
	var text := str(value).strip_edges()
	return text if JSON.parse_string(text) is Dictionary else JSON.stringify(fallback)


static func _turn_order(value: Variant) -> String:
	var requested := str(value)
	return requested if requested in VALID_TURN_ORDERS else "roundRobin"


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var text := str(item).strip_edges()
			if not text.is_empty() and text not in result:
				result.append(text)
	return result


static func _remap_json_text(text: String, id_map: Dictionary) -> String:
	var parsed = JSON.parse_string(text)
	return JSON.stringify(_remap_value(parsed, id_map)) if parsed is Dictionary else text


static func _remap_dictionary_keys(value: Variant, id_map: Dictionary) -> Dictionary:
	if not value is Dictionary:
		return {}
	var result: Dictionary = {}
	for raw_key in value:
		var key := str(raw_key)
		result[str(id_map.get(key, key))] = _remap_value(value[raw_key], id_map)
	return result


static func _remap_value(value: Variant, id_map: Dictionary) -> Variant:
	if value is Dictionary:
		return _remap_dictionary_keys(value, id_map)
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_remap_value(item, id_map))
		return result
	if value is String:
		return str(id_map.get(value, value))
	return value


static func _inject_png_text(bytes: PackedByteArray, keyword: String, text: String) -> Dictionary:
	if not _has_png_signature(bytes):
		return {"ok": false, "error": "The source image is not a valid PNG."}
	var output := PackedByteArray()
	output.append_array(PNG_SIGNATURE)
	var offset := 8
	var inserted := false
	while offset + 12 <= bytes.size():
		var length := _read_u32_be(bytes, offset)
		if length < 0 or offset + 12 + length > bytes.size():
			return {"ok": false, "error": "The PNG chunk table is malformed."}
		var chunk_type := bytes.slice(offset + 4, offset + 8).get_string_from_ascii()
		var chunk_data := bytes.slice(offset + 8, offset + 8 + length)
		var skip := false
		if chunk_type == "tEXt":
			skip = str(_parse_text_chunk(chunk_data).get("keyword", "")).to_lower() == keyword.to_lower()
		if chunk_type == "IEND" and not inserted:
			output.append_array(_make_text_chunk(keyword, text))
			inserted = true
		if not skip:
			output.append_array(bytes.slice(offset, offset + 12 + length))
		if chunk_type == "IEND":
			break
		offset += 12 + length
	return {"ok": inserted, "bytes": output,
		"error": "The PNG does not contain a valid IEND chunk." if not inserted else ""}


static func _read_png_text(bytes: PackedByteArray, keyword: String) -> Dictionary:
	if not _has_png_signature(bytes):
		return {"ok": false, "error": "The selected file is not a valid PNG."}
	var offset := 8
	while offset + 12 <= bytes.size():
		var length := _read_u32_be(bytes, offset)
		if length < 0 or offset + 12 + length > bytes.size():
			return {"ok": false, "error": "The PNG chunk table is malformed."}
		var chunk_type := bytes.slice(offset + 4, offset + 8).get_string_from_ascii()
		var chunk_data := bytes.slice(offset + 8, offset + 8 + length)
		if chunk_type == "tEXt":
			var parsed := _parse_text_chunk(chunk_data)
			if str(parsed.get("keyword", "")).to_lower() == keyword.to_lower():
				return {"ok": true, "text": str(parsed.get("text", ""))}
		if chunk_type == "IEND":
			break
		offset += 12 + length
	return {"ok": false, "error": "No '%s' metadata chunk was found in this PNG." % keyword}


static func _png_has_text_key(bytes: PackedByteArray, keyword: String) -> bool:
	return bool(_read_png_text(bytes, keyword).get("ok", false))


static func _has_png_signature(bytes: PackedByteArray) -> bool:
	return bytes.size() >= PNG_SIGNATURE.size() and bytes.slice(0, PNG_SIGNATURE.size()) == PNG_SIGNATURE


static func _read_u32_be(bytes: PackedByteArray, offset: int) -> int:
	if offset < 0 or offset + 4 > bytes.size():
		return -1
	return ((int(bytes[offset]) << 24) | (int(bytes[offset + 1]) << 16) |
		(int(bytes[offset + 2]) << 8) | int(bytes[offset + 3]))


static func _append_u32_be(target: PackedByteArray, value: int) -> void:
	target.append((value >> 24) & 0xff)
	target.append((value >> 16) & 0xff)
	target.append((value >> 8) & 0xff)
	target.append(value & 0xff)


static func _parse_text_chunk(data: PackedByteArray) -> Dictionary:
	var separator := data.find(0)
	if separator < 0:
		return {"keyword": "", "text": ""}
	return {"keyword": data.slice(0, separator).get_string_from_ascii(),
		"text": data.slice(separator + 1).get_string_from_ascii()}


static func _make_text_chunk(keyword: String, content: String) -> PackedByteArray:
	var chunk_type := "tEXt".to_ascii_buffer()
	var chunk_data := PackedByteArray()
	chunk_data.append_array(keyword.to_ascii_buffer())
	chunk_data.append(0)
	chunk_data.append_array(content.to_ascii_buffer())
	var crc_input := PackedByteArray()
	crc_input.append_array(chunk_type)
	crc_input.append_array(chunk_data)
	var output := PackedByteArray()
	_append_u32_be(output, chunk_data.size())
	output.append_array(chunk_type)
	output.append_array(chunk_data)
	_append_u32_be(output, _crc32(crc_input))
	return output


static func _crc32(bytes: PackedByteArray) -> int:
	var crc: int = 0xffffffff
	for byte_value in bytes:
		crc ^= int(byte_value)
		for _bit_index in range(8):
			crc = (crc >> 1) ^ 0xedb88320 if (crc & 1) != 0 else crc >> 1
	return (crc ^ 0xffffffff) & 0xffffffff
