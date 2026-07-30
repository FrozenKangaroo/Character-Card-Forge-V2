class_name CCFGenerationContractService
extends RefCounted

const CONTRACT_FORMAT_VERSION := 3
const DEFAULT_CONTRACT_PATH := "res://data/generation_contracts/default.json"


static func contract_for_template(template: Dictionary) -> Dictionary:
	var required_fields: Array[Dictionary] = []
	for raw_field in CCFTemplateService.generation_fields(template):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		if not bool(field.get("required", false)):
			continue
		required_fields.append(
			{
				"id": str(field.get("id", "")).strip_edges(),
				"label": str(field.get("label", field.get("id", "Field"))).strip_edges(),
				"type": str(field.get("type", "multiline"))
			}
		)

	var field_rules: Dictionary = {}
	var template_id := str(template.get("template_id", "default")).strip_edges()
	if template_id == "default":
		var bundled := _read_contract(DEFAULT_CONTRACT_PATH)
		var bundled_fields: Variant = bundled.get("fields", {})
		if bundled_fields is Dictionary:
			field_rules = bundled_fields.duplicate(true)

	for raw_group in CCFTemplateService.enabled_generation_groups(template):
		if not raw_group is Dictionary:
			continue
		var group: Dictionary = raw_group
		var output_field_id := str(group.get("output_field_id", "")).strip_edges()
		if output_field_id.is_empty():
			continue
		var rule_value: Variant = field_rules.get(output_field_id, {})
		var rule: Dictionary = rule_value.duplicate(true) if rule_value is Dictionary else {}
		var groups_value: Variant = rule.get("generation_groups", [])
		var generation_groups: Array = groups_value.duplicate(true) if groups_value is Array else []
		if generation_groups.is_empty():
			# Template groups supersede an old bundled component list, while field-wide
			# rules such as minimum length and marker counts remain active.
			rule.erase("components")
			rule.erase("required_labels")
			rule.erase("allow_extra_components")
			rule.erase("group_id")
			rule.erase("group_title")

		var component_contracts: Array[Dictionary] = []
		var required_labels: Array[String] = []
		var components_value: Variant = group.get("components", [])
		if components_value is Array:
			for raw_component in components_value:
				if not raw_component is Dictionary or not bool(raw_component.get("enabled", true)):
					continue
				var component: Dictionary = raw_component
				var label := str(component.get("label", component.get("id", "Component"))).strip_edges()
				if label.is_empty():
					continue
				var component_contract := {
					"id": str(component.get("id", "")).strip_edges(),
					"label": label,
					"required": bool(component.get("required", true)),
					"instruction": str(component.get("instruction", "")).strip_edges()
				}
				component_contracts.append(component_contract)
				if bool(component_contract.get("required", false)):
					required_labels.append(label)

		var group_title := str(group.get("title", output_field_id.capitalize())).strip_edges()
		if group_title.is_empty():
			group_title = output_field_id.capitalize()
		generation_groups.append(
			{
				"id": str(group.get("id", "")).strip_edges(),
				"title": group_title,
				"components": component_contracts,
				"required_labels": required_labels,
				"allow_extra_components": bool(group.get("allow_extra_components", false))
			}
		)
		rule["generation_groups"] = generation_groups
		rule["require_group_headings"] = generation_groups.size() > 1

		# Retain flattened compatibility data for older diagnostics. The ordered
		# generation_groups collection is authoritative for prompting and validation.
		var all_components: Array[Dictionary] = []
		var all_required_labels: Array[String] = []
		for raw_existing_group in generation_groups:
			if not raw_existing_group is Dictionary:
				continue
			var existing_group: Dictionary = raw_existing_group
			var existing_components: Variant = existing_group.get("components", [])
			if existing_components is Array:
				for raw_existing_component in existing_components:
					if raw_existing_component is Dictionary:
						all_components.append(raw_existing_component.duplicate(true))
			var existing_required: Variant = existing_group.get("required_labels", [])
			if existing_required is Array:
				for raw_label in existing_required:
					all_required_labels.append(str(raw_label))
		rule["components"] = all_components
		rule["required_labels"] = all_required_labels
		field_rules[output_field_id] = rule

	return {
		"format_version": CONTRACT_FORMAT_VERSION,
		"template_id": template_id,
		"required_fields": required_fields,
		"field_rules": field_rules
	}


static func prompt_text(contract: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Generation completeness contract:")
	var required_fields: Variant = contract.get("required_fields", [])
	if required_fields is Array and not required_fields.is_empty():
		var required_labels: Array[String] = []
		for raw_field in required_fields:
			if raw_field is Dictionary:
				required_labels.append(str(raw_field.get("id", raw_field.get("label", "field"))))
		if not required_labels.is_empty():
			lines.append("- Required top-level JSON keys: %s." % _join_strings(required_labels, ", "))

	var field_rules: Variant = contract.get("field_rules", {})
	if field_rules is Dictionary:
		for raw_field_id in field_rules:
			var field_id := str(raw_field_id)
			var raw_rule: Variant = field_rules.get(raw_field_id)
			if not raw_rule is Dictionary:
				continue
			var rule: Dictionary = raw_rule
			var groups_value: Variant = rule.get("generation_groups", [])
			if groups_value is Array and not groups_value.is_empty():
				var generation_groups: Array = groups_value
				if generation_groups.size() > 1:
					lines.append(
						"- %s must be one combined JSON string containing all %d generation groups below in this exact order. Append later groups after earlier groups; never replace an earlier group with a later one."
						% [field_id, generation_groups.size()]
					)
					lines.append("  - Include each group title as a plain section heading inside %s." % field_id)
				else:
					lines.append("- %s must contain the enabled generation group below as labelled lines." % field_id)
				for group_index in range(generation_groups.size()):
					var raw_group: Variant = generation_groups[group_index]
					if not raw_group is Dictionary:
						continue
					var group: Dictionary = raw_group
					var group_title := str(group.get("title", "Group %d" % (group_index + 1)))
					lines.append("  - Group %d — %s:" % [group_index + 1, group_title])
					var components_value: Variant = group.get("components", [])
					if components_value is Array:
						for raw_component in components_value:
							if not raw_component is Dictionary:
								continue
							var label := str(raw_component.get("label", "Component"))
							var requirement := "required" if bool(raw_component.get("required", true)) else "optional"
							var instruction := str(raw_component.get("instruction", "")).strip_edges()
							var component_line := "    - %s (%s)" % [label, requirement]
							if not instruction.is_empty():
								component_line += ": %s" % instruction
							lines.append(component_line)
					if not bool(group.get("allow_extra_components", false)):
						lines.append("    - Do not invent extra labelled components inside %s." % group_title)
			else:
				var components_value: Variant = rule.get("components", [])
				if components_value is Array and not components_value.is_empty():
					lines.append("- %s must organise its enabled generation components as clear labelled lines:" % field_id)
					for raw_component in components_value:
						if not raw_component is Dictionary:
							continue
						var label := str(raw_component.get("label", "Component"))
						var requirement := "required" if bool(raw_component.get("required", true)) else "optional"
						var instruction := str(raw_component.get("instruction", "")).strip_edges()
						var component_line := "  - %s (%s)" % [label, requirement]
						if not instruction.is_empty():
							component_line += ": %s" % instruction
						lines.append(component_line)
					if not bool(rule.get("allow_extra_components", false)):
						lines.append("  - Do not invent extra labelled components for %s beyond the enabled list." % field_id)
				else:
					var required_labels_value: Variant = rule.get("required_labels", [])
					if required_labels_value is Array and not required_labels_value.is_empty():
						var labels: Array[String] = []
						for raw_label in required_labels_value:
							labels.append(str(raw_label))
						lines.append("- %s must contain these clearly labelled components: %s." % [field_id, _join_strings(labels, "; ")])
			var minimum_characters := int(rule.get("minimum_characters", 0))
			if minimum_characters > 0:
				lines.append("- %s should contain at least %d characters of useful content." % [field_id, minimum_characters])
			var marker_rules_value: Variant = rule.get("marker_rules", [])
			if marker_rules_value is Array:
				for raw_marker_rule in marker_rules_value:
					if not raw_marker_rule is Dictionary:
						continue
					var marker := str(raw_marker_rule.get("marker", ""))
					var exact_count := int(raw_marker_rule.get("exact_count", -1))
					if not marker.is_empty() and exact_count >= 0:
						lines.append("- %s must contain marker %s exactly %d time(s) when that optional field is returned." % [field_id, marker, exact_count])
	return _join_strings(lines, "\n")


static func validate_generated_data(data: Dictionary, contract: Dictionary) -> Dictionary:
	var issues: Array[Dictionary] = []
	var required_lookup: Dictionary = {}
	var required_fields: Variant = contract.get("required_fields", [])
	if required_fields is Array:
		for raw_field in required_fields:
			if not raw_field is Dictionary:
				continue
			var field_id := str(raw_field.get("id", "")).strip_edges()
			if field_id.is_empty():
				continue
			required_lookup[field_id] = true
			if not data.has(field_id) or not _value_has_content(data.get(field_id)):
				issues.append({"kind": "missing_field", "field_id": field_id, "label": str(raw_field.get("label", field_id)), "reason": "Required top-level field is missing or empty."})

	var field_rules: Variant = contract.get("field_rules", {})
	if field_rules is Dictionary:
		for raw_field_id in field_rules:
			var field_id := str(raw_field_id)
			var raw_rule: Variant = field_rules.get(raw_field_id)
			if not raw_rule is Dictionary:
				continue
			var rule: Dictionary = raw_rule
			var value_present := data.has(field_id) and _value_has_content(data.get(field_id))
			if not value_present:
				continue
			var value_text := _value_to_text(data.get(field_id))
			var minimum_characters := int(rule.get("minimum_characters", 0))
			if minimum_characters > 0 and value_text.strip_edges().length() < minimum_characters:
				issues.append({"kind": "minimum_length", "field_id": field_id, "label": field_id, "reason": "Field is too short for its generation contract (%d/%d characters)." % [value_text.strip_edges().length(), minimum_characters]})

			var groups_value: Variant = rule.get("generation_groups", [])
			if groups_value is Array and not groups_value.is_empty():
				_validate_generation_groups(value_text, field_id, groups_value, issues)
			else:
				var required_labels_value: Variant = rule.get("required_labels", [])
				if required_labels_value is Array:
					for raw_label in required_labels_value:
						var label := str(raw_label).strip_edges()
						if label.is_empty() or _contains_label(value_text, label):
							continue
						issues.append({"kind": "missing_component", "field_id": field_id, "label": label, "reason": "Expected enabled required generation component is missing."})

			var marker_rules_value: Variant = rule.get("marker_rules", [])
			if marker_rules_value is Array:
				for raw_marker_rule in marker_rules_value:
					if not raw_marker_rule is Dictionary:
						continue
					var marker := str(raw_marker_rule.get("marker", ""))
					var exact_count := int(raw_marker_rule.get("exact_count", -1))
					if marker.is_empty() or exact_count < 0:
						continue
					var actual_count := value_text.count(marker)
					if actual_count != exact_count:
						issues.append({"kind": "marker_count", "field_id": field_id, "label": marker, "reason": "Expected marker %s exactly %d time(s), found %d." % [marker, exact_count, actual_count]})
	return {"ok": issues.is_empty(), "issue_count": issues.size(), "issues": issues, "required_field_count": required_lookup.size(), "summary": "Generation contract satisfied." if issues.is_empty() else "%d generation-contract issue(s) detected." % issues.size()}


static func repair_instructions(report: Dictionary) -> String:
	var lines: Array[String] = []
	var raw_issues: Variant = report.get("issues", [])
	if raw_issues is Array:
		for raw_issue in raw_issues:
			if not raw_issue is Dictionary:
				continue
			var field_id := str(raw_issue.get("field_id", "field"))
			var group_title := str(raw_issue.get("group_title", "")).strip_edges()
			var label := str(raw_issue.get("label", "")).strip_edges()
			var reason := str(raw_issue.get("reason", "Incomplete content."))
			var target := field_id
			if not group_title.is_empty():
				target += " → %s" % group_title
			if not label.is_empty() and label != field_id and label != group_title:
				target += " → %s" % label
			lines.append("- %s: %s" % [target, reason])
	return _join_strings(lines, "\n")


static func _validate_generation_groups(
	value_text: String,
	field_id: String,
	groups: Array,
	issues: Array[Dictionary]
) -> void:
	var group_titles: Array[String] = []
	for raw_group in groups:
		if raw_group is Dictionary:
			group_titles.append(str(raw_group.get("title", "Generation Group")).strip_edges())
	var require_headings := groups.size() > 1
	for raw_group in groups:
		if not raw_group is Dictionary:
			continue
		var group: Dictionary = raw_group
		var group_id := str(group.get("id", "")).strip_edges()
		var group_title := str(group.get("title", group_id)).strip_edges()
		var section_text := value_text
		if require_headings:
			if not _contains_heading(value_text, group_title):
				issues.append(
					{
						"kind": "missing_generation_group",
						"field_id": field_id,
						"group_id": group_id,
						"group_title": group_title,
						"label": group_title,
						"reason": "Expected generation group section is missing. Multiple groups bound to one field must be appended in template order, not overwritten."
					}
				)
				continue
			section_text = _group_section_text(value_text, group_title, group_titles)
		var required_labels_value: Variant = group.get("required_labels", [])
		if not required_labels_value is Array:
			continue
		for raw_label in required_labels_value:
			var label := str(raw_label).strip_edges()
			if label.is_empty() or _contains_label(section_text, label):
				continue
			issues.append(
				{
					"kind": "missing_component",
					"field_id": field_id,
					"group_id": group_id,
					"group_title": group_title,
					"label": label,
					"reason": "Expected enabled required generation component is missing from this generation group."
				}
			)


static func _read_contract(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


static func _value_has_content(value: Variant) -> bool:
	if value == null:
		return false
	if value is String:
		return not value.strip_edges().is_empty()
	if value is Array:
		return not value.is_empty()
	if value is Dictionary:
		return not value.is_empty()
	return true


static func _value_to_text(value: Variant) -> String:
	if value is Array:
		var parts: Array[String] = []
		for raw_item in value:
			parts.append(str(raw_item))
		return _join_strings(parts, ", ")
	return str(value)


static func _contains_label(text: String, label: String) -> bool:
	var wanted := label.strip_edges().to_lower()
	if wanted.is_empty():
		return true
	for raw_line in text.split("\n", false):
		var line := str(raw_line).strip_edges().to_lower()
		while line.begins_with("-") or line.begins_with("#") or line.begins_with("•"):
			line = line.substr(1).strip_edges()
		line = line.replace("**", "").replace("__", "")
		if line.begins_with(wanted + ":") or line.begins_with(wanted + "："):
			return true
	return false


static func _contains_heading(text: String, title: String) -> bool:
	for raw_line in text.split("\n", false):
		if _line_is_heading(str(raw_line), title):
			return true
	return false


static func _group_section_text(text: String, title: String, all_titles: Array[String]) -> String:
	var source_lines := text.split("\n", true)
	var start_index := -1
	for index in range(source_lines.size()):
		if _line_is_heading(str(source_lines[index]), title):
			start_index = index + 1
			break
	if start_index < 0:
		return ""
	var end_index := source_lines.size()
	for index in range(start_index, source_lines.size()):
		var line := str(source_lines[index])
		for other_title in all_titles:
			if other_title.to_lower() == title.to_lower():
				continue
			if _line_is_heading(line, other_title):
				end_index = index
				break
		if end_index != source_lines.size():
			break
	var section_lines: Array[String] = []
	for index in range(start_index, end_index):
		section_lines.append(str(source_lines[index]))
	return _join_strings(section_lines, "\n")


static func _line_is_heading(raw_line: String, title: String) -> bool:
	var line := raw_line.strip_edges()
	while line.begins_with("-") or line.begins_with("#") or line.begins_with("•") or line.begins_with(">"):
		line = line.substr(1).strip_edges()
	line = line.replace("**", "").replace("__", "").strip_edges()
	if line.begins_with("[") and line.ends_with("]") and line.length() > 2:
		line = line.substr(1, line.length() - 2).strip_edges()
	while line.ends_with(":") or line.ends_with("："):
		line = line.left(line.length() - 1).strip_edges()
	return line.to_lower() == title.strip_edges().to_lower()


static func _join_strings(values: Array[String], separator: String) -> String:
	var result := ""
	for index in range(values.size()):
		if index > 0:
			result += separator
		result += values[index]
	return result
