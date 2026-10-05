class_name CCFIdeaPromptProvenanceV02114
extends RefCounted

## Internal per-Idea generation metadata. It travels with generated Ideas while
## they are curated, but is converted into portable source metadata on save.
const INTERNAL_KEY := "_ccf_generation_provenance"


static func capture(generation_context: Dictionary, provider_prompt: String) -> Dictionary:
	var prompt := provider_prompt.strip_edges()
	var visible_instruction := str(generation_context.get("seed_text", "")).strip_edges()
	if prompt.is_empty():
		prompt = visible_instruction
	return {
		"generation_prompt": prompt,
		"visible_instruction": visible_instruction,
		"prompt_mode": str(generation_context.get("prompt_mode", "primary_prompt")).strip_edges(),
		"idea_source_id": str(generation_context.get("idea_source_id", "")).strip_edges(),
		"idea_source_title": str(generation_context.get("idea_source_title", "")).strip_edges()
	}


static func attach_to_idea(
	idea: Dictionary, generation_context: Dictionary, provider_prompt: String
) -> Dictionary:
	var result := idea.duplicate(true)
	result[INTERNAL_KEY] = capture(generation_context, provider_prompt)
	return result


static func source_for_saved_idea(idea: Dictionary, fallback_source: Dictionary) -> Dictionary:
	var result := fallback_source.duplicate(true)
	var provenance_value: Variant = idea.get(INTERNAL_KEY, {})
	if provenance_value is Dictionary:
		var provenance: Dictionary = provenance_value
		var prompt := str(provenance.get("generation_prompt", "")).strip_edges()
		if not prompt.is_empty():
			result["generation_prompt"] = prompt
			# Keep the historical field as an alias so older CCF versions and
			# existing external tools retain the prompt when they read this Idea.
			result["seed_prompt"] = prompt
		for field_id in [
			"visible_instruction", "prompt_mode", "idea_source_id", "idea_source_title"
		]:
			var value := str(provenance.get(field_id, "")).strip_edges()
			if not value.is_empty() or field_id == "visible_instruction":
				result[field_id] = value
	return result


static func clean_idea_for_save(idea: Dictionary) -> Dictionary:
	var result := idea.duplicate(true)
	result.erase(INTERNAL_KEY)
	return result


static func reusable_prompt(idea: Dictionary) -> String:
	var source_value: Variant = idea.get("source", {})
	if source_value is Dictionary:
		var source: Dictionary = source_value
		for field_id in ["generation_prompt", "seed_prompt"]:
			var prompt := str(source.get(field_id, "")).strip_edges()
			if not prompt.is_empty():
				return prompt
	var provenance_value: Variant = idea.get(INTERNAL_KEY, {})
	if provenance_value is Dictionary:
		var internal_prompt := str(
			(provenance_value as Dictionary).get("generation_prompt", "")
		).strip_edges()
		if not internal_prompt.is_empty():
			return internal_prompt
	var structured_value: Variant = idea.get("structured_idea", {})
	if structured_value is Dictionary:
		var entry_value: Variant = (structured_value as Dictionary).get("entry", {})
		if entry_value is Dictionary:
			return str((entry_value as Dictionary).get("generation_prompt", "")).strip_edges()
	return ""
