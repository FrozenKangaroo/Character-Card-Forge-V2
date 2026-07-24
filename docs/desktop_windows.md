# Desktop Tool Windows

Character Card Forge uses native operating-system windows selectively for substantial workspaces that benefit from being detached from the main application.

## Native tools in v0.4.1

- Idea Generator
- Generation Preview
- Character Builder
- Controlled Build

The windows are constructed hidden before native-window mode is configured, because Godot does not allow `force_native` to change while a window is displayed. Once opened, they are deliberately non-exclusive. The main Character Card Forge window remains interactive while they are open, which makes it possible to compare generated content with the current character workspace or place tools on another monitor.

Small confirmation dialogs and file pickers remain ordinary application dialogs rather than being promoted into independent workspaces.

## Window state

Tool-window geometry is stored separately from character projects and application/API settings:

```text
user://character_card_forge/settings/tool_windows.json
```

The state file contains only UI placement data. It can be deleted safely; Character Card Forge will recreate it as tools are used.

When a saved window rectangle no longer overlaps an available display, the saved position is ignored and the tool opens centred again. This protects against stale layouts after monitors are disconnected or rearranged.

Exact window placement remains subject to the host operating system and desktop compositor. Some display servers may restrict applications from restoring absolute positions even though users can still drag native windows normally.


## v0.5 project-level windows

The following project-level tools are also native detachable windows:

- **Shared Project Context** — edits premise, setting, shared situation, rules, and project notes.
- **Group Scene Generator** — selects multiple characters, generates a shared scene proposal, and reviews per-character scenarios.

Unlike character-specific Generation Preview, Character Builder, and Controlled Build windows, these project-level windows may remain open while switching between characters inside the same project. They are released when a different project is opened.
