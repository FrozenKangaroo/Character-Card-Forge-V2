class_name CCFFrontPorchAvatarGalleryServiceV0175
extends RefCounted

const GALLERY_KEY := "front_porch_avatar_gallery"
const GALLERY_FORMAT_VERSION := 1
const PACK_TYPE := "character_card_forge_expression_pack"
const PACK_FORMAT_VERSION := 1
const MANIFEST_ENTRY := "ccf-expression-pack.json"
const MAX_FRONT_PORCH_IMAGES := 30
const PORTRAIT_FAVOURITE_ID := "__portrait__"
const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
const EMOTION_LABELS := [
	"admiration", "affection", "amusement", "anger", "annoyance",
	"anticipation", "approval", "caring", "confusion", "curiosity",
	"desire", "disappointment", "disapproval", "disgust", "embarrassment",
	"excitement", "fear", "gratitude", "grief", "joy", "love",
	"nervousness", "optimism", "pride", "realization", "relief", "remorse",
	"sadness", "surprise", "neutral"
]


static func capabilities() -> Dictionary:
	return {
		"format_version": GALLERY_FORMAT_VERSION,
		"manual_image_import": true,
		"image_studio_sources": true,
		"multiple_looks": true,
		"expression_labels": EMOTION_LABELS.duplicate(),
		"canonical_favourite": true,
		"portrait_assignment_separate": true,
		"portable_expression_zip": true,
		"front_porch_api_install": true,
		"raw_database_writes": false
	}


static func gallery_for_character(character: Dictionary) -> Dictionary:
	var assets_value: Variant = character.get("assets", {})
	var assets: Dictionary = (
		(assets_value as Dictionary) if assets_value is Dictionary else {}
	)
	var raw_value: Variant = assets.get(GALLERY_KEY, {})
	var gallery: Dictionary = (
		(raw_value as Dictionary).duplicate(true) if raw_value is Dictionary else {}
	)
	gallery["format_version"] = GALLERY_FORMAT_VERSION
	var entries: Array = []
	var seen_ids: Dictionary = {}
	for raw_entry in gallery.get("entries", []):
		if not raw_entry is Dictionary:
			continue
		var entry := _normalise_entry(raw_entry)
		var gallery_id := str(entry.get("gallery_id", ""))
		if entry.is_empty() or seen_ids.has(gallery_id):
			continue
		seen_ids[gallery_id] = true
		entries.append(entry)
	gallery["entries"] = entries
	var favourite_id := str(gallery.get("favourite_gallery_id", "")).strip_edges()
	if not favourite_id.is_empty() and not seen_ids.has(favourite_id):
		favourite_id = ""
	gallery["favourite_gallery_id"] = favourite_id
	return gallery


static func entries_for_character(character: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_entry in gallery_for_character(character).get("entries", []):
		if raw_entry is Dictionary:
			result.append((raw_entry as Dictionary).duplicate(true))
	return result


static func available_sources(project: Dictionary, character_id: String) -> Array[Dictionary]:
	var character := CCFStorageService.get_character(project, character_id)
	if character.is_empty():
		return []
	var result: Array[Dictionary] = []
	var assets_value: Variant = character.get("assets", {})
	if not assets_value is Dictionary:
		return result
	var assets := assets_value as Dictionary
	var seen_paths: Dictionary = {}
	var portrait := str(assets.get("portrait", "")).strip_edges()
	if not portrait.is_empty() and not _resolve_project_path(project, portrait).is_empty():
		seen_paths[portrait] = true
		result.append({
			"kind": "portrait",
			"path": portrait,
			"label": "Current portrait — %s" % portrait.get_file(),
			"source_record": {"origin": "portrait"}
		})
	var generated_value: Variant = assets.get("generated_images", [])
	if generated_value is Array:
		for raw_record in generated_value:
			var record := _normalise_generated_record(raw_record)
			if record.is_empty():
				continue
			var path := str(record.get("path", ""))
			if _resolve_project_path(project, path).is_empty():
				continue
			if seen_paths.has(path):
				continue
			seen_paths[path] = true
			result.append({
				"kind": "image_studio",
				"path": path,
				"label": _source_label(record),
				"source_record": record
			})
	return result


static func add_source(
	project: Dictionary,
	character_id: String,
	source: Dictionary,
	entry_kind: String,
	emotion_label := ""
) -> Dictionary:
	var path := str(source.get("path", "")).strip_edges()
	if _resolve_project_path(project, path).is_empty():
		return {"ok": false, "error": "The selected source image is unavailable."}
	return _add_entry(
		project,
		character_id,
		path,
		entry_kind,
		emotion_label,
		_provenance_from_source(source)
	)


static func import_image(
	project: Dictionary,
	character_id: String,
	source_path: String,
	entry_kind: String,
	emotion_label := ""
) -> Dictionary:
	if not FileAccess.file_exists(source_path):
		return {"ok": false, "error": "The selected image file does not exist."}
	var validation := _validate_kind_and_label(entry_kind, emotion_label)
	if not bool(validation.get("ok", false)):
		return validation
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		return {"ok": false, "error": "The selected file is not a readable image."}
	var relative_path := _managed_relative_path(character_id, entry_kind)
	var destination := _absolute_project_path(project, relative_path)
	DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
	var save_error := image.save_png(destination)
	if save_error != OK:
		return {"ok": false, "error": "Could not copy the image into this project."}
	return _add_entry(
		project,
		character_id,
		relative_path,
		entry_kind,
		emotion_label,
		{
			"origin": "manual_import",
			"source_filename": source_path.get_file(),
			"imported_at": Time.get_datetime_string_from_system(true)
		}
	)


static func import_expression_zip(
	project: Dictionary, character_id: String, source_path: String
) -> Dictionary:
	var reader := ZIPReader.new()
	var open_error := reader.open(source_path)
	if open_error != OK:
		return {"ok": false, "error": "Could not open the expression ZIP."}
	var working := project.duplicate(true)
	var imported := 0
	var unrecognised := 0
	var skipped := 0
	for entry_path_value in reader.get_files():
		var entry_path := str(entry_path_value)
		if entry_path.ends_with("/"):
			continue
		var extension := entry_path.get_extension().to_lower()
		if extension not in IMAGE_EXTENSIONS:
			continue
		var label := expression_label_for_filename(entry_path.get_file())
		if label.is_empty():
			unrecognised += 1
			continue
		if _expression_count(CCFStorageService.get_character(
			working, character_id
		)) >= MAX_FRONT_PORCH_IMAGES:
			skipped += 1
			continue
		var image := _image_from_bytes(reader.read_file(entry_path), extension)
		if image == null or image.is_empty():
			unrecognised += 1
			continue
		var relative_path := _managed_relative_path(character_id, "expression")
		var destination := _absolute_project_path(working, relative_path)
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		if image.save_png(destination) != OK:
			skipped += 1
			continue
		var added := _add_entry(
			working,
			character_id,
			relative_path,
			"expression",
			label,
			{
				"origin": "sprite_pack",
				"source_pack": source_path.get_file(),
				"source_entry": entry_path,
				"imported_at": Time.get_datetime_string_from_system(true)
			}
		)
		if bool(added.get("ok", false)):
			working = added.get("project", working)
			imported += 1
		else:
			skipped += 1
	reader.close()
	return {
		"ok": imported > 0,
		"project": working,
		"imported": imported,
		"unrecognised": unrecognised,
		"skipped": skipped,
		"error": "No recognised Front Porch expression images were found." if imported == 0 else ""
	}


static func export_expression_zip(
	project: Dictionary, character_id: String, destination_path: String
) -> Dictionary:
	var character := CCFStorageService.get_character(project, character_id)
	if character.is_empty():
		return {"ok": false, "error": "The active character could not be found."}
	var expressions: Array[Dictionary] = []
	for entry in entries_for_character(character):
		if str(entry.get("kind", "")) == "expression":
			expressions.append(entry)
	if expressions.is_empty():
		return {"ok": false, "error": "Add at least one expression before exporting a pack."}
	var writer := ZIPPacker.new()
	var open_error := writer.open(destination_path)
	if open_error != OK:
		return {"ok": false, "error": "Could not create the expression ZIP."}
	var counts: Dictionary = {}
	var exported_entries: Array = []
	for entry in expressions:
		var source_path := _resolve_project_path(project, str(entry.get("path", "")))
		if source_path.is_empty():
			continue
		var label := str(entry.get("label", "neutral"))
		var count := int(counts.get(label, 0)) + 1
		counts[label] = count
		var filename := "%s.png" % label if count == 1 else "%s-%d.png" % [label, count]
		var image := Image.load_from_file(source_path)
		if image == null or image.is_empty():
			continue
		var bytes := image.save_png_to_buffer()
		if _write_zip_entry(writer, "expressions/%s" % filename, bytes) != OK:
			writer.close()
			return {"ok": false, "error": "Could not write an expression image into the ZIP."}
		exported_entries.append({
			"gallery_id": entry.get("gallery_id", ""),
			"label": label,
			"file": "expressions/%s" % filename,
			"provenance": entry.get("provenance", {}).duplicate(true)
		})
	var manifest := {
		"package_type": PACK_TYPE,
		"package_format_version": PACK_FORMAT_VERSION,
		"application": "Character Card Forge",
		"application_version": "0.17.5",
		"created_at": Time.get_datetime_string_from_system(true),
		"character_name": CCFStorageService.character_display_name(character),
		"expression_count": exported_entries.size(),
		"entries": exported_entries
	}
	if _write_zip_entry(
		writer, MANIFEST_ENTRY, JSON.stringify(manifest, "  ").to_utf8_buffer()
	) != OK:
		writer.close()
		return {"ok": false, "error": "Could not write the expression-pack manifest."}
	writer.close()
	if exported_entries.is_empty():
		return {"ok": false, "error": "None of the expression image files were available."}
	return {"ok": true, "path": destination_path, "manifest": manifest}


static func set_favourite(
	project: Dictionary, character_id: String, gallery_id: String
) -> Dictionary:
	var character_index := CCFStorageService.character_index(project, character_id)
	if character_index < 0:
		return {"ok": false, "error": "The active character could not be found."}
	var updated := project.duplicate(true)
	var characters: Array = updated.get("characters", [])
	var character: Dictionary = (characters[character_index] as Dictionary).duplicate(true)
	var gallery := gallery_for_character(character)
	var target := gallery_id.strip_edges()
	if target == PORTRAIT_FAVOURITE_ID:
		target = ""
	if not target.is_empty():
		var found := false
		for entry in gallery.get("entries", []):
			if str(entry.get("gallery_id", "")) == target:
				found = true
				break
		if not found:
			return {"ok": false, "error": "The selected gallery entry no longer exists."}
	gallery["favourite_gallery_id"] = target
	_set_character_gallery(character, gallery)
	characters[character_index] = character
	updated["characters"] = characters
	return {"ok": true, "project": updated, "favourite_gallery_id": target}


static func set_portrait(
	project: Dictionary, character_id: String, gallery_id: String
) -> Dictionary:
	var entry := entry_by_id(project, character_id, gallery_id)
	if entry.is_empty():
		return {"ok": false, "error": "The selected gallery entry no longer exists."}
	var updated := project.duplicate(true)
	var character_index := CCFStorageService.character_index(updated, character_id)
	var characters: Array = updated.get("characters", [])
	var character: Dictionary = (characters[character_index] as Dictionary).duplicate(true)
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	assets["portrait"] = str(entry.get("path", ""))
	character["assets"] = assets
	characters[character_index] = character
	updated["characters"] = characters
	return {"ok": true, "project": updated, "entry": entry}


static func remove_entry(
	project: Dictionary, character_id: String, gallery_id: String
) -> Dictionary:
	var character_index := CCFStorageService.character_index(project, character_id)
	if character_index < 0:
		return {"ok": false, "error": "The active character could not be found."}
	var updated := project.duplicate(true)
	var characters: Array = updated.get("characters", [])
	var character: Dictionary = (characters[character_index] as Dictionary).duplicate(true)
	var gallery := gallery_for_character(character)
	var remaining: Array = []
	var removed := false
	for entry in gallery.get("entries", []):
		if str(entry.get("gallery_id", "")) == gallery_id:
			removed = true
			continue
		remaining.append(entry)
	if not removed:
		return {"ok": false, "error": "The selected gallery entry no longer exists."}
	gallery["entries"] = remaining
	if str(gallery.get("favourite_gallery_id", "")) == gallery_id:
		gallery["favourite_gallery_id"] = ""
	_set_character_gallery(character, gallery)
	characters[character_index] = character
	updated["characters"] = characters
	return {"ok": true, "project": updated}


static func entry_by_id(
	project: Dictionary, character_id: String, gallery_id: String
) -> Dictionary:
	var character := CCFStorageService.get_character(project, character_id)
	for entry in entries_for_character(character):
		if str(entry.get("gallery_id", "")) == gallery_id:
			return entry
	return {}


static func expression_label_for_filename(filename: String) -> String:
	var base := filename.get_file().get_basename().to_lower()
	for label in EMOTION_LABELS:
		if (
			base == label
			or base.begins_with("%s-" % label)
			or base.begins_with("%s." % label)
			or base.begins_with("%s_" % label)
		):
			return label
	return ""


static func _add_entry(
	project: Dictionary,
	character_id: String,
	path: String,
	entry_kind: String,
	emotion_label: String,
	provenance: Dictionary
) -> Dictionary:
	var validation := _validate_kind_and_label(entry_kind, emotion_label)
	if not bool(validation.get("ok", false)):
		return validation
	var character_index := CCFStorageService.character_index(project, character_id)
	if character_index < 0:
		return {"ok": false, "error": "The active character could not be found."}
	var updated := project.duplicate(true)
	var characters: Array = updated.get("characters", [])
	var character: Dictionary = (characters[character_index] as Dictionary).duplicate(true)
	var gallery := gallery_for_character(character)
	var entries: Array = gallery.get("entries", []).duplicate(true)
	if (
		entry_kind == "expression"
		and _expression_count(character) >= MAX_FRONT_PORCH_IMAGES
	):
		return {
			"ok": false,
			"error": "Front Porch supports up to %d expressions per character." % MAX_FRONT_PORCH_IMAGES
		}
	for existing in entries:
		if (
			str(existing.get("path", "")) == path
			and str(existing.get("kind", "")) == entry_kind
			and str(existing.get("label", "")) == emotion_label
		):
			return {"ok": false, "error": "That image already has the same Front Porch role."}
	var gallery_id := "gallery_%s_%s" % [
		int(Time.get_unix_time_from_system()), randi_range(100000, 999999)
	]
	var entry := {
		"gallery_id": gallery_id,
		"kind": entry_kind,
		"label": emotion_label if entry_kind == "expression" else "",
		"path": path,
		"created_at": Time.get_datetime_string_from_system(true),
		"provenance": provenance.duplicate(true)
	}
	entries.append(entry)
	gallery["entries"] = entries
	_set_character_gallery(character, gallery)
	characters[character_index] = character
	updated["characters"] = characters
	return {"ok": true, "project": updated, "entry": entry}


static func _set_character_gallery(character: Dictionary, gallery: Dictionary) -> void:
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	assets[GALLERY_KEY] = gallery
	character["assets"] = assets


static func _expression_count(character: Dictionary) -> int:
	var count := 0
	for entry in entries_for_character(character):
		if str(entry.get("kind", "")) == "expression":
			count += 1
	return count


static func _normalise_entry(raw_entry: Dictionary) -> Dictionary:
	var entry := raw_entry.duplicate(true)
	var path := str(entry.get("path", "")).strip_edges()
	var entry_kind := str(entry.get("kind", "")).strip_edges().to_lower()
	var label := str(entry.get("label", "")).strip_edges().to_lower()
	if path.is_empty() or entry_kind not in ["look", "expression"]:
		return {}
	if entry_kind == "expression" and label not in EMOTION_LABELS:
		return {}
	entry["path"] = path
	entry["kind"] = entry_kind
	entry["label"] = label if entry_kind == "expression" else ""
	var gallery_id := str(entry.get("gallery_id", "")).strip_edges()
	if gallery_id.is_empty():
		gallery_id = "gallery_%s" % ("%s:%s:%s" % [path, entry_kind, label]).sha256_text().left(20)
	entry["gallery_id"] = gallery_id
	if not entry.get("provenance", {}) is Dictionary:
		entry["provenance"] = {}
	return entry


static func _normalise_generated_record(raw_record: Variant) -> Dictionary:
	if raw_record is Dictionary:
		return (raw_record as Dictionary).duplicate(true)
	var path := str(raw_record).strip_edges()
	return {"path": path} if not path.is_empty() else {}


static func _source_label(record: Dictionary) -> String:
	var path := str(record.get("path", ""))
	var label := "Image Studio — %s" % path.get_file()
	var created_at := str(record.get("created_at", "")).strip_edges()
	if not created_at.is_empty():
		label += " — %s" % created_at.replace("T", " ")
	return label


static func _provenance_from_source(source: Dictionary) -> Dictionary:
	var source_record_value: Variant = source.get("source_record", {})
	var source_record: Dictionary = (
		(source_record_value as Dictionary) if source_record_value is Dictionary else {}
	)
	var provenance := {
		"origin": str(source.get("kind", "existing_asset")),
		"source_image_id": str(source_record.get("image_id", "")),
		"linked_at": Time.get_datetime_string_from_system(true)
	}
	var generation_keys := [
		"created_at", "provider", "backend", "profile_id", "profile_name", "model",
		"size", "prompt_style", "prompt", "negative_prompt", "sampler", "steps",
		"cfg_scale", "seed", "generation_mode", "source_image_id", "width", "height"
	]
	var generation: Dictionary = {}
	for key in generation_keys:
		if source_record.has(key):
			generation[key] = source_record.get(key)
	if not generation.is_empty():
		provenance["image_studio"] = generation
	return provenance


static func _validate_kind_and_label(entry_kind: String, emotion_label: String) -> Dictionary:
	if entry_kind not in ["look", "expression"]:
		return {"ok": false, "error": "Choose Look or Expression."}
	if entry_kind == "expression" and emotion_label not in EMOTION_LABELS:
		return {"ok": false, "error": "Choose one of Front Porch's supported expression labels."}
	return {"ok": true}


static func _managed_relative_path(character_id: String, entry_kind: String) -> String:
	return "characters/%s/avatar_gallery/%s_%s_%s.png" % [
		character_id,
		entry_kind,
		int(Time.get_unix_time_from_system()),
		randi_range(100000, 999999)
	]


static func _absolute_project_path(project: Dictionary, relative_path: String) -> String:
	return ProjectSettings.globalize_path(
		CCFStorageService.project_folder(str(project.get("project_id", ""))).path_join(relative_path)
	)


static func _resolve_project_path(project: Dictionary, stored_path: String) -> String:
	var clean := stored_path.strip_edges()
	if clean.is_empty():
		return ""
	var candidate := clean
	if not clean.is_absolute_path() and not clean.begins_with("user://") and not clean.begins_with("res://"):
		candidate = CCFStorageService.project_folder(
			str(project.get("project_id", ""))
		).path_join(clean)
	return candidate if FileAccess.file_exists(candidate) else ""


static func _image_from_bytes(bytes: PackedByteArray, extension: String) -> Image:
	var image := Image.new()
	var load_error := ERR_FILE_UNRECOGNIZED
	match extension:
		"png":
			load_error = image.load_png_from_buffer(bytes)
		"jpg", "jpeg":
			load_error = image.load_jpg_from_buffer(bytes)
		"webp":
			load_error = image.load_webp_from_buffer(bytes)
	return image if load_error == OK else null


static func _write_zip_entry(
	writer: ZIPPacker, entry_path: String, data: PackedByteArray
) -> Error:
	var start_error := writer.start_file(entry_path)
	if start_error != OK:
		return start_error
	var write_error := writer.write_file(data)
	if write_error != OK:
		return write_error
	return writer.close_file()
