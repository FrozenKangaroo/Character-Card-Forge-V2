extends SceneTree


func _init() -> void:
	var direct_install_source := FileAccess.get_file_as_string(
		"res://scripts/ui/import_export_window_v0173.gd"
	)
	var group_service_source := FileAccess.get_file_as_string(
		"res://scripts/services/front_porch_group_card_service_v0174.gd"
	)
	var group_window_source := FileAccess.get_file_as_string(
		"res://scripts/ui/import_export_window_v0174.gd"
	)
	var workspace_source := FileAccess.get_file_as_string(
		"res://scripts/ui/workspace_v0175.gd"
	)
	if not _require(
		not direct_install_source.contains("var duplicate :=")
		and direct_install_source.contains("var already_listed := false"),
		"Direct-install artwork discovery must not shadow Node.duplicate()."
	):
		return
	if not _require(
		not group_service_source.contains("1024 / columns")
		and not group_service_source.contains("1024 / rows")
		and not group_service_source.contains("int(index / columns)")
		and group_service_source.contains("floori(1024.0 / float(columns))")
		and group_service_source.contains("floori(1024.0 / float(rows))")
		and group_service_source.contains(
			"floori(float(index) / float(columns)) * cell_height"
		),
		"Group-cover layout must use explicit floating-point division and flooring."
	):
		return
	if not _require(
		not group_window_source.contains(
			"var report: Dictionary = loaded.get(\"report\", {})"
		)
		and group_window_source.contains("var failure_report: Dictionary")
		and group_window_source.contains("var import_report: Dictionary"),
		"Group import preview must use unambiguous report variable names."
	):
		return
	if not _require(
		not workspace_source.contains(
			"var default_value: Variant = [] if"
		)
		and workspace_source.contains("var default_value: Variant = \"\"")
		and workspace_source.contains(
			"if str(field.get(\"type\", \"\")) == \"tags\":"
		),
		"Character Life unchanged-value review must avoid a mixed Array/String ternary."
	):
		return
	print("v0.17.5-hotfix3 Godot 4.7.2 warning cleanup regression passed")
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	print("V0175_HOTFIX3_WARNING_CLEANUP_ERROR: %s" % message)
	quit(1)
	return false
