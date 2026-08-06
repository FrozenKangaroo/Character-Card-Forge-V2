extends "res://scripts/ui/image_generation_window_v01538.gd"

const PICKER_INDEX_SERVICE_V01538 = preload(
	"res://scripts/services/character_picker_index_service_v01538.gd"
)


func build_character_picker_index_v01538(project_rows: Array) -> Array[Dictionary]:
	return PICKER_INDEX_SERVICE_V01538.build_index(project_rows)


func filter_character_picker_rows_v01538(
	rows: Array,
	query: String,
	limit: int = CHARACTER_PICKER_MAX_VISIBLE_V01538
) -> Array[Dictionary]:
	return PICKER_INDEX_SERVICE_V01538.filter_rows(rows, query, limit)


func _count_character_picker_matches_v01538(rows: Array, query: String) -> int:
	return PICKER_INDEX_SERVICE_V01538.count_matches(rows, query)
