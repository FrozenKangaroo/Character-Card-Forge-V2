class_name CCFGenerationContractService
extends RefCounted

const CONTRACT_FORMAT_VERSION := 2
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
		rule["components"] = component_contracts
		rule["required_labels"] = required_labels
		rule["allow_extra_components"] = bool(group.get("allow_extra_components", false))
		rule["group_id"] = str(group.get("id", ""))
		rule["group_title"] = str(group.get("title", output_field_id.capitalize()))
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
			var label := str(raw_issue.get("label", "")).strip_edges()
			var reason := str(raw_issue.get("reason", "Incomplete content."))
			var target := field_id if label.is_empty() or label == field_id else "%s → %s" % [field_id, label]
			lines.append("- %s: %s" % [target, reason])
	return _join_strings(lines, "\n")


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


static func _join_strings(values: Array[String], separator: String) -> String:
	var result := ""
	for index in range(values.size()):
		if index > 0:
			result += separator
		result += values[index]
	return result
