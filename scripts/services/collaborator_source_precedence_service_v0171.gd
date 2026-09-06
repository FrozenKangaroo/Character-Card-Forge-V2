class_name CCFCollaboratorSourcePrecedenceServiceV0171
extends RefCounted

const SOURCE_SERVICE_V01537 = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)

const ROLE_TARGET_CANON := "target_canon"
const ROLE_STRUCTURED_FACTS := "structured_source_facts"
const ROLE_AUTHOR_REFERENCE := "author_reference"
const ROLE_CREATIVE_INTENT := "creative_intent"
const ROLE_SUPPLEMENTARY_OBSERVATION := "supplementary_observation"


static func capabilities() -> Dictionary:
	return {
		"version": "0.17.1",
		"evidence_roles": true,
		"single_target_precedence": true,
		"structured_metadata_vs_vision_review": true,
		"image_prompt_vs_vision_review": true,
		"linked_vision_identity": true,
		"potential_conflicts_not_auto_resolved": true,
		"model_facing_precedence_contract": true,
		"source_snapshots_immutable": true,
		"canonical_writes_automatic": false
	}


static func evidence_role(source: Dictionary) -> Dictionary:
	var source_type := str(source.get("source_type", ""))
	var source_role := str(source.get("source_role", SOURCE_SERVICE_V01537.ROLE_REFERENCE))
	if (
		source_type == SOURCE_SERVICE_V01537.TYPE_CHARACTER
		and source_role == SOURCE_SERVICE_V01537.ROLE_TARGET
	):
		return {
			"id": ROLE_TARGET_CANON,
			"label": "TARGET CANON",
			"explanation": "Current canonical facts for the one character eligible for Compare & Apply."
		}
	if source_type in [
		SOURCE_SERVICE_V01537.TYPE_CHARACTER,
		SOURCE_SERVICE_V01537.TYPE_EXTERNAL_CARD
	]:
		return {
			"id": ROLE_STRUCTURED_FACTS,
			"label": "STRUCTURED FACTS",
			"explanation": "Established facts from this separately identified character/card source; it does not overwrite the target."
		}
	if source_type == SOURCE_SERVICE_V01537.TYPE_IMAGE_STUDIO_RESULT:
		return {
			"id": ROLE_CREATIVE_INTENT,
			"label": "CREATIVE INTENT",
			"explanation": "Raw image provenance plus generation intent. Prompted details are not automatically visible facts."
		}
	return {
		"id": ROLE_AUTHOR_REFERENCE,
		"label": "AUTHOR REFERENCE",
		"explanation": "Read-only concept or reference supplied by the author; conflicts must be surfaced rather than silently merged."
	}


static func presentation(sources: Array[Dictionary], context_items: Variant) -> Dictionary:
	var clean := SOURCE_SERVICE_V01537.normalise_collection(sources)
	var rows: Array[Dictionary] = []
	var notices: Array[String] = []
	var structured_fact_count := 0
	var has_target := false
	for source in clean:
		var role := evidence_role(source)
		var vision_items := linked_vision_items(source, context_items)
		var source_type := str(source.get("source_type", ""))
		if str(role.get("id", "")) == ROLE_TARGET_CANON:
			has_target = true
		if str(role.get("id", "")) == ROLE_STRUCTURED_FACTS:
			structured_fact_count += 1
		rows.append({
			"source_context_id": str(source.get("source_context_id", "")),
			"label": str(source.get("label", "Source material")),
			"source_type": source_type,
			"display_type": SOURCE_SERVICE_V01537.display_type(source),
			"source_role": str(source.get("source_role", SOURCE_SERVICE_V01537.ROLE_REFERENCE)),
			"evidence_role_id": str(role.get("id", "")),
			"evidence_role_label": str(role.get("label", "REFERENCE")),
			"explanation": str(role.get("explanation", "")),
			"summary": SOURCE_SERVICE_V01537.display_summary(source),
			"linked_vision_count": vision_items.size(),
			"review_available": not vision_items.is_empty()
		})
		if not vision_items.is_empty():
			if source_type == SOURCE_SERVICE_V01537.TYPE_EXTERNAL_CARD:
				notices.append(
					"%s has both embedded Character Card data and linked Vision evidence. Card fields remain structured facts; Vision may add visible details or expose a discrepancy, but never overwrites the card automatically."
					% str(source.get("label", "Character Card"))
				)
			elif source_type == SOURCE_SERVICE_V01537.TYPE_IMAGE_STUDIO_RESULT:
				notices.append(
					"%s has both an Image Studio prompt and linked Vision evidence. The prompt records creative intent; Vision describes apparent pixels. Review differences instead of treating the prompt as observation."
					% str(source.get("label", "Image Studio result"))
				)
	if structured_fact_count > 1:
		notices.push_front(
			"Several structured character/card sources are present. Keep their identities separate and surface contradictory facts before proposing a blend or transfer."
		)
	if has_target and clean.size() > 1:
		notices.push_front(
			"The TARGET CANON source is the only current character eligible for Compare & Apply. References can inform proposals but do not silently replace its established fields."
		)
	return {
		"rows": rows,
		"notices": _deduplicate(notices),
		"source_count": clean.size(),
		"has_target": has_target,
		"needs_conflict_review": not notices.is_empty()
	}


static func linked_vision_items(source: Dictionary, context_items: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source_id := str(source.get("source_context_id", "")).strip_edges()
	if source_id.is_empty() or not context_items is Array:
		return result
	for raw_item in context_items as Array:
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item
		if (
			str(item.get("type", "")) == "vision_reference"
			and str(item.get("linked_source_context_id", "")) == source_id
		):
			result.append(item.duplicate(true))
	return result


static func model_precedence_block(
	sources: Array[Dictionary],
	context_items: Variant
) -> String:
	var view := presentation(sources, context_items)
	var rows_value: Variant = view.get("rows", [])
	if not rows_value is Array or (rows_value as Array).is_empty():
		return ""
	var lines: Array[String] = [
		"COLLABORATOR EVIDENCE ROLES AND CONFLICT CONTRACT",
		"",
		"PRECEDENCE RULES:",
		"- The author's explicit current request controls requested changes, but never rewrite stored source snapshots.",
		"- TARGET CANON is the sole current character eligible for Compare & Apply. Reference sources cannot silently overwrite it.",
		"- STRUCTURED FACTS remain authoritative for their own separately identified source. Do not merge identities by default.",
		"- AUTHOR REFERENCE and CREATIVE INTENT can inspire proposals; clearly label anything not established by target/source facts.",
		"- Vision is SUPPLEMENTARY OBSERVATION. It may describe visible details or uncertainty, but never overwrites structured metadata by itself.",
		"- If structured facts, creative intent and Vision appear inconsistent, name the discrepancy and ask or propose explicit alternatives instead of silently choosing.",
		"",
		"ACTIVE EVIDENCE MAP:"
	]
	for raw_row in rows_value as Array:
		if not raw_row is Dictionary:
			continue
		var row: Dictionary = raw_row
		lines.append("- %s — %s — %s%s" % [
			str(row.get("evidence_role_label", "REFERENCE")),
			str(row.get("display_type", "Source")),
			str(row.get("label", "Source material")),
			(
				" — linked Vision observations: %d"
				% int(row.get("linked_vision_count", 0))
				if int(row.get("linked_vision_count", 0)) > 0
				else ""
			)
		])
	return "\n".join(lines)


static func evidence_review_text(
	source: Dictionary,
	context_items: Variant
) -> String:
	var clean := SOURCE_SERVICE_V01537.upgrade_source(source)
	if clean.is_empty():
		return "The selected source is no longer available."
	var role := evidence_role(clean)
	var vision_items := linked_vision_items(clean, context_items)
	var lines: Array[String] = [
		"SOURCE",
		"%s • %s" % [
			str(role.get("label", "REFERENCE")),
			str(clean.get("label", "Source material"))
		],
		str(role.get("explanation", "")),
		"",
		"STRUCTURED / RAW SOURCE SNAPSHOT",
		_truncate(JSON.stringify(clean.get("ai_snapshot", {}), "  ", false), 12000),
		"",
		"LINKED VISION — SEPARATE SUPPLEMENTARY OBSERVATION"
	]
	if vision_items.is_empty():
		lines.append("No linked Vision evidence is currently available for this source.")
	else:
		for index in range(vision_items.size()):
			var item: Dictionary = vision_items[index]
			lines.append("Vision observation %d • %s" % [
				index + 1,
				str(item.get("label", "Image analysis"))
			])
			lines.append(_truncate(str(item.get("content", "")), 8000))
			lines.append("")
	lines.append("REVIEW RULE")
	if str(clean.get("source_type", "")) == SOURCE_SERVICE_V01537.TYPE_EXTERNAL_CARD:
		lines.append("Embedded card fields remain structured source facts. Use Vision for apparent visible details and uncertainty; surface discrepancies for an explicit author decision.")
	elif str(clean.get("source_type", "")) == SOURCE_SERVICE_V01537.TYPE_IMAGE_STUDIO_RESULT:
		lines.append("The generation prompt is creative intent, not a pixel observation. Use linked Vision for apparent visible details and surface prompt/image differences explicitly.")
	else:
		lines.append("Keep this source individually identified. Linked Vision may supplement it but never silently rewrites the source snapshot.")
	return "\n".join(lines)


static func _deduplicate(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var seen := {}
	for value in values:
		if value.is_empty() or seen.has(value):
			continue
		seen[value] = true
		result.append(value)
	return result


static func _truncate(text: String, limit: int) -> String:
	if text.length() <= limit:
		return text
	return text.left(maxi(0, limit - 1)).strip_edges() + "…"
