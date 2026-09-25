class_name CCFIdeaGeneratorCustomLengthV0211
extends RefCounted

const CONTRACT_VERSION := 1
const MIN_TARGET_CHARACTERS := 500
const MAX_TARGET_CHARACTERS := 50000
const DEFAULT_TARGET_CHARACTERS := 6000
const TARGET_TOLERANCE_PERCENT := 15
const APPROXIMATE_CHARACTERS_PER_TOKEN := 4.0
const JSON_OVERHEAD_CHARACTERS_PER_IDEA := 600
const OUTPUT_SAFETY_MULTIPLIER := 1.15


static func normalise_target_characters(value: Variant) -> int:
	return clampi(
		int(value), MIN_TARGET_CHARACTERS, MAX_TARGET_CHARACTERS
	)


static func target_range(target_characters: int) -> Dictionary:
	var target := normalise_target_characters(target_characters)
	var tolerance := float(TARGET_TOLERANCE_PERCENT) / 100.0
	return {
		"minimum": int(floor(float(target) * (1.0 - tolerance))),
		"target": target,
		"maximum": int(ceil(float(target) * (1.0 + tolerance)))
	}


static func output_budget(
	target_characters: int,
	idea_count: int,
	profile_max_output_tokens: int
) -> Dictionary:
	var target := normalise_target_characters(target_characters)
	var count := clampi(idea_count, 1, 12)
	var profile_limit := maxi(128, profile_max_output_tokens)
	var estimated_characters := (
		(target + JSON_OVERHEAD_CHARACTERS_PER_IDEA) * count
	)
	var estimated_tokens := int(ceil(
		(float(estimated_characters) / APPROXIMATE_CHARACTERS_PER_TOKEN)
		* OUTPUT_SAFETY_MULTIPLIER
	))
	var requested_tokens := maxi(256, estimated_tokens)
	var effective_tokens := mini(requested_tokens, profile_limit)
	return {
		"target_characters_per_idea": target,
		"idea_count": count,
		"estimated_output_characters": estimated_characters,
		"requested_output_tokens": requested_tokens,
		"profile_max_output_tokens": profile_limit,
		"effective_output_tokens": effective_tokens,
		"budget_limited": requested_tokens > profile_limit
	}


static func prompt_instruction(target_characters: int) -> String:
	var target_bounds := target_range(target_characters)
	return (
		"CUSTOM IDEA LENGTH TARGET:\n"
		+ "- Aim for approximately %d characters in the concept field of EACH idea (rough guide: %d–%d).\n"
		+ "- Count only the concept body, not title, character_name, character_role, source_anchor, roleplay_hook, tags, or JSON syntax.\n"
		+ "- This is a soft authoring target, not permission to add repetitive filler or truncate a coherent thought.\n"
		+ "- Preserve every identity, point-of-view, {{user}} agency, schema, and requested-idea-count rule even if exact length cannot be achieved."
	) % [
		int(target_bounds.get("target", DEFAULT_TARGET_CHARACTERS)),
		int(target_bounds.get("minimum", 0)),
		int(target_bounds.get("maximum", 0))
	]


static func actual_counts(ideas: Array) -> Array[int]:
	var counts: Array[int] = []
	for idea_value in ideas:
		if idea_value is Dictionary:
			counts.append(str((idea_value as Dictionary).get("concept", "")).length())
	return counts


static func count_within_target(actual_count: int, target_characters: int) -> bool:
	var target_bounds := target_range(target_characters)
	return (
		actual_count >= int(target_bounds.get("minimum", 0))
		and actual_count <= int(target_bounds.get("maximum", 0))
	)
