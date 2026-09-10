# v0.18.0-hotfix3 — Lorebook Word Wrapping

The Lorebook Manager's **Lore content** and **Trigger Preview** inputs are multiline text editors, but they did not opt into Godot's boundary wrapping. Long paragraphs therefore continued horizontally until the author inserted a manual line break.

Both controls now use boundary word wrapping, matching the other multiline authoring surfaces in Character Card Forge. Long text flows onto additional visible lines automatically as the editor width changes.

This is visual wrapping only. CCF does not insert newline characters into the saved lore, rewrite existing lorebook content or change trigger matching. Authors can still enter deliberate paragraph breaks normally.

The focused regression opens the live application, verifies that the generation-aware Lorebook Manager is still installed, checks both multiline controls and confirms that visual wrapping leaves the stored text unchanged.
