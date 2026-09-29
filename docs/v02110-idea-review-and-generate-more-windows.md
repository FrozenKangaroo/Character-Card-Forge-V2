# v0.21.10 Idea Review and Generate More Windows

v0.21.10 is a focused usability follow-up for Final Idea Review and the editable
Generate More workflow introduced in v0.21.9. It does not change Idea generation,
curation, portable formats or review authority.

## Inspect the Idea before deciding

Every Final Idea Review candidate still starts checked. A new **Show Idea** control on
each review card expands the complete stored generated Idea without opening another
window. The read-only view puts **Concept** first and includes populated Character Name,
Character Role, Source Anchor, Roleplay Hook, Tags and any additional meaningful fields
returned in the Idea schema.

**Expand All** and **Collapse All** are available for larger batches. Expanding or
collapsing details never changes a Keep checkbox. AI adherence and similarity findings
remain advisory, and only the author's checked state controls retention.

## Context-aware Final Idea Review placement

Final Idea Review now uses the Idea Generator window as its launch context. A valid
remembered position and size are retained. If that geometry is no longer on an available
display, the review opens centred and clamped on the display containing Idea Generator.
The review remains a separate native tool window that can be moved and resized normally.

## Generate More actions stay reachable

Generate More is now a native child tool window of Idea Generator. It remains above its
owner and on the same display, instead of being owned by the main Workspace behind it.

The count, frozen Idea Source confirmation and Prompt / Additional Direction editor live
inside a scrollable body. **Cancel** and **Generate & Append** use a fixed footer outside
that body, so the actions stay visible when display height is limited or the editor needs
more room.

All v0.21.9 behavior is preserved: the latest successful instruction remains the next
prefill, frozen source and Series context never follow unrelated main-generator edits,
one manual extension shares one instruction across provider batches and optional top-up,
and only that extension's new Ideas enter its review checklist.
