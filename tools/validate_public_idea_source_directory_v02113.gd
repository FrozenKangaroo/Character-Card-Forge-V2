extends SceneTree


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass the directory containing public .ccfideasource.json files.")
		quit(2)
		return
	var directory := str(args[0])
	var file_names := DirAccess.get_files_at(directory)
	var service := CCFIdeaSourceServiceV0213.new()
	var count := 0
	for file_name in file_names:
		if not file_name.to_lower().ends_with(CCFIdeaSourceServiceV0213.EXTENSION):
			continue
		var result := service.parse_file(directory.path_join(file_name))
		if not bool(result.get("load_allowed", false)):
			push_error("%s failed production parsing: %s" % [file_name, JSON.stringify(result.get("errors", []))])
			quit(1)
			return
		count += 1
	if count == 0:
		push_error("No public Idea Sources were found in %s." % directory)
		quit(1)
		return
	if args.size() >= 2:
		var manifest_text := FileAccess.get_file_as_string(str(args[1]))
		var catalog_service := CCFPublicIdeaSourceCatalogV02113.new()
		var parsed_manifest := catalog_service.parse_manifest_text(manifest_text)
		if not bool(parsed_manifest.get("ok", false)):
			push_error(str(parsed_manifest.get("error", "Manifest validation failed.")))
			quit(1)
			return
		var catalog: Dictionary = parsed_manifest.get("catalog", {})
		for entry_value in catalog.get("sources", []):
			var entry := entry_value as Dictionary
			var path := directory.path_join(str(entry.get("path", "")).get_file())
			var body := FileAccess.get_file_as_bytes(path)
			var validated := catalog_service.validate_source_body(entry, body)
			if not bool(validated.get("ok", false)):
				push_error("%s failed catalog validation: %s" % [path, str(validated.get("error", "Unknown error."))])
				quit(1)
				return
	print("PUBLIC_IDEA_SOURCE_DIRECTORY_OK:%d" % count)
	quit(0)
