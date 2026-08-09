# v0.16.0 — Character Collaborator Conversation Rewind

v0.16.0 starts the post-v0.15.40 development cycle with a safety/editing feature for Character Collaborator: an author can remove an accidentally submitted message without leaving later replies grounded in context that no longer exists.

## Delete From Here

Every author/user message in the Collaborator transcript now exposes **Delete From Here…** beside the existing Copy action.

The action is intentionally destructive to the branch rather than a single chat bubble. After confirmation it deletes:

- the selected author message;
- the assistant response that followed it;
- every later author/assistant/Vision transcript message;
- response variants stored inside removed assistant messages; and
- pending response-regeneration state for the removed branch.

The resulting conversation resumes immediately before the selected author message.

The action is available on author messages only. It is blocked while the Collaborator generation worker is active so an in-flight completion cannot arrive against a transcript that has just been rewritten.

## Summary safety

Character Collaborator may compress older history into `memory_summary`, with `summarized_through` recording the final transcript index represented by that summary.

A rewind preserves the summary only when `summarized_through` is strictly before the deleted message. If the selected/deleted message was already represented in the summary, v0.16.0 clears `memory_summary` and resets `summarized_through` to `-1`.

This is required for context correctness: deleting a visible message is not sufficient if the same information could otherwise remain in model context through derived summary memory.

## Reference Context remains independent

Delete From Here edits conversation history, not the independent Reference Context model.

Structured TARGET/REFERENCE sources, Character Card metadata, attached text/reference material and Vision-derived context remain attached unless the author explicitly removes them through their existing Reference Context controls. This preserves the established separation between conversation chronology and source material.

## Persistence

The rewind commits through the existing `_store_active_session()` path. The v0.15.5 independent Collaborator session store therefore autosaves the truncated transcript immediately without requiring the Character Project itself to be saved.

## Regression coverage

`tools/test_v0160_collaborator_rewind.gd` exercises the real `main.tscn` and verifies:

- the v0.16.0 Workspace installs the v0.16.0 Collaborator;
- every rendered author message exposes Delete From Here;
- deleting a user message removes that message and every later transcript message;
- assistant response variants on the deleted branch disappear with their message;
- pending regeneration state is cleared;
- a memory summary covering only retained history survives;
- a memory summary that includes the deleted branch is invalidated;
- structured and ordinary Reference Context survive transcript rewind; and
- assistant-message deletion is rejected by the public rewind contract.

The v0.16.0 regression manifest inherits the complete v0.15.40-hotfix9/release baseline so this feature remains behind the existing cross-feature release gates.
