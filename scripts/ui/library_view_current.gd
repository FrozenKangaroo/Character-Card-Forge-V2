class_name CCFLibraryCurrentView
extends "res://scripts/ui/library_view_v0200_hotfix1.gd"


func _rebuild_grid() -> void:
	# Card density changes rebuild immediately. Recalculate the virtual grid before
	# that rebuild so it never renders Mini cards with the previous Large columns.
	_update_grid_columns()
	super._rebuild_grid()


func density_reflow_capabilities_v0212() -> Dictionary:
	return {
		"reflow_on_density_change": true,
		"window_resize_not_required": true,
		"virtualized_grid_preserved": true,
	}
