class_name CCFTemplateService
extends RefCounted

const DEFAULT_TEMPLATE_PATH := "res://data/templates/default.json"
const CURRENT_FORMAT_VERSION := 2

static func load_default_template() -> Dictionary:
    var loaded := _read_json(DEFAULT_TEMPLATE_PATH)
    if not loaded.get("ok", false):
        return _fallback_template()
    return normalise_template(loaded.get("data", {}))

static func load_template(template_id: String) -> Dictionary:
    var clean_id := template_id.strip_edges()
    if clean_id.is_empty() or clean_id == "default":
        return load_default_template()

    var path := _template_path(clean_id)
    var loaded := _read_json(path)
    if not loaded.get("ok", false):
        return load_default_template()
    return normalise_template(loaded.get("data", {}))

static func list_templates() -> Array:
    CCFStorageService.ensure_directories()
    var result: Array = []
    var default_template := load_default_template()
    result.append(_summary(default_template, true))

    for filename in DirAccess.get_files_at(CCFStorageService.TEMPLATES_DIR):
        if not filename.to_lower().ends_with(".json"):
            continue
        var loaded := _read_json(CCFStorageService.TEMPLATES_DIR.path_join(filename))
        if not loaded.get("ok", false):
            continue
        var template := normalise_template(loaded.get("data", {}))
        if str(template.get("template_id", "")) == "default":
            continue
        result.append(_summary(template, false))

    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if bool(a.get("built_in", false)) != bool(b.get("built_in", false)):
            return bool(a.get("built_in", false))
        return str(a.get("name", "")).naturalnocasecmp_to(str(b.get("name", ""))) < 0
    )
    return result

static func create_template(display_name := "New Template") -> Dictionary:
    var template := _fallback_template()
    template["template_id"] = _new_template_id()
    template["name"] = display_name
    template["description"] = ""
    template["sections"] = [
        {
            "id": "overview",
            "title": "Overview",
            "description": "",
            "kind": "standard",
            "fields": [
                {
                    "id": "name",
                    "label": "Character name",
                    "type": "line",
                    "path": "character.name",
                    "placeholder": "Character name",
                    "generate": true,
                    "required": true
                },
                {
                    "id": "concept",
                    "label": "Generation concept",
                    "type": "multiline",
                    "path": "concept.prompt",
                    "placeholder": "Describe the character you want to create.",
                    "generate": false,
                    "required": false,
                    "height": 180
                }
            ]
        }
    ]
    return normalise_template(template)

static func duplicate_template(template_id: String) -> Dictionary:
    var source := load_template(template_id).duplicate(true)
    source["template_id"] = _new_template_id()
    source["name"] = "%s Copy" % str(source.get("name", "Template"))
    var result := save_template(source)
    if not result.get("ok", false):
        return result
    return {"ok": true, "template": source}

static func save_template(template: Dictionary) -> Dictionary:
    CCFStorageService.ensure_directories()
    var normalised := normalise_template(template)
    var template_id := str(normalised.get("template_id", "")).strip_edges()
    if template_id.is_empty():
        template_id = _new_template_id()
        normalised["template_id"] = template_id
    if template_id == "default":
        return {"ok": false, "error": "The built-in Default template is read-only. Duplicate it before editing."}

    var validation := validate_template(normalised)
    if not validation.get("ok", false):
        return validation

    var path := _template_path(template_id)
    var write_result := _write_json(path, normalised)
    if not write_result.get("ok", false):
        return write_result
    return {"ok": true, "path": path, "template": normalised}

static func delete_template(template_id: String) -> Dictionary:
    if template_id == "default":
        return {"ok": false, "error": "The built-in Default template cannot be deleted."}
    var path := ProjectSettings.globalize_path(_template_path(template_id))
    if not FileAccess.file_exists(path):
        return {"ok": false, "error": "Template file does not exist."}
    var error := DirAccess.remove_absolute(path)
    if error != OK:
        return {"ok": false, "error": "Could not delete template (error %s)." % error}
    return {"ok": true}

static func export_template(template_id: String, destination_path: String) -> Dictionary:
    var template := load_template(template_id)
    var target := destination_path.strip_edges()
    if target.is_empty():
        return {"ok": false, "error": "Choose an export path."}
    if not target.to_lower().ends_with(".json"):
        target += ".json"
    return _write_json(target, template)

static func import_template(source_path: String) -> Dictionary:
    var loaded := _read_json(source_path)
    if not loaded.get("ok", false):
        return loaded
    if not loaded.get("data") is Dictionary:
        return {"ok": false, "error": "Imported template must be a JSON object."}

    var template := normalise_template(loaded.get("data", {}))
    var incoming_id := str(template.get("template_id", "")).strip_edges()
    if incoming_id.is_empty() or incoming_id == "default" or _template_exists(incoming_id):
        template["template_id"] = _new_template_id()
    var result := save_template(template)
    if not result.get("ok", false):
        return result
    return {"ok": true, "template": result.get("template", template)}

static func generation_fields(template: Dictionary) -> Array:
    var result: Array = []
    for section in template.get("sections", []):
        if not section is Dictionary:
            continue
        for field in section.get("fields", []):
            if field is Dictionary and bool(field.get("generate", false)):
                result.append(field)
    return result

static func field_by_id(template: Dictionary, field_id: String) -> Dictionary:
    for section in template.get("sections", []):
        if not section is Dictionary:
            continue
        for field in section.get("fields", []):
            if field is Dictionary and str(field.get("id", "")) == field_id:
                return field
    return {}

static func output_policy(template: Dictionary) -> Dictionary:
    var policy = template.get("output_policy", {})
    if not policy is Dictionary:
        return {"mode": "strict", "unexpected_fields": "ignore"}
    return {
        "mode": str(policy.get("mode", "strict")),
        "unexpected_fields": str(policy.get("unexpected_fields", "ignore"))
    }

static func normalise_template(template: Dictionary) -> Dictionary:
    var result := _fallback_template()
    result["format_version"] = CURRENT_FORMAT_VERSION
    result["template_id"] = str(template.get("template_id", result["template_id"])).strip_edges()
    result["name"] = str(template.get("name", result["name"])).strip_edges()
    result["description"] = str(template.get("description", ""))

    var incoming_rules = template.get("global_generation_instructions", [])
    var rules: Array[String] = []
    if incoming_rules is Array:
        for rule in incoming_rules:
            var text := str(rule).strip_edges()
            if not text.is_empty():
                rules.append(text)
    result["global_generation_instructions"] = rules

    var incoming_policy = template.get("output_policy", {})
    var policy := {"mode": "strict", "unexpected_fields": "ignore"}
    if incoming_policy is Dictionary:
        var mode := str(incoming_policy.get("mode", "strict"))
        var unexpected := str(incoming_policy.get("unexpected_fields", "ignore"))
        policy["mode"] = mode if mode in ["strict", "flexible"] else "strict"
        policy["unexpected_fields"] = unexpected if unexpected in ["ignore", "store"] else "ignore"
    result["output_policy"] = policy

    var sections: Array = []
    var incoming_sections = template.get("sections", [])
    if incoming_sections is Array:
        for section_index in range(incoming_sections.size()):
            var section = incoming_sections[section_index]
            if not section is Dictionary:
                continue
            sections.append(_normalise_section(section, section_index))
    result["sections"] = sections
    return result

static func validate_template(template: Dictionary) -> Dictionary:
    var template_name := str(template.get("name", "")).strip_edges()
    if template_name.is_empty():
        return {"ok": false, "error": "Template name cannot be empty."}

    var seen_section_ids: Dictionary = {}
    var seen_field_ids: Dictionary = {}
    var seen_paths: Dictionary = {}
    for section in template.get("sections", []):
        if not section is Dictionary:
            continue
        var section_id := str(section.get("id", "")).strip_edges()
        if section_id.is_empty():
            return {"ok": false, "error": "Every section needs an ID."}
        if seen_section_ids.has(section_id):
            return {"ok": false, "error": "Duplicate section ID: %s" % section_id}
        seen_section_ids[section_id] = true

        for field in section.get("fields", []):
            if not field is Dictionary:
                continue
            var field_id := str(field.get("id", "")).strip_edges()
            var path := str(field.get("path", "")).strip_edges()
            if field_id.is_empty():
                return {"ok": false, "error": "Every field needs an ID."}
            if path.is_empty():
                return {"ok": false, "error": "Field '%s' needs a project path." % field_id}
            if seen_field_ids.has(field_id):
                return {"ok": false, "error": "Duplicate field ID: %s" % field_id}
            if seen_paths.has(path):
                return {"ok": false, "error": "Two fields use the same project path: %s" % path}
            seen_field_ids[field_id] = true
            seen_paths[path] = true

    return {"ok": true}

static func _normalise_section(section: Dictionary, section_index: int) -> Dictionary:
    var section_id := _safe_identifier(str(section.get("id", "section_%d" % section_index)))
    var result := {
        "id": section_id,
        "title": str(section.get("title", "Section %d" % (section_index + 1))),
        "description": str(section.get("description", "")),
        "kind": str(section.get("kind", "standard")) if str(section.get("kind", "standard")) in ["standard", "interview"] else "standard",
        "fields": []
    }

    var fields: Array = []
    var incoming_fields = section.get("fields", [])
    if incoming_fields is Array:
        for field_index in range(incoming_fields.size()):
            var field = incoming_fields[field_index]
            if field is Dictionary:
                fields.append(_normalise_field(field, section_id, field_index))
    result["fields"] = fields
    return result

static func _normalise_field(field: Dictionary, section_id: String, field_index: int) -> Dictionary:
    var field_id := _safe_identifier(str(field.get("id", "field_%d" % field_index)))
    var field_type := str(field.get("type", "multiline"))
    if not field_type in ["line", "multiline", "tags", "number", "checkbox", "select"]:
        field_type = "multiline"

    var result := {
        "id": field_id,
        "label": str(field.get("label", field_id.capitalize())),
        "type": field_type,
        "path": str(field.get("path", "character.custom.%s_%s" % [section_id, field_id])),
        "placeholder": str(field.get("placeholder", "")),
        "generate": bool(field.get("generate", false)),
        "required": bool(field.get("required", false)),
        "generation_prompt": str(field.get("generation_prompt", ""))
    }

    if field_type == "multiline":
        result["height"] = clampi(int(field.get("height", 150)), 80, 800)
    elif field_type == "number":
        result["minimum"] = float(field.get("minimum", 0.0))
        result["maximum"] = float(field.get("maximum", 100.0))
        result["step"] = maxf(0.001, float(field.get("step", 1.0)))
    elif field_type == "select":
        var options: Array[String] = []
        var incoming_options = field.get("options", [])
        if incoming_options is Array:
            for option in incoming_options:
                var option_text := str(option).strip_edges()
                if not option_text.is_empty() and not options.has(option_text):
                    options.append(option_text)
        result["options"] = options
    return result

static func _summary(template: Dictionary, built_in: bool) -> Dictionary:
    var field_count := 0
    for section in template.get("sections", []):
        if section is Dictionary:
            field_count += section.get("fields", []).size()
    return {
        "template_id": str(template.get("template_id", "default")),
        "name": str(template.get("name", "Template")),
        "description": str(template.get("description", "")),
        "section_count": template.get("sections", []).size(),
        "field_count": field_count,
        "built_in": built_in
    }

static func _fallback_template() -> Dictionary:
    return {
        "format_version": CURRENT_FORMAT_VERSION,
        "template_id": "default",
        "name": "Default Character Card",
        "description": "The starter Character Card Forge workspace template.",
        "global_generation_instructions": [
            "Write a coherent character suitable for roleplay.",
            "Keep fields internally consistent.",
            "Return valid JSON only."
        ],
        "output_policy": {
            "mode": "strict",
            "unexpected_fields": "ignore"
        },
        "sections": []
    }

static func _template_path(template_id: String) -> String:
    return CCFStorageService.TEMPLATES_DIR.path_join("%s.json" % _safe_identifier(template_id))

static func _template_exists(template_id: String) -> bool:
    if template_id == "default":
        return true
    return FileAccess.file_exists(_template_path(template_id))

static func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {"ok": false, "error": "File does not exist: %s" % path}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {"ok": false, "error": "Could not open %s." % path}
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        return {"ok": false, "error": "Invalid template JSON in %s." % path}
    return {"ok": true, "data": parsed}

static func _write_json(path: String, data: Variant) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return {"ok": false, "error": "Could not write %s." % path}
    file.store_string(JSON.stringify(data, "  "))
    file.close()
    return {"ok": true, "path": path}

static func _safe_identifier(value: String) -> String:
    var clean := value.strip_edges().to_lower()
    var result := ""
    for character in clean:
        if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
            result += character
        elif character == "_" or character == "-" or character == " ":
            result += "_"
    while "__" in result:
        result = result.replace("__", "_")
    result = result.trim_prefix("_").trim_suffix("_")
    if result.is_empty():
        result = "item"
    return result

static func _new_template_id() -> String:
    return "template_%s_%s" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
