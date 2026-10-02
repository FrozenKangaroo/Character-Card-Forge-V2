extends SceneTree


var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := CCFHelpContentServiceV0203.load_catalog()
	_require(
		CCFHelpContentServiceV0203.validate_catalog().is_empty(),
		"The expanded Help catalog must remain valid."
	)
	_require(
		CCFHelpContentServiceV0203.articles(catalog).size() >= 53,
		"The refreshed manual must retain all 53 current articles."
	)

	var source_article := CCFHelpContentServiceV0203.article_by_id(
		"idea_sources", catalog
	)
	var formats_article := CCFHelpContentServiceV0203.article_by_id(
		"portable_json_formats", catalog
	)
	var source_example := _example(
		source_article, "Portable Idea Source with one Direction Preset"
	)
	var minimal_source := _example(formats_article, "Minimal .ccfideasource.json")
	var pack_example := _example(formats_article, "Minimal .ccfideas.json Idea Pack")
	var character_example := _example(formats_article, "Concept-only .ccfchar")
	var series_example := _example(formats_article, "Series definition JSON")

	var source_service := CCFIdeaSourceServiceV0213.new()
	for example in [source_example, minimal_source]:
		var parsed_source := source_service.parse_text(str(example.get("content", "")))
		_require(
			bool(parsed_source.get("ok", false))
			and bool(parsed_source.get("load_allowed", false)),
			"Every documented Idea Source example must pass the production schema parser."
		)
	var source_data: Dictionary = JSON.parse_string(
		str(source_example.get("content", ""))
	)
	_require(
		(source_data.get("direction_presets", []) as Array).size() == 1,
		"The full Idea Source example must retain its valid Direction Preset."
	)

	var pack_service := CCFIdeaPackServiceV0210.new()
	var parsed_pack := pack_service.parse_text(str(pack_example.get("content", "")))
	_require(
		bool(parsed_pack.get("ok", false))
		and bool(parsed_pack.get("import_allowed", false))
		and (parsed_pack.get("entries", []) as Array).size() == 1,
		"The documented Idea Pack example must pass the production schema parser."
	)

	var character_data: Variant = JSON.parse_string(
		str(character_example.get("content", ""))
	)
	var parsed_character := (
		CCFCharSourceServiceV01421.normalise_source(character_data)
		if character_data is Dictionary else {}
	)
	_require(
		bool(parsed_character.get("ok", false))
		and (parsed_character.get("values", {}) as Dictionary).has("concept.prompt"),
		"The documented .ccfchar example must pass the production source parser."
	)

	var series_data: Variant = JSON.parse_string(str(series_example.get("content", "")))
	var series := (
		CCFSeriesService.normalise_series(series_data)
		if series_data is Dictionary else {}
	)
	_require(
		str(series.get("series_id", "")) == "astral-courier-guild"
		and str(series.get("name", "")) == "Astral Courier Guild",
		"The documented Series example must retain its required identity."
	)

	var rendered := CCFHelpContentServiceV0203.render_article(source_article)
	_require(
		rendered.contains("[font_size=19]Examples[/font_size]")
		and rendered.contains("[code]")
		and rendered.contains("[lb]"),
		"In-app JSON examples must render as safe selectable code."
	)

	if _failed:
		quit(1)
		return
	print("V02112_DOCUMENTATION_FORMATS_OK")
	quit(0)


func _example(article: Dictionary, title: String) -> Dictionary:
	for value in article.get("examples", []):
		if value is Dictionary and str(value.get("title", "")) == title:
			return value
	_require(false, "Missing documentation example: %s" % title)
	return {}


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
