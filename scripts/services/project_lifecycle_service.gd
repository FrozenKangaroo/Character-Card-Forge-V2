class_name CCFProjectLifecycleService
extends RefCounted


static func is_placeholder_character_name(value: String) -> bool:
	var clean := value.strip_edges()
	if clean.is_empty():
		return true
	var lower := clean.to_lower()
	if lower in ["untitled character", "unnamed character", "new character"]:
		return true
	if lower.begins_with("untitled character "):
		var suffix := lower.trim_prefix("untitled character ").strip_edges()
		return suffix.is_valid_int()
	return false


static func first_name(value: String) -> String:
	var clean := value.strip_edges()
	if clean.is_empty():
		return ""
	var parts := clean.split(" ", false)
	return str(parts[0]).strip_edges() if not parts.is_empty() else clean


static func first_character_name(project: Dictionary) -> String:
	var characters = project.get("characters", [])
	if not characters is Array or characters.is_empty() or not characters[0] is Dictionary:
		return ""
	var name := CCFStorageService.character_display_name(characters[0]).strip_edges()
	return "" if is_placeholder_character_name(name) else name


static func automatic_project_name(project: Dictionary) -> String:
	return first_name(first_character_name(project))


static func infer_manual_project_name(project: Dictionary) -> bool:
	var metadata = project.get("metadata", {})
	if not metadata is Dictionary:
		return false
	if metadata.has("name_is_manual"):
		return bool(metadata.get("name_is_manual", false))
	var current := str(metadata.get("name", "")).strip_edges()
	if current.is_empty() or current in ["Untitled Project", "Untitled Character"]:
		return false
	var first_full := first_character_name(project)
	var automatic := automatic_project_name(project)
	return current != automatic and current != first_full


static func sync_project_name(project: Dictionary) -> String:
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	var manual := bool(metadata.get("name_is_manual", infer_manual_project_name(project)))
	var current := str(metadata.get("name", "")).strip_edges()
	if manual and not current.is_empty():
		metadata["name_is_manual"] = true
		project["metadata"] = metadata
		return current
	var automatic := automatic_project_name(project)
	metadata["name_is_manual"] = false
	metadata["name"] = automatic
	project["metadata"] = metadata
	return automatic


static func character_has_meaningful_content(character: Dictionary) -> bool:
	var name := CCFStorageService.character_display_name(character).strip_edges()
	if not is_placeholder_character_name(name):
		return true
	var metadata = character.get("metadata", {})
	if metadata is Dictionary:
		for key in ["summary", "role", "creator", "character_version"]:
			if not str(metadata.get(key, "")).strip_edges().is_empty():
				return true
		if _variant_has_content(metadata.get("tags", [])):
			return true
		if bool(metadata.get("favorite", false)):
			return true
	if _variant_has_content(character.get("concept", {})):
		return true
	var card = character.get("character", {})
	if card is Dictionary:
		for key in card:
			if str(key) == "name":
				continue
			if _variant_has_content(card.get(key)):
				return true
	if _variant_has_content(character.get("assets", {})):
		return true
	if _variant_has_content(character.get("attachments", [])):
		return true
	var workspace = character.get("workspace", {})
	if workspace is Dictionary and _variant_has_content(workspace.get("builder", {})):
		return true
	return false


static func project_has_real_character(project: Dictionary) -> bool:
	var characters = project.get("characters", [])
	if not characters is Array:
		return false
	for character in characters:
		if character is Dictionary and character_has_meaningful_content(character):
			return true
	return false


static func prepare_for_save(project: Dictionary, active_character_id: String) -> Dictionary:
	var characters = project.get("characters", [])
	if not characters is Array:
		return {"ok": false, "empty": true, "error": "This Character Project does not contain a character yet."}
	var kept: Array = []
	var removed_count := 0
	for raw_character in characters:
		if not raw_character is Dictionary:
			removed_count += 1
			continue
		if character_has_meaningful_content(raw_character):
			kept.append(raw_character)
		else:
			removed_count += 1
	if kept.is_empty():
		return {
			"ok": false,
			"empty": true,
			"removed_count": 0,
			"error": "This Character Project is still empty. Add or generate a character before saving it."
		}
	for raw_character in kept:
		var character: Dictionary = raw_character
		var character_name := CCFStorageService.character_display_name(character).strip_edges()
		if is_placeholder_character_name(character_name):
			return {
				"ok": false,
				"empty": false,
				"removed_count": removed_count,
				"error": "Give each character a name before saving. Placeholder names are not stored as real characters."
			}
	project["characters"] = kept
	var next_active := active_character_id
	var active_found := false
	for character in kept:
		if character is Dictionary and str(character.get("character_id", "")) == next_active:
			active_found = true
			break
	if not active_found:
		next_active = str(kept[0].get("character_id", ""))
	var workspace: Dictionary = project.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = next_active
	project["workspace"] = workspace
	sync_project_name(project)
	return {
		"ok": true,
		"empty": false,
		"removed_count": removed_count,
		"active_character_id": next_active
	}


static func _variant_has_content(value: Variant) -> bool:
	if value == null:
		return false
	if value is String:
		return not value.strip_edges().is_empty()
	if value is Array:
		for item in value:
			if _variant_has_content(item):
				return true
		return false
	if value is Dictionary:
		for key in value:
			if _variant_has_content(value.get(key)):
				return true
		return false
	if value is bool:
		return value
	if value is int or value is float:
		return float(value) != 0.0
	return true
