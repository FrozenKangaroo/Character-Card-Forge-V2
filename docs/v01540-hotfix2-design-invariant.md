# v0.15.40-hotfix2 Source Renderer Invariant

For the active Character Collaborator, a populated multi-source list must converge on one renderer regardless of which inherited refresh path initiated the update:

- one stacked source card per source;
- descriptive label above actions;
- wrapping action flow below;
- no live `HBoxContainer` source rows;
- action controls never inherit wrapped-label height;
- linked Vision only changes provenance/status/action text, not the source-row structural contract.

This invariant is intentionally enforced after the complete source-panel refresh rather than inferred from which override Godot dispatched during the refresh chain.
