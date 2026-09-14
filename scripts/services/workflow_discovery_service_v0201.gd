class_name CCFWorkflowDiscoveryServiceV0201
extends RefCounted


static func new_project_methods() -> Array[Dictionary]:
	return [
		{
			"id": "manual",
			"label": "Blank Workspace",
			"description": "Start with the selected template and edit fields directly.",
			"shortcut": "Ctrl+N",
		},
		{
			"id": "manual_guided",
			"label": "Manual Guided",
			"description": "Work through the selected template step by step without AI.",
			"shortcut": "",
		},
		{
			"id": "idea_generator",
			"label": "Idea Generator",
			"description": "Generate several concepts, then choose what to develop.",
			"shortcut": "",
		},
		{
			"id": "collaborator",
			"label": "Character Collaborator",
			"description": "Develop a character conversationally before creating the draft.",
			"shortcut": "",
		},
		{
			"id": "idea_notebook",
			"label": "Idea Notebook",
			"description": "Open saved ideas and turn one into a new character.",
			"shortcut": "",
		},
		{
			"id": "import",
			"label": "Import Card or Project",
			"description": "Open Import / Export and review an existing card or project first.",
			"shortcut": "",
		},
		{
			"id": "template",
			"label": "Template Start",
			"description": "Create a clean draft from the selected template for expert editing.",
			"shortcut": "",
		},
	]


static func quick_actions() -> Array[Dictionary]:
	return [
		{"id": "new_project", "label": "New Project", "group": "Create", "shortcut": "Ctrl+N"},
		{"id": "library", "label": "Open Character Library", "group": "Navigate", "shortcut": ""},
		{"id": "library_search", "label": "Search Character Library", "group": "Navigate", "shortcut": "Ctrl+F"},
		{"id": "save", "label": "Save Current Project", "group": "Workspace", "shortcut": "Ctrl+S"},
		{"id": "next_field", "label": "Focus Next Character Field", "group": "Workspace", "shortcut": "Alt+Down"},
		{"id": "previous_field", "label": "Focus Previous Character Field", "group": "Workspace", "shortcut": "Alt+Up"},
		{"id": "ai_review", "label": "Open AI Review", "group": "Review", "shortcut": "Ctrl+Shift+R"},
		{"id": "compare", "label": "Compare and Improve", "group": "Review", "shortcut": "Ctrl+Shift+D"},
		{"id": "export_install", "label": "Export or Install", "group": "Publish", "shortcut": "Ctrl+Shift+E"},
		{"id": "lorebook", "label": "Open Lorebook Manager", "group": "Workspace", "shortcut": "Ctrl+Shift+L"},
		{"id": "layout_editing", "label": "Layout: Editing", "group": "Layouts", "shortcut": ""},
		{"id": "layout_review", "label": "Layout: Review", "group": "Layouts", "shortcut": ""},
		{"id": "layout_lorebook", "label": "Layout: Lorebook", "group": "Layouts", "shortcut": ""},
		{"id": "layout_front_porch", "label": "Layout: Front Porch Deployment", "group": "Layouts", "shortcut": ""},
		{"id": "layout_group_card", "label": "Layout: Group Card", "group": "Layouts", "shortcut": ""},
		{"id": "image_studio", "label": "Open Image Studio", "group": "Navigate", "shortcut": ""},
		{"id": "settings", "label": "Open Settings", "group": "Navigate", "shortcut": ""},
		{"id": "getting_started", "label": "Getting Started Guide", "group": "Help", "shortcut": "F1"},
		{"id": "support_diagnostics", "label": "Support & Diagnostics", "group": "Help", "shortcut": ""},
	]


static func workspace_layouts() -> Array[Dictionary]:
	return [
		{"id": "editing", "label": "Editing", "description": "Return focus to the main character fields."},
		{"id": "review", "label": "Review", "description": "Open the review surface without starting an AI request."},
		{"id": "lorebook", "label": "Lorebook", "description": "Open project and character lore together."},
		{"id": "front_porch", "label": "Front Porch Deployment", "description": "Show Front Porch authoring and open export/install tools."},
		{"id": "group_card", "label": "Group Card", "description": "Open multi-character Card Workflows."},
	]


static func capabilities() -> Dictionary:
	return {
		"format_version": 1,
		"new_project_chooser": true,
		"creation_methods": new_project_methods().size(),
		"quick_actions": true,
		"keyboard_shortcuts": true,
		"workspace_layout_presets": workspace_layouts().size(),
		"getting_started_reopenable": true,
		"existing_workflows_reused": true,
	}
