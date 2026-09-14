# v0.20.3 Searchable Offline Help Center

v0.20.3 adds a permanent **Help Center** to the sidebar and to searchable Quick
Actions. It provides concise, task-oriented guidance inside Character Card Forge
without requiring a browser, an AI provider or a network connection.

## Included guides

The initial catalog contains 12 guides across six categories:

- Getting Started: first launch, provider setup, first character and import.
- Creating & Editing: Workspace editing, Card Inspector, AI Review and recovery.
- Library: search, organisation, panels, density, archives and portable libraries.
- Images: Image Studio, prompts, presets, provider capabilities and expressions.
- Import, Export & Front Porch: safe export, artwork selection and supported-API installation.
- Help & Recovery: backup, troubleshooting and diagnostic privacy.

Search checks titles, summaries, keywords, steps and notes. A category selector can
narrow the result set, and related-topic links keep common task paths connected.

## Direct app routes

Guides can open the existing canonical tool for the task, such as New Project,
Settings, Character Library, Image Studio, AI Review, Export or Install, and Support
& Diagnostics. The Help Center does not create replacement workflows or alter project
data by itself.

## Offline and privacy boundary

The catalog is loaded from `data/help_articles_v1.json`. Searching, reading and moving
between topics are deterministic local operations. The Help Center contains no network
request node, makes no provider calls and sends no project or character data anywhere.
Only an explicit **Open in app** action can take the author to an existing tool; that
tool retains its own established confirmation and network boundaries.

## Versioned content contract

The external catalog has `format_version: 1`, ordered categories and articles with
stable IDs. Each article may provide:

- a category, title, summary and search keywords;
- ordered task steps and optional notes;
- action IDs that must exist in the app's Quick Action catalog;
- related article IDs that must exist in the same help catalog.

Startup does not rewrite the catalog. Catalog validation and the v0.20.3 live UI test
guard IDs, references, routing and offline behavior. This structure also gives the
planned GitHub Wiki an initial verified content set that can be expanded without
coupling help text to individual UI scripts.
