extends SceneTree

const BUILDER_V014 = preload("res://scripts/ui/character_builder_window_v014.gd")


func _init() -> void:
	var problems := CCFAuthoringOptionService.validate_catalog()
	_expect(problems.is_empty(), "Authoring option catalog should validate: %s" % str(problems))

	var builder_paths: Dictionary = {}
	for builder_field in CCFBuilderService.all_fields():
		if builder_field is Dictionary:
			builder_paths[str(builder_field.get("path", ""))] = true
	for field_path in CCFAuthoringOptionService.configured_field_paths():
		_expect(builder_paths.has(field_path), "Authoring option path must reference a real Builder field: %s" % field_path)
		_expect(not CCFAuthoringOptionService.options_for_field(field_path).is_empty(), "Configured Builder option pool must not be empty: %s" % field_path)

	_expect(CCFAuthoringOptionService.options_for_field("foundation.genre").has("Fantasy"), "Genre suggestions should expose reusable V1-style choices.")
	_expect(CCFAuthoringOptionService.mode_for_field("personality.traits") == "multi", "Trait suggestions should be additive.")

	var tags: Variant = CCFAuthoringOptionService.apply_option(["playful"], "tags", "reserved")
	_expect(tags is Array and tags.size() == 2, "Selecting a tag suggestion should append instead of replacing existing choices.")
	tags = CCFAuthoringOptionService.apply_option(tags, "tags", "Reserved")
	_expect(tags is Array and tags.size() == 2, "Suggestion pools should avoid case-insensitive duplicates.")

	var line_value: Variant = CCFAuthoringOptionService.apply_option("My custom role", "line", "Rival")
	_expect(str(line_value) == "Rival", "Selecting a single-choice suggestion should fill the editable field.")
	var custom_state := CCFBuilderService.default_state()
	CCFStorageService.set_value_at_path(custom_state, "foundation.role", "My completely custom archetype")
	var normalised := CCFBuilderService.normalise_state(custom_state)
	_expect(str(CCFStorageService.get_value_at_path(normalised, "foundation.role", "")) == "My completely custom archetype", "Builder option pools must remain suggestions rather than restrictive enums.")

	var window := BUILDER_V014.new()
	_expect(window is CCFCharacterBuilderWindow, "v0.14 Builder should remain compatible with the existing Builder window contract.")
	window.free()

	print("v0.14 authoring option foundation regression passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
