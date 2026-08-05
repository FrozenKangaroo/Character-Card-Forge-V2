class_name CCFCollaboratorCharacterIntentServiceV01534
extends RefCounted

const SOURCE_SERVICE_V01533 = preload(
	"res://scripts/services/collaborator_source_context_service_v01533.gd"
)

const DEFAULT_INTENT_ID := "refine"


static func intent_options() -> Array[Dictionary]:
	return [
		{
			"id": "refine",
			"label": "Refine / deepen this character",
			"description": "Explore gaps, contradictions, motivations, relationships and stronger detail while treating the existing card as canon by default.",
			"author_intent": "Refine and deepen this existing character while preserving established canon unless the author explicitly asks to change it.",
			"placeholder": "Optional: focus on weak areas, missing motivations, relationship depth, speech style, scenario logic, or anything else you want to improve."
		},
		{
			"id": "alternative_version",
			"label": "Alternative version / route",
			"description": "Branch from the current character into a different route or version without rewriting the stored source card.",
			"author_intent": "Develop an alternative version or route of this character. Preserve source facts up to the branch point, then apply the author's requested divergence consistently.",
			"placeholder": "Optional: describe the branch point, changed choice, relationship outcome, setting change, or alternate premise."
		},
		{
			"id": "future_version",
			"label": "Future version",
			"description": "Advance the character forward in time while preserving the established history that still applies.",
			"author_intent": "Develop a future version of this character. Treat the source as established history and reason forward from it rather than replacing it.",
			"placeholder": "Optional: specify how many years later, the event being followed, a changed relationship, career, family situation, or other future condition."
		},
		{
			"id": "past_version",
			"label": "Past version",
			"description": "Explore the character at an earlier point in their established timeline.",
			"author_intent": "Develop a past version of this character. Work backward consistently from established source facts and do not invent contradictions to later canon without the author's direction.",
			"placeholder": "Optional: specify age, year, school/work period, relationship stage, or an event from the character's earlier life."
		},
		{
			"id": "continue_after_event",
			"label": "Continue after an event",
			"description": "Treat the current card as the checkpoint, then explore what happens after a specified event.",
			"author_intent": "Continue this character after an author-specified event. Preserve the existing card as prior canon and develop consequences from the new event forward.",
			"placeholder": "Describe the event or turning point to continue from and anything that is already known about its immediate aftermath."
		},
		{
			"id": "side_character_promotion",
			"label": "Promote a side character",
			"description": "Use a person already mentioned or implied by this card as the grounded source for a new standalone character.",
			"author_intent": "Develop a side character established or implied by this source into a distinct standalone character. Preserve every source fact about that person and invent only the missing material.",
			"placeholder": "Name or describe the side character you want to promote and any direction for making them distinct."
		},
		{
			"id": "relative_descendant",
			"label": "Relative / descendant",
			"description": "Create or develop a family-connected character grounded in the source character and established setting.",
			"author_intent": "Develop a relative or descendant connected to this source character. Preserve established family and setting facts, make the new person distinct, and keep the relationship provenance clear.",
			"placeholder": "Optional: older sister, son, granddaughter, cousin, parent, or another family relationship, plus any known facts."
		},
		{
			"id": "connected_character",
			"label": "Connected character",
			"description": "Create or develop another person connected through work, friendship, rivalry, romance, history, or another established relationship.",
			"author_intent": "Develop a distinct character connected to this source character. Preserve established connection facts and use the source as continuity context rather than cloning its identity.",
			"placeholder": "Describe who the connected character is: friend, rival, coworker, ex, neighbour, classmate, mentor, partner, or another connection."
		},
		{
			"id": "same_setting",
			"label": "New character in the same setting",
			"description": "Use the source character as setting and continuity reference while creating someone new who need not be directly related.",
			"author_intent": "Develop a new standalone character in the same established setting or continuity. Reuse source-world facts where relevant without assuming a relationship that the author has not established.",
			"placeholder": "Optional: describe the role, location, social circle, workplace, university, series premise, or other setting connection."
		},
		{
			"id": "open_ended",
			"label": "Open-ended development",
			"description": "Start with the current character as read-only source and decide the direction conversationally in Collaborator.",
			"author_intent": "Develop from this existing character as open-ended authoring source. Preserve established source facts and let the author decide through conversation whether the work becomes a refinement, branch, continuation, or connected character.",
			"placeholder": "Optional: add any opening thought or leave this blank and decide the direction in the conversation."
		}
	]


static func intent_by_id(intent_id: String) -> Dictionary:
	var clean_id := intent_id.strip_edges()
	for option in intent_options():
		if str(option.get("id", "")) == clean_id:
			return option.duplicate(true)
	for option in intent_options():
		if str(option.get("id", "")) == DEFAULT_INTENT_ID:
			return option.duplicate(true)
	return {}


static func build_source(
	character: Dictionary,
	project_id: String,
	project_name: String,
	source_name: String,
	options: Dictionary
) -> Dictionary:
	if character.is_empty():
		return {}
	var intent_id := str(options.get("intent_id", DEFAULT_INTENT_ID)).strip_edges()
	var intent := intent_by_id(intent_id)
	if intent.is_empty():
		return {}
	intent_id = str(intent.get("id", DEFAULT_INTENT_ID))
	var intent_label := str(intent.get("label", "Existing character development"))
	var instruction := str(options.get("instruction", "")).strip_edges()
	var source := SOURCE_SERVICE_V01533.from_character(character, project_id, project_name)
	if source.is_empty():
		return {}

	var clean_source_name := source_name.strip_edges()
	if clean_source_name.is_empty():
		clean_source_name = str(source.get("label", "Existing Character"))
	if clean_source_name.is_empty():
		clean_source_name = "Existing Character"
	source["label"] = clean_source_name

	var author_intent := str(intent.get("author_intent", "Develop from this existing character."))
	if not instruction.is_empty():
		author_intent += "\nAuthor's starting direction: %s" % instruction
	source["author_intent"] = author_intent

	var provenance_value: Variant = source.get("provenance", {})
	var provenance: Dictionary = (
		(provenance_value as Dictionary).duplicate(true)
		if provenance_value is Dictionary
		else {}
	)
	provenance["derivation"] = {
		"source_project_id": project_id,
		"source_character_id": str(
			character.get("character_id", character.get("id", ""))
		),
		"source_character_name": clean_source_name,
		"derivation_type": intent_id,
		"derivation_prompt": instruction,
		"intent_label": intent_label,
		"origin_workflow": "existing_character_collaborator_v01534",
		"created_at": Time.get_datetime_string_from_system(true)
	}
	source["provenance"] = provenance
	return SOURCE_SERVICE_V01533.normalise(source)


static func capabilities() -> Dictionary:
	return {
		"version": "0.15.34",
		"intent_count": intent_options().size(),
		"existing_character_source": true,
		"read_only_source": true,
		"v01410_derivation_provenance": true,
		"automatic_source_replacement": false,
		"multi_source": false
	}
