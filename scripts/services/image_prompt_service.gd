class_name CCFImagePromptService
extends RefCounted

const LOCATION_TAGS := [
	"university classroom",
	"college classroom",
	"classroom",
	"university campus",
	"school hallway",
	"school rooftop",
	"office",
	"apartment",
	"bedroom",
	"living room",
	"kitchen",
	"cafe",
	"coffee shop",
	"restaurant",
	"bar",
	"nightclub",
	"library",
	"gym",
	"train station",
	"train platform",
	"train carriage",
	"train interior",
	"bus stop",
	"street",
	"city street",
	"park",
	"beach",
	"hotel room",
	"hotel lobby",
	"festival",
	"fantasy tavern",
	"forest",
	"garden"
]

const TIME_TAGS := [
	"sunrise",
	"early morning",
	"morning",
	"midday",
	"noon",
	"afternoon",
	"sunset",
	"golden hour",
	"dusk",
	"evening",
	"night",
	"midnight"
]

const WEATHER_TAGS := [
	"rainy",
	"rain",
	"snowy",
	"snow",
	"foggy",
	"fog",
	"overcast",
	"sunny",
	"stormy",
	"storm"
]

const VISIBLE_OBJECT_TAGS := [
	"classroom desks",
	"desks",
	"blackboard",
	"whiteboard",
	"windows",
	"books",
	"bookshelves",
	"laptop",
	"phone",
	"train",
	"railway tracks",
	"platform",
	"streetlights",
	"neon signs",
	"flowers"
]


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
	var character_name := CCFStorageService.character_display_name(character)
	var description := str(character_data.get("description", "")).strip_edges()
	var scenario := str(character_data.get("scenario", "")).strip_edges()
	var extra := extra_direction.strip_edges()
	var resolved_style := prompt_style.strip_edges().to_lower()
	if resolved_style == "stable_diffusion":
		return _build_sd_prompt(character_name, description, scenario, extra)
	return _build_natural_prompt(character_name, description, scenario, extra)


static func _build_sd_prompt(
	character_name: String,
	description: String,
	scenario: String,
	extra_direction: String
) -> String:
	var components := _parse_description_components(description)
	var visual_tags: Array[String] = []
	_append_unique(visual_tags, _subject_tag(description))
	_append_unique(visual_tags, "solo")
	_append_unique(visual_tags, "character focus")

	var age_text := str(components.get("age", "")).strip_edges()
	var age_tag := _age_tag(age_text)
	if not age_tag.is_empty():
		_append_unique(visual_tags, age_tag)

	for key in ["appearance", "outfit style", "outfit", "distinguishing features"]:
		var component_text := str(components.get(key, "")).strip_edges()
		if component_text.is_empty():
			continue
		for tag in _prose_to_visual_tags(component_text, character_name):
			_append_unique(visual_tags, tag)

	if components.is_empty() and not description.is_empty():
		for tag in _prose_to_visual_tags(description, character_name):
			_append_unique(visual_tags, tag)

	for tag in scene_visual_tags(scenario):
		_append_unique(visual_tags, tag)

	for tag in _extra_visual_tags(extra_direction):
		_append_unique(visual_tags, tag)

	if visual_tags.size() <= 3:
		return ""
	_append_unique(visual_tags, "detailed face")
	_append_unique(visual_tags, "detailed eyes")
	return ", ".join(visual_tags)


static func _build_natural_prompt(
	character_name: String,
	description: String,
	scenario: String,
	extra_direction: String
) -> String:
	var scene_tags := scene_visual_tags(scenario)
	if description.is_empty() and scene_tags.is_empty() and extra_direction.is_empty():
		return ""
	var sections: Array[String] = [
		"Create polished character artwork suitable for an AI roleplay character card. Keep the character visually coherent and clearly dominant in the composition."
	]
	if not character_name.is_empty() and character_name != "Untitled Character":
		sections.append("Character: %s." % character_name)
	if not description.is_empty():
		sections.append("Appearance and clothing: %s" % description.left(5000))
	if not scene_tags.is_empty():
		sections.append("Visible setting and atmosphere: %s." % ", ".join(scene_tags))
	if not extra_direction.is_empty():
		sections.append("Additional visual direction: %s" % extra_direction)
	sections.append("Use only visually depictable information. Do not illustrate hidden motives, relationship explanations, internal thoughts, or other nonvisual story summary unless the user explicitly asks for a scene showing them.")
	return "\n\n".join(sections)


static func scene_visual_tags(scenario: String) -> Array[String]:
	var tags: Array[String] = []
	var lower := " " + scenario.to_lower().replace("\n", " ") + " "
	if lower.strip_edges().is_empty():
		return tags

	var location_added := false
	for location in LOCATION_TAGS:
		if lower.contains(str(location).to_lower()):
			_append_unique(tags, str(location))
			location_added = true
			if location in ["university classroom", "college classroom"]:
				break
	if not location_added and lower.contains(" university ") and lower.contains(" classroom "):
		_append_unique(tags, "university classroom")

	for time_tag in TIME_TAGS:
		if lower.contains(str(time_tag).to_lower()):
			_append_unique(tags, str(time_tag))

	if lower.contains("sunset") or lower.contains("golden hour"):
		_append_unique(tags, "warm golden-hour lighting")
		_append_unique(tags, "sunset light through windows" if lower.contains("window") or lower.contains("classroom") else "warm sunset lighting")
	elif lower.contains("sunrise"):
		_append_unique(tags, "soft sunrise lighting")
	elif lower.contains("night") or lower.contains("midnight"):
		_append_unique(tags, "nighttime lighting")
	elif lower.contains("evening") or lower.contains("dusk"):
		_append_unique(tags, "soft evening lighting")

	for weather_tag in WEATHER_TAGS:
		if lower.contains(str(weather_tag).to_lower()):
			_append_unique(tags, str(weather_tag))

	for object_tag in VISIBLE_OBJECT_TAGS:
		if lower.contains(str(object_tag).to_lower()):
			_append_unique(tags, str(object_tag))

	return tags


static func _parse_description_components(description: String) -> Dictionary:
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


static func _age_tag(age_text: String) -> String:
	var clean := age_text.strip_edges().to_lower()
	if clean.is_empty():
		return ""
	var digits := ""
	for character in clean:
		if str(character).is_valid_int():
			digits += str(character)
		elif not digits.is_empty():
			break
	if not digits.is_empty():
		return "%s years old" % digits
	if clean.length() <= 24:
		return clean
	return ""


static func _subject_tag(description: String) -> String:
	var lower := " " + description.to_lower().replace("\n", " ") + " "
	if lower.contains(" she ") or lower.contains(" her "):
		return "1girl"
	if lower.contains(" he ") or lower.contains(" his "):
		return "1boy"
	return "1person"


static func _prose_to_visual_tags(text: String, character_name: String) -> Array[String]:
	var prepared := text.replace("\n", " ")
	prepared = prepared.replace(";", ",").replace(". ", ", ").replace(".", ",")
	prepared = prepared.replace(" falls past her shoulders", ", past-shoulder length hair")
	prepared = prepared.replace(" falls past his shoulders", ", past-shoulder length hair")
	prepared = prepared.replace(" falls to her waist", ", waist-length hair")
	prepared = prepared.replace(" falls to his waist", ", waist-length hair")
	prepared = prepared.replace(" framing a face with ", ", ")
	prepared = prepared.replace(" glows naturally", "")
	prepared = prepared.replace(" is visible ", " ")

	var tags: Array[String] = []
	for raw_fragment in prepared.split(",", false):
		var fragment := _clean_visual_fragment(str(raw_fragment), character_name)
		if fragment.is_empty():
			continue
		for sub_fragment in fragment.split(" and ", false):
			var tag := _clean_visual_fragment(str(sub_fragment), character_name)
			if not tag.is_empty():
				_append_unique(tags, tag)
	return tags


static func _clean_visual_fragment(fragment: String, character_name: String) -> String:
	var value := fragment.strip_edges()
	if value.is_empty():
		return ""
	var lower := value.to_lower()
	for stop_phrase in [" that ", " which ", " when ", " while ", " because ", " so that "]:
		var index := lower.find(stop_phrase)
		if index >= 0:
			value = value.left(index).strip_edges()
			lower = value.to_lower()

	var name_lower := character_name.strip_edges().to_lower()
	var prefixes: Array[String] = []
	if not name_lower.is_empty() and name_lower != "untitled character":
		prefixes.append(name_lower + " has ")
		prefixes.append(name_lower + " is ")
		prefixes.append(name_lower + " wears ")
	for prefix in [
		"she has ", "she is ", "she wears ", "she sports ",
		"he has ", "he is ", "he wears ", "he sports ",
		"they have ", "they are ", "they wear ",
		"her ", "his ", "their "
	]:
		prefixes.append(prefix)
	for prefix in prefixes:
		if lower.begins_with(prefix):
			value = value.substr(prefix.length()).strip_edges()
			lower = value.to_lower()
			break

	for rejected in [
		"asks ", "wants ", "feels ", "thinks ", "believes ", "remembers ",
		"habitually ", "usually fidgets", "often fidgets", "relationship", "boyfriend",
		"girlfriend", "cheating", "motivation", "reason is"
	]:
		if lower.contains(rejected):
			return ""

	value = value.replace("especially ", "").replace("naturally ", "")
	value = value.replace("a pair of ", "").replace("an especially ", "")
	value = value.replace("the ", "") if value.to_lower().begins_with("the ") else value
	value = value.strip_edges().trim_prefix("a ").trim_prefix("an ")
	while value.ends_with(".") or value.ends_with(","):
		value = value.left(value.length() - 1).strip_edges()
	if value.is_empty():
		return ""
	var words := value.split(" ", false)
	if words.size() > 12:
		var shortened: Array[String] = []
		for index in range(12):
			shortened.append(str(words[index]))
		value = " ".join(shortened)
	return value.to_lower()


static func _extra_visual_tags(extra_direction: String) -> Array[String]:
	var clean := extra_direction.strip_edges()
	if clean.is_empty():
		return []
	if not clean.contains(".") and clean.contains(","):
		var tags: Array[String] = []
		for raw_tag in clean.split(",", false):
			var tag := str(raw_tag).strip_edges().to_lower()
			if not tag.is_empty():
				_append_unique(tags, tag)
		return tags
	return _prose_to_visual_tags(clean, "")


static func _append_unique(values: Array[String], value: String) -> void:
	var clean := value.strip_edges()
	if clean.is_empty():
		return
	if not values.has(clean):
		values.append(clean)
