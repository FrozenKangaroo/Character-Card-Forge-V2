class_name CCFCollaboratorTokenBudgetCurrent
extends RefCounted

# A model's maximum output capability is not a useful default request size for
# every conversational turn. Keep this author-chosen request separate.
const DEFAULT_REPLY_OUTPUT_TOKENS := 16384
const MIN_REPLY_OUTPUT_TOKENS := 128


static func requested_output_tokens(profile: Dictionary) -> int:
	var model_maximum := maxi(
		MIN_REPLY_OUTPUT_TOKENS, int(profile.get("max_output_tokens", 6000))
	)
	var chosen := maxi(
		MIN_REPLY_OUTPUT_TOKENS,
		int(profile.get("collaborator_reply_output_tokens", DEFAULT_REPLY_OUTPUT_TOKENS))
	)
	return mini(chosen, model_maximum)


static func request_profile(profile: Dictionary) -> Dictionary:
	var request := profile.duplicate(true)
	request["max_output_tokens"] = requested_output_tokens(profile)
	return request


static func budget(profile: Dictionary, used_input_tokens: int) -> Dictionary:
	var context_window := maxi(0, int(profile.get("context_window_tokens", 0)))
	var reserve := requested_output_tokens(profile)
	var used := maxi(0, used_input_tokens)
	var available_input := -1
	var remaining := -1
	var percentage := 0
	if context_window > 0:
		available_input = maxi(0, context_window - reserve)
		remaining = available_input - used
		percentage = int(round(float(used) * 100.0 / float(maxi(1, available_input))))
	return {
		"used": used,
		"context_window": context_window,
		"configured_output": maxi(MIN_REPLY_OUTPUT_TOKENS, int(profile.get("max_output_tokens", 6000))),
		"reserve": reserve,
		"available_input": available_input,
		"remaining": remaining,
		"percentage": percentage
	}
