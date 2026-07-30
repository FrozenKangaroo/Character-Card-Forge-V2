class_name CCFImagePromptServiceV0139
extends CCFImagePromptService

const MAX_APPEARANCE_TAGS := 7
const MAX_OUTFIT_TAGS := 3
const MAX_DISTINGUISHING_TAGS := 2
const MAX_SCENE_TAGS := 4
const DISTINGUISHING_THRESHOLD := 10

const NON_IDENTITY_PHRASES := [
	"embarrassed",
	"flustered",
	"mischievous glint",
	"knowing smile",
	"calm smile",
	"observant smile",
	"cataloguing",
	"legacy piece",
	"heirloom",
	"reminder of",
	"symbol of",
	"personality",
	"temperament",
	"mood",
	"emotion",
	"habit of",
	"usually",
	"typically"
]

const OUTFIT_GARMENT_HINTS := [
	"áo dài", "ao dai", "dress", "shirt", "blouse", "top", "skirt", "pants", "trousers",
	"jacket", "coat", "hoodie", "uniform", "suit", "gown", "kimono", "sari", "qipao",
	"cheongsam", "sweater", "jeans", "shorts", "leggings", "swimsuit", "bikini", "lingerie"
]
const OUTFIT_STRUCTURE_HINTS := [
	"collar", "sleeve", "sleeved", "strapless", "high-waisted", "low-cut", "neckline",
	"form-fitting", "fitted", "cuffs"
]
const OUTFIT_MOTIF_HINTS := [
	"embroidery", "embroidered", "lace", "floral", "pattern", "striped", "plaid", "print"
]

static func build_prompt(project: Dictionary, character_id: String, prompt_style: String, extra_direction: String = "") -> String:
	var character := CCFStorageService.get_character(project, character_id)
	if character.is_empty():
		return extra_direction.strip_edges()
	var character_data_value: Variant = character.get("character", {})
	var character_data: Dictionary = character_data_value if character_data_value is Dictionary else {}
	var character_name := CCFStorageService.character_display_name(character)
	var description := str(character_data.get("description", "")).strip_edges()
	var scenario := str(character_data.get("scenario", "")).strip_edges()
	var extra := extra_direction.strip_edges()
	var resolved_style := prompt_style.strip_edges().to_lower()
	if resolved_style == "stable_diffusion":
		return _build_balanced_sd_prompt(character_name, description, scenario, extra)
	return _build_balanced_natural_prompt(character_name, description, scenario, extra)

static func _build_balanced_sd_prompt(character_name: String, description: String, scenario: String, extra_direction: String) -> String:
	var visual_tags: Array[String] = []
	_append_unique(visual_tags, CCFImagePromptService._subject_tag(description))
	_append_unique(visual_tags, "solo")
	_append_unique(visual_tags, "character focus")
	var components := _parse_components(description)
	_append_unique(visual_tags, CCFImagePromptService._age_tag(str(components.get("age", ""))))
	for tag in _limited_component_tags(str(components.get("appearance", "")), character_name, MAX_APPEARANCE_TAGS):
		_append_unique(visual_tags, tag)
	var outfit_text := str(components.get("outfit style", components.get("outfit", "")))
	for tag in _outfit_component_tags(outfit_text, character_name, MAX_OUTFIT_TAGS):
		_append_unique(visual_tags, tag)
	if visual_tags.size() < DISTINGUISHING_THRESHOLD:
		for tag in _limited_component_tags(str(components.get("distinguishing features", "")), character_name, MAX_DISTINGUISHING_TAGS):
			_append_unique(visual_tags, tag)
	if components.is_empty() and not description.is_empty():
		for tag in _limited_component_tags(description, character_name, MAX_APPEARANCE_TAGS + MAX_OUTFIT_TAGS):
			_append_unique(visual_tags, tag)
	var scene_count := 0
	for tag in CCFImagePromptService.scene_visual_tags(scenario):
		if scene_count >= MAX_SCENE_TAGS:
			break
		_append_unique(visual_tags, tag)
		scene_count += 1
	for tag in CCFImagePromptService._extra_visual_tags(extra_direction):
		_append_unique(visual_tags, tag)
	if visual_tags.size() <= 3:
		return ""
	_append_unique(visual_tags, "detailed face")
	_append_unique(visual_tags, "detailed eyes")
	return ", ".join(visual_tags)

static func _build_balanced_natural_prompt(character_name: String, description: String, scenario: String, extra_direction: String) -> String:
	var components := _parse_components(description)
	var core_tags: Array[String] = []
	_append_unique(core_tags, CCFImagePromptService._age_tag(str(components.get("age", ""))))
	for tag in _limited_component_tags(str(components.get("appearance", "")), character_name, MAX_APPEARANCE_TAGS):
		_append_unique(core_tags, tag)
	var outfit_text := str(components.get("outfit style", components.get("outfit", "")))
	for tag in _outfit_component_tags(outfit_text, character_name, MAX_OUTFIT_TAGS):
		_append_unique(core_tags, tag)
	if core_tags.size() < DISTINGUISHING_THRESHOLD:
		for tag in _limited_component_tags(str(components.get("distinguishing features", "")), character_name, MAX_DISTINGUISHING_TAGS):
			_append_unique(core_tags, tag)
	if components.is_empty() and not description.is_empty():
		for tag in _limited_component_tags(description, character_name, MAX_APPEARANCE_TAGS + MAX_OUTFIT_TAGS):
			_append_unique(core_tags, tag)
	var scene_tags: Array[String] = []
	for tag in CCFImagePromptService.scene_visual_tags(scenario):
		if scene_tags.size() >= MAX_SCENE_TAGS:
			break
		_append_unique(scene_tags, tag)
	if core_tags.is_empty() and scene_tags.is_empty() and extra_direction.is_empty():
		return ""
	var sections: Array[String] = ["Create polished character artwork suitable for an AI roleplay character card. Keep the character visually coherent and clearly dominant in the composition."]
	if not character_name.is_empty() and character_name != "Untitled Character":
		sections.append("Character: %s." % character_name)
	if not core_tags.is_empty():
		sections.append("Core visual identity: %s." % ", ".join(core_tags))
	if not scene_tags.is_empty():
		sections.append("Visible setting and atmosphere: %s." % ", ".join(scene_tags))
	if not extra_direction.is_empty():
		sections.append("Additional visual direction: %s" % extra_direction)
	sections.append("Prioritise the stable visual identity over incidental prose. Do not invent symbolic meaning, personality, relationship context, habits, transient expressions, or ceremonial styling that was not explicitly requested.")
	return "\n\n".join(sections)

static func _parse_components(description: String) -> Dictionary:
	var result: Dictionary = {}
	var active_key := ""
	for raw_line in description.split("\n"):
		var line := str(raw_line).strip_edges()
		if line.is_empty():
			continue
		var colon_index := line.find(":")
		if colon_index > 0 and colon_index < 40:
			var possible_key := line.left(colon_index).strip_edges().to_lower()
			if possible_key in ["age", "appearance", "outfit style", "outfit", "distinguishing features"]:
				active_key = possible_key
				result[active_key] = line.substr(colon_index + 1).strip_edges()
				continue
		if not active_key.is_empty():
			var previous := str(result.get(active_key, ""))
			result[active_key] = (previous + " " + line).strip_edges()
	return result

static func _limited_component_tags(text: String, character_name: String, limit: int) -> Array[String]:
	var result: Array[String] = []
	if text.strip_edges().is_empty() or limit <= 0:
		return result
	for raw_tag in CCFImagePromptService._prose_to_visual_tags(text, character_name):
		var tag := _clean_core_visual_tag(str(raw_tag))
		if tag.is_empty() or result.has(tag):
			continue
		result.append(tag)
		if result.size() >= limit:
			break
	return result

static func _outfit_component_tags(text: String, character_name: String, limit: int) -> Array[String]:
	var candidates: Array[String] = []
	if text.strip_edges().is_empty() or limit <= 0:
		return candidates
	for raw_tag in CCFImagePromptService._prose_to_visual_tags(text, character_name):
		var tag := _clean_core_visual_tag(str(raw_tag))
		if tag.is_empty() or _is_low_value_outfit_tag(tag) or candidates.has(tag):
			continue
		candidates.append(tag)

	var result: Array[String] = []
	_append_first_matching(result, candidates, OUTFIT_GARMENT_HINTS)
	if result.size() < limit:
		_append_first_matching(result, candidates, OUTFIT_STRUCTURE_HINTS)
	if result.size() < limit:
		_append_first_matching(result, candidates, OUTFIT_MOTIF_HINTS)
	for candidate in candidates:
		if result.size() >= limit:
			break
		_append_unique(result, candidate)
	return result

static func _append_first_matching(result: Array[String], candidates: Array[String], hints: Array) -> void:
	for candidate in candidates:
		if result.has(candidate):
			continue
		for raw_hint in hints:
			if candidate.contains(str(raw_hint)):
				result.append(candidate)
				return

static func _is_low_value_outfit_tag(tag: String) -> bool:
	var value := tag.strip_edges().to_lower()
	if value.is_empty() or value.begins_with("its "):
		return true
	if value in ["red", "reds", "blue", "blues", "pink", "pinks", "black", "white"]:
		return true
	if value.contains("lower hem") or value.ends_with(" blooming"):
		return true
	return false

static func _clean_core_visual_tag(raw_tag: String) -> String:
	var value := raw_tag.strip_edges().to_lower()
	if value.is_empty():
		return ""
	for marker in [" when ", " whenever ", " often ", " usually ", " typically ", " as if ", " catch the light", " catches the light", " rest on her nose", " rests on her nose", " rest on his nose", " rests on his nose"]:
		var marker_index := value.find(marker)
		if marker_index > 0:
			value = value.left(marker_index).strip_edges()
	for phrase in NON_IDENTITY_PHRASES:
		if value.contains(phrase):
			return ""
	for prefix in ["combination of ", "the combination of ", "a combination of "]:
		if value.begins_with(prefix):
			value = value.substr(prefix.length()).strip_edges()
			break
	return value

static func _append_unique(values: Array[String], value: String) -> void:
	var clean := value.strip_edges()
	if clean.is_empty() or values.has(clean):
		return
	values.append(clean)
