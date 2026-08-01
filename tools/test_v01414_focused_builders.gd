extends SceneTree


func _init() -> void:
	var schema_text := FileAccess.get_file_as_string("res://data/focused_builder_schema_v01414.json")
	var schema = JSON.parse_string(schema_text)
	assert(schema is Dictionary, "Focused builder schema must be valid JSON.")
	assert(int(schema.get("format_version", 0)) == 1, "Focused builder schema must be versioned.")
	var tabs = schema.get("tabs", [])
	assert(tabs is Array and tabs.size() == 3, "Focused builders must provide Appearance, Personality, and Scene tabs.")
	for required_text in ["Appearance", "Personality", "Scene", "Accessories & Traits", "Relationship with {{user}}", "Tension & Stakes"]:
		assert(schema_text.contains(required_text), "Focused schema is missing %s." % required_text)
	var service := FileAccess.get_file_as_string("res://scripts/services/focused_builder_service_v01414.gd")
	assert(service.contains("sync_into_full_builder"), "Focused builders must sync into the established Full Character state.")
	assert(service.contains("background.appearance"), "Appearance guidance must map to the existing appearance path.")
	assert(service.contains("personality.relationship_style"), "Personality guidance must map to the existing personality path.")
	assert(service.contains("scene.situation"), "Scene guidance must map to the existing scene path.")
	var window := FileAccess.get_file_as_string("res://scripts/ui/character_builder_window_v01414.gd")
	assert(window.contains("Full Character"), "Existing Full Character workflow must remain available.")
	assert(window.contains("Sync to Full Character"), "Focused builders need an explicit safe sync action.")
	assert(window.contains("focused_builders_v01414"), "Focused builder state must persist separately per character.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01414.gd")
	assert(main_source.contains("extends \"res://scripts/main_v01413.gd\""), "v0.14.14 must inherit the v0.14.13 shell.")
	var current_source := FileAccess.get_file_as_string("res://scripts/main_v01415.gd")
	assert(current_source.contains("extends \"res://scripts/main_v01414.gd\""), "Newer shells must preserve the v0.14.14 focused-builder layer.")
	print("v0.14.14 focused Character Builder regression passed")
	quit(0)
