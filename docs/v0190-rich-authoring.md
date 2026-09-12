# v0.19.0 Rich Scenario, Greeting, World and Ensemble Authoring

v0.19.0 builds richer authoring on the existing Character Card, Card Workflow,
Relationship, Front Porch group-card and `.fpworld` models. It does not create a second
canonical store or write directly to Front Porch.

## Scenario presets

Each character can retain multiple versioned setup records with an alternate scenario,
opening message, active cast, shared-world references, tags and favourite state. A
single-scenario target uses an explicit materialisation preview: CCF produces a standard
Character Card V2 object with the selected setup but does not edit the source character
or discard the other presets.

## Greeting manager

Alternative Greetings can carry categories, tags, a bounded random weight, favourite
state and an optional Front Porch opening-state seed. The ordinary ordered
`alternate_greetings` string array remains synchronised for Character Card V2
compatibility. Weighted preview is local and never changes the saved order.

## Ensembles and group workflows

Rich Authoring exposes direct entry points to create a group project, add a blank member
or add an existing library character. Library intake creates an independent record with
a fresh stable ID and private lineage. Managed artwork and attachments are not
cross-linked between project folders.

Card Workflow Studio remains the primary editor for name, roster, shared scenario,
opening, member directions, prompts, turn behavior, Director/chaos options, objectives,
opening state, lore and worlds. v0.19.0 stores the persistent roster separately from the
members active in a particular scenario. Combined-card preview creates a valid reviewed
runtime artifact and reports semantics that a target cannot express; it never merges or
modifies the independent source records.

## Split Character Sets

A shared concept plus `Name | Role` member seeds creates independent character records
before generation starts. The AI request is one recoverable parent batch, but each
validated member is applied and checkpointed separately. A malformed member does not
discard successful siblings, and Retry Failed Members requests only the pending or
failed stable IDs. Per-character Interview/Q&A remains separate.

## Worlds, dependencies and lineage

Projects link existing `.fpworld` records rather than silently copying their lore.
Dependency inspection reports character/workflow membership, scenario and workflow world
references, portrait files and collection membership so deletion surfaces references
first. Lineage rows expose existing revision/derivative provenance plus library-copy and
split-set relationships; optional timeline and family-role fields remain private.

## Private custom metadata

Custom metadata is CCF-private by default. An author may map an individual private key to
a named Character Card extension key and inspect a preview. Only valid explicit mappings
are emitted; unmapped values and the mapping configuration itself remain out of ordinary
card exports. The reserved Character Card Forge extension cannot be overwritten.

## Safety boundary

- Materialisation never edits source characters.
- Imported library members receive fresh IDs and their own first revision.
- Split results are validated per member and partial work remains recoverable.
- Unknown world/group fields continue through their established lossless adapters.
- No AI task runs merely because Rich Authoring opens.
- No automatic network call, Front Porch database write or background content deletion is introduced.
