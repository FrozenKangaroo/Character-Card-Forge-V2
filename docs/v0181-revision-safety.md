# v0.18.1 — Revision Safety, Diff and Recovery

Character Card Forge v0.18.1 adds durable revision history to each character record.
It complements the editor's short-lived undo behavior; it does not checkpoint every
keystroke.

## Meaningful checkpoints

The application creates revisions for:

- explicit named checkpoints;
- meaningful saves (unchanged automatic save snapshots are deduplicated);
- accepted AI preview changes;
- imported character projects;
- selective merges, restores and forks.

Each entry stores an immutable character snapshot, timestamp, label, optional note,
reason, bounded provenance and content hash. The snapshot excludes its own revision
history and volatile update timestamp so history does not grow recursively.

## Compare and recover

Open **Revision History** from the Workspace toolbar. The two selectors can compare
the current character, another character in the project, or any pair of saved
checkpoints. The table reports field paths
across core card content, alternate greetings, lorebooks, metadata, custom fields and
vendor extensions. Selecting a row shows the complete structured before/after value.

Checked changes can be applied from the right-hand revision or related character. A
recovery checkpoint is created first. Restoring a complete revision uses the same safety rule: CCF saves the
displaced current state, applies the historical snapshot, then appends the result as a
new current revision. Existing later history is never truncated.

Fork creates a new character with a fresh ID and private source lineage. Export writes
the selected historical snapshot as ordinary Character Card V2 JSON; revision history
and private lineage are excluded from that card export.

## Retention and portable projects

Retention is configured per character from 5 to 500 entries (50 by default). Oldest
entries are removed only when the limit is exceeded or **Prune Now** is used.

History is included in `.ccfproject` packages by default so recovery points can travel
with a project. Authors can turn this off per character. Package preparation operates
on a copy and never strips history from the live saved project.

Character snapshots keep image and attachment paths/provenance as references. They do
not embed or duplicate the underlying image, attachment or generated-result binaries
for every checkpoint.

## Future integration contract

New destructive format migrations and the planned v0.18.4 library batch-action layer
must create a checkpoint before modifying character content. They should call the same
revision service instead of creating a separate backup format.
