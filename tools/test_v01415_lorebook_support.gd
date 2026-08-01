extends SceneTree


func _init() -> void:
	var project := {
		"concept": {"prompt": "Mika meets {{user}} at the railway museum."},
		"shared_context": {"setting": "A preserved regional railway museum."},
		"lorebook": {
			"name": "Project Lorebook",
			"token_budget": 2048,
			"entries": [
				{"name": "Museum", "keys": ["railway museum"], "content": "The museum occupies a restored 1912 station.", "enabled": true, "constant": false, "selective": false, "case_sensitive": false, "priority": 100, "insertion_order": 0},
				{"name": "Always", "keys": [], "content": "Steam locomotives are maintained by volunteers.", "enabled": true, "constant": true, "priority": 50, "insertion_order": 1},
				{"name": "Off", "keys": ["Mika"], "content": "This must never appear.", "enabled": false}
			]
		},
		"character": {
			"name": "Mika",
			"character_book": {
				"name": "Character Lorebook",
				"entries": [
					{"name": "Signal Box", "keys": ["signal box"], "secondary_keys": ["Mika"], "content": "Mika secretly restored the signal box herself.", "enabled": true, "selective": true, "case_sensitive": false, "priority": 120, "insertion_order": 0}
				]
			}
		}
	}
	var context := CCFLorebookContextServiceV01415.generation_context_for_project(project, "Mika opens the signal box.")
	assert(context.contains("Museum"), "Primary-key project lore should activate.")
	assert(context.contains("Always"), "Constant project lore should activate.")
	assert(context.contains("Signal Box"), "Selective character lore should activate when primary and secondary keys match.")
	assert(not context.contains("This must never appear"), "Disabled lore must not enter generation context.")
	var selective_miss := CCFLorebookContextServiceV01415.describe_activation(project.character.character_book, "signal box")
	assert(selective_miss.is_empty(), "Selective lore must require its secondary key when configured.")
	var generation_service := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01415.gd")
	assert(generation_service.contains("LOREBOOK CONTEXT"), "Generation service must inject activated lorebook context.")
	var lore_window := FileAccess.get_file_as_string("res://scripts/ui/lorebook_window_v01415.gd")
	assert(lore_window.contains("Test Triggers"), "Lorebook Manager needs trigger preview.")
	assert(lore_window.contains("Copy to Other Scope"), "Lorebook Manager needs copy-between-scope support.")
	assert(lore_window.contains("Move to Other Scope"), "Lorebook Manager needs move-between-scope support.")
	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01415.gd")
	assert(workspace.contains("GENERATION_SERVICE_V01415"), "Workspace must install lore-aware generation service.")
	assert(workspace.contains("LOREBOOK_WINDOW_V01415"), "Workspace must install the upgraded Lorebook Manager.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01415.gd")
	assert(main_source.contains("extends \"res://scripts/main_v01414.gd\""), "v0.14.15 must preserve v0.14.14.")
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene.contains("main_v01415.gd"), "Main scene must use the v0.14.15 shell.")
	print("v0.14.15 lorebook support regression passed")
	quit(0)
