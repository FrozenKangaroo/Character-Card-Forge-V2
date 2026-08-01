class_name CCFSettingsV0152View
extends "res://scripts/ui/settings_view_v0151.gd"

const MAX_OUTPUT_TOKENS_V0152 := 4194304


func _ready() -> void:
	super._ready()
	if _max_tokens != null:
		_max_tokens.max_value = MAX_OUTPUT_TOKENS_V0152
		_max_tokens.allow_greater = true
		_max_tokens.tooltip_text = "Maximum response tokens requested from the model. Large-context models may support values well above 131,072; Character Card Forge does not impose the old 131,072-token ceiling."
