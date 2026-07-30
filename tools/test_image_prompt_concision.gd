extends SceneTree

const IMAGE_PROMPT_SERVICE_V0139 = preload("res://scripts/services/image_prompt_service_v0139.gd")

func _init() -> void:
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var characters: Array = project.get("characters", []).duplicate(true)
	if characters.is_empty() or not characters[0] is Dictionary:
		_fail("new project did not contain a character")
		return
	var character: Dictionary = characters[0].duplicate(true)
	var character_data: Dictionary = character.get("character", {}).duplicate(true)
	character_data["name"] = "Thảo"
	character_data["description"] = "Age: 24\nAppearance: Fair-skinned with a curvy, hourglass build. She has shoulder-length brown hair cut into a soft bob with straight bangs, framing an expressive face. Round wire-rimmed glasses rest on her nose, often adjusted when flustered. Her lips are painted a muted red, and small dangling earrings catch the light. Her expression is typically a calm, observant smile that can slip into a hidden mischievous glint.\nOutfit Style: A pristine white long-sleeved áo dài with a high mandarin collar, its lower hem and side slits blooming with colorful floral embroidery in reds, blues, and pinks. White lace trims the cuffs. A large, ornate jeweled brooch shaped like a flower is pinned at the center of the collar. She wears the traditional loose silk trousers that complete the dress.\nDistinguishing Features: The combination of modern round glasses and a classic embroidered áo dài. The habit of adjusting her glasses when embarrassed. The large floral brooch at her throat, a legacy piece. The way her calm smiles slowly turn knowing, as if she is quietly cataloguing everything about you."
	character_data["scenario"] = "A quiet afternoon in a tucked-away cafe in Hanoi."
	character["character"] = character_data
	characters[0] = character
	project["characters"] = characters

	var sd_prompt: String = IMAGE_PROMPT_SERVICE_V0139.build_prompt(project, character_id, "stable_diffusion", "")
	if sd_prompt.is_empty():
		_fail("Stable Diffusion prompt was unexpectedly empty")
		return
	for rejected in ["embarrassed", "flustered", "legacy piece", "cataloguing", "mischievous glint", "knowing smile", "lower hem", "side slits blooming", ", reds", ", blues", ", pinks"]:
		if sd_prompt.to_lower().contains(rejected):
			_fail("SD prompt leaked non-core prose/detail: %s" % rejected)
			return
	if sd_prompt.split(",", false).size() > 20:
		_fail("SD automatic prompt exceeded balanced detail budget: %s" % sd_prompt)
		return
	if not sd_prompt.contains("áo dài"):
		_fail("SD prompt lost the character's main outfit identity")
		return
	if not sd_prompt.to_lower().contains("mandarin collar"):
		_fail("SD prompt lost the outfit's useful structural detail")
		return
	if not sd_prompt.to_lower().contains("embroidery"):
		_fail("SD prompt lost the outfit's useful visual motif")
		return

	var natural_prompt: String = IMAGE_PROMPT_SERVICE_V0139.build_prompt(project, character_id, "natural", "")
	for rejected in ["embarrassed", "legacy piece", "cataloguing", "mischievous glint", "lower hem", "side slits blooming"]:
		if natural_prompt.to_lower().contains(rejected):
			_fail("Natural prompt leaked non-core prose/detail: %s" % rejected)
			return
	if not natural_prompt.contains("Core visual identity:"):
		_fail("Natural prompt did not use the concise visual-identity format")
		return

	print("Image prompt concision regression passed.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
