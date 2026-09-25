class_name CCFIdeaGeneratorBatchingV0211
extends RefCounted

const CONTRACT_VERSION := 1
const MAX_TOTAL_IDEAS := 50
const MAX_IDEAS_PER_REQUEST := 12
const DEFAULT_IDEAS_PER_REQUEST := 12


static func normalise_total_ideas(value: Variant) -> int:
	return clampi(int(value), 1, MAX_TOTAL_IDEAS)


static func normalise_ideas_per_request(value: Variant) -> int:
	return clampi(int(value), 1, MAX_IDEAS_PER_REQUEST)


static func request_plan(total_ideas: int, ideas_per_request: int) -> Array[int]:
	var remaining := normalise_total_ideas(total_ideas)
	var batch_size := normalise_ideas_per_request(ideas_per_request)
	var plan: Array[int] = []
	while remaining > 0:
		var request_size := mini(batch_size, remaining)
		plan.append(request_size)
		remaining -= request_size
	return plan


static func prompt_instruction(
	batch_index: int, request_count: int, requested_total: int
) -> String:
	return (
		"BATCHED IDEA REQUEST:\n"
		+ "- This is request %d of %d in an author-requested run of %d total ideas.\n"
		+ "- Return exactly the number of ideas requested by this individual request.\n"
		+ "- Make the ideas within this response meaningfully distinct; the app will combine all successful responses in request order.\n"
		+ "- Treat this request number as a variation partition and favor concepts unlikely to recur in other numbered requests.\n"
		+ "- Do not refer to batching, request numbers, or this instruction in the idea content."
	) % [batch_index + 1, request_count, requested_total]


static func capabilities() -> Dictionary:
	return {
		"contract_version": CONTRACT_VERSION,
		"maximum_total_ideas": MAX_TOTAL_IDEAS,
		"maximum_ideas_per_request": MAX_IDEAS_PER_REQUEST,
		"default_ideas_per_request": DEFAULT_IDEAS_PER_REQUEST,
		"single_idea_requests_supported": true,
		"sequential_aggregation": true,
		"partial_success_preserved": true
	}
