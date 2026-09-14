class_name CCFHelpContentServiceV0203
extends RefCounted

const CATALOG_PATH := "res://data/help_articles_v1.json"
const FORMAT_VERSION := 1


static func capabilities() -> Dictionary:
	var catalog := load_catalog()
	return {
		"format_version": FORMAT_VERSION,
		"offline": true,
		"provider_calls": false,
		"automatic_network": false,
		"searchable": true,
		"task_oriented": true,
		"article_count": articles(catalog).size(),
		"category_count": categories(catalog).size(),
		"routes_to_existing_tools": true,
	}


static func load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {"format_version": FORMAT_VERSION, "categories": [], "articles": []}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {"format_version": FORMAT_VERSION, "categories": [], "articles": []}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		return {"format_version": FORMAT_VERSION, "categories": [], "articles": []}
	return (parser.data as Dictionary).duplicate(true)


static func categories(catalog := {}) -> Array[Dictionary]:
	var source: Dictionary = catalog if catalog is Dictionary and not catalog.is_empty() else load_catalog()
	var result: Array[Dictionary] = []
	var values: Variant = source.get("categories", [])
	if not values is Array:
		return result
	for value in values:
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


static func articles(catalog := {}) -> Array[Dictionary]:
	var source: Dictionary = catalog if catalog is Dictionary and not catalog.is_empty() else load_catalog()
	var result: Array[Dictionary] = []
	var values: Variant = source.get("articles", [])
	if not values is Array:
		return result
	for value in values:
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


static func article_by_id(article_id: String, catalog := {}) -> Dictionary:
	for article in articles(catalog):
		if str(article.get("id", "")) == article_id:
			return article
	return {}


static func search(
	query: String, category_id := "", catalog := {}
) -> Array[Dictionary]:
	var needle := query.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for article in articles(catalog):
		if not category_id.is_empty() and str(article.get("category", "")) != category_id:
			continue
		if needle.is_empty() or _search_text(article).contains(needle):
			result.append(article)
	return result


static func render_article(article: Dictionary) -> String:
	if article.is_empty():
		return "[font_size=22]No help topic selected[/font_size]"
	var lines := PackedStringArray([
		"[font_size=26][b]%s[/b][/font_size]" % _escape_bbcode(str(article.get("title", "Help"))),
		"",
		"%s" % _escape_bbcode(str(article.get("summary", ""))),
		"",
		"[font_size=19][b]Steps[/b][/font_size]",
	])
	var step_number := 1
	for step_value in article.get("steps", []):
		lines.append("[b]%d.[/b] %s" % [step_number, _escape_bbcode(str(step_value))])
		lines.append("")
		step_number += 1
	var notes_value: Variant = article.get("notes", [])
	if notes_value is Array and not (notes_value as Array).is_empty():
		lines.append("[font_size=19][b]Good to know[/b][/font_size]")
		for note_value in notes_value:
			lines.append("• %s" % _escape_bbcode(str(note_value)))
		lines.append("")
	return "\n".join(lines)


static func validate_catalog() -> Array[String]:
	var problems: Array[String] = []
	var catalog := load_catalog()
	if int(catalog.get("format_version", 0)) != FORMAT_VERSION:
		problems.append("Unsupported help catalog format version.")
	var category_ids: Array[String] = []
	for category in categories(catalog):
		var category_id := str(category.get("id", "")).strip_edges()
		if category_id.is_empty() or category_ids.has(category_id):
			problems.append("Help categories require unique non-empty IDs.")
		else:
			category_ids.append(category_id)
		if str(category.get("label", "")).strip_edges().is_empty():
			problems.append("Help category %s needs a label." % category_id)
	var article_ids: Array[String] = []
	for article in articles(catalog):
		var article_id := str(article.get("id", "")).strip_edges()
		if article_id.is_empty() or article_ids.has(article_id):
			problems.append("Help articles require unique non-empty IDs.")
		else:
			article_ids.append(article_id)
		if str(article.get("category", "")) not in category_ids:
			problems.append("Help article %s uses an unknown category." % article_id)
		if str(article.get("title", "")).strip_edges().is_empty():
			problems.append("Help article %s needs a title." % article_id)
		var steps_value: Variant = article.get("steps", [])
		if not steps_value is Array or (steps_value as Array).is_empty():
			problems.append("Help article %s needs at least one step." % article_id)
	for article in articles(catalog):
		for related_value in article.get("related", []):
			if str(related_value) not in article_ids:
				problems.append(
					"Help article %s links to unknown topic %s."
					% [str(article.get("id", "")), str(related_value)]
				)
	return problems


static func _search_text(article: Dictionary) -> String:
	var parts := PackedStringArray([
		str(article.get("title", "")),
		str(article.get("summary", "")),
		str(article.get("category", "")),
	])
	for key in ["keywords", "steps", "notes"]:
		var values: Variant = article.get(key, [])
		if values is Array:
			for value in values:
				parts.append(str(value))
	return " ".join(parts).to_lower()


static func _escape_bbcode(value: String) -> String:
	return value.replace("[", "[​")
