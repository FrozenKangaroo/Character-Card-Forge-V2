class_name CCFImagePromptComposerServiceV0162
extends RefCounted

const CATALOG_PATH := "res://data/image_prompt_catalog_v1.json"
const CATALOG_FORMAT_VERSION := 1


static func load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {"ok": false, "error": "Creative prompt catalog is missing.", "catalog": {}}
	var source := FileAccess.get_file_as_string(CATALOG_PATH)
	var parsed: Variant = JSON.parse_string(source)
	if not parsed is Dictionary:
		return {"ok": false, "error": "Creative prompt catalog is not valid JSON.", "catalog": {}}
	var catalog: Dictionary = parsed
	if int(catalog.get("format_version", 0)) != CATALOG_FORMAT_VERSION:
		return {
			"ok": false,
			"error": "Unsupported creative prompt catalog format version.",
			"catalog": catalog
		}
	if not catalog.get("categories", []) is Array or not catalog.get("modifiers", []) is Array:
		return {"ok": false, "error": "Creative prompt catalog is missing required collections.", "catalog": catalog}
	return {"ok": true, "error": "", "catalog": catalog}


static func default_selection(catalog: Dictionary) -> Dictionary:
	var selections := {"categories": {}, "modifiers": []}
	for category_variant in catalog.get("categories", []):
		if not category_variant is Dictionary:
			continue
		var category: Dictionary = category_variant
		var category_id := str(category.get("id", "")).strip_edges()
		if category_id.is_empty():
			continue
		var first_id := "none"
		var options: Array = category.get("options", [])
		if not options.is_empty() and options[0] is Dictionary:
			first_id = str((options[0] as Dictionary).get("id", "none"))
		selections["categories"][category_id] = first_id
	return selections


static func compose(base_prompt: String, selections: Dictionary, catalog: Dictionary) -> Dictionary:
	var base := base_prompt.strip_edges().trim_suffix(",").strip_edges()
	var phrases: Array[String] = []
	if not base.is_empty():
		phrases.append(base)

	var selected_categories: Dictionary = (
		selections.get("categories", {}) if selections.get("categories", {}) is Dictionary else {}
	)
	for category_variant in catalog.get("categories", []):
		if not category_variant is Dictionary:
			continue
		var category: Dictionary = category_variant
		var category_id := str(category.get("id", ""))
		var option_id := str(selected_categories.get(category_id, "none"))
		var phrase := _prompt_for_option(category.get("options", []), option_id)
		_append_unique_phrase(phrases, phrase)

	var selected_modifiers: Array = (
		selections.get("modifiers", []) if selections.get("modifiers", []) is Array else []
	)
	for modifier_id_variant in selected_modifiers:
		var modifier_phrase := _prompt_for_option(catalog.get("modifiers", []), str(modifier_id_variant))
		_append_unique_phrase(phrases, modifier_phrase)

	var composed := ", ".join(phrases)
	return {
		"prompt": composed,
		"contributions": contribution_rows(selections, catalog),
		"selection": selections.duplicate(true)
	}


static func contribution_rows(selections: Dictionary, catalog: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var selected_categories: Dictionary = (
		selections.get("categories", {}) if selections.get("categories", {}) is Dictionary else {}
	)
	for category_variant in catalog.get("categories", []):
		if not category_variant is Dictionary:
			continue
		var category: Dictionary = category_variant
		var category_id := str(category.get("id", ""))
		var option_id := str(selected_categories.get(category_id, "none"))
		var option := _option_by_id(category.get("options", []), option_id)
		if option.is_empty() or str(option.get("prompt", "")).strip_edges().is_empty():
			continue
		rows.append({
			"category_id": category_id,
			"category": str(category.get("label", category_id)),
			"option_id": option_id,
			"label": str(option.get("label", option_id)),
			"prompt": str(option.get("prompt", ""))
		})

	var selected_modifiers: Array = (
		selections.get("modifiers", []) if selections.get("modifiers", []) is Array else []
	)
	for modifier_id_variant in selected_modifiers:
		var modifier_id := str(modifier_id_variant)
		var modifier := _option_by_id(catalog.get("modifiers", []), modifier_id)
		if modifier.is_empty():
			continue
		rows.append({
			"category_id": "modifier",
			"category": "Modifier",
			"option_id": modifier_id,
			"label": str(modifier.get("label", modifier_id)),
			"prompt": str(modifier.get("prompt", ""))
		})
	return rows


static func selection_is_valid(selections: Dictionary, catalog: Dictionary) -> bool:
	var selected_categories: Dictionary = (
		selections.get("categories", {}) if selections.get("categories", {}) is Dictionary else {}
	)
	for category_variant in catalog.get("categories", []):
		if not category_variant is Dictionary:
			continue
		var category: Dictionary = category_variant
		var category_id := str(category.get("id", ""))
		if category_id.is_empty():
			continue
		var option_id := str(selected_categories.get(category_id, "none"))
		if _option_by_id(category.get("options", []), option_id).is_empty():
			return false
	var valid_modifier_ids: Dictionary = {}
	for modifier_variant in catalog.get("modifiers", []):
		if modifier_variant is Dictionary:
			valid_modifier_ids[str((modifier_variant as Dictionary).get("id", ""))] = true
	for modifier_id_variant in selections.get("modifiers", []):
		if not valid_modifier_ids.has(str(modifier_id_variant)):
			return false
	return true


static func _prompt_for_option(options_variant: Variant, option_id: String) -> String:
	var option := _option_by_id(options_variant, option_id)
	return str(option.get("prompt", "")).strip_edges()


static func _option_by_id(options_variant: Variant, option_id: String) -> Dictionary:
	if not options_variant is Array:
		return {}
	for option_variant in options_variant:
		if not option_variant is Dictionary:
			continue
		var option: Dictionary = option_variant
		if str(option.get("id", "")) == option_id:
			return option
	return {}


static func _append_unique_phrase(phrases: Array[String], phrase: String) -> void:
	var clean := phrase.strip_edges().trim_suffix(",").strip_edges()
	if clean.is_empty():
		return
	var clean_lower := clean.to_lower()
	for existing in phrases:
		if existing.to_lower().contains(clean_lower):
			return
	phrases.append(clean)
